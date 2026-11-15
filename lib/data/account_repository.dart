import 'package:drift/drift.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/accounts/account_type.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

export 'package:kibuo/domain/accounts/account_type.dart';

/// An account as the screens show it.
class AccountInfo {
  const AccountInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.opening,
    required this.openingDate,
    required this.balance,
    required this.archived,
  });

  final String id;
  final String name;
  final AccountType type;

  /// The starting balance, on [openingDate].
  final Money opening;
  final DateTime openingDate;

  /// Today's balance: the starting balance, then its transactions.
  final Money balance;
  final bool archived;

  String get currency => opening.currency;
}

/// A type the user created, with its icon.
class CustomAccountType {
  const CustomAccountType({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;

  /// The Phosphor icon's name.
  final String icon;

  AccountType get type => AccountType.custom(id);
}

/// The user's accounts and account types. Every write carries the sync
/// metadata of ADR 0003.
class AccountRepository {
  AccountRepository(this._db);

  final KibuoDatabase _db;
  HybridClock? _clock;

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  static String _cleanName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError.value(name, 'name', 'is empty');
    return clean;
  }

  /// Adds an account holding [opening] on [openingDate]; returns its id.
  Future<String> create({
    required String name,
    required AccountType type,
    required Money opening,
    required DateTime openingDate,
  }) async {
    final clean = _cleanName(name);
    await CurrencyRepository(_db).addCurrency(opening.currency);
    final id = const Uuid().v7();
    final last = _db.accounts.position.max();
    final position =
        await (_db.selectOnly(
          _db.accounts,
        )..addColumns([last])).map((r) => r.read(last)).getSingle() ??
        0;
    await _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: id,
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            name: clean,
            type: type.key,
            currency: opening.currency,
            openingBalance: opening.minor,
            openingDate: openingDate.toUtc(),
            position: position + 1,
          ),
        );
    return id;
  }

  /// Renames [id] or changes its type. Its currency and starting balance
  /// are set once, at creation.
  Future<void> update(
    String id, {
    required String name,
    required AccountType type,
  }) => _write(
    id,
    AccountsCompanion(name: Value(_cleanName(name)), type: Value(type.key)),
  );

  /// Takes the account out of lists and totals, or back with [archived]
  /// false. Its transactions stay.
  Future<void> archive(String id, {bool archived = true}) =>
      _write(id, AccountsCompanion(archived: Value(archived)));

  /// The active accounts, or the archived ones, in the order they were
  /// created.
  Future<List<AccountInfo>> accounts({bool archived = false}) async {
    final rows =
        await (_db.select(_db.accounts)
              ..where((a) => a.deleted.not() & a.archived.equals(archived))
              ..orderBy([(a) => OrderingTerm.asc(a.position)]))
            .get();
    final changes = await _balanceChanges();
    return [
      for (final r in rows)
        AccountInfo(
          id: r.id,
          name: r.name,
          type: AccountType.fromKey(r.type),
          opening: Money(r.openingBalance, r.currency),
          openingDate: r.openingDate.toUtc(),
          balance: Money(r.openingBalance + (changes[r.id] ?? 0), r.currency),
          archived: r.archived,
        ),
    ];
  }

  /// What the operations dated from each account's starting date changed,
  /// by account: income less fees, expenses plus fees.
  Future<Map<String, int>> _balanceChanges() async {
    final rows = await _db
        .customSelect(
          'SELECT t.account_id AS account, SUM(CASE WHEN t.kind = \'in\' '
          'THEN t.converted - t.fees ELSE -(t.converted + t.fees) END) AS change '
          'FROM transactions t JOIN accounts a ON a.id = t.account_id '
          'WHERE t.deleted = 0 AND t.date >= a.opening_date '
          'GROUP BY t.account_id',
          readsFrom: {_db.transactions, _db.accounts},
        )
        .get();
    return {
      for (final r in rows) r.read<String>('account'): r.read<int>('change'),
    };
  }

  static const _allInMain = 'accounts_all_in_main';

  /// Whether Comptes shows every amount in the main currency.
  Future<bool> allInMain() async {
    final row =
        await (_db.select(_db.preferences)
              ..where((p) => p.name.equals(_allInMain) & p.deleted.not()))
            .getSingleOrNull();
    return row?.value == 'true';
  }

  Future<void> setAllInMain(bool on) async {
    final existing = await (_db.select(
      _db.preferences,
    )..where((p) => p.name.equals(_allInMain))).getSingleOrNull();
    final version = await _nextVersion();
    if (existing == null) {
      await _db
          .into(_db.preferences)
          .insert(
            PreferencesCompanion.insert(
              id: const Uuid().v7(),
              version: version,
              deviceId: _db.deviceId,
              name: _allInMain,
              value: '$on',
            ),
          );
    } else {
      await (_db.update(
        _db.preferences,
      )..where((p) => p.id.equals(existing.id))).write(
        PreferencesCompanion(
          value: Value('$on'),
          version: Value(version),
          deviceId: Value(_db.deviceId),
          deleted: const Value(false),
        ),
      );
    }
  }

  Future<String> createType({
    required String name,
    required String icon,
  }) async {
    final id = const Uuid().v7();
    await _db
        .into(_db.accountTypes)
        .insert(
          AccountTypesCompanion.insert(
            id: id,
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            name: _cleanName(name),
            icon: icon,
          ),
        );
    return id;
  }

  /// The user's own types, in the order they were created.
  Future<List<CustomAccountType>> types() async {
    final rows =
        await (_db.select(_db.accountTypes)
              ..where((t) => t.deleted.not())
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return [
      for (final r in rows)
        CustomAccountType(id: r.id, name: r.name, icon: r.icon),
    ];
  }

  Future<void> _write(String id, AccountsCompanion changes) async {
    await (_db.update(_db.accounts)..where((a) => a.id.equals(id))).write(
      changes.copyWith(
        version: Value(await _nextVersion()),
        deviceId: Value(_db.deviceId),
      ),
    );
  }
}
