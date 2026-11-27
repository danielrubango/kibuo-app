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
import 'package:kibuo/ui/overview/share_row.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operation_screens.dart';

/// What a line of the Catégories tab opens on: its tile and name, which
/// operations of the period are its own, what each counts for, and how
/// they group (PRODUCT, 27 November 2026).
class LineSource {
  const LineSource({
    required this.name,
    required this.tile,
    required this.hue,
    required this.picks,
    required this.groupOf,
    this.amountOf,
    this.detailOf,
  });

  /// A category, its subcategories as groups (variant B, canvas CatB-page).
  factory LineSource.category(
    AppLocalizations l,
    CategoryInfo category,
    Map<String, CategoryInfo> categories, {
    required bool out,
  }) {
    final ids = {category.id, for (final s in category.subs) s.id};
    final kind = out ? EntryKind.expense : EntryKind.income;
    return LineSource(
      name: categoryName(l, category),
      tile: CategoryTile(category: category, size: 36, colored: true),
      hue: categoryHue(category.color),
      picks: (t) => t.kind == kind && ids.contains(t.categoryId),
      groupOf: (t) => categoryName(l, categories[t.categoryId] ?? category),
    );
  }

  /// Money lent, borrowed or paid back: « Dettes » and « Créances » as
  /// groups.
  factory LineSource.debts(AppLocalizations l, {required bool out}) {
    final kind = out ? EntryKind.expense : EntryKind.income;
    return LineSource(
      name: l.overviewDebtsLine,
      tile: const PlainLineTile(icon: KibuoIcons.handCoins, size: 36),
      hue: categoryHue(CategoryColor.grey),
      picks: (t) =>
          t.kind == kind &&
          t.categoryId != null &&
          isDebtCategoryId(t.categoryId!),
      groupOf: (t) =>
          debtOweOf(t.categoryId!.substring('default-'.length)) == true
          ? l.followedDebts
          : l.followedReceivables,
    );
  }

  /// The transfers that had fees, each counting for its fees.
  factory LineSource.fees(AppLocalizations l, String Function(Money) money) =>
      LineSource(
        name: l.overviewFeesLine,
        tile: const PlainLineTile(icon: KibuoIcons.arrowsLeftRight, size: 36),
        hue: categoryHue(CategoryColor.grey),
        picks: (t) => t.kind == EntryKind.transfer && t.total.fees.minor > 0,
        groupOf: (_) => null,
        amountOf: (t) => t.total.fees,
        detailOf: (t) => l.overviewFeesOf(money(t.total.fees)),
      );

  final String name;
  final Widget tile;

  /// The bars' colour.
  final Color hue;

  /// Whether an operation belongs to the line (the period aside).
  final bool Function(TransactionInfo t) picks;

  /// The group an operation counts in (a subcategory's name); null for
  /// none, and then no bars.
  final String? Function(TransactionInfo t) groupOf;

  /// What an operation counts for, its total by default.
  final Money Function(TransactionInfo t)? amountOf;

  /// Said after the account, instead of the time (a transfer's fees).
  final String Function(TransactionInfo t)? detailOf;
}

/// A line of the Catégories tab over the Aperçu's period (variant B, canvas
/// CatB-page, 27 November 2026): its tile, name and period at the top, its
/// total, its share of the money out (or in) and its number of operations,
/// its groups with their bars, then the operations, day by day.
class LinePage extends StatefulWidget {
  const LinePage({
    super.key,
    required this.data,
    required this.source,
    required this.periodLabel,
    required this.span,
    required this.out,
    required this.periodTotal,
    required this.main,
    required this.rates,
  });

  final EntryData data;
  final LineSource source;
  final String periodLabel;
  final TimeSpan span;
  final bool out;

  /// The period's money out (or in), for the line's share.
  final int periodTotal;
  final CurrencyInfo main;
  final Map<String, ExchangeRate> rates;

  @override
  State<LinePage> createState() => _LinePageState();
}

class _LinePageState extends State<LinePage> {
  List<(TransactionInfo, OperationLabels)>? _ops;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// The line's saved operations within the period, the latest first.
  Future<void> _load() async {
    final all = await widget.data.transactions.all();
    final mine = [
      for (final t in all)
        if (t.counts &&
            widget.source.picks(t) &&
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
    final amount = widget.source.amountOf?.call(t) ?? t.total.total;
    final flow = widget.out
        ? MoneyFlow(outgoing: amount)
        : MoneyFlow(incoming: amount);
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
            widget.source.tile,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.source.name,
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

  /// The total, the share and count, and the groups.
  Widget _summary(
    AppLocalizations l,
    List<(TransactionInfo, OperationLabels)> ops,
  ) {
    final byGroup = <String?, int>{};
    for (final (t, _) in ops) {
      final group = widget.source.groupOf(t);
      byGroup[group] = (byGroup[group] ?? 0) + _inMain(t);
    }
    final total = byGroup.values.fold(0, (a, b) => a + b);
    final share = widget.periodTotal <= 0
        ? 0
        : (total * 100 / widget.periodTotal).round();
    final groups = [
      for (final MapEntry(:key, :value) in byGroup.entries)
        if (key != null) (name: key, amount: value),
    ]..sort((a, b) => b.amount - a.amount);
    final most = groups.isEmpty ? 1 : groups.first.amount;
    // Only the line itself: no group to show.
    final shown =
        groups.length > 1 ||
        (groups.isNotEmpty && groups.first.name != widget.source.name);
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
          if (shown)
            for (final g in groups) ...[
              const SizedBox(height: 12),
              ShareRow(
                name: g.name,
                nameStyle: KibuoType.body.copyWith(
                  color: KibuoColors.inkSecondary,
                ),
                amount: '${widget.out ? '−' : '+'}${_money(g.amount)}',
                percent: total <= 0 ? 0 : (g.amount * 100 / total).round(),
                bar: most <= 0 ? 0 : g.amount / most,
                color: widget.source.hue,
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
    final detailOf = widget.source.detailOf;
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
                  '${detailOf?.call(t) ?? DateFormat.Hm(_lang).format(t.date.toLocal())}',
              null,
            ),
            onTap: () => _open(t),
          ),
        ],
      ],
    ];
  }
}
