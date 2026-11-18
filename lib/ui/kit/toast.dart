import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

OverlayEntry? _shown;
Timer? _timer;

/// How long a message with an action stays: as long as the sheet after a
/// save (DIRECTION).
const toastWithActionFor = Duration(seconds: 6);
const _toastFor = Duration(milliseconds: 2600);

/// A short message above the tab bar (canvas BrouillonA3): ink, 14 round,
/// a mint check, gone after a moment. With an [action] (« Annuler »), it
/// stays [toastWithActionFor], and while a finger is on it. A new one
/// replaces the last.
void showKibuoToast(
  BuildContext context,
  String text, {
  String? action,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  hideKibuoToast();
  late final OverlayEntry entry;
  final stay = action == null ? _toastFor : toastWithActionFor;
  void close() {
    if (_shown == entry) hideKibuoToast();
  }

  void start() {
    _timer?.cancel();
    _timer = Timer(stay, close);
  }

  entry = OverlayEntry(
    builder: (context) => _Toast(
      text: text,
      action: action,
      onAction: onAction == null
          ? null
          : () {
              close();
              onAction();
            },
      onHold: () => _timer?.cancel(),
      onRelease: start,
    ),
  );
  _shown = entry;
  overlay.insert(entry);
  start();
}

/// Takes the message away now.
void hideKibuoToast() {
  _timer?.cancel();
  _timer = null;
  _shown?.remove();
  _shown = null;
}

class _Toast extends StatelessWidget {
  const _Toast({
    required this.text,
    required this.onHold,
    required this.onRelease,
    this.action,
    this.onAction,
  });

  final String text;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback onHold;
  final VoidCallback onRelease;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom + 96;
    final action = this.action;
    final card = Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(14, action == null ? 12 : 0, 6, 0),
        constraints: BoxConstraints(minHeight: action == null ? 0 : 52),
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
        child: Padding(
          padding: EdgeInsets.only(bottom: action == null ? 12 : 0),
          child: Row(
            children: [
              const Icon(KibuoIcons.check, size: 20, color: KibuoColors.mint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: KibuoType.body.copyWith(color: KibuoColors.surface),
                ),
              ),
              if (action != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: KibuoColors.mint,
                    minimumSize: const Size(
                      KibuoTheme.heightTouch,
                      KibuoTheme.heightTouch,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: KibuoType.buttonSmall,
                  ),
                  child: Text(action),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
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
        child: action == null
            ? IgnorePointer(child: card)
            // Kept while a finger is on it.
            : Listener(
                onPointerDown: (_) => onHold(),
                onPointerUp: (_) => onRelease(),
                onPointerCancel: (_) => onRelease(),
                child: card,
              ),
      ),
    );
  }
}
