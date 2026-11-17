import 'package:flutter/material.dart';
import 'package:kibuo/domain/budgets/budget_curve.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

enum ChartView { total, pace }

/// « Au fil du mois » (canvas BudgetDetail, BudgetRythme): the running
/// total in steps, against the budget (Total) or the regular pace
/// (Rythme), with today's mark.
class BudgetChart extends StatelessWidget {
  const BudgetChart({
    super.key,
    required this.view,
    required this.steps,
    required this.days,
    required this.amount,
    required this.color,
    required this.budgetLabel,
    this.today,
    this.gapLabel,
    this.gapAhead = false,
  });

  final ChartView view;
  final List<CurveStep> steps;

  /// The period's length in days.
  final int days;

  /// The budget, in minor units.
  final int amount;

  /// The bar's colour: grey, amber or peach.
  final Color color;

  /// « Budget 100 $ ».
  final String budgetLabel;

  /// Today's day in the period (0 for its first), when it is the current one.
  final int? today;

  /// « +70 $ d'avance », « 20 $ de marge », at today's mark in Rythme.
  final String? gapLabel;
  final bool gapAhead;

  static const height = 144.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) {
          final painter = _ChartPainter(
            view: view,
            steps: steps,
            days: days,
            amount: amount,
            color: color,
            today: today,
            gapAhead: gapAhead,
          );
          final x = today == null
              ? null
              : painter.xOf(today! + 1, box.maxWidth);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: CustomPaint(painter: painter)),
              if (view == ChartView.total)
                Positioned(
                  left: 0,
                  top: painter.yOf(amount.toDouble()) - 16,
                  child: Text(
                    budgetLabel,
                    style: KibuoType.caption.copyWith(fontSize: 10),
                  ),
                ),
              if (view == ChartView.pace && gapLabel != null && x != null)
                Positioned(
                  right: box.maxWidth - x + 6,
                  top: 2,
                  child: Text(
                    gapLabel!,
                    style: KibuoType.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation.weight(700)],
                      color: gapAhead
                          ? KibuoColors.debtInk
                          : KibuoColors.accent,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.view,
    required this.steps,
    required this.days,
    required this.amount,
    required this.color,
    required this.today,
    required this.gapAhead,
  });

  final ChartView view;
  final List<CurveStep> steps;
  final int days;
  final int amount;
  final Color color;
  final int? today;
  final bool gapAhead;

  static const _top = 14.0;
  static const _bottom = BudgetChart.height - 14;

  double get _max {
    final spent = steps.isEmpty ? 0 : steps.last.total;
    final top = [amount * 1.25, spent * 1.1].reduce((a, b) => a > b ? a : b);
    return top <= 0 ? 1 : top;
  }

  double xOf(num day, double width) => width * (day / days).clamp(0, 1);

  double yOf(double value) => _bottom - value / _max * (_bottom - _top);

  /// The running total as points: flat until each step, then up.
  List<Offset> _path(double width, int lastDay) {
    final points = <Offset>[Offset(0, yOf(0))];
    var total = 0.0;
    for (final s in steps) {
      if (s.day > lastDay) break;
      final x = xOf(s.day + 0.5, width);
      points
        ..add(Offset(x, yOf(total)))
        ..add(Offset(x, yOf(s.total.toDouble())));
      total = s.total.toDouble();
    }
    points.add(Offset(xOf(lastDay + 1, width), yOf(total)));
    return points;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final lastDay = today ?? days - 1;
    canvas.drawLine(
      Offset(0, _bottom),
      Offset(w, _bottom),
      Paint()
        ..color = KibuoColors.track
        ..strokeWidth = 1,
    );
    final budgetY = yOf(amount.toDouble());
    final points = _path(w, lastDay);
    final line = Path()..addPolygon(points, false);

    if (view == ChartView.total) {
      // Past the budget, tinted.
      canvas.drawRect(
        Rect.fromLTRB(0, 0, w, budgetY),
        Paint()..color = KibuoColors.debtTint.withValues(alpha: 0.55),
      );
      _dashed(
        canvas,
        Offset(0, budgetY),
        Offset(w, budgetY),
        2,
        3,
        KibuoColors.inkSecondary,
        1,
      );
      final area = Path()
        ..addPolygon([...points, Offset(points.last.dx, _bottom)], true);
      canvas.drawPath(area, Paint()..color = color.withValues(alpha: 0.12));
    } else {
      // The regular pace, from nothing to the budget at the period's end.
      _dashed(
        canvas,
        Offset(0, _bottom),
        Offset(w, budgetY),
        4,
        4,
        KibuoColors.inkSecondary,
        1.5,
      );
      // The gap to it, day by day, up to today.
      final gap = Paint()
        ..color = gapAhead ? KibuoColors.debtTint : KibuoColors.accentTint;
      for (var i = 0; i < points.length - 1; i++) {
        final a = points[i];
        final b = points[i + 1];
        if (b.dx <= a.dx) continue;
        final paceA = _bottom - (_bottom - budgetY) * a.dx / w;
        final paceB = _bottom - (_bottom - budgetY) * b.dx / w;
        canvas.drawPath(
          Path()..addPolygon([
            a,
            Offset(b.dx, a.dy),
            Offset(b.dx, paceB),
            Offset(a.dx, paceA),
          ], true),
          gap,
        );
      }
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    if (view == ChartView.total) {
      for (final s in steps) {
        if (s.day > lastDay) break;
        final c = Offset(xOf(s.day + 0.5, w), yOf(s.total.toDouble()));
        canvas
          ..drawCircle(c, 4, Paint()..color = KibuoColors.surface)
          ..drawCircle(
            c,
            4,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
      }
    }
    if (today != null) {
      final x = xOf(today! + 1, w);
      canvas.drawLine(
        Offset(x, _top - 6),
        Offset(x, _bottom),
        Paint()
          ..color = KibuoColors.ink
          ..strokeWidth = 1,
      );
    }
  }

  void _dashed(
    Canvas canvas,
    Offset from,
    Offset to,
    double dash,
    double gap,
    Color color,
    double width,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width;
    final length = (to - from).distance;
    final step = (to - from) / length;
    for (var d = 0.0; d < length; d += dash + gap) {
      final end = (d + dash).clamp(0, length).toDouble();
      canvas.drawLine(from + step * d, from + step * end, paint);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.view != view ||
      old.steps != steps ||
      old.amount != amount ||
      old.color != color ||
      old.today != today;
}
