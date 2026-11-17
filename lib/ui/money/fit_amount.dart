import 'package:flutter/material.dart';
import 'package:kibuo/domain/money/long_amounts.dart';

/// The « Montants longs » choice, read once at start and changed from
/// Réglages; every [FitAmount] follows it.
final longAmountsChoice = ValueNotifier<LongAmounts>(LongAmounts.auto);

/// An amount read at a glance (PRODUCT: Montants longs): whole, or written
/// short (« 128,5 M FC ») when the choice says so, and smaller only if even
/// that does not fit. Screen readers always get it whole.
class FitAmount extends StatelessWidget {
  const FitAmount({
    super.key,
    required this.span,
    this.long = true,
    this.style,
    this.alignment = Alignment.centerLeft,
    this.maxWidth,
  });

  /// The text, whole or short.
  final InlineSpan Function(bool short) span;

  /// Some amount in it reaches 10 000 (for « Toujours »).
  final bool long;

  final TextStyle? style;
  final AlignmentGeometry alignment;

  /// Its place when the row around it does not give one (an amount at the
  /// end of a row).
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final whole = span(false);
    return Semantics(
      label: whole.toPlainText(),
      excludeSemantics: true,
      child: ValueListenableBuilder<LongAmounts>(
        valueListenable: longAmountsChoice,
        builder: (context, choice, _) => ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
          child: LayoutBuilder(
            builder: (context, box) {
              final short = switch (choice) {
                LongAmounts.never => false,
                LongAmounts.always => long,
                LongAmounts.auto => !_fits(context, whole, box.maxWidth),
              };
              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: alignment,
                child: Text.rich(
                  short ? span(true) : whole,
                  style: style,
                  maxLines: 1,
                  softWrap: false,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  bool _fits(BuildContext context, InlineSpan text, double width) {
    if (!width.isFinite) return true;
    final painter = TextPainter(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.merge(style),
        children: [text],
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    final fits = painter.width <= width;
    painter.dispose();
    return fits;
  }
}
