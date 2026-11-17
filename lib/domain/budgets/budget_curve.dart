import 'package:kibuo/domain/transactions/budget_period.dart';

/// One step of « Au fil du mois »: on [day] (0 for the period's first),
/// the total spent so far.
class CurveStep {
  const CurveStep(this.day, this.total);

  final int day;
  final int total;
}

/// The running total of [expenses] (when, how much in minor units) within
/// [period], one step per day that has any.
List<CurveStep> cumulative(
  BudgetPeriod period,
  List<(DateTime, int)> expenses,
) {
  final first = DateTime.utc(
    period.first.year,
    period.first.month,
    period.first.day,
  );
  final byDay = <int, int>{};
  for (final (moment, minor) in expenses) {
    if (!period.contains(moment)) continue;
    final day = DateTime.utc(
      moment.year,
      moment.month,
      moment.day,
    ).difference(first).inDays;
    byDay[day] = (byDay[day] ?? 0) + minor;
  }
  var total = 0;
  return [
    for (final day in byDay.keys.toList()..sort())
      CurveStep(day, total += byDay[day]!),
  ];
}

/// How far [spent] is from the regular pace at [elapsed] of the period:
/// above it (ahead, « d'avance ») when positive.
int paceGap({
  required int spent,
  required int amount,
  required double elapsed,
}) => spent - (amount * elapsed).round();
