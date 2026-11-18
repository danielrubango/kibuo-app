import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

OverlayEntry? _shown;
Timer? _timer;

/// A short message above the tab bar (canvas BrouillonA3): ink, 14 round,
/// a mint check, gone after a moment. A new one replaces the last.
void showKibuoToast(BuildContext context, String text) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _timer?.cancel();
  _shown?.remove();
  final entry = OverlayEntry(builder: (context) => _Toast(text: text));
  _shown = entry;
  overlay.insert(entry);
  _timer = Timer(const Duration(milliseconds: 2600), () {
    if (_shown == entry) {
      entry.remove();
      _shown = null;
    }
  });
}

class _Toast extends StatelessWidget {
  const _Toast({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom + 96;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 180),
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - t)),
              child: child,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: KibuoColors.ink,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x400E1320),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    KibuoIcons.check,
                    size: 20,
                    color: KibuoColors.mint,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: KibuoType.body.copyWith(
                        color: KibuoColors.surface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
