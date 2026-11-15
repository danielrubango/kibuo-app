import 'package:drift/drift.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

/// A rate as known now, with the one it replaced.
class RateInfo {
  const RateInfo({
    required this.rate,
    required this.setOn,
    this.previous,
    this.isWorkedOut = false,
  });

  final ExchangeRate rate;
  final DateTime setOn;
  final RateInfo? previous;

  /// Not typed by the user, but worked out through a third currency.
  final bool isWorkedOut;
}

/// Why a currency cannot be removed.
sealed class KeptReason {
  const KeptReason();
}

/// It is the main currency.
class KeptAsMain extends KeptReason {
  const KeptAsMain();

  @override
  bool operator ==(Object other) => other is KeptAsMain;

  @override
  int get hashCode => 0;
}

/// An account (archived or not) is kept in it.
class KeptForAccount extends KeptReason {
  const KeptForAccount(this.account);

  final String account;

  @override
  bool operator ==(Object other) =>
      other is KeptForAccount && other.account == account;

  @override
  int get hashCode => account.hashCode;
}

/// The user's currencies, main currency and exchange rates (ADR 0004).
/// Every write carries the sync metadata of ADR 0003.
class CurrencyRepository {
  CurrencyRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final KibuoDatabase _db;
  final DateTime Function() _now;
  HybridClock? _clock;

  static const _primaryCurrency = 'primary_currency';

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  Future<String?> primaryCurrency() async {
    final row =
        await (_db.select(_db.preferences)
              ..where((p) => p.name.equals(_primaryCurrency) & p.deleted.not()))
            .getSingleOrNull();
    return row?.value;
  }

  /// On the first start, the phone's country's currency; never overwrites.
  Future<void> ensurePrimaryCurrency(String? countryCode) async {
    if (await primaryCurrency() != null) return;
    await setPrimaryCurrency(defaultPrimaryCurrency(countryCode));
  }

  Future<void> setPrimaryCurrency(String code) async {
    currencyOf(code);
    await addCurrency(code);
    final existing = await (_db.select(
      _db.preferences,
    )..where((p) => p.name.equals(_primaryCurrency))).getSingleOrNull();
    final version = await _nextVersion();
    if (existing == null) {
      await _db
          .into(_db.preferences)
          .insert(
            PreferencesCompanion.insert(
              id: const Uuid().v7(),
              version: version,
              deviceId: _db.deviceId,
              name: _primaryCurrency,
              value: code,
            ),
          );
    } else {
      await (_db.update(
        _db.preferences,
      )..where((p) => p.id.equals(existing.id))).write(
        PreferencesCompanion(
          value: Value(code),
          version: Value(version),
          deviceId: Value(_db.deviceId),
          deleted: const Value(false),
        ),
      );
    }
  }

  /// The user's currencies, in the order they were added.
  Future<List<String>> currencyCodes() async {
    final rows =
        await (_db.select(_db.currencies)
              ..where((c) => c.deleted.not())
              ..orderBy([(c) => OrderingTerm.asc(c.version)]))
            .get();
    return [for (final r in rows) r.code];
  }

  /// [code] as the user uses it (decimals on or off).
  Future<CurrencyInfo> currency(String code) async {
    final row = await (_db.select(
      _db.currencies,
    )..where((c) => c.code.equals(code) & c.deleted.not())).getSingleOrNull();
    final info = currencyOf(code);
    return row == null ? info : info.withDecimals(row.usesDecimals);
  }

  Future<void> addCurrency(String code) async {
    final info = currencyOf(code);
    final exists = await (_db.select(
      _db.currencies,
    )..where((c) => c.code.equals(code) & c.deleted.not())).getSingleOrNull();
    if (exists != null) return;
    await _db
        .into(_db.currencies)
        .insert(
          CurrenciesCompanion.insert(
            id: const Uuid().v7(),
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            code: code,
            usesDecimals: info.usesDecimals,
          ),
        );
  }

  /// Why [code] must stay among the user's currencies, or null when it can
  /// be removed.
  Future<KeptReason?> whyKept(String code) async {
    if (await primaryCurrency() == code) return const KeptAsMain();
    final account =
        await (_db.select(_db.accounts)
              ..where((a) => a.currency.equals(code) & a.deleted.not())
              ..limit(1))
            .getSingleOrNull();
    return account == null ? null : KeptForAccount(account.name);
  }

  /// Takes [code] out of the user's currencies. Its rates stay, and come
  /// back if it is added again.
  Future<void> removeCurrency(String code) async {
    if (await whyKept(code) != null) {
      throw StateError('$code is still in use');
    }
    await (_db.update(
      _db.currencies,
    )..where((c) => c.code.equals(code) & c.deleted.not())).write(
      CurrenciesCompanion(
        deleted: const Value(true),
        version: Value(await _nextVersion()),
        deviceId: Value(_db.deviceId),
      ),
    );
  }

  Future<void> setUsesDecimals(String code, {required bool on}) async {
    await addCurrency(code);
    await (_db.update(
      _db.currencies,
    )..where((c) => c.code.equals(code) & c.deleted.not())).write(
      CurrenciesCompanion(
        usesDecimals: Value(on && currencyOf(code).digits > 0),
        version: Value(await _nextVersion()),
        deviceId: Value(_db.deviceId),
      ),
    );
  }

  /// Records « 1 [base] = [value] [quote] » from now on; older rates stay.
  Future<void> setRate(String base, String quote, RateValue value) async {
    await _db
        .into(_db.exchangeRates)
        .insert(
          ExchangeRatesCompanion.insert(
            id: const Uuid().v7(),
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            base: base,
            quote: quote,
            value: value.toString(),
            setOn: _now().toUtc(),
          ),
        );
  }

  /// The latest rate between [a] and [b], typed either way; else one worked
  /// out through a third currency; else null.
  Future<RateInfo?> latestRate(String a, String b) async {
    final direct = await _pairHistory(a, b);
    if (direct.isNotEmpty) {
      return RateInfo(
        rate: direct[0].$1,
        setOn: direct[0].$2,
        previous: direct.length > 1
            ? RateInfo(rate: direct[1].$1, setOn: direct[1].$2)
            : null,
      );
    }
    // Currencies with a rate to both a and b can link them.
    final rows = await (_db.select(
      _db.exchangeRates,
    )..where((r) => r.deleted.not())).get();
    Set<String> linkedTo(String c) => {
      for (final r in rows)
        if (r.base == c) r.quote else if (r.quote == c) r.base,
    };
    for (final pivot in linkedTo(a).intersection(linkedTo(b))) {
      if (pivot == a || pivot == b) continue;
      final first = await _pairHistory(a, pivot);
      final second = await _pairHistory(pivot, b);
      if (first.isEmpty || second.isEmpty) continue;
      final older = first[0].$2.isBefore(second[0].$2)
          ? first[0].$2
          : second[0].$2;
      return RateInfo(
        rate: ExchangeRate.through(
          from: a,
          to: b,
          first: first[0].$1,
          second: second[0].$1,
        ),
        setOn: older,
        isWorkedOut: true,
      );
    }
    return null;
  }

  /// Rates between [a] and [b], newest first.
  Future<List<(ExchangeRate, DateTime)>> _pairHistory(
    String a,
    String b,
  ) async {
    final rows =
        await (_db.select(_db.exchangeRates)
              ..where(
                (r) =>
                    r.deleted.not() &
                    ((r.base.equals(a) & r.quote.equals(b)) |
                        (r.base.equals(b) & r.quote.equals(a))),
              )
              ..orderBy([
                (r) => OrderingTerm.desc(r.setOn),
                (r) => OrderingTerm.desc(r.version),
              ]))
            .get();
    return [
      for (final r in rows)
        (
          ExchangeRate(
            base: r.base,
            quote: r.quote,
            value: RateValue.parse(r.value),
          ),
          r.setOn.toUtc(),
        ),
    ];
  }
}
