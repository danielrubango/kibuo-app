import 'package:flutter/widgets.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// The › of a card that opens a page (owner, 24 November): 18, grey on a
/// white card, green on a mint one. The card keeps [edge] on both sides;
/// the arrow sits 2 closer to the right edge, at 12, so it looks as far
/// from it as the words do from the left.
class CardArrow extends StatelessWidget {
  const CardArrow({super.key, this.color = KibuoColors.inkMuted});

  /// Every home card's inner margin, left and right.
  static const edge = 14.0;

  final Color color;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(2, 0),
    child: Icon(KibuoIcons.caretRight, size: 18, color: color),
  );
}
