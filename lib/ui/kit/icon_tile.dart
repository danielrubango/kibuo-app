import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// An icon on its tinted square, 36 by default (rows of « À traiter »,
/// choices of a sheet, form rows, confirmations).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.tint = KibuoColors.background,
    this.ink = KibuoColors.inkSecondary,
    this.size = 36,
    this.iconSize = 18,
    this.radius = KibuoTheme.radiusPill,
  });

  final IconData icon;
  final Color tint;
  final Color? ink;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Icon(icon, size: iconSize, color: ink),
  );
}
