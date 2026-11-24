import 'package:kibuo/domain/projects/project_plan.dart';

/// When a project's reminder rings over the next [days] (PRODUCT:
/// Projets): at 9, each Monday, the 1st and the 15th, or the 1st.
List<DateTime> projectReminderTimes(
  PlanPeriod period,
  DateTime now, {
  int days = 30,
}) {
  final until = now.add(Duration(days: days));
  final out = <DateTime>[];
  for (
    var day = DateTime(now.year, now.month, now.day);
    !day.isAfter(until);
    day = DateTime(day.year, day.month, day.day + 1)
  ) {
    final rings = switch (period) {
      PlanPeriod.week => day.weekday == DateTime.monday,
      PlanPeriod.fortnight => day.day == 1 || day.day == 15,
      PlanPeriod.month => day.day == 1,
    };
    final at = DateTime(day.year, day.month, day.day, 9);
    if (rings && at.isAfter(now) && !at.isAfter(until)) out.add(at);
  }
  return out;
}

/// The day after the period a reminder at [at] opens.
DateTime reminderPeriodEnd(PlanPeriod period, DateTime at) => switch (period) {
  PlanPeriod.week => DateTime(at.year, at.month, at.day + 7),
  PlanPeriod.fortnight =>
    at.day < 15
        ? DateTime(at.year, at.month, 15)
        : DateTime(at.year, at.month + 1),
  PlanPeriod.month => DateTime(at.year, at.month + 1),
};
