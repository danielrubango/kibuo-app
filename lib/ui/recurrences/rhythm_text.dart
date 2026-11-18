import 'package:intl/intl.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations.dart';

/// « 1er » in French, « 1 » otherwise.
String dayNumber(String lang, int day) =>
    lang == 'fr' && day == 1 ? '1er' : '$day';

/// « a, b et c ».
String joinAnd(AppLocalizations l, List<String> items) => items.length < 2
    ? items.join()
    : '${items.sublist(0, items.length - 1).join(', ')} ${l.rhythmAnd} '
          '${items.last}';

/// What a recurrence does, in one line (canvas Recurrence): « Le 8 de
/// chaque mois, sans fin ».
String rhythmText(AppLocalizations l, String lang, Schedule s) =>
    '${rhythmOnly(l, lang, s)}, ${endText(l, lang, s)}';

/// « Le 8 de chaque mois ».
String rhythmOnly(AppLocalizations l, String lang, Schedule s) {
  final n = s.every;
  switch (s.unit) {
    case RepeatUnit.day:
      return n == 1 ? l.rhythmDaily : l.rhythmEveryDays('$n');
    case RepeatUnit.week:
      final names = [
        // Without days chosen, the first time's.
        for (final d
            in (s.weekdays.isEmpty ? {s.start.weekday} : s.weekdays).toList()
              ..sort())
          DateFormat.EEEE(lang).format(DateTime(2026, 11, 15 + d)),
      ];
      if (n == 1) return l.rhythmWeekly(joinAnd(l, names));
      final the = joinAnd(l, [for (final d in names) l.rhythmThe(d)]);
      final days = the[0].toUpperCase() + the.substring(1);
      return n == 2
          ? l.rhythmEveryOtherWeek(days)
          : l.rhythmEveryWeeks(days, '$n');
    case RepeatUnit.month:
      final day = dayNumber(lang, s.start.day);
      return n == 1 ? l.rhythmMonthly(day) : l.rhythmEveryMonths(day, '$n');
    case RepeatUnit.year:
      final date = DateFormat.MMMMd(lang).format(s.start);
      return n == 1 ? l.rhythmYearly(date) : l.rhythmEveryYears(date, '$n');
  }
}

/// « sans fin », « 6 fois en tout », « jusqu'au 8 juin 2027 ».
String endText(AppLocalizations l, String lang, Schedule s) {
  if (s.count != null) return l.rhythmEndCount('${s.count}');
  if (s.until != null) {
    return l.rhythmEndDate(DateFormat.yMMMMd(lang).format(s.until!));
  }
  return l.rhythmEndNever;
}
