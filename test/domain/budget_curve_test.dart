import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/budgets/budget_curve.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';

void main() {
  final november = BudgetPeriod.named(2026, 11, startDay: 1);

  test('the total climbs once a day, in day order', () {
    final steps = cumulative(november, [
      (DateTime(2026, 11, 9, 20), 3000),
      (DateTime(2026, 11, 2, 10), 4000),
      (DateTime(2026, 11, 6, 9), 2200),
      (DateTime(2026, 11, 6, 18), 1200),
    ]);
    expect([for (final s in steps) s.day], [1, 5, 8]);
    expect([for (final s in steps) s.total], [4000, 7400, 10400]);
  });

  test('outside the period: left out', () {
    expect(cumulative(november, [(DateTime(2026, 10, 31), 500)]), isEmpty);
  });

  test('ahead of or behind the regular pace, on a day', () {
    // 104 $ spent on the 11th of 30, for 100 $: 104 − 36,67 = +67,33.
    expect(paceGap(spent: 10400, amount: 10000, elapsed: 11 / 30), 6733);
    expect(paceGap(spent: 2000, amount: 10000, elapsed: 0.5), -3000);
  });
}
