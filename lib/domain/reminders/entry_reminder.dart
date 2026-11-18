/// When to remind the user to note their operations (PRODUCT: Rappels):
/// every day at [minuteOfDay] for [days] days, starting today unless
/// something was already noted or the time has passed.
List<DateTime> entryReminderTimes({
  required DateTime now,
  required int minuteOfDay,
  required bool notedToday,
  int days = 30,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final times = <DateTime>[];
  for (var d = 0; times.length < days; d++) {
    final at = DateTime(
      today.year,
      today.month,
      today.day + d,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (d == 0 && (notedToday || !at.isAfter(now))) continue;
    times.add(at);
  }
  return times;
}

/// When an operation was noted: a UUID v7 starts with its creation time in
/// milliseconds. Null for any other id.
DateTime? notedAt(String id) {
  final parts = id.split('-');
  if (parts.length != 5 || parts[0].length != 8 || parts[1].length != 4) {
    return null;
  }
  if (!parts[2].startsWith('7')) return null;
  final ms = int.tryParse('${parts[0]}${parts[1]}', radix: 16);
  return ms == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
}
