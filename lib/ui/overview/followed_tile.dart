import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The small picture of a tile (DIRECTION: a running curve for an amount
/// that adds up, a filling bar for a share, small columns with the largest
/// in colour).
sealed class TileVisual {
  const TileVisual();
}

class TileCurve extends TileVisual {
  const TileCurve(this.values, this.color);

  final List<int> values;
  final Color color;
}

class TileBar extends TileVisual {
  const TileBar(this.share, this.color);

  /// From 0 to 1.
  final double share;
  final Color color;
}

class TileColumns extends TileVisual {
  const TileColumns(this.values, this.highlight, this.color);

  final List<int> values;
  final int? highlight;
  final Color color;
}

/// One tile of « Points suivis » (canvas ApercuTMois): its name, the
/// figure, a picture 20 high, then a line of detail, each on one line.
class FollowedTile extends StatelessWidget {
  const FollowedTile({
    super.key,
    required this.name,
    required this.value,
    required this.detail,
    this.valueColor = KibuoColors.ink,
    this.visual,
    this.detailColor = KibuoColors.inkSecondary,
    this.arrowUp,
    this.onTap,
  });

  final String name;
  final String value;
  final Color valueColor;
  final TileVisual? visual;
  final String detail;
  final Color detailColor;

  /// An arrow before the detail, leaning up or down; none when null.
  final bool? arrowUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final arrowUp = this.arrowUp;
    final line = KibuoType.caption.copyWith(height: 16 / 12);
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
        onTap: onTap == null
            ? null
            : () {
                Haptics.tap();
                onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: line,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KibuoType.cardTitle.copyWith(
                  fontSize: 18,
                  height: 22 / 18,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 20,
                child: switch (visual) {
                  null => null,
                  TileBar(:final share, :final color) => Center(
                    child: _Bar(share: share, color: color),
                  ),
                  final TileVisual v => CustomPaint(painter: _VisualPainter(v)),
                },
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (arrowUp != null) ...[
                    CustomPaint(
                      size: const Size.square(14),
                      painter: TrendArrow(up: arrowUp, color: detailColor),
                    ),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: line.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                        color: detailColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.share, required this.color});

  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 6,
    decoration: BoxDecoration(
      color: KibuoColors.background,
      borderRadius: BorderRadius.circular(3),
    ),
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: share.clamp(0, 1).toDouble(),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    ),
  );
}

/// The curve and the columns, drawn as the canvas does in a 120 × 30 box
/// stretched to the tile.
class _VisualPainter extends CustomPainter {
  _VisualPainter(this.visual);

  final TileVisual visual;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 120;
    final sy = size.height / 30;
    switch (visual) {
      case TileCurve(:final values, :final color):
        if (values.isEmpty) return;
        final top = math.max(1, values.reduce(math.max));
        final n = values.length;
        final path = Path();
        for (final (i, v) in values.indexed) {
          final x = (2 + (n == 1 ? 0 : i * 116 / (n - 1))) * sx;
          final y = (27 - v / top * 24) * sy;
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        );
      case TileColumns(:final values, :final highlight, :final color):
        if (values.isEmpty) return;
        final top = math.max(1, values.reduce(math.max));
        final w = 120 / values.length;
        for (final (i, v) in values.indexed) {
          final h = math.max(2, v / top * 28);
          canvas.drawRect(
            Rect.fromLTWH(
              (i * w + w * 0.18) * sx,
              (30 - h) * sy,
              w * 0.64 * sx,
              h * sy,
            ),
            Paint()..color = i == highlight ? color : KibuoColors.track,
          );
        }
      case TileBar():
        break;
    }
  }

  @override
  bool shouldRepaint(_VisualPainter old) => old.visual != visual;
}

/// The arrow leaning up or down before a change (canvas ApercuP2).
class TrendArrow extends CustomPainter {
  TrendArrow({required this.up, required this.color});

  final bool up;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = up
        ? (Path()
            ..moveTo(7 * s, 17 * s)
            ..lineTo(17 * s, 7 * s)
            ..moveTo(9 * s, 7 * s)
            ..lineTo(17 * s, 7 * s)
            ..lineTo(17 * s, 15 * s))
        : (Path()
            ..moveTo(7 * s, 7 * s)
            ..lineTo(17 * s, 17 * s)
            ..moveTo(17 * s, 9 * s)
            ..lineTo(17 * s, 17 * s)
            ..lineTo(9 * s, 17 * s));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, 2.6 * s)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(TrendArrow old) => old.up != up || old.color != color;
}
