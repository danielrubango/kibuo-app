import 'package:flutter/material.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/card_arrow.dart';
import 'package:kibuo/ui/kit/dashed_border.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// What a home card shows of one side: what is left in the main currency,
/// how many, how many late.
class DebtSide {
  const DebtSide({required this.total, required this.count, this.late = 0});

  /// Formatted; null when nothing is owed on this side.
  final String? total;
  final int count;
  final int late;
}

/// « Je dois › » and « On me doit › » side by side, under the month
/// (canvas Aujourdhui): the amount in the colour of its side, then « 3
/// dettes · 1 en retard », the delay in red. No name, no date.
class DebtHomeCards extends StatelessWidget {
  const DebtHomeCards({
    super.key,
    required this.owe,
    required this.owed,
    required this.onOpen,
  });

  final DebtSide owe;
  final DebtSide owed;
  final ValueChanged<DebtDirection> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Card(
              label: l.debtsOwe,
              side: owe,
              ink: KibuoColors.debtInk,
              count: l.debtsCountOwe(owe.count),
              onTap: () => onOpen(DebtDirection.owe),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Card(
              label: l.debtsOwed,
              side: owed,
              ink: KibuoColors.accent,
              count: l.debtsCountOwed(owed.count),
              onTap: () => onOpen(DebtDirection.owed),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.label,
    required this.side,
    required this.ink,
    required this.count,
    required this.onTap,
  });

  final String label;
  final DebtSide side;
  final Color ink;
  final String count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = side.total;
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        onTap: () {
          Haptics.tap();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, CardArrow.edge, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: KibuoType.body
                          .copyWith(
                            fontSize: 13,
                            color: KibuoColors.inkSecondary,
                          )
                          .weight(600),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        total ?? l.debtsNothing,
                        maxLines: 1,
                        style: KibuoType.highlight.copyWith(
                          fontSize: 22,
                          color: total == null ? KibuoColors.inkMuted : ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Always three lines: « Rien » keeps its place at the
                    // top, like its neighbour (owner, 24 November).
                    if (side.count > 0)
                      Text.rich(
                        TextSpan(
                          text: count,
                          children: [
                            if (side.late > 0)
                              TextSpan(
                                text: ' · ${l.debtsLateCount(side.late)}',
                                style: const TextStyle(
                                  color: KibuoColors.danger,
                                ).weight(700),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KibuoType.caption,
                      )
                    else
                      Text(
                        '—',
                        style: KibuoType.caption.copyWith(
                          color: KibuoColors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const CardArrow(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A debt due soon in « À venir » (canvas Aujourdhui): drawn like a
/// planned operation, dashed and grey, « Rembourser Amani » or « Grâce me
/// rembourse », « Prévu » then « Dette » or « Créance », what is left.
class DebtComingRow extends StatelessWidget {
  const DebtComingRow({super.key, required this.debt, required this.onTap});

  final DebtLine debt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final owe = debt.direction == DebtDirection.owe;
    final amount = formatMoney(debt.left, currencyOf(debt.left.currency), lang);
    return DashedBorder(
      radius: 16,
      color: KibuoColors.line,
      child: Material(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: KibuoTheme.heightTouch,
                    height: KibuoTheme.heightTouch,
                    decoration: BoxDecoration(
                      color: KibuoColors.background,
                      borderRadius: BorderRadius.circular(
                        KibuoTheme.heightTouch * 0.3,
                      ),
                    ),
                    child: const Icon(
                      KibuoIcons.handCoins,
                      size: 22,
                      color: KibuoColors.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owe
                              ? l.debtComingOwe(debt.person)
                              : l.debtComingOwed(debt.person),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.rowLabel,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: KibuoColors.background,
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                l.plannedTag,
                                style: KibuoType.caption
                                    .copyWith(fontSize: 11)
                                    .weight(600),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              owe ? l.debtTagOwe : l.debtTagOwed,
                              style: KibuoType.help,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${owe ? '−' : '+'}$amount',
                    style: KibuoType.buttonSmall.copyWith(
                      color: KibuoColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
