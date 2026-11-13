import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// The four bottom-bar icons, from Phosphor.
///
/// At rest the regular (line) icon in grey. When its tab becomes active the
/// icon switches at once to its filled version in ink, zooms in a touch and
/// back, while a mint pill opens behind it, horizontally only. With Android's
/// « Supprimer les animations » on, it changes state without moving.
enum TabGlyph { home, operations, overview, more }

class KibuoTabIcon extends StatefulWidget {
  const KibuoTabIcon({super.key, required this.glyph, required this.active});

  final TabGlyph glyph;
  final bool active;

  @override
  State<KibuoTabIcon> createState() => _KibuoTabIconState();
}

class _KibuoTabIconState extends State<KibuoTabIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );

  @override
  void didUpdateWidget(KibuoTabIcon old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final zoom = active ? math.sin(math.pi * t) : 0.0;
        return SizedBox.fromSize(
          size: _PillPainter.size,
          child: CustomPaint(
            painter: active ? _PillPainter(progress: t) : null,
            child: Center(
              child: Transform.scale(
                scale: 1 + .06 * zoom,
                child: Icon(
                  _icon(widget.glyph, filled: active),
                  size: 24,
                  color: active ? KibuoColors.ink : KibuoColors.inkSecondary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static IconData _icon(TabGlyph glyph, {required bool filled}) =>
      switch (glyph) {
        TabGlyph.home => filled ? KibuoIcons.houseFill : KibuoIcons.house,
        TabGlyph.operations => filled ? KibuoIcons.listFill : KibuoIcons.list,
        TabGlyph.overview =>
          filled ? KibuoIcons.chartBarFill : KibuoIcons.chartBar,
        TabGlyph.more =>
          filled ? KibuoIcons.squaresFourFill : KibuoIcons.squaresFour,
      };
}

/// The mint pill behind the active icon. It widens from the centre in the
/// first 150 ms of the animation; [progress] runs from 0 to 1 over 240 ms.
class _PillPainter extends CustomPainter {
  const _PillPainter({required this.progress});

  final double progress;

  static const size = Size(56, 30);

  @override
  void paint(Canvas canvas, Size box) {
    final open = Curves.easeOutCubic.transform(
      (progress * 240 / 150).clamp(0.0, 1.0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: box.center(Offset.zero),
          width: lerpDouble(box.height, box.width, open)!,
          height: box.height,
        ),
        Radius.circular(box.height / 2),
      ),
      Paint()..color = KibuoColors.mint.withValues(alpha: open),
    );
  }

  @override
  bool shouldRepaint(_PillPainter old) => old.progress != progress;
}
