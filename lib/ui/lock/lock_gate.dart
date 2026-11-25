import 'package:flutter/material.dart';
import 'package:kibuo/ui/brand/kibuo_mark.dart';
import 'package:kibuo/ui/brand/kibuo_wordmark.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/unlock_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// Shows the unlock screen over the app while it is locked, locks it again
/// after the chosen absence, and covers the balances when kibuo leaves the
/// screen on Android 8 to 12 (newer versions hide the preview themselves).
///
/// It sits on Accueil, once the data is open. Under a [LockLayer] (above
/// every screen, main.dart), it hands the lock over to it after its first
/// frame, so screens and sheets opened over Accueil are covered too and see
/// the lock (fixed 25 November 2026). Without one (some tests), it covers
/// Accueil alone, as before.
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
  _LockLayerState? _layer;
  bool _handedOver = false;

  @override
  void initState() {
    super.initState();
    _layer = context.findAncestorStateOfType<_LockLayerState>();
    if (_layer != null) {
      // After this first frame, where Accueil is covered here: the layer
      // takes over, and this gate only keeps its place.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _layer!._attach(this);
        setState(() => _handedOver = true);
      });
    }
  }

  @override
  void dispose() {
    _layer?._detach(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KibuoLock(
    controller: widget.controller,
    eraseAll: widget.eraseAll,
    // The child keeps its place whatever covers it: no state is lost when
    // the layer takes over.
    child: _LockStack(
      controller: widget.controller,
      active: !_handedOver,
      child: widget.child,
    ),
  );
}

/// Above every screen (MaterialApp's builder): once a [LockGate] has
/// handed it the lock, it covers screens, sheets and Accueil alike, and
/// gives the lock to every screen (the code of important actions).
class LockLayer extends StatefulWidget {
  const LockLayer({super.key, required this.child});

  /// The app's navigator, with every screen.
  final Widget child;

  @override
  State<LockLayer> createState() => _LockLayerState();
}

class _LockLayerState extends State<LockLayer> {
  _LockGateState? _gate;

  void _attach(_LockGateState gate) => setState(() => _gate = gate);

  void _detach(_LockGateState gate) {
    if (_gate != gate) return;
    _gate = null;
    // Called while the gate is being disposed: rebuild after this frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final gate = _gate?.widget;
    return KibuoLock(
      controller: gate?.controller,
      eraseAll: gate?.eraseAll ?? () async {},
      child: _LockStack(
        controller: gate?.controller,
        active: gate != null,
        child: widget.child,
      ),
    );
  }
}

/// [child], with the unlock screen over it while locked, a plain cover
/// until the lock is ready, and the logo while kibuo leaves the screen.
/// Inactive, it shows [child] alone (the lock is handled elsewhere).
class _LockStack extends StatefulWidget {
  const _LockStack({
    required this.controller,
    required this.active,
    required this.child,
  });

  final LockController? controller;
  final bool active;
  final Widget child;

  @override
  State<_LockStack> createState() => _LockStackState();
}

class _LockStackState extends State<_LockStack> {
  late final AppLifecycleListener _lifecycle;
  bool _covered = false;

  LockController? get _lock => widget.active ? widget.controller : null;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onInactive: () {
        if (_lock case final lock?) {
          setState(() => _covered = lock.coversPreview);
        }
      },
      onHide: () => _lock?.left(),
      onShow: () => _lock?.returned(),
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
    final lock = _lock;
    final Listenable listenable = lock ?? const _Never();
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, child) => Stack(
        children: [
          Positioned.fill(child: child!),
          if (lock != null && lock.ready && lock.locked)
            Positioned.fill(
              // Its own navigator (« Code oublié ? » opens over it), apart
              // from the app's, whose transitions it must not share.
              child: HeroControllerScope.none(
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) =>
                        UnlockScreen(controller: lock, onUnlocked: lock.unlock),
                  ),
                ),
              ),
            ),
          if (lock != null && !lock.ready)
            const Positioned.fill(child: _Cover(logo: false)),
          if (lock != null && _covered)
            const Positioned.fill(child: _Cover(logo: true)),
        ],
      ),
      child: widget.child,
    );
  }
}

/// A listenable that never rings, while no lock applies.
class _Never implements Listenable {
  const _Never();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
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
                  KibuoWordmark(size: 28),
                ],
              ),
            ),
    );
  }
}
