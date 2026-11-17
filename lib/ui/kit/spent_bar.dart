import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// How much of a month's entries went out, as the bar shows it (PRODUCT):
/// 0 with nothing, past 100 with exits and no entry.
class SpentLevel {
  SpentLevel(FlowTotals totals)
    : outOnly = totals.spentPercent == null && totals.exits.minor > 0,
      percent = totals.spentPercent ?? 0;

  /// A budget's share of its amount.
  const SpentLevel.share(this.percent) : outOnly = false;

  /// Exits without any entry: the bar full, in alert.
  final bool outOnly;
  final int percent;

  int get level => outOnly ? 101 : percent;

  /// Grey up to 80 %, amber up to 100 %, peach beyond.
  Color get bar => level <= 80
      ? KibuoColors.inkMuted
      : level <= 100
      ? KibuoColors.warning
      : KibuoColors.debtInk;

  /// The bold « 49 % »: ink while calm, then the alert's ink.
  Color get ink => level <= 80
      ? KibuoColors.ink
      : level <= 100
      ? KibuoColors.warningInk
      : KibuoColors.debtInk;
}

/// The spent bar of the home and the list (canvas Aujourdhui,
/// ListeOperations): 10 high, and in the current month a dark mark at
/// today with its date above.
class SpentBar extends StatelessWidget {
  const SpentBar({
    super.key,
    required this.spent,
    this.today,
    this.thin = false,
  });

  final SpentLevel spent;

  /// Today and its period, when the bar is the current period's.
  final (DateTime, BudgetPeriod)? today;

  /// A budget tile's bar (PRODUCT): 6 high, the mark 3 over, no date.
  final bool thin;

  double get _bar => thin ? 6 : 10;
  double get _over => thin ? 3 : 4;
  double get _label => thin ? 0 : 14;

  @override
  Widget build(BuildContext context) {
    final bar = LinearProgressIndicator(
      value: (spent.level / 100).clamp(0, 1).toDouble(),
      minHeight: _bar,
      color: spent.bar,
      backgroundColor: KibuoColors.track,
      borderRadius: BorderRadius.circular(_bar / 2),
    );
    if (this.today case null) return bar;
    final (today, period) = this.today!;
    final lang = Localizations.localeOf(context).languageCode;
    final label = DateFormat.MMMd(lang).format(today);
    final style = KibuoType.caption.copyWith(
      fontSize: 10,
      height: 1.2,
      fontWeight: FontWeight.w600,
      fontVariations: const [FontVariation.weight(600)],
    );
    return SizedBox(
      height: _label + _over + _bar + _over,
      child: LayoutBuilder(
        builder: (context, box) {
          final x = box.maxWidth * period.elapsed(today);
          final painter = TextPainter(
            text: TextSpan(text: label, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(left: 0, right: 0, top: _label + _over, child: bar),
              Positioned(
                left: x - 1,
                top: _label,
                child: Container(
                  width: 2,
                  height: _bar + 2 * _over,
                  decoration: BoxDecoration(
                    color: KibuoColors.ink,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // Centred on the mark, kept inside the card.
              if (!thin)
                Positioned(
                  top: 0,
                  left: (x - width / 2)
                      .clamp(0, box.maxWidth - width)
                      .toDouble(),
                  child: Text(label, maxLines: 1, style: style),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// « 49 % dépensés » under the bar: the share in bold, its words as they
/// are; « Aucune entrée » in alert when only exits.
class SpentShare extends StatelessWidget {
  const SpentShare({super.key, required this.spent});

  final SpentLevel spent;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bold = TextStyle(
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation.weight(700)],
      color: spent.ink,
    );
    final text = l.listSpent(spent.percent);
    final cut = text.indexOf('%');
    return Text.rich(
      spent.outOnly
          ? TextSpan(text: l.listNoEntries, style: bold)
          : cut < 0
          ? TextSpan(text: text)
          : TextSpan(
              children: [
                TextSpan(text: text.substring(0, cut + 1), style: bold),
                TextSpan(text: text.substring(cut + 1)),
              ],
            ),
      maxLines: 1,
      style: KibuoType.caption,
    );
  }
}
