/// How a dated project's plan is divided (PRODUCT: Projets).
enum PlanPeriod {
  week('week', 7),
  fortnight('fortnight', 14),
  month('month', 30.4375);

  const PlanPeriod(this.stored, this.days);

  final String stored;

  /// Its length, a month on average.
  final double days;

  static PlanPeriod fromStored(String? value) =>
      values.firstWhere((p) => p.stored == value, orElse: () => week);
}

int _days(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// The periods from [today] to [due], at least one: the last one partly.
int periodsLeft(PlanPeriod period, DateTime today, DateTime due) {
  final days = _days(today, due);
  if (days <= 0) return 1;
  final n = (days / period.days).ceil();
  return n < 1 ? 1 : n;
}

/// What is left to set aside, in equal parts per period, rounded up so the
/// goal is met; none once reached.
int perPeriod({
  required int goal,
  required int saved,
  required DateTime today,
  required DateTime due,
  required PlanPeriod period,
}) {
  final left = goal - saved;
  if (left <= 0) return 0;
  return (left / periodsLeft(period, today, due)).ceil();
}

/// Where a dated project should be today, as a share of its goal: a
/// straight line from its start to its date.
double expectedShare({
  required DateTime today,
  required DateTime start,
  required DateTime due,
}) {
  final total = _days(start, due);
  if (total <= 0) return 1;
  return (_days(start, today) / total).clamp(0, 1).toDouble();
}

/// Ahead (positive) or behind (negative) that line.
int projectGap({
  required int goal,
  required int saved,
  required double share,
}) => saved - (goal * share).round();
