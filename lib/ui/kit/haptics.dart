import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The app's touches felt in the hand (owner, 23 November): three
/// strengths, through Android's own feedback, so the phone's « Vibration
/// au toucher » setting decides whether anything is felt.
abstract final class Haptics {
  /// A key, a switch, a choice, a tab, a line opening.
  static void tap() => HapticFeedback.selectionClick();

  /// What saves: « Enregistrer », « Rembourser », « Valider ».
  static void confirm() => HapticFeedback.mediumImpact();

  /// A refusal, or a swipe passing its threshold.
  static void refuse() => HapticFeedback.heavyImpact();
}

/// Felt once, when [child] first shows (a refusal line).
class RefuseOnAppear extends StatefulWidget {
  const RefuseOnAppear({super.key, required this.child});

  final Widget child;

  @override
  State<RefuseOnAppear> createState() => _RefuseOnAppearState();
}

class _RefuseOnAppearState extends State<RefuseOnAppear> {
  @override
  void initState() {
    super.initState();
    Haptics.refuse();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
