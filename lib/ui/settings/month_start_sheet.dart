import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/month_start_store.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Début du mois » (canvas ReglageDebutMois): a wheel of days 1 to 28,
/// the period it makes, and « Enregistrer ». Closing changes nothing.
Future<void> showMonthStartSheet(
  BuildContext context,
  MonthStartStore store,
) async {
  final l = AppLocalizations.of(context);
  final picked = await showKibuoSheet<int>(
    context,
    title: l.monthStart,
    builder: (context) => _MonthStartPicker(start: monthStartChoice.value),
  );
  if (picked == null || picked == monthStartChoice.value) return;
  monthStartChoice.value = picked;
  await store.write(picked);
}

class _MonthStartPicker extends StatefulWidget {
  const _MonthStartPicker({required this.start});

  final int start;

  @override
  State<_MonthStartPicker> createState() => _MonthStartPickerState();
}

class _MonthStartPickerState extends State<_MonthStartPicker> {
  late int _day = widget.start;
  late final _wheel = FixedExtentScrollController(
    initialItem: widget.start - 1,
  );

  static const _row = 44.0;

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    // The current period, with the day being chosen.
    final now = DateTime.now();
    final period = BudgetPeriod.containing(now, startDay: _day);
    final month = DateFormat.MMMM(lang).format(period.month);
    // « 1er novembre », not « 1 novembre ».
    String day(DateTime d) {
      final text = DateFormat.MMMMd(lang).format(d);
      return lang == 'fr' && d.day == 1
          ? text.replaceFirst(RegExp(r'^1(?=\D)'), '1er')
          : text;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HelpText(l.monthStartHelp),
        const SizedBox(height: 12),
        Container(
          height: 7 * _row,
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // The band under the chosen day.
              Positioned(
                left: 12,
                right: 12,
                top: 3 * _row,
                height: _row,
                child: Container(
                  decoration: BoxDecoration(
                    color: KibuoColors.background,
                    borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
                  ),
                ),
              ),
              ListWheelScrollView.useDelegate(
                controller: _wheel,
                itemExtent: _row,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() => _day = i + 1),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 28,
                  builder: (context, i) {
                    final away = (i + 1 - _day).abs();
                    return Center(
                      child: Opacity(
                        opacity: switch (away) {
                          0 => 1,
                          1 => 0.78,
                          2 => 0.56,
                          _ => 0.34,
                        },
                        child: Text(
                          '${i + 1}',
                          style: away == 0
                              ? KibuoType.body.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontVariations: const [
                                    FontVariation.weight(700),
                                  ],
                                )
                              : KibuoType.body.copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  fontVariations: const [
                                    FontVariation.weight(500),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Fading at the top and the bottom.
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 70,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [KibuoColors.surface, Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 70,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00FFFFFF), KibuoColors.surface],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: KibuoColors.projectTint,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
          ),
          child: Row(
            children: [
              const Icon(
                KibuoIcons.calendarBlank,
                size: 20,
                color: KibuoColors.projectInk,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.monthStartPreview(
                    month[0].toUpperCase() + month.substring(1),
                    day(period.first),
                    day(period.last),
                  ),
                  style: KibuoType.body.copyWith(
                    height: 20 / 14,
                    color: KibuoColors.projectInk,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KibuoButton(
          label: l.monthStartSave,
          onPressed: () => Navigator.of(context).pop(_day),
        ),
      ],
    );
  }
}
