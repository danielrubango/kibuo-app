import 'package:flutter/material.dart';

import 'package:kibuo/ui/shell/add_choice.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// Where each choice sits, relative to the centre of the + button, in logical
/// pixels (from the validated mockup at 390 px wide).
const _fanOffsets = {
  AddChoice.expense: Offset(0, -137),
  AddChoice.income: Offset(-113, -109),
  AddChoice.transfer: Offset(113, -109),
  AddChoice.debt: Offset(-143, -217),
  AddChoice.project: Offset(143, -217),
};

const _tileSize = 56.0;
const _slotWidth = 96.0;

/// The fan shown while + is held: a dark backdrop, the + turned into a dark
/// cross, and the five choices above it.
///
/// The shell feeds it the finger position; [choiceAt] tells which choice is
/// under a point, so lifting the finger there opens it.
class PlusFan extends StatelessWidget {
  const PlusFan({
    super.key,
    required this.plusCenter,
    required this.hovered,
    required this.onPick,
    required this.onClose,
  });

  final Offset plusCenter;
  final AddChoice? hovered;
  final ValueChanged<AddChoice> onPick;
  final VoidCallback onClose;

  /// The choice whose tile or label contains [point], if any.
  static AddChoice? choiceAt(Offset point, Offset plusCenter, double width) {
    for (final entry in _fanOffsets.entries) {
      final slot = _slotRect(entry.value, plusCenter, width);
      if (slot.inflate(8).contains(point)) return entry.key;
    }
    return null;
  }

  static Rect _slotRect(Offset offset, Offset plusCenter, double width) {
    final centre = plusCenter + offset;
    final left = (centre.dx - _slotWidth / 2).clamp(
      4.0,
      width - _slotWidth - 4,
    );
    return Rect.fromLTWH(left, centre.dy - _tileSize / 2, _slotWidth, 120);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final text = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: ColoredBox(color: KibuoColors.ink.withValues(alpha: 0.72)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: plusCenter.dy - 295,
            child: Text(
              'Glissez vers un choix, ou touchez-le',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: KibuoColors.line),
            ),
          ),
          for (final entry in _fanOffsets.entries)
            Positioned.fromRect(
              rect: _slotRect(entry.value, plusCenter, width),
              child: _FanTile(
                choice: entry.key,
                highlighted: entry.key == hovered,
                onTap: () => onPick(entry.key),
              ),
            ),
          Positioned(
            left: plusCenter.dx - 31,
            top: plusCenter.dy - 31,
            child: Semantics(
              button: true,
              label: 'Fermer',
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: KibuoColors.ink,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: KibuoColors.ink.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    KibuoIcons.xBold,
                    size: 26,
                    color: KibuoColors.surface,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FanTile extends StatelessWidget {
  const _FanTile({
    required this.choice,
    required this.highlighted,
    required this.onTap,
  });

  final AddChoice choice;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: choice.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedScale(
              scale: highlighted ? 1.15 : 1,
              duration: const Duration(milliseconds: 120),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: _tileSize,
                height: _tileSize,
                decoration: BoxDecoration(
                  color: highlighted ? KibuoColors.mint : KibuoColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  choice.icon,
                  size: 24,
                  color: highlighted ? KibuoColors.ink : choice.ink,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              choice.fanLabel,
              textAlign: TextAlign.center,
              style: text.labelLarge?.copyWith(
                fontSize: 13,
                height: 16 / 13,
                color: KibuoColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
