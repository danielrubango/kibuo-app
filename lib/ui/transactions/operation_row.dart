import 'package:flutter/material.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';

/// A piece of text and where the searched words are in it, if anywhere.
typedef Marked = (String text, (int, int)? mark);

/// One operation in a list or in the search (canvas ListeOperations,
/// RechercheR2): white, 16 round, its 44 tile, the name and a second line,
/// then the amount. Searched words are marked in light green.
class OperationRow extends StatelessWidget {
  const OperationRow({
    super.key,
    required this.t,
    required this.labels,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.amountMarked = false,
  });

  final TransactionInfo t;
  final OperationLabels labels;
  final Marked title;
  final Marked subtitle;
  final VoidCallback onTap;

  /// The searched amount is this one.
  final bool amountMarked;

  @override
  Widget build(BuildContext context) {
    final ink = kindColors(t.kind).ink;
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              children: [
                OperationTile(
                  kind: t.kind,
                  labels: labels,
                  size: KibuoTheme.heightTouch,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MarkedText(title, KibuoType.rowLabel, markWeight: 700),
                      const SizedBox(height: 2),
                      _MarkedText(
                        subtitle,
                        KibuoType.help.copyWith(height: 1.2),
                        markWeight: 600,
                      ),
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
                  child: Text(
                    signedTotal(context, t),
                    style: KibuoType.buttonSmall.copyWith(color: ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
