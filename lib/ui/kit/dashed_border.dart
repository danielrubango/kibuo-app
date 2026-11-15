import 'package:flutter/widgets.dart';

/// A dashed rounded outline around [child]: optional code boxes, « Créer un
/// autre type ».
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    required this.radius,
    required this.color,
    this.width = 1.5,
  });

  final Widget child;
  final double radius;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: DashedRRectPainter(
        radius: radius,
        color: color,
        width: width,
      ),
      child: child,
    );
  }
}

class DashedRRectPainter extends CustomPainter {
  const DashedRRectPainter({
    required this.radius,
    required this.color,
    this.width = 1.5,
  });

  final double radius;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(radius),
    );
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) =>
      old.color != color || old.radius != radius || old.width != width;
}
