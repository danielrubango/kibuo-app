import 'package:flutter/material.dart';

import 'package:kibuo/ui/brand/kibuo_mark.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

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
    duration: const Duration(milliseconds: 750),
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
      label: 'Kibuo',
      container: true,
      excludeSemantics: true,
      child: Material(
        color: KibuoColors.background,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // The coin slips 3 units into the slot over the first 450 ms.
            final drop = Curves.easeInOut.transform((t / .6).clamp(0.0, 1.0));
            // The name fades in from 250 ms to 750 ms.
            final name = Curves.easeOut.transform(
              ((t - 1 / 3) / (2 / 3)).clamp(0.0, 1.0),
            );
            return Stack(
              children: [
                Positioned(
                  left: centre.dx - box / 2,
                  top: centre.dy - box / 2,
                  width: box,
                  height: box,
                  child: CustomPaint(
                    painter: KibuoMarkPainter(coinDrop: 3 * drop),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  // Under the circle, whose bottom is 25 units below centre.
                  top: centre.dy + box / 96 * 25 + 28,
                  child: Opacity(
                    opacity: name,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - name)),
                      child: const Text(
                        'Kibuo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: KibuoTheme.brandFont,
                          fontVariations: [FontVariation.weight(700)],
                          fontSize: 40,
                          letterSpacing: -0.5,
                          color: KibuoColors.ink,
                        ),
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
