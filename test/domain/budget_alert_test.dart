import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/budgets/budget_alert.dart';

void main() {
  const month = 202611;

  test('the thresholds crossed, not yet alerted this month', () {
    final crossed = crossings(
      month: month,
      budgets: {
        'repas': (spent: 8500, amount: 10000),
        'taxi': (spent: 2000, amount: 10000),
      },
      alerted: const {},
    );
    expect([for (final c in crossed) c.key], ['budget:repas:202611:80']);
  });

  test('over: both thresholds, and the 100 is the one to say', () {
    final crossed = crossings(
      month: month,
      budgets: {'repas': (spent: 10400, amount: 10000)},
      alerted: const {'budget:repas:202611:80'},
    );
    expect([for (final c in crossed) c.threshold], [100]);
    expect(crossed.single.percent, 104);
  });

  test('a switch off leaves its threshold out', () {
    expect(
      crossings(
        month: month,
        budgets: {'repas': (spent: 8500, amount: 10000)},
        alerted: const {},
        at80: false,
      ),
      isEmpty,
    );
  });

  test('the most touched one is said', () {
    final crossed = crossings(
      month: month,
      budgets: {
        'repas': (spent: 8500, amount: 10000),
        'taxi': (spent: 12000, amount: 10000),
      },
      alerted: const {},
    );
    expect(mostTouched(crossed)!.budgetId, 'taxi');
    expect(mostTouched(const []), isNull);
  });

  test('saying the 100 settles the 80 too', () {
    const c = Crossing(budgetId: 'r', threshold: 100, percent: 104, month: 1);
    expect(c.covers, ['budget:r:1:80', 'budget:r:1:100']);
  });
}
