import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/reminders/entry_reminder.dart';

void main() {
  test('every day at its time, from today if still to come', () {
    final times = entryReminderTimes(
      now: DateTime(2026, 11, 19, 10),
      minuteOfDay: 20 * 60,
      notedToday: false,
      days: 3,
    );
    expect(times, [
      DateTime(2026, 11, 19, 20),
      DateTime(2026, 11, 20, 20),
      DateTime(2026, 11, 21, 20),
    ]);
  });

  test('not today once something was noted, nor once its time passed', () {
    expect(
      entryReminderTimes(
        now: DateTime(2026, 11, 19, 10),
        minuteOfDay: 20 * 60,
        notedToday: true,
        days: 2,
      ),
      [DateTime(2026, 11, 20, 20), DateTime(2026, 11, 21, 20)],
    );
    expect(
      entryReminderTimes(
        now: DateTime(2026, 11, 19, 21),
        minuteOfDay: 20 * 60 + 30,
        notedToday: false,
        days: 1,
      ),
      [DateTime(2026, 11, 20, 20, 30)],
    );
  });

  test('when an operation was noted: read from its id', () {
    // A UUID v7 starts with its creation time, in milliseconds.
    final at = DateTime.utc(2026, 11, 19, 8, 30);
    final hex = at.millisecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8)}-7abc-8def-0123456789ab';
    expect(notedAt(id), at);
    expect(notedAt('default-food'), isNull);
  });
}
