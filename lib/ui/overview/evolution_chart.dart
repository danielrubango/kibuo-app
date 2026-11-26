import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kibuo/domain/overview/overview_choice.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The Aperçu's chart (canvas ApercuP2): the period's bars, the compared
/// period as a curve or as sticks behind them, the marks under the bars,
/// then the legend with both names.
class EvolutionChart extends StatelessWidget {
  const EvolutionChart({
    super.key,
    required this.values,
    required this.ahead,
    required this.marks,
    required this.out,
    required this.currentName,
    this.compared,
    this.comparedName,
    this.comparedAs = ComparedAs.curve,
  });

  /// The period's bars, in the main currency's minor unit.
  final List<int> values;

  /// The bars that have not begun yet, paler.
  final List<bool> ahead;

  /// What is written under each bar.
  final List<String?> marks;

  /// Exits (peach) or entries (green).
  final bool out;
  final String currentName;

  /// The compared period's bars, by the same index; null without
  /// comparison.
  final List<int>? compared;
  final String? comparedName;
  final ComparedAs comparedAs;

  static const _height = 120.0;

  @override
  Widget build(BuildContext context) {
    final compared = this.compared;
    final sticks = comparedAs == ComparedAs.sticks;
    final legend = KibuoType.caption;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: _height + 1,
            child: CustomPaint(
              painter: _BarsPainter(
                values: values,
                ahead: ahead,
                out: out,
                compared: compared,
                sticks: sticks,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ExcludeSemantics(
          child: SizedBox(
            height: 13,
            child: LayoutBuilder(
              builder: (context, box) {
                final w = box.maxWidth / math.max(1, marks.length);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final (i, mark) in marks.indexed)
                      if (mark != null)
                        Positioned(
                          left: (i + 0.5) * w - 24,
                          width: 48,
                          top: 0,
                          child: Text(
                            mark,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: KibuoType.caption.copyWith(
                              fontSize: 10,
                              height: 1.2,
                            ),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _Swatch(
              width: 10,
              height: 10,
              radius: 3,
              color: out ? KibuoColors.debtLine : KibuoColors.chartIn,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                currentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: legend,
              ),
            ),
            if (compared != null && comparedName != null) ...[
              const SizedBox(width: 14),
              sticks
                  ? const _Swatch(
                      width: 10,
                      height: 10,
                      radius: 3,
                      color: KibuoColors.track,
                    )
                  : const _Swatch(
                      width: 14,
                      height: 2,
                      radius: 1,
                      color: KibuoColors.chartCompared,
                    ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  comparedName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: legend,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.width,
    required this.height,
    required this.radius,
    required this.color,
  });

  final double width;
  final double height;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.ahead,
    required this.out,
    required this.compared,
    required this.sticks,
  });

  final List<int> values;
  final List<bool> ahead;
  final bool out;
  final List<int>? compared;
  final bool sticks;

  @override
  void paint(Canvas canvas, Size size) {
    const h = EvolutionChart._height;
    // The line under the bars.
    canvas.drawRect(
      Rect.fromLTWH(0, h, size.width, 1),
      Paint()..color = KibuoColors.background,
    );
    final n = values.length;
    if (n == 0) return;
    final w = size.width / n;
    final compared = this.compared;
    final shown = compared == null ? 0 : math.min(n, compared.length);
    var top = 1;
    for (final v in values) {
      top = math.max(top, v);
    }
    for (var i = 0; i < shown; i++) {
      top = math.max(top, compared![i]);
    }
    final inset = n > 20 ? 1.0 : 3.0;

    void bar(double left, double width, double height, Color color) {
      if (height <= 0 || width <= 0) return;
      final r = Radius.circular(math.min(4, width / 2));
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, h - height, width, height),
          topLeft: r,
          topRight: r,
        ),
        Paint()..color = color,
      );
    }

    if (compared != null && sticks) {
      for (var i = 0; i < shown; i++) {
        bar(
          i * w + inset,
          w - 2 * inset,
          compared[i] / top * h,
          KibuoColors.track,
        );
      }
    }

    final side = compared != null && sticks ? w * 0.22 : inset;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      if (v <= 0) continue;
      final color = ahead[i]
          ? (out ? KibuoColors.chartOutAhead : KibuoColors.chartInAhead)
          : (out ? KibuoColors.debtLine : KibuoColors.chartIn);
      bar(i * w + side, w - 2 * side, math.max(v / top * h, h * 0.03), color);
    }

    if (compared == null || sticks || shown == 0) return;
    // A soft curve through the compared values (Catmull-Rom, as the
    // canvas draws it), with a point on each.
    final points = [
      for (var i = 0; i < shown; i++)
        Offset((i + 0.5) * w, h - compared[i] / top * h),
    ];
    double clamp(double y) => y.clamp(-0.04 * h, h);
    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[math.max(i - 1, 0)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[math.min(i + 2, points.length - 1)];
      path.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        clamp(p1.dy + (p2.dy - p0.dy) / 6),
        p2.dx - (p3.dx - p1.dx) / 6,
        clamp(p2.dy - (p3.dy - p1.dy) / 6),
        p2.dx,
        p2.dy,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = KibuoColors.chartCompared
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    final dot = (n > 20 ? 5.0 : 7.0) / 2;
    final fill = Paint()..color = KibuoColors.surface;
    final ring = Paint()
      ..color = KibuoColors.chartCompared
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final p in points) {
      canvas.drawCircle(p, dot, fill);
      canvas.drawCircle(p, dot - 0.75, ring);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values ||
      old.ahead != ahead ||
      old.out != out ||
      old.compared != compared ||
      old.sticks != sticks;
}
