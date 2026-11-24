import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/todo_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/accounts/account_total.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/home/todo.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/day_header.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/month_summary_card.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/spent_bar.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/obligations/debt_home_cards.dart';
import 'package:kibuo/ui/obligations/debt_screen.dart';
import 'package:kibuo/ui/recurrences/planned_operation.dart';
import 'package:kibuo/ui/recurrences/recurrences_screen.dart';
import 'package:kibuo/ui/recurrences/rhythm_text.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';

/// The « Accueil » tab (canvas Aujourdhui, Total_sansprojet): today's date,
/// what is available, the month so far, « À traiter » and « À venir ».
/// Debts join it with their module (PRODUCT).
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.data,
    this.refresh,
    this.onOpenAccounts,
    this.onOpenMonth,
    this.budgets,
    this.todos,
    this.onChanged,
    this.onOpenDebts,
    this.onOpenProjects,
    this.onNewProject,
  });

  /// The strip under the available amount: the projects, or a first one.
  final VoidCallback? onOpenProjects;
  final VoidCallback? onNewProject;

  /// Touching « Je dois » or « On me doit »: the debts, on that tab.
  final ValueChanged<DebtDirection>? onOpenDebts;

  /// Something done from here (a draft, a recurrence) may change other
  /// tabs: the shell reloads them all, this one included.
  final VoidCallback? onChanged;

  final EntryData data;

  /// For the budgets of « À traiter ».
  final BudgetLoader? budgets;

  /// Where « Plus tard » is kept.
  final TodoStore? todos;

  /// Bumped by the shell when something may have changed.
  final Listenable? refresh;

  /// Touching the available amount.
  final VoidCallback? onOpenAccounts;

  /// Touching the month: the list, until the overview exists.
  final VoidCallback? onOpenMonth;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CurrencyInfo? _main;
  AccountTotal? _available;
  FlowTotals? _month;
  List<HomeTodo> _todo = const [];

  /// Each recurrence due in the next 14 days, once, at its next date:
  /// the 5 nearest (PRODUCT).
  List<(TransactionInfo, OperationLabels, Schedule)> _coming = const [];

  /// Debts and receivables due in those 14 days, among the 5 shown.
  List<DebtLine> _comingDebts = const [];

  /// How many recurrences are due in those 14 days.
  int _comingCount = 0;

  AccountTotal? _total;
  AccountTotal? _held;
  bool _hasProjects = false;

  /// The debts and receivables not settled (PRODUCT: Dettes et créances).
  List<DebtLine> _debts = const [];
  Map<String, ExchangeRate> _rates = const {};

  /// One side of the home cards, in the main currency.
  DebtSide _side(DebtDirection direction, CurrencyInfo main, String lang) {
    final lines = [
      for (final d in _debts)
        if (d.direction == direction) d,
    ];
    if (lines.isEmpty) return const DebtSide(total: null, count: 0);
    final total = totalIn(main, [
      for (final d in lines) d.left,
    ], (code) => _rates[code]);
    final now = DateTime.now();
    return DebtSide(
      total: formatMoney(total.amount, main, lang),
      count: lines.length,
      late: lines.where((d) => debtState(d, now).$1 == DebtState.late).length,
    );
  }

  static const _comingShown = 5;

  TodoLoader _loader(BuildContext context) => TodoLoader(
    data: widget.data,
    budgets: widget.budgets,
    store: widget.todos,
    lock: KibuoLock.maybeControllerOf(context),
  );

  TodoActions _actions(BuildContext context) => TodoActions(
    data: widget.data,
    budgets: widget.budgets,
    store: widget.todos,
    lock: KibuoLock.maybeControllerOf(context),
    reload: _changed,
  );

  Future<void> _changed() async {
    final changed = widget.onChanged;
    if (changed == null) return _load();
    changed();
  }

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(HomeScreen old) {
    super.didUpdateWidget(old);
    if (old.refresh != widget.refresh) {
      old.refresh?.removeListener(_load);
      widget.refresh?.addListener(_load);
    }
  }

  @override
  void dispose() {
    widget.refresh?.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final data = widget.data;
    final accounts = await data.accounts.accounts();
    final ops = await data.transactions.all();
    final mainCode = await data.currencies.primaryCurrency() ?? 'USD';
    final main = await data.currencies.currency(mainCode);
    final now = DateTime.now();
    // Debts' operations stay apart when the user chose so (PRODUCT).
    final debtsCount = await data.debts?.countInTotals() ?? true;
    final month = [
      for (final t in ops)
        if (periodOf(now).contains(t.date.toLocal()) &&
            (debtsCount || t.debtId == null))
          t,
    ];
    final held = await data.projects?.reserved() ?? const <String, int>{};
    final hasProjects = (await data.projects?.projects() ?? const []).any(
      (p) => p.running,
    );
    final debts = [
      for (final d in await data.debts?.debts() ?? const <DebtLine>[])
        if (!d.settled) d,
    ];
    final rates = <String, ExchangeRate>{};
    final codes = {
      for (final a in accounts) a.balance.currency,
      for (final d in debts) d.left.currency,
      for (final t in month) ...[
        if (flowOf(t).incoming case final m?) m.currency,
        if (flowOf(t).outgoing case final m?) m.currency,
      ],
    }..remove(mainCode);
    for (final code in codes) {
      final rate = await data.currencies.latestRate(mainCode, code);
      if (rate != null) rates[code] = rate.rate;
    }
    if (!mounted) return;
    final todo = await _loader(context).load(context, now);
    final today = DateTime(now.year, now.month, now.day);
    final planned =
        await data.recurrences?.planned(
          now: now,
          until: today.add(const Duration(days: 14)),
        ) ??
        const [];
    // In date order: the first date of a recurrence is its next.
    final seen = <String>{};
    final next = [
      for (final p in planned)
        if (seen.add(p.rule.id)) p,
    ];
    // Debts due in the 14 days join them, in date order (PRODUCT).
    final dueDebts = [
      for (final d in debts)
        if (d.due case final due?)
          if (!due.isBefore(today) &&
              due.isBefore(today.add(const Duration(days: 15))))
            d,
    ];
    final both = <(DateTime, Object)>[
      for (final p in next) (p.day, p),
      for (final d in dueDebts) (d.due!, d),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final shown = both.take(_comingShown).map((e) => e.$2).toList();
    final comingDebts = [
      for (final e in shown)
        if (e is DebtLine) e,
    ];
    final coming = <(TransactionInfo, OperationLabels, Schedule)>[];
    for (final p in shown.whereType<Planned>()) {
      if (!mounted) return;
      final t = plannedOperation(p);
      coming.add((
        t,
        await OperationLabels.of(context, data, t),
        p.rule.schedule,
      ));
    }
    if (!mounted) return;
    setState(() {
      _todo = todo;
      _coming = coming;
      _comingCount = next.length + dueDebts.length;
      _comingDebts = comingDebts;
      _main = main;
      // Available: the accounts less what projects hold back (PRODUCT).
      _available = totalIn(main, [
        for (final a in accounts)
          Money(a.balance.minor - (held[a.id] ?? 0), a.balance.currency),
      ], (code) => rates[code]);
      _total = totalIn(main, [
        for (final a in accounts) a.balance,
      ], (code) => rates[code]);
      _held = totalIn(main, [
        for (final a in accounts)
          if (held[a.id] case final h? when h > 0) Money(h, a.balance.currency),
      ], (code) => rates[code]);
      _hasProjects = hasProjects;
      _month = flowTotals(main, month.map(flowOf), (code) => rates[code]);
      _debts = debts;
      _rates = rates;
    });
  }

  Future<void> _openCurrencies() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CurrenciesScreen(repository: widget.data.currencies),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final available = _available;
    final month = _month;
    final main = _main;
    return ListView(
      // Room for the floating bar and its fade.
      padding: const EdgeInsets.fromLTRB(16, 16, 16, KibuoTheme.belowTabBar),
      children: [
        TabHeader(
          title: TabHeader.text(l.homeTitle),
          subtitle: _capitalized(DateFormat.MMMMEEEEd(lang).format(now)),
        ),
        if (available != null && month != null && main != null) ...[
          const SizedBox(height: 16),
          _AvailableCard(
            long: isLong(available.amount),
            amount: (short) => (short ? formatShort : formatMoney)(
              available.amount,
              main,
              lang,
            ),
            onTap: widget.onOpenAccounts,
            strip: widget.onOpenProjects == null || _total == null
                ? null
                : _ProjectsStrip(
                    total: formatMoney(_total!.amount, main, lang),
                    held: _hasProjects
                        ? formatMoney(_held!.amount, main, lang)
                        : null,
                    onTap: _hasProjects
                        ? widget.onOpenProjects!
                        : widget.onNewProject ?? widget.onOpenProjects!,
                  ),
          ),
          if (available.withoutRate.isNotEmpty) ...[
            const SizedBox(height: 8),
            HelpText(l.accountsNoRateNote(available.withoutRate.join(', '))),
            Align(
              alignment: Alignment.centerLeft,
              child: TextAction(
                label: l.accountsAddRate,
                onPressed: _openCurrencies,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _MonthCard(
            name: _capitalized(
              DateFormat.MMMM(lang).format(periodOf(now).month),
            ),
            totals: month,
            today: (now, periodOf(now)),
            money: (m, short) =>
                (short ? formatShort : formatMoney)(m, main, lang),
            signed: (m, short) => short
                ? '${m.minor > 0 ? '+' : ''}'
                      '${formatShort(m, main, lang, symbol: false)}'
                : formatSigned(m, main, lang),
            onTap: widget.onOpenMonth,
          ),
          // Under the month, as soon as something is owed (PRODUCT).
          if (_debts.isNotEmpty && widget.onOpenDebts != null) ...[
            const SizedBox(height: 8),
            DebtHomeCards(
              owe: _side(DebtDirection.owe, main, lang),
              owed: _side(DebtDirection.owed, main, lang),
              onOpen: widget.onOpenDebts!,
            ),
          ],
        ],
        if (_todo.isNotEmpty)
          TodoSection(
            items: _todo,
            actions: _actions(context),
            onSeeAll: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => TodoListScreen(
                  loader: _loader(context),
                  actions: _actions(context),
                ),
              ),
            ),
          ),
        if (_coming.isNotEmpty || _comingDebts.isNotEmpty) ..._upcoming(l),
      ],
    );
  }

  /// « À venir » (canvas Aujourdhui): the recurrences of the next 14 days,
  /// as the list's planned operations, under their date (PRODUCT).
  List<Widget> _upcoming(AppLocalizations l) {
    final lang = Localizations.localeOf(context).languageCode;
    final days = <DateTime, List<Object>>{};
    for (final e in _coming) {
      final d = e.$1.date.toLocal();
      (days[DateTime(d.year, d.month, d.day)] ??= []).add(e);
    }
    for (final d in _comingDebts) {
      final due = d.due!;
      (days[DateTime(due.year, due.month, due.day)] ??= []).add(d);
    }
    final sorted = days.keys.toList()..sort();
    return [
      const SizedBox(height: GroupTitle.before),
      GroupTitle(
        title: l.upcomingTitle,
        trailing: SeeAll(
          _comingCount > _comingShown
              ? l.todoSeeAll('$_comingCount')
              : l.upcomingSeeAll,
        ),
        onTap: widget.onOpenMonth,
      ),
      for (final (i, day) in sorted.indexed) ...[
        if (i > 0) const SizedBox(height: GroupTitle.before),
        GroupTitle(title: dayLabel(context, day)),
        for (final (j, e) in days[day]!.indexed) ...[
          if (j > 0) const SizedBox(height: 8),
          if (e case (
            final TransactionInfo t,
            final OperationLabels labels,
            final Schedule schedule,
          ))
            OperationRow(
              t: t,
              labels: labels,
              title: (labels.categoryPath.split(' › ').last, null),
              subtitle: (rhythmOnly(l, lang, schedule), null),
              tag: l.plannedTag,
              onTap: () async {
                await openRuleCard(context, widget.data, t.id);
                await _changed();
              },
            )
          else if (e case final DebtLine d)
            DebtComingRow(
              debt: d,
              onTap: () async {
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => DebtScreen(
                      data: widget.data,
                      debts: widget.data.debts!,
                      id: d.id,
                    ),
                  ),
                );
                await _changed();
              },
            ),
        ],
      ],
    ];
  }

  static String _capitalized(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// « Disponible », the amount, « à dépenser librement »: mint, 22 round,
/// opening Comptes.
class _AvailableCard extends StatelessWidget {
  const _AvailableCard({
    required this.amount,
    required this.long,
    this.onTap,
    this.strip,
  });

  /// « Total … · dont projets … › » just under, close, in a paler mint.
  final Widget? strip;

  /// Whole or short.
  final String Function(bool short) amount;
  final bool long;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      hint: l.homeOpenAccounts,
      child: Column(
        children: [
          Material(
            color: KibuoColors.mint,
            borderRadius: strip == null
                ? BorderRadius.circular(KibuoTheme.radiusFeatured)
                : const BorderRadius.vertical(
                    top: Radius.circular(KibuoTheme.radiusFeatured),
                    bottom: Radius.circular(8),
                  ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.homeAvailable,
                            style: KibuoType.help.copyWith(
                              fontWeight: FontWeight.w500,
                              fontVariations: const [FontVariation.weight(500)],
                              color: KibuoColors.accentDeep,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FitAmount(
                            long: long,
                            style: KibuoType.bigAmount.copyWith(
                              height: 42 / 34,
                            ),
                            span: (short) => TextSpan(text: amount(short)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.homeAvailableHelp,
                            style: KibuoType.caption.copyWith(
                              color: KibuoColors.accentDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      KibuoIcons.caretRight,
                      size: 20,
                      color: KibuoColors.accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (strip case final strip?) ...[const SizedBox(height: 6), strip],
        ],
      ),
    );
  }
}

/// « Total 1 248,50 $ » and « dont projets 300,00 $ › » (canvas
/// Total_positif), or « + Créer un projet » without any.
class _ProjectsStrip extends StatelessWidget {
  const _ProjectsStrip({required this.total, required this.onTap, this.held});

  final String total;
  final String? held;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    const ink = KibuoColors.accentStripInk;
    TextSpan part(String label, String value) => TextSpan(
      children: [
        TextSpan(text: '$label '),
        TextSpan(
          text: value,
          style: const TextStyle(color: KibuoColors.ink).weight(700),
        ),
      ],
    );
    final held = this.held;
    return Material(
      color: KibuoColors.accentTintStrong,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(8),
        bottom: Radius.circular(KibuoTheme.radiusCard),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: KibuoTheme.heightTouch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    part(l.homeTotalLabel, total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KibuoType.body.copyWith(fontSize: 13, color: ink),
                  ),
                ),
                if (held != null)
                  Text.rich(
                    part(l.homeOfProjectsLabel, held),
                    style: KibuoType.body.copyWith(fontSize: 13, color: ink),
                  )
                else
                  Text(
                    '+ ${l.homeNewProject}',
                    style: KibuoType.body
                        .copyWith(fontSize: 13, color: KibuoColors.accent)
                        .weight(600),
                  ),
                const SizedBox(width: 2),
                const Icon(KibuoIcons.caretRight, size: 16, color: ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// « Novembre · ce mois-ci », what is left, the bar with today on it, and
/// « 49 % dépensés · −588,00 sur +1 200,00 ».
class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.name,
    required this.totals,
    required this.today,
    required this.money,
    required this.signed,
    this.onTap,
  });

  final String name;
  final FlowTotals totals;

  /// Today and the period it is in.
  final (DateTime, BudgetPeriod) today;
  final String Function(Money, bool short) money;
  final String Function(Money, bool short) signed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rest = totals.rest;
    final pre = totals.approximate ? '≈ ' : '';
    final exits = Money(-totals.exits.minor, totals.exits.currency);
    return MonthSummaryCard(
      month: name,
      detail: l.homeThisMonth,
      left: (short) =>
          pre +
          (rest.minor > 0 ? '+${money(rest, short)}' : money(rest, short)),
      leftWord: l.homeLeft,
      leftLong: isLong(rest),
      leftInAlert: rest.minor < 0,
      spent: SpentLevel(totals),
      today: today,
      line: (short) => _outOfIn(
        l,
        '$pre${signed(exits, short)}',
        '$pre${signed(totals.entries, short)}',
      ),
      lineLong: isLong(exits) || isLong(totals.entries),
      onTap: onTap,
    );
  }

  /// « −588,00 » in the debt colour, « sur », « +1 200,00 » in green.
  static TextSpan _outOfIn(AppLocalizations l, String out, String income) {
    const outMark = '\u0000';
    const inMark = '\u0001';
    final pattern = l.homeOutOfIn(outMark, inMark);
    final spans = <InlineSpan>[];
    var rest = pattern;
    while (rest.isNotEmpty) {
      final i = rest.indexOf(RegExp('[$outMark$inMark]'));
      if (i < 0) {
        spans.add(TextSpan(text: rest));
        break;
      }
      if (i > 0) spans.add(TextSpan(text: rest.substring(0, i)));
      final isOut = rest[i] == outMark;
      final text = isOut ? out : income;
      final zero = !text.contains(RegExp('[+−]'));
      spans.add(
        TextSpan(
          text: text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation.weight(700)],
            color: zero
                ? KibuoColors.inkMuted
                : isOut
                ? KibuoColors.debtInk
                : KibuoColors.accent,
          ),
        ),
      );
      rest = rest.substring(i + 1);
    }
    return TextSpan(children: spans);
  }
}
