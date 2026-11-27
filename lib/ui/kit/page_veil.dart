import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// How much the screen behind an enlarged tile is blurred (DIRECTION
/// « Derrière ce qui passe devant »).
const pageVeilBlur = 8.0;

/// What stands behind something brought to the front of a page, edge to
/// edge (DIRECTION « Derrière ce qui passe devant », 27 November 2026): the
/// + sheet's veil, ink at 42 % with the page still readable (an open line,
/// a tip, a guide), or, [blurred], the screen blurred under ink at 32 % (an
/// enlarged tile).
///
/// Only the veil's darkness follows [veil], from 0 to 1, so a caller fades
/// it in and out; a blur comes at once, as soon as [veil] is above 0. A
/// [window] stays clear, its corners rounded by [radius] (a guide). The
/// veil holds every touch; [onTap] says what a touch on it does.
class PageVeil extends StatelessWidget {
  const PageVeil({
    super.key,
    this.veil = 1,
    this.blurred = false,
    this.window,
    this.radius = 0,
    this.onTap,
  });

  final double veil;
  final bool blurred;
  final Rect? window;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (veil <= 0) return const SizedBox.expand();
    final shade = blurred ? KibuoColors.blurVeil : KibuoColors.scrim;
    final Widget tint = ColoredBox(
      color: shade.withValues(alpha: shade.a * veil.clamp(0.0, 1.0)),
    );
    final layer = blurred
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: pageVeilBlur,
              sigmaY: pageVeilBlur,
            ),
            child: tint,
          )
        : tint;
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
