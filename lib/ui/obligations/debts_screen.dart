import 'dart:ui' show ImageFilter, PathMetric;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/hint_store.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/domain/calendar.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/empty_card.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/obligations/debt_screen.dart';
import 'package:kibuo/ui/obligations/new_debt_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// Plus › « Dettes et créances » (canvas DettesListeDois): « Je dois » and
/// « On me doit » with what is left of each, then the lines by due date or
/// by person. Touching a line opens it in place.
class DebtsScreen extends StatefulWidget {
  const DebtsScreen({
    super.key,
    required this.data,
    required this.debts,
    required this.prefs,
    this.hints,
    this.tab = DebtDirection.owe,
    this.now = DateTime.now,
    this.onChanged,
  });

  final EntryData data;
  final DebtRepository debts;
  final PreferenceStore prefs;

  /// Where the two-step guide remembers it was shown; none, no guide.
  final HintStore? hints;

  /// The tab it opens on.
  final DebtDirection tab;
  final DateTime Function() now;

  /// A debt was saved: its money may have reached a list.
  final VoidCallback? onChanged;

  static const groupingKey = 'debts_grouping';
  static const paidKey = 'debts_paid_place';
  static const detailsKey = 'debts_details_place';

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  late DebtDirection _tab = widget.tab;
  List<DebtLine>? _lines;
  DebtGrouping _grouping = DebtGrouping.due;
  PaidPlace _paidPlace = PaidPlace.inline;
  String? _open;
  bool _paidShown = false;

  /// The guide's step, 1 or 2; 0 when not shown.
  int _coach = 0;
  final _firstRow = GlobalKey();

  /// What converts each other currency to the main one.
  String? _main;
  Map<String, ExchangeRate> _rates = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lines = await widget.debts.debts();
    final grouping = await widget.prefs.read(DebtsScreen.groupingKey);
    final paid = await widget.prefs.read(DebtsScreen.paidKey);
    final details = await widget.prefs.read(DebtsScreen.detailsKey);
    final main = await widget.data.currencies.primaryCurrency();
    final rates = <String, ExchangeRate>{};
    if (main != null) {
      for (final code in {for (final l in lines) l.left.currency}) {
        if (code == main) continue;
        final info = await widget.data.currencies.latestRate(code, main);
        if (info != null) rates[code] = info.rate;
      }
    }
    if (!mounted) return;
    setState(() {
      _lines = lines;
      _grouping = grouping == DebtGrouping.person.name
          ? DebtGrouping.person
          : DebtGrouping.due;
      _paidPlace = PaidPlace.fromStored(paid);
      _detailsAbove = details != 'below';
      _main = main;
      _rates = rates;
      // Deleted from its card: nothing stays open.
      if (!lines.any((d) => d.id == _lifted)) {
        _open = null;
        _lifted = null;
      }
    });
    // Once, the first time the list has a line (owner, 23 November).
    final hints = widget.hints;
    if (hints != null &&
        _coach == 0 &&
        lines.any((d) => d.direction == _tab) &&
        !await hints.debtsCoachShown()) {
      await hints.debtsCoachDone();
      if (mounted) setState(() => _coach = 1);
    }
  }

  void _coachNext() {
    if (_coach == 1) {
      setState(() => _coach = 2);
      return;
    }
    // « Essayer »: the first line opens.
    setState(() => _coach = 0);
    final first = _firstId;
    if (first != null) _openLine(first);
  }

  String? _firstId;
  List<DebtLine>? _firstLines;

  String get _lang => Localizations.localeOf(context).languageCode;

  /// [m] in the main currency, and whether it was converted; null without
  /// a rate.
  (Money, bool)? _inMain(Money m) {
    final main = _main;
    if (main == null || m.currency == main) return (m, false);
    final rate = _rates[m.currency];
    if (rate == null) return null;
    return (rate.convert(m, to: currencyOf(main)), true);
  }

  /// What is left of [lines], in the main currency: « Environ » once
  /// something is converted.
  String? _total(Iterable<DebtLine> lines) {
    final main = _main;
    if (main == null) return null;
    var sum = 0;
    var about = false;
    for (final l in lines) {
      if (l.settled) continue;
      final m = _inMain(l.left);
      if (m == null) return null;
      sum += m.$1.minor;
      about = about || m.$2;
    }
    final text = context.money(Money(sum, main));
    return about ? AppLocalizations.of(context).debtsAbout(text) : text;
  }

  Future<void> _add() async {
    final saved = await runNewDebt(
      context,
      data: widget.data,
      debts: widget.debts,
      direction: _tab,
      now: widget.now,
      onSaved: () {
        widget.onChanged?.call();
        _load();
      },
    );
    if (saved == null || !mounted) return;
    setState(() {
      _tab = saved;
      _open = null;
    });
  }

  Future<void> _display() async {
    final l = AppLocalizations.of(context);
    await showKibuoSheet<void>(
      context,
      title: l.listDisplay,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void pick({DebtGrouping? grouping, PaidPlace? paid, bool? above}) {
            setState(() {
              _grouping = grouping ?? _grouping;
              _paidPlace = paid ?? _paidPlace;
              _detailsAbove = above ?? _detailsAbove;
              _open = null;
            });
            if (above != null) {
              widget.prefs.write(
                DebtsScreen.detailsKey,
                above ? 'above' : 'below',
              );
            }
            setSheet(() {});
            if (grouping != null) {
              widget.prefs.write(DebtsScreen.groupingKey, grouping.name);
            }
            if (paid != null) {
              widget.prefs.write(DebtsScreen.paidKey, paid.stored);
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionTitle(l.debtsGroupBy),
              SettingsCard(
                children: [
                  DisplayChoice(
                    icon: KibuoIcons.calendarBlank,
                    label: l.debtsByDue,
                    help: l.debtsByDueHelp,
                    on: _grouping == DebtGrouping.due,
                    onTap: () => pick(grouping: DebtGrouping.due),
                  ),
                  DisplayChoice(
                    icon: KibuoIcons.users,
                    label: l.debtsByPerson,
                    help: l.debtsByPersonHelp,
                    on: _grouping == DebtGrouping.person,
                    onTap: () => pick(grouping: DebtGrouping.person),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionTitle(l.debtsPaidTitle),
              SettingsCard(
                children: [
                  DisplayChoice(
                    icon: KibuoIcons.list,
                    label: l.debtsPaidInline,
                    help: l.debtsPaidInlineHelp,
                    on: _paidPlace == PaidPlace.inline,
                    onTap: () => pick(paid: PaidPlace.inline),
                  ),
                  DisplayChoice(
                    icon: KibuoIcons.arrowDown,
                    label: l.debtsPaidBottom,
                    help: l.debtsPaidBottomHelp,
                    on: _paidPlace == PaidPlace.bottom,
                    onTap: () => pick(paid: PaidPlace.bottom),
                  ),
                  DisplayChoice(
                    icon: KibuoIcons.eyeSlash,
                    label: l.debtsPaidHidden,
                    help: l.debtsPaidHiddenHelp,
                    on: _paidPlace == PaidPlace.hidden,
                    onTap: () => pick(paid: PaidPlace.hidden),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SectionTitle(l.debtsOpenTitle),
              SettingsCard(
                children: [
                  DisplayChoice(
                    icon: KibuoIcons.arrowLineUp,
                    label: l.debtsDetailsAbove,
                    help: l.debtsDetailsAboveHelp,
                    on: _detailsAbove,
                    onTap: () => pick(above: true),
                  ),
                  DisplayChoice(
                    icon: KibuoIcons.arrowDown,
                    label: l.debtsDetailsBelow,
                    help: l.debtsDetailsBelowHelp,
                    on: !_detailsAbove,
                    onTap: () => pick(above: false),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              KibuoButton(
                label: l.displayDone,
                kind: ButtonKind.dark,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      ),
    );
  }

  /// With a line open, any touch closes it, even on another line; the
  /// next one opens (owner, 23 November).
  void _toggle(String id) {
    Haptics.tap();
    _open == null ? _openLine(id) : _close();
  }

  static const _opening = Duration(milliseconds: 250);
  static const _closing = Duration(milliseconds: 200);

  /// The line above the veil, kept while it closes.
  String? _lifted;

  /// Where an open line's details show (the display sheet's choice).
  bool _detailsAbove = true;

  /// The card above the veil is built closed, then opens: both it and the
  /// one in the list grow together.
  void _openLine(String id) {
    setState(() => _lifted = id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _lifted == id) setState(() => _open = id);
    });
  }

  void _close() {
    setState(() => _open = null);
    Future<void>.delayed(_closing, () {
      if (mounted && _open == null) setState(() => _lifted = null);
    });
  }

  /// Where the open line's card is, for its copy above the veil.
  final _openLink = LayerLink();

  /// A line; [live] above the veil, where it opens. In the list behind,
  /// it never moves (owner, 23 November).
  Widget _row(
    AppLocalizations l,
    DebtLine d,
    DateTime now, {
    required bool live,
  }) => _DebtRow(
    line: d,
    now: now,
    open: live && d.id == _open,
    amount: context.money(d.left),
    details: live && d.id == _lifted ? _details(l, d, now) : null,
    detailsAbove: _detailsAbove,
    onTap: () => _toggle(d.id),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lines = _lines;
    final now = widget.now();
    final mine = [
      for (final d in lines ?? const <DebtLine>[])
        if (d.direction == _tab) d,
    ];
    final listing = arrangeDebts(
      mine,
      today: now,
      grouping: _grouping,
      paidPlace: _paidPlace,
    );
    final dim = _open != null;
    _firstLines = listing.groups.isEmpty ? null : listing.groups.first.lines;
    _firstId = _firstLines?.first.id;
    final page = Scaffold(
      appBar: AppBar(
        title: Text(l.debtsTitle),
        actions: [
          IconButton(
            tooltip: l.listDisplay,
            onPressed: _display,
            icon: const Icon(
              KibuoIcons.slidersHorizontal,
              color: KibuoColors.accent,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: lines == null
          ? const SizedBox.shrink()
          // A touch on the empty page closes the open line.
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: dim ? _close : null,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  _Dimmed(
                    on: dim,
                    child: Row(
                      children: [
                        for (final d in DebtDirection.values) ...[
                          if (d == DebtDirection.owed)
                            const SizedBox(width: 10),
                          Expanded(child: _tabCard(l, d, lines, now)),
                        ],
                      ],
                    ),
                  ),
                  if (listing.groups.isEmpty && listing.paid.isEmpty) ...[
                    const SizedBox(height: 16),
                    EmptyCard(
                      icon: KibuoIcons.handCoins,
                      title: _tab == DebtDirection.owe
                          ? l.debtsEmptyOwe
                          : l.debtsEmptyOwed,
                      help: _tab == DebtDirection.owe
                          ? l.debtsEmptyOweHelp
                          : l.debtsEmptyOwedHelp,
                    ),
                  ],
                  for (final g in listing.groups) ...[
                    const SizedBox(height: GroupTitle.before),
                    _Dimmed(
                      on: dim,
                      child: GroupTitle(
                        title: _groupTitle(l, g.key),
                        leading: g.key.isLate ? const _LateDot() : null,
                        trailing:
                            [
                                  for (final d in g.lines)
                                    if (!d.settled) d,
                                ].length >
                                1
                            ? GroupNote(_total(g.lines) ?? '')
                            : null,
                      ),
                    ),
                    _card(l, g.lines, now),
                  ],
                  if (listing.paid.isNotEmpty) ...[
                    const SizedBox(height: GroupTitle.gap),
                    _Dimmed(
                      on: dim && !listing.paid.any((d) => d.id == _open),
                      child: _PaidToggle(
                        label: _tab == DebtDirection.owe
                            ? l.debtSettledOwe(listing.paid.length)
                            : l.debtSettledOwed(listing.paid.length),
                        open: _paidShown,
                        onTap: _open != null
                            ? _close
                            : () => setState(() => _paidShown = !_paidShown),
                      ),
                    ),
                    if (_paidShown) ...[
                      const SizedBox(height: 8),
                      _card(l, listing.paid, now),
                    ],
                  ],
                  // Like « Nouveau compte » and « Nouveau budget »: dashed, at
                  // the end of the list.
                  const SizedBox(height: 16),
                  _Dimmed(
                    on: dim,
                    child: KibuoButton(
                      label: _tab == DebtDirection.owe
                          ? l.debtNewOwe
                          : l.debtNewOwed,
                      kind: ButtonKind.create,
                      icon: KibuoIcons.plusBold,
                      onPressed: dim ? _close : _add,
                    ),
                  ),
                ],
              ),
            ),
    );
    return Stack(
      children: [
        page,
        // Behind the open line, faded and lightly blurred, a light grey
        // veil over the whole screen, its bar too; the card holding the
        // line stays white above it, in its place (owner, 23 November).
        if (_lifted != null) ...[
          // Only what appears reacts: the veil holds the page behind,
          // which neither scrolls nor moves, and a touch on it closes the
          // line (owner, 23 November).
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: AnimatedOpacity(
                duration: dim ? _opening : _closing,
                opacity: dim ? 1 : 0,
                child: const ColoredBox(color: KibuoColors.veil),
              ),
            ),
          ),
          for (final lines in [
            for (final g in listing.groups) g.lines,
            if (_paidShown) listing.paid,
          ])
            if (lines.any((d) => d.id == _lifted))
              Positioned(
                left: 16,
                right: 16,
                top: 0,
                child: CompositedTransformFollower(
                  link: _openLink,
                  showWhenUnlinked: false,
                  child: Material(
                    type: MaterialType.transparency,
                    child: _card(l, lines, now, above: true),
                  ),
                ),
              ),
        ],
        if (_coach > 0)
          Positioned.fill(
            // Above the page's own Material: its words need one too.
            child: Material(
              type: MaterialType.transparency,
              child: _Coach(
                target: _firstRow,
                step: _coach,
                onSkip: () => setState(() => _coach = 0),
                onNext: _coachNext,
              ),
            ),
          ),
      ],
    );
  }

  Widget _tabCard(
    AppLocalizations l,
    DebtDirection d,
    List<DebtLine> lines,
    DateTime now,
  ) {
    final on = d == _tab;
    final its = [
      for (final x in lines)
        if (x.direction == d) x,
    ];
    final late = its
        .where((x) => debtState(x, now).$1 == DebtState.late)
        .length;
    return Material(
      color: on ? KibuoColors.ink : KibuoColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _open != null
            ? _close
            : () {
                Haptics.tap();
                setState(() => _tab = d);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      d == DebtDirection.owe ? l.debtsOwe : l.debtsOwed,
                      style: KibuoType.body.copyWith(
                        fontSize: 13,
                        color: on ? KibuoColors.surface : KibuoColors.ink,
                      ),
                    ),
                  ),
                  if (late > 0)
                    Text(
                      l.debtsLateCount(late),
                      style: KibuoType.body
                          .copyWith(
                            fontSize: 13,
                            color: on
                                ? KibuoColors.dangerOnInk
                                : KibuoColors.danger,
                          )
                          .weight(600),
                    ),
                ],
              ),
              Text(
                _total(its) ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KibuoType.highlight.copyWith(
                  fontSize: 21,
                  height: 26 / 21,
                  color: on ? KibuoColors.surface : KibuoColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _groupTitle(AppLocalizations l, DebtGroupKey key) {
    if (key.isLate) return l.debtsLateGroup;
    if (key.isNone) return l.debtsNoDue;
    if (key.isPerson) return key.person;
    final now = widget.now();
    final month = DateTime(key.year, key.month);
    final t = key.year == now.year
        ? DateFormat.MMMM(_lang).format(month)
        : DateFormat.yMMMM(_lang).format(month);
    return t[0].toUpperCase() + t.substring(1);
  }

  /// One white card for a group's lines. The card holding the open line
  /// is drawn again [above] the veil, its other lines only faded.
  Widget _card(
    AppLocalizations l,
    List<DebtLine> lines,
    DateTime now, {
    bool above = false,
  }) {
    final holds = lines.any((d) => d.id == _lifted);
    final card = AnimatedContainer(
      duration: _open != null ? _opening : _closing,
      curve: Curves.easeOutCubic,
      // With the line's block 6 around its words: 12 to the card's edge,
      // and 8 on each side of a divider, as before.
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        children: [
          for (final (i, d) in lines.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                child: Container(
                  height: 1,
                  color: above && (d.id == _open || lines[i - 1].id == _open)
                      ? Colors.transparent
                      : KibuoColors.background,
                ),
              ),
            _Dimmed(
              on: _open != null && (!above || d.id != _open),
              blur: !above,
              child: !above && i == 0 && identical(lines, _firstLines)
                  ? KeyedSubtree(
                      key: _firstRow,
                      child: _row(l, d, now, live: false),
                    )
                  : _row(l, d, now, live: above),
            ),
          ],
        ],
      ),
    );
    return holds && !above
        ? CompositedTransformTarget(link: _openLink, child: card)
        : card;
  }

  /// What an open line adds: the full date, how much is paid back, and
  /// what a foreign amount is worth today.
  Widget _details(AppLocalizations l, DebtLine d, DateTime now) {
    final (state, _) = debtState(d, now);
    final look = _Look.of(state);
    final due = d.due;
    String day(DateTime x) => DateFormat.MMMMEEEEd(_lang).format(x);
    final dateLine = due == null
        ? l.debtNoDueLine
        : state == DebtState.late
        ? l.debtDueLateLine(day(due))
        : state == DebtState.today
        ? l.debtDueTodayLine(day(due))
        : l.debtDueLine(day(due));
    final owe = d.direction == DebtDirection.owe;
    final paid = Money(d.amount.minor - d.left.minor, d.amount.currency);
    final main = _inMain(d.left);
    final payLine = main != null && main.$2 && !d.settled
        ? l.debtAboutLine(context.money(main.$1))
        : paid.minor <= 0
        ? (owe ? l.debtNothingRepaid : l.debtNothingReceived)
        : owe
        ? l.debtRepaidLine(context.money(paid), context.money(d.amount))
        : l.debtReceivedLine(context.money(paid), context.money(d.amount));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: look.box,
        border: Border.all(color: look.track),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLine, style: KibuoType.body.weight(600)),
          if (d.repaidShare > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: d.repaidShare,
                      minHeight: 8,
                      color: look.bar,
                      backgroundColor: look.track,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${context.money(paid)} / ${context.money(d.amount)}',
                  style: KibuoType.caption
                      .copyWith(color: KibuoColors.ink)
                      .weight(600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            payLine,
            style: KibuoType.body.copyWith(
              fontSize: 13,
              height: 18 / 13,
              color: KibuoColors.inkSecondary,
            ),
          ),
          // « Rembourser » or « Encaisser », then « Détails › » (canvas
          // DettesListeDois); once settled, only « Détails ».
          const SizedBox(height: 12),
          Row(
            children: [
              if (!d.settled) ...[
                Expanded(
                  child: _BoxButton(
                    label: owe ? l.debtRepay : l.debtCollect,
                    dark: true,
                    onTap: () => _repay(d.id),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _BoxButton(
                  label: l.debtDetails,
                  chevron: true,
                  onTap: () => _openCard(d.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _repay(String id) async {
    final detail = await widget.debts.detail(id);
    if (detail == null || !mounted) return;
    // The line stays open behind the sheet, and updates (owner, 23
    // November).
    final saved = await repayDebt(
      context,
      data: widget.data,
      debts: widget.debts,
      detail: detail,
      now: widget.now,
      onSaved: _load,
    );
    if (saved) {
      widget.onChanged?.call();
      await _load();
    }
  }

  Future<void> _openCard(String id) async {
    // Back from the card, the line is still open, up to date.
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DebtScreen(
          data: widget.data,
          debts: widget.debts,
          id: id,
          now: widget.now,
        ),
      ),
    );
    widget.onChanged?.call();
    await _load();
  }
}

/// The colours of a line's day and words, by its state (canvas
/// DettesListeDois).
class _Look {
  const _Look(this.box, this.ink, this.bar, this.word, this.track);

  final Color box;
  final Color ink;
  final Color bar;
  final Color word;
  final Color track;

  static _Look of(DebtState state) => switch (state) {
    DebtState.late => const _Look(
      KibuoColors.dangerSoft,
      KibuoColors.dangerDeep,
      KibuoColors.danger,
      KibuoColors.danger,
      KibuoColors.dangerTrack,
    ),
    DebtState.today || DebtState.soon => const _Look(
      KibuoColors.warningSoft,
      KibuoColors.warningSoftInk,
      KibuoColors.warning,
      KibuoColors.warningInk,
      KibuoColors.warningTrack,
    ),
    DebtState.normal => const _Look(
      KibuoColors.accentSoft,
      KibuoColors.ink,
      KibuoColors.accent,
      KibuoColors.inkSecondary,
      KibuoColors.accentTintOpen,
    ),
    DebtState.none => const _Look(
      KibuoColors.fillSoft,
      KibuoColors.inkSecondary,
      KibuoColors.inkMuted,
      KibuoColors.inkSecondary,
      KibuoColors.track,
    ),
    DebtState.paid => const _Look(
      KibuoColors.accentDone,
      KibuoColors.accent,
      KibuoColors.accent,
      KibuoColors.accent,
      KibuoColors.accentTintOpen,
    ),
  };
}

/// « En retard de 7 jours », « Après-demain », « Sans échéance ».
String debtWord(AppLocalizations l, DebtLine d, DateTime now) {
  final (state, days) = debtState(d, now);
  return switch (state) {
    DebtState.late => l.debtWordLate(-days!),
    DebtState.today => l.debtWordToday,
    DebtState.soon => days == 1 ? l.debtWordTomorrow : l.debtWordAfterTomorrow,
    DebtState.normal => l.debtWordIn(days!),
    DebtState.none => l.debtsNoDue,
    DebtState.paid => () {
      final on = d.settledOn ?? DateTime(now.year, now.month, now.day);
      final ago = calendarDays(on, now);
      return d.direction == DebtDirection.owe
          ? l.debtWordSettled(ago)
          : l.debtWordReceived(ago);
    }(),
  };
}

/// A line: the due day in its ringed square, the name, the words, what is
/// left, ˅. Open, it lifts and unfolds [details] below.
class _DebtRow extends StatelessWidget {
  const _DebtRow({
    required this.line,
    required this.now,
    required this.open,
    required this.amount,
    required this.onTap,
    this.details,
    this.detailsAbove = false,
  });

  final DebtLine line;
  final DateTime now;
  final bool open;

  final String amount;
  final Widget? details;

  /// The details come down from above the line, which goes down with
  /// them, and go back up on closing (owner, 23 November, to compare).
  final bool detailsAbove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (state, _) = debtState(line, now);
    final look = _Look.of(state);
    final paid = state == DebtState.paid;
    final due = line.due;
    final row = Semantics(
      button: true,
      expanded: open,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              _DayBox(
                look: look,
                share: line.repaidShare,
                child: paid
                    ? Icon(KibuoIcons.checkBold, size: 20, color: look.ink)
                    : Text(
                        due == null ? '–' : '${due.day}',
                        style: KibuoType.cardTitle.copyWith(
                          fontSize: 16,
                          color: look.ink,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.person,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.rowLabel
                          .copyWith(
                            color: paid
                                ? KibuoColors.inkSecondary
                                : KibuoColors.ink,
                          )
                          .weight(600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      debtWord(l, line, now),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.body
                          .copyWith(fontSize: 13, color: look.word)
                          .weight(600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amount,
                style: KibuoType.cardTitle.copyWith(
                  color: paid ? KibuoColors.inkSecondary : KibuoColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                open ? KibuoIcons.caretUp : KibuoIcons.caretDown,
                size: 18,
                color: KibuoColors.inkSecondary,
              ),
            ],
          ),
        ),
      ),
    );
    // The block is always there, 8 inside the card and 6 around the
    // words: open, its frame fades in, nothing slides sideways, only the
    // height changes (owner, 23 November). Opening, the frame comes
    // first, then the details; closing, the other way round.
    final duration = open
        ? _DebtsScreenState._opening
        : _DebtsScreenState._closing;
    return AnimatedContainer(
      duration: duration,
      curve: open
          ? const Interval(0, 0.6, curve: Curves.easeOut)
          : const Interval(0.4, 1, curve: Curves.easeIn),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
        border: Border.all(
          color: open
              ? KibuoColors.track
              : KibuoColors.track.withValues(alpha: 0),
        ),
        boxShadow: [
          BoxShadow(
            color: open ? const Color(0x1F0E1320) : const Color(0x000E1320),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!detailsAbove) row,
          AnimatedCrossFade(
            duration: _DebtsScreenState._opening,
            reverseDuration: _DebtsScreenState._closing,
            // Opening, the details wait for the frame; closing, they go
            // first.
            sizeCurve: open
                ? const Interval(0.25, 1, curve: Curves.easeOutCubic)
                : const Interval(0, 0.75, curve: Curves.easeInCubic),
            secondCurve: const Interval(0.4, 1, curve: Curves.easeOut),
            // Above, the details slide in from the top edge and leave by
            // it: their bottom shows first.
            alignment: detailsAbove
                ? Alignment.bottomCenter
                : Alignment.topCenter,
            crossFadeState: open && details != null
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: EdgeInsets.only(
                top: detailsAbove ? 0 : 8,
                bottom: detailsAbove ? 8 : 0,
              ),
              child: details ?? const SizedBox(width: double.infinity),
            ),
          ),
          if (detailsAbove) row,
        ],
      ),
    );
  }
}

/// The 46 square around the due day: tinted, ringed, the ring filling in
/// green (or the state's colour) as the debt is paid back.
class _DayBox extends StatelessWidget {
  const _DayBox({required this.look, required this.share, required this.child});

  final _Look look;
  final double share;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 46,
    height: 46,
    child: CustomPaint(
      painter: _RingPainter(look, share),
      child: Center(child: child),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.look, this.share);

  final _Look look;
  final double share;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2.5, 2.5, size.width - 5, size.height - 5),
      const Radius.circular(13),
    );
    canvas.drawRRect(rect, Paint()..color = look.box);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawRRect(rect, stroke..color = look.track);
    if (share <= 0) return;
    // From the top's middle, clockwise.
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, 2.5)
      ..lineTo(w - 15.5, 2.5)
      ..arcToPoint(Offset(w - 2.5, 15.5), radius: const Radius.circular(13))
      ..lineTo(w - 2.5, h - 15.5)
      ..arcToPoint(Offset(w - 15.5, h - 2.5), radius: const Radius.circular(13))
      ..lineTo(15.5, h - 2.5)
      ..arcToPoint(Offset(2.5, h - 15.5), radius: const Radius.circular(13))
      ..lineTo(2.5, 15.5)
      ..arcToPoint(const Offset(15.5, 2.5), radius: const Radius.circular(13))
      ..close();
    final PathMetric metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * share.clamp(0, 1)),
      stroke..color = look.bar,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.share != share || old.look != look;
}

/// Lines and blocks behind an open line: faded, lightly blurred.
class _Dimmed extends StatelessWidget {
  const _Dimmed({required this.on, required this.child, this.blur = true});

  final bool on;
  final bool blur;
  final Widget child;

  // The blur comes at once, only the fading moves: a blur that grows
  // spreads the edges, and the page seemed to move (owner, 23 November).
  @override
  Widget build(BuildContext context) => ImageFiltered(
    enabled: blur && on,
    imageFilter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
    child: AnimatedOpacity(
      duration: on ? _DebtsScreenState._opening : _DebtsScreenState._closing,
      curve: Curves.easeOutCubic,
      opacity: on ? 0.6 : 1,
      child: child,
    ),
  );
}

class _LateDot extends StatelessWidget {
  const _LateDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: KibuoColors.danger,
      shape: BoxShape.circle,
    ),
  );
}

/// « 1 dette soldée » ✓ … ˅, when settled ones go at the bottom.
class _PaidToggle extends StatelessWidget {
  const _PaidToggle({
    required this.label,
    required this.open,
    required this.onTap,
  });

  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: KibuoColors.surface,
    borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
    child: InkWell(
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      onTap: onTap,
      child: SizedBox(
        height: KibuoTheme.heightSecondary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                KibuoIcons.checkBold,
                size: 20,
                color: KibuoColors.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: KibuoType.body
                      .copyWith(color: KibuoColors.inkSecondary)
                      .weight(600),
                ),
              ),
              Icon(
                open ? KibuoIcons.caretUp : KibuoIcons.caretDown,
                size: 18,
                color: KibuoColors.inkSecondary,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The list's guide (canvas DettesListeDois): the page darkened but for
/// the first line, then a white card under it, « 1 sur 2 », its title and
/// words, « Passer » and « Suivant », then « Essayer ».
class _Coach extends StatefulWidget {
  const _Coach({
    required this.target,
    required this.step,
    required this.onSkip,
    required this.onNext,
  });

  final GlobalKey target;
  final int step;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  State<_Coach> createState() => _CoachState();
}

class _CoachState extends State<_Coach> {
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final box = widget.target.currentContext?.findRenderObject() as RenderBox?;
    final me = context.findRenderObject() as RenderBox?;
    if (!mounted || box == null || me == null || !box.hasSize) return;
    final topLeft = me.globalToLocal(box.localToGlobal(Offset.zero));
    // The window fits the card: its sides, and 12 above and below the
    // line's words, the card's own space (owner, 23 November). The line's
    // block sits 8 inside the card and 6 around its words.
    final line = topLeft & box.size;
    setState(
      () => _hole = Rect.fromLTRB(
        line.left - 8,
        line.top - 6,
        line.right + 8,
        line.bottom + 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hole = _hole;
    if (hole == null) return const SizedBox.expand();
    final first = widget.step == 1;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: CustomPaint(painter: _HolePainter(hole)),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: hole.bottom + 15,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 24,
                top: -7,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: 14,
                    height: 14,
                    color: KibuoColors.surface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KibuoColors.surface,
                  borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.debtsCoachStep(widget.step),
                      style: KibuoType.caption.weight(600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      first ? l.debtsCoach1Title : l.debtsCoach2Title,
                      style: KibuoType.cardTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      first ? l.debtsCoach1Text : l.debtsCoach2Text,
                      style: KibuoType.body.copyWith(
                        color: KibuoColors.inkSecondary,
                        height: 20 / 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: widget.onSkip,
                          style: TextButton.styleFrom(
                            foregroundColor: KibuoColors.inkSecondary,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 44),
                            textStyle: KibuoType.buttonSmall.copyWith(
                              fontSize: 14,
                            ),
                          ),
                          child: Text(l.debtsCoachSkip),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: widget.onNext,
                          style: FilledButton.styleFrom(
                            backgroundColor: KibuoColors.mint,
                            foregroundColor: KibuoColors.ink,
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                KibuoTheme.radiusTile,
                              ),
                            ),
                            textStyle: KibuoType.buttonSmall,
                          ),
                          child: Text(
                            first ? l.debtsCoachNext : l.debtsCoachTry,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The guide's veil, open around [hole].
class _HolePainter extends CustomPainter {
  _HolePainter(this.hole);

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(
          hole,
          const Radius.circular(KibuoTheme.radiusCard),
        ),
      );
    canvas.drawPath(path, Paint()..color = KibuoColors.tipScrim);
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.hole != hole;
}

/// A button of the open line's box: ink for the action, white for
/// « Détails › ».
class _BoxButton extends StatelessWidget {
  const _BoxButton({
    required this.label,
    required this.onTap,
    this.dark = false,
    this.chevron = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool dark;
  final bool chevron;

  @override
  Widget build(BuildContext context) => Material(
    color: dark ? KibuoColors.ink : KibuoColors.surface,
    borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
    child: InkWell(
      borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
      onTap: onTap,
      child: SizedBox(
        height: KibuoTheme.heightTouch,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: KibuoType.body
                  .copyWith(color: dark ? KibuoColors.surface : KibuoColors.ink)
                  .weight(600),
            ),
            if (chevron) ...[
              const SizedBox(width: 8),
              const Icon(
                KibuoIcons.caretRight,
                size: 16,
                color: KibuoColors.ink,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
