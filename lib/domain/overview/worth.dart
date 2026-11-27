import 'package:kibuo/domain/overview/overview_period.dart';

/// A change of the worth (or of an account) at a moment, in the main
/// currency.
typedef WorthChange = ({DateTime at, int change});

/// The worth just before each of [moments]: [current] less every change
/// from that moment on (PRODUCT, Patrimoine tab, 27 November 2026).
List<int> worthAt(
  List<DateTime> moments, {
  required int current,
  required Iterable<WorthChange> changes,
}) => [
  for (final m in moments)
    current -
        changes
            .where((c) => !c.at.isBefore(m))
            .fold(0, (sum, c) => sum + c.change),
];

/// What the worth gained over [span]: from its start to now, or to its end
/// for a period gone by.
int worthChange(
  TimeSpan span, {
  required int current,
  required Iterable<WorthChange> changes,
  required DateTime now,
}) {
  final end = span.end.isAfter(now) ? now : span.end;
  final values = worthAt(
    [span.start, end],
    current: current,
    changes: [
      for (final c in changes)
        if (!c.at.isAfter(now)) c,
    ],
  );
  return values[1] - values[0];
}

/// Ahead of [now], the worth at each of [moments] if the [planned]
/// operations happen: [from] (the worth now) plus what is planned from now
/// until that moment.
List<int> projectedAt(
  List<DateTime> moments, {
  required int from,
  required DateTime now,
  required Iterable<WorthChange> planned,
}) => [
  for (final m in moments)
    from +
        planned
            .where((p) => !p.at.isBefore(now) && p.at.isBefore(m))
            .fold(0, (sum, p) => sum + p.change),
];

/// What each account gained or lost over [span], by its id.
Map<String, int> accountChanges(
  TimeSpan span,
  Iterable<({String account, DateTime at, int change})> moves,
) {
  final out = <String, int>{};
  for (final m in moves) {
    if (!span.contains(m.at)) continue;
    out[m.account] = (out[m.account] ?? 0) + m.change;
  }
  return out;
}
