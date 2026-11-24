import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/calendar.dart';

void main() {
  test('whole days on the calendar, whatever the hours', () {
    expect(
      calendarDays(DateTime(2026, 11, 24, 23, 59), DateTime(2026, 11, 25)),
      1,
    );
    expect(calendarDays(DateTime(2026, 11, 24), DateTime(2026, 11, 24, 18)), 0);
    expect(calendarDays(DateTime(2026, 12, 1), DateTime(2026, 11, 24)), -7);
  });

  test('a clock change in between counts no extra day', () {
    // Spring forward in many places on 29 March 2026.
    expect(calendarDays(DateTime(2026, 3, 28), DateTime(2026, 3, 30)), 2);
    expect(calendarDays(DateTime(2026, 1, 1), DateTime(2027, 1, 1)), 365);
  });
}
