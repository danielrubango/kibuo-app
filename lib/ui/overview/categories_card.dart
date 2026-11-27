import 'package:flutter/material.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/domain/overview/category_lines.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/overview/share_row.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Où part mon argent » (or « D'où vient mon argent ») of the Catégories
/// tab (canvas ApercuP2): the four biggest categories, each with its tile in
/// its colour, its amount, a bar of its share and its percentage, then the
/// rest folded under « 3 autres catégories » (PRODUCT, 27 November 2026).
class CategoriesCard extends StatefulWidget {
  const CategoriesCard({
    super.key,
    required this.out,
    required this.lines,
    required this.total,
    required this.categories,
    required this.money,
    required this.onOpen,
  });

  final bool out;
  final List<CategoryLine> lines;

  /// The period's total, written.
  final String total;
  final Map<String, CategoryInfo> categories;

  /// An amount in the main currency, written without its sign.
  final String Function(int minor) money;

  /// A line touched: its page (a category, the debts, the fees).
  final ValueChanged<CategoryLine> onOpen;

  @override
  State<CategoriesCard> createState() => _CategoriesCardState();
}

/// A line's room: 64 high at least, 6 above and below.
const _linePadding = EdgeInsets.symmetric(vertical: 6);
const _lineHeight = 64.0;

class _CategoriesCardState extends State<CategoriesCard> {
  bool _restOpen = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lines = widget.lines;
    final (:shown, :rest) = splitLines(lines);
    final most = lines.isEmpty ? 1 : lines.first.amount;
    Widget line(CategoryLine c) => _LineRow(
      line: c,
      category: c.category == null ? null : widget.categories[c.category],
      out: widget.out,
      most: most,
      money: widget.money,
      onOpen: widget.onOpen,
    );
    final restAmount = rest.fold(0, (a, c) => a + c.amount);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  widget.out ? l.overviewWhereOut : l.overviewWhereIn,
                  style: KibuoType.cardTitle.copyWith(fontSize: 16),
                ),
              ),
              Text(
                widget.out
                    ? l.overviewTotalOut(widget.total)
                    : l.overviewTotalIn(widget.total),
                style: KibuoType.caption.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (lines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                widget.out ? l.overviewNoExitPeriod : l.overviewNoEntryPeriod,
                style: KibuoType.body.copyWith(color: KibuoColors.inkSecondary),
              ),
            )
          else ...[
            for (final c in shown) line(c),
            if (rest.isNotEmpty) ...[
              ShareRow(
                leading: const PlainLineTile(icon: KibuoIcons.dotsThreeCircle),
                name: l.overviewOtherCategories(rest.length),
                amount: '${widget.out ? '−' : '+'}${widget.money(restAmount)}',
                percent: rest.fold(0, (a, c) => a + c.share),
                bar: restAmount / most,
                color: categoryHue(CategoryColor.grey),
                onTap: () => setState(() => _restOpen = !_restOpen),
                padding: _linePadding,
                minHeight: _lineHeight,
              ),
              if (_restOpen)
                for (final c in rest) line(c),
            ],
            const SizedBox(height: 8),
            Text(
              l.overviewCategoriesHelp,
              style: KibuoType.caption.copyWith(
                fontSize: 13,
                color: KibuoColors.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One line: a category, the debts together, or the transfer fees.
class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.category,
    required this.out,
    required this.most,
    required this.money,
    required this.onOpen,
  });

  final CategoryLine line;
  final CategoryInfo? category;
  final bool out;
  final int most;
  final String Function(int minor) money;
  final ValueChanged<CategoryLine> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final category = this.category;
    final amount = '${out ? '−' : '+'}${money(line.amount)}';
    final bar = most <= 0 ? 0.0 : line.amount / most;
    final (leading, name, onTap) = switch (line.kind) {
      CategoryLineKind.category when category != null => (
        CategoryTile(category: category, size: 40, colored: true) as Widget,
        categoryName(l, category),
        () => onOpen(line),
      ),
      CategoryLineKind.debts => (
        const PlainLineTile(icon: KibuoIcons.handCoins) as Widget,
        l.overviewDebtsLine,
        () => onOpen(line),
      ),
      _ => (
        const PlainLineTile(icon: KibuoIcons.arrowsLeftRight) as Widget,
        line.kind == CategoryLineKind.fees ? l.overviewFeesLine : '—',
        line.kind == CategoryLineKind.fees ? () => onOpen(line) : null,
      ),
    };
    return ShareRow(
      leading: leading,
      name: name,
      amount: amount,
      percent: line.share,
      bar: bar,
      color: categoryHue(category?.color ?? CategoryColor.grey),
      onTap: onTap,
      padding: _linePadding,
      minHeight: _lineHeight,
    );
  }
}
