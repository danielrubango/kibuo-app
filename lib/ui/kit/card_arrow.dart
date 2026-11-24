import 'package:flutter/widgets.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// The › of a card that opens a page (owner, 24 November): 18, grey on a
/// white card, green on a mint one, always [edge] from the card's right
/// side, which the card gives as its right padding.
class CardArrow extends StatelessWidget {
  const CardArrow({super.key, this.color = KibuoColors.inkMuted});

  /// The card's right padding, so every arrow sits as far from its edge.
  static const edge = 14.0;

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Icon(KibuoIcons.caretRight, size: 18, color: color);
}
