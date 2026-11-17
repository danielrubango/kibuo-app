import 'package:flutter/widgets.dart';

import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The name « kibuo » as it is drawn (BRAND, canvas NomMinusculeB): in
/// lowercase, Space Grotesk bold, the dot of the i being the amber coin of
/// the logo with its ink edge.
class KibuoWordmark extends StatelessWidget {
  const KibuoWordmark({
    super.key,
    this.size = 40,
    this.color = KibuoColors.ink,
    this.letterSpacing,
  });

  final double size;
  final Color color;

  /// Defaults to a slight tightening, as in the mock-ups.
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: KibuoTheme.brandFont,
      fontVariations: const [FontVariation.weight(700)],
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 1.2,
      letterSpacing: letterSpacing ?? -size / 80,
      color: color,
      decoration: TextDecoration.none,
    );
    final coin = size * .27;
    return Semantics(
      label: 'kibuo',
      excludeSemantics: true,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'k'),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The dotless i, so the coin is its only dot.
                  Text('ı', style: style),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: size * .1,
                    child: Center(
                      child: Container(
                        key: const ValueKey('kibuo-coin'),
                        width: coin,
                        height: coin,
                        decoration: BoxDecoration(
                          color: KibuoColors.coin,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KibuoColors.ink,
                            width: size * .045 < 1 ? 1 : size * .045,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const TextSpan(text: 'buo'),
          ],
        ),
        style: style,
        textAlign: TextAlign.center,
      ),
    );
  }
}
