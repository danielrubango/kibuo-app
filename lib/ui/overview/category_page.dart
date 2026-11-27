import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/day_header.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operation_screens.dart';

/// A category over the Aperçu's period (variant B, canvas CatB-page, 27
/// November 2026): its tile, name and period at the top, its total, its
/// share of the money out (or in) and its number of operations, its
/// subcategories with their bars, then the operations, day by day.
class CategoryPage extends StatefulWidget {
  const CategoryPage({
    super.key,
    required this.data,
    required this.category,
    required this.categories,
    required this.periodLabel,
    required this.span,
    required this.out,
    required this.periodTotal,
    required this.main,
    required this.rates,
  });

  final EntryData data;
  final CategoryInfo category;

  /// Every category by its id, subcategories included.
  final Map<String, CategoryInfo> categories;
  final String periodLabel;
  final TimeSpan span;
  final bool out;

  /// The period's money out (or in), for the category's share.
  final int periodTotal;
  final CurrencyInfo main;
  final Map<String, ExchangeRate> rates;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<(TransactionInfo, OperationLabels)>? _ops;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// The saved operations of the category and its subcategories within the
  /// period, the latest first.
  Future<void> _load() async {
    final ids = {
      widget.category.id,
      for (final s in widget.category.subs) s.id,
    };
    final kind = widget.out ? EntryKind.expense : EntryKind.income;
    final all = await widget.data.transactions.all();
    final mine = [
      for (final t in all)
        if (t.counts &&
            t.kind == kind &&
            ids.contains(t.categoryId) &&
            widget.span.contains(t.date.toLocal()))
          t,
    ]..sort((a, b) => b.date.compareTo(a.date));
    if (!mounted) return;
    final ops = [
      for (final t in mine)
        (t, await OperationLabels.of(context, widget.data, t)),
    ];
    if (mounted) setState(() => _ops = ops);
  }

  int _inMain(TransactionInfo t) {
    final flow = widget.out
        ? MoneyFlow(outgoing: t.total.total)
        : MoneyFlow(incoming: t.total.total);
    final totals = flowTotals(widget.main, [flow], (c) => widget.rates[c]);
    return widget.out ? totals.exits.minor : totals.entries.minor;
  }

  String _money(int minor) =>
      formatMoney(Money(minor, widget.main.code), widget.main, _lang);

  String get _lang => Localizations.localeOf(context).languageCode;

  Future<void> _open(TransactionInfo t) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OperationDetailScreen(data: widget.data, id: t.id),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final category = widget.category;
    final ops = _ops;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(KibuoIcons.caretLeft, size: 22),
        ),
        title: Row(
          children: [
            CategoryTile(category: category, size: 36, colored: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    categoryName(l, category),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KibuoType.cardTitle.copyWith(fontSize: 18),
                  ),
                  Text(
                    widget.periodLabel,
                    style: KibuoType.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: ops == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [_summary(l, ops), ..._days(ops)],
            ),
    );
  }

  /// The total, the share and count, and the subcategories.
  Widget _summary(
    AppLocalizations l,
    List<(TransactionInfo, OperationLabels)> ops,
  ) {
    final bySub = <String, int>{};
    for (final (t, _) in ops) {
      final id = t.categoryId ?? widget.category.id;
      bySub[id] = (bySub[id] ?? 0) + _inMain(t);
    }
    final total = bySub.values.fold(0, (a, b) => a + b);
    final share = widget.periodTotal <= 0
        ? 0
        : (total * 100 / widget.periodTotal).round();
    final subs = bySub.entries.toList()..sort((a, b) => b.value - a.value);
    final most = subs.isEmpty ? 1 : subs.first.value;
    final hue = categoryHue(widget.category.color);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.out ? '−' : '+'}${_money(total)}',
            style: KibuoType.bigAmount.copyWith(
              fontSize: 30,
              color: widget.out ? KibuoColors.debtInk : KibuoColors.accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.out
                ? l.categoryPageOut(share, ops.length)
                : l.categoryPageIn(share, ops.length),
            style: KibuoType.caption.copyWith(fontSize: 13),
          ),
          // Only the category itself: no subcategory to show.
          if (subs.length > 1 ||
              (subs.isNotEmpty && subs.first.key != widget.category.id))
            for (final MapEntry(key: id, value: amount) in subs) ...[
              const SizedBox(height: 12),
              _SubRow(
                name: categoryName(l, widget.categories[id] ?? widget.category),
                amount: '${widget.out ? '−' : '+'}${_money(amount)}',
                share: total <= 0 ? 0 : (amount * 100 / total).round(),
                bar: most <= 0 ? 0 : amount / most,
                hue: hue,
              ),
            ],
        ],
      ),
    );
  }

  /// The operations under their day, the latest day first.
  List<Widget> _days(List<(TransactionInfo, OperationLabels)> ops) {
    final days = <DateTime, List<(TransactionInfo, OperationLabels)>>{};
    for (final op in ops) {
      final d = op.$1.date.toLocal();
      (days[DateTime(d.year, d.month, d.day)] ??= []).add(op);
    }
    return [
      for (final MapEntry(key: day, value: list) in days.entries) ...[
        const SizedBox(height: GroupTitle.before),
        GroupTitle(title: dayLabel(context, day)),
        for (final (i, (t, labels)) in list.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          OperationRow(
            t: t,
            labels: labels,
            title: (labels.categoryPath.split(' › ').last, null),
            subtitle: (
              '${labels.account} · '
                  '${DateFormat.Hm(_lang).format(t.date.toLocal())}',
              null,
            ),
            onTap: () => _open(t),
          ),
        ],
      ],
    ];
  }
}

/// A subcategory: its name and amount, a bar of its share, the share.
class _SubRow extends StatelessWidget {
  const _SubRow({
    required this.name,
    required this.amount,
    required this.share,
    required this.bar,
    required this.hue,
  });

  final String name;
  final String amount;
  final int share;
  final double bar;
  final Color hue;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: KibuoType.body.copyWith(color: KibuoColors.inkSecondary),
            ),
          ),
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
                      child: ColoredBox(color: KibuoColors.background),
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
  );
}
