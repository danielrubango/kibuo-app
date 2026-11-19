/// A budget's threshold crossed (PRODUCT: Alertes de budget).
class Crossing {
  const Crossing({
    required this.budgetId,
    required this.threshold,
    required this.percent,
    required this.month,
  });

  final String budgetId;

  /// 80 or 100.
  final int threshold;

  /// Spent as a share of the amount, rounded.
  final int percent;

  /// The period's key (year × 100 + month).
  final int month;

  /// Said once a month: this key is kept once alerted.
  String get key => 'budget:$budgetId:$month:$threshold';

  /// What saying it settles: past 100, the 80 is said too.
  List<String> get covers => [
    for (final t in [80, 100])
      if (t <= threshold) 'budget:$budgetId:$month:$t',
  ];
}

/// The thresholds [budgets] have crossed in [month] and that were not
/// alerted yet; for one budget past both, only the highest.
List<Crossing> crossings({
  required int month,
  required Map<String, ({int spent, int amount})> budgets,
  required Set<String> alerted,
  bool at80 = true,
  bool at100 = true,
}) {
  final found = <Crossing>[];
  for (final MapEntry(key: id, value: b) in budgets.entries) {
    if (b.amount <= 0) continue;
    final percent = (b.spent * 100 / b.amount).round();
    for (final threshold in [100, 80]) {
      final on = threshold == 100 ? at100 : at80;
      final reached = threshold == 100
          ? b.spent >= b.amount
          : b.spent * 100 >= b.amount * 80;
      final crossing = Crossing(
        budgetId: id,
        threshold: threshold,
        percent: percent,
        month: month,
      );
      if (!on || !reached || alerted.contains(crossing.key)) continue;
      found.add(crossing);
      break;
    }
  }
  return found;
}

/// The one to say: the most used budget.
Crossing? mostTouched(List<Crossing> crossed) {
  Crossing? best;
  for (final c in crossed) {
    if (best == null || c.percent > best.percent) best = c;
  }
  return best;
}
