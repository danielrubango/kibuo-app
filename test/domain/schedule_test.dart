import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';

List<DateTime> first(Schedule s, int n) => s.dates().take(n).toList();

void main() {
  test('every 2 days', () {
    final s = Schedule(
      start: DateTime(2026, 11, 30),
      unit: RepeatUnit.day,
      every: 2,
    );
    expect(first(s, 3), [
      DateTime(2026, 11, 30),
      DateTime(2026, 12, 2),
      DateTime(2026, 12, 4),
    ]);
  });

  test('Monday and Thursday, one week in two', () {
    // 16 November 2026 is a Monday.
    final s = Schedule(
      start: DateTime(2026, 11, 16),
      unit: RepeatUnit.week,
      every: 2,
      weekdays: {DateTime.monday, DateTime.thursday},
    );
    expect(first(s, 4), [
      DateTime(2026, 11, 16),
      DateTime(2026, 11, 19),
      DateTime(2026, 11, 30),
      DateTime(2026, 12, 3),
    ]);
  });

  test('a week that starts after the first chosen day skips it', () {
    // Starting on Wednesday 18: Monday 16 is before it.
    final s = Schedule(
      start: DateTime(2026, 11, 18),
      unit: RepeatUnit.week,
      weekdays: {DateTime.monday, DateTime.friday},
    );
    expect(first(s, 3), [
      DateTime(2026, 11, 20),
      DateTime(2026, 11, 23),
      DateTime(2026, 11, 27),
    ]);
  });

  test('the 31st falls on the last day of shorter months, then comes back', () {
    final s = Schedule(start: DateTime(2027, 1, 31), unit: RepeatUnit.month);
    expect(first(s, 4), [
      DateTime(2027, 1, 31),
      DateTime(2027, 2, 28),
      DateTime(2027, 3, 31),
      DateTime(2027, 4, 30),
    ]);
  });

  test('every 3 months, and every year from a 29 February', () {
    expect(
      first(
        Schedule(
          start: DateTime(2026, 11, 8),
          unit: RepeatUnit.month,
          every: 3,
        ),
        3,
      ),
      [DateTime(2026, 11, 8), DateTime(2027, 2, 8), DateTime(2027, 5, 8)],
    );
    expect(
      first(Schedule(start: DateTime(2028, 2, 29), unit: RepeatUnit.year), 3),
      [DateTime(2028, 2, 29), DateTime(2029, 2, 28), DateTime(2030, 2, 28)],
    );
  });

  test('ends after a number of times, or after a date', () {
    expect(
      Schedule(
        start: DateTime(2026, 11, 8),
        unit: RepeatUnit.month,
        count: 3,
      ).dates().toList().length,
      3,
    );
    expect(
      Schedule(
        start: DateTime(2026, 11, 8),
        unit: RepeatUnit.month,
        until: DateTime(2027, 1, 7),
      ).dates().toList(),
      [DateTime(2026, 11, 8), DateTime(2026, 12, 8)],
    );
  });

  test('the dates due by a day, from a given one on', () {
    final s = Schedule(
      start: DateTime(2026, 11, 1),
      unit: RepeatUnit.week,
      weekdays: {DateTime.sunday},
    );
    expect(s.due(from: DateTime(2026, 11, 8), until: DateTime(2026, 11, 22)), [
      DateTime(2026, 11, 8),
      DateTime(2026, 11, 15),
      DateTime(2026, 11, 22),
    ]);
  });
}
