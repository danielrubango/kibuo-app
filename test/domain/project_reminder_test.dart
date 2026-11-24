import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/projects/project_plan.dart';
import 'package:kibuo/domain/projects/project_reminder.dart';

void main() {
  // A Tuesday, at noon.
  final now = DateTime(2026, 11, 24, 12);

  test('each Monday at 9, from the next one', () {
    final times = projectReminderTimes(PlanPeriod.week, now);
    expect(times.first, DateTime(2026, 11, 30, 9));
    expect(times[1], DateTime(2026, 12, 7, 9));
    expect(times.length, 4); // 30 Nov to 21 Dec, within 30 days
  });

  test('a Monday before 9 counts that very day', () {
    final times = projectReminderTimes(
      PlanPeriod.week,
      DateTime(2026, 11, 30, 8),
    );
    expect(times.first, DateTime(2026, 11, 30, 9));
  });

  test('the 1st and the 15th', () {
    final times = projectReminderTimes(PlanPeriod.fortnight, now);
    expect(times, [DateTime(2026, 12, 1, 9), DateTime(2026, 12, 15, 9)]);
  });

  test('the 1st of the month', () {
    final times = projectReminderTimes(PlanPeriod.month, now);
    expect(times, [DateTime(2026, 12, 1, 9)]);
  });

  test('the period a reminder opens: until the next one', () {
    expect(
      reminderPeriodEnd(PlanPeriod.week, DateTime(2026, 11, 30, 9)),
      DateTime(2026, 12, 7),
    );
    expect(
      reminderPeriodEnd(PlanPeriod.fortnight, DateTime(2026, 12, 1, 9)),
      DateTime(2026, 12, 15),
    );
    expect(
      reminderPeriodEnd(PlanPeriod.fortnight, DateTime(2026, 12, 15, 9)),
      DateTime(2027, 1, 1),
    );
    expect(
      reminderPeriodEnd(PlanPeriod.month, DateTime(2026, 12, 1, 9)),
      DateTime(2027, 1, 1),
    );
  });
}
