import 'package:flutter/widgets.dart';

import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// What the + button can create, in the order of the « Ajouter » sheet.
enum AddChoice {
  expense(
    label: 'Dépense',
    hint: 'Le plus fréquent',
    fanLabel: 'Dépense',
    entryTitle: 'Nouvelle dépense',
    icon: KibuoIcons.arrowDown,
    tint: KibuoColors.debtTint,
    ink: KibuoColors.debtInk,
  ),
  income(
    label: 'Revenu',
    hint: 'Salaire, vente',
    fanLabel: 'Revenu',
    entryTitle: 'Nouveau revenu',
    icon: KibuoIcons.arrowUp,
    tint: KibuoColors.accentTintStrong,
    ink: KibuoColors.accent,
  ),
  transfer(
    label: 'Transfert',
    hint: 'Entre comptes',
    fanLabel: 'Transfert',
    entryTitle: 'Nouveau transfert',
    icon: KibuoIcons.arrowsLeftRight,
    tint: KibuoColors.background,
    ink: KibuoColors.inkSecondary,
  ),
  debt(
    label: 'Dette',
    hint: 'ou créance',
    fanLabel: 'Dette ou\ncréance',
    entryTitle: 'Nouvelle dette ou créance',
    icon: KibuoIcons.handCoins,
    tint: KibuoColors.debtTint,
    ink: KibuoColors.debtInk,
  ),
  project(
    label: 'Projet',
    hint: 'Mettre de côté',
    fanLabel: 'Mettre\nde côté',
    entryTitle: 'Mettre de côté',
    icon: KibuoIcons.target,
    tint: KibuoColors.projectTint,
    ink: KibuoColors.projectInk,
  );

  const AddChoice({
    required this.label,
    required this.hint,
    required this.fanLabel,
    required this.entryTitle,
    required this.icon,
    required this.tint,
    required this.ink,
  });

  final String label;
  final String hint;
  final String fanLabel;
  final String entryTitle;
  final IconData icon;
  final Color tint;
  final Color ink;
}
