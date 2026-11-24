import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/auto_close.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/icon_tile.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// What a confirmation sheet's button gives back.
class ConfirmAction<T> {
  const ConfirmAction(this.label, this.value, {this.main = false});

  final String label;
  final T value;

  /// Mint, last; the others white.
  final bool main;
}

/// « Dette enregistrée », « Remboursement enregistré » (canvas ConfirmA):
/// the title with ✕, a white card with what was saved, its actions, then
/// the bar that empties; it closes by itself, or at once with ✕.
Future<T?> showConfirmSheet<T>(
  BuildContext context, {
  required String title,
  required Widget card,
  List<ConfirmAction<T>> actions = const [],
}) => showModalBottomSheet<T>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  builder: (context) => withSheetHandle(
    Padding(
      padding: sheetPadding(context),
      child: AutoClose(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(title: title),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
              ),
              child: card,
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (i, a) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: KibuoButton(
                        label: a.label,
                        kind: a.main ? ButtonKind.mint : ButtonKind.secondary,
                        onPressed: () => Navigator.of(context).pop(a.value),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    ),
  ),
);

/// The mint check, what was saved and its line, the amount: the first row
/// of every confirmation (canvas ApresFeuilleB, ConfirmA).
class SavedLine extends StatelessWidget {
  const SavedLine({
    super.key,
    required this.title,
    required this.subtitle,
    this.amount,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? amount;

  /// In place of the amount (the lock of an encrypted backup).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconTile(
        icon: KibuoIcons.check,
        tint: KibuoColors.mint,
        ink: null,
        iconSize: 20,
        radius: 11,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: KibuoType.itemName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: KibuoType.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      if (amount case final amount?) ...[
        const SizedBox(width: 8),
        Text(amount, style: KibuoType.cardTitle),
      ],
      if (trailing case final trailing?) ...[
        const SizedBox(width: 8),
        trailing,
      ],
    ],
  );
}
