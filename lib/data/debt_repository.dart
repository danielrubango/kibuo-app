import 'package:drift/drift.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/categories/default_categories.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/obligations/debt_list.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

export 'package:kibuo/domain/obligations/debt_list.dart';

/// A repayment of a debt or receivable, as its card lists it.
class Repayment {
  const Repayment({
    required this.id,
    required this.date,
    required this.account,
    required this.amount,
  });

  /// Its operation.
  final String id;
  final DateTime date;

  /// The account's name.
  final String account;

  /// In the debt's currency.
  final Money amount;
}

/// What a debt's card shows.
class DebtDetail {
  const DebtDetail({
    required this.line,
    required this.openedOn,
    required this.repayments,
    required this.operations,
    this.openingAccountId,
  });

  final DebtLine line;
  final DateTime openedOn;

  /// The newest first.
  final List<Repayment> repayments;

  /// The account the money borrowed or lent moved on, if any.
  final String? openingAccountId;

  /// Its operations, opening included: deleting it removes them.
  final int operations;
}

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

  /// A repayment of [debtId] from (or, for a receivable, into)
  /// [accountId]: [amount] in the debt's currency, never more than what is
  /// left (PRODUCT); converted at [rate] for an account in another
  /// currency. Returns its operation's id.
  Future<String> repay(
    String debtId, {
    required Money amount,
    required String accountId,
    required DateTime date,
    ExchangeRate? rate,
    bool rateTyped = false,
  }) async {
    final line = (await debts()).firstWhere((d) => d.id == debtId);
    if (amount.currency != line.left.currency ||
        amount.minor <= 0 ||
        amount.minor > line.left.minor) {
      throw ArgumentError.value(amount, 'amount', 'more than what is left');
    }
    final owe = line.direction == DebtDirection.owe;
    final kind = owe ? CategoryKind.out : CategoryKind.into;
    await _ensureCategories();
    return _transactions.create(
      kind: owe ? EntryKind.expense : EntryKind.income,
      accountId: accountId,
      categoryId: debtCategoryId(owe: owe, kind: kind),
      paid: amount,
      fees: 0,
      date: date,
      rate: rate,
      rateTyped: rateTyped,
      note: line.person,
      debtId: debtId,
    );
  }

  /// Its card: what is left, its repayments, where its money moved.
  Future<DebtDetail?> detail(String id) async {
    final line = (await debts()).where((d) => d.id == id).firstOrNull;
    if (line == null) return null;
    final row = await (_db.select(
      _db.debts,
    )..where((d) => d.id.equals(id))).getSingle();
    final moves =
        await (_db.select(_db.transactions)
              ..where((t) => t.debtId.equals(id) & t.deleted.not())
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();
    final names = {
      for (final a in await _db.select(_db.accounts).get()) a.id: a.name,
    };
    final repayKind = line.direction == DebtDirection.owe ? 'out' : 'in';
    return DebtDetail(
      line: line,
      openedOn: row.openedOn.toLocal(),
      operations: moves.length,
      openingAccountId: moves
          .where((m) => m.kind != repayKind)
          .firstOrNull
          ?.accountId,
      repayments: [
        for (final m in moves)
          if (m.kind == repayKind && m.status == 'done')
            Repayment(
              id: m.id,
              date: m.date.toLocal(),
              account: names[m.accountId] ?? '',
              amount: Money(m.amount, m.currency),
            ),
      ],
    );
  }

  /// A new name, amount or due date. The amount never goes below what was
  /// already paid back; the operation that opened it follows.
  Future<void> edit(
    String id, {
    required String person,
    required Money amount,
    DateTime? due,
  }) async {
    final line = (await debts()).firstWhere((d) => d.id == id);
    final repaid = line.amount.minor - line.left.minor;
    if (amount.currency != line.amount.currency || amount.minor < repaid) {
      throw ArgumentError.value(amount, 'amount', 'below what was repaid');
    }
    await _db.transaction(() async {
      await (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
        DebtsCompanion(
          person: Value(person.trim()),
          amount: Value(amount.minor),
          dueDate: Value(due?.toUtc()),
          version: Value(await _nextVersion()),
          deviceId: Value(_db.deviceId),
        ),
      );
      if (amount == line.amount) return;
      final openKind = line.direction == DebtDirection.owe ? 'in' : 'out';
      final opening =
          await (_db.select(_db.transactions)..where(
                (t) =>
                    t.debtId.equals(id) &
                    t.kind.equals(openKind) &
                    t.deleted.not(),
              ))
              .getSingleOrNull();
      if (opening == null) return;
      final op = (await _transactions.get(opening.id))!;
      await _transactions.update(
        op.id,
        kind: op.kind,
        accountId: op.accountId,
        categoryId: op.categoryId!,
        paid: amount,
        fees: op.total.fees.minor,
        date: op.date,
        rate: op.rate,
        rateTyped: op.rateTyped,
        note: op.note,
      );
    });
  }

  /// The debt and every operation of it, gone together (PRODUCT).
  Future<void> delete(String id) async {
    await _db.transaction(() async {
      final moves = await (_db.select(
        _db.transactions,
      )..where((t) => t.debtId.equals(id) & t.deleted.not())).get();
      for (final m in moves) {
        await _transactions.delete(m.id);
      }
      await (_db.update(_db.debts)..where((d) => d.id.equals(id))).write(
        DebtsCompanion(
          deleted: const Value(true),
          version: Value(await _nextVersion()),
          deviceId: Value(_db.deviceId),
        ),
      );
    });
  }

  static const _inTotals = 'debts_in_totals';

  /// Whether debts' operations count in Entrées and Sorties (PRODUCT: on
  /// by default; never in budgets either way).
  Future<bool> countInTotals() async =>
      await PreferenceStore(_db).read(_inTotals) != 'false';

  Future<void> setCountInTotals(bool on) =>
      PreferenceStore(_db).write(_inTotals, '$on');
}
