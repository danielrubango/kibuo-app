import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/budgets/budget_detail_screen.dart';
import 'package:kibuo/ui/budgets/budget_form_screen.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/empty_card.dart';
import 'package:kibuo/ui/kit/month_picker.dart';
import 'package:kibuo/ui/kit/month_summary_card.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/spent_bar.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

enum _Layout { tiles, list }

enum _Order { watch, mine }

/// The Budgets page (canvas Budgets, BudgetsListe, BudgetsAffichage): the
/// month's summary, then the budgets in tiles or in a list grouped by
/// state, and « Ajouter un budget ».
class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, required this.loader, required this.prefs});

  final BudgetLoader loader;
  final PreferenceStore prefs;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  static const _layoutKey = 'budgets_layout';
  static const _orderKey = 'budgets_order';

  DateTime _month = periodOf(DateTime.now()).month;
  BudgetBook? _book;
  _Layout _layout = _Layout.tiles;
  _Order _order = _Order.watch;
  bool _picker = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final layout = await widget.prefs.read(_layoutKey);
    final order = await widget.prefs.read(_orderKey);
    final book = await widget.loader.load(_month);
    if (!mounted) return;
    setState(() {
      _book = book;
      _layout = layout == 'list' ? _Layout.list : _Layout.tiles;
      _order = order == 'mine' ? _Order.mine : _Order.watch;
    });
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  String _money(Money m, {bool short = false}) =>
      formatAmount(m, _book!.main, _lang, short: short);

  bool get _current => _month == periodOf(DateTime.now()).month;

  List<BudgetLine> _sorted(AppLocalizations l) {
    final lines = [..._book!.lines];
    if (_order == _Order.watch) {
      lines.sort(
        (a, b) => watchOrder(
          a.status,
          categoryName(l, a.category),
          b.status,
          categoryName(l, b.category),
        ),
      );
    }
    return lines;
  }

  Future<void> _open([BudgetLine? line]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            BudgetFormScreen(loader: widget.loader, book: _book!, line: line),
      ),
    );
    if (changed ?? false) await _load();
  }

  Future<void> _detail(BudgetLine line) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BudgetDetailScreen(
          loader: widget.loader,
          month: _month,
          budgetId: line.budget.id,
        ),
      ),
    );
    if (changed ?? false) await _load();
  }

  /// « Mon ordre »: [moved] goes where [target] is.
  Future<void> _move(String moved, String target) async {
    if (moved == target) return;
    final ids = [for (final b in _book!.budgets) b.id]..remove(moved);
    ids.insert(ids.indexOf(target), moved);
    await widget.loader.budgets.reorder(ids);
    await _load();
  }

  Future<void> _openDisplay() async {
    final l = AppLocalizations.of(context);
    await showKibuoSheet<void>(
      context,
      title: l.budgetsDisplay,
      builder: (context) => StatefulBuilder(
        builder: (context, refresh) {
          void set({_Layout? layout, _Order? order}) {
            setState(() {
              _layout = layout ?? _layout;
              _order = order ?? _order;
            });
            refresh(() {});
            if (layout != null) widget.prefs.write(_layoutKey, layout.name);
            if (order != null) widget.prefs.write(_orderKey, order.name);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(l.budgetsLayout),
              SettingsCard(
                children: [
                  DisplayChoice(
                    icon: KibuoIcons.squaresFour,
                    label: l.budgetsTiles,
                    help: l.budgetsTilesHelp,
                    on: _layout == _Layout.tiles,
                    onTap: () => set(layout: _Layout.tiles),
                  ),
                  DisplayChoice(
                    icon: KibuoIcons.list,
                    label: l.budgetsList,
                    help: l.budgetsListHelp,
                    on: _layout == _Layout.list,
                    onTap: () => set(layout: _Layout.list),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionTitle(l.budgetsOrder),
              SettingsCard(
                children: [
                  DisplayChoice(
                    icon: KibuoIcons.warning,
                    label: l.budgetsWatch,
                    help: l.budgetsWatchHelp,
                    on: _order == _Order.watch,
                    onTap: () => set(order: _Order.watch),
                  ),
                  DisplayChoice(
                    icon: KibuoIcons.arrowsDownUp,
                    label: l.budgetsMine,
                    help: l.budgetsMineHelp,
                    on: _order == _Order.mine,
                    onTap: () => set(order: _Order.mine),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              KibuoButton(
                label: l.budgetsDone,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// « du 1er au 30 », or « du 25 oct. au 24 nov. ».
  String _periodText(AppLocalizations l) {
    final p = _book!.period;
    if (p.first.month == p.last.month) {
      final first = _lang == 'fr' && p.first.day == 1
          ? '1er'
          : '${p.first.day}';
      return l.budgetsDays(first, '${p.last.day}');
    }
    return l.listPeriod(
      DateFormat.MMMd(_lang).format(p.first),
      DateFormat.MMMd(_lang).format(p.last),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final book = _book;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.budgetsTitle),
        actions: [
          if (book != null && book.budgets.isNotEmpty)
            IconButton(
              tooltip: l.budgetsDisplay,
              color: KibuoColors.accent,
              onPressed: _openDisplay,
              icon: const Icon(KibuoIcons.slidersHorizontal),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: book == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: book.budgets.isEmpty
                  ? [
                      EmptyCard(
                        icon: KibuoIcons.target,
                        title: l.budgetsEmptyTitle,
                        help: l.budgetsEmptyHelp,
                        action: l.budgetsAdd,
                        onAction: _open,
                      ),
                    ]
                  : [
                      _summary(l, book),
                      if (_picker) ...[
                        const SizedBox(height: 8),
                        MonthPicker(
                          month: _month,
                          onPick: (m) {
                            setState(() {
                              _month = m;
                              _picker = false;
                            });
                            _load();
                          },
                          onThisMonth: _current
                              ? null
                              : () {
                                  setState(() {
                                    _month = periodOf(DateTime.now()).month;
                                    _picker = false;
                                  });
                                  _load();
                                },
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_layout == _Layout.tiles)
                        _tiles(l)
                      else
                        ..._groups(l),
                      const SizedBox(height: 16),
                      KibuoButton(
                        label: l.budgetsAdd,
                        kind: ButtonKind.create,
                        icon: KibuoIcons.plusBold,
                        onPressed: () => _open(),
                      ),
                    ],
            ),
    );
  }

  Widget _summary(AppLocalizations l, BudgetBook book) {
    final total = book.total;
    final left = total.left;
    final pre = total.approximate ? '≈ ' : '';
    final name = DateFormat.MMMM(_lang).format(_month);
    return MonthSummaryCard(
      month: name[0].toUpperCase() + name.substring(1),
      detail: _periodText(l),
      left: (short) => '$pre${_money(left, short: short)}',
      leftWord: left.minor < 0 ? l.budgetsTooMuch : l.homeLeft,
      leftLong: isLong(left),
      leftInAlert: left.minor < 0,
      spent: SpentLevel.share(total.percent),
      today: _current ? (DateTime.now(), book.period) : null,
      line: (short) => TextSpan(
        text: l.budgetsOutOf(
          '$pre${_money(total.spent, short: short)}',
          _money(total.amount, short: short),
        ),
      ),
      lineLong: isLong(total.amount),
      trailing: KibuoIcons.caretDown,
      onTap: () => setState(() => _picker = !_picker),
    );
  }

  Widget _tiles(AppLocalizations l) {
    final lines = _sorted(l);
    final mine = _order == _Order.mine;
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - 8) / 2;
        Widget tile(BudgetLine line) => SizedBox(
          width: width,
          child: _BudgetTile(
            line: line,
            name: categoryName(l, line.category),
            money: _money,
            today: _current ? (DateTime.now(), _book!.period) : null,
            onTap: () => _detail(line),
          ),
        );
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final line in lines)
              if (!mine)
                tile(line)
              else
                DragTarget<String>(
                  onAcceptWithDetails: (d) => _move(d.data, line.budget.id),
                  builder: (context, waiting, _) => LongPressDraggable<String>(
                    data: line.budget.id,
                    feedback: Material(
                      color: Colors.transparent,
                      elevation: 8,
                      borderRadius: BorderRadius.circular(
                        KibuoTheme.radiusCard,
                      ),
                      child: tile(line),
                    ),
                    childWhenDragging: Opacity(opacity: 0.3, child: tile(line)),
                    child: Container(
                      decoration: waiting.isEmpty
                          ? null
                          : BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                KibuoTheme.radiusCard,
                              ),
                              border: Border.all(
                                color: KibuoColors.accent,
                                width: 2,
                              ),
                            ),
                      child: tile(line),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  List<Widget> _groups(AppLocalizations l) {
    final lines = _sorted(l);
    final groups = [
      (BudgetState.over, l.budgetsGroupOver, KibuoColors.debtInk),
      (BudgetState.near, l.budgetsGroupNear, KibuoColors.warning),
      (BudgetState.ok, l.budgetsGroupOk, KibuoColors.inkMuted),
    ];
    return [
      for (final (state, title, dot) in groups)
        if (lines.any((x) => x.status.state == state)) ...[
          _GroupTitle(
            title: title,
            count: lines.where((x) => x.status.state == state).length,
            dot: dot,
          ),
          const SizedBox(height: 6),
          SettingsCard(
            children: [
              for (final line in lines)
                if (line.status.state == state)
                  _BudgetRow(
                    line: line,
                    name: categoryName(l, line.category),
                    money: _money,
                    today: _current ? (DateTime.now(), _book!.period) : null,
                    onTap: () => _detail(line),
                  ),
            ],
          ),
          const SizedBox(height: 14),
        ],
    ];
  }
}

/// « −4,00 $ » and its word, the colours of a budget's state.
({String Function(bool) amount, Color ink, Color share}) _look(
  BudgetStatus s,
  String Function(Money, {bool short}) money,
) {
  final left = s.left;
  final over = s.state == BudgetState.over;
  return (
    amount: (short) => over
        ? '−${money(Money(-left.minor, left.currency), short: short)}'
        : money(left, short: short),
    ink: over ? KibuoColors.debtInk : KibuoColors.ink,
    share: switch (s.state) {
      BudgetState.over => KibuoColors.debtInk,
      BudgetState.near => KibuoColors.warningInk,
      BudgetState.ok => KibuoColors.inkSecondary,
    },
  );
}

/// A budget's category icon in a grey tile.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: KibuoColors.background,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
      ),
      child: Icon(icon, size: size * 0.55, color: KibuoColors.inkSecondary),
    );
  }
}

/// A tile (canvas Budgets): icon and name, the share in the corner, what
/// is left in large, « restants sur 250,00 $ », then the thin bar.
class _BudgetTile extends StatelessWidget {
  const _BudgetTile({
    required this.line,
    required this.name,
    required this.money,
    required this.today,
    required this.onTap,
  });

  final BudgetLine line;
  final String name;
  final String Function(Money, {bool short}) money;
  final (DateTime, BudgetPeriod)? today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = line.status;
    final look = _look(s, money);
    final over = s.state == BudgetState.over;
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _IconTile(icon: categoryIcon(line.category), size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${s.percent} %',
                    style: KibuoType.caption.copyWith(
                      color: look.share,
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation.weight(700)],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FitAmount(
                long: isLong(s.left),
                style: KibuoType.sheetTitle.copyWith(
                  height: 1.2,
                  color: look.ink,
                ),
                span: (short) => TextSpan(text: look.amount(short)),
              ),
              const SizedBox(height: 1),
              FitAmount(
                long: isLong(s.amount),
                style: KibuoType.caption,
                span: (short) => TextSpan(
                  text: over
                      ? l.budgetsOverOf(money(s.amount, short: short))
                      : l.budgetsLeftOf(money(s.amount, short: short)),
                ),
              ),
              const SizedBox(height: 8),
              SpentBar(
                spent: SpentLevel.share(s.percent),
                today: today,
                thin: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of the list (canvas BudgetsListe): icon, name and « 104,00 $
/// dépensés sur 100,00 $ », what is left at the right, then the thin bar.
class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.line,
    required this.name,
    required this.money,
    required this.today,
    required this.onTap,
  });

  final BudgetLine line;
  final String name;
  final String Function(Money, {bool short}) money;
  final (DateTime, BudgetPeriod)? today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = line.status;
    final look = _look(s, money);
    final over = s.state == BudgetState.over;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                _IconTile(icon: categoryIcon(line.category), size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: KibuoType.rowLabel.copyWith(
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation.weight(600)],
                        ),
                      ),
                      const SizedBox(height: 1),
                      // « Montants longs »: shortened rather than cut.
                      FitAmount(
                        long: isLong(s.spent) || isLong(s.amount),
                        style: KibuoType.caption,
                        span: (short) => TextSpan(
                          text: l.budgetsSpentOf(
                            money(s.spent, short: short),
                            money(s.amount, short: short),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FitAmount(
                      long: isLong(s.left),
                      alignment: Alignment.centerRight,
                      maxWidth: MediaQuery.sizeOf(context).width * 0.35,
                      style: KibuoType.cardTitle.copyWith(color: look.ink),
                      span: (short) => TextSpan(text: look.amount(short)),
                    ),
                    Text(
                      over ? l.budgetsTooMuch : l.homeLeft,
                      style: KibuoType.caption.copyWith(
                        color: over ? KibuoColors.debtInk : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: SpentBar(
                spent: SpentLevel.share(s.percent),
                today: today,
                thin: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « ● Dépassés · 1 ».
class _GroupTitle extends StatelessWidget {
  const _GroupTitle({
    required this.title,
    required this.count,
    required this.dot,
  });

  final String title;
  final int count;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              text: title,
              children: [
                TextSpan(
                  text: ' · $count',
                  style: KibuoType.sectionTitle.copyWith(
                    fontWeight: FontWeight.w500,
                    fontVariations: const [FontVariation.weight(500)],
                    color: KibuoColors.inkMuted,
                  ),
                ),
              ],
            ),
            style: KibuoType.sectionTitle,
          ),
        ],
      ),
    );
  }
}
