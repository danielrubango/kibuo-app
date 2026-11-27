import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/accounts/account_total.dart';
import 'package:kibuo/domain/calendar.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/obligations/debt_list.dart';
import 'package:kibuo/domain/overview/category_lines.dart';
import 'package:kibuo/domain/overview/followed.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/overview/overview_totals.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/spent_bar.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/overview/enlarged_tiles.dart';
import 'package:kibuo/ui/overview/followed_tile.dart';
import 'package:kibuo/ui/recurrences/planned_operation.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/overdraft_check.dart';

/// The curve of Dépensé (canvas ApercuP2).
const _spentLine = Color(0xFFC9874E);

/// Something coming in the next 14 days: a planned operation or a debt
/// due.
typedef Coming = ({
  DateTime day,
  String label,
  Money amount,
  bool out,
  DebtDirection? debt,
});

/// What the followed tiles read besides the operations' flows.
class FollowedData {
  const FollowedData({
    required this.spends,
    required this.gains,
    required this.accounts,
    required this.parents,
    required this.categories,
    required this.accountsTotal,
    required this.accountChanges,
    required this.worthChanges,
    this.accountMoves = const [],
    this.accountNames = const {},
    this.reserved = 0,
    required this.debts,
    required this.projects,
    required this.contributions,
    required this.coming,
  });

  /// Expenses with their category.
  final List<CategorySpend> spends;

  /// Incomes with their category.
  final List<CategorySpend> gains;

  /// Each open account and its balance in the main currency, the largest
  /// first.
  final List<({String name, int balance})> accounts;

  /// A subcategory's parent, by id.
  final Map<String, String> parents;

  /// Categories by id, subcategories included.
  final Map<String, CategoryInfo> categories;

  /// The accounts' total today, in the main currency (Accueil's « Total »).
  final int accountsTotal;

  /// What changed the accounts, and what changed the net worth (the same
  /// less what a debt moved, which moves the debt as much), in the main
  /// currency.
  final List<({DateTime at, int change})> accountChanges;
  final List<({DateTime at, int change})> worthChanges;

  /// Each account's moves, by its id, in the main currency (the Patrimoine
  /// tab's « Mes comptes sur la période »), and their names.
  final List<({String account, DateTime at, int change})> accountMoves;
  final Map<String, String> accountNames;

  /// What the running projects hold back in the accounts, in the main
  /// currency.
  final int reserved;

  /// Debts and receivables not settled.
  final List<DebtLine> debts;
  final List<ProjectInfo> projects;

  /// Each project's set-asides (positive) and take-backs.
  final Map<String, List<ContributionLine>> contributions;

  /// In date order.
  final List<Coming> coming;
}

/// Reads what the tiles need (PRODUCT, 27 November 2026).
Future<FollowedData> loadFollowedData(
  BuildContext context,
  EntryData data, {
  required List<TransactionInfo> counted,
  required List<DebtLine> debts,
  required CurrencyInfo main,
  required Map<String, ExchangeRate> rates,
  required DateTime now,
}) async {
  int inMain(Money m) {
    if (m.currency == main.code) return m.minor;
    final rate = rates[m.currency];
    if (rate == null) return 0;
    final sign = m.minor < 0 ? -1 : 1;
    return sign *
        rate.convert(Money(m.minor.abs(), m.currency), to: main).minor;
  }

  final tops = [
    ...await data.categories.categories(CategoryKind.out),
    ...await data.categories.categories(CategoryKind.into),
  ];
  final parents = <String, String>{};
  final categories = <String, CategoryInfo>{};
  for (final c in tops) {
    categories[c.id] = c;
    for (final s in c.subs) {
      parents[s.id] = c.id;
      categories[s.id] = s;
    }
  }

  final accounts = await data.accounts.accounts();
  final currencyOfAccount = {for (final a in accounts) a.id: a.currency};
  final accountsTotal = totalIn(main, [
    for (final a in accounts) a.balance,
  ], (code) => rates[code]).amount.minor;
  final accountChanges = <({DateTime at, int change})>[
    for (final a in accounts)
      (at: a.openingDate.toLocal(), change: inMain(a.opening)),
  ];
  final worthChanges = [...accountChanges];
  final accountMoves = <({String account, DateTime at, int change})>[
    for (final a in accounts)
      (account: a.id, at: a.openingDate.toLocal(), change: inMain(a.opening)),
  ];
  final spends = <CategorySpend>[];
  final gains = <CategorySpend>[];
  for (final t in counted) {
    final at = t.date.toLocal();
    if (t.kind == EntryKind.expense && t.categoryId != null) {
      spends.add((at: at, category: t.categoryId!, amount: t.total.total));
    }
    if (t.kind == EntryKind.income && t.categoryId != null) {
      gains.add((at: at, category: t.categoryId!, amount: t.total.total));
    }
    for (final MapEntry(key: account, value: change) in effectsOf(t).entries) {
      final code = currencyOfAccount[account];
      if (code == null || change == 0) continue;
      final moved = (at: at, change: inMain(Money(change, code)));
      accountChanges.add(moved);
      accountMoves.add((account: account, at: at, change: moved.change));
      // A debt moves the accounts and the debt alike: no change in worth.
      if (t.debtId == null) worthChanges.add(moved);
    }
  }

  final projects = await data.projects?.projects() ?? const <ProjectInfo>[];
  final held = await data.projects?.reserved() ?? const <String, int>{};
  final reserved = held.entries.fold(
    0,
    (sum, e) =>
        sum + inMain(Money(e.value, currencyOfAccount[e.key] ?? main.code)),
  );
  final contributions = <String, List<ContributionLine>>{
    for (final p in projects) p.id: await data.projects!.contributions(p.id),
  };

  final today = DateTime(now.year, now.month, now.day);
  final planned =
      await data.recurrences?.planned(
        now: now,
        until: today.add(const Duration(days: 14)),
      ) ??
      const <Planned>[];
  final coming = <Coming>[];
  for (final p in planned) {
    if (!context.mounted) break;
    final t = plannedOperation(p);
    final labels = await OperationLabels.of(context, data, t);
    coming.add((
      day: p.day,
      label: labels.categoryPath,
      amount: t.total.total,
      out: t.kind != EntryKind.income,
      debt: null,
    ));
  }
  for (final d in debts) {
    final due = d.due;
    if (due == null || due.isBefore(today)) continue;
    if (!due.isBefore(today.add(const Duration(days: 15)))) continue;
    coming.add((
      day: due,
      label: d.person,
      amount: d.left,
      out: d.direction == DebtDirection.owe,
      debt: d.direction,
    ));
  }
  coming.sort((a, b) => a.day.compareTo(b.day));

  final balances = [
    for (final a in accounts) (name: a.name, balance: inMain(a.balance)),
  ]..sort((a, b) => b.balance - a.balance);
  return FollowedData(
    spends: spends,
    gains: gains,
    accounts: balances,
    parents: parents,
    categories: categories,
    accountsTotal: accountsTotal,
    accountChanges: accountChanges,
    worthChanges: worthChanges,
    accountMoves: accountMoves,
    accountNames: {for (final a in accounts) a.id: a.name},
    reserved: reserved,
    debts: [
      for (final d in debts)
        if (!d.settled) d,
    ],
    projects: projects,
    contributions: contributions,
    coming: coming,
  );
}

/// Where a tile leads (PRODUCT, 27 November 2026: until the tile opens
/// larger, the screen it is about).
class FollowedLinks {
  const FollowedLinks({
    this.operations,
    this.budget,
    this.budgets,
    this.project,
    this.projects,
    this.accounts,
    this.debts,
    this.recurrences,
  });

  /// Opérations on a month, filtered on a category or not.
  final void Function(DateTime month, String? category)? operations;
  final void Function(String budgetId, DateTime month)? budget;
  final VoidCallback? budgets;
  final void Function(String projectId)? project;
  final VoidCallback? projects;
  final VoidCallback? accounts;
  final void Function(DebtDirection tab)? debts;

  /// The recurrences (À venir's action).
  final VoidCallback? recurrences;
}

/// The period the tiles look at, with what the chart already summed.
class FollowedPeriod {
  const FollowedPeriod({
    required this.kind,
    required this.offset,
    required this.span,
    required this.bars,
    required this.startDay,
    required this.now,
    required this.flows,
    required this.totals,
    required this.compared,
    required this.main,
    required this.rates,
    this.label = '',
    this.inlineLabel = '',
    this.grouping = Grouping.day,
    this.comparedBars,
    this.comparedName,
    this.comparedWindow,
  });

  /// The period's name on an enlarged tile (« Novembre »), and as said
  /// inside a line (« novembre »).
  final String label;
  final String inlineLabel;

  /// How [bars] cut the period.
  final Grouping grouping;

  /// The compared period's bars, its name as said inside a line
  /// (« octobre »), and its stretch up to the same date; null without
  /// comparison.
  final List<FlowTotals>? comparedBars;
  final String? comparedName;
  final TimeSpan? comparedWindow;

  final PeriodKind kind;
  final int offset;
  final TimeSpan span;

  /// The chart's bars.
  final List<TimeSpan> bars;
  final int startDay;
  final DateTime now;
  final List<DatedFlow> flows;
  final FlowTotals totals;

  /// The compared period up to the same date; null without comparison.
  final FlowTotals? compared;
  final CurrencyInfo main;
  final Map<String, ExchangeRate> rates;

  PeriodScale get scale => scaleOf(kind, span);
  bool get running => span.contains(now);
  ExchangeRate? rateFor(String code) => rates[code];

  /// The bars begun by now.
  List<TimeSpan> get begun => [
    for (final b in bars)
      if (!b.start.isAfter(now)) b,
  ];

  /// The budget month the tiles speak of: the period's own for a month,
  /// else the one around its end, or today for a period still running.
  DateTime get budgetMonth {
    final at = running ? now : span.end.subtract(const Duration(seconds: 1));
    return BudgetPeriod.containing(at, startDay: startDay).month;
  }
}

/// « Points suivis · Ce mois-ci » with « Suivre », the tiles on two
/// columns, the first 4 then « Voir les autres » (canvas ApercuTMois).
class FollowedSection extends StatelessWidget {
  const FollowedSection({
    super.key,
    required this.period,
    required this.periodLabel,
    required this.choice,
    required this.data,
    required this.book,
    required this.expanded,
    required this.onExpand,
    required this.onFollow,
    required this.links,
  });

  final FollowedPeriod period;

  /// The period's name in the header, for a period that is not the
  /// current one.
  final String periodLabel;
  final FollowedChoice choice;
  final FollowedData? data;

  /// The budgets of [FollowedPeriod.budgetMonth], once read.
  final BudgetBook? book;
  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onFollow;
  final FollowedLinks links;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final shown = choice.shown;
    final tiles = data == null
        ? const <Widget>[]
        : [
            for (final f in expanded ? shown : shown.take(4))
              _Tiles(l, lang, period, data!, book, choice, links).tile(
                f,
                open: () => openEnlarged(
                  context,
                  tiles: shown,
                  initial: shown.indexOf(f),
                  period: period,
                  data: data!,
                  book: book,
                  choice: choice,
                  links: links,
                ),
              ),
          ];
    final title = switch (period.kind) {
      _ when period.offset != 0 => periodLabel,
      PeriodKind.today => l.overviewKindToday,
      PeriodKind.yesterday => l.overviewKindYesterday,
      PeriodKind.last24Hours => l.overviewKind24h,
      PeriodKind.last7Days => l.overviewKind7Days,
      PeriodKind.month => l.followedThisMonth,
      PeriodKind.year => l.followedThisYear,
      PeriodKind.custom => l.followedDays(period.span.days),
    };
    final rest = shown.length - 4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.followedTitle(title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KibuoType.sectionTitle,
                ),
              ),
              _GreenAction(
                label: l.followedFollow,
                icon: KibuoIcons.plusBold,
                onTap: onFollow,
                leading: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < tiles.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[i]),
                const SizedBox(width: 8),
                Expanded(
                  child: i + 1 < tiles.length
                      ? tiles[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
        if (rest > 0)
          Center(
            child: _GreenAction(
              label: expanded ? l.followedLess : l.followedMore(rest),
              icon: expanded ? KibuoIcons.caretUp : KibuoIcons.caretDown,
              onTap: onExpand,
            ),
          ),
      ],
    );
  }
}

/// A green text action with its small icon (« + Suivre », « Voir les 4
/// autres ⌄ »).
class _GreenAction extends StatelessWidget {
  const _GreenAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.leading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool leading;

  @override
  Widget build(BuildContext context) {
    final glyph = Icon(icon, size: 16, color: KibuoColors.accent);
    return InkWell(
      borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: KibuoTheme.heightTouch),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: leading ? 4 : 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading) ...[glyph, const SizedBox(width: 4)],
              Text(
                label,
                style: KibuoType.buttonSmall.copyWith(
                  fontSize: 14,
                  color: KibuoColors.accent,
                ),
              ),
              if (!leading) ...[const SizedBox(width: 4), glyph],
            ],
          ),
        ),
      ),
    );
  }
}

/// Builds each tile for the period, as its scale asks (PRODUCT: each tile
/// fits the period).
class _Tiles {
  _Tiles(
    this.l,
    this.lang,
    this.p,
    this.data,
    this.book,
    this.choice,
    this.links,
  );

  final AppLocalizations l;
  final String lang;
  final FollowedPeriod p;
  final FollowedData data;
  final BudgetBook? book;
  final FollowedChoice choice;
  final FollowedLinks links;

  CurrencyInfo get main => p.main;

  String money(int minor, {String? code}) {
    final m = Money(minor, code ?? main.code);
    return formatAmount(m, currencyOf(m.currency), lang);
  }

  String signed(int minor, {String? code}) => minor == 0
      ? money(0, code: code)
      : '${minor < 0 ? '−' : '+'}${money(minor.abs(), code: code)}';

  int inMain(Money m) {
    if (m.currency == main.code) return m.minor;
    final rate = p.rates[m.currency];
    if (rate == null) return 0;
    return rate.convert(m, to: main).minor;
  }

  String _cap(String t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);

  /// Opérations on the period's month.
  VoidCallback? _toOperations([String? category]) {
    final open = links.operations;
    if (open == null) return null;
    return () => open(p.budgetMonth, category);
  }

  /// The tile; touching it opens the tiles enlarged on it.
  Widget tile(Followed f, {VoidCallback? open}) {
    final made = _made(f);
    if (open == null || made is! FollowedTile) return made;
    return FollowedTile(
      name: made.name,
      value: made.value,
      valueColor: made.valueColor,
      visual: made.visual,
      detail: made.detail,
      detailColor: made.detailColor,
      arrowUp: made.arrowUp,
      onTap: open,
    );
  }

  Widget _made(Followed f) => switch (f) {
    Followed.spent => _spent(),
    Followed.received => _received(),
    Followed.savings => _savings(),
    Followed.average => _average(),
    Followed.topCategory => _topCategory(),
    Followed.priciest => _priciest(),
    Followed.upcoming => _upcoming(),
    Followed.budget => _budget(),
    Followed.debts => _debts(DebtDirection.owe),
    Followed.receivables => _debts(DebtDirection.owed),
    Followed.project => _project(),
    Followed.accounts => _total(worth: false),
    Followed.netWorth => _total(worth: true),
  };

  List<int> _begunExits({bool entries = false}) => [
    for (final t in totalsByBucket(p.begun, p.flows, main, p.rateFor))
      entries ? t.entries.minor : t.exits.minor,
  ];

  /// An arrow and the change in %, or the precision line (PRODUCT, 27
  /// November 2026).
  FollowedTile _withChange({
    required String name,
    required String value,
    required Color valueColor,
    required TileVisual visual,
    required int figure,
    required int? compared,
    required bool lessIsBetter,
    required String precision,
    required VoidCallback? onTap,
  }) {
    final change = compared == null
        ? null
        : changeOf(figure, compared, lessIsBetter: lessIsBetter);
    return FollowedTile(
      name: name,
      value: value,
      valueColor: valueColor,
      visual: visual,
      detail: change == null ? precision : '${change.percent} %',
      detailColor: change == null
          ? KibuoColors.inkSecondary
          : change.good
          ? KibuoColors.accent
          : KibuoColors.warningInk,
      arrowUp: change?.up,
      onTap: onTap,
    );
  }

  Widget _spent() {
    final exits = p.totals.exits.minor;
    final value = exits == 0 ? money(0) : '−${money(exits)}';
    final visual = TileCurve(runningTotal(_begunExits()), _spentLine);
    if (p.scale == PeriodScale.day) {
      // Compared with an average day (PRODUCT, 27 November 2026).
      final day = averageDay(
        p.flows,
        now: p.span.end.subtract(const Duration(microseconds: 1)),
        main: main,
        rateFor: p.rateFor,
      );
      return FollowedTile(
        name: l.followedSpent,
        value: value,
        valueColor: exits == 0 ? KibuoColors.inkMuted : KibuoColors.debtInk,
        visual: visual,
        detail: l.followedAverageDayDetail(money(day)),
        onTap: _toOperations(),
      );
    }
    final perDay = averageOf(
      p.span,
      p.flows,
      unit: Grouping.day,
      now: p.now,
      main: main,
      rateFor: p.rateFor,
    );
    return _withChange(
      name: l.followedSpent,
      value: value,
      valueColor: exits == 0 ? KibuoColors.inkMuted : KibuoColors.debtInk,
      visual: visual,
      figure: exits,
      compared: p.compared?.exits.minor,
      lessIsBetter: true,
      precision: l.followedPerDay(money(perDay.amount)),
      onTap: _toOperations(),
    );
  }

  Widget _received() {
    final entries = p.totals.entries.minor;
    final count = p.flows
        .where(
          (f) => p.span.contains(f.at) && (f.flow.incoming?.minor ?? 0) > 0,
        )
        .length;
    return _withChange(
      name: l.followedReceived,
      value: entries == 0 ? money(0) : '+${money(entries)}',
      valueColor: entries == 0 ? KibuoColors.inkMuted : KibuoColors.accent,
      visual: TileCurve(
        runningTotal(_begunExits(entries: true)),
        KibuoColors.accent,
      ),
      figure: entries,
      compared: p.compared?.entries.minor,
      lessIsBetter: false,
      precision: l.followedEntriesCount(count),
      onTap: _toOperations(),
    );
  }

  Widget _savings() {
    final saved = p.totals.rest.minor;
    final steps = [
      for (final t in totalsByBucket(p.begun, p.flows, main, p.rateFor))
        t.rest.minor,
    ];
    return FollowedTile(
      name: p.kind == PeriodKind.year
          ? l.followedSavingsYear
          : l.followedSavings,
      value: signed(saved),
      valueColor: saved < 0 ? KibuoColors.debtInk : KibuoColors.accent,
      visual: TileCurve(runningTotal(steps), KibuoColors.accent),
      detail: l.followedSavingsDetail,
      onTap: _toOperations(),
    );
  }

  Widget _average() {
    if (p.scale == PeriodScale.day) {
      // A day has no days to average: the 30 days before it.
      final end = p.span.end.subtract(const Duration(microseconds: 1));
      final today = DateTime(end.year, end.month, end.day);
      final days = bucketsOf(
        TimeSpan(DateTime(today.year, today.month, today.day - 30), today),
        Grouping.day,
      );
      final top = priciest(days, p.flows, main: main, rateFor: p.rateFor);
      final value = averageDay(
        p.flows,
        now: end,
        main: main,
        rateFor: p.rateFor,
      );
      return FollowedTile(
        name: l.followedAverageDay,
        value: value == 0 ? money(0) : '−${money(value)}',
        valueColor: value == 0 ? KibuoColors.inkMuted : KibuoColors.debtInk,
        visual: top == null
            ? null
            : TileColumns(top.values, top.index, KibuoColors.debtLine),
        detail: l.followedOverDays(30),
        onTap: _toOperations(),
      );
    }
    final unit = switch (p.scale) {
      PeriodScale.month => Grouping.week,
      PeriodScale.long => Grouping.month,
      _ => Grouping.day,
    };
    final avg = averageOf(
      p.span,
      p.flows,
      unit: unit,
      now: p.now,
      main: main,
      rateFor: p.rateFor,
      startDay: p.startDay,
    );
    final units = bucketsOf(p.span, unit, startDay: p.startDay);
    final top = priciest(units, p.flows, main: main, rateFor: p.rateFor);
    final days = p.running
        ? calendarDays(p.span.start, p.now) + 1
        : p.span.days;
    return FollowedTile(
      name: switch (unit) {
        Grouping.week => l.followedAverageWeek,
        Grouping.month => l.followedAverageMonth,
        _ => l.followedAverageDay,
      },
      value: avg.amount == 0 ? money(0) : '−${money(avg.amount)}',
      valueColor: avg.amount == 0 ? KibuoColors.inkMuted : KibuoColors.debtInk,
      visual: top == null
          ? null
          : TileColumns(top.values, top.index, KibuoColors.debtLine),
      detail: unit == Grouping.month && top != null
          ? l.followedPriciestOf(_monthName(units[top.index].start))
          : l.followedOverDays(days),
      onTap: _toOperations(),
    );
  }

  String _monthName(DateTime start) =>
      DateFormat.MMMM(lang)
          .format(BudgetPeriod.containing(start, startDay: p.startDay).month);

  Widget _topCategory() {
    final top = categoryLines(
      p.span,
      data.spends,
      parentOf: (id) => data.parents[id] ?? id,
      isDebt: isDebtCategoryId,
      total: p.totals.exits.minor,
      withFees: true,
      main: main,
      rateFor: p.rateFor,
    ).firstOrNull;
    final name = p.scale == PeriodScale.day
        ? l.followedTopCategoryDay
        : l.followedTopCategory;
    final category = top?.category == null
        ? null
        : data.categories[top!.category];
    if (top == null) {
      return FollowedTile(
        name: name,
        value: l.followedNoExit,
        valueColor: KibuoColors.inkMuted,
        detail: '—',
        onTap: _toOperations(),
      );
    }
    return FollowedTile(
      name: name,
      value: category != null
          ? categoryName(l, category)
          : top.kind == CategoryLineKind.debts
          ? l.overviewDebtsLine
          : l.overviewFeesLine,
      visual: TileBar(
        top.share / 100,
        categoryHue(category?.color ?? CategoryColor.grey),
      ),
      detail: l.followedAmountShare(money(top.amount), top.share),
      onTap: _toOperations(top.category),
    );
  }

  Widget _priciest() {
    final unit = switch (p.scale) {
      PeriodScale.day => Grouping.hour,
      PeriodScale.long => Grouping.month,
      _ => Grouping.day,
    };
    final units = bucketsOf(p.span, unit, startDay: p.startDay);
    final top = priciest(units, p.flows, main: main, rateFor: p.rateFor);
    final name = switch (unit) {
      Grouping.hour => l.followedPriciestHour,
      Grouping.month => l.followedPriciestMonth,
      _ => l.followedPriciestDay,
    };
    if (top == null) {
      return FollowedTile(
        name: name,
        value: l.followedNoExit,
        valueColor: KibuoColors.inkMuted,
        detail: '—',
        onTap: _toOperations(),
      );
    }
    final start = units[top.index].start;
    return FollowedTile(
      name: name,
      value: switch (unit) {
        Grouping.hour => l.overviewHourMark(start.hour),
        Grouping.month => _cap(_monthName(start)),
        _ when p.scale == PeriodScale.week => _cap(
          DateFormat.EEEE(lang).format(start),
        ),
        _ => DateFormat.MMMEd(lang).format(start),
      },
      visual: TileColumns(top.values, top.index, KibuoColors.debtLine),
      detail: '−${money(top.amount)}',
      onTap: _toOperations(),
    );
  }

  Widget _upcoming() {
    final today = DateTime(p.now.year, p.now.month, p.now.day);
    final next = data.coming.isEmpty ? null : data.coming.first;
    if (next == null) {
      return FollowedTile(
        name: l.followedUpcoming,
        value: l.followedNothingComing,
        valueColor: KibuoColors.inkMuted,
        detail: l.followedNext14Days,
        onTap: _toOperations(),
      );
    }
    final days = calendarDays(today, next.day);
    final perDay = List.filled(15, 0);
    for (final c in data.coming) {
      final d = calendarDays(today, c.day);
      if (d >= 0 && d < 15) perDay[d] += inMain(c.amount).abs();
    }
    final amount = next.amount.minor.abs();
    return FollowedTile(
      name: l.followedUpcoming,
      value: switch (days) {
        <= 0 => l.followedToday(next.label),
        1 => l.followedTomorrow(next.label),
        _ => l.followedIn(next.label, days),
      },
      visual: TileColumns(perDay, days, KibuoColors.inkMuted),
      detail: l.followedOnDay(
        '${next.out ? '−' : '+'}${money(amount, code: next.amount.currency)}',
        DateFormat.MMMd(lang).format(next.day),
      ),
      onTap: switch (next.debt) {
        final tab? when links.debts != null => () => links.debts!(tab),
        _ => _toOperations(),
      },
    );
  }

  Widget _budget() {
    final lines = book?.lines ?? const <BudgetLine>[];
    final id = lines.any((b) => b.budget.id == choice.budget)
        ? choice.budget
        : nearestLimit([
            for (final b in lines) (id: b.budget.id, percent: b.status.percent),
          ]);
    final line = lines.where((b) => b.budget.id == id).firstOrNull;
    if (line == null) {
      return FollowedTile(
        name: l.followedBudget,
        value: l.followedNoBudget,
        valueColor: KibuoColors.inkMuted,
        detail: '—',
        onTap: links.budgets,
      );
    }
    final status = line.status;
    final name = categoryName(l, line.category);
    final open = links.budget == null
        ? null
        : () => links.budget!(line.budget.id, p.budgetMonth);
    final today = DateTime(p.now.year, p.now.month, p.now.day);
    if (p.kind == PeriodKind.today && p.offset == 0) {
      // What is left for today (canvas ApercuTJour).
      final ids = {line.category.id, for (final s in line.category.subs) s.id};
      final spentToday = flowTotals(main, [
        for (final s in data.spends)
          if (ids.contains(s.category) &&
              !s.at.isBefore(today) &&
              s.at.isBefore(today.add(const Duration(days: 1))))
            MoneyFlow(outgoing: s.amount),
      ], p.rateFor).exits.minor;
      final daysLeft = calendarDays(today, book!.period.last) + 1;
      final left = leftForToday(
        amount: status.amount.minor,
        spentBefore: status.spent.minor - spentToday,
        spentToday: spentToday,
        daysLeft: daysLeft,
      );
      return FollowedTile(
        name: l.followedLeftToday,
        value: left.left < 0 ? '−${money(-left.left)}' : money(left.left),
        valueColor: left.left < 0 ? KibuoColors.debtInk : KibuoColors.accent,
        visual: TileBar(
          left.allowance <= 0 ? 1 : spentToday / left.allowance,
          left.left < 0 ? KibuoColors.debtLine : KibuoColors.mint,
        ),
        detail: l.followedMonthBudget(name),
        onTap: open,
      );
    }
    final level = SpentLevel.share(status.percent);
    final String detail;
    if (p.scale == PeriodScale.month) {
      final left = status.left.minor;
      detail = left >= 0
          ? l.followedLeft(money(left))
          : l.followedOver(money(-left));
    } else {
      final month = _cap(DateFormat.MMMM(lang).format(p.budgetMonth));
      detail = book!.period.contains(p.now)
          ? l.followedMonthRunning(month)
          : month;
    }
    return FollowedTile(
      name: l.followedBudgetNamed(name),
      value: '${status.percent} %',
      valueColor: level.ink,
      visual: TileBar(status.percent / 100, level.bar),
      detail: detail,
      onTap: open,
    );
  }

  Widget _debts(DebtDirection direction) {
    final lines = [
      for (final d in data.debts)
        if (d.direction == direction) d,
    ];
    final left = totalIn(main, [
      for (final d in lines) d.left,
    ], p.rateFor).amount.minor;
    final amount = totalIn(main, [
      for (final d in lines) d.amount,
    ], p.rateFor).amount.minor;
    final owe = direction == DebtDirection.owe;
    final today = DateTime(p.now.year, p.now.month, p.now.day);
    final late = lines
        .where((d) => d.due != null && d.due!.isBefore(today))
        .length;
    final forgiven = totalIn(main, [
      for (final d in lines) ?d.forgiven,
    ], p.rateFor).amount.minor;
    return FollowedTile(
      name: owe ? l.followedDebts : l.followedReceivables,
      value: money(left),
      valueColor: owe ? KibuoColors.debtInk : KibuoColors.accent,
      visual: TileBar(
        amount <= 0 ? 0 : 1 - left / amount,
        owe ? KibuoColors.debtLine : KibuoColors.accentDash,
      ),
      detail: owe
          ? (late > 0
                ? l.followedLate(late)
                : l.followedDebtCount(lines.length))
          : l.followedRecovered(money(math.max(0, amount - forgiven - left))),
      detailColor: owe && late > 0
          ? KibuoColors.danger
          : KibuoColors.inkSecondary,
      onTap: links.debts == null ? null : () => links.debts!(direction),
    );
  }

  Widget _project() {
    final projects = data.projects;
    if (p.scale == PeriodScale.long) {
      // Over a year: the projects reached (canvas ApercuTAn).
      final reached =
          [
            for (final x in projects)
              if (x.reached) x,
          ]..sort(
            (a, b) =>
                (b.endedOn ?? b.startedOn).compareTo(a.endedOn ?? a.startedOn),
          );
      return FollowedTile(
        name: l.followedProjectsReached,
        value: l.followedReachedOf(reached.length, projects.length),
        valueColor: KibuoColors.projectInk,
        visual: TileBar(
          projects.isEmpty ? 0 : reached.length / projects.length,
          KibuoColors.projectLine,
        ),
        detail: reached.isEmpty ? l.followedNoneReached : reached.first.name,
        onTap: links.projects,
      );
    }
    final id = projects.any((x) => x.id == choice.project)
        ? choice.project
        : soonestDue([
            for (final x in projects)
              (id: x.id, due: x.due, running: x.running),
          ]);
    final project = projects.where((x) => x.id == id).firstOrNull;
    if (project == null) {
      return FollowedTile(
        name: l.followedProject,
        value: l.followedNoProject,
        valueColor: KibuoColors.inkMuted,
        detail: '—',
        onTap: links.projects,
      );
    }
    final moved = [
      for (final c
          in data.contributions[project.id] ?? const <ContributionLine>[])
        if (p.span.contains(c.date)) c.amount.minor,
    ].fold(0, (a, b) => a + b);
    final code = project.goal.currency;
    return FollowedTile(
      name: l.followedProjectNamed(project.name),
      value: '${(project.share * 100).round()} %',
      valueColor: KibuoColors.projectInk,
      visual: TileBar(project.share, KibuoColors.projectLine),
      detail: moved < 0
          ? l.followedTakenBack(money(-moved, code: code))
          : l.followedPutAside(money(moved, code: code)),
      onTap: links.project == null ? null : () => links.project!(project.id),
    );
  }

  /// Comptes, or Patrimoine net: today's total, back in time.
  Widget _total({required bool worth}) {
    var current = data.accountsTotal;
    if (worth) {
      for (final d in data.debts) {
        final left = inMain(d.left);
        current += d.direction == DebtDirection.owed ? left : -left;
      }
    }
    final changes = worth ? data.worthChanges : data.accountChanges;
    final moments = [p.span.start, for (final b in p.begun) b.end];
    final values = totalsBack(moments, current: current, changes: changes);
    final end = p.running
        ? current
        : totalsBack([p.span.end], current: current, changes: changes).first;
    final low = values.reduce(math.min);
    return FollowedTile(
      name: worth ? l.followedNetWorth : l.followedAccounts,
      value: end < 0 ? '−${money(-end)}' : money(end),
      visual: TileCurve([for (final v in values) v - low], KibuoColors.accent),
      detail: signed(end - values.first),
      onTap: links.accounts,
    );
  }
}
