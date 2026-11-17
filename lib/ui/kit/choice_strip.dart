import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Choices side by side on a grey strip, the chosen one in ink (canvas
/// Recurrence: Jour | Semaine | Mois | Année). [onWhite] puts the strip
/// on the page's background instead of inside a card.
class ChoiceStrip<T> extends StatelessWidget {
  const ChoiceStrip({
    super.key,
    required this.items,
    required this.value,
    required this.onPick,
    this.onWhite = false,
    this.height = 40,
  });

  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onPick;
  final bool onWhite;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onWhite ? KibuoColors.surface : KibuoColors.background,
        borderRadius: BorderRadius.circular(onWhite ? 16 : 14),
      ),
      child: Row(
        children: [
          for (final (i, (item, label)) in items.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                selected: item == value,
                button: true,
                child: Material(
                  color: item == value ? KibuoColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(onWhite ? 12 : 11),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(onWhite ? 12 : 11),
                    onTap: () => onPick(item),
                    child: SizedBox(
                      height: height,
                      child: Center(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.buttonSmall.copyWith(
                            fontSize: 14,
                            color: item == value
                                ? KibuoColors.surface
                                : KibuoColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// « − 2 + » on a grey pill (canvas Recurrence).
class CountStepper extends StatelessWidget {
  const CountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.lessLabel,
    this.moreLabel,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final String? lessLabel;
  final String? moreLabel;

  @override
  Widget build(BuildContext context) {
    Widget button(String text, String? label, VoidCallback? onTap) => Semantics(
      label: label,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
        onTap: onTap,
        child: SizedBox.square(
          dimension: KibuoTheme.heightTouch,
          child: Center(
            child: Text(
              text,
              style: KibuoType.button.copyWith(
                fontSize: 20,
                color: onTap == null ? KibuoColors.lineStrong : KibuoColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: KibuoColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            '−',
            lessLabel,
            value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: KibuoType.cardTitle.copyWith(fontSize: 18),
            ),
          ),
          button(
            '+',
            moreLabel,
            value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
