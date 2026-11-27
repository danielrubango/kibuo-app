import 'package:flutter/material.dart';
import 'package:kibuo/ui/kit/page_veil.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The room left around what a guide shows, the same on every side
/// (DIRECTION « Guides », 26 November 2026).
const guideGap = 8.0;

/// A guide's page (DIRECTION « Guides »): everything under the + sheet's
/// veil but for a window around [target], [gap] wider on every side, and
/// [card] under it. Touches on the veil do nothing: only the card answers.
class GuideSpotlight extends StatefulWidget {
  const GuideSpotlight({
    super.key,
    required this.target,
    required this.card,
    this.gap = guideGap,
  });

  /// What the window frames; measured once it is laid out.
  final GlobalKey target;

  /// Usually a [GuideCard], laid under the window between the page margins.
  final Widget card;

  final double gap;

  @override
  State<GuideSpotlight> createState() => _GuideSpotlightState();
}

class _GuideSpotlightState extends State<GuideSpotlight> {
  Rect? _window;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(GuideSpotlight old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target || old.gap != widget.gap) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    final box = widget.target.currentContext?.findRenderObject() as RenderBox?;
    final me = context.findRenderObject() as RenderBox?;
    if (!mounted || box == null || me == null || !box.hasSize) return;
    final topLeft = me.globalToLocal(box.localToGlobal(Offset.zero));
    setState(() => _window = (topLeft & box.size).inflate(widget.gap));
  }

  @override
  Widget build(BuildContext context) {
    final window = _window;
    if (window == null) return const SizedBox.expand();
    return Stack(
      children: [
        Positioned.fill(
          child: PageVeil(
            window: window,
            // Concentric with a card's corners, so the band around it keeps
            // its width in the turns.
            radius: KibuoTheme.radiusCard + widget.gap,
          ),
        ),
        Positioned(
          left: KibuoTheme.screenMargin,
          right: KibuoTheme.screenMargin,
          top: window.bottom + 15,
          child: widget.card,
        ),
      ],
    );
  }
}

/// A guide's white card (canvas DettesListeDois): its point towards the
/// window, « 1 sur 2 », a title, a few words, then [skipLabel] on the left
/// and [actionLabel] in mint on the right.
class GuideCard extends StatelessWidget {
  const GuideCard({
    super.key,
    required this.step,
    required this.title,
    required this.text,
    required this.skipLabel,
    required this.onSkip,
    required this.actionLabel,
    required this.onAction,
  });

  final String step;
  final String title;
  final String text;
  final String skipLabel;
  final VoidCallback onSkip;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 24,
          top: -7,
          child: Transform.rotate(
            angle: 0.785398,
            child: Container(width: 14, height: 14, color: KibuoColors.surface),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(step, style: KibuoType.caption.weight(600)),
              const SizedBox(height: 8),
              Text(title, style: KibuoType.cardTitle),
              const SizedBox(height: 8),
              Text(
                text,
                style: KibuoType.body.copyWith(
                  color: KibuoColors.inkSecondary,
                  height: 20 / 14,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: KibuoColors.inkSecondary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, KibuoTheme.heightTouch),
                      textStyle: KibuoType.buttonSmall.copyWith(fontSize: 14),
                    ),
                    child: Text(skipLabel),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: KibuoColors.mint,
                      foregroundColor: KibuoColors.ink,
                      minimumSize: const Size(0, KibuoTheme.heightTouch),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          KibuoTheme.radiusTile,
                        ),
                      ),
                      textStyle: KibuoType.buttonSmall,
                    ),
                    child: Text(actionLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
