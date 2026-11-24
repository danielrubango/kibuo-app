/// Whole days on the calendar from [from] to [to], whatever the hours and
/// any clock change in between; negative when [to] comes first.
int calendarDays(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
