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

/// The periods from [today] to [due], at least one: the last one stretches
/// or shrinks to end the day before [due] (« avant le 1er janvier »).
int periodsLeft(PlanPeriod period, DateTime today, DateTime due) {
  final days = _days(today, due);
  if (days <= 0) return 1;
  final n = (days / period.days).round();
  return n < 1 ? 1 : n;
}

/// One period of the plan: its days, both included, and what to set aside.
class PlanPart {
  const PlanPart({
    required this.start,
    required this.end,
    required this.amount,
  });

  final DateTime start;
  final DateTime end;
  final int amount;
}

int _roundUp(int value, int unit) =>
    unit <= 1 ? value : (value + unit - 1) ~/ unit * unit;

/// What is left to set aside, in equal parts per period rounded up to
/// [unit] (a whole dollar is 100), so the goal is met; none once reached.
int perPeriod({
  required int goal,
  required int saved,
  required DateTime today,
  required DateTime due,
  required PlanPeriod period,
  int unit = 1,
}) {
  final left = goal - saved;
  if (left <= 0) return 0;
  return _roundUp((left / periodsLeft(period, today, due)).ceil(), unit);
}

/// The plan, from the period running [today] to the day before [due]:
/// each part [perPeriod], the last one what is left (PRODUCT: Projets).
List<PlanPart> planParts({
  required int goal,
  required int saved,
  required DateTime today,
  required DateTime due,
  required PlanPeriod period,
  int unit = 1,
}) {
  final per = perPeriod(
    goal: goal,
    saved: saved,
    today: today,
    due: due,
    period: period,
    unit: unit,
  );
  if (per <= 0) return const [];
  final n = periodsLeft(period, today, due);
  final first = DateTime(today.year, today.month, today.day);
  final lastDay = DateTime(due.year, due.month, due.day - 1);
  DateTime startOf(int i) => switch (period) {
    PlanPeriod.month => DateTime(first.year, first.month + i, first.day),
    _ => DateTime(first.year, first.month, first.day + i * period.days.round()),
  };
  var rest = goal - saved;
  final parts = <PlanPart>[];
  for (var i = 0; i < n; i++) {
    final start = startOf(i);
    final next = startOf(i + 1);
    final end = i == n - 1
        ? (lastDay.isBefore(start) ? start : lastDay)
        : DateTime(next.year, next.month, next.day - 1);
    final amount = i == n - 1 ? rest : (per < rest ? per : rest);
    rest -= amount;
    parts.add(PlanPart(start: start, end: end, amount: amount));
  }
  return parts;
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
