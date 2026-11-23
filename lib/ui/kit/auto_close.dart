import 'package:flutter/material.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';

/// A confirmation sheet's content that closes by itself (canvas
/// ApresFeuilleB): [child], then a mint bar that empties, with no words
/// (owner, 23 November). A touch on the sheet keeps it open, and the bar
/// goes.
class AutoClose extends StatefulWidget {
  const AutoClose({
    super.key,
    required this.child,
    this.stay = const Duration(seconds: 6),
  });

  final Widget child;
  final Duration stay;

  @override
  State<AutoClose> createState() => _AutoCloseState();
}

class _AutoCloseState extends State<AutoClose>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(vsync: this, duration: widget.stay)
    ..forward().whenCompleteOrCancel(() {
      if (mounted && !_held) Navigator.of(context).maybePop();
    });
  bool _held = false;

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _hold() {
    if (_held) return;
    setState(() => _held = true);
    _clock.stop();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _hold(),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child,
        if (!_held) ...[
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _clock,
            builder: (context, _) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: 1 - _clock.value,
                minHeight: 4,
                color: KibuoColors.mint,
                backgroundColor: KibuoColors.track,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
