import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late CategoryRepository repo;

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    repo = CategoryRepository(db);
  });
  tearDown(() => db.close());

  test(
    'the provided categories come once, in order, with subcategories',
    () async {
      final out = await repo.categories(CategoryKind.out);
      expect(
        [for (final c in out) c.key],
        [
          'food',
          'transport',
          'groceries',
          'housing',
          'communication',
          'health',
          'school',
          'family',
          'outings',
          'contributions',
          'otherExpense',
          'adjustExpense',
        ],
      );
      final transport = out[1];
      expect(
        [for (final s in transport.subs) s.key],
        ['taxi', 'motoTaxi', 'bus', 'fuel', 'toll'],
      );
      expect(transport.name, isNull, reason: 'named by the app’s language');

      await repo.categories(CategoryKind.out);
      expect(await repo.categories(CategoryKind.out), hasLength(12));
      expect(
        [for (final c in await repo.categories(CategoryKind.into)) c.key],
        [
          'salary',
          'business',
          'giftReceived',
          'refund',
          'otherIncome',
          'adjustIncome',
        ],
      );
    },
  );

  test('a renamed category keeps its new name', () async {
    final food = (await repo.categories(CategoryKind.out)).first;
    await repo.update(food.id, name: ' Nourriture ', icon: 'basket');

    final again = (await repo.categories(CategoryKind.out)).first;
    expect(again.name, 'Nourriture');
    expect(again.icon, 'basket');
  });

  test('a new category goes last, a subcategory under its parent', () async {
    final id = await repo.create(
      kind: CategoryKind.out,
      name: 'Église',
      icon: 'church',
    );
    final transport = (await repo.categories(CategoryKind.out))[1];
    await repo.create(
      kind: CategoryKind.out,
      name: 'Train',
      icon: 'bus',
      parentId: transport.id,
    );

    final out = await repo.categories(CategoryKind.out);
    expect(out.last.id, id);
    expect(out.last.name, 'Église');
    expect(out[1].subs.last.name, 'Train');
  });

  test('a name is required', () async {
    expect(
      () => repo.create(kind: CategoryKind.into, name: ' ', icon: 'tag'),
      throwsArgumentError,
    );
  });

  test('removing a category removes its subcategories too', () async {
    final transport = (await repo.categories(CategoryKind.out))[1];
    await repo.remove(transport.id);

    final out = await repo.categories(CategoryKind.out);
    expect([for (final c in out) c.key], isNot(contains('transport')));
    expect(
      await repo.category(transport.subs.first.id),
      isNotNull,
      reason: 'old operations keep it',
    );
    expect((await repo.category(transport.subs.first.id))!.removed, isTrue);
  });

  test('removed provided categories never come back', () async {
    for (final c in await repo.categories(CategoryKind.into)) {
      await repo.remove(c.id);
    }
    expect(await repo.categories(CategoryKind.into), isEmpty);
    expect(await repo.categories(CategoryKind.into), isEmpty);
  });

  test('a provided category can be read before the lists are', () async {
    expect((await repo.category('default-taxi'))!.key, 'taxi');
  });

  test('« Régularisation » closes both lists, even for older data', () async {
    final out = await repo.categories(CategoryKind.out);
    final into = await repo.categories(CategoryKind.into);
    expect(out.last.id, adjustmentCategoryId(CategoryKind.out));
    expect(into.last.id, adjustmentCategoryId(CategoryKind.into));
    expect(out.last.key, 'adjustExpense');

    // Data seeded before it existed gets it once, at the end.
    await (db.delete(
      db.categories,
    )..where((c) => c.key.isIn(['adjustExpense', 'adjustIncome']))).go();
    await (db.delete(
      db.preferences,
    )..where((p) => p.name.equals('categories_adjust_seeded'))).go();
    final again = CategoryRepository(db);
    final out2 = await again.categories(CategoryKind.out);
    expect(out2.last.key, 'adjustExpense');
    expect(out2.where((c) => c.key == 'adjustExpense'), hasLength(1));
  });
}
