import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The year between ‹ › and its 12 months; months to come are greyed
/// (canvas ListeMoisOuvert). « Ce mois-ci » only away from this month.
class MonthPicker extends StatefulWidget {
  const MonthPicker({
    super.key,
    required this.month,
    required this.onPick,
    required this.onThisMonth,
  });

  final DateTime month;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onThisMonth;

  @override
  State<MonthPicker> createState() => _MonthPickerState();
}

class _MonthPickerState extends State<MonthPicker> {
  late int _year = widget.month.year;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    Widget arrow(IconData icon, VoidCallback? onTap) => SizedBox.square(
      dimension: KibuoTheme.heightTouch,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 20,
          color: onTap == null ? KibuoColors.lineStrong : KibuoColors.ink,
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        boxShadow: const [
          BoxShadow(
            color: Color(0x380E1320),
            blurRadius: 36,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              arrow(KibuoIcons.caretLeft, () => setState(() => _year--)),
              Expanded(
                child: Text(
                  '$_year',
                  textAlign: TextAlign.center,
                  style: KibuoType.cardTitle,
                ),
              ),
              arrow(
                KibuoIcons.caretRight,
                _year >= now.year ? null : () => setState(() => _year++),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < 4; row++) ...[
            if (row > 0) const SizedBox(height: 6),
            Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _monthCell(
                      DateTime(_year, row * 3 + col + 1),
                      now,
                      lang,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (widget.onThisMonth case final back?) ...[
            const SizedBox(height: 8),
            TextAction(label: l.listThisMonth, onPressed: back),
          ],
        ],
      ),
    );
  }

  Widget _monthCell(DateTime m, DateTime now, String lang) {
    final future = m.isAfter(periodOf(DateTime.now()).month);
    final current = m == widget.month;
    final name = DateFormat.MMMM(lang).format(m);
    return Material(
      color: current ? KibuoColors.ink : KibuoColors.background,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
        onTap: future ? null : () => widget.onPick(m),
        child: SizedBox(
          height: KibuoTheme.heightTouch,
          child: Center(
            child: Text(
              name[0].toUpperCase() + name.substring(1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KibuoType.body.copyWith(
                fontWeight: FontWeight.w600,
                fontVariations: const [FontVariation.weight(600)],
                color: current
                    ? KibuoColors.surface
                    : future
                    ? KibuoColors.lineStrong
                    : KibuoColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The first visit shows the month swipe (canvas ListeOnboard): the list
/// darkened and blurred, a card above the tab bar with two months sliding
/// under a finger, the words, then « Compris ».
