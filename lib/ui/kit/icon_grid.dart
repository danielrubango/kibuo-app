import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Icons to choose from, six per row filling the width (TypeCompte); the
/// chosen one in ink. Each is labelled by its stored name.
class IconGrid extends StatelessWidget {
  const IconGrid({
    super.key,
    required this.icons,
    required this.chosen,
    required this.onPick,
  });

  final Map<String, IconData> icons;
  final String chosen;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final MapEntry(key: name, value: icon) in icons.entries)
          Semantics(
            label: name,
            selected: name == chosen,
            button: true,
            excludeSemantics: true,
            child: Material(
              color: name == chosen ? KibuoColors.ink : KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onPick(name),
                child: Center(
                  child: Icon(
                    icon,
                    size: 22,
                    color: name == chosen
                        ? KibuoColors.surface
                        : KibuoColors.ink,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
