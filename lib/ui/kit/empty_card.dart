import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/dashed_border.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// An empty list (DIRECTION; canvas ListeOperations, RechercheR2): white,
/// dashed grey, the icon in a grey circle, a title, a line of help, then the
/// useful action on a grey button.
class EmptyCard extends StatelessWidget {
  const EmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.help,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String help;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return DashedBorder(
      radius: KibuoTheme.radiusCard,
      color: KibuoColors.line,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: KibuoColors.surface,
          borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        ),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: KibuoColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: KibuoColors.inkSecondary),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: KibuoType.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              help,
              style: KibuoType.body.copyWith(
                color: KibuoColors.inkSecondary,
                height: 20 / 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 16),
              Material(
                color: KibuoColors.background,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                child: InkWell(
                  borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                  onTap: onAction,
                  child: Container(
                    height: KibuoTheme.heightTouch,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        action,
                        style: KibuoType.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation.weight(600)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
