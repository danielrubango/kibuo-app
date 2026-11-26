import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Choices side by side on a grey strip, the chosen one white (canvas
/// ApercuP2: Évolution | Catégories | Patrimoine, and the choices of the
/// « Période » sheet). A choice in [disabled] is greyed and does nothing.
class TabStrip<T> extends StatelessWidget {
  const TabStrip({
    super.key,
    required this.items,
    required this.value,
    required this.onPick,
    this.disabled = const {},
    this.height = KibuoTheme.heightTouch,
  });

  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onPick;
  final Set<T> disabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KibuoColors.fill,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
      ),
      child: Row(
        children: [
          for (final (i, (item, label)) in items.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(child: _choice(item, label)),
          ],
        ],
      ),
    );
  }

  Widget _choice(T item, String label) {
    final chosen = item == value;
    final off = disabled.contains(item);
    return Semantics(
      selected: chosen,
      enabled: !off,
      button: true,
      child: Material(
        color: chosen ? KibuoColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: off || chosen
              ? null
              : () {
                  Haptics.tap();
                  onPick(item);
                },
          child: SizedBox(
            height: height,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KibuoType.buttonSmall.copyWith(
                  fontSize: 13,
                  color: off ? KibuoColors.lineStrong : KibuoColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
