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
  });

  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
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
}
