import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Tabs on a white bar, the chosen one in ink (Catégories, the entry's
/// Dépense / Revenu).
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.items,
    required this.value,
    required this.onPick,
    this.compact = false,
  });

  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onPick;

  /// Small, on a white card (canvas BudgetDetail « Total | Rythme »): 30
  /// high, grey behind, as wide as its words.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _compact();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
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
                  borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                    onTap: () => onPick(item),
                    child: SizedBox(
                      height: KibuoTheme.heightTouch,
                      child: Center(
                        child: Text(
                          label,
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

  Widget _compact() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: KibuoColors.background,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, (item, label)) in items.indexed) ...[
          if (i > 0) const SizedBox(width: 2),
          Semantics(
            selected: item == value,
            button: true,
            child: Material(
              color: item == value ? KibuoColors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                borderRadius: BorderRadius.circular(9),
                onTap: () => onPick(item),
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: KibuoType.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      fontVariations: const [FontVariation.weight(600)],
                      color: item == value
                          ? KibuoColors.surface
                          : KibuoColors.inkSecondary,
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
