import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// A share as a bar: its colour over a light track, rounded, 6 high by
/// default; [mark] puts an ink line where it should be, with [markLabel]
/// above (Un projet's plan). Used by the tiles, their enlarged cards and
/// the Catégories tab.
class ShareBar extends StatelessWidget {
  const ShareBar({
    super.key,
    required this.share,
    required this.color,
    this.height = 6,
    this.track = KibuoColors.background,
    this.mark,
    this.markLabel,
  });

  final double share;
  final Color color;
  final double height;
  final Color track;
  final double? mark;
  final String? markLabel;

  @override
  Widget build(BuildContext context) {
    final mark = this.mark;
    final bar = LayoutBuilder(
      builder: (context, box) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: track,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
          Container(
            width: box.maxWidth * share.clamp(0, 1),
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
          if (mark != null)
            Positioned(
              left: box.maxWidth * mark.clamp(0, 1) - 1,
              top: -5,
              bottom: -5,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  color: KibuoColors.ink,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
        ],
      ),
    );
    final label = markLabel;
    if (mark == null || label == null) return bar;
    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment((mark.clamp(0, 1) * 2 - 1).toDouble(), 0),
            child: Text(label, style: KibuoType.caption.copyWith(fontSize: 10)),
          ),
          const SizedBox(height: 8),
          bar,
        ],
      ),
    );
  }
}
