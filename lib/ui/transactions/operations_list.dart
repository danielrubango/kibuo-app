import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/hint_store.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/search_history.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/choice_menu.dart';
import 'package:kibuo/ui/kit/day_header.dart';
import 'package:kibuo/ui/kit/empty_card.dart';
import 'package:kibuo/ui/kit/fading_row.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/month_picker.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/spent_bar.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/recurrences/list_display.dart';
import 'package:kibuo/ui/recurrences/planned_operation.dart';
import 'package:kibuo/ui/recurrences/recurrences_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/draft_screen.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operation_screens.dart';
import 'package:kibuo/ui/transactions/search_screen.dart';

/// What an operation brings in or takes out (PRODUCT): an expense with its
/// fees out, an income less its fees in, only a transfer's fees out.
MoneyFlow flowOf(TransactionInfo t) => switch (t.kind) {
  EntryKind.expense => MoneyFlow(outgoing: t.total.total),
  EntryKind.income => MoneyFlow(incoming: t.total.total),
  EntryKind.transfer => MoneyFlow(outgoing: t.total.fees),
};

/// The Opérations tab (canvas ListeOperations): a month, its entries and
/// exits, the Type, Compte and Catégorie filters, then the days, each
/// foldable with its own balance.
class OperationsScreen extends StatefulWidget {
  const OperationsScreen({
    super.key,
    required this.data,
    this.refresh,
    this.thisMonth,
    this.onAdd,
    this.hints,
    this.history,
  });

  final EntryData data;

  /// Bumped by the shell after a save, to reload.
  final Listenable? refresh;

  /// Bumped to bring the list back to this month.
  final Listenable? thisMonth;

  /// « Ajouter » from an empty month.
  final VoidCallback? onAdd;

  /// Where the month swipe is remembered as shown.
  final HintStore? hints;

  /// Where « Recherches récentes » are kept.
  final SearchHistory? history;

  /// « Voir dans Opérations » (a budget's detail) and the Aperçu's tiles:
  /// the month to show and the one category to filter on, if any. The
  /// shell brings the tab forward.
  static final show = ValueNotifier<({DateTime month, String? category})?>(
    null,
  );

  /// Forgets the month, filters and folded days kept while the app runs.
  @visibleForTesting
  static void forget() => _OperationsScreenState.forget();

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  // Kept while the app runs, not from one opening to the next (PRODUCT).
  static DateTime? _keptMonth;
  static final _types = <EntryKind>{};
  static final _accounts = <String>{};
  static final _categories = <String>{};
  static final _folded = <DateTime>{};

  static void forget() {
    _keptMonth = null;
    _types.clear();
    _accounts.clear();
    _categories.clear();
    _folded.clear();
  }

  late DateTime _month = _keptMonth ?? _thisMonth();
  List<(TransactionInfo, OperationLabels)> _all = const [];

  /// The current month's planned operations, from tomorrow on (PRODUCT).
  List<(TransactionInfo, OperationLabels)> _planned = const [];

  /// « Groupés en haut »: drafts late or due today above the days.
  bool _onTop = false;
  List<AccountRowInfo> _accountChoices = const [];
  List<CategoryInfo> _categoryChoices = const [];
  CurrencyInfo? _main;
  Map<String, ExchangeRate> _rates = const {};
  bool _picker = false;
  bool _tip = false;

  /// The filter whose menu is open, and where its chip is.
  _Filter? _menu;
  Rect _menuAt = Rect.zero;
  final _stackKey = GlobalKey();
  final _layer = OverlayPortalController();
  static const _menuWidth = 210.0;
  final _chipKeys = {for (final f in _Filter.values) f: GlobalKey()};
  final _chipLinks = {for (final f in _Filter.values) f: LayerLink()};

  /// The current period's name (« Début du mois » may push it ahead).
  static DateTime _thisMonth() => periodOf(DateTime.now()).month;

  bool get _isThisMonth => _month == _thisMonth();

  /// Asked from elsewhere: [OperationsScreen.show]'s month, filtered on
  /// its category alone.
  void _shown() {
    final asked = OperationsScreen.show.value;
    if (asked == null) return;
    setState(() {
      _types.clear();
      _accounts.clear();
      _categories.clear();
      if (asked.category case final category?) _categories.add(category);
    });
    _goTo(asked.month);
  }

  /// « Début du mois » changed: the periods move, back to the current one.
  void _startChanged() {
    setState(() {
      _month = _thisMonth();
      _keptMonth = _month;
    });
    if (_pages.hasClients) _pages.jumpToPage(0);
  }

  void _backToThisMonth() {
    if (!_isThisMonth) _goTo(_thisMonth());
  }

  bool get _filtered =>
      _types.isNotEmpty || _accounts.isNotEmpty || _categories.isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.refresh?.addListener(_load);
    widget.thisMonth?.addListener(_backToThisMonth);
    monthStartChoice.addListener(_startChanged);
    OperationsScreen.show.addListener(_shown);
    // Always on; it draws nothing while no layer is open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _layer.show();
    });
    _load();
    _maybeTip();
  }

  @override
  void dispose() {
    _pages.dispose();
    widget.refresh?.removeListener(_load);
    widget.thisMonth?.removeListener(_backToThisMonth);
    monthStartChoice.removeListener(_startChanged);
    OperationsScreen.show.removeListener(_shown);
    super.dispose();
  }

  Future<void> _maybeTip() async {
    final hints = widget.hints;
    if (hints == null || await hints.swipeShown()) return;
    if (mounted) setState(() => _tip = true);
  }

  Future<void> _tipDone() async {
    setState(() => _tip = false);
    await widget.hints?.swipeDone();
  }

  bool _debtsCount = true;

  Future<void> _load() async {
    final data = widget.data;
    _debtsCount = await data.debts?.countInTotals() ?? true;
    // Drafts and ignored ones show in the list; only done ones count.
    final all = await data.transactions.all(drafts: true);
    final recurrences = data.recurrences;
    final onTop = await recurrences?.draftsOnTop() ?? false;
    final planned = recurrences == null || !await recurrences.showPlanned()
        ? const <Planned>[]
        : await recurrences.planned(
            now: DateTime.now(),
            until: periodNamed(_thisMonth()).last,
          );
    final accounts = [
      ...await data.accounts.accounts(),
      ...await data.accounts.accounts(archived: true),
    ];
    final categories = [
      ...await data.categories.categories(CategoryKind.out),
      ...await data.categories.categories(CategoryKind.into),
    ];
    final code =
        await data.currencies.primaryCurrency() ??
        (accounts.isEmpty ? 'USD' : accounts.first.currency);
    final main = await data.currencies.currency(code);
    final rates = <String, ExchangeRate>{};
    for (final c in {for (final a in accounts) a.currency}) {
      if (c == code) continue;
      final info = await data.currencies.latestRate(code, c);
      if (info != null) rates[c] = info.rate;
    }
    if (!mounted) return;
    final list = <(TransactionInfo, OperationLabels)>[];
    for (final t in all) {
      if (!mounted) return;
      list.add((t, await OperationLabels.of(context, data, t)));
    }
    final coming = <(TransactionInfo, OperationLabels)>[];
    for (final p in planned) {
      if (!mounted) return;
      final t = plannedOperation(p);
      coming.add((t, await OperationLabels.of(context, data, t)));
    }
    if (!mounted) return;
    setState(() {
      _all = list;
      _planned = coming;
      _onTop = onTop;
      _accountChoices = [
        for (final a in accounts) AccountRowInfo(a.id, a.name),
      ];
      _categoryChoices = categories;
      _main = main;
      _rates = rates;
    });
  }

  /// Months are pages: 0 is this month, 1 the month before, and so on.
  static int _indexOf(DateTime month) {
    final now = _thisMonth();
    return (now.year - month.year) * 12 + now.month - month.month;
  }

  static DateTime _monthAt(int index) {
    final now = _thisMonth();
    return DateTime(now.year, now.month - index);
  }

  late final _pages = PageController(initialPage: _indexOf(_month));

  /// Goes to [month]: a slide when it is next door, a jump from the
  /// picker.
  void _goTo(DateTime month) {
    if (month.isAfter(_thisMonth())) return;
    setState(() => _picker = false);
    final index = _indexOf(month);
    if (!_pages.hasClients) return _showMonth(index);
    final far = (index - (_pages.page ?? index.toDouble())).abs() > 1.5;
    if (far) {
      _pages.jumpToPage(index);
    } else {
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showMonth(int index) => setState(() {
    _month = _monthAt(index);
    _keptMonth = _month;
    _menu = null;
    _picker = false;
  });

  bool _inMonth(TransactionInfo t, [DateTime? month]) =>
      periodNamed(month ?? _month).contains(t.date.toLocal());

  /// A top-level category's id, for a category or one of its subcategories.
  String? _topCategory(String? id) {
    if (id == null) return null;
    for (final c in _categoryChoices) {
      if (c.id == id || c.subs.any((s) => s.id == id)) return c.id;
    }
    return id;
  }

  bool _passes(
    TransactionInfo t, {
    bool type = true,
    bool account = true,
    bool category = true,
  }) {
    if (type && _types.isNotEmpty && !_types.contains(t.kind)) return false;
    if (account &&
        _accounts.isNotEmpty &&
        !_accounts.contains(t.accountId) &&
        !_accounts.contains(t.toAccountId)) {
      return false;
    }
    if (category &&
        _categories.isNotEmpty &&
        !_categories.contains(_topCategory(t.categoryId))) {
      return false;
    }
    return true;
  }

  /// Drafts, ignored and planned operations count in no total; debts'
  /// operations only if the user wants (PRODUCT).
  FlowTotals _totals(Iterable<TransactionInfo> ops) => flowTotals(
    _main!,
    ops.where((t) => t.counts && (_debtsCount || t.debtId == null)).map(flowOf),
    (code) => _rates[code],
  );

  String _money(Money m, {bool short = false}) =>
      formatAmount(m, currencyOf(m.currency), _lang, short: short);

  String get _lang => Localizations.localeOf(context).languageCode;

  Future<void> _open(TransactionInfo t) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OperationDetailScreen(data: widget.data, id: t.id),
      ),
    );
    await _load();
  }

  Future<void> _openSearch(DateTime month) async {
    setState(() {
      _menu = null;
      _picker = false;
    });
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          data: widget.data,
          month: month,
          history: widget.history,
        ),
      ),
    );
    await _load();
  }

  String _dayLabel(DateTime day) => dayLabel(context, day);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // The veil, the month picker, a filter's menu and the first-visit tip
    // cover the whole phone, tab bar included (canvas ListeOperations).
    return OverlayPortal(
      controller: _layer,
      overlayChildBuilder: (context) => _layers(context, l),
      child: Stack(
        key: _stackKey,
        children: [
          // Each month is a page that follows the finger: right for the
          // month before, left for the month after, never past this month
          // (canvas ListeOnboard).
          PageView.builder(
            controller: _pages,
            reverse: true,
            onPageChanged: _showMonth,
            itemBuilder: (context, index) =>
                _page(l, _monthAt(index), current: _monthAt(index) == _month),
          ),
        ],
      ),
    );
  }

  /// One month: its title, totals, filters and days.
  Widget _page(AppLocalizations l, DateTime month, {required bool current}) {
    final main = _main;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime dayOf(TransactionInfo t) {
      final d = t.date.toLocal();
      return DateTime(d.year, d.month, d.day);
    }

    // « Groupés en haut »: drafts late or due today, above the days.
    final waiting = <(TransactionInfo, OperationLabels)>[];
    final shown = <(TransactionInfo, OperationLabels)>[
      // Planned ones only in the current month (PRODUCT).
      if (month == _thisMonth())
        for (final e in _planned)
          if (_passes(e.$1)) e,
    ];
    for (final e in _all) {
      if (!_inMonth(e.$1, month) || !_passes(e.$1)) continue;
      final late = e.$1.isDraft && !dayOf(e.$1).isAfter(today);
      (_onTop && late ? waiting : shown).add(e);
    }
    shown.sort((a, b) => b.$1.date.compareTo(a.$1.date));
    // Days, newest first, each with its operations.
    final days = <DateTime, List<(TransactionInfo, OperationLabels)>>{};
    for (final e in shown) {
      (days[dayOf(e.$1)] ??= []).add(e);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, KibuoTheme.belowTabBar),
      children: [
        _header(l, month),
        const SizedBox(height: 16),
        if (main != null)
          _TotalsCard(
            // The whole month: the filters choose what the list shows, not
            // what the month did (PRODUCT).
            totals: _totals([
              for (final e in _all)
                if (_inMonth(e.$1, month)) e.$1,
            ]),
            money: _money,
            today: month == _thisMonth()
                ? (DateTime.now(), periodNamed(month))
                : null,
          ),
        const SizedBox(height: 12),
        _filters(l, current: current),
        if (waiting.isNotEmpty) ...[
          const SizedBox(height: GroupTitle.before),
          GroupTitle(
            title: l.draftsToValidate('${waiting.length}'),
            trailing: GroupNote(l.draftsLateAndToday),
          ),
          ..._rows(l, waiting),
        ],
        if (days.isEmpty && waiting.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _empty(l, month),
          )
        else
          for (final MapEntry(key: day, value: ops) in days.entries)
            ..._day(day, ops),
      ],
    );
  }

  Widget _layers(BuildContext context, AppLocalizations l) {
    // Only while this tab is the one shown.
    final shown = TickerMode.valuesOf(context).enabled;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (!shown || stack == null || !stack.hasSize) {
      return const SizedBox.shrink();
    }
    if (!_picker && _menu == null && !_tip) return const SizedBox.shrink();
    final origin = stack.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(context);
    final bottomBar = MediaQuery.viewPaddingOf(context).bottom + 104;
    return Stack(
      children: [
        // A light veil under an open month picker or filter menu; a tap
        // on it closes them.
        if (_picker || _menu != null)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() {
                _picker = false;
                _menu = null;
              }),
              child: const ColoredBox(color: KibuoColors.veil),
            ),
          ),
        if (_picker)
          Positioned(
            left: origin.dx + 12,
            top: origin.dy + 64,
            width: 308,
            child: MonthPicker(
              month: _month,
              onPick: _goTo,
              onThisMonth: _isThisMonth ? null : () => _goTo(_thisMonth()),
            ),
          ),
        if (_menu case final menu?) ...[
          // Both follow the chip at every frame: the chips move when the
          // totals card grows or shrinks (its bar comes and goes with the
          // filters), and the menu must stay under its chip.
          Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: _chipLinks[menu]!,
              showWhenUnlinked: false,
              // The open chip stays above the veil (DIRECTION).
              child: _chipFor(l, menu, open: true),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: _chipLinks[menu]!,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomLeft,
              // Kept 16 from the screen's edges.
              offset: Offset(
                _menuAt.left
                        .clamp(16.0, screen.width - 16 - _menuWidth)
                        .toDouble() -
                    _menuAt.left,
                6,
              ),
              child: ChoiceMenu(
                width: _menuWidth,
                // Never under the tab bar; a little room for the bar of
                // the totals coming back.
                maxHeight: (screen.height - _menuAt.bottom - 6 - bottomBar - 24)
                    .clamp(140.0, double.infinity),
                children: _menuRows(l, menu),
              ),
            ),
          ),
        ],
        if (_tip)
          Positioned.fill(
            child: _SwipeTip(onDone: _tipDone, month: _thisMonth()),
          ),
      ],
    );
  }

  Widget _header(AppLocalizations l, DateTime month) {
    // Canvas ListeOperations: the short month (« Sept. ») when the full one
    // would not fit on one line.
    String cap(String t) => t[0].toUpperCase() + t.substring(1);
    final full = cap(DateFormat.MMMM(_lang).format(month));
    final short = cap(DateFormat.MMM(_lang).format(month));
    final room =
        MediaQuery.sizeOf(context).width -
        32 -
        8 -
        KibuoTheme.heightTouch -
        (month != _thisMonth() ? 110 : 0);
    final fits =
        (TextPainter(
              text: TextSpan(
                text: '$full ${month.year} ',
                style: KibuoType.tabTitle,
              ),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 1,
            )..layout()).width +
            24 <=
        room;
    final name = fits ? full : short;
    // « du 25 oct. au 24 nov. » when the month does not start on the 1st.
    final period = periodNamed(month);
    final range = monthStartChoice.value == 1
        ? null
        : l.listPeriod(
            DateFormat.MMMd(_lang).format(period.first),
            DateFormat.MMMd(_lang).format(period.last),
          );
    // A fixed height: « Ce mois-ci » coming and going must not move the list.
    return SizedBox(
      height: KibuoTheme.heightTouch + (range == null ? 0 : 18),
      child: TabHeader(
        subtitle: range,
        onTitleTap: () => setState(() => _picker = !_picker),
        title: Text.rich(
          maxLines: 1,
          softWrap: false,
          TextSpan(
            children: [
              TextSpan(text: name),
              TextSpan(
                text: ' ${month.year} ',
                style: const TextStyle(
                  color: KibuoColors.inkSecondary,
                  fontWeight: FontWeight.w500,
                  fontVariations: [FontVariation.weight(500)],
                ),
              ),
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  KibuoIcons.caretDown,
                  size: 18,
                  color: KibuoColors.accent,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (month != _thisMonth())
            TextAction(
              label: l.listThisMonth,
              onPressed: () => _goTo(_thisMonth()),
            ),
          // Canvas BrouillonA3: « Affichage de la liste », then the
          // magnifier at the right edge.
          Transform.translate(
            offset: const Offset(10, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.data.recurrences case final recurrences?)
                  SizedBox.square(
                    dimension: KibuoTheme.heightTouch,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: l.listDisplay,
                      onPressed: () async {
                        await showListDisplaySheet(
                          context,
                          recurrences,
                          debts: widget.data.debts,
                        );
                        await _load();
                      },
                      icon: const Icon(
                        KibuoIcons.slidersHorizontal,
                        color: KibuoColors.accent,
                      ),
                    ),
                  ),
                SizedBox.square(
                  dimension: KibuoTheme.heightTouch,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: l.listSearch,
                    onPressed: () => _openSearch(month),
                    icon: const Icon(
                      KibuoIcons.magnifyingGlass,
                      color: KibuoColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// What each filter offers, with how many operations of the month each
  /// choice keeps; a filter's numbers follow the two other filters.
  ({
    List<(EntryKind, String, int)> types,
    List<(String, String, int)> accounts,
    List<(String, String, int)> expenses,
    List<(String, String, int)> incomes,
    int allTypes,
    int allAccounts,
    int allCategories,
  })
  _choices(AppLocalizations l) {
    final inMonth = [
      for (final e in _all)
        if (_inMonth(e.$1)) e.$1,
    ];
    int count(bool Function(TransactionInfo) keep) =>
        inMonth.where(keep).length;
    List<(String, String, int)> cats(CategoryKind kind) => [
      for (final c in _categoryChoices)
        if (c.kind == kind)
          (
            c.id,
            categoryName(l, c),
            count(
              (t) =>
                  _topCategory(t.categoryId) == c.id &&
                  _passes(t, category: false),
            ),
          ),
    ];
    return (
      types: [
        for (final k in EntryKind.values)
          (
            k,
            _typeName(l, k),
            count((t) => t.kind == k && _passes(t, type: false)),
          ),
      ],
      accounts: [
        for (final a in _accountChoices)
          (
            a.id,
            a.name,
            count(
              (t) =>
                  (t.accountId == a.id || t.toAccountId == a.id) &&
                  _passes(t, account: false),
            ),
          ),
      ],
      expenses: cats(CategoryKind.out),
      incomes: cats(CategoryKind.into),
      allTypes: count((t) => _passes(t, type: false)),
      allAccounts: count((t) => _passes(t, account: false)),
      allCategories: count((t) => _passes(t, category: false)),
    );
  }

  String _typeName(AppLocalizations l, EntryKind k) => switch (k) {
    EntryKind.expense => l.filterExpenses,
    EntryKind.income => l.filterIncomes,
    EntryKind.transfer => l.filterTransfers,
  };

  /// The chips; only the shown month's carry what the open menu follows
  /// (a neighbour month is drawn too while the finger slides).
  Widget _filters(AppLocalizations l, {required bool current}) {
    return FadingRow(
      children: [
        for (final f in _Filter.values) _chipFor(l, f, inRow: current),
      ],
    );
  }

  Widget _chipFor(
    AppLocalizations l,
    _Filter f, {
    bool open = false,
    bool inRow = false,
  }) {
    String label(
      String base,
      Set<Object> chosen,
      String Function(int) many,
      String Function(Object) one,
    ) => chosen.isEmpty
        ? base
        : chosen.length == 1
        ? one(chosen.first)
        : many(chosen.length);
    String name(Iterable<(Object, String, int)> list, Object id) {
      for (final (value, text, _) in list) {
        if (value == id) return text;
      }
      return '';
    }

    final c = _choices(l);
    final (text, active) = switch (f) {
      _Filter.type => (
        label(l.filterType, _types, l.filterTypes, (k) => name(c.types, k)),
        _types.isNotEmpty,
      ),
      _Filter.account => (
        label(
          l.filterAccount,
          _accounts,
          l.filterAccounts,
          (id) => name(c.accounts, id),
        ),
        _accounts.isNotEmpty,
      ),
      _Filter.category => (
        label(
          l.filterCategory,
          _categories,
          l.filterCategories,
          (id) => name([...c.expenses, ...c.incomes], id),
        ),
        _categories.isNotEmpty,
      ),
    };
    final chip = FilterChipButton(
      key: inRow ? _chipKeys[f] : null,
      label: text,
      active: active,
      open: open,
      onTap: () => open ? setState(() => _menu = null) : _openMenu(f),
    );
    // The chip in the row is what the open menu follows.
    return inRow
        ? CompositedTransformTarget(link: _chipLinks[f]!, child: chip)
        : chip;
  }

  void _openMenu(_Filter f) {
    final chip = _chipKeys[f]!.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (chip == null || stack == null) return;
    final topLeft = chip.localToGlobal(Offset.zero);
    setState(() {
      _menu = _menu == f ? null : f;
      _menuAt = topLeft & chip.size;
      _picker = false;
    });
  }

  void _toggle<T>(Set<T> chosen, T value) => setState(
    () => chosen.contains(value) ? chosen.remove(value) : chosen.add(value),
  );

  /// The open filter's choices (canvas ListeFiltreOuvert): « Tous » with a
  /// line under it, then each choice. Catégorie shows only the categories
  /// of the month (and those chosen), most used first, by Dépenses and
  /// Revenus; the others wait behind « Afficher les N autres » (PRODUCT).
  List<Widget> _menuRows(AppLocalizations l, _Filter f) {
    final c = _choices(l);
    switch (f) {
      case _Filter.type:
        return [
          ChoiceRow(
            label: l.filterAllType,
            count: c.allTypes,
            selected: _types.isEmpty,
            // « Tous » closes the menu: nothing more to choose.
            onTap: () => setState(() {
              _types.clear();
              _menu = null;
            }),
          ),
          for (final (i, (k, name, n)) in c.types.indexed)
            ChoiceRow(
              label: name,
              count: n,
              selected: _types.contains(k),
              divided: i == 0,
              onTap: () => _toggle(_types, k),
            ),
        ];
      case _Filter.account:
        return [
          ChoiceRow(
            label: l.filterAll,
            count: c.allAccounts,
            selected: _accounts.isEmpty,
            // « Tous » closes the menu: nothing more to choose.
            onTap: () => setState(() {
              _accounts.clear();
              _menu = null;
            }),
          ),
          for (final (i, (id, name, n)) in c.accounts.indexed)
            ChoiceRow(
              label: name,
              count: n,
              selected: _accounts.contains(id),
              divided: i == 0,
              onTap: () => _toggle(_accounts, id),
            ),
        ];
      case _Filter.category:
        List<(String, String, int)> shown(List<(String, String, int)> all) => [
          for (final o in all)
            if (o.$3 > 0 || _categories.contains(o.$1)) o,
        ]..sort((a, b) => b.$3.compareTo(a.$3));
        final expenses = shown(c.expenses);
        final incomes = shown(c.incomes);
        final hidden =
            c.expenses.length +
            c.incomes.length -
            expenses.length -
            incomes.length;
        return [
          ChoiceRow(
            label: l.filterAllCategories,
            count: c.allCategories,
            selected: _categories.isEmpty,
            // « Tous » closes the menu: nothing more to choose.
            onTap: () => setState(() {
              _categories.clear();
              _menu = null;
            }),
          ),
          ..._categoryGroups(l, expenses, incomes),
          if (hidden > 0)
            ChoiceMoreRow(
              label: l.filterMore(hidden),
              onTap: () => _allCategories(l),
            ),
        ];
    }
  }

  List<Widget> _categoryGroups(
    AppLocalizations l,
    List<(String, String, int)> expenses,
    List<(String, String, int)> incomes,
  ) => [
    for (final (i, (title, group)) in [
      if (expenses.isNotEmpty) (l.categoriesExpenses, expenses),
      if (incomes.isNotEmpty) (l.categoriesIncome, incomes),
    ].indexed) ...[
      ChoiceGroupTitle(title, divided: i == 0),
      for (final (id, name, n) in group)
        ChoiceRow(
          label: name,
          count: n,
          selected: _categories.contains(id),
          onTap: () => _toggle(_categories, id),
        ),
    ],
  ];

  /// Every category, in a sheet two thirds of the screen high that scrolls;
  /// choices apply at once, ✕ or a tap outside closes it.
  Future<void> _allCategories(AppLocalizations l) async {
    setState(() => _menu = null);
    await showKibuoSheet<void>(
      context,
      title: l.filterCategory,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) {
          final c = _choices(l);
          void again(VoidCallback change) {
            setState(change);
            refresh(() {});
          }

          // In a white card, as the other lists of a sheet; two thirds of
          // the screen at most, the rest scrolls.
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 2 / 3 - 120,
            ),
            decoration: BoxDecoration(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(6),
              children: [
                ChoiceRow(
                  label: l.filterAllCategories,
                  count: c.allCategories,
                  selected: _categories.isEmpty,
                  // « Toutes » closes the sheet, as « Tous » the menu.
                  onTap: () {
                    setState(_categories.clear);
                    Navigator.of(context).pop();
                  },
                ),
                for (final (i, (title, group)) in [
                  (l.categoriesExpenses, c.expenses),
                  (l.categoriesIncome, c.incomes),
                ].indexed) ...[
                  ChoiceGroupTitle(title, divided: i == 0),
                  for (final (id, name, n) in group)
                    ChoiceRow(
                      label: name,
                      count: n,
                      selected: _categories.contains(id),
                      onTap: () => again(
                        () => _categories.contains(id)
                            ? _categories.remove(id)
                            : _categories.add(id),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _day(
    DateTime day,
    List<(TransactionInfo, OperationLabels)> ops,
  ) {
    final folded = _folded.contains(day);
    final t = _totals([for (final e in ops) e.$1]);
    final onlyFreeTransfers = t.entries.minor == 0 && t.exits.minor == 0;
    return [
      const SizedBox(height: GroupTitle.before),
      DayHeader(
        label: _dayLabel(day),
        count: ops.length,
        folded: folded,
        net: onlyFreeTransfers ? null : t.rest,
        approximate: t.approximate,
        onTap: () =>
            setState(() => folded ? _folded.remove(day) : _folded.add(day)),
      ),
      if (!folded) ..._rows(AppLocalizations.of(context), ops),
    ];
  }

  /// A group's operations, 8 apart (DIRECTION: Groupes).
  List<Widget> _rows(
    AppLocalizations l,
    List<(TransactionInfo, OperationLabels)> ops,
  ) => [
    for (final (i, (t, labels)) in ops.indexed) ...[
      if (i > 0) const SizedBox(height: 8),
      _row(l, t, labels),
    ],
  ];

  /// One operation: a draft's card, an ignored or planned row, or a row.
  Widget _row(AppLocalizations l, TransactionInfo t, OperationLabels labels) {
    final title = (labels.categoryPath.split(' › ').last, null);
    final Widget child;
    if (t.isDraft) {
      child = DraftCard(
        t: t,
        labels: labels,
        title: title,
        subtitle: (l.draftFromRecurrence(labels.account), null),
        onTap: () => _openDraft(t),
        onIgnore: () => _ignore(t, labels),
        onValidate: () => _validate(t, labels),
      );
    } else if (t.isIgnored || t.isPlanned) {
      child = OperationRow(
        t: t,
        labels: labels,
        title: title,
        subtitle: (labels.account, null),
        tag: t.isIgnored ? l.recurrenceIgnored : l.plannedTag,
        onTap: () => t.isPlanned ? _openRecurrence(t) : _openDraft(t),
      );
    } else {
      child = OperationRow(
        t: t,
        labels: labels,
        title: title,
        subtitle: (
          '${labels.account} · '
              '${DateFormat.Hm(_lang).format(t.date.toLocal())}',
          null,
        ),
        onTap: () => _open(t),
      );
    }
    return child;
  }

  Future<void> _validate(TransactionInfo t, OperationLabels labels) async {
    await validateFromList(context, widget.data, t, labels);
    await _load();
  }

  Future<void> _ignore(TransactionInfo t, OperationLabels labels) async {
    await ignoreFromList(context, widget.data, t, labels);
    await _load();
  }

  Future<void> _openDraft(TransactionInfo t) async {
    await openDraft(context, widget.data, t);
    await _load();
  }

  Future<void> _openRecurrence(TransactionInfo t) async {
    await openRuleCard(context, widget.data, t.id);
    await _load();
  }

  Widget _empty(AppLocalizations l, DateTime month) {
    final monthName = DateFormat.yMMMM(_lang).format(month);
    final (title, help, action, onAction) = _filtered
        ? (
            l.emptyFilterTitle,
            l.emptyFilterHelp,
            l.clearFilters,
            () => setState(() {
              _types.clear();
              _accounts.clear();
              _categories.clear();
            }),
          )
        : month != _thisMonth()
        ? (
            l.emptyMonthTitle,
            l.emptyMonthHelp(monthName),
            l.backToThisMonth,
            () => _goTo(_thisMonth()),
          )
        : (
            l.emptyMonthTitle,
            l.emptyMonthHelp(monthName),
            l.entryNewExpense,
            widget.onAdd,
          );
    return EmptyCard(
      icon: KibuoIcons.list,
      title: title,
      help: help,
      action: action,
      onAction: onAction,
    );
  }
}

enum _Filter { type, account, category }

/// An account's id and name, for the Compte filter.
class AccountRowInfo {
  const AccountRowInfo(this.id, this.name);

  final String id;
  final String name;
}

/// Entries, exits, « 49 % dépensés » and what is left (canvas
/// ListeOperations, EtatBarre).
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals, required this.money, this.today});

  final FlowTotals totals;

  /// Today and its period, when the card is the current period's: the
  /// mark on the bar.
  final (DateTime, BudgetPeriod)? today;
  final String Function(Money, {bool short}) money;

  /// « +25,00 $ », « −106,00 $ », or « 0,00 $ » in grey; [short] writes
  /// « +1,2 M $ ».
  (String Function(bool short), Color) _signed(
    Money m, {
    required bool out,
    String pre = '',
  }) {
    if (m.minor == 0) {
      return ((short) => money(m, short: short), KibuoColors.inkMuted);
    }
    final abs = Money(m.minor.abs(), m.currency);
    return out || m.minor < 0
        ? ((short) => '$pre−${money(abs, short: short)}', KibuoColors.debtInk)
        : ((short) => '$pre+${money(abs, short: short)}', KibuoColors.accent);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pre = totals.approximate ? '≈ ' : '';
    // The bar is always there (PRODUCT): empty and grey with nothing in or
    // out, full and peach with exits but no entry, as when over 100 %.
    final spent = SpentLevel(totals);
    final (inText, inColor) = _signed(totals.entries, out: false, pre: pre);
    final (outText, outColor) = _signed(totals.exits, out: true, pre: pre);
    final (restText, restColor) = _signed(totals.rest, out: false);
    Widget amount(
      String label,
      String Function(bool short) text,
      Color color,
      Money m, {
      bool end = false,
    }) => Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(label, style: KibuoType.help),
        const SizedBox(height: 2),
        FitAmount(
          long: isLong(m),
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          style: KibuoType.sheetTitle.copyWith(color: color),
          span: (short) => TextSpan(text: text(short)),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: amount(l.listEntries, inText, inColor, totals.entries),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: amount(
                  l.listExits,
                  outText,
                  outColor,
                  totals.exits,
                  end: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SpentBar(spent: spent, today: today),
          const SizedBox(height: 8),
          Row(
            children: [
              SpentShare(spent: spent),
              const SizedBox(width: 10),
              Expanded(
                child: FitAmount(
                  long: isLong(totals.rest),
                  alignment: Alignment.centerRight,
                  style: KibuoType.caption,
                  span: (short) => TextSpan(
                    text: '${l.listRest} ',
                    children: [
                      TextSpan(
                        text: restText(short),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation.weight(700)],
                          color: restColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwipeTip extends StatefulWidget {
  const _SwipeTip({required this.onDone, required this.month});

  final VoidCallback onDone;
  final DateTime month;

  @override
  State<_SwipeTip> createState() => _SwipeTipState();
}

class _SwipeTipState extends State<_SwipeTip>
    with SingleTickerProviderStateMixin {
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Still, for those who asked the phone for less motion.
      if (MediaQuery.disableAnimationsOf(context)) return;
      _loop.repeat();
    });
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDone,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: const ColoredBox(color: KibuoColors.tipScrim),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + 112,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x590E1320),
                  blurRadius: 50,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SlidingMonths(loop: _loop, month: widget.month),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.swipeTipTitle, style: KibuoType.cardTitle),
                      const SizedBox(height: 4),
                      Text(
                        l.swipeTipText,
                        style: KibuoType.body.copyWith(
                          color: KibuoColors.inkSecondary,
                          height: 20 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                KibuoButton(label: l.plusHoldTipDone, onPressed: widget.onDone),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Two small months side by side, sliding to the month before and back,
/// a green touch going with them (canvas ListeOnboard, 3.2 s).
class _SlidingMonths extends StatelessWidget {
  const _SlidingMonths({required this.loop, required this.month});

  final Animation<double> loop;
  final DateTime month;

  /// Where the pages are (0: this month, 1: the month before), over the loop.
  static double _pages(double t) {
    double ease(double x) => Curves.easeInOut.transform(x.clamp(0, 1));
    if (t < .10) return 0;
    if (t < .36) return ease((t - .10) / .26);
    if (t < .54) return 1;
    if (t < .80) return 1 - ease((t - .54) / .26);
    return 0;
  }

  /// The touch: its place (-1 left, 1 right) and how visible it is.
  static (double, double) _touch(double t) {
    double lerp(double a, double b, double x) => a + (b - a) * x.clamp(0, 1);
    if (t < .04) return (-1, 0);
    if (t < .10) return (-1, lerp(0, 1, (t - .04) / .06));
    if (t < .36) return (lerp(-1, 1, (t - .10) / .26), 1);
    if (t < .42) return (1, lerp(1, 0, (t - .36) / .06));
    if (t < .48) return (1, 0);
    if (t < .54) return (1, lerp(0, 1, (t - .48) / .06));
    if (t < .80) return (lerp(1, -1, (t - .54) / .26), 1);
    if (t < .86) return (-1, lerp(1, 0, (t - .80) / .06));
    return (-1, 0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    String n(String key) => l.categoryName(key);
    final bank = l.accountTypeBank;
    final cash = l.accountTypeCash;
    // Signed, in dollars: the picture of a month, not real operations.
    (String, bool) m(int minor) {
      final text = formatMoney(
        Money(minor.abs(), 'USD'),
        currencyOf('USD'),
        lang,
      );
      return (minor < 0 ? '−$text' : '+$text', minor > 0);
    }

    String title(DateTime m) {
      final t = DateFormat.yMMMM(lang).format(m);
      return t[0].toUpperCase() + t.substring(1);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 190,
        color: KibuoColors.background,
        child: LayoutBuilder(
          builder: (context, box) => AnimatedBuilder(
            animation: loop,
            builder: (context, _) {
              final w = box.maxWidth;
              final shift = _pages(loop.value) * w;
              final (x, seen) = _touch(loop.value);
              return Stack(
                children: [
                  Positioned(
                    left: shift - w,
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: _MiniMonth(
                      title: title(DateTime(month.year, month.month - 1)),
                      lines: [
                        (n('rent'), '${n('housing')} · $bank', m(-25000)),
                        (n('salary'), bank, m(120000)),
                        (n('groceries'), '${n('groceries')} · $cash', m(-3800)),
                      ],
                    ),
                  ),
                  Positioned(
                    left: shift,
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: _MiniMonth(
                      title: title(month),
                      lines: [
                        (n('restaurant'), '${n('food')} · $cash', m(-650)),
                        (n('taxi'), '${n('transport')} · $cash', m(-500)),
                        (n('salary'), bank, m(120000)),
                      ],
                    ),
                  ),
                  Positioned(
                    left: w / 2 - 16 + x * 60,
                    top: 92,
                    child: Opacity(
                      opacity: seen,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: KibuoColors.accent.withValues(alpha: .85),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: KibuoColors.accent.withValues(alpha: .18),
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({required this.title, required this.lines});

  final String title;
  final List<(String, String, (String, bool))> lines;

  @override
  Widget build(BuildContext context) {
    // A picture: what does not fit (large text) is cut at the bottom.
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: double.infinity,
        child: _content(),
      ),
    );
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KibuoType.cardTitle.copyWith(fontSize: 15)),
          for (final (name, sub, (amount, income)) in lines) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: KibuoType.caption.copyWith(
                            color: KibuoColors.ink,
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation.weight(600)],
                          ),
                        ),
                        Text(
                          sub,
                          style: KibuoType.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amount,
                    style: KibuoType.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation.weight(700)],
                      color: income ? KibuoColors.accent : KibuoColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
