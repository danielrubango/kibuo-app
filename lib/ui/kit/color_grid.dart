import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Colours to choose from, five per row filling the width, square like the
/// icons above them; the chosen one ringed in ink and ticked (canvas
/// CouleurC1, 27 November 2026). Each is labelled by its name.
class ColorGrid<T> extends StatelessWidget {
  const ColorGrid({
    super.key,
    required this.colors,
    required this.chosen,
    required this.onPick,
  });

  /// Each choice with its hue and its name.
  final List<({T value, Color hue, String name})> colors;
  final T chosen;
  final ValueChanged<T> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 5,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Room for the ring of the chosen one.
      padding: const EdgeInsets.all(5),
      children: [
        for (final c in colors)
          Semantics(
            label: c.name,
            selected: c.value == chosen,
            button: true,
            excludeSemantics: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                boxShadow: c.value == chosen
                    ? const [
                        BoxShadow(
                          color: KibuoColors.background,
                          spreadRadius: 2.5,
                        ),
                        BoxShadow(color: KibuoColors.ink, spreadRadius: 5),
                      ]
                    : null,
              ),
              child: Material(
                color: c.hue,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onPick(c.value),
                  child: c.value == chosen
                      ? const Center(
                          child: Icon(
                            KibuoIcons.checkBold,
                            size: 18,
                            color: KibuoColors.ink,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
