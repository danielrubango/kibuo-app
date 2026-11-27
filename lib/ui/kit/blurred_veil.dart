import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// How much the screen behind is blurred (DIRECTION « Fond flouté »).
const blurredVeilSigma = 8.0;

/// What stands behind something brought to the front of a page (a tile
/// enlarged, an open line, a tip, a guide): the whole screen blurred and
/// darkened, edge to edge, the same everywhere (DIRECTION « Fond flouté »,
/// 27 November 2026).
///
/// The blur comes at once, as soon as [veil] is above 0; only the veil's
/// darkness follows [veil], from 0 to 1, so a caller fades it in and out.
/// A [window] stays clear, its corners rounded by [radius] (a guide). The
/// veil holds every touch; [onTap] says what a touch on it does.
class BlurredVeil extends StatelessWidget {
  const BlurredVeil({
    super.key,
    this.veil = 1,
    this.window,
    this.radius = 0,
    this.onTap,
  });

  final double veil;
  final Rect? window;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (veil <= 0) return const SizedBox.expand();
    final shade = KibuoColors.blurVeil;
    final layer = BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: blurredVeilSigma,
        sigmaY: blurredVeilSigma,
      ),
      child: ColoredBox(
        color: shade.withValues(alpha: shade.a * veil.clamp(0.0, 1.0)),
      ),
    );
    final window = this.window;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () {},
      child: window == null
          ? ClipRect(child: layer)
          : ClipPath(clipper: _Around(window, radius), child: layer),
    );
  }
}

/// The whole screen but [window].
class _Around extends CustomClipper<Path> {
  _Around(this.window, this.radius);

  final Rect window;
  final double radius;

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addRRect(RRect.fromRectAndRadius(window, Radius.circular(radius)));

  @override
  bool shouldReclip(_Around old) =>
      old.window != window || old.radius != radius;
}
