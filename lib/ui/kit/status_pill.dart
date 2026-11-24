import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// A small tag, 22 high, bold in [ink] on [tint] (« En retard », « En
/// avance », « Terminé »).
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.text,
    required this.ink,
    required this.tint,
  });

  final String text;
  final Color ink;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: KibuoType.caption.copyWith(fontSize: 11, color: ink).weight(700),
    ),
  );
}
