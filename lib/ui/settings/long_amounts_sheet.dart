import 'package:flutter/material.dart';
import 'package:kibuo/data/long_amounts_store.dart';
import 'package:kibuo/domain/money/long_amounts.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/fit_amount.dart';

/// « Automatique », « Toujours » or « Jamais », for the Réglages row.
String longAmountsName(AppLocalizations l, LongAmounts choice) =>
    switch (choice) {
      LongAmounts.auto => l.longAmountsAuto,
      LongAmounts.always => l.longAmountsAlways,
      LongAmounts.never => l.longAmountsNever,
    };

/// « Montants longs » (canvas MontantsReglage): the three choices, the one
/// in use checked; touching one applies it, keeps it and closes the sheet.
Future<void> showLongAmountsSheet(
  BuildContext context,
  LongAmountsStore store,
) async {
  final l = AppLocalizations.of(context);
  final current = longAmountsChoice.value;
  final picked = await showKibuoSheet<LongAmounts>(
    context,
    title: l.longAmounts,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsCard(
          children: [
            for (final (choice, help) in [
              (LongAmounts.auto, l.longAmountsAutoHelp),
              (LongAmounts.always, l.longAmountsAlwaysHelp),
              (LongAmounts.never, l.longAmountsNeverHelp),
            ])
              CheckChoice(
                label: longAmountsName(l, choice),
                help: help,
                on: choice == current,
                onTap: () => Navigator.of(context).pop(choice),
              ),
          ],
        ),
        const SizedBox(height: 8),
        HelpText(l.longAmountsNote),
      ],
    ),
  );
  if (picked == null || picked == current) return;
  longAmountsChoice.value = picked;
  await store.write(picked);
}
