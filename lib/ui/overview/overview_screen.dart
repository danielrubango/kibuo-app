import 'package:flutter/material.dart';
import 'package:kibuo/data/overview_store.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/domain/categories/default_categories.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/obligations/debt_list.dart';
import 'package:kibuo/domain/overview/category_lines.dart';
import 'package:kibuo/domain/overview/followed.dart';
import 'package:kibuo/domain/overview/overview_choice.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/overview/overview_totals.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/tab_strip.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/overview/categories_card.dart';
import 'package:kibuo/ui/overview/category_page.dart';
import 'package:kibuo/ui/overview/evolution_chart.dart';
import 'package:kibuo/ui/overview/follow_sheet.dart';
import 'package:kibuo/ui/overview/followed_section.dart';
import 'package:kibuo/ui/overview/followed_tile.dart';
import 'package:kibuo/ui/overview/overview_labels.dart';
import 'package:kibuo/ui/overview/period_sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operations_list.dart' show flowOf;

enum _Tab { evolution, categories, worth }

/// The Aperçu tab (canvas ApercuP2, PRODUCT 27 November 2026): « Aperçu
/// ‹ période ⌄ › », the Évolution, Catégories and Patrimoine tabs, then
/// Sorties and Entrées over the chart. Catégories and Patrimoine come in
/// later deliveries.
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    required this.data,
    this.refresh,
    this.now,
    this.store,
    this.budgets,
    this.links = const FollowedLinks(),
    this.clock = DateTime.now,
  });

  final EntryData data;

  /// Reads a month's budgets for « Un budget »; none in some tests.
  final BudgetLoader? budgets;

  /// Where the followed tiles lead.
  final FollowedLinks links;

  /// The time now; a fixed one in the screen captures.
  final DateTime Function() clock;

  /// Fires after a save: the figures are read again.
  final Listenable? refresh;

  /// Fires to come back to the current period (Accueil's month).
  final Listenable? now;

  /// Keeps the « Période » choices; none in some tests.
  final OverviewStore? store;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  OverviewChoice _choice = const OverviewChoice();
  int _offset = 0;
  _Tab _tab = _Tab.evolution;

  /// Entrées is the tile shown; Sorties by default.
  bool _entries = false;

  List<DatedFlow> _flows = const [];
  CurrencyInfo? _main;
  Map<String, ExchangeRate> _rates = const {};

  FollowedChoice _followed = const FollowedChoice();
  FollowedData? _followedData;

  /// « Voir les autres » is open.
  bool _allTiles = false;

  /// Each month's budgets, read once per load.
  final _books = <DateTime, BudgetBook>{};
  final _reading = <DateTime>{};

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_load);
    widget.now?.addListener(_startChanged);
    monthStartChoice.addListener(_startChanged);
    _readChoice();
    _load();
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_load);
    widget.now?.removeListener(_startChanged);
    monthStartChoice.removeListener(_startChanged);
    super.dispose();
  }

  /// Back to the current period: « Début du mois » changed, or Accueil's
  /// month was touched. The period after and the current one have no
  /// sense there: compared with the period before.
  void _startChanged() {
    final comparison = _choice.comparisonAt(0);
    _show((
      choice: comparison == _choice.comparison
          ? _choice
          : _choice.withComparison(comparison),
      offset: 0,
    ));
  }

  Future<void> _readChoice() async {
    final choice = await widget.store?.read();
    final followed = await widget.store?.readFollowed();
    if (!mounted) return;
    setState(() {
      if (choice != null) _choice = choice;
      if (followed != null) _followed = followed;
    });
  }

  void _follow(FollowedChoice choice) {
    setState(() => _followed = choice);
    widget.store?.writeFollowed(choice);
  }

  /// Reads [month]'s budgets once, for « Un budget ».
  void _readBook(DateTime month) {
    final loader = widget.budgets;
    if (loader == null || _books.containsKey(month) || !_reading.add(month)) {
      return;
    }
    loader.load(month).then((book) {
      _reading.remove(month);
      if (mounted) setState(() => _books[month] = book);
    });
  }

  /// The same operations as the month totals of Opérations (PRODUCT):
  /// saved ones only, debts' only if the user wants, transfers by their
  /// fees, in the main currency at the latest rate.
  Future<void> _load() async {
    final data = widget.data;
    final debtsCount = await data.debts?.countInTotals() ?? true;
    final all = await data.transactions.all();
    final debts = await data.debts?.debts() ?? const <DebtLine>[];
    final projects = await data.projects?.projects() ?? const <ProjectInfo>[];
    final accounts = [
      ...await data.accounts.accounts(),
      ...await data.accounts.accounts(archived: true),
    ];
    final code =
        await data.currencies.primaryCurrency() ??
        (accounts.isEmpty ? 'USD' : accounts.first.currency);
    final main = await data.currencies.currency(code);
    final rates = <String, ExchangeRate>{};
    for (final c in {
      for (final a in accounts) a.currency,
      for (final d in debts) d.amount.currency,
      for (final p in projects) p.goal.currency,
    }) {
      if (c == code) continue;
      final info = await data.currencies.latestRate(code, c);
      if (info != null) rates[c] = info.rate;
    }
    if (!mounted) return;
    final counted = [
      for (final t in all)
        if (t.counts && (debtsCount || t.debtId == null)) t,
    ];
    final followed = await loadFollowedData(
      context,
      data,
      counted: counted,
      debts: debts,
      main: main,
      rates: rates,
      now: widget.clock(),
    );
    if (!mounted) return;
    setState(() {
      _flows = [
        for (final t in counted) (at: t.date.toLocal(), flow: flowOf(t)),
      ];
      _main = main;
      _rates = rates;
      _followedData = followed;
      // Budgets may have changed: read again when shown.
      _books.clear();
    });
  }

  void _show(OverviewView view) {
    final changed = !identical(view.choice, _choice);
    setState(() {
      _choice = view.choice;
      _offset = view.offset;
    });
    if (changed) widget.store?.write(view.choice);
  }

  void _back() => _show((choice: _choice, offset: _offset - 1));

  void _ahead() {
    if (_offset >= 0) return;
    final offset = _offset + 1;
    // The period after and the current one do not exist from the current
    // period: back to the period before (canvas ApercuP2).
    final choice = offset == 0 && !comparisonOpen(_choice.comparison, offset: 0)
        ? _choice.withComparison(Comparison.previous)
        : _choice;
    _show((choice: choice, offset: offset));
  }

  void _openSheet() => showPeriodSheet(
    context,
    view: (choice: _choice, offset: _offset),
    startDay: monthStartChoice.value,
    onChanged: _show,
    clock: widget.clock,
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = widget.clock();
    final startDay = monthStartChoice.value;
    TimeSpan spanAt(int offset) => periodSpan(
      _choice.kind,
      now: now,
      offset: offset,
      startDay: startDay,
      custom: _choice.custom,
    );
    final span = spanAt(_offset);
    final label = periodLabel(l, lang, _choice.kind, _offset, span);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, KibuoTheme.belowTabBar),
      children: [
        _Header(
          title: l.tabOverview,
          period: label,
          onPeriod: _openSheet,
          onBack: _back,
          onAhead: _offset < 0 ? _ahead : null,
          backLabel: l.overviewPreviousPeriod,
          aheadLabel: l.overviewNextPeriod,
        ),
        const SizedBox(height: 14),
        TabStrip<_Tab>(
          items: [
            (_Tab.evolution, l.overviewEvolution),
            (_Tab.categories, l.overviewCategories),
            (_Tab.worth, l.overviewWorth),
          ],
          value: _tab,
          onPick: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: 14),
        switch (_tab) {
          _Tab.evolution => _evolution(l, lang, now, span, label, spanAt),
          _Tab.categories => _categories(l, lang, now, span, label, spanAt),
          _Tab.worth => _Soon(
            icon: KibuoIcons.bank,
            tint: KibuoColors.projectTint,
            ink: KibuoColors.projectInk,
            title: l.overviewSoon,
            text: l.overviewWorthText,
          ),
        },
      ],
    );
  }

  Widget _evolution(
    AppLocalizations l,
    String lang,
    DateTime now,
    TimeSpan span,
    String label,
    TimeSpan Function(int offset) spanAt,
  ) {
    final main = _main;
    if (main == null) return const SizedBox(height: 300);
    final startDay = monthStartChoice.value;
    final grouping = _choice.groupingFor(span);
    final bars = bucketsOf(span, grouping, startDay: startDay);
    final byBar = totalsByBucket(bars, _flows, main, (c) => _rates[c]);
    final totals = totalsWithin(span, _flows, main, (c) => _rates[c]);

    final comparison = _choice.comparisonAt(_offset);
    final comparedAt = comparedOffset(comparison, offset: _offset);
    List<FlowTotals>? comparedBars;
    FlowTotals? comparedTotals;
    String? comparedName;
    String? comparedTileName;
    TimeSpan? comparedWindow;
    if (comparedAt != null) {
      final compared = spanAt(comparedAt);
      comparedBars = totalsByBucket(
        bucketsOf(compared, grouping, startDay: startDay),
        _flows,
        main,
        (c) => _rates[c],
      );
      final until = comparedUntil(
        current: span,
        compared: compared,
        now: now,
        grouping: grouping,
      );
      comparedWindow = TimeSpan(compared.start, until);
      comparedTotals = totalsWithin(
        comparedWindow,
        _flows,
        main,
        (c) => _rates[c],
      );
      comparedName = periodLabel(l, lang, _choice.kind, comparedAt, compared);
      comparedTileName = tilePeriodName(
        l,
        lang,
        _choice.kind,
        comparedAt,
        compared,
        now: now,
      );
    }
    final tileName = tilePeriodName(
      l,
      lang,
      _choice.kind,
      _offset,
      span,
      now: now,
    );

    String money(Money m, {bool short = false}) =>
        formatAmount(m, currencyOf(m.currency), lang, short: short);
    final out = !_entries;
    final period = FollowedPeriod(
      kind: _choice.kind,
      offset: _offset,
      span: span,
      bars: bars,
      startDay: startDay,
      now: now,
      flows: _flows,
      totals: totals,
      compared: comparedTotals,
      main: main,
      rates: _rates,
      label: capitalized(tileName),
      inlineLabel: tileName,
      grouping: grouping,
      comparedBars: comparedBars,
      comparedName: comparedTileName,
      comparedWindow: comparedWindow,
    );
    final month = period.budgetMonth;
    final book = _books[month];
    if (book == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _readBook(month));
    }
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _flowTiles(l, totals, comparedTotals, money),
          const SizedBox(height: 10),
          EvolutionChart(
            values: [
              for (final b in byBar) out ? b.exits.minor : b.entries.minor,
            ],
            ahead: [for (final b in bars) b.start.isAfter(now)],
            marks: [
              for (var i = 0; i < bars.length; i++)
                barMark(
                  l,
                  lang,
                  _choice.kind,
                  grouping,
                  bars,
                  i,
                  startDay: startDay,
                ),
            ],
            out: out,
            currentName: label,
            compared: comparedBars == null
                ? null
                : [
                    for (final b in comparedBars)
                      out ? b.exits.minor : b.entries.minor,
                  ],
            comparedName: comparedName,
            comparedAs: _choice.comparedAs,
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        const SizedBox(height: 14),
        FollowedSection(
          period: period,
          periodLabel: label,
          choice: _followed,
          data: _followedData,
          book: book,
          expanded: _allTiles,
          onExpand: () => setState(() => _allTiles = !_allTiles),
          onFollow: () => _openFollow(l, book),
          links: widget.links,
        ),
      ],
    );
  }

  /// Sorties and Entrées, each with its change; touching one shows it, in
  /// Évolution and Catégories alike (PRODUCT, 27 November 2026).
  Widget _flowTiles(
    AppLocalizations l,
    FlowTotals totals,
    FlowTotals? comparedTotals,
    String Function(Money m, {bool short}) money,
  ) {
    final out = !_entries;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FlowTile(
            label: l.overviewExits,
            amount: totals.exits,
            approximate: totals.approximate,
            out: true,
            chosen: out,
            compared: comparedTotals != null,
            change: comparedTotals == null
                ? null
                : changeOf(
                    totals.exits.minor,
                    comparedTotals.exits.minor,
                    lessIsBetter: true,
                  ),
            money: money,
            onTap: () => setState(() => _entries = false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _FlowTile(
            label: l.overviewEntries,
            amount: totals.entries,
            approximate: totals.approximate,
            out: false,
            chosen: !out,
            compared: comparedTotals != null,
            change: comparedTotals == null
                ? null
                : changeOf(
                    totals.entries.minor,
                    comparedTotals.entries.minor,
                    lessIsBetter: false,
                  ),
            money: money,
            onTap: () => setState(() => _entries = true),
          ),
        ),
      ],
    );
  }

  /// The Catégories tab: the same tiles, then where the money went (or came
  /// from), category by category (canvas ApercuP2, PRODUCT, 27 November
  /// 2026).
  Widget _categories(
    AppLocalizations l,
    String lang,
    DateTime now,
    TimeSpan span,
    String label,
    TimeSpan Function(int offset) spanAt,
  ) {
    final main = _main;
    final data = _followedData;
    if (main == null || data == null) return const SizedBox(height: 300);
    final grouping = _choice.groupingFor(span);
    final totals = totalsWithin(span, _flows, main, (c) => _rates[c]);
    FlowTotals? comparedTotals;
    final comparedAt = comparedOffset(
      _choice.comparisonAt(_offset),
      offset: _offset,
    );
    if (comparedAt != null) {
      final compared = spanAt(comparedAt);
      final until = comparedUntil(
        current: span,
        compared: compared,
        now: now,
        grouping: grouping,
      );
      comparedTotals = totalsWithin(
        TimeSpan(compared.start, until),
        _flows,
        main,
        (c) => _rates[c],
      );
    }
    String money(Money m, {bool short = false}) =>
        formatAmount(m, currencyOf(m.currency), lang, short: short);
    final out = !_entries;
    final total = out ? totals.exits.minor : totals.entries.minor;
    final lines = categoryLines(
      span,
      out ? data.spends : data.gains,
      parentOf: (id) => data.parents[id] ?? id,
      isDebt: isDebtCategoryId,
      total: total,
      withFees: out,
      main: main,
      rateFor: (c) => _rates[c],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          child: _flowTiles(l, totals, comparedTotals, money),
        ),
        const SizedBox(height: 14),
        CategoriesCard(
          out: out,
          lines: lines,
          total: money(Money(total, main.code)),
          categories: data.categories,
          money: (minor) => money(Money(minor, main.code)),
          onOpen: (id) {
            final category = data.categories[id];
            if (category == null) return;
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => CategoryPage(
                  data: widget.data,
                  category: category,
                  categories: data.categories,
                  periodLabel: label,
                  span: span,
                  out: out,
                  periodTotal: total,
                  main: main,
                  rates: _rates,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// « Suivre »: the budgets of the month shown and the running projects
  /// can be picked.
  void _openFollow(AppLocalizations l, BudgetBook? book) {
    final lines = book?.lines ?? const <BudgetLine>[];
    final projects = [
      for (final p in _followedData?.projects ?? const <ProjectInfo>[])
        if (p.running) p,
    ];
    final budget = lines.any((b) => b.budget.id == _followed.budget)
        ? _followed.budget
        : nearestLimit([
            for (final b in lines) (id: b.budget.id, percent: b.status.percent),
          ]);
    final project = projects.any((p) => p.id == _followed.project)
        ? _followed.project
        : soonestDue([
            for (final p in projects) (id: p.id, due: p.due, running: true),
          ]);
    showFollowSheet(
      context,
      choice: _followed,
      budgets: [
        for (final b in lines) (b.budget.id, categoryName(l, b.category)),
      ],
      projects: [for (final p in projects) (p.id, p.name)],
      budgetShown: budget,
      projectShown: project,
      onChanged: _follow,
    );
  }
}

/// « Aperçu » at the left; the period between ‹ and › at the right (canvas
/// ApercuP2), › greyed on the current period.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.period,
    required this.onPeriod,
    required this.onBack,
    required this.onAhead,
    required this.backLabel,
    required this.aheadLabel,
  });

  final String title;
  final String period;
  final VoidCallback onPeriod;
  final VoidCallback onBack;
  final VoidCallback? onAhead;
  final String backLabel;
  final String aheadLabel;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, String label, VoidCallback? onTap) => Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
        onTap: onTap == null
            ? null
            : () {
                Haptics.tap();
                onTap();
              },
        child: SizedBox(
          width: 40,
          height: KibuoTheme.heightTouch,
          child: Icon(
            icon,
            size: 22,
            color: onTap == null ? KibuoColors.line : KibuoColors.ink,
          ),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: KibuoTheme.heightTouch),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(title, style: KibuoType.tabTitle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Transform.translate(
              offset: const Offset(8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  arrow(KibuoIcons.caretLeft, backLabel, onBack),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          KibuoTheme.radiusPill,
                        ),
                        onTap: onPeriod,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 40),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    period,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: KibuoType.buttonSmall,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  KibuoIcons.caretDown,
                                  size: 16,
                                  color: KibuoColors.accent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  arrow(KibuoIcons.caretRight, aheadLabel, onAhead),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// « Sorties » or « Entrées »: the amount, its change against the compared
/// period, and a radio; the one shown is tinted (DIRECTION, Aperçu).
class _FlowTile extends StatelessWidget {
  const _FlowTile({
    required this.label,
    required this.amount,
    required this.approximate,
    required this.out,
    required this.chosen,
    required this.compared,
    required this.change,
    required this.money,
    required this.onTap,
  });

  final String label;
  final Money amount;
  final bool approximate;
  final bool out;
  final bool chosen;

  /// A period is compared: the change's line is kept, empty when there is
  /// nothing to compare with.
  final bool compared;
  final Change? change;
  final String Function(Money, {bool short}) money;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = out ? KibuoColors.debtInk : KibuoColors.accent;
    final tint = out ? KibuoColors.debtTint : KibuoColors.accentTintStrong;
    final pre = approximate ? '≈ ' : '';
    final zero = amount.minor == 0;
    String text(bool short) => zero
        ? money(amount, short: short)
        : '$pre${out ? '−' : '+'}${money(amount, short: short)}';
    final change = this.change;
    final changeInk = change == null || change.good
        ? KibuoColors.accent
        : KibuoColors.warningInk;
    return Semantics(
      selected: chosen,
      button: true,
      child: Material(
        color: chosen ? tint : KibuoColors.fillSoft,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
        child: InkWell(
          borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
          onTap: chosen
              ? null
              : () {
                  Haptics.tap();
                  onTap();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KibuoType.caption,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Radio(
                      on: chosen,
                      color: chosen ? ink : KibuoColors.lineStrong,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                FitAmount(
                  long: isLong(amount),
                  style: KibuoType.cardTitle.copyWith(
                    fontSize: 18,
                    color: zero ? KibuoColors.inkMuted : ink,
                  ),
                  span: (short) => TextSpan(text: text(short)),
                ),
                if (compared) ...[
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 16,
                    // Nothing to compare with: a dash, not an empty line
                    // (owner, 27 November 2026).
                    child: change == null
                        ? Text(
                            '—',
                            style: KibuoType.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              fontVariations: const [FontVariation.weight(700)],
                              color: KibuoColors.inkMuted,
                            ),
                          )
                        : Row(
                            children: [
                              CustomPaint(
                                size: const Size.square(14),
                                painter: TrendArrow(
                                  up: change.up,
                                  color: changeInk,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${change.percent} %',
                                style: KibuoType.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontVariations: const [
                                    FontVariation.weight(700),
                                  ],
                                  color: changeInk,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on, required this.color});

  final bool on;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(
      color: KibuoColors.surface,
      shape: BoxShape.circle,
      border: Border.all(color: color, width: 2),
    ),
    alignment: Alignment.center,
    child: on
        ? Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
        : null,
  );
}

/// A tab that comes in a later delivery: a white card, its icon, « Bientôt »
/// and what it will show.
class _Soon extends StatelessWidget {
  const _Soon({
    required this.icon,
    required this.tint,
    required this.ink,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final Color tint;
  final Color ink;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
    decoration: BoxDecoration(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
    ),
    child: Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
          ),
          child: Icon(icon, color: ink),
        ),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: KibuoType.cardTitle),
        const SizedBox(height: 8),
        Text(text, textAlign: TextAlign.center, style: KibuoType.help),
      ],
    ),
  );
}
