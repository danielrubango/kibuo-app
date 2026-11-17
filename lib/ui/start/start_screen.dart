import 'package:flutter/material.dart';

import 'package:kibuo/ui/brand/kibuo_mark.dart';
import 'package:kibuo/ui/brand/kibuo_wordmark.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// Shown when Kibuo really starts, right after Android's own start screen.
///
/// The logo sits exactly where Android drew it, so the hand-over does not
/// show; then the coin slips into the slot and the name appears. The screen
/// stays [minimum] at least, and longer only while the app is not [ready].
/// Coming back from another app never shows it.
class StartGate extends StatefulWidget {
  const StartGate({
    super.key,
    required this.child,
    this.ready,
    this.minimum = const Duration(milliseconds: 1500),
  });

  /// What comes after: the PIN screen or Accueil.
  final Widget child;

  /// Completes when the app can open, e.g. once the database is open.
  final Future<void>? ready;

  final Duration minimum;

  @override
  State<StartGate> createState() => _StartGateState();
}

class _StartGateState extends State<StartGate> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Count the minimum from the first frame on screen, not from start-up:
    // on a slow phone the first frame can take a while.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.wait([
        Future<void>.delayed(widget.minimum),
        if (widget.ready != null) widget.ready!,
      ]).then((_) {
        if (mounted) setState(() => _done = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: _done ? widget.child : const StartScreen(),
    );
  }
}

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  /// Size of the 96 logo box. Android draws its start-screen logo
  /// (android/app/src/main/res/drawable/splash_icon.xml) at 288 dp for 108
  /// units, enlarged by 1.1: one logo unit is 288 / 108 × 1.1 dp.
  static const logoBox = 96 * 288 / 108 * 1.1;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _started = true;
      // Start once the logo is on screen, so the coin's slide is seen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final centre = size.center(Offset.zero);
    const box = StartScreen.logoBox;
    return Semantics(
      label: 'kibuo',
      container: true,
      excludeSemantics: true,
      child: Material(
        color: KibuoColors.background,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            // Canvas DemarrageE with C's piggy bank, in seconds.
            final sec = _controller.value * .9;
            double part(double from, double to, [Curve c = Curves.easeInOut]) =>
                c.transform(((sec - from) / (to - from)).clamp(0.0, 1.0));
            // The coin falls 4 units, bounces back to 2.4, settles at 3.
            final drop = sec < .30
                ? 4 * part(0, .30)
                : sec < .42
                ? 4 - 1.6 * part(.30, .42)
                : 2.4 + .6 * part(.42, .52);
            // The piggy bank takes the coin: flattened, then round again.
            final squash = sec < .52 ? part(.40, .52) : 1 - part(.52, .68);
            // The name grows a little and closes up its letters.
            final grow = part(.40, .85, const Cubic(.34, 1.56, .64, 1));
            final seen = part(.40, .85, Curves.linear);
            return Stack(
              children: [
                Positioned(
                  left: centre.dx - box / 2,
                  top: centre.dy - box / 2,
                  width: box,
                  height: box,
                  child: CustomPaint(
                    painter: KibuoMarkPainter(coinDrop: drop, squash: squash),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  // Under the circle, whose bottom is 25 units below centre.
                  top: centre.dy + box / 96 * 25 + 28,
                  child: Opacity(
                    opacity: seen,
                    child: Transform.scale(
                      scale: .85 + .15 * grow,
                      child: Center(
                        child: KibuoWordmark(letterSpacing: 8 - 8.5 * grow),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
