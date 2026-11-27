import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/obligations/debt_list.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/overview/worth.dart';
import 'package:kibuo/domain/transactions/entry_total.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/overview/account_page.dart';
import 'package:kibuo/ui/overview/enlarged_parts.dart';
import 'package:kibuo/ui/overview/followed_section.dart';
import 'package:kibuo/ui/overview/overview_labels.dart';
import 'package:kibuo/ui/recurrences/planned_operation.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// The Aperçu's Patrimoine tab (canvas ApercuP2, PRODUCT, 27 November
/// 2026): what I have and its curve over the period, dotted ahead with
/// what is planned; what it is made of; what each account did.
class WorthTab extends StatefulWidget {
  const WorthTab({
    super.key,
    required this.data,
    required this.followed,
    required this.kind,
    required this.offset,
    required this.span,
    required this.bars,
    required this.grouping,
    required this.startDay,
    required this.now,
    required this.main,
    required this.rates,
    required this.periodLabel,
  });

  final EntryData data;
  final FollowedData followed;
  final PeriodKind kind;
  final int offset;
  final TimeSpan span;
  final List<TimeSpan> bars;
  final Grouping grouping;
  final int startDay;
  final DateTime now;
  final CurrencyInfo main;
  final Map<String, ExchangeRate> rates;

  /// Under an account's name, on its page.
  final String periodLabel;

  @override
  State<WorthTab> createState() => _WorthTabState();
}

class _WorthTabState extends State<WorthTab> {
  /// What the recurrences will do to the worth until the period's end.
  List<WorthChange> _planned = const [];
  TimeSpan? _plannedFor;

  bool get _running => widget.span.contains(widget.now);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPlanned();
  }

  @override
  void didUpdateWidget(WorthTab old) {
    super.didUpdateWidget(old);
    _loadPlanned();
  }

  int _inMain(Money m) {
    final flow = MoneyFlow(incoming: Money(m.minor.abs(), m.currency));
    final value = flowTotals(widget.main, [
      flow,
    ], (c) => widget.rates[c]).entries.minor;
    return m.minor < 0 ? -value : value;
  }

  Future<void> _loadPlanned() async {
    if (!_running) {
      if (_planned.isNotEmpty) setState(() => _planned = const []);
      return;
    }
    if (_plannedFor == widget.span) return;
    _plannedFor = widget.span;
    final last = widget.span.end.subtract(const Duration(seconds: 1));
    final planned =
        await widget.data.recurrences?.planned(now: widget.now, until: last) ??
        const [];
    final changes = <WorthChange>[];
    for (final p in planned) {
      final t = plannedOperation(p);
      // Money in or out changes the worth; a transfer only by its fees.
      final change = switch (t.kind) {
        EntryKind.income => _inMain(t.total.total),
        EntryKind.expense => -_inMain(t.total.total),
        EntryKind.transfer => -_inMain(t.total.fees),
      };
      if (change != 0) changes.add((at: p.day, change: change));
    }
    if (mounted) setState(() => _planned = changes);
  }

  /// An account over the period (variant B, canvas CompteB).
  void _openAccount(String id, String name) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => AccountPage(
        data: widget.data,
        accountId: id,
        name: name,
        periodLabel: widget.periodLabel,
        kind: widget.kind,
        offset: widget.offset,
        span: widget.span,
        bars: widget.bars,
        grouping: widget.grouping,
        startDay: widget.startDay,
        now: widget.now,
      ),
    ),
  );

  String _money(int minor, {bool signed = false}) {
    final lang = Localizations.localeOf(context).languageCode;
    final text = formatMoney(
      Money(minor.abs(), widget.main.code),
      widget.main,
      lang,
    );
    if (!signed) return minor < 0 ? '−$text' : text;
    return minor == 0 ? text : '${minor < 0 ? '−' : '+'}$text';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final data = widget.followed;
    var owed = 0;
    var owe = 0;
    for (final d in data.debts) {
      final v = _inMain(d.left);
      if (d.direction == DebtDirection.owed) {
        owed += v;
      } else {
        owe += v;
      }
    }
    final net = data.accountsTotal + owed - owe;
    final now = widget.now;
    final changes = data.worthChanges;
    final shownAt = _running ? now : widget.span.end;
    final figure = worthAt([shownAt], current: net, changes: changes).single;
    final change = worthChange(
      widget.span,
      current: net,
      changes: changes,
      now: now,
    );
    // The curve: the period's start, then each bar's end (now for the bar
    // running); ahead, dotted, what is planned.
    final begun = [
      for (final b in widget.bars)
        if (!b.start.isAfter(now)) b,
    ];
    final solid = worthAt(
      [
        widget.span.start,
        for (final b in begun) b.end.isAfter(now) ? now : b.end,
      ],
      current: net,
      changes: changes,
    );
    final ahead = _running
        ? projectedAt(
            [
              for (final b in widget.bars)
                if (b.end.isAfter(now)) b.end,
            ],
            from: net,
            now: now,
            planned: _planned,
          )
        : const <int>[];
    final axis = curveAxis(
      l,
      lang,
      widget.bars,
      widget.grouping,
      startDay: widget.startDay,
      today: _running ? now : null,
    );
    // Today's date stands under its line, at the solid line's last point.
    final points = solid.length + ahead.length;
    final at = _running && points > 1
        ? (solid.length - 1) / (points - 1)
        : widget.bars.length <= 1
        ? 0.0
        : (begun.length - 1) / (widget.bars.length - 1);

    // What it is made of, today.
    final available = data.accountsTotal - data.reserved;
    final parts = [
      (
        label: l.accountsAvailable,
        value: available,
        color: KibuoColors.mint,
        ink: KibuoColors.ink,
      ),
      (
        label: l.accountsReserved,
        value: data.reserved,
        color: KibuoColors.projectLine,
        ink: KibuoColors.projectInk,
      ),
      (
        label: l.debtsOwed,
        value: owed,
        color: KibuoColors.accentDash,
        ink: KibuoColors.accent,
      ),
      (
        label: l.debtsOwe,
        value: -owe,
        color: KibuoColors.debtLine,
        ink: KibuoColors.debtInk,
      ),
    ];
    final whole = parts.fold(0, (a, p) => a + p.value.abs());

    // What each account did over the period, the biggest change first.
    final byAccount =
        accountChanges(
            widget.span,
            data.accountMoves,
          ).entries.where((e) => e.value != 0).toList()
          ..sort((a, b) => b.value.abs() - a.value.abs());

    final changeColor = change < 0 ? KibuoColors.debtInk : KibuoColors.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          children: [
            Text(l.worthWhat, style: KibuoType.caption.copyWith(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _money(figure),
                      style: KibuoType.bigAmount.copyWith(fontSize: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_money(change, signed: true)} '
                  '${worthWhen(l, lang, widget.kind, widget.offset, widget.span, running: _running)}',
                  style: KibuoType.caption
                      .copyWith(fontSize: 13, color: changeColor)
                      .copyWith(
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation.weight(700)],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            WorthCurve(solid: solid, ahead: ahead, today: _running),
            const SizedBox(height: 6),
            AxisLabels(axis, at: at, strong: _running),
            if (ahead.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l.worthProjected,
                style: KibuoType.caption.copyWith(fontSize: 12),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        _Card(
          children: [
            Text(
              _running ? l.worthMadeOf : l.worthMadeOfToday,
              style: KibuoType.cardTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 10),
            if (whole > 0)
              SplitBar(
                height: 12,
                parts: [
                  for (final p in parts)
                    if (p.value != 0)
                      (share: p.value.abs() / whole, color: p.color),
                ],
              ),
            const SizedBox(height: 6),
            for (final p in parts)
              _PartRow(
                color: p.color,
                label: p.label,
                value:
                    p.label == l.accountsAvailable ||
                        p.label == l.accountsReserved
                    ? _money(p.value)
                    : _money(p.value, signed: true),
                ink: p.ink,
              ),
          ],
        ),
        const SizedBox(height: 14),
        _Card(
          children: [
            Text(
              l.worthAccounts,
              style: KibuoType.cardTitle.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 6),
            if (byAccount.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l.worthNoMove,
                  style: KibuoType.body.copyWith(
                    color: KibuoColors.inkSecondary,
                  ),
                ),
              ),
            for (final MapEntry(key: id, value: v) in byAccount)
              _AccountRow(
                name: data.accountNames[id] ?? '',
                value: _money(v, signed: true),
                ink: v < 0 ? KibuoColors.debtInk : KibuoColors.accent,
                onTap: () => _openAccount(id, data.accountNames[id] ?? ''),
              ),
          ],
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// A part of the worth: its dot, its name, its amount.
class _PartRow extends StatelessWidget {
  const _PartRow({
    required this.color,
    required this.label,
    required this.value,
    required this.ink,
  });

  final Color color;
  final String label;
  final String value;
  final Color ink;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 34),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: KibuoType.body)),
        Text(
          value,
          style: KibuoType.itemName.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation.weight(700)],
            color: ink,
          ),
        ),
      ],
    ),
  );
}

/// An account and what it gained or lost over the period.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.name,
    required this.value,
    required this.ink,
    required this.onTap,
  });

  final String name;
  final String value;
  final Color ink;

  /// Opens the account's page.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 34),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KibuoType.body,
            ),
          ),
          Text(
            value,
            style: KibuoType.itemName.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation.weight(700)],
              color: ink,
            ),
          ),
        ],
      ),
    ),
  );
}

/// The worth over the period: a green line up to now, then dotted ahead
/// (canvas ApercuP2).
class WorthCurve extends StatelessWidget {
  const WorthCurve({
    super.key,
    required this.solid,
    required this.ahead,
    this.slots,
    this.today = false,
  });

  /// Marks the last point of [solid], today: a light line from top to
  /// bottom and a dot on the curve (J3, 27 November 2026).
  final bool today;

  /// From the period's start to now.
  final List<int> solid;

  /// From now to the period's end, planned.
  final List<int> ahead;

  /// How many points the whole width holds, the period's start and each
  /// bar's end; by default, the points given. Without [ahead], the line
  /// stops under today.
  final int? slots;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 96,
      child: CustomPaint(
        painter: _WorthPainter(
          solid,
          ahead,
          slots ?? solid.length + ahead.length,
          today,
        ),
      ),
    ),
  );
}

class _WorthPainter extends CustomPainter {
  _WorthPainter(this.solid, this.ahead, this.slots, this.today);

  final List<int> solid;
  final List<int> ahead;
  final int slots;
  final bool today;

  @override
  void paint(Canvas canvas, Size size) {
    if (solid.isEmpty) return;
    final all = [...solid, ...ahead];
    final top = all.reduce(math.max);
    final low = all.reduce(math.min);
    final span = math.max(1, top - low);
    final n = math.max(2, math.max(slots, all.length));
    double x(int i) => i * size.width / (n - 1);
    double y(int v) => 6 + (size.height - 12) * (1 - (v - low) / span);
    final line = Paint()
      ..color = KibuoColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final solidPoints = [
      for (final (i, v) in solid.indexed) Offset(x(i), y(v)),
    ];
    final now = solidPoints.last;
    if (today) {
      canvas.drawLine(
        Offset(now.dx, 0),
        Offset(now.dx, size.height),
        Paint()
          ..color = KibuoColors.ink.withValues(alpha: 0.14)
          ..strokeWidth = 2,
      );
    }
    if (solidPoints.length > 1) {
      canvas.drawPath(smoothPath(solidPoints), line);
    }
    if (today) {
      canvas.drawCircle(now, 5.5, Paint()..color = KibuoColors.surface);
      canvas.drawCircle(now, 4.5, Paint()..color = KibuoColors.accent);
    }
    if (ahead.isEmpty) return;
    final aheadPoints = [
      solidPoints.last,
      for (final (i, v) in ahead.indexed) Offset(x(solid.length + i), y(v)),
    ];
    final dotted = smoothPath(aheadPoints);
    for (final PathMetric metric in dotted.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 4, metric.length)),
          line,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_WorthPainter old) => true;
}
