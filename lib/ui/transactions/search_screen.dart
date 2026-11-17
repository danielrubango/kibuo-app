import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/search_history.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/transactions/search.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/dashed_border.dart';
import 'package:kibuo/ui/kit/empty_card.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operation_screens.dart';

/// The search of operations (PRODUCT; canvas RechercheR2): its own screen,
/// every month, the month shown in the list first, the others folded.
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.data,
    required this.month,
    this.history,
  });

  final EntryData data;

  /// The month the list shows: its results come first.
  final DateTime month;

  /// Where « Recherches récentes » are kept.
  final SearchHistory? history;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

/// One operation and its words, ready to be searched.
class _Item {
  _Item(this.t, this.labels, this.group, this.toAccount);

  final TransactionInfo t;
  final OperationLabels labels;

  /// The category above (« Transport » for Taxi), or the category itself.
  final String? group;
  final String? toAccount;

  String get title => labels.categoryPath.split(' › ').last;
}

/// What a search found in one operation, and where.
class _Found {
  const _Found(this.item, this.title, this.subtitle, this.amount);

  final _Item item;
  final Marked title;
  final Marked subtitle;
  final bool amount;
}

class _SearchScreenState extends State<SearchScreen> {
  final _field = TextEditingController();
  List<_Item> _items = const [];
  List<String> _recent = const [];
  List<(IconData, String)> _suggestions = const [];
  bool _othersOpen = false;

  @override
  void initState() {
    super.initState();
    _field.addListener(() => setState(() => _othersOpen = false));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  Future<void> _load() async {
    final data = widget.data;
    final l = AppLocalizations.of(context);
    final all = await data.transactions.all();
    final accounts = [
      ...await data.accounts.accounts(),
      ...await data.accounts.accounts(archived: true),
    ];
    final categories = [
      ...await data.categories.categories(CategoryKind.out),
      ...await data.categories.categories(CategoryKind.into),
    ];
    CategoryInfo? topOf(String? id) {
      for (final c in categories) {
        if (c.id == id || c.subs.any((s) => s.id == id)) return c;
      }
      return null;
    }

    final recent = await widget.history?.recent() ?? const <String>[];
    if (!mounted) return;
    final items = <_Item>[];
    for (final t in all) {
      if (!mounted) return;
      final labels = await OperationLabels.of(context, data, t);
      final top = topOf(t.categoryId);
      items.add(
        _Item(
          t,
          labels,
          top == null ? null : categoryName(l, top),
          labels.toAccount,
        ),
      );
    }
    // « Chercher par »: the categories and accounts used most these last
    // 30 days, three of each.
    final now = DateTime.now();
    final topCats = mostUsed([
      for (final t in all)
        if (topOf(t.categoryId) case final c?) (c, t.date.toLocal()),
    ], now: now);
    final topAccounts = mostUsed([
      for (final t in all)
        if (accounts.where((a) => a.id == t.accountId).firstOrNull
            case final a?)
          (a, t.date.toLocal()),
    ], now: now);
    if (!mounted) return;
    setState(() {
      _items = items;
      _recent = recent;
      _suggestions = [
        for (final c in topCats) (categoryIcon(c), categoryName(l, c)),
        for (final a in topAccounts) (_accountIcon(a.type), a.name),
      ];
    });
  }

  static IconData _accountIcon(AccountType t) => switch (t) {
    AccountType.cash => KibuoIcons.money,
    AccountType.bank => KibuoIcons.bank,
    AccountType.mobile => KibuoIcons.deviceMobile,
    AccountType.savings => KibuoIcons.currencyCircleDollar,
    _ => KibuoIcons.wallet,
  };

  void _search(String q) {
    _field.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
  }

  Future<void> _clearRecent() async {
    await widget.history?.clear();
    if (mounted) setState(() => _recent = const []);
  }

  Future<void> _open(TransactionInfo t) async {
    final history = widget.history;
    if (history != null) {
      final recent = await history.remember(_field.text);
      if (mounted) setState(() => _recent = recent);
    }
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OperationDetailScreen(data: widget.data, id: t.id),
      ),
    );
    await _load();
  }

  /// Where [q] is in this operation: its name, then the category above or
  /// the account, then its note, then its amount (PRODUCT).
  _Found? _match(SearchQuery q, _Item i) {
    final day = DateFormat.MMMd(_lang).format(i.t.date.toLocal());
    final parts = [day, ?i.group, i.labels.account];
    final sub = parts.join(' · ');
    final title = i.title;
    if (q.find(title) case final hit?) {
      return _Found(i, (title, hit), (sub, null), false);
    }
    // In the second line, but never in the date.
    var at = day.length + 3;
    for (final part in parts.skip(1)) {
      if (q.find(part) case (final s, final e)) {
        return _Found(i, (title, null), (sub, (at + s, at + e)), false);
      }
      at += part.length + 3;
    }
    if (i.toAccount case final to? when q.find(to) != null) {
      return _Found(i, (title, null), (sub, null), false);
    }
    final note = i.t.note;
    if (note != null) {
      if (q.find(note) case (final s, final e)) {
        final line = '$day · $note';
        final at = day.length + 3;
        return _Found(i, (title, null), (line, (at + s, at + e)), false);
      }
    }
    final digits = currencyOf(i.t.paid.currency).digits;
    if (q.matchesAmount(i.t.paid.minor, decimals: digits)) {
      return _Found(i, (title, null), (sub, null), true);
    }
    return null;
  }

  String _monthTitle(DateTime m) {
    final t = DateFormat.yMMMM(_lang).format(m);
    return t[0].toUpperCase() + t.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final q = SearchQuery.parse(_field.text);
    return Scaffold(
      backgroundColor: KibuoColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _header(l),
            const SizedBox(height: 16),
            if (q.isEmpty) ..._start(l) else ..._results(l, q),
          ],
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    final typed = _field.text.isNotEmpty;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          // Canvas RechercheR2: the arrow's touch area starts 10 left of
          // the margin, so the arrow itself lines up with it.
          SizedBox(
            width: KibuoTheme.heightTouch - 10,
            height: KibuoTheme.heightTouch,
            child: OverflowBox(
              maxWidth: KibuoTheme.heightTouch,
              alignment: Alignment.centerRight,
              child: SizedBox.square(
                dimension: KibuoTheme.heightTouch,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: l.searchClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    KibuoIcons.arrowLeft,
                    color: KibuoColors.ink,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 12, right: 4),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                border: Border.all(color: KibuoColors.accent, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(
                    KibuoIcons.magnifyingGlass,
                    size: 20,
                    color: KibuoColors.inkSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _field,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      cursorColor: KibuoColors.accent,
                      style: KibuoType.body.copyWith(fontSize: 16),
                      decoration: InputDecoration.collapsed(
                        hintText: l.searchHint,
                        hintStyle: KibuoType.body.copyWith(
                          fontSize: 16,
                          color: KibuoColors.inkMuted,
                        ),
                      ),
                    ),
                  ),
                  if (typed)
                    SizedBox.square(
                      dimension: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        tooltip: l.searchClear,
                        onPressed: () => _search(''),
                        icon: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: KibuoColors.track,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            KibuoIcons.x,
                            size: 14,
                            color: KibuoColors.ink,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, {Widget? end}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        Expanded(child: Text(text, style: KibuoType.sectionTitle)),
        ?end,
      ],
    ),
  );

  /// Nothing typed yet: « Recherches récentes » and « Chercher par ».
  List<Widget> _start(AppLocalizations l) => [
    if (_recent.isNotEmpty) ...[
      // 36 high so « Effacer » is easy to touch, the card still close.
      SizedBox(
        height: 36,
        child: _sectionTitle(
          l.searchRecent,
          end: InkWell(
            borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
            onTap: _clearRecent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                widthFactor: 1,
                child: Text(
                  l.searchRecentClear,
                  style: KibuoType.sectionTitle.copyWith(
                    color: KibuoColors.accent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: KibuoColors.surface,
          borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
        ),
        child: Column(
          children: [
            for (final (i, r) in _recent.indexed)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: i == 0
                      ? null
                      : const Border(
                          top: BorderSide(color: KibuoColors.background),
                        ),
                ),
                child: InkWell(
                  onTap: () => _search(r),
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        const Icon(
                          KibuoIcons.clockCounterClockwise,
                          size: 20,
                          color: KibuoColors.inkMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KibuoType.rowLabel,
                          ),
                        ),
                        const Icon(
                          KibuoIcons.arrowUpLeft,
                          size: 18,
                          color: KibuoColors.lineStrong,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
    _sectionTitle(l.searchBy),
    const SizedBox(height: 8),
    if (_suggestions.isNotEmpty) ...[
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (icon, name) in _suggestions)
            Material(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
              child: InkWell(
                borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
                onTap: () => _search(name),
                child: Container(
                  height: KibuoTheme.heightTouch,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: KibuoColors.inkMuted),
                      const SizedBox(width: 8),
                      Text(name, style: KibuoType.rowLabel),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
    ],
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        l.searchHelp,
        style: KibuoType.caption.copyWith(height: 16 / 12),
      ),
    ),
  ];

  List<Widget> _results(AppLocalizations l, SearchQuery q) {
    final found = [for (final i in _items) ?_match(q, i)];
    if (found.isEmpty) {
      return [
        EmptyCard(
          icon: KibuoIcons.magnifyingGlass,
          title: l.searchNoResultTitle(_field.text.trim()),
          help: l.searchNoResultHelp,
          action: l.searchClear,
          onAction: () => _search(''),
        ),
      ];
    }
    final split = splitByMonth(
      found,
      (f) => f.item.t.date.toLocal(),
      widget.month,
    );
    final others = [for (final g in split.others) ...g.items];
    final earlierOnly = split.others.every(
      (g) => g.month.isBefore(widget.month),
    );
    // The others open by themselves when the shown month has nothing.
    final open = _othersOpen || split.shown.isEmpty;
    return [
      if (split.shown.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l.searchNothingInMonth(
              DateFormat.yMMMM(_lang).format(widget.month),
              _field.text.trim(),
            ),
            style: KibuoType.body.copyWith(color: KibuoColors.inkSecondary),
          ),
        )
      else
        ..._group(l, widget.month, split.shown),
      if (others.isNotEmpty) ...[
        const SizedBox(height: 16),
        if (!open)
          _OthersCard(
            title: l.searchOthers(others.length),
            subtitle: earlierOnly ? l.searchEarlierMonths : l.searchOtherMonths,
            onTap: () => setState(() => _othersOpen = true),
          )
        else ...[
          if (split.shown.isNotEmpty) ...[
            _FoldLine(
              label: earlierOnly
                  ? l.searchEarlierFold(others.length)
                  : l.searchOtherFold(others.length),
              fold: l.searchFold,
              onFold: () => setState(() => _othersOpen = false),
            ),
            const SizedBox(height: 8),
          ],
          for (final (i, g) in split.others.indexed) ...[
            if (i > 0) const SizedBox(height: 16),
            ..._group(l, g.month, g.items),
          ],
        ],
      ],
    ];
  }

  /// A month's results: its title and number, then its operations.
  List<Widget> _group(AppLocalizations l, DateTime month, List<_Found> list) =>
      [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(_monthTitle(month), style: KibuoType.sectionTitle),
              ),
              Text(
                l.searchResults(list.length),
                style: KibuoType.sectionTitle.copyWith(
                  fontWeight: FontWeight.w500,
                  fontVariations: const [FontVariation.weight(500)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final (i, f) in list.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          OperationRow(
            t: f.item.t,
            labels: f.item.labels,
            title: f.title,
            subtitle: f.subtitle,
            amountMarked: f.amount,
            onTap: () => _open(f.item.t),
          ),
        ],
      ];
}

/// « 3 autres résultats · Dans les mois précédents », folded (canvas
/// RechercheR2).
class _OthersCard extends StatelessWidget {
  const _OthersCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DashedBorder(
      radius: 16,
      color: KibuoColors.line,
      child: Material(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  KibuoIcons.clockCounterClockwise,
                  size: 20,
                  color: KibuoColors.inkSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: KibuoType.buttonSmall),
                      Text(subtitle, style: KibuoType.caption),
                    ],
                  ),
                ),
                const Icon(
                  KibuoIcons.caretDown,
                  size: 18,
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

/// « Mois précédents · 3 », a dashed line, then « Replier ».
class _FoldLine extends StatelessWidget {
  const _FoldLine({
    required this.label,
    required this.fold,
    required this.onFold,
  });

  final String label;
  final String fold;
  final VoidCallback onFold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KibuoType.sectionTitle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomPaint(
              size: const Size.fromHeight(1.5),
              painter: _DashedLine(),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onFold,
            child: SizedBox(
              height: KibuoTheme.heightTouch,
              child: Row(
                children: [
                  Text(
                    fold,
                    style: KibuoType.body.copyWith(
                      color: KibuoColors.accent,
                      fontWeight: FontWeight.w600,
                      fontVariations: const [FontVariation.weight(600)],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    KibuoIcons.caretUp,
                    size: 16,
                    color: KibuoColors.accent,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KibuoColors.line
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLine old) => false;
}
