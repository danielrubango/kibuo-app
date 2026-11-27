import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/overview/category_lines.dart';
import 'package:kibuo/domain/overview/followed.dart';
import 'package:kibuo/domain/overview/overview_period.dart';

/// The lines of the Aperçu's Catégories tab add up to the period's total
/// (PRODUCT, 27 November 2026).
void main() {
  final usd = currencyOf('USD');
  final rate = ExchangeRate(
    base: 'USD',
    quote: 'CDF',
    value: RateValue.parse('2800'),
  );
  ExchangeRate? rateFor(String code) => code == 'CDF' ? rate : null;
  final november = TimeSpan.days(DateTime(2026, 11, 1), DateTime(2026, 11, 30));
  final day = DateTime(2026, 11, 12, 10);

  CategorySpend spend(String category, int minor, [String code = 'USD']) =>
      (at: day, category: category, amount: Money(minor, code));
  const parents = {'restaurant': 'food', 'market': 'food'};
  String parentOf(String id) => parents[id] ?? id;
  bool isDebt(String id) =>
      id.startsWith('debt') || id.startsWith('receivable');

  List<CategoryLine> linesOf(
    List<CategorySpend> spends,
    int total, {
    bool fees = true,
  }) => categoryLines(
    november,
    spends,
    parentOf: parentOf,
    isDebt: isDebt,
    total: total,
    withFees: fees,
    main: usd,
    rateFor: rateFor,
  );

  test('a subcategory counts in its category, the most first', () {
    final lines = linesOf([
      spend('restaurant', 2400),
      spend('market', 1400),
      spend('housing', 13100),
    ], 16900);
    expect(
      [for (final l in lines) (l.category, l.amount)],
      [('housing', 13100), ('food', 3800)],
    );
    expect([for (final l in lines) l.share], [78, 22]);
  });

  test('debts and receivables make one line', () {
    final lines = linesOf([
      spend('debtOut', 1000),
      spend('receivableOut', 2000),
      spend('food', 500),
    ], 3500);
    expect(lines.first.kind, CategoryLineKind.debts);
    expect(lines.first.amount, 3000);
    expect(lines.first.category, isNull);
  });

  test('what no category explains goes in the transfer fees', () {
    // 502 $ out: 500 $ of taxi and 2 $ of a transfer's fees.
    final lines = linesOf([spend('transport', 50000)], 50200);
    expect(lines.last.kind, CategoryLineKind.fees);
    expect(lines.last.amount, 200);
    expect(lines.fold(0, (a, l) => a + l.amount), 50200);
  });

  test('money in has no fees line', () {
    final lines = linesOf([spend('salary', 120000)], 120000, fees: false);
    expect(lines.single.kind, CategoryLineKind.category);
  });

  test('amounts in another currency count at the rate', () {
    // 28 000 FC at 2 800 FC for 1 $.
    final lines = linesOf([spend('food', 2800000, 'CDF')], 1000);
    expect(lines.single.amount, 1000);
  });

  test('outside the period, nothing counts', () {
    final lines = linesOf([
      (
        at: DateTime(2026, 10, 31, 23),
        category: 'food',
        amount: Money(900, 'USD'),
      ),
    ], 0);
    expect(lines, isEmpty);
  });

  test('up to five lines all show; beyond, four and the rest', () {
    CategoryLine line(int amount) => (
      kind: CategoryLineKind.category,
      category: 'c$amount',
      amount: amount,
      share: 0,
    );
    final five = [for (var i = 5; i >= 1; i--) line(i)];
    expect(splitLines(five).shown.length, 5);
    expect(splitLines(five).rest, isEmpty);
    final six = [for (var i = 6; i >= 1; i--) line(i)];
    final split = splitLines(six);
    expect(split.shown.length, 4);
    expect([for (final l in split.rest) l.amount], [2, 1]);
  });
}
