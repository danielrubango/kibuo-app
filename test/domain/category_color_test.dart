import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/categories/category_color.dart';

/// The colours categories start with (PRODUCT « Couleur des catégories »,
/// ADR 0014, 27 November 2026).
void main() {
  StartCategory cat(
    String id, {
    String kind = 'out',
    String? key,
    String? parent,
    int position = 1,
    CategoryColor? color,
  }) => (
    id: id,
    kind: kind,
    key: key,
    parentId: parent,
    position: position,
    color: color,
  );

  test('a provided category takes its own colour', () {
    final colors = startColors([
      cat('default-housing', key: 'housing'),
      cat('default-groceries', key: 'groceries', position: 2),
      cat('default-food', key: 'food', position: 3),
      cat('default-transport', key: 'transport', position: 4),
      cat('default-otherExpense', key: 'otherExpense', position: 5),
      cat('default-salary', kind: 'in', key: 'salary'),
      cat('default-giftReceived', kind: 'in', key: 'giftReceived', position: 2),
      cat('default-otherIncome', kind: 'in', key: 'otherIncome', position: 3),
    ]);
    expect(colors['default-housing'], CategoryColor.peach);
    expect(colors['default-groceries'], CategoryColor.apricot);
    expect(colors['default-food'], CategoryColor.rose);
    expect(colors['default-transport'], CategoryColor.blue);
    expect(colors['default-otherExpense'], CategoryColor.grey);
    expect(colors['default-salary'], CategoryColor.mint);
    expect(colors['default-giftReceived'], CategoryColor.rose);
    expect(colors['default-otherIncome'], CategoryColor.grey);
  });

  test('debts, receivables and adjustments stay grey', () {
    final colors = startColors([
      cat('default-debtOut', key: 'debtOut'),
      cat('default-receivableIn', kind: 'in', key: 'receivableIn'),
      cat('default-adjustExpense', key: 'adjustExpense'),
    ]);
    expect(colors.values, everyElement(CategoryColor.grey));
  });

  test("the user's own categories take the least used colour, in order", () {
    final colors = startColors([
      cat('default-housing', key: 'housing'),
      cat('default-food', key: 'food', position: 2),
      cat('mine-2', position: 4),
      cat('mine-1', position: 3),
    ]);
    // Pêche and Rose are taken: Abricot, then Sable, in palette order.
    expect(colors['mine-1'], CategoryColor.apricot);
    expect(colors['mine-2'], CategoryColor.sand);
  });

  test('each list counts its own colours', () {
    final colors = startColors([
      cat('default-salary', kind: 'in', key: 'salary'),
      cat('mine-out'),
      cat('mine-in', kind: 'in', position: 2),
    ]);
    // Menthe is used among income only.
    expect(colors['mine-out'], CategoryColor.peach);
    expect(colors['mine-in'], CategoryColor.peach);
  });

  test('once every colour is used, the least used comes back first', () {
    final mine = [for (var i = 0; i < 11; i++) cat('mine-$i', position: i + 1)];
    final colors = startColors(mine);
    expect(colors['mine-9'], CategoryColor.green);
    expect(colors['mine-10'], CategoryColor.peach);
  });

  test('a subcategory has no colour of its own', () {
    final colors = startColors([
      cat('default-food', key: 'food'),
      cat('default-restaurant', key: 'restaurant', parent: 'default-food'),
      cat('mine-sub', parent: 'default-food', position: 2),
    ]);
    expect(colors.containsKey('default-restaurant'), isFalse);
    expect(colors.containsKey('mine-sub'), isFalse);
  });

  test('a colour already set is kept and counted', () {
    final colors = startColors([
      cat('mine-1', color: CategoryColor.peach),
      cat('mine-2', position: 2),
    ]);
    expect(colors['mine-1'], CategoryColor.peach);
    expect(colors['mine-2'], CategoryColor.apricot);
  });

  test('a new category takes the least used colour of its list', () {
    expect(
      leastUsed([CategoryColor.peach, CategoryColor.apricot]),
      CategoryColor.sand,
    );
    // Grey is never handed out, and does not count.
    expect(leastUsed([CategoryColor.grey]), CategoryColor.peach);
  });

  test('the stored name reads back, and an unknown one reads as none', () {
    for (final c in CategoryColor.values) {
      expect(CategoryColor.named(c.name), c);
    }
    expect(CategoryColor.named('purple'), isNull);
    expect(CategoryColor.named(null), isNull);
  });
}
