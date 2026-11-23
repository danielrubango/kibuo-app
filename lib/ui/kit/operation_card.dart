import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/dashed_border.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The top of an operation that is not one yet (canvas
/// OperationCarteBrouillon, OperationCarteIgnoree; the planned one's card):
/// dashed, 22 round, its tile, name and status, the amount in large, and
/// a chip with its date.
class OperationHero extends StatelessWidget {
  const OperationHero({
    super.key,
    required this.tile,
    required this.title,
    required this.status,
    required this.amount,
    required this.chip,
    this.statusColor = KibuoColors.inkSecondary,
    this.amountColor = KibuoColors.ink,
    this.struck = false,
    this.background = KibuoColors.surface,
    this.dash = KibuoColors.line,
  });

  final Widget tile;
  final String title;
  final String status;
  final Color statusColor;
  final String amount;
  final Color amountColor;

  /// An ignored one: the amount struck through.
  final bool struck;
  final String chip;
  final Color background;
  final Color dash;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      radius: KibuoTheme.radiusFeatured,
      color: dash,
      width: 2,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                tile,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: KibuoType.body
                            .weight(600)
                            .copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        status,
                        style: KibuoType.help
                            .weight(500)
                            .copyWith(color: statusColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              amount,
              style: KibuoType.bigAmount.copyWith(
                fontSize: 42,
                height: 48 / 42,
                color: amountColor,
                decoration: struck ? TextDecoration.lineThrough : null,
                decorationColor: amountColor,
                decorationThickness: 2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x0F0E1320),
                borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
              ),
              child: Text(
                chip,
                style: KibuoType.help.copyWith(color: KibuoColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A sentence in a frame, with its icon (canvas OperationCarteBrouillon):
/// what the screen's state means.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.icon,
    required this.text,
    this.background = KibuoColors.surface,
    this.ink = KibuoColors.inkSecondary,
  });

  final IconData icon;
  final String text;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: KibuoType.body.copyWith(height: 20 / 14, color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
