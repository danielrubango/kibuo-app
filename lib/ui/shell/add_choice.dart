import 'package:flutter/widgets.dart';

import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// What the + button can create, in the order of the « Ajouter » sheet.
enum AddChoice {
  expense(
    icon: KibuoIcons.arrowDown,
    tint: KibuoColors.debtTint,
    ink: KibuoColors.debtInk,
  ),
  income(
    icon: KibuoIcons.arrowUp,
    tint: KibuoColors.accentTintStrong,
    ink: KibuoColors.accent,
  ),
  transfer(
    icon: KibuoIcons.arrowsLeftRight,
    tint: KibuoColors.background,
    ink: KibuoColors.inkSecondary,
  ),
  debt(
    icon: KibuoIcons.handCoins,
    tint: KibuoColors.debtTint,
    ink: KibuoColors.debtInk,
  ),
  project(
    icon: KibuoIcons.target,
    tint: KibuoColors.projectTint,
    ink: KibuoColors.projectInk,
  );

  const AddChoice({required this.icon, required this.tint, required this.ink});

  final IconData icon;
  final Color tint;
  final Color ink;

  /// Name on the sheet's tile.
  String label(AppLocalizations l) => switch (this) {
    expense => l.addExpense,
    income => l.addIncome,
    transfer => l.addTransfer,
    debt => l.addDebt,
    project => l.addProject,
  };

  /// Small text under the name on the sheet.
  String hint(AppLocalizations l) => switch (this) {
    expense => l.addExpenseHint,
    income => l.addIncomeHint,
    transfer => l.addTransferHint,
    debt => l.addDebtHint,
    project => l.addProjectHint,
  };

  /// Name under the tile in the fan, on up to two lines.
  String fanLabel(AppLocalizations l) => switch (this) {
    debt => l.addDebtFan,
    project => l.addProjectFan,
    _ => label(l),
  };

  /// Title of the entry screen it opens.
  String entryTitle(AppLocalizations l) => switch (this) {
    expense => l.addExpenseTitle,
    income => l.addIncomeTitle,
    transfer => l.addTransferTitle,
    debt => l.addDebtTitle,
    project => l.addProjectTitle,
  };
}
