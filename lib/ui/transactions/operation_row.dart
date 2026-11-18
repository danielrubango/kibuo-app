import 'package:flutter/material.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/dashed_border.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';

/// A piece of text and where the searched words are in it, if anywhere.
typedef Marked = (String text, (int, int)? mark);

/// One operation in a list or in the search (canvas ListeOperations,
/// RechercheR2): white, 16 round, its 44 tile, the name and a second line,
/// then the amount. Searched words are marked in light green. An ignored
/// or planned one is dashed and grey, with its [tag] (canvas BrouillonA3).
class OperationRow extends StatelessWidget {
  const OperationRow({
    super.key,
    required this.t,
    required this.labels,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.amountMarked = false,
    this.tag,
  });

  final TransactionInfo t;
  final OperationLabels labels;
  final Marked title;
  final Marked subtitle;
  final VoidCallback onTap;

  /// The searched amount is this one.
  final bool amountMarked;

  /// « Ignoré », « Prévu »: before the second line.
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final muted = t.isIgnored || t.isPlanned;
    final row = Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: _RowBody(
              t: t,
              labels: labels,
              title: title,
              subtitle: subtitle,
              amountMarked: amountMarked,
              tag: tag,
              titleColor: t.isIgnored
                  ? KibuoColors.inkSecondary
                  : KibuoColors.ink,
              amountColor: t.isIgnored
                  ? KibuoColors.inkMuted
                  : t.isPlanned
                  ? KibuoColors.inkSecondary
                  : kindColors(t.kind).ink,
              muted: muted,
            ),
          ),
        ),
      ),
    );
    if (!muted) return row;
    return DashedBorder(radius: 16, color: KibuoColors.line, child: row);
  }
}

/// A draft in a list (canvas BrouillonA3): tinted by its type and dashed,
/// the amount in grey, then « Brouillon », « Ignorer » and « Valider ».
class DraftCard extends StatelessWidget {
  const DraftCard({
    super.key,
    required this.t,
    required this.labels,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onIgnore,
    required this.onValidate,
    this.amountMarked = false,
  });

  final TransactionInfo t;
  final OperationLabels labels;
  final Marked title;
  final Marked subtitle;
  final VoidCallback onTap;
  final VoidCallback onIgnore;
  final VoidCallback onValidate;
  final bool amountMarked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (:card, :dash) = draftColors(t.kind);
    final ink = kindColors(t.kind).ink;
    TextStyle w(TextStyle s, int weight) => s.copyWith(
      fontWeight: FontWeight.values[weight ~/ 100 - 1],
      fontVariations: [FontVariation.weight(weight.toDouble())],
    );
    return DashedBorder(
      radius: 16,
      color: dash,
      child: Material(
        color: card,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 14, 0),
                child: _RowBody(
                  t: t,
                  labels: labels,
                  title: title,
                  subtitle: subtitle,
                  amountMarked: amountMarked,
                  amountColor: KibuoColors.inkSecondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 9, 6),
              child: CustomPaint(
                painter: _DashedTop(dash),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            l.draftLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: w(KibuoType.help, 600).copyWith(color: ink),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: KibuoTheme.heightTouch,
                        child: TextButton(
                          onPressed: onIgnore,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, KibuoTheme.heightTouch),
                            foregroundColor: KibuoColors.inkSecondary,
                            textStyle: w(KibuoType.body, 600),
                          ),
                          child: Text(l.draftIgnore),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 40,
                        child: FilledButton(
                          onPressed: onValidate,
                          style: FilledButton.styleFrom(
                            backgroundColor: KibuoColors.mint,
                            foregroundColor: KibuoColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: w(KibuoType.body, 600),
                          ),
                          child: Text(l.draftValidate),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashed line above a draft's actions.
class _DashedTop extends CustomPainter {
  const _DashedTop(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 3, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedTop old) => old.color != color;
}

/// The tile, the two lines and the amount of an operation's row.
class _RowBody extends StatelessWidget {
  const _RowBody({
    required this.t,
    required this.labels,
    required this.title,
    required this.subtitle,
    required this.amountMarked,
    required this.amountColor,
    this.titleColor = KibuoColors.ink,
    this.tag,
    this.muted = false,
  });

  final TransactionInfo t;
  final OperationLabels labels;
  final Marked title;
  final Marked subtitle;
  final bool amountMarked;
  final Color amountColor;
  final Color titleColor;
  final String? tag;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final second = _MarkedText(
      subtitle,
      KibuoType.help.copyWith(height: 1.2),
      markWeight: 600,
    );
    return Row(
      children: [
        OperationTile(
          kind: t.kind,
          labels: labels,
          size: KibuoTheme.heightTouch,
          muted: muted,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MarkedText(
                title,
                KibuoType.rowLabel.copyWith(color: titleColor),
                markWeight: 700,
              ),
              const SizedBox(height: 2),
              if (tag case final tag?)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: KibuoColors.background,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        tag,
                        style: KibuoType.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation.weight(600)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(child: second),
                  ],
                )
              else
                second,
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: amountMarked
              ? const EdgeInsets.symmetric(horizontal: 2)
              : EdgeInsets.zero,
          decoration: amountMarked
              ? BoxDecoration(
                  color: KibuoColors.accentTintStrong,
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child: FitAmount(
            long: isLong(t.total.total),
            alignment: Alignment.centerRight,
            maxWidth: MediaQuery.sizeOf(context).width * 0.4,
            style: KibuoType.buttonSmall.copyWith(
              color: amountColor,
              decoration: t.isIgnored ? TextDecoration.lineThrough : null,
              decorationColor: amountColor,
            ),
            span: (short) =>
                TextSpan(text: signedTotal(context, t, short: short)),
          ),
        ),
      ],
    );
  }
}

class _MarkedText extends StatelessWidget {
  const _MarkedText(this.marked, this.style, {required this.markWeight});

  final Marked marked;
  final TextStyle style;
  final int markWeight;

  @override
  Widget build(BuildContext context) {
    final (text, mark) = marked;
    if (mark == null) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final (start, end) = mark;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, start)),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              decoration: BoxDecoration(
                color: KibuoColors.accentTintStrong,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                text.substring(start, end),
                style: style.copyWith(
                  color: KibuoColors.ink,
                  fontWeight: FontWeight.values[markWeight ~/ 100 - 1],
                  fontVariations: [FontVariation.weight(markWeight.toDouble())],
                ),
              ),
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}
