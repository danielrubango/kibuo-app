import 'package:kibuo/domain/accounts/overdraft.dart';

/// When to remind of a date [due] [daysBefore] days ahead: at 9:00 that
/// day (PRODUCT: Rappels).
DateTime reminderAt(DateTime due, int daysBefore) =>
    DateTime(due.year, due.month, due.day - daysBefore, 9);

/// A planned operation's effect on accounts, by account id, in each
/// account's minor unit: negative going out.
class PlannedMove {
  const PlannedMove({
    required this.key,
    required this.day,
    required this.changes,
  });

  final String key;
  final DateTime day;
  final Map<String, int> changes;
}

/// What each planned operation would leave missing on its account, by
/// [PlannedMove.key], given today's [balances] and floors and everything
/// planned before it (PRODUCT: solde insuffisant). Only the short ones.
Map<String, int> shortfalls({
  required Map<String, (int, Overdraft)> balances,
  required List<PlannedMove> moves,
}) {
  final running = {for (final e in balances.entries) e.key: e.value.$1};
  final sorted = [...moves]..sort((a, b) => a.day.compareTo(b.day));
  final missing = <String, int>{};
  for (final move in sorted) {
    var worst = 0;
    for (final MapEntry(key: account, value: change) in move.changes.entries) {
      final before = running[account];
      final floor = balances[account]?.$2;
      if (before == null || floor == null) continue;
      final after = before + change;
      running[account] = after;
      if (change >= 0 || floor.allows(after)) continue;
      final room = floor.available(before) ?? 0;
      final short = -change - (room < 0 ? 0 : room);
      if (short > worst) worst = short;
    }
    if (worst > 0) missing[move.key] = worst;
  }
  return missing;
}
