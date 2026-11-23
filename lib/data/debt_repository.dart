import 'package:drift/drift.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/categories/default_categories.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/obligations/debt_list.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

export 'package:kibuo/domain/obligations/debt_list.dart';

/// Debts and receivables (PRODUCT: Dettes et créances). Money that moves
/// for them is an operation of its account, tied to the debt.
class DebtRepository {
  DebtRepository(this._db) : _transactions = TransactionRepository(_db);

  final KibuoDatabase _db;
  final TransactionRepository _transactions;
  HybridClock? _clock;

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  /// A new debt ([DebtDirection.owe]) or receivable. With [accountId], the
  /// money borrowed reaches it, or the money lent leaves it, converted at
  /// [rate] when the account has another currency. Without, it is an old
  /// one: only what is left is noted. Returns its id.
  Future<String> create({
    required DebtDirection direction,
    required String person,
    required Money amount,
    required DateTime openedOn,
    DateTime? due,
    String? note,
    String? accountId,
    ExchangeRate? rate,
    bool rateTyped = false,
  }) async {
    final id = const Uuid().v7();
    final name = person.trim();
    final clean = note?.trim();
    await _db.transaction(() async {
      await _db
          .into(_db.debts)
          .insert(
            DebtsCompanion.insert(
              id: id,
              version: await _nextVersion(),
              deviceId: _db.deviceId,
              direction: direction.stored,
              person: name,
              amount: amount.minor,
              currency: amount.currency,
              openedOn: openedOn.toUtc(),
              dueDate: Value(due?.toUtc()),
              note: Value(clean == null || clean.isEmpty ? null : clean),
            ),
          );
      if (accountId == null) return;
      final owe = direction == DebtDirection.owe;
      final kind = owe ? CategoryKind.into : CategoryKind.out;
      await _ensureCategories();
      await _transactions.create(
        kind: owe ? EntryKind.income : EntryKind.expense,
        accountId: accountId,
        categoryId: debtCategoryId(owe: owe, kind: kind),
        paid: amount,
        fees: 0,
        date: openedOn,
        rate: rate,
        rateTyped: rateTyped,
        note: name,
        debtId: id,
      );
    });
    return id;
  }

  /// Every debt and receivable, with what is left of each.
  Future<List<DebtLine>> debts() async {
    final rows = await (_db.select(
      _db.debts,
    )..where((d) => d.deleted.not())).get();
    final moves =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.debtId.isNotNull() &
                  t.deleted.not() &
                  t.status.equals('done'),
            ))
            .get();
    return [
      for (final r in rows)
        () {
          final direction = DebtDirection.fromStored(r.direction);
          // A debt is repaid with money going out, a receivable with
          // money coming in.
          final repayKind = direction == DebtDirection.owe ? 'out' : 'in';
          final repaid = [
            for (final m in moves)
              if (m.debtId == r.id &&
                  m.kind == repayKind &&
                  m.currency == r.currency)
                m,
          ];
          final left =
              r.amount - repaid.fold<int>(0, (sum, m) => sum + m.amount);
          DateTime? last;
          for (final m in repaid) {
            final d = m.date.toLocal();
            if (last == null || d.isAfter(last)) last = d;
          }
          return DebtLine(
            id: r.id,
            direction: direction,
            person: r.person,
            amount: Money(r.amount, r.currency),
            left: Money(left < 0 ? 0 : left, r.currency),
            due: r.dueDate?.toLocal(),
            settledOn: left <= 0 ? last : null,
          );
        }(),
    ];
  }

  /// The names already used, the latest first, each once whatever its
  /// case or accents, as last typed.
  Future<List<String>> people() async {
    final rows =
        await (_db.select(_db.debts)
              ..where((d) => d.deleted.not())
              ..orderBy([(d) => OrderingTerm.desc(d.version)]))
            .get();
    final seen = <String>{};
    return [
      for (final r in rows)
        if (seen.add(debtPersonKey(r.person))) r.person,
    ];
  }

  /// Its categories, out of every list of choices: removed from the start,
  /// so old and new operations still show them.
  Future<void> _ensureCategories() async {
    for (final (c, kind) in [
      (debtIn, CategoryKind.into),
      (debtOut, CategoryKind.out),
      (receivableIn, CategoryKind.into),
      (receivableOut, CategoryKind.out),
    ]) {
      await _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'default-${c.key}',
              version: await _nextVersion(),
              deviceId: _db.deviceId,
              kind: kind.stored,
              key: Value(c.key),
              icon: c.icon,
              position: 0,
              removed: const Value(true),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }
}
