import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/budgets/budget_curve.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/budgets/budget_chart.dart';
import 'package:kibuo/ui/budgets/budget_form_screen.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/day_header.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/month_summary_card.dart';
import 'package:kibuo/ui/kit/segmented_tabs.dart';
import 'package:kibuo/ui/kit/spent_bar.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operation_screens.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';

/// A budget's detail (canvas BudgetDetail, BudgetRythme, BudgetJourReplie):
/// the month's summary, « Au fil du mois », then the month's operations by
/// day and « Voir dans Opérations ». Pops true when something changed.
class BudgetDetailScreen extends StatefulWidget {
  const BudgetDetailScreen({
    super.key,
    required this.loader,
    required this.month,
    required this.budgetId,
  });

  final BudgetLoader loader;

  /// The period shown on Budgets.
  final DateTime month;
  final String budgetId;

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  BudgetBook? _book;
  BudgetLine? _line;
  List<(TransactionInfo, OperationLabels)> _ops = const [];
  ChartView _view = ChartView.total;
  final _folded = <DateTime>{};
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final book = await widget.loader.load(widget.month);
    final line = book.lines
        .where((l) => l.budget.id == widget.budgetId)
        .firstOrNull;
    if (line == null) {
      // Deleted from « Modifier ».
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    final ids = {line.category.id, for (final s in line.category.subs) s.id};
    final all = await widget.loader.data.transactions.all();
    if (!mounted) return;
    final ops = [
      for (final t in all)
        if (t.kind == EntryKind.expense &&
            ids.contains(t.categoryId) &&
            book.period.contains(t.date.toLocal()))
          t,
    ]..sort((a, b) => b.date.compareTo(a.date));
    final labelled = [
      for (final t in ops)
        (t, await OperationLabels.of(context, widget.loader.data, t)),
    ];
    if (!mounted) return;
    setState(() {
      _book = book;
      _line = line;
      _ops = labelled;
    });
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  String _money(Money m, {bool short = false}) =>
      formatAmount(m, _book!.main, _lang, short: short);

  bool get _current => widget.month == periodOf(DateTime.now()).month;

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            BudgetFormScreen(loader: widget.loader, book: _book!, line: _line),
      ),
    );
    if (changed ?? false) {
      _changed = true;
      await _load();
    }
  }

  Future<void> _openOperation(TransactionInfo t) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            OperationDetailScreen(data: widget.loader.data, id: t.id),
      ),
    );
    _changed = true;
    await _load();
  }

  void _seeInList() {
    final category = _line!.category.id;
    Navigator.of(context).popUntil((r) => r.isFirst);
    OperationsScreen.show
      ..value = null
      ..value = (month: widget.month, category: category);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final line = _line;
    final book = _book;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: line == null
              ? null
              : Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: KibuoColors.surface,
                        borderRadius: BorderRadius.circular(
                          KibuoTheme.radiusPill,
                        ),
                      ),
                      child: Icon(
                        categoryIcon(line.category),
                        size: 18,
                        color: KibuoColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        categoryName(l, line.category),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
          actions: [
            if (line != null)
              TextAction(label: l.budgetEditAction, onPressed: _edit),
            const SizedBox(width: 8),
          ],
        ),
        body: line == null || book == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                children: [
                  _summary(l, line, book),
                  const SizedBox(height: 16),
                  _chart(l, line, book),
                  const SizedBox(height: 16),
                  _opsTitle(l),
                  if (_ops.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                      child: Text(
                        l.budgetNoOps(categoryName(l, line.category)),
                        style: KibuoType.help,
                      ),
                    )
                  else
                    ..._days(),
                  const SizedBox(height: 16),
                  Center(
                    child: TextAction(
                      label: l.budgetSeeInList,
                      onPressed: _seeInList,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _summary(AppLocalizations l, BudgetLine line, BudgetBook book) {
    final s = line.status;
    final left = s.left;
    final over = s.state == BudgetState.over;
    final pre = s.approximate ? '≈ ' : '';
    final name = DateFormat.MMMM(_lang).format(widget.month);
    return MonthSummaryCard(
      month: name[0].toUpperCase() + name.substring(1),
      detail: l.budgetDetailBudget(_money(s.amount)),
      left: (short) => over
          ? '$pre−${_money(Money(-left.minor, left.currency), short: short)}'
          : '$pre${_money(left, short: short)}',
      leftWord: over ? l.budgetsTooMuch : l.homeLeft,
      leftLong: isLong(left),
      leftInAlert: over,
      spent: SpentLevel.share(s.percent),
      today: _current ? (DateTime.now(), book.period) : null,
      line: (short) => TextSpan(
        text: l.budgetsOutOf(
          '$pre${_money(s.spent, short: short)}',
          _money(s.amount, short: short),
        ),
      ),
      lineLong: isLong(s.amount),
      badge: switch (s.state) {
        BudgetState.over => (
          text: l.budgetOver,
          tint: KibuoColors.debtTint,
          ink: KibuoColors.debtInk,
        ),
        BudgetState.near => (
          text: l.budgetNear,
          tint: KibuoColors.warningTint,
          ink: KibuoColors.warningInk,
        ),
        BudgetState.ok => null,
      },
    );
  }

  Widget _chart(AppLocalizations l, BudgetLine line, BudgetBook book) {
    final s = line.status;
    final period = book.period;
    final now = DateTime.now();
    final today = _current
        ? DateTime.utc(now.year, now.month, now.day)
              .difference(
                DateTime.utc(
                  period.first.year,
                  period.first.month,
                  period.first.day,
                ),
              )
              .inDays
        : null;
    final steps = cumulative(period, [
      for (final (t, _) in _ops)
        (
          t.date.toLocal(),
          expenseInMain(
                total: t.total.total,
                paid: t.paid,
                frozen: t.rate,
                main: book.main,
                rateFor: (code) => book.rates[code],
              )?.minor ??
              0,
        ),
    ]);
    final spentNow = steps.isEmpty ? 0 : steps.last.total;
    final gap = today == null
        ? null
        : paceGap(
            spent: spentNow,
            amount: s.amount.minor,
            elapsed: period.elapsed(now),
          );
    final color = SpentLevel.share(s.percent).bar;
    String gapText(int minor) => _money(Money(minor.abs(), book.main.code));
    final first = _lang == 'fr' && period.first.day == 1
        ? '1er'
        : '${period.first.day}';
    Widget legend(Widget mark, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 4),
        Text(text, style: KibuoType.caption.copyWith(fontSize: 11)),
      ],
    );
    Widget lineMark(Color c, {bool dashed = false}) => SizedBox(
      width: 10,
      height: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dashed ? null : c,
          border: dashed ? Border(top: BorderSide(color: c, width: 2)) : null,
        ),
      ),
    );
    Widget square(Color c) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.budgetChart,
                  style: KibuoType.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation.weight(600)],
                  ),
                ),
              ),
              SegmentedTabs<ChartView>(
                compact: true,
                items: [
                  (ChartView.total, l.budgetChartTotal),
                  (ChartView.pace, l.budgetChartPace),
                ],
                value: _view,
                onPick: (v) => setState(() => _view = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BudgetChart(
            view: _view,
            steps: steps,
            days: period.days,
            amount: s.amount.minor,
            color: color,
            budgetLabel: l.budgetChartBudget(_money(s.amount)),
            today: today,
            gapLabel: gap == null
                ? null
                : gap > 0
                ? l.budgetAhead(gapText(gap))
                : l.budgetMargin(gapText(gap)),
            gapAhead: (gap ?? 0) > 0,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, box) {
                final style = KibuoType.caption.copyWith(
                  fontSize: 11,
                  color: KibuoColors.inkMuted,
                );
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(left: 0, child: Text(first, style: style)),
                    if (today != null)
                      Positioned(
                        left: (box.maxWidth * (today + 1) / period.days - 20)
                            .clamp(24, box.maxWidth - 64)
                            .toDouble(),
                        child: Text(
                          DateFormat.MMMd(_lang).format(now),
                          style: style.copyWith(
                            color: KibuoColors.ink,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation.weight(600)],
                          ),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      child: Text('${period.last.day}', style: style),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: _view == ChartView.total
                ? [
                    legend(lineMark(color), l.budgetLegendSpent),
                    legend(square(KibuoColors.debtTint), l.budgetLegendOver),
                  ]
                : [
                    legend(lineMark(color), l.budgetLegendSpent),
                    legend(
                      lineMark(KibuoColors.inkSecondary, dashed: true),
                      l.budgetLegendPace,
                    ),
                    legend(
                      square(
                        (gap ?? 0) > 0
                            ? KibuoColors.debtTint
                            : KibuoColors.accentTint,
                      ),
                      (gap ?? 0) > 0 ? l.budgetLegendFast : l.budgetLegendSlow,
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _opsTitle(AppLocalizations l) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            l.budgetOps,
            style: KibuoType.rowLabel.copyWith(
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
            ),
          ),
        ),
        Text('${_ops.length}', style: KibuoType.help),
      ],
    ),
  );

  List<Widget> _days() {
    final byDay = <DateTime, List<(TransactionInfo, OperationLabels)>>{};
    for (final e in _ops) {
      final d = e.$1.date.toLocal();
      byDay.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(e);
    }
    return [
      for (final MapEntry(key: day, value: ops) in byDay.entries) ...[
        const SizedBox(height: GroupTitle.before),
        DayHeader(
          label: dayLabel(context, day),
          count: ops.length,
          folded: _folded.contains(day),
          net: Money(
            -ops.fold<int>(
              0,
              (s, e) =>
                  s +
                  (expenseInMain(
                        total: e.$1.total.total,
                        paid: e.$1.paid,
                        frozen: e.$1.rate,
                        main: _book!.main,
                        rateFor: (code) => _book!.rates[code],
                      )?.minor ??
                      0),
            ),
            _book!.main.code,
          ),
          onTap: () => setState(
            () =>
                _folded.contains(day) ? _folded.remove(day) : _folded.add(day),
          ),
        ),
        if (!_folded.contains(day)) ...[
          for (final (i, (t, labels)) in ops.indexed)
            Padding(
              padding: EdgeInsets.only(top: i > 0 ? 8 : 0),
              child: OperationRow(
                t: t,
                labels: labels,
                title: (labels.categoryPath.split(' › ').last, null),
                subtitle: (
                  [
                    if (labels.categoryPath.contains(' › '))
                      labels.categoryPath.split(' › ').first,
                    labels.account,
                  ].join(' · '),
                  null,
                ),
                onTap: () => _openOperation(t),
              ),
            ),
        ],
      ],
    ];
  }
}
