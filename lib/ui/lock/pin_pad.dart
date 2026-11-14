import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// One box per digit. Boxes past [firm] are optional (dashed) until filled;
/// the next box to fill is outlined in green. A filled box shows a dot, never
/// the digit.
class PinBoxes extends StatelessWidget {
  const PinBoxes({
    super.key,
    required this.count,
    required this.filled,
    int? firm,
    this.greyed = false,
  }) : firm = firm ?? count;

  final int count;
  final int filled;
  final int firm;
  final bool greyed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$filled / $count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _box(i),
          ],
        ],
      ),
    );
  }

  Widget _box(int i) {
    final on = i < filled;
    final current = i == filled && !greyed;
    final optional = i >= firm && !on && !current;
    final color = greyed
        ? KibuoColors.line
        : current
        ? KibuoColors.accent
        : on
        ? KibuoColors.ink
        : optional
        ? KibuoColors.line
        : KibuoColors.lineStrong;
    return CustomPaint(
      painter: _BoxBorder(color: color, dashed: optional),
      child: SizedBox(
        width: 44,
        height: 54,
        child: on
            ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: KibuoColors.ink,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _BoxBorder extends CustomPainter {
  const _BoxBorder({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      const Radius.circular(12),
    );
    canvas.drawRRect(rect, Paint()..color = KibuoColors.surface);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (!dashed) {
      canvas.drawRRect(rect, stroke);
      return;
    }
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, d + 4), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_BoxBorder old) =>
      old.color != color || old.dashed != dashed;
}

/// The code keypad. With [shuffle] on, the digits change place every time
/// [layoutSeed] changes (each opening and each attempt).
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.shuffle = true,
    this.layoutSeed = 0,
    this.enabled = true,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool shuffle;
  final int layoutSeed;
  final bool enabled;

  List<String> _digits() {
    final digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'];
    if (shuffle) digits.shuffle(Random(layoutSeed));
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    final d = _digits();
    final keys = [...d.take(9), '', d[9], '⌫'];
    return SizedBox(
      width: 3 * 80 + 2 * 22,
      child: Wrap(
        spacing: 22,
        runSpacing: 10,
        children: [for (final k in keys) _key(context, k)],
      ),
    );
  }

  Widget _key(BuildContext context, String k) {
    if (k.isEmpty) return const SizedBox(width: 80, height: 60);
    final isDelete = k == '⌫';
    return SizedBox(
      width: 80,
      height: 60,
      child: Material(
        color: enabled ? KibuoColors.surface : KibuoColors.fill,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? () => isDelete ? onDelete() : onDigit(k) : null,
          child: Center(
            child: isDelete
                ? Icon(
                    Icons.backspace_outlined,
                    semanticLabel: AppLocalizations.of(context).keypadDelete,
                    color: enabled ? KibuoColors.ink : KibuoColors.lineStrong,
                  )
                : Text(
                    k,
                    style: TextStyle(
                      fontFamily: KibuoTheme.displayFont,
                      fontVariations: const [FontVariation.weight(500)],
                      fontSize: 26,
                      color: enabled ? KibuoColors.ink : KibuoColors.lineStrong,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The layout of every code screen: what's on top, then the keypad and an
/// optional button at the bottom, within reach of the thumb.
class PinLayout extends StatelessWidget {
  const PinLayout({
    super.key,
    required this.top,
    required this.keypad,
    this.button,
    this.appBar,
  });

  final Widget top;
  final Widget keypad;
  final Widget? button;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          // Full width, so the top and the keypad are centred on the screen.
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                top,
                const Spacer(),
                keypad,
                if (button != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, child: button),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « 0:28 » for a wait.
String formatWait(Duration left) {
  final s = left.inSeconds.clamp(0, 359999);
  final minutes = s ~/ 60;
  final seconds = (s % 60).toString().padLeft(2, '0');
  if (minutes >= 60) {
    return '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}
