import 'package:flutter/material.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/more/plus_page.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The Aperçu tab until its charts come in version 0.2 (variant B of
/// `ApercuAttente-variantes.html`, PRODUCT 25 November 2026): what comes,
/// then where the figures already are.
class OverviewWaiting extends StatelessWidget {
  const OverviewWaiting({
    super.key,
    required this.onMonth,
    required this.onBudgets,
  });

  /// « Le mois en chiffres »: the Opérations tab.
  final VoidCallback onMonth;

  /// « Budgets ».
  final VoidCallback onBudgets;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, KibuoTheme.belowTabBar),
      children: [
        TabHeader(title: TabHeader.text(l.tabOverview)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: KibuoColors.accentTint,
                  borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
                ),
                child: const Icon(
                  KibuoIcons.chartBar,
                  color: KibuoColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.overviewSoonTitle,
                textAlign: TextAlign.center,
                style: KibuoType.cardTitle,
              ),
              const SizedBox(height: 8),
              Text(
                l.overviewSoonText,
                textAlign: TextAlign.center,
                style: KibuoType.help,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PlusCard(
          children: [
            PlusRow(
              icon: KibuoIcons.trendUp,
              tint: KibuoColors.debtTint,
              ink: KibuoColors.debtInk,
              label: l.overviewEvolution,
              detail: l.overviewEvolutionText,
              detailLines: 2,
            ),
            PlusRow(
              icon: KibuoIcons.chartPieSlice,
              tint: KibuoColors.accentTintStrong,
              ink: KibuoColors.accent,
              label: l.overviewCategories,
              detail: l.overviewCategoriesText,
              detailLines: 2,
            ),
            PlusRow(
              icon: KibuoIcons.bank,
              tint: KibuoColors.projectTint,
              ink: KibuoColors.projectInk,
              label: l.overviewWorth,
              detail: l.overviewWorthText,
              detailLines: 2,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(l.overviewMeanwhile, style: KibuoType.sectionTitle),
        ),
        PlusCard(
          children: [
            PlusRow(
              icon: KibuoIcons.list,
              label: l.overviewMonth,
              detail: l.overviewMonthText,
              detailLines: 2,
              onTap: onMonth,
            ),
            PlusRow(
              icon: KibuoIcons.chartPieSlice,
              tint: KibuoColors.warningTint,
              ink: KibuoColors.warningInk,
              label: l.budgetsTitle,
              detail: l.overviewBudgetsText,
              detailLines: 2,
              onTap: onBudgets,
            ),
          ],
        ),
      ],
    );
  }
}
