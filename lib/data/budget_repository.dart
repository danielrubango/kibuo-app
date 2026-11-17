import 'package:drift/drift.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

/// A budget as the screens use it: its category and every amount change.
class BudgetInfo {
  const BudgetInfo({
    required this.id,
    required this.categoryId,
    required this.position,
    required this.changes,
  });

  final String id;
  final String categoryId;
  final int position;
  final List<AmountChange> changes;
}

/// The user's budgets (GLOSSARY: Budget). Every write carries the sync
/// metadata of ADR 0003; deleting marks the rows.
class BudgetRepository {
  BudgetRepository(this._db);

  final KibuoDatabase _db;
  HybridClock? _clock;

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  /// In « Mon ordre ».
  Future<List<BudgetInfo>> budgets() async {
    final rows =
        await (_db.select(_db.budgets)
              ..where((b) => b.deleted.not())
              ..orderBy([(b) => OrderingTerm.asc(b.position)]))
            .get();
    final amounts = await (_db.select(
      _db.budgetAmounts,
    )..where((a) => a.deleted.not())).get();
    return [
      for (final b in rows)
        BudgetInfo(
          id: b.id,
          categoryId: b.categoryId,
          position: b.position,
          changes: [
            for (final a in amounts)
              if (a.budgetId == b.id)
                AmountChange(a.fromMonth, Money(a.amount, a.currency)),
          ],
        ),
    ];
  }

  /// One budget per category: a second one is refused.
  Future<String> create({
    required String categoryId,
    required Money amount,
    required int fromMonth,
  }) => _db.transaction(() async {
    final existing = await budgets();
    if (existing.any((b) => b.categoryId == categoryId)) {
      throw StateError('$categoryId already has a budget');
    }
    final id = const Uuid().v7();
    final last = existing.isEmpty
        ? -1
        : existing.map((b) => b.position).reduce((a, b) => a > b ? a : b);
    await _db
        .into(_db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: id,
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            categoryId: categoryId,
            position: last + 1,
          ),
        );
    await _addAmount(id, amount, fromMonth);
    return id;
  });

  Future<void> _addAmount(String budgetId, Money amount, int fromMonth) async =>
      _db
          .into(_db.budgetAmounts)
          .insert(
            BudgetAmountsCompanion.insert(
              id: const Uuid().v7(),
              version: await _nextVersion(),
              deviceId: _db.deviceId,
              budgetId: budgetId,
              fromMonth: fromMonth,
              amount: amount.minor,
              currency: amount.currency,
            ),
          );

  /// [amount] from [fromMonth] on; a change already made that month is
  /// replaced.
  Future<void> setAmount(String id, Money amount, {required int fromMonth}) =>
      _db.transaction(() async {
        final same =
            await (_db.select(_db.budgetAmounts)..where(
                  (a) =>
                      a.budgetId.equals(id) &
                      a.fromMonth.equals(fromMonth) &
                      a.deleted.not(),
                ))
                .getSingleOrNull();
        if (same == null) return _addAmount(id, amount, fromMonth);
        await (_db.update(
          _db.budgetAmounts,
        )..where((a) => a.id.equals(same.id))).write(
          BudgetAmountsCompanion(
            amount: Value(amount.minor),
            currency: Value(amount.currency),
            version: Value(await _nextVersion()),
            deviceId: Value(_db.deviceId),
          ),
        );
      });

  /// « Mon ordre »: [ids] from first to last.
  Future<void> reorder(List<String> ids) => _db.transaction(() async {
    for (var i = 0; i < ids.length; i++) {
      await (_db.update(_db.budgets)..where((b) => b.id.equals(ids[i]))).write(
        BudgetsCompanion(
          position: Value(i),
          version: Value(await _nextVersion()),
          deviceId: Value(_db.deviceId),
        ),
      );
    }
  });

  /// The amount of [categoryId]'s budget, its latest; none without one.
  Future<Money?> ofCategory(String categoryId) async {
    final b = (await budgets())
        .where((b) => b.categoryId == categoryId)
        .firstOrNull;
    if (b == null || b.changes.isEmpty) return null;
    return (b.changes.toList()
          ..sort((x, y) => x.fromMonth.compareTo(y.fromMonth)))
        .last
        .amount;
  }

  /// With its category (retro, 18 November): the budget goes too.
  Future<void> deleteOfCategory(String categoryId) async {
    for (final b in await budgets()) {
      if (b.categoryId == categoryId) await delete(b.id);
    }
  }

  Future<void> delete(String id) => _db.transaction(() async {
    final version = await _nextVersion();
    await (_db.update(_db.budgets)..where((b) => b.id.equals(id))).write(
      BudgetsCompanion(
        deleted: const Value(true),
        version: Value(version),
        deviceId: Value(_db.deviceId),
      ),
    );
    await (_db.update(
      _db.budgetAmounts,
    )..where((a) => a.budgetId.equals(id))).write(
      BudgetAmountsCompanion(
        deleted: const Value(true),
        version: Value(version),
        deviceId: Value(_db.deviceId),
      ),
    );
  });
}
