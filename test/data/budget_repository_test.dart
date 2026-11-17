import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/budget_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/money.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late BudgetRepository budgets;
  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    budgets = BudgetRepository(db);
  });
  tearDown(() => db.close());

  Money d(int minor) => Money(minor, 'USD');

  test('a budget per category, in the order they were made', () async {
    final food = await budgets.create(
      categoryId: 'default-food',
      amount: d(25000),
      fromMonth: 202611,
    );
    await budgets.create(
      categoryId: 'default-leisure',
      amount: d(10000),
      fromMonth: 202611,
    );
    final all = await budgets.budgets();
    expect(
      [for (final b in all) b.categoryId],
      ['default-food', 'default-leisure'],
    );
    expect(all.first.id, food);
    expect(amountFor(all.first.changes, 202611), d(25000));
    expect(
      () => budgets.create(
        categoryId: 'default-food',
        amount: d(1),
        fromMonth: 202611,
      ),
      throwsStateError,
      reason: 'one per category',
    );
  });

  test(
    'a new amount holds from its month; the months before keep theirs',
    () async {
      final id = await budgets.create(
        categoryId: 'default-food',
        amount: d(25000),
        fromMonth: 202609,
      );
      await budgets.setAmount(id, d(30000), fromMonth: 202611);
      await budgets.setAmount(id, d(32000), fromMonth: 202611);
      final b = (await budgets.budgets()).single;
      expect(b.changes.length, 2, reason: 'the same month is changed again');
      expect(amountFor(b.changes, 202610), d(25000));
      expect(amountFor(b.changes, 202611), d(32000));
    },
  );

  test('reordered, then deleted', () async {
    final a = await budgets.create(
      categoryId: 'default-food',
      amount: d(1),
      fromMonth: 202611,
    );
    final b = await budgets.create(
      categoryId: 'default-leisure',
      amount: d(1),
      fromMonth: 202611,
    );
    await budgets.reorder([b, a]);
    expect([for (final x in await budgets.budgets()) x.id], [b, a]);
    await budgets.delete(b);
    expect([for (final x in await budgets.budgets()) x.id], [a]);
    // Its category can have a budget again.
    await budgets.create(
      categoryId: 'default-leisure',
      amount: d(2),
      fromMonth: 202611,
    );
    expect((await budgets.budgets()).length, 2);
  });

  test(
    'removing its category deletes the budget (retro, 18 November)',
    () async {
      final categories = CategoryRepository(db);
      final id = await categories.create(
        kind: CategoryKind.out,
        name: 'Voyages',
        icon: 'airplane',
      );
      await budgets.create(categoryId: id, amount: d(5000), fromMonth: 202611);
      expect(await budgets.ofCategory(id), d(5000));
      await categories.remove(id);
      expect(await budgets.budgets(), isEmpty);
      expect(await budgets.ofCategory(id), isNull);
    },
  );
}
