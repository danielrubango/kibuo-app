import 'package:flutter/material.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/ui/kit/spent_bar.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// A month's summary (canvas Aujourdhui, Budgets; PRODUCT: the same card
/// on the home and on Budgets): « Novembre · ce mois-ci », what is left
/// with its word, the spent bar, then the share and a line at the right.
class MonthSummaryCard extends StatelessWidget {
  const MonthSummaryCard({
    super.key,
    required this.month,
    required this.detail,
    required this.left,
    required this.leftWord,
    required this.leftLong,
    required this.spent,
    required this.line,
    required this.lineLong,
    this.leftInAlert = false,
    this.today,
    this.trailing = KibuoIcons.caretRight,
    this.onTap,
  });

  /// « Novembre ».
  final String month;

  /// « ce mois-ci », « du 1er au 30 ».
  final String detail;

  /// « +612,00 $ », whole or short.
  final String Function(bool short) left;

  /// « restants ».
  final String leftWord;
  final bool leftLong;

  /// Below zero: in the debt colour.
  final bool leftInAlert;
  final SpentLevel spent;

  /// Today and its period, when the card is the current period's.
  final (DateTime, BudgetPeriod)? today;

  /// At the right under the bar: « −588,00 sur +1 200,00 ».
  final InlineSpan Function(bool short) line;
  final bool lineLong;

  /// › to open something, ▾ to choose the month.
  final IconData trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final down = trailing == KibuoIcons.caretDown;
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    const Icon(
                      KibuoIcons.calendarBlank,
                      size: 16,
                      color: KibuoColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: month,
                          children: [
                            TextSpan(
                              text: ' · $detail',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontVariations: [FontVariation.weight(500)],
                                color: KibuoColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KibuoType.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                        ),
                      ),
                    ),
                    Icon(
                      trailing,
                      size: 18,
                      color: down ? KibuoColors.accent : KibuoColors.inkMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              FitAmount(
                long: leftLong,
                span: (short) => TextSpan(
                  text: left(short),
                  style: KibuoType.tabTitle.copyWith(
                    height: 1.2,
                    color: leftInAlert ? KibuoColors.debtInk : null,
                  ),
                  children: [
                    TextSpan(
                      text: ' $leftWord',
                      style: KibuoType.help.copyWith(
                        fontWeight: FontWeight.w500,
                        fontVariations: const [FontVariation.weight(500)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              SpentBar(spent: spent, today: today),
              const SizedBox(height: 8),
              Row(
                children: [
                  SpentShare(spent: spent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FitAmount(
                      long: lineLong,
                      alignment: Alignment.centerRight,
                      style: KibuoType.caption,
                      span: line,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
