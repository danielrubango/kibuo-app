import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  });

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

  /// How many recurrences are due in those 14 days.
  int _comingCount = 0;

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
    final month = [
      for (final t in ops)
        if (periodOf(now).contains(t.date.toLocal())) t,
    ];
    final rates = <String, ExchangeRate>{};
    final codes = {
      for (final a in accounts) a.balance.currency,
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
    final coming = <(TransactionInfo, OperationLabels, Schedule)>[];
    for (final p in next.take(_comingShown)) {
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
      _comingCount = next.length;
      _main = main;
      _available = totalIn(main, [
        for (final a in accounts) a.balance,
      ], (code) => rates[code]);
      _month = flowTotals(main, month.map(flowOf), (code) => rates[code]);
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
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
        if (_coming.isNotEmpty) ..._upcoming(l),
      ],
    );
  }

  /// « À venir » (canvas Aujourdhui): the recurrences of the next 14 days,
  /// as the list's planned operations, under their date (PRODUCT).
  List<Widget> _upcoming(AppLocalizations l) {
    final lang = Localizations.localeOf(context).languageCode;
    final days =
        <DateTime, List<(TransactionInfo, OperationLabels, Schedule)>>{};
    for (final e in _coming) {
      final d = e.$1.date.toLocal();
      (days[DateTime(d.year, d.month, d.day)] ??= []).add(e);
    }
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
      for (final (i, MapEntry(key: day, value: ops))
          in days.entries.indexed) ...[
        if (i > 0) const SizedBox(height: GroupTitle.before),
        GroupTitle(title: dayLabel(context, day)),
        for (final (j, (t, labels, schedule)) in ops.indexed) ...[
          if (j > 0) const SizedBox(height: 8),
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
  const _AvailableCard({required this.amount, required this.long, this.onTap});

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
      child: Material(
        color: KibuoColors.mint,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
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
                        style: KibuoType.bigAmount.copyWith(height: 42 / 34),
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
