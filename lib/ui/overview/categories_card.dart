import 'package:flutter/material.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/domain/overview/category_lines.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
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

  /// A category touched: its page.
  final ValueChanged<String> onOpen;

  @override
  State<CategoriesCard> createState() => _CategoriesCardState();
}

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
              _RowFrame(
                tile: const _PlainTile(icon: KibuoIcons.dotsThreeCircle),
                name: l.overviewOtherCategories(rest.length),
                amount: '${widget.out ? '−' : '+'}${widget.money(restAmount)}',
                share: rest.fold(0, (a, c) => a + c.share),
                bar: restAmount / most,
                hue: categoryHue(CategoryColor.grey),
                caret: _restOpen ? KibuoIcons.caretUp : KibuoIcons.caretDown,
                onTap: () => setState(() => _restOpen = !_restOpen),
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
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final category = this.category;
    final amount = '${out ? '−' : '+'}${money(line.amount)}';
    final bar = most <= 0 ? 0.0 : line.amount / most;
    return switch (line.kind) {
      CategoryLineKind.category when category != null => _RowFrame(
        tile: CategoryTile(category: category, size: 40, colored: true),
        name: categoryName(l, category),
        amount: amount,
        share: line.share,
        bar: bar,
        hue: categoryHue(category.color),
        caret: KibuoIcons.caretRight,
        onTap: () => onOpen(category.id),
      ),
      CategoryLineKind.debts => _RowFrame(
        tile: const _PlainTile(icon: KibuoIcons.handCoins),
        name: l.overviewDebtsLine,
        amount: amount,
        share: line.share,
        bar: bar,
        hue: categoryHue(CategoryColor.grey),
      ),
      _ => _RowFrame(
        tile: const _PlainTile(icon: KibuoIcons.arrowsLeftRight),
        name: line.kind == CategoryLineKind.fees ? l.overviewFeesLine : '—',
        amount: amount,
        share: line.share,
        bar: bar,
        hue: categoryHue(CategoryColor.grey),
      ),
    };
  }
}

/// A grey tile for what is not a category of the lists.
class _PlainTile extends StatelessWidget {
  const _PlainTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: categoryHue(CategoryColor.grey),
      borderRadius: BorderRadius.circular(40 * 0.32),
    ),
    child: Icon(icon, size: 24, color: KibuoColors.ink),
  );
}

/// The tile, the name and amount, the bar and its percentage, and a caret
/// when the line opens something.
class _RowFrame extends StatelessWidget {
  const _RowFrame({
    required this.tile,
    required this.name,
    required this.amount,
    required this.share,
    required this.bar,
    required this.hue,
    this.caret,
    this.onTap,
  });

  final Widget tile;
  final String name;
  final String amount;
  final int share;

  /// The bar's length, the biggest line's being 1.
  final double bar;
  final Color hue;
  final IconData? caret;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            tile,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.rowLabel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amount,
                        style: KibuoType.itemName.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: SizedBox(
                            height: 6,
                            child: Stack(
                              children: [
                                const Positioned.fill(
                                  child: ColoredBox(
                                    color: KibuoColors.background,
                                  ),
                                ),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: bar.clamp(0.0, 1.0),
                                  heightFactor: 1,
                                  child: ColoredBox(color: hue),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '$share %',
                          textAlign: TextAlign.end,
                          style: KibuoType.caption.copyWith(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 26,
              child: caret == null
                  ? null
                  : Icon(caret, size: 18, color: KibuoColors.inkSecondary),
            ),
          ],
        ),
      ),
    );
    return onTap == null
        ? row
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
            child: row,
          );
  }
}
