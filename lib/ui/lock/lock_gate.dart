import 'package:flutter/material.dart';
import 'package:kibuo/ui/brand/kibuo_mark.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/unlock_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Shows the unlock screen over the app while it is locked, locks it again
/// after the chosen absence, and covers the balances when Kibuo leaves the
/// screen on Android 8 to 12 (newer versions hide the preview themselves).
class LockGate extends StatefulWidget {
  const LockGate({
    super.key,
    required this.controller,
    required this.eraseAll,
    required this.child,
  });

  final LockController controller;
  final Future<void> Function() eraseAll;
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  late final AppLifecycleListener _lifecycle;
  bool _covered = false;

  LockController get _lock => widget.controller;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () => setState(() => _covered = _lock.coversPreview),
      onHide: _lock.left,
      onShow: _lock.returned,
      onResume: () => setState(() => _covered = false),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KibuoLock(
      controller: _lock,
      eraseAll: widget.eraseAll,
      child: ListenableBuilder(
        listenable: _lock,
        builder: (context, _) => Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (_lock.ready && _lock.locked)
              Positioned.fill(
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => UnlockScreen(
                      controller: _lock,
                      onUnlocked: _lock.unlock,
                    ),
                  ),
                ),
              ),
            if (!_lock.ready) const Positioned.fill(child: _Cover(logo: false)),
            if (_covered) const Positioned.fill(child: _Cover(logo: true)),
          ],
        ),
      ),
    );
  }
}

/// The logo in place of the balances, as seen in recent apps.
class _Cover extends StatelessWidget {
  const _Cover({required this.logo});

  final bool logo;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: KibuoColors.background,
      child: !logo
          ? null
          : const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 96,
                    child: CustomPaint(painter: KibuoMarkPainter()),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Kibuo',
                    style: TextStyle(
                      fontFamily: KibuoTheme.brandFont,
                      fontVariations: [FontVariation.weight(700)],
                      fontSize: 28,
                      color: KibuoColors.ink,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
