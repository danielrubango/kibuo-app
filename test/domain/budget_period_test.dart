import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';

void main() {
  test('from the 1st, a period is the calendar month', () {
    final p = BudgetPeriod.named(2026, 11, startDay: 1);
    expect(p.first, DateTime(2026, 11));
    expect(p.last, DateTime(2026, 11, 30));
    expect(p.days, 30);
  });

  test('from the 25th, November runs from 25 October to 24 November', () {
    final p = BudgetPeriod.named(2026, 11, startDay: 25);
    expect(p.first, DateTime(2026, 10, 25));
    expect(p.last, DateTime(2026, 11, 24));
    expect(p.days, 31);
  });

  test('January from the 25th starts in December of the year before', () {
    final p = BudgetPeriod.named(2027, 1, startDay: 25);
    expect(p.first, DateTime(2026, 12, 25));
    expect(p.last, DateTime(2027, 1, 24));
  });

  test('the period a day belongs to is named by the month it ends in', () {
    BudgetPeriod at(DateTime d, int start) =>
        BudgetPeriod.containing(d, startDay: start);
    expect(at(DateTime(2026, 11, 24, 23), 25).month, DateTime(2026, 11));
    expect(at(DateTime(2026, 11, 25), 25).month, DateTime(2026, 12));
    expect(at(DateTime(2026, 12, 31), 25).month, DateTime(2027, 1));
    expect(at(DateTime(2026, 11, 30), 1).month, DateTime(2026, 11));
  });

  test('a day is in it from its first morning to its last evening', () {
    final p = BudgetPeriod.named(2026, 11, startDay: 25);
    expect(p.contains(DateTime(2026, 10, 25)), isTrue);
    expect(p.contains(DateTime(2026, 11, 24, 23, 59)), isTrue);
    expect(p.contains(DateTime(2026, 11, 25)), isFalse);
    expect(p.contains(DateTime(2026, 10, 24, 23, 59)), isFalse);
  });

  test('how far into it a day is, that day included', () {
    expect(
      BudgetPeriod.named(2026, 11, startDay: 1).elapsed(DateTime(2026, 11, 11)),
      closeTo(11 / 30, 1e-9),
    );
    expect(
      BudgetPeriod.named(
        2026,
        11,
        startDay: 25,
      ).elapsed(DateTime(2026, 11, 17)),
      closeTo(24 / 31, 1e-9),
    );
  });
}
