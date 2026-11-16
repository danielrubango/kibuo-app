import 'package:drift/drift.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:kibuo/domain/transactions/entry_total.dart';
import 'package:kibuo/domain/transactions/transfer_total.dart';
import 'package:uuid/uuid.dart';

export 'package:kibuo/domain/transactions/entry_total.dart';
export 'package:kibuo/domain/transactions/transfer_total.dart';

/// An expense, income or transfer as the screens show it.
class TransactionInfo {
  const TransactionInfo({
    required this.id,
    required this.kind,
    required this.accountId,
    required this.categoryId,
    required this.paid,
    required this.total,
    required this.date,
    this.toAccountId,
    this.arrived,
    this.rate,
    this.rateTyped = false,
    this.note,
  });

  final String id;
  final EntryKind kind;

  /// For a transfer, the sending account.
  final String accountId;

  /// None for a transfer.
  final String? categoryId;

  /// A transfer's receiving account, and what reached it in its currency.
  final String? toAccountId;
  final Money? arrived;

  /// What was paid or received, in its own currency; for a transfer, what
  /// was sent, in the sending account's currency.
  final Money paid;

  /// The frozen rate when [paid] is not in the account's currency, or a
  /// transfer's two accounts differ.
  final ExchangeRate? rate;

  /// The changer's rate, typed for this operation.
  final bool rateTyped;

  /// Converted amount, fees and what it did to the account.
  final EntryTotal total;
  final DateTime date;
  final String? note;
}

/// The user's expenses and income. Every write carries the sync metadata of
/// ADR 0003.
class TransactionRepository {
  TransactionRepository(this._db);

  final KibuoDatabase _db;
  HybridClock? _clock;

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  /// The columns of an operation, its conversion done once and kept.
  Future<TransactionsCompanion> _columns({
    required EntryKind kind,
    required String accountId,
    required String categoryId,
    required Money paid,
    required int fees,
    required DateTime date,
    ExchangeRate? rate,
    bool rateTyped = false,
    String? note,
  }) async {
    final currencies = CurrencyRepository(_db);
    final account = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).getSingle();
    final accountCurrency = await currencies.currency(account.currency);
    final total = entryTotal(
      kind: kind,
      paid: paid,
      account: accountCurrency,
      rate: paid.currency == account.currency ? null : rate,
      fees: fees,
    );
    await currencies.addCurrency(paid.currency);
    final usesRate = paid.currency != account.currency;
    final clean = note?.trim();
    return TransactionsCompanion(
      kind: Value(kind.stored),
      accountId: Value(accountId),
      // A transfer turned into an expense or income loses its other account.
      toAccountId: const Value(null),
      categoryId: Value(categoryId),
      amount: Value(paid.minor),
      currency: Value(paid.currency),
      rateBase: Value(usesRate ? rate!.base : null),
      rateQuote: Value(usesRate ? rate!.quote : null),
      rateValue: Value(usesRate ? rate!.value.toString() : null),
      rateTyped: Value(usesRate && rateTyped),
      converted: Value(total.converted.minor),
      fees: Value(fees),
      date: Value(date.toUtc()),
      note: Value(clean == null || clean.isEmpty ? null : clean),
    );
  }

  Future<String> create({
    required EntryKind kind,
    required String accountId,
    required String categoryId,
    required Money paid,
    required int fees,
    required DateTime date,
    ExchangeRate? rate,
    bool rateTyped = false,
    String? note,
  }) async {
    final id = const Uuid().v7();
    final columns = await _columns(
      kind: kind,
      accountId: accountId,
      categoryId: categoryId,
      paid: paid,
      fees: fees,
      date: date,
      rate: rate,
      rateTyped: rateTyped,
      note: note,
    );
    await _db
        .into(_db.transactions)
        .insert(
          columns.copyWith(
            id: Value(id),
            version: Value(await _nextVersion()),
            deviceId: Value(_db.deviceId),
          ),
        );
    return id;
  }

  Future<void> update(
    String id, {
    required EntryKind kind,
    required String accountId,
    required String categoryId,
    required Money paid,
    required int fees,
    required DateTime date,
    ExchangeRate? rate,
    bool rateTyped = false,
    String? note,
  }) async {
    final columns = await _columns(
      kind: kind,
      accountId: accountId,
      categoryId: categoryId,
      paid: paid,
      fees: fees,
      date: date,
      rate: rate,
      rateTyped: rateTyped,
      note: note,
    );
    await _write(id, columns);
  }

  /// The columns of a transfer: sent in the sending account's currency,
  /// what arrived converted once at the frozen rate.
  Future<TransactionsCompanion> _transferColumns({
    required String fromId,
    required String toId,
    required Money sent,
    required int fees,
    required DateTime date,
    ExchangeRate? rate,
    bool rateTyped = false,
    String? note,
  }) async {
    final currencies = CurrencyRepository(_db);
    final to = await (_db.select(
      _db.accounts,
    )..where((a) => a.id.equals(toId))).getSingle();
    final usesRate = sent.currency != to.currency;
    final total = transferTotal(
      sent: sent,
      to: await currencies.currency(to.currency),
      rate: usesRate ? rate : null,
      fees: fees,
    );
    final clean = note?.trim();
    return TransactionsCompanion(
      kind: Value(EntryKind.transfer.stored),
      accountId: Value(fromId),
      toAccountId: Value(toId),
      categoryId: const Value(null),
      amount: Value(sent.minor),
      currency: Value(sent.currency),
      rateBase: Value(usesRate ? rate!.base : null),
      rateQuote: Value(usesRate ? rate!.quote : null),
      rateValue: Value(usesRate ? rate!.value.toString() : null),
      rateTyped: Value(usesRate && rateTyped),
      converted: Value(total.arrived.minor),
      fees: Value(fees),
      date: Value(date.toUtc()),
      note: Value(clean == null || clean.isEmpty ? null : clean),
    );
  }

  Future<String> createTransfer({
    required String fromId,
    required String toId,
    required Money sent,
    required int fees,
    required DateTime date,
    ExchangeRate? rate,
    bool rateTyped = false,
    String? note,
  }) async {
    final id = const Uuid().v7();
    final columns = await _transferColumns(
      fromId: fromId,
      toId: toId,
      sent: sent,
      fees: fees,
      date: date,
      rate: rate,
      rateTyped: rateTyped,
      note: note,
    );
    await _db
        .into(_db.transactions)
        .insert(
          columns.copyWith(
            id: Value(id),
            version: Value(await _nextVersion()),
            deviceId: Value(_db.deviceId),
          ),
        );
    return id;
  }

  Future<void> updateTransfer(
    String id, {
    required String fromId,
    required String toId,
    required Money sent,
    required int fees,
    required DateTime date,
    ExchangeRate? rate,
    bool rateTyped = false,
    String? note,
  }) async {
    await _write(
      id,
      await _transferColumns(
        fromId: fromId,
        toId: toId,
        sent: sent,
        fees: fees,
        date: date,
        rate: rate,
        rateTyped: rateTyped,
        note: note,
      ),
    );
  }

  /// Takes the operation away (« Annuler et modifier » saves it again).
  Future<void> delete(String id) =>
      _write(id, const TransactionsCompanion(deleted: Value(true)));

  Future<void> _write(String id, TransactionsCompanion changes) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      changes.copyWith(
        version: Value(await _nextVersion()),
        deviceId: Value(_db.deviceId),
      ),
    );
  }

  /// Every operation, newest first.
  Future<List<TransactionInfo>> all() async {
    final rows =
        await (_db.select(_db.transactions)
              ..where((t) => t.deleted.not())
              ..orderBy([
                (t) => OrderingTerm.desc(t.date),
                (t) => OrderingTerm.desc(t.version),
              ]))
            .get();
    final accounts = {
      for (final a in await _db.select(_db.accounts).get()) a.id: a.currency,
    };
    return [
      for (final r in rows)
        _info(
          r,
          accounts[r.accountId] ?? r.currency,
          accounts[r.toAccountId] ?? r.currency,
        ),
    ];
  }

  Future<TransactionInfo?> get(String id) async {
    final row = await (_db.select(
      _db.transactions,
    )..where((t) => t.id.equals(id) & t.deleted.not())).getSingleOrNull();
    if (row == null) return null;
    Future<String?> currencyOf(String? id) async => id == null
        ? null
        : (await (_db.select(
            _db.accounts,
          )..where((a) => a.id.equals(id))).getSingleOrNull())?.currency;
    return _info(
      row,
      await currencyOf(row.accountId) ?? row.currency,
      await currencyOf(row.toAccountId) ?? row.currency,
    );
  }

  static TransactionInfo _info(
    TransactionRow r,
    String accountCurrency,
    String toCurrency,
  ) {
    final kind = EntryKind.fromStored(r.kind);
    final transfer = kind == EntryKind.transfer;
    return TransactionInfo(
      id: r.id,
      kind: kind,
      accountId: r.accountId,
      categoryId: r.categoryId,
      toAccountId: r.toAccountId,
      arrived: transfer ? Money(r.converted, toCurrency) : null,
      paid: Money(r.amount, r.currency),
      rate: r.rateValue == null
          ? null
          : ExchangeRate(
              base: r.rateBase!,
              quote: r.rateQuote!,
              value: RateValue.parse(r.rateValue!),
            ),
      rateTyped: r.rateTyped,
      // A transfer's sending side: what was sent, in its own currency.
      total: EntryTotal(
        kind: kind,
        converted: Money(transfer ? r.amount : r.converted, accountCurrency),
        fees: Money(r.fees, accountCurrency),
      ),
      date: r.date.toUtc(),
      note: r.note,
    );
  }
}
