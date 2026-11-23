import 'dart:ui' show ImageFilter, PathMetric;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/empty_card.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/money/money_format.dart';
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
    this.now = DateTime.now,
    this.onChanged,
  });

  final EntryData data;
  final DebtRepository debts;
  final PreferenceStore prefs;
  final DateTime Function() now;

  /// A debt was saved: its money may have reached a list.
  final VoidCallback? onChanged;

  static const groupingKey = 'debts_grouping';
  static const paidKey = 'debts_paid_place';

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  DebtDirection _tab = DebtDirection.owe;
  List<DebtLine>? _lines;
  DebtGrouping _grouping = DebtGrouping.due;
  PaidPlace _paidPlace = PaidPlace.inline;
  String? _open;
  bool _paidShown = false;

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
      _main = main;
      _rates = rates;
    });
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  String _money(Money m) => formatMoney(m, currencyOf(m.currency), _lang);

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
    final text = _money(Money(sum, main));
    return about ? AppLocalizations.of(context).debtsAbout(text) : text;
  }

  Future<void> _add() async {
    final saved = await Navigator.of(context).push<DebtDirection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NewDebtScreen(
          data: widget.data,
          debts: widget.debts,
          direction: _tab,
          now: widget.now,
        ),
      ),
    );
    if (saved == null || !mounted) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _tab = saved;
      _open = null;
    });
    showKibuoToast(
      context,
      saved == DebtDirection.owe ? l.debtSavedOwe : l.debtSavedOwed,
    );
    widget.onChanged?.call();
    await _load();
  }

  Future<void> _display() async {
    final l = AppLocalizations.of(context);
    await showKibuoSheet<void>(
      context,
      title: l.listDisplay,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          void pick({DebtGrouping? grouping, PaidPlace? paid}) {
            setState(() {
              _grouping = grouping ?? _grouping;
              _paidPlace = paid ?? _paidPlace;
              _open = null;
            });
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

  void _toggle(String id) => setState(() => _open = _open == id ? null : id);

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
    return Scaffold(
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
      floatingActionButton: dim
          ? null
          : _AddButton(label: l.debtsAdd, onTap: _add),
      body: lines == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                _Dimmed(
                  on: dim,
                  child: Row(
                    children: [
                      for (final d in DebtDirection.values) ...[
                        if (d == DebtDirection.owed) const SizedBox(width: 10),
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
                      onTap: () => setState(() => _paidShown = !_paidShown),
                    ),
                  ),
                  if (_paidShown) ...[
                    const SizedBox(height: 8),
                    _card(l, listing.paid, now),
                  ],
                ],
              ],
            ),
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
        onTap: () => setState(() {
          _tab = d;
          _open = null;
        }),
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

  /// One white card for a group's lines.
  Widget _card(AppLocalizations l, List<DebtLine> lines, DateTime now) {
    final hasOpen = lines.any((d) => d.id == _open);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
                  vertical: 8,
                ),
                child: Container(
                  height: 1,
                  color: d.id == _open || lines[i - 1].id == _open
                      ? Colors.transparent
                      : KibuoColors.background,
                ),
              ),
            _Dimmed(
              on: _open != null && d.id != _open,
              blur: hasOpen,
              child: _DebtRow(
                line: d,
                now: now,
                open: d.id == _open,
                amount: _money(d.left),
                details: d.id == _open ? _details(l, d, now) : null,
                onTap: () => _toggle(d.id),
              ),
            ),
          ],
        ],
      ),
    );
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
        ? l.debtAboutLine(_money(main.$1))
        : paid.minor <= 0
        ? (owe ? l.debtNothingRepaid : l.debtNothingReceived)
        : owe
        ? l.debtRepaidLine(_money(paid), _money(d.amount))
        : l.debtReceivedLine(_money(paid), _money(d.amount));
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
                  '${_money(paid)} / ${_money(d.amount)}',
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
        ],
      ),
    );
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
      final ago = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).difference(DateTime.utc(on.year, on.month, on.day)).inDays;
      return d.direction == DebtDirection.owe
          ? l.debtWordSettled(ago)
          : l.debtWordReceived(ago);
    }(),
  };
}

/// A line: the due day in its ringed square, the name, the words, what is
/// left, ˅. Open, it lifts and shows [details] above.
class _DebtRow extends StatelessWidget {
  const _DebtRow({
    required this.line,
    required this.now,
    required this.open,
    required this.amount,
    required this.onTap,
    this.details,
  });

  final DebtLine line;
  final DateTime now;
  final bool open;
  final String amount;
  final Widget? details;
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(horizontal: open ? 6 : 14),
      padding: EdgeInsets.all(open ? 8 : 0),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: open
            ? const [
                BoxShadow(
                  color: Color(0x240E1320),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          if (details case final details?) ...[
            details,
            const SizedBox(height: 8),
          ],
          row,
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

/// Lines and blocks behind an open line: faded and blurred.
class _Dimmed extends StatelessWidget {
  const _Dimmed({required this.on, required this.child, this.blur = true});

  final bool on;
  final bool blur;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity: on ? 0.6 : 1,
    child: on && blur
        ? ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: child,
          )
        : child,
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

/// The + at the bottom right (canvas DettesListeDois): 62, mint, 20 round.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: KibuoColors.mint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: const SizedBox(
          width: 62,
          height: 62,
          child: Icon(KibuoIcons.plusBold, size: 26, color: KibuoColors.ink),
        ),
      ),
    ),
  );
}
