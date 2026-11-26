import 'package:kibuo/domain/calendar.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';

/// The periods of the Aperçu's « Période » sheet (canvas ApercuP2Ouvert),
/// in their order.
enum PeriodKind {
  today,
  yesterday,
  last24Hours,
  last7Days,
  month,
  year,
  custom,
}

/// « Regrouper par »: what one bar of the chart holds.
enum Grouping { hour, day, week, month }

/// « Comparer à »: the period before, the one after, the current one, or
/// none (PRODUCT, Aperçu).
enum Comparison { previous, next, current, none }

/// A stretch of time, from [start] to [end], [end] excluded.
class TimeSpan {
  const TimeSpan(this.start, this.end);

  /// Whole days, from [first] to [last], both included.
  TimeSpan.days(DateTime first, DateTime last)
    : start = _day(first),
      end = DateTime(last.year, last.month, last.day + 1);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  /// Its calendar days, the last one included when it ends at midnight.
  int get days => calendarDays(start, end);

  /// The day it ends on, for a span of whole days.
  DateTime get lastDay => DateTime(end.year, end.month, end.day - 1);

  /// The same length, [days] later (earlier when negative).
  TimeSpan movedBy(int days) => TimeSpan(
    DateTime(start.year, start.month, start.day + days, start.hour),
    DateTime(end.year, end.month, end.day + days, end.hour),
  );

  @override
  bool operator ==(Object other) =>
      other is TimeSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'TimeSpan($start, $end)';
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// The period of [kind] that [offset] steps back from the one around [now]
/// (0 is the current one, −1 the one before). Months and years follow the
/// month start day, as Opérations and Budgets do; a [custom] period steps
/// by its own length.
TimeSpan periodSpan(
  PeriodKind kind, {
  required DateTime now,
  int offset = 0,
  int startDay = 1,
  TimeSpan? custom,
}) {
  final today = _day(now);
  switch (kind) {
    case PeriodKind.today:
      return TimeSpan.days(today, today).movedBy(offset);
    case PeriodKind.yesterday:
      return TimeSpan.days(today, today).movedBy(offset - 1);
    case PeriodKind.last24Hours:
      // The current hour is the last bar.
      final end = DateTime(now.year, now.month, now.day, now.hour + 1);
      return TimeSpan(
        DateTime(end.year, end.month, end.day - 1, end.hour),
        end,
      ).movedBy(offset);
    case PeriodKind.last7Days:
      return TimeSpan.days(
        DateTime(today.year, today.month, today.day - 6),
        today,
      ).movedBy(offset * 7);
    case PeriodKind.month:
      final named = BudgetPeriod.containing(today, startDay: startDay).month;
      final period = BudgetPeriod.named(
        named.year,
        named.month + offset,
        startDay: startDay,
      );
      return TimeSpan.days(period.first, period.last);
    case PeriodKind.year:
      final year =
          BudgetPeriod.containing(today, startDay: startDay).month.year +
          offset;
      return TimeSpan(
        BudgetPeriod.named(year, 1, startDay: startDay).first,
        BudgetPeriod.named(year + 1, 1, startDay: startDay).first,
      );
    case PeriodKind.custom:
      final chosen = custom ?? TimeSpan.days(today, today);
      return chosen.movedBy(offset * chosen.days);
  }
}

/// What « Regrouper par » offers for a period, the default first. A custom
/// period offers what fits its length: days up to about three months,
/// weeks from two weeks to a year, months from a month and a half.
List<Grouping> groupingsFor(PeriodKind kind, TimeSpan span) => switch (kind) {
  PeriodKind.today ||
  PeriodKind.yesterday ||
  PeriodKind.last24Hours => const [Grouping.hour],
  PeriodKind.last7Days => const [Grouping.day],
  PeriodKind.month => const [Grouping.day, Grouping.week],
  PeriodKind.year => const [Grouping.month, Grouping.week],
  PeriodKind.custom => [
    if (span.days <= 92) Grouping.day,
    if (span.days >= 14 && span.days <= 371) Grouping.week,
    if (span.days >= 45) Grouping.month,
  ],
};

/// The bars of [span] grouped by [grouping], end to end. Weeks are 7 days
/// from the first day, so the same week of two periods compares; the last
/// one is shorter. Months are budget months, cut at the span's ends.
List<TimeSpan> bucketsOf(TimeSpan span, Grouping grouping, {int startDay = 1}) {
  final bars = <TimeSpan>[];
  var start = span.start;
  while (start.isBefore(span.end)) {
    var end = switch (grouping) {
      // Real hours: a day the clock changes has 23 or 25.
      Grouping.hour => start.add(const Duration(hours: 1)),
      Grouping.day => DateTime(start.year, start.month, start.day + 1),
      Grouping.week => DateTime(start.year, start.month, start.day + 7),
      Grouping.month => () {
        final p = BudgetPeriod.containing(start, startDay: startDay);
        return DateTime(p.last.year, p.last.month, p.last.day + 1);
      }(),
    };
    if (end.isAfter(span.end)) end = span.end;
    bars.add(TimeSpan(start, end));
    start = end;
  }
  return bars;
}

/// Whether « Comparer à » can offer [comparison]: the period after and the
/// current one only exist for a past period.
bool comparisonOpen(Comparison comparison, {required int offset}) =>
    switch (comparison) {
      Comparison.next || Comparison.current => offset < 0,
      Comparison.previous || Comparison.none => true,
    };

/// The offset of the compared period, or null without comparison.
int? comparedOffset(Comparison comparison, {required int offset}) =>
    switch (comparison) {
      Comparison.previous => offset - 1,
      Comparison.next => offset + 1,
      Comparison.current => 0,
      Comparison.none => null,
    };

/// Where the compared period stops counting (PRODUCT, 27 November 2026): a
/// period in progress is compared up to the same date, or the same hour
/// when its bars are hours (1 to 12 November against 1 to 12 October); a
/// past period with the whole compared period.
DateTime comparedUntil({
  required TimeSpan current,
  required TimeSpan compared,
  required DateTime now,
  required Grouping grouping,
}) {
  if (!current.contains(now)) return compared.end;
  final DateTime until;
  if (grouping == Grouping.hour) {
    final hours = now.difference(current.start).inHours + 1;
    until = compared.start.add(Duration(hours: hours));
  } else {
    final days = calendarDays(current.start, now) + 1;
    final s = compared.start;
    until = DateTime(s.year, s.month, s.day + days);
  }
  return until.isAfter(compared.end) ? compared.end : until;
}
