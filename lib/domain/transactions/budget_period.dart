import 'package:kibuo/domain/calendar.dart';

/// A month that starts on the chosen day (GLOSSARY: Période budgétaire),
/// named after the month it ends in: from the 25th, November runs from
/// 25 October to 24 November.
class BudgetPeriod {
  BudgetPeriod._(this.month, this.first, this._next);

  /// The period named [year] and [month].
  factory BudgetPeriod.named(int year, int month, {required int startDay}) {
    if (startDay <= 1) {
      return BudgetPeriod._(
        DateTime(year, month),
        DateTime(year, month),
        DateTime(year, month + 1),
      );
    }
    return BudgetPeriod._(
      DateTime(year, month),
      DateTime(year, month - 1, startDay),
      DateTime(year, month, startDay),
    );
  }

  /// The period [day] belongs to.
  factory BudgetPeriod.containing(DateTime day, {required int startDay}) {
    final ahead = startDay > 1 && day.day >= startDay;
    final month = DateTime(day.year, day.month + (ahead ? 1 : 0));
    return BudgetPeriod.named(month.year, month.month, startDay: startDay);
  }

  /// Its name: the year and month it ends in.
  final DateTime month;

  /// Its first day.
  final DateTime first;

  /// The first day of the next period.
  final DateTime _next;

  /// Its last day.
  DateTime get last => DateTime(_next.year, _next.month, _next.day - 1);

  int get days => calendarDays(first, _next);

  bool contains(DateTime moment) =>
      !moment.isBefore(first) && moment.isBefore(_next);

  /// How far into it [day] is, that day included.
  double elapsed(DateTime day) {
    final done = calendarDays(first, day);
    return ((done + 1) / days).clamp(0, 1).toDouble();
  }
}
