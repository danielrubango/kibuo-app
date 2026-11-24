import 'package:flutter/material.dart';

/// A bar with what is done in full colour and the part being added
/// hatched (canvas RembourserV3, ProjetP1); 12 high.
class HatchedBar extends StatelessWidget {
  const HatchedBar({
    super.key,
    required this.done,
    required this.after,
    required this.ink,
    required this.track,
    required this.hatch,
  });

  final double done;
  final double after;
  final Color ink;
  final Color track;
  final Color hatch;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 12,
    child: CustomPaint(painter: _HatchPainter(done, after, ink, track, hatch)),
  );
}

class _HatchPainter extends CustomPainter {
  _HatchPainter(this.done, this.after, this.ink, this.track, this.hatch);

  final double done;
  final double after;
  final Color ink;
  final Color track;
  final Color hatch;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    final doneW = size.width * done;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, doneW, size.height),
      Paint()..color = ink,
    );
    final part = Rect.fromLTWH(
      doneW + (doneW > 0 ? 2 : 0),
      0,
      (size.width * after - doneW - (doneW > 0 ? 2 : 0)).clamp(0, size.width),
      size.height,
    );
    canvas.save();
    canvas.clipRect(part);
    canvas.drawRect(part, Paint()..color = track);
    final stripe = Paint()
      ..color = hatch
      ..strokeWidth = 4;
    for (
      var x = part.left - size.height;
      x < part.right + size.height;
      x += 8
    ) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatchPainter old) =>
      old.done != done || old.after != after;
}
