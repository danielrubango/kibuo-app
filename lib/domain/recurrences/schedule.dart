/// How often a recurrence comes back (PRODUCT: Récurrences).
enum RepeatUnit { day, week, month, year }

/// When a recurrence falls (GLOSSARY: Récurrence): from [start], every
/// [every] days, weeks, months or years; on [weekdays] for a week; until
/// [count] times or [until], or for ever. Days are calendar days.
class Schedule {
  Schedule({
    required DateTime start,
    required this.unit,
    this.every = 1,
    Set<int>? weekdays,
    this.count,
    DateTime? until,
  }) : start = DateTime(start.year, start.month, start.day),
       weekdays = weekdays == null || weekdays.isEmpty
           ? {start.weekday}
           : weekdays,
       until = until == null
           ? null
           : DateTime(until.year, until.month, until.day);

  final DateTime start;
  final RepeatUnit unit;
  final int every;

  /// [DateTime.monday] to [DateTime.sunday], for a week; at least one.
  final Set<int> weekdays;
  final int? count;
  final DateTime? until;

  /// Every date, in order, honouring the end.
  Iterable<DateTime> dates() sync* {
    var made = 0;
    for (final d in _raw()) {
      if (count != null && made >= count!) return;
      if (until != null && d.isAfter(until!)) return;
      made++;
      yield d;
    }
  }

  /// The dates from [from] to [until] (both included).
  List<DateTime> due({required DateTime from, required DateTime until}) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(until.year, until.month, until.day);
    return [
      for (final d in dates().takeWhile((d) => !d.isAfter(b)))
        if (!d.isBefore(a)) d,
    ];
  }

  /// The day [day] of month [month] in [year], or that month's last day.
  static DateTime _clamped(int year, int month, int day) {
    final last = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day > last ? last : day);
  }

  Iterable<DateTime> _raw() sync* {
    switch (unit) {
      case RepeatUnit.day:
        for (var k = 0; ; k++) {
          yield DateTime(start.year, start.month, start.day + k * every);
        }
      case RepeatUnit.week:
        final monday = DateTime(
          start.year,
          start.month,
          start.day - (start.weekday - 1),
        );
        final days = weekdays.toList()..sort();
        for (var k = 0; ; k++) {
          for (final w in days) {
            final d = DateTime(
              monday.year,
              monday.month,
              monday.day + k * 7 * every + (w - 1),
            );
            if (!d.isBefore(start)) yield d;
          }
        }
      case RepeatUnit.month:
        for (var k = 0; ; k++) {
          final m = DateTime(start.year, start.month + k * every);
          yield _clamped(m.year, m.month, start.day);
        }
      case RepeatUnit.year:
        for (var k = 0; ; k++) {
          yield _clamped(start.year + k * every, start.month, start.day);
        }
    }
  }
}
