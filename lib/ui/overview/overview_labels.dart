import 'package:intl/intl.dart';
import 'package:kibuo/domain/overview/overview_choice.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/l10n/app_localizations.dart';

String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

/// A chip of the « Période » sheet.
String kindName(AppLocalizations l, PeriodKind kind) => switch (kind) {
  PeriodKind.today => l.overviewKindToday,
  PeriodKind.yesterday => l.overviewKindYesterday,
  PeriodKind.last24Hours => l.overviewKind24h,
  PeriodKind.last7Days => l.overviewKind7Days,
  PeriodKind.month => l.overviewKindMonth,
  PeriodKind.year => l.overviewKindYear,
  PeriodKind.custom => l.overviewKindCustom,
};

String groupingName(AppLocalizations l, Grouping g) => switch (g) {
  Grouping.hour => l.overviewByHour,
  Grouping.day => l.overviewByDay,
  Grouping.week => l.overviewByWeek,
  Grouping.month => l.overviewByMonth,
};

String comparisonName(AppLocalizations l, Comparison c) => switch (c) {
  Comparison.previous => l.overviewComparePrevious,
  Comparison.next => l.overviewCompareNext,
  Comparison.current => l.overviewCompareCurrent,
  Comparison.none => l.overviewCompareNone,
};

String comparedAsName(AppLocalizations l, ComparedAs c) => switch (c) {
  ComparedAs.curve => l.overviewCurve,
  ComparedAs.sticks => l.overviewSticks,
};

/// The period in the header and in the legend (canvas ApercuP2):
/// « Aujourd’hui », « Hier », « dim. 22 nov. », « Dernières 24 h »,
/// « Jusqu’au 11 nov., 15 h », « 7 derniers jours », « 30 oct. – 5 nov. »,
/// « Novembre 2026 », « 2026 », « 1 sept. – 12 nov. 2026 ».
String periodLabel(
  AppLocalizations l,
  String lang,
  PeriodKind kind,
  int offset,
  TimeSpan span,
) {
  String day(DateTime d) => DateFormat.MMMd(lang).format(d);
  String weekday(DateTime d) => DateFormat.MMMEd(lang).format(d);
  switch (kind) {
    case PeriodKind.today:
      if (offset == 0) return l.overviewKindToday;
      if (offset == -1) return l.overviewKindYesterday;
      return weekday(span.start);
    case PeriodKind.yesterday:
      return offset == 0 ? l.overviewKindYesterday : weekday(span.start);
    case PeriodKind.last24Hours:
      if (offset == 0) return l.overviewLast24h;
      final last = span.end.subtract(const Duration(hours: 1));
      return l.overviewUntil(day(last), last.hour);
    case PeriodKind.last7Days:
      if (offset == 0) return l.overviewLast7Days;
      return l.overviewRange(day(span.start), day(span.lastDay));
    case PeriodKind.month:
      // The month the period ends in names it, as in Opérations.
      final named = DateTime(span.lastDay.year, span.lastDay.month);
      return _cap(DateFormat.yMMMM(lang).format(named));
    case PeriodKind.year:
      return '${span.lastDay.year}';
    case PeriodKind.custom:
      final first = span.start;
      final last = span.lastDay;
      return l.overviewRange(
        first.year == last.year
            ? day(first)
            : DateFormat.yMMMd(lang).format(first),
        DateFormat.yMMMd(lang).format(last),
      );
  }
}

/// What is written under bar [i], or null: every 6 hours, a day number
/// every few days (the weekday over 7 days), the weeks « S1 »…, the months
/// by their initial over a year and their short name otherwise.
String? barMark(
  AppLocalizations l,
  String lang,
  PeriodKind kind,
  Grouping grouping,
  List<TimeSpan> bars,
  int i, {
  required int startDay,
}) {
  final n = bars.length;
  final start = bars[i].start;
  switch (grouping) {
    case Grouping.hour:
      return start.hour % 6 == 0 ? l.overviewHourMark(start.hour) : null;
    case Grouping.day:
      if (kind == PeriodKind.last7Days) {
        return DateFormat.E(lang).format(start).replaceAll('.', '');
      }
      if (n <= 31) return i % 5 == 0 ? '${start.day}' : null;
      // Longer than a month: the 1st of each month, with its name
      // (« 1 oct. »), and the first day when no 1st comes soon after it.
      if (start.day == 1) return DateFormat.MMMd(lang).format(start);
      final firstSoon = bars.take(8).any((b) => b.start.day == 1);
      return i == 0 && !firstSoon ? DateFormat.MMMd(lang).format(start) : null;
    case Grouping.week:
      final step = n <= 11 ? 1 : 4;
      return i % step == 0 ? l.overviewWeekMark(i + 1) : null;
    case Grouping.month:
      final named = BudgetPeriod.containing(start, startDay: startDay).month;
      if (n > 6 && n <= 12) {
        return DateFormat.MMMM(lang).format(named)[0].toUpperCase();
      }
      final step = n <= 6 ? 1 : (n / 6).ceil();
      return i % step == 0 ? DateFormat.MMM(lang).format(named) : null;
  }
}
