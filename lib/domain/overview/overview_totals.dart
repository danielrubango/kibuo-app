import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';

/// What one operation brings in or takes out, and when (local time).
typedef DatedFlow = ({DateTime at, MoneyFlow flow});

/// The entries and exits of each bar, in the main currency, by the same
/// rule as the month totals of Opérations ([flowTotals]).
List<FlowTotals> totalsByBucket(
  List<TimeSpan> buckets,
  Iterable<DatedFlow> flows,
  CurrencyInfo main,
  ExchangeRate? Function(String code) rateFor,
) {
  final each = [for (final _ in buckets) <MoneyFlow>[]];
  for (final f in flows) {
    final i = _bucketOf(buckets, f.at);
    if (i != null) each[i].add(f.flow);
  }
  return [for (final list in each) flowTotals(main, list, rateFor)];
}

/// The entries and exits within [span], in the main currency.
FlowTotals totalsWithin(
  TimeSpan span,
  Iterable<DatedFlow> flows,
  CurrencyInfo main,
  ExchangeRate? Function(String code) rateFor,
) => flowTotals(main, [
  for (final f in flows)
    if (span.contains(f.at)) f.flow,
], rateFor);

/// The bar [at] falls in, found by halves; null outside them all.
int? _bucketOf(List<TimeSpan> buckets, DateTime at) {
  var low = 0;
  var high = buckets.length - 1;
  while (low <= high) {
    final mid = (low + high) ~/ 2;
    final b = buckets[mid];
    if (at.isBefore(b.start)) {
      high = mid - 1;
    } else if (!at.isBefore(b.end)) {
      low = mid + 1;
    } else {
      return mid;
    }
  }
  return null;
}

/// How a figure moved against the compared period (DIRECTION: « ↗ 33 % »,
/// green when it is a good sign, amber otherwise).
class Change {
  const Change({required this.percent, required this.up, required this.good});

  /// The gap as a share of the compared figure, rounded, never negative.
  final int percent;

  /// The figure is at least the compared one.
  final bool up;

  /// Less spent, or more received.
  final bool good;
}

/// How [value] compares with [compared]; null when there is nothing to
/// compare with. [lessIsBetter] for what goes out.
Change? changeOf(int value, int compared, {required bool lessIsBetter}) {
  if (compared == 0) return null;
  return Change(
    percent: ((value - compared).abs() * 100 / compared.abs()).round(),
    up: value >= compared,
    good: lessIsBetter ? value <= compared : value >= compared,
  );
}
