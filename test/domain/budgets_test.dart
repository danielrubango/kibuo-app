import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

void main() {
  final usd = currencyOf('USD');
  final cdf = currencyOf('CDF');
  ExchangeRate rate(String value) =>
      ExchangeRate(base: 'USD', quote: 'CDF', value: RateValue.parse(value));
  Money d(int minor) => Money(minor, 'USD');

  group('the amount for a period', () {
    final changes = [
      AmountChange(202609, d(10000)),
      AmountChange(202611, d(15000)),
    ];
    test('the last change made before or at it', () {
      expect(amountFor(changes, 202611), d(15000));
      expect(amountFor(changes, 202612), d(15000));
      expect(
        amountFor(changes, 202610),
        d(10000),
        reason: 'months keep theirs',
      );
      expect(amountFor(changes, 202608), isNull, reason: 'before it existed');
    });
    test('the order changes were made in does not matter', () {
      expect(amountFor(changes.reversed.toList(), 202610), d(10000));
    });
  });

  group('what an expense takes from its budget, in the main currency', () {
    ExchangeRate? none(String _) => null;
    test('in the main currency: its total, fees in', () {
      expect(
        expenseInMain(
          total: d(1050),
          paid: d(1000),
          frozen: null,
          main: usd,
          rateFor: none,
        ),
        d(1050),
      );
    });

    test('paid in the main currency from another account: frozen', () {
      // 10 $ paid from a franc account at 1 $ = 2 800 FC, 280 FC of fees.
      final frozen = rate('2800');
      expect(
        expenseInMain(
          total: Money.fromMajor('28280', cdf),
          paid: d(1000),
          frozen: frozen,
          main: usd,
          rateFor: (_) => rate('3000'),
        ),
        d(1010),
      );
    });

    test('otherwise at the rate of the day, or nothing without one', () {
      final today = rate('2500');
      expect(
        expenseInMain(
          total: Money.fromMajor('5000', cdf),
          paid: Money.fromMajor('5000', cdf),
          frozen: null,
          main: usd,
          rateFor: (_) => today,
        ),
        d(200),
      );
      expect(
        expenseInMain(
          total: Money.fromMajor('5000', cdf),
          paid: Money.fromMajor('5000', cdf),
          frozen: null,
          main: usd,
          rateFor: none,
        ),
        isNull,
      );
    });
  });

  group('a budget in a period', () {
    test('what is left, the share and the state', () {
      final ok = BudgetStatus(amount: d(10000), spent: d(4000));
      expect(ok.left, d(6000));
      expect(ok.percent, 40);
      expect(ok.state, BudgetState.ok);
      expect(
        BudgetStatus(amount: d(25000), spent: d(20500)).state,
        BudgetState.near,
      );
      expect(
        BudgetStatus(amount: d(10000), spent: d(10000)).state,
        BudgetState.near,
        reason: 'reached, not over',
      );
      final over = BudgetStatus(amount: d(10000), spent: d(10400));
      expect(over.state, BudgetState.over);
      expect(over.left, d(-400));
      expect(over.percent, 104);
    });
  });

  test('« À surveiller »: the most used first, then by name', () {
    final rows = [
      ('Santé', BudgetStatus(amount: d(10000), spent: d(4000))),
      ('Loisirs', BudgetStatus(amount: d(10000), spent: d(10400))),
      ('Courses', BudgetStatus(amount: d(20000), spent: d(8000))),
      ('Repas', BudgetStatus(amount: d(25000), spent: d(20500))),
    ];
    rows.sort((a, b) => watchOrder(a.$2, a.$1, b.$2, b.$1));
    expect(
      [for (final r in rows) r.$1],
      ['Loisirs', 'Repas', 'Courses', 'Santé'],
    );
  });

  group('the average offered at creation', () {
    test('the finished periods, at most the last three', () {
      expect(averageOf([d(9000), d(10000), d(11000)]), d(10000));
      expect(averageOf([d(9000), d(10000)]), d(9500));
    });
    test('nothing without any expense', () {
      expect(averageOf([]), isNull);
      expect(averageOf([d(0), d(0)]), isNull);
    });
  });
}
