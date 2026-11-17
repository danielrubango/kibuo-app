import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// The Kibuo logo without its night background: the mint piggy bank with the
/// amber coin rising a third above it. Drawn on the 96 logo box of
/// `docs/design/logos/kibuo-logo.svg`, whose big circle sits on the exact
/// centre of the box.
///
/// [coinDrop] moves the coin down into the slot, in logo units; the part that
/// enters the slot is hidden by it. [squash] (0 to 1) flattens the piggy
/// bank a little from its base, as when it takes the coin.
class KibuoMarkPainter extends CustomPainter {
  const KibuoMarkPainter({this.coinDrop = 0, this.squash = 0});

  final double coinDrop;
  final double squash;

  static const _coinY = 27.0;
  static const _coinR = 10.0;
  static const _slotTop = 35.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 96, size.height / 96)
      // Flattened from the base of the circle: 3 % wider, 4 % lower.
      ..save()
      ..translate(48, 73)
      ..scale(1 + .03 * squash, 1 - .04 * squash)
      ..translate(-48, -73)
      ..drawCircle(const Offset(48, 48), 25, Paint()..color = KibuoColors.mint)
      ..restore();

    final coinY = _coinY + coinDrop;
    final edge = Paint()
      ..color = KibuoColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas
      ..save()
      ..clipRect(const Rect.fromLTRB(0, 0, 96, _slotTop))
      ..drawCircle(Offset(48, coinY), _coinR, Paint()..color = KibuoColors.coin)
      ..drawCircle(Offset(48, coinY), _coinR, edge);
    // The coin's edge along the slot, as in the logo.
    final dy = _slotTop - coinY;
    if (dy.abs() < _coinR) {
      final half = math.sqrt(_coinR * _coinR - dy * dy);
      canvas.drawLine(
        Offset(48 - half, _slotTop),
        Offset(48 + half, _slotTop),
        edge,
      );
    }
    canvas
      ..drawLine(
        Offset(45, coinY + 1.5),
        Offset(51, coinY + 1.5),
        Paint()
          ..color = KibuoColors.ink.withValues(alpha: .45)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      )
      ..restore()
      ..drawRRect(
        RRect.fromLTRBR(37, _slotTop, 59, 40, const Radius.circular(2.5)),
        Paint()..color = KibuoColors.ink,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(KibuoMarkPainter old) =>
      old.coinDrop != coinDrop || old.squash != squash;
}
