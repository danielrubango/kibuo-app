import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

// The parts of an enlarged tile (canvas « Tuiles agrandies », 27 November
// 2026): a white card, its landmarks, and the pictures the tiles share.

const _tints = [KibuoColors.debtLine, Color(0xFFF2C9A8), Color(0xFFF8DDC8)];

/// The card: name and period, the figure, a line under it, what the tile
/// shows, then its action (canvas ApercuTuile).
class EnlargedCard extends StatelessWidget {
  const EnlargedCard({
    super.key,
    required this.title,
    required this.figure,
    required this.children,
    required this.action,
    required this.onAction,
    required this.onClose,
    this.figureColor = KibuoColors.ink,
    this.line,
    this.badge,
  });

  final String title;
  final String figure;
  final Color figureColor;

  /// Beside the figure (Épargne's « 27 % gardés »).
  final Widget? badge;

  /// Under the figure: the change, or a plain line.
  final Widget? line;
  final List<Widget> children;
  final String action;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusSheet),
        boxShadow: const [
          BoxShadow(
            color: Color(0x470E1320),
            blurRadius: 50,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Material(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusSheet),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.caption.copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            figure,
                            maxLines: 1,
                            style: KibuoType.bigAmount.copyWith(
                              fontSize: 36,
                              height: 42 / 36,
                              color: figureColor,
                            ),
                          ),
                        ),
                      ),
                      if (badge != null) ...[const SizedBox(width: 10), badge],
                    ],
                  ),
                  if (line case final line?) ...[
                    const SizedBox(height: 2),
                    line,
                  ],
                  for (final child in children) ...[
                    const SizedBox(height: 10),
                    child,
                  ],
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
                    onTap: onAction,
                    child: SizedBox(
                      height: KibuoTheme.heightTouch,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              action,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KibuoType.buttonSmall.copyWith(
                                fontSize: 14,
                                color: KibuoColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            KibuoIcons.caretRight,
                            size: 16,
                            color: KibuoColors.accent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -10,
                right: -10,
                child: SizedBox.square(
                  dimension: KibuoTheme.heightTouch,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: onClose,
                    tooltip: MaterialLocalizations.of(context)
                        .closeButtonTooltip,
                    icon: const Icon(
                      KibuoIcons.x,
                      size: 22,
                      color: KibuoColors.inkSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A plain line under the figure.
class CardNote extends StatelessWidget {
  const CardNote(this.text, {super.key, this.color = KibuoColors.inkSecondary});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 2,
    style: KibuoType.caption.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      fontVariations: const [FontVariation.weight(500)],
      color: color,
    ),
  );
}

/// A small tinted pill beside the figure (« 27 % gardés »).
class CardBadge extends StatelessWidget {
  const CardBadge(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: KibuoColors.accentTint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: KibuoType.caption.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation.weight(700)],
        color: KibuoColors.accent,
      ),
    ),
  );
}

/// One landmark: its name at the left, the value and its line at the right.
///
/// [lead] stands before the value (Épargne's ring); [mark] before the
/// label, which is then in ink (an account's colour).
typedef Landmark = ({
  String label,
  String value,
  String sub,
  Color? color,
  Widget? lead,
  Widget? mark,
});

Landmark landmark(
  String label,
  String value,
  String sub, {
  Color? color,
  Widget? lead,
  Widget? mark,
}) => (
  label: label,
  value: value,
  sub: sub,
  color: color,
  lead: lead,
  mark: mark,
);

class LandmarkRows extends StatelessWidget {
  const LandmarkRows(this.rows, {super.key});

  final List<Landmark> rows;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // The value side never takes more than 60 % of the row: past that, its
    // line wraps instead of pushing the row out of the card.
    builder: (context, box) => Column(
      children: [
        for (final r in rows)
          Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: KibuoColors.background)),
            ),
            child: Row(
              children: [
                if (r.mark case final mark?) ...[
                  mark,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    r.label,
                    style: KibuoType.body.copyWith(
                      color: r.mark == null
                          ? KibuoColors.inkSecondary
                          : KibuoColors.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (r.lead case final lead?) ...[
                  lead,
                  const SizedBox(width: 10),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * 0.6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        r.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KibuoType.itemName.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                          color: r.color ?? KibuoColors.ink,
                        ),
                      ),
                      if (r.sub.isNotEmpty)
                        Text(
                          r.sub,
                          textAlign: TextAlign.end,
                          style: KibuoType.caption.copyWith(
                            fontSize: 11,
                            color: KibuoColors.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// The marks under a chart, spread from start to end.
class AxisLabels extends StatelessWidget {
  const AxisLabels(this.labels, {super.key, this.at});

  final List<String> labels;

  /// Where the middle label stands, from 0 to 1: under the day's line. An
  /// end label it would touch gives way.
  final double? at;

  @override
  Widget build(BuildContext context) {
    final style = KibuoType.caption.copyWith(
      fontSize: 11,
      color: KibuoColors.inkMuted,
    );
    final at = this.at;
    if (at == null || labels.length != 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (final l in labels) Text(l, style: style)],
      );
    }
    final scaler = MediaQuery.textScalerOf(context);
    Size sizeOf(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final size = painter.size;
      painter.dispose();
      return size;
    }

    return LayoutBuilder(
      builder: (context, box) {
        const gap = 6.0;
        final w = box.maxWidth;
        final first = sizeOf(labels[0]).width;
        final middle = sizeOf(labels[1]);
        final last = sizeOf(labels[2]).width;
        final left = (at * w - middle.width / 2)
            .clamp(0.0, math.max(0.0, w - middle.width))
            .toDouble();
        return SizedBox(
          height: middle.height,
          child: Stack(
            children: [
              if (left >= first + gap)
                Positioned(left: 0, child: Text(labels[0], style: style)),
              Positioned(
                left: left,
                child: Text(labels[1], style: style),
              ),
              if (left + middle.width + gap <= w - last)
                Positioned(right: 0, child: Text(labels[2], style: style)),
            ],
          ),
        );
      },
    );
  }
}

/// The period's colour and the compared line, with their names.
class ChartLegend extends StatelessWidget {
  const ChartLegend({
    super.key,
    required this.color,
    required this.name,
    this.comparedName,
    this.comparedSticks = false,
  });

  final Color color;
  final String name;
  final String? comparedName;
  final bool comparedSticks;

  @override
  Widget build(BuildContext context) {
    final style = KibuoType.caption;
    Widget swatch(double w, double h, double r, Color c) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(r),
      ),
    );
    final compared = comparedName;
    return Row(
      children: [
        swatch(10, 10, 3, color),
        const SizedBox(width: 6),
        Text(name, maxLines: 1, style: style),
        if (compared != null) ...[
          const SizedBox(width: 14),
          comparedSticks
              ? swatch(10, 10, 3, KibuoColors.track)
              : swatch(14, 2, 1, KibuoColors.inkMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              compared,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
      ],
    );
  }
}

Path _smooth(List<Offset> p, {double? low, double? high}) {
  double clamp(double y) =>
      y.clamp(low ?? double.negativeInfinity, high ?? double.infinity);
  final path = Path()..moveTo(p.first.dx, p.first.dy);
  for (var i = 0; i < p.length - 1; i++) {
    final p0 = p[math.max(i - 1, 0)];
    final p1 = p[i];
    final p2 = p[i + 1];
    final p3 = p[math.min(i + 2, p.length - 1)];
    // Each handle stays between its two points, so a sudden expense does
    // not dip the curve below the day before.
    final lo = math.min(p1.dy, p2.dy);
    final hi = math.max(p1.dy, p2.dy);
    double inside(double y) => clamp(y.clamp(lo, hi));
    path.cubicTo(
      p1.dx + (p2.dx - p0.dx) / 6,
      inside(p1.dy + (p2.dy - p0.dy) / 6),
      p2.dx - (p3.dx - p1.dx) / 6,
      inside(p2.dy - (p3.dy - p1.dy) / 6),
      p2.dx,
      p2.dy,
    );
  }
  return path;
}

void _paintPill(
  Canvas canvas,
  String text,
  double centre,
  double width,
  Color fill,
  Color ink,
) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: KibuoType.caption.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation.weight(700)],
        color: ink,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final w = painter.width + 16;
  final left = (centre - w / 2).clamp(0.0, math.max(0.0, width - w)).toDouble();
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 0, w, 20),
      const Radius.circular(10),
    ),
    Paint()..color = fill,
  );
  painter.paint(canvas, Offset(left + 8, (20 - painter.height) / 2));
  painter.dispose();
}

/// The running curve of the period against the compared one, the day's
/// amount on a dotted line rising to a label above the chart (DIRECTION,
/// 27 November 2026), the zero line when it goes below.
class DayLineChart extends StatelessWidget {
  const DayLineChart({
    super.key,
    required this.current,
    required this.compared,
    required this.points,
    required this.color,
    required this.tint,
    required this.dayLabel,
    required this.pill,
    required this.pillInk,
  });

  /// Running values of the days begun.
  final List<int> current;

  /// Running values of the compared period, or its straight line.
  final List<int>? compared;

  /// How many points the period has.
  final int points;
  final Color color;
  final Color tint;
  final String dayLabel;
  final Color pill;
  final Color pillInk;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 160,
      child: CustomPaint(painter: _LinePainter(this)),
    ),
  );
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.c);

  final DayLineChart c;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 30.0;
    final h = size.height - pad;
    final all = [...c.current, ...?c.compared];
    if (all.isEmpty) return;
    final top = math.max(1, all.reduce(math.max)) * 1.05;
    final low = math.min(0, all.reduce(math.min)) * 1.1;
    final n = math.max(2, c.points);
    double x(int i) => i * size.width / (n - 1);
    double y(int v) => pad + h - (v - low) / (top - low) * h;
    canvas.drawLine(
      Offset(0, pad + h),
      Offset(size.width, pad + h),
      Paint()..color = KibuoColors.track,
    );
    if (low < 0) {
      final zy = y(0);
      for (var dx = 0.0; dx < size.width; dx += 6) {
        canvas.drawLine(
          Offset(dx, zy),
          Offset(math.min(dx + 3, size.width), zy),
          Paint()..color = KibuoColors.track,
        );
      }
    }
    final compared = c.compared;
    if (compared != null && compared.length > 1) {
      // Over its own length: October's 31 days end where November's 30 do.
      final m = compared.length;
      canvas.drawPath(
        _smooth([
          for (final (i, v) in compared.indexed)
            Offset(i * size.width / (m - 1), y(v)),
        ]),
        Paint()
          ..color = KibuoColors.inkMuted
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
    if (c.current.isEmpty) return;
    final points = [for (final (i, v) in c.current.indexed) Offset(x(i), y(v))];
    if (points.length > 1) {
      final line = _smooth(points);
      final area = Path.from(line)
        ..lineTo(points.last.dx, pad + h)
        ..lineTo(0, pad + h)
        ..close();
      canvas.drawPath(area, Paint()..color = c.tint.withValues(alpha: 0.55));
      canvas.drawPath(
        line,
        Paint()
          ..color = c.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }
    final day = points.last;
    for (var dy = day.dy; dy > 20; dy -= 6) {
      canvas.drawLine(
        Offset(day.dx, dy),
        Offset(day.dx, math.max(20, dy - 3)),
        Paint()
          ..color = c.color
          ..strokeWidth = 1.2,
      );
    }
    _paintPill(canvas, c.dayLabel, day.dx, size.width, c.pill, c.pillInk);
    canvas.drawCircle(day, 4, Paint()..color = KibuoColors.surface);
    canvas.drawCircle(
      day,
      4,
      Paint()
        ..color = c.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}

/// One bar a day, the average as a dotted ink line (Moyenne).
class AverageBars extends StatelessWidget {
  const AverageBars({
    super.key,
    required this.values,
    required this.average,
    required this.marks,
  });

  final List<int> values;
  final int average;
  final List<String?> marks;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 110,
          child: CustomPaint(painter: _AveragePainter(values, average)),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final m in marks)
              Expanded(
                child: Text(
                  m ?? '',
                  textAlign: TextAlign.center,
                  style: KibuoType.caption.copyWith(
                    fontSize: 10,
                    color: KibuoColors.inkMuted,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _AveragePainter extends CustomPainter {
  _AveragePainter(this.values, this.average);

  final List<int> values;
  final int average;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    canvas.drawLine(
      Offset(0, h),
      Offset(size.width, h),
      Paint()..color = KibuoColors.track,
    );
    if (values.isEmpty) return;
    final top = math.max(1, math.max(values.reduce(math.max), average)) * 1.08;
    final w = size.width / values.length;
    final inset = values.length > 20 ? 1.0 : w * 0.14;
    for (final (i, v) in values.indexed) {
      if (v <= 0) continue;
      final bh = math.max(v / top * h, 3.0);
      final bw = w - 2 * inset;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(i * w + inset, h - bh, bw, bh),
          topLeft: Radius.circular(math.min(4, bw / 2)),
          topRight: Radius.circular(math.min(4, bw / 2)),
        ),
        Paint()..color = KibuoColors.debtLine,
      );
    }
    final ay = h - average / top * h;
    for (var dx = 0.0; dx < size.width; dx += 7) {
      canvas.drawLine(
        Offset(dx, ay),
        Offset(math.min(dx + 4, size.width), ay),
        Paint()
          ..color = KibuoColors.ink
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_AveragePainter old) => true;
}

/// The first ones in order: rank, name, amount, a bar of their share.
class RankedBars extends StatelessWidget {
  const RankedBars({super.key, required this.items, required this.color});

  final List<({String name, String value, String sub, double share})> items;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final (i, item) in items.indexed)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: KibuoColors.background)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${i + 1}',
                      style: KibuoType.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation.weight(700)],
                        color: KibuoColors.inkMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                      ),
                    ),
                  ),
                  Text(
                    item.value,
                    style: KibuoType.itemName.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation.weight(700)],
                      color: color == KibuoColors.debtLine
                          ? KibuoColors.debtInk
                          : color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: Bar(share: item.share, color: color),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.sub,
                    style: KibuoType.caption.copyWith(
                      fontSize: 11,
                      color: KibuoColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    ],
  );
}

/// A filling bar, with an optional mark (the plan of a project) and its
/// label above.
class Bar extends StatelessWidget {
  const Bar({
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

/// The calendar of Jour le plus cher (K2): each cell its name and its
/// amount, only the three priciest tinted, the cells to come grey.
class AmountCalendar extends StatelessWidget {
  const AmountCalendar({
    super.key,
    required this.labels,
    required this.amounts,
    required this.top,
    required this.columns,
    this.ahead = const {},
    this.lead = 0,
    this.header,
    this.cellHeight = 42,
    this.today = -1,
  });

  final List<String> labels;

  /// What each cell shows; empty for none.
  final List<String> amounts;

  /// The three priciest, priciest first.
  final List<int> top;
  final int columns;
  final Set<int> ahead;

  /// Empty cells before the first (a month starting mid-week).
  final int lead;

  /// The weekday letters above a month.
  final List<String>? header;
  final double cellHeight;

  /// Today's cell, outlined in ink; -1 for none.
  final int today;

  @override
  Widget build(BuildContext context) {
    final header = this.header;
    final cells = <Widget>[
      if (header != null)
        for (final h in header)
          Center(
            child: Text(
              h,
              style: KibuoType.caption.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontVariations: const [FontVariation.weight(600)],
                color: KibuoColors.inkMuted,
              ),
            ),
          ),
      for (var i = 0; i < lead; i++) const SizedBox.shrink(),
      for (final (i, label) in labels.indexed) _cell(i, label),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 3.0;
        final w = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (i, c) in cells.indexed)
              SizedBox(
                width: w,
                height: header != null && i < columns ? 14 : cellHeight,
                child: c,
              ),
          ],
        );
      },
    );
  }

  Widget _cell(int i, String label) {
    final future = ahead.contains(i);
    final rank = future ? -1 : top.indexOf(i);
    final tinted = rank >= 0;
    final ink = rank == 0 ? KibuoColors.surface : KibuoColors.ink;
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
      foregroundDecoration: i == today
          ? BoxDecoration(
              border: Border.all(color: KibuoColors.ink, width: 1.5),
              borderRadius: BorderRadius.circular(9),
            )
          : null,
      decoration: BoxDecoration(
        color: future
            ? KibuoColors.fillSoft
            : tinted
            ? _tints[rank]
            : KibuoColors.surface,
        border: tinted || future
            ? null
            : Border.all(color: KibuoColors.background),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            style: KibuoType.caption.copyWith(
              fontSize: 9,
              height: 1.1,
              color: tinted ? ink : KibuoColors.inkMuted,
            ),
          ),
          if (!future && amounts[i].isNotEmpty)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                amounts[i],
                style: KibuoType.caption.copyWith(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation.weight(700)],
                  color: ink,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The next 14 days in a row, a dot under each one with something due.
class DayRibbon extends StatelessWidget {
  const DayRibbon({super.key, required this.days});

  /// Letter, number and the dot's colour (null: nothing due).
  final List<({String letter, int day, Color? dot})> days;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final (i, d) in days.indexed) ...[
        if (i > 0) const SizedBox(width: 2),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: d.dot == null ? KibuoColors.surface : KibuoColors.fillSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  d.letter,
                  style: KibuoType.caption.copyWith(
                    fontSize: 10,
                    color: KibuoColors.inkMuted,
                  ),
                ),
                Text(
                  '${d.day}',
                  style: KibuoType.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation.weight(700)],
                    color: KibuoColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: d.dot ?? Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

/// A list where each line starts with a grey square holding a date (or a
/// dash), then a name and its line, the amount at the right (À venir,
/// Dettes, Créances).
class DatedList extends StatelessWidget {
  const DatedList({super.key, required this.items});

  final List<
    ({
      String day,
      String month,
      String name,
      String sub,
      bool late,
      String value,
      Color color,
    })
  >
  items;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final it in items)
        Container(
          constraints: const BoxConstraints(minHeight: 54),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: KibuoColors.background)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KibuoColors.fillSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      it.day,
                      style: KibuoType.itemName.copyWith(
                        fontSize: 15,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation.weight(700)],
                      ),
                    ),
                    if (it.month.isNotEmpty)
                      Text(
                        it.month,
                        style: KibuoType.caption.copyWith(fontSize: 10),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                      ),
                    ),
                    Text(
                      it.sub,
                      style: KibuoType.caption.copyWith(
                        fontSize: 11,
                        color: it.late
                            ? KibuoColors.danger
                            : KibuoColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                it.value,
                style: KibuoType.itemName.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation.weight(700)],
                  color: it.color,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

/// One bar cut in parts, each with its colour (Comptes).
class SplitBar extends StatelessWidget {
  const SplitBar({super.key, required this.parts, this.height = 20});

  final List<({double share, Color color})> parts;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, p) in parts.indexed) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              flex: math.max(1, (p.share * 1000).round()),
              child: ColoredBox(color: p.color),
            ),
          ],
        ],
      ),
    ),
  );
}

/// The colour, the name, the amount and its line.
class DotRows extends StatelessWidget {
  const DotRows(this.rows, {super.key});

  final List<({Color color, String name, String value, String sub})> rows;

  @override
  Widget build(BuildContext context) => LandmarkRows([
    for (final r in rows)
      landmark(
        r.name,
        r.value,
        r.sub,
        mark: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: r.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
  ]);
}

/// Accounts, plus what is owed to me, less my debts, gives the net worth.
class Waterfall extends StatelessWidget {
  const Waterfall({super.key, required this.steps});

  /// Label, amount and whether it starts from zero (a total).
  final List<({String label, int value, Color color, bool total})> steps;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 120,
          child: CustomPaint(painter: _WaterfallPainter(steps)),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final s in steps)
              Expanded(
                child: Text(
                  s.label,
                  textAlign: TextAlign.center,
                  style: KibuoType.caption.copyWith(fontSize: 11),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _WaterfallPainter extends CustomPainter {
  _WaterfallPainter(this.steps);

  final List<({String label, int value, Color color, bool total})> steps;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    canvas.drawLine(
      Offset(0, h),
      Offset(size.width, h),
      Paint()..color = KibuoColors.track,
    );
    if (steps.isEmpty) return;
    var top = 1;
    var base = 0;
    for (final s in steps) {
      base = s.total ? s.value : base + s.value;
      top = math.max(top, math.max(base, s.value.abs()));
    }
    final scale = h / (top * 1.1);
    final w = size.width / steps.length;
    base = 0;
    for (final (i, s) in steps.indexed) {
      final from = s.total ? 0 : base;
      final to = s.total ? s.value : base + s.value;
      final lo = math.min(from, to);
      final hi = math.max(from, to);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * w + w * 0.18,
            h - hi * scale,
            w * 0.64,
            math.max(s.total || hi == lo ? 2 : 10, (hi - lo) * scale),
          ),
          const Radius.circular(5),
        ),
        Paint()..color = s.color,
      );
      base = to;
    }
  }

  @override
  bool shouldRepaint(_WaterfallPainter old) => true;
}

/// The pager of enlarged tiles over the blurred Aperçu (canvas
/// ApercuTuile): the card 16 from the left, the next one showing at the
/// right edge, the dots and the hint just under the card; a touch beside,
/// ✕, a swipe down or back close it (PRODUCT, 27 November 2026).
class EnlargedPager extends StatefulWidget {
  const EnlargedPager({
    super.key,
    required this.count,
    required this.initial,
    required this.card,
    required this.hint,
  });

  final int count;
  final int initial;
  final Widget Function(BuildContext context, int index) card;
  final String hint;

  @override
  State<EnlargedPager> createState() => _EnlargedPagerState();
}

class _EnlargedPagerState extends State<EnlargedPager> {
  static const _side = 16.0;
  static const _gap = 18.0;
  static const _top = 16.0;

  PageController? _pages;
  late int _index = widget.initial;
  final _heights = <int, double>{};
  double _drag = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A page is the card and the gap after it; centred, it leaves the
    // card 16 from the left and the next one showing 16 at the right.
    final width = MediaQuery.sizeOf(context).width;
    _pages ??= PageController(
      initialPage: widget.initial,
      viewportFraction: (width - 2 * _side) / width,
    );
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  void _measured(int i, double height) {
    if (!mounted || _heights[i] == height) return;
    setState(() => _heights[i] = height);
  }

  /// The height of the card under the dots, between two cards while
  /// swiping.
  double? _cardHeight() {
    final pages = _pages!;
    final page = pages.hasClients && pages.position.hasContentDimensions
        ? pages.page ?? _index.toDouble()
        : _index.toDouble();
    final a = page.floor().clamp(0, widget.count - 1);
    final b = (a + 1).clamp(0, widget.count - 1);
    final ha = _heights[a];
    if (ha == null) return null;
    final hb = _heights[b] ?? ha;
    return ha + (hb - ha) * (page - a);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      onVerticalDragUpdate: (d) => _drag += d.delta.dy,
      onVerticalDragEnd: (d) {
        if (_drag > 80 || (d.primaryVelocity ?? 0) > 700) {
          Haptics.tap();
          _close();
        }
        _drag = 0;
      },
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned.fill(
                top: _top,
                child: PageView.builder(
                  controller: pages,
                  clipBehavior: Clip.none,
                  itemCount: widget.count,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: _gap),
                    child: SingleChildScrollView(
                      clipBehavior: Clip.none,
                      padding: const EdgeInsets.only(bottom: 72),
                      child: _Measured(
                        onHeight: (h) => _measured(i, h),
                        child: GestureDetector(
                          // A touch on the card does not close it.
                          onTap: () {},
                          child: widget.card(context, i),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: pages,
                builder: (context, _) {
                  final height = _cardHeight();
                  final top = height == null
                      ? box.maxHeight - 56
                      : math.min(_top + height + 14, box.maxHeight - 56);
                  return Positioned(
                    left: 0,
                    right: 0,
                    top: top,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: height == null ? 0 : 1,
                        child: _Dots(
                          count: widget.count,
                          index: _index,
                          hint: widget.hint,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where one is among the tiles, and how to move on.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.hint});

  final int count;
  final int index;
  final String hint;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == index
                    ? KibuoColors.surface
                    : KibuoColors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          hint,
          textAlign: TextAlign.center,
          style: KibuoType.caption.copyWith(
            color: KibuoColors.surface.withValues(alpha: 0.85),
          ),
        ),
      ),
    ],
  );
}

/// Tells its child's height once laid out, so the dots can sit under it.
class _Measured extends SingleChildRenderObjectWidget {
  const _Measured({required this.onHeight, required super.child});

  final ValueChanged<double> onHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasured(onHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasured render) =>
      render.onHeight = onHeight;
}

class _RenderMeasured extends RenderProxyBox {
  _RenderMeasured(this.onHeight);

  ValueChanged<double> onHeight;
  double? _told;

  @override
  void performLayout() {
    super.performLayout();
    final height = size.height;
    if (height == _told) return;
    _told = height;
    WidgetsBinding.instance.addPostFrameCallback((_) => onHeight(height));
  }
}

/// A small ring of a share, in mint (Épargne's « Part épargnée »).
class MiniRing extends StatelessWidget {
  const MiniRing({super.key, required this.share, this.size = 30});

  final double share;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _RingPainter(share)),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.share);

  final double share;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = KibuoColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * share.clamp(0, 1),
      false,
      Paint()
        ..color = KibuoColors.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.share != share;
}

/// What was kept each day, up in green, down in peach from a zero line
/// (Épargne as bars).
class NetBars extends StatelessWidget {
  const NetBars({super.key, required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 120,
      child: CustomPaint(painter: _NetPainter(values)),
    ),
  );
}

class _NetPainter extends CustomPainter {
  _NetPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final hi = math.max(1, values.reduce(math.max));
    final lo = math.min(0, values.reduce(math.min));
    final h = size.height;
    final zero = h * hi / (hi - lo);
    final w = size.width / values.length;
    final inset = values.length > 20 ? 1.0 : w * 0.14;
    for (final (i, v) in values.indexed) {
      if (v == 0) continue;
      final bh = math.max(2.0, v.abs() / (hi - lo) * h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * w + inset,
            v > 0 ? zero - bh : zero,
            w - 2 * inset,
            bh,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = v > 0 ? KibuoColors.chartIn : KibuoColors.debtLine,
      );
    }
    canvas.drawLine(
      Offset(0, zero),
      Offset(size.width, zero),
      Paint()..color = KibuoColors.track,
    );
  }

  @override
  bool shouldRepaint(_NetPainter old) => true;
}
