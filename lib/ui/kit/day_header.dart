import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Aujourd'hui », « Hier », « Mardi 10 novembre ».
String dayLabel(BuildContext context, DateTime day) {
  final l = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return l.entryToday;
  if (day == today.subtract(const Duration(days: 1))) return l.entryYesterday;
  final t = DateFormat.MMMMEEEEd(lang).format(day);
  return t[0].toUpperCase() + t.substring(1);
}

/// A day of operations (canvas ListeOperations, BudgetDetail): a group
/// title (DIRECTION: Groupes) with the date, « · 3 » once folded, the
/// day's total in colour, and ˄ or ˅; touching it folds the day.
class DayHeader extends StatelessWidget {
  const DayHeader({
    super.key,
    required this.label,
    required this.count,
    required this.folded,
    required this.onTap,
    this.net,
    this.approximate = false,
  });

  final String label;
  final int count;
  final bool folded;
  final VoidCallback onTap;

  /// The day's total with its sign; none when only free transfers.
  final Money? net;
  final bool approximate;

  @override
  Widget build(BuildContext context) {
    final net = this.net;
    final lang = Localizations.localeOf(context).languageCode;
    String amount(bool short) {
      final m = net!;
      final abs = Money(m.minor.abs(), m.currency);
      final text = formatAmount(
        abs,
        currencyOf(m.currency),
        lang,
        short: short,
      );
      return '${approximate ? '≈ ' : ''}'
          '${m.minor > 0
              ? '+'
              : m.minor < 0
              ? '−'
              : ''}$text';
    }

    final color = net == null || net.minor == 0
        ? KibuoColors.inkMuted
        : net.minor > 0
        ? KibuoColors.accent
        : KibuoColors.debtInk;
    return GroupTitle(
      title: label,
      count: folded ? '$count' : null,
      folded: folded,
      onTap: onTap,
      trailing: net == null
          ? null
          : FitAmount(
              long: isLong(net),
              alignment: Alignment.centerRight,
              maxWidth: MediaQuery.sizeOf(context).width * 0.45,
              style: KibuoType.sectionTitle.copyWith(color: color),
              span: (short) => TextSpan(text: amount(short)),
            ),
    );
  }
}
