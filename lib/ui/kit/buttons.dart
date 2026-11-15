import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/dashed_border.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The eight kinds of button of the design system, each with its role.
enum ButtonKind {
  /// Mint, 54 high: the one main action of a screen, at the bottom.
  primary,

  /// White, 48 high: Annuler, Plus tard.
  secondary,

  /// White with an outline: a heavy choice that is not dangerous.
  outline,

  /// Ink: closes the keypad of an entry (Terminé).
  dark,

  /// Red outline: erasing, held down.
  danger,

  /// Dashed: adds an item to a list.
  create,
}

class KibuoButton extends StatelessWidget {
  const KibuoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (height, radius, text) = switch (kind) {
      ButtonKind.primary => (
        KibuoTheme.heightPrimary,
        KibuoTheme.radiusCard,
        KibuoType.button,
      ),
      ButtonKind.dark => (
        KibuoTheme.heightField,
        KibuoTheme.radiusField,
        KibuoType.button,
      ),
      _ => (
        KibuoTheme.heightSecondary,
        KibuoTheme.radiusField,
        KibuoType.buttonSmall,
      ),
    };
    final (background, foreground, border) = switch (kind) {
      _ when !enabled => (KibuoColors.fill, KibuoColors.inkMuted, null),
      ButtonKind.primary => (KibuoColors.mint, KibuoColors.ink, null),
      ButtonKind.secondary => (KibuoColors.surface, KibuoColors.ink, null),
      ButtonKind.outline => (
        KibuoColors.surface,
        KibuoColors.ink,
        const BorderSide(color: KibuoColors.lineStrong),
      ),
      ButtonKind.dark => (KibuoColors.ink, KibuoColors.surface, null),
      ButtonKind.danger => (
        KibuoColors.surface,
        KibuoColors.danger,
        const BorderSide(color: KibuoColors.danger, width: 1.5),
      ),
      ButtonKind.create => (Colors.transparent, KibuoColors.accent, null),
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: border ?? BorderSide.none,
    );
    Widget button = Material(
      color: background,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: text.copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (kind == ButtonKind.create && enabled) {
      button = DashedBorder(
        radius: radius,
        color: KibuoColors.lineStrong,
        child: button,
      );
    }
    return Semantics(button: true, enabled: enabled, child: button);
  }
}

/// A green action in a card or a row: « Modifier », « Changer ».
class TextAction extends StatelessWidget {
  const TextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = KibuoColors.accent,
    this.underline = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  /// For a way out that is not the main path: « Code oublié ? ».
  final bool underline;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(KibuoTheme.heightTouch, KibuoTheme.heightTouch),
        textStyle: KibuoType.buttonSmall.copyWith(
          decoration: underline ? TextDecoration.underline : null,
        ),
      ),
      child: Text(label),
    );
  }
}
