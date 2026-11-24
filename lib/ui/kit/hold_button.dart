import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// A button that acts only once held, filling up meanwhile; letting go
/// early undoes it (« Effacer », « Maintenir pour remplacer »). [dark]:
/// ink, 54 high, filling in red (canvas RestauC1); else outlined in red.
class HoldToConfirm extends StatefulWidget {
  const HoldToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.holding,
    this.dark = false,
    this.duration = const Duration(milliseconds: 1200),
  });

  final String label;

  /// Said while the finger stays (« Continuez d'appuyer… »).
  final String? holding;
  final VoidCallback? onConfirmed;
  final bool dark;
  final Duration duration;

  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            Haptics.confirm();
            widget.onConfirmed?.call();
          }
        });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  void _start() {
    if (widget.onConfirmed == null) return;
    Haptics.tap();
    _hold.forward();
  }

  void _stop() {
    if (!_hold.isCompleted) _hold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.onConfirmed != null;
    return Semantics(
      button: true,
      enabled: on,
      label: widget.label,
      child: Listener(
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _stop(),
        onPointerCancel: (_) => _stop(),
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, _) {
            final busy = _hold.value > 0 && !_hold.isCompleted;
            final text = busy && widget.holding != null
                ? widget.holding!
                : widget.label;
            if (!widget.dark) {
              return Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: KibuoColors.danger, width: 1.5),
                  gradient: LinearGradient(
                    colors: const [KibuoColors.dangerTint, KibuoColors.surface],
                    stops: [_hold.value, _hold.value],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  text,
                  style: const TextStyle(
                    color: KibuoColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return Container(
              height: KibuoTheme.heightPrimary,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: on ? KibuoColors.ink : KibuoColors.line,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: _hold.value,
                    heightFactor: 1,
                    child: const ColoredBox(color: KibuoColors.danger),
                  ),
                  Center(
                    child: Text(
                      text,
                      style: KibuoType.button.copyWith(
                        color: on ? KibuoColors.surface : KibuoColors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
