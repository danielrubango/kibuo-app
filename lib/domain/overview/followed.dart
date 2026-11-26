import 'package:kibuo/domain/calendar.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/overview/overview_totals.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';

/// The tiles of « Points suivis », in the order of the « Suivre » sheet:
/// Argent, Repères, Engagements, Patrimoine (PRODUCT, 27 November 2026).
enum Followed {
  spent,
  received,
  savings,
  average,
  topCategory,
  priciest,
  upcoming,
  budget,
  debts,
  receivables,
  project,
  accounts,
  netWorth,
}

/// The tiles on at first (PRODUCT, 27 November 2026).
const followedAtFirst = {
  Followed.spent,
  Followed.received,
  Followed.topCategory,
  Followed.budget,
  Followed.debts,
  Followed.receivables,
  Followed.project,
  Followed.accounts,
};

/// How a tile reads a period: a day, a week, a month, or longer (counted
/// by month).
enum PeriodScale { day, week, month, long }

/// The scale of a period. A custom one goes by its length (PRODUCT): up to
/// 2 days as a day, up to 2 weeks as a week, up to two months as a month,
/// beyond as a year.
PeriodScale scaleOf(PeriodKind kind, TimeSpan span) => switch (kind) {
  PeriodKind.today ||
  PeriodKind.yesterday ||
  PeriodKind.last24Hours => PeriodScale.day,
  PeriodKind.last7Days => PeriodScale.week,
  PeriodKind.month => PeriodScale.month,
  PeriodKind.year => PeriodScale.long,
  PeriodKind.custom =>
    span.days <= 2
        ? PeriodScale.day
        : span.days <= 14
        ? PeriodScale.week
        : span.days <= 62
        ? PeriodScale.month
        : PeriodScale.long,
};

/// The average day, which Dépensé is compared with for a day (PRODUCT, 27
/// November 2026): what went out over the 30 days before today, today left
/// out, divided by 30.
int averageDay(
  Iterable<DatedFlow> flows, {
  required DateTime now,
  required CurrencyInfo main,
  required ExchangeRate? Function(String code) rateFor,
}) {
  final today = DateTime(now.year, now.month, now.day);
  final span = TimeSpan(
    DateTime(today.year, today.month, today.day - 30),
    today,
  );
  return (totalsWithin(span, flows, main, rateFor).exits.minor / 30).round();
}

/// What went out over [span] per [unit] (day, week or month), and over how
/// many units: those begun so far for a period in progress, today
/// included; all of them for a past one.
({int amount, int units}) averageOf(
  TimeSpan span,
  Iterable<DatedFlow> flows, {
  required Grouping unit,
  required DateTime now,
  required CurrencyInfo main,
  required ExchangeRate? Function(String code) rateFor,
  int startDay = 1,
}) {
  final running = span.contains(now);
  final days = running
      ? calendarDays(span.start, now) + 1
      : calendarDays(span.start, span.end);
  final int units = switch (unit) {
    Grouping.hour || Grouping.day => days,
    Grouping.week => (days / 7).ceil(),
    Grouping.month => bucketsOf(
      span,
      Grouping.month,
      startDay: startDay,
    ).where((b) => !running || !b.start.isAfter(now)).length,
  };
  final spent = totalsWithin(span, flows, main, rateFor).exits.minor;
  final n = units < 1 ? 1 : units;
  return (amount: (spent / n).round(), units: n);
}

/// The bar where the most went out, the first one when two are equal, with
/// every bar's exits; null when nothing went out.
({int index, int amount, List<int> values})? priciest(
  List<TimeSpan> bars,
  Iterable<DatedFlow> flows, {
  required CurrencyInfo main,
  required ExchangeRate? Function(String code) rateFor,
}) {
  final values = [
    for (final t in totalsByBucket(bars, flows, main, rateFor)) t.exits.minor,
  ];
  var index = -1;
  var most = 0;
  for (final (i, v) in values.indexed) {
    if (v > most) {
      most = v;
      index = i;
    }
  }
  return index < 0 ? null : (index: index, amount: most, values: values);
}

/// An expense and its category, when (local time).
typedef CategorySpend = ({DateTime at, String category, Money amount});

/// The category where the most went out over [span], a subcategory counting
/// in its parent ([parentOf]), with its share of all [exits]; null without
/// any expense.
({String category, int amount, int share})? topCategory(
  TimeSpan span,
  Iterable<CategorySpend> spends, {
  required String Function(String id) parentOf,
  required int exits,
  required CurrencyInfo main,
  required ExchangeRate? Function(String code) rateFor,
}) {
  final byParent = <String, List<MoneyFlow>>{};
  for (final s in spends) {
    if (!span.contains(s.at)) continue;
    byParent
        .putIfAbsent(parentOf(s.category), () => [])
        .add(MoneyFlow(outgoing: s.amount));
  }
  String? best;
  var most = 0;
  for (final MapEntry(:key, :value) in byParent.entries) {
    final amount = flowTotals(main, value, rateFor).exits.minor;
    if (amount > most) {
      most = amount;
      best = key;
    }
  }
  if (best == null) return null;
  return (
    category: best,
    amount: most,
    share: exits <= 0 ? 0 : (most * 100 / exits).round(),
  );
}

/// What a monthly budget leaves for today: what is left of it, spread over
/// the days left with today ([allowance]), less what today already took
/// ([left], below zero when today went past it).
({int allowance, int left}) leftForToday({
  required int amount,
  required int spentBefore,
  required int spentToday,
  required int daysLeft,
}) {
  final rest = amount - spentBefore;
  final allowance = rest <= 0 || daysLeft <= 0 ? 0 : rest ~/ daysLeft;
  return (allowance: allowance, left: allowance - spentToday);
}

/// The running total of [values], bar after bar (the curve of a tile).
List<int> runningTotal(List<int> values) {
  var sum = 0;
  return [for (final v in values) sum += v];
}

/// What « Suivre » keeps: the tiles on, and the budget and the project the
/// user picked (null: the default one).
class FollowedChoice {
  const FollowedChoice({this.on = followedAtFirst, this.budget, this.project});

  final Set<Followed> on;
  final String? budget;
  final String? project;

  /// The tiles on, in the order of the « Suivre » sheet.
  List<Followed> get shown => [
    for (final f in Followed.values)
      if (on.contains(f)) f,
  ];

  FollowedChoice turned(Followed tile, bool value) => FollowedChoice(
    on: value ? {...on, tile} : ({...on}..remove(tile)),
    budget: budget,
    project: project,
  );

  FollowedChoice withBudget(String id) =>
      FollowedChoice(on: on, budget: id, project: project);

  FollowedChoice withProject(String id) =>
      FollowedChoice(on: on, budget: budget, project: id);
}

/// A total at each of [moments]: the [current] total less every change
/// dated at or after that moment (the curves of Comptes and Patrimoine
/// net). [changes] are signed, in the main currency.
List<int> totalsBack(
  List<DateTime> moments, {
  required int current,
  required Iterable<({DateTime at, int change})> changes,
}) => [
  for (final m in moments)
    current -
        changes
            .where((c) => !c.at.isBefore(m))
            .fold(0, (sum, c) => sum + c.change),
];

/// The budget nearest its limit (the highest share spent), shown by
/// « Un budget » until the user picks one; null without budgets.
String? nearestLimit(Iterable<({String id, int percent})> budgets) {
  String? best;
  var most = -1;
  for (final b in budgets) {
    if (b.percent > most) {
      most = b.percent;
      best = b.id;
    }
  }
  return best;
}

/// The running project due soonest, or the first running one without a
/// date, shown by « Un projet » until the user picks one.
String? soonestDue(
  Iterable<({String id, DateTime? due, bool running})> projects,
) {
  final running = projects.where((p) => p.running).toList();
  final dated = running.where((p) => p.due != null).toList()
    ..sort((a, b) => a.due!.compareTo(b.due!));
  if (dated.isNotEmpty) return dated.first.id;
  return running.isEmpty ? null : running.first.id;
}
