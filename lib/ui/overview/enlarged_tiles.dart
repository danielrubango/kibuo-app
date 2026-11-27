import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/domain/budgets/budget_curve.dart';
import 'package:kibuo/domain/calendar.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/obligations/debt_list.dart';
import 'package:kibuo/domain/overview/followed.dart';
import 'package:kibuo/domain/overview/overview_choice.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/overview/overview_totals.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/page_veil.dart';
import 'package:kibuo/ui/kit/spent_bar.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/overview/enlarged_parts.dart';
import 'package:kibuo/ui/overview/evolution_chart.dart';
import 'package:kibuo/ui/overview/followed_section.dart';
import 'package:kibuo/ui/overview/followed_tile.dart';
import 'package:kibuo/ui/overview/overview_labels.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Opens the followed tiles enlarged over the blurred Aperçu, on [tiles]
/// at [initial] (PRODUCT, DIRECTION, 27 November 2026).
Future<void> openEnlarged(
  BuildContext context, {
  required List<Followed> tiles,
  required int initial,
  required FollowedPeriod period,
  required FollowedData data,
  required BudgetBook? book,
  required FollowedChoice choice,
  required FollowedLinks links,
}) {
  final l = AppLocalizations.of(context);
  final lang = Localizations.localeOf(context).languageCode;
  return Navigator.of(context).push<void>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (routeContext, animation, _) {
        void close() => Navigator.of(routeContext).maybePop();
        void then(VoidCallback? go) {
          if (go == null) return;
          Navigator.of(routeContext).pop();
          go();
        }

        final build = EnlargedTiles(
          l,
          lang,
          period,
          data,
          book,
          choice,
          links,
          close: close,
          then: then,
        );
        // Behind the tiles, the screen blurred: the blur comes at once,
        // only its veil and the cards fade (DIRECTION « Derrière ce qui
        // passe devant »).
        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, _) =>
                    PageVeil(veil: animation.value, blurred: true),
              ),
            ),
            FadeTransition(
              opacity: animation,
              child: Material(
                type: MaterialType.transparency,
                child: EnlargedPager(
                  count: tiles.length,
                  initial: initial,
                  hint: l.enlHint,
                  card: (_, i) => build.card(tiles[i]),
                ),
              ),
            ),
          ],
        );
      },
      transitionsBuilder: (_, _, _, child) => child,
    ),
  );
}

/// What each enlarged tile shows, as chosen tile by tile on the canvas
/// (DIRECTION, 27 November 2026).
class EnlargedTiles {
  EnlargedTiles(
    this.l,
    this.lang,
    this.p,
    this.data,
    this.book,
    this.choice,
    this.links, {
    required this.close,
    required this.then,
  });

  final AppLocalizations l;
  final String lang;
  final FollowedPeriod p;
  final FollowedData data;
  final BudgetBook? book;
  final FollowedChoice choice;
  final FollowedLinks links;
  final VoidCallback close;

  /// Closes the tiles, then goes where an action leads.
  final void Function(VoidCallback? go) then;

  static const _spentLine = Color(0xFFC9874E);

  String money(int minor, {String? code}) {
    final m = Money(minor, code ?? p.main.code);
    return formatAmount(m, currencyOf(m.currency), lang);
  }

  String signed(int minor, {String? code}) => minor == 0
      ? money(0, code: code)
      : '${minor < 0 ? '−' : '+'}${money(minor.abs(), code: code)}';

  /// Whole units, for a chart's label (« −273 $ »).
  String round(int minor, {String? code}) {
    final text = roundUnsigned(minor.abs(), code: code);
    return minor == 0 ? text : '${minor < 0 ? '−' : '+'}$text';
  }

  String roundUnsigned(int minor, {String? code}) {
    final m = Money(minor, code ?? p.main.code);
    return formatMoney(m, currencyOf(m.currency).withDecimals(false), lang);
  }

  int inMain(Money m) {
    if (m.currency == p.main.code) return m.minor;
    final rate = p.rates[m.currency];
    if (rate == null) return 0;
    final sign = m.minor < 0 ? -1 : 1;
    return sign *
        rate.convert(Money(m.minor.abs(), m.currency), to: p.main).minor;
  }

  String _cap(String t) => capitalized(t);

  String _lower(String t) =>
      t.isEmpty ? t : t[0].toLowerCase() + t.substring(1);

  DateTime get _today => DateTime(p.now.year, p.now.month, p.now.day);

  VoidCallback _operations([String? category]) =>
      () => then(
        links.operations == null
            ? null
            : () => links.operations!(p.budgetMonth, category),
      );

  String _day(DateTime d) =>
      withFirst(DateFormat.MMMd(lang).format(d), d, lang);

  /// « samedi 9 nov. »
  String _weekday(DateTime d) =>
      withFirst(DateFormat('EEEE d MMM', lang).format(d), d, lang);

  /// « Samedi 7 »
  String _dayName(DateTime d) =>
      _cap(withFirst(DateFormat('EEEE d', lang).format(d), d, lang));

  /// The day the chart has reached: today, or the period's last day.
  DateTime get _reached =>
      p.running ? p.now : p.span.end.subtract(const Duration(seconds: 1));

  /// Where the day's line stands on a curve of the period, from 0 to 1.
  double get _dayAt =>
      p.bars.length <= 1 ? 0 : (p.begun.length - 1) / (p.bars.length - 1);

  /// The day the curve has reached, on its label.
  String get _reachedMark => p.grouping == Grouping.hour
      ? l.overviewHourMark(_reached.hour)
      : _day(_reached);

  /// Days under a curve: « 1er · 12 nov. · 30 » while it runs, « 1er ·
  /// 30 nov. » once over (canvas TuileDepenseA, TuileDepenseA3).
  List<String> _dayAxis(DateTime first, DateTime last, DateTime? today) {
    final middle =
        today != null &&
        calendarDays(first, today) > 0 &&
        calendarDays(today, last) > 0;
    final same = first.year == last.year && first.month == last.month;
    return [
      same ? l.enlAxisDay(first.day) : _day(first),
      if (middle) _day(today),
      same && middle ? '${last.day}' : _day(last),
    ];
  }

  List<String> get _axis {
    final first = p.bars.first.start;
    final last = p.bars.last.start;
    final today = p.running ? p.now : null;
    if (p.grouping == Grouping.day) return _dayAxis(first, last, today);
    String mark(DateTime d) => switch (p.grouping) {
      Grouping.hour => l.overviewHourMark(d.hour),
      Grouping.month => DateFormat.MMM(
        lang,
      ).format(BudgetPeriod.containing(d, startDay: p.startDay).month),
      _ => _day(d),
    };
    final at = today == null ? -1 : p.bars.indexWhere((b) => b.contains(today));
    return [
      mark(first),
      if (at > 0 && at < p.bars.length - 1) mark(today!),
      mark(last),
    ];
  }

  /// The change line under the figure, or a note.
  Widget? _change(
    int figure,
    int? compared, {
    required bool lessIsBetter,
    String? text,
  }) {
    final name = p.comparedName;
    if (compared == null || name == null) return null;
    final change = changeOf(figure, compared, lessIsBetter: lessIsBetter);
    final atDate =
        text ??
        l.enlAtThisDate(
          name,
          lessIsBetter ? signed(-compared) : signed(compared),
        );
    if (change == null) return CardNote(atDate);
    final color = change.good ? KibuoColors.accent : KibuoColors.warningInk;
    return Row(
      children: [
        CustomPaint(
          size: const Size.square(14),
          painter: TrendArrow(up: change.up, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          '${change.percent} %',
          style: KibuoType.caption.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontVariations: const [FontVariation.weight(600)],
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '· $atDate',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KibuoType.caption.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget card(Followed f) => switch (f) {
    Followed.spent => _flow(out: true),
    Followed.received => _flow(out: false),
    Followed.savings => _savings(),
    Followed.average => _average(),
    Followed.topCategory => _categories(),
    Followed.priciest => _priciest(),
    Followed.upcoming => _upcoming(),
    Followed.budget => _budget(),
    Followed.debts => _debts(DebtDirection.owe),
    Followed.receivables => _debts(DebtDirection.owed),
    Followed.project => _project(),
    Followed.accounts => _accounts(),
    Followed.netWorth => _worth(),
  };

  List<FlowTotals> get _begun =>
      totalsByBucket(p.begun, p.flows, p.main, p.rateFor);

  /// Dépensé and Reçu: the running curve against the compared period, or a
  /// bar a day when « Affichage » says so.
  Widget _flow({required bool out}) {
    int pick(FlowTotals t) => out ? t.exits.minor : t.entries.minor;
    final total = pick(p.totals);
    final color = out ? _spentLine : KibuoColors.accent;
    final tint = out ? KibuoColors.debtTint : KibuoColors.accentTint;
    final compared = p.comparedBars;
    final values = [for (final t in _begun) pick(t)];
    final Widget picture;
    if (choice.bars) {
      picture = EvolutionChart(
        values: [
          for (final t in totalsByBucket(p.bars, p.flows, p.main, p.rateFor))
            pick(t),
        ],
        ahead: [for (final b in p.bars) b.start.isAfter(p.now)],
        marks: [
          for (var i = 0; i < p.bars.length; i++)
            barMark(
              l,
              lang,
              p.kind,
              p.grouping,
              p.bars,
              i,
              startDay: p.startDay,
            ),
        ],
        out: out,
        currentName: p.label,
        compared: compared == null ? null : [for (final t in compared) pick(t)],
        comparedName: p.comparedName == null ? null : _cap(p.comparedName!),
        comparedAs: ComparedAs.sticks,
      );
    } else {
      picture = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DayLineChart(
            current: runningTotal(values),
            compared: compared == null
                ? null
                : runningTotal([for (final t in compared) pick(t)]),
            points: p.bars.length,
            color: color,
            tint: tint,
            dayLabel: '$_reachedMark · ${out ? round(-total) : round(total)}',
            pill: tint,
            pillInk: out ? KibuoColors.debtInk : KibuoColors.accent,
          ),
          const SizedBox(height: 6),
          AxisLabels(_axis, at: _dayAt),
          const SizedBox(height: 8),
          ChartLegend(
            color: color,
            name: p.label,
            comparedName: compared == null || p.comparedName == null
                ? null
                : '${_cap(p.comparedName!)} ${round((out ? -1 : 1) * [for (final t in compared) pick(t)].fold(0, (a, b) => a + b))}',
          ),
        ],
      );
    }
    final List<Landmark> marks;
    if (out) {
      final perDay = averageOf(
        p.span,
        p.flows,
        unit: Grouping.day,
        now: p.now,
        main: p.main,
        rateFor: p.rateFor,
      );
      final window = p.comparedWindow;
      final comparedDay = window == null || perDay.units == 0
          ? null
          : (totalsWithin(window, p.flows, p.main, p.rateFor).exits.minor /
                    perDay.units)
                .round();
      final days = bucketsOf(p.span, Grouping.day);
      final top = priciest(days, p.flows, main: p.main, rateFor: p.rateFor);
      final category = topCategory(
        p.span,
        data.spends,
        parentOf: (id) => data.parents[id] ?? id,
        exits: total,
        main: p.main,
        rateFor: p.rateFor,
      );
      marks = [
        landmark(
          l.followedAverageDay,
          money(perDay.amount),
          comparedDay == null || p.comparedName == null
              ? ''
              : l.enlPeriodValue(p.comparedName!, money(comparedDay)),
        ),
        if (top != null)
          landmark(
            l.followedPriciestDay,
            signed(-top.amount),
            _weekday(days[top.index].start),
          ),
        if (category != null && data.categories[category.category] != null)
          landmark(
            l.enlWhereMost,
            categoryName(l, data.categories[category.category]!),
            l.enlOfExits(signed(-category.amount), category.share),
          ),
      ];
    } else {
      final big = biggest(p.span, data.gains, main: p.main, rateFor: p.rateFor);
      final from = topCategory(
        p.span,
        data.gains,
        parentOf: (id) => data.parents[id] ?? id,
        exits: total,
        main: p.main,
        rateFor: p.rateFor,
      );
      int count(TimeSpan span) => p.flows
          .where(
            (f) => span.contains(f.at) && (f.flow.incoming?.minor ?? 0) > 0,
          )
          .length;
      final window = p.comparedWindow;
      marks = [
        if (big != null)
          landmark(
            l.enlBiggestEntry,
            signed(big.amount),
            [
              if (data.categories[big.category] case final c?)
                categoryName(l, c),
              _day(big.at),
            ].join(' · '),
            color: KibuoColors.accent,
          ),
        if (from != null && data.categories[from.category] != null)
          landmark(
            l.enlWhereFrom,
            categoryName(l, data.categories[from.category]!),
            l.enlOfEntries(from.share),
          ),
        landmark(
          l.enlEntriesCount,
          '${count(p.span)}',
          window == null || p.comparedName == null
              ? ''
              : l.enlAtThisDate(p.comparedName!, '${count(window)}'),
        ),
      ];
    }
    return EnlargedCard(
      title: '${out ? l.followedSpent : l.followedReceived} · ${p.label}',
      figure: total == 0 ? money(0) : (out ? signed(-total) : signed(total)),
      figureColor: total == 0
          ? KibuoColors.inkMuted
          : (out ? KibuoColors.debtInk : KibuoColors.accent),
      line: _change(
        total,
        out ? p.compared?.exits.minor : p.compared?.entries.minor,
        lessIsBetter: out,
      ),
      action: l.enlSeeOperations,
      onAction: _operations(),
      onClose: close,
      children: [picture, LandmarkRows(marks)],
    );
  }

  Widget _savings() {
    final entries = p.totals.entries.minor;
    final exits = p.totals.exits.minor;
    final saved = entries - exits;
    final share = savedShare(entries: entries, exits: exits);
    final compared = p.comparedBars;
    final Widget picture = choice.bars
        ? NetBars(
            values: [
              for (final t in totalsByBucket(
                p.bars,
                p.flows,
                p.main,
                p.rateFor,
              ))
                t.rest.minor,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DayLineChart(
                current: runningTotal([for (final t in _begun) t.rest.minor]),
                compared: compared == null
                    ? null
                    : runningTotal([for (final t in compared) t.rest.minor]),
                points: p.bars.length,
                color: KibuoColors.accent,
                tint: KibuoColors.accentTint,
                dayLabel: '$_reachedMark · ${round(saved)}',
                pill: KibuoColors.accentTint,
                pillInk: KibuoColors.accent,
              ),
              const SizedBox(height: 6),
              AxisLabels(_axis, at: _dayAt),
              const SizedBox(height: 8),
              ChartLegend(
                color: KibuoColors.accent,
                name: p.label,
                comparedName: compared == null || p.comparedName == null
                    ? null
                    : '${_cap(p.comparedName!)} ${round([for (final t in compared) t.rest.minor].fold(0, (a, b) => a + b))}',
              ),
            ],
          );
    final window = p.comparedWindow;
    final comparedRest = window == null
        ? null
        : totalsWithin(window, p.flows, p.main, p.rateFor).rest.minor;
    return EnlargedCard(
      title:
          '${p.kind == PeriodKind.year ? l.followedSavingsYear : l.followedSavings}'
          ' · ${p.label}',
      figure: signed(saved),
      figureColor: saved < 0 ? KibuoColors.debtInk : KibuoColors.accent,
      badge: share == null || share <= 0 ? null : CardBadge(l.enlKept(share)),
      line: comparedRest == null || p.comparedName == null
          ? CardNote(l.followedSavingsDetail)
          : CardNote(l.enlAtThisDate(p.comparedName!, signed(comparedRest))),
      action: l.enlSeeOperations,
      onAction: _operations(),
      onClose: close,
      children: [
        picture,
        LandmarkRows([
          landmark(
            l.overviewEntries,
            signed(entries),
            p.inlineLabel,
            color: KibuoColors.accent,
          ),
          landmark(
            l.overviewExits,
            signed(-exits),
            p.inlineLabel,
            color: KibuoColors.debtInk,
          ),
          if (share != null)
            landmark(
              l.enlSavedShare,
              '$share %',
              l.enlOfEntriesShort,
              lead: MiniRing(share: share / 100),
            ),
        ]),
      ],
    );
  }

  Grouping get _averageUnit => switch (p.scale) {
    PeriodScale.month => Grouping.week,
    PeriodScale.long => Grouping.month,
    _ => Grouping.day,
  };

  String _units(int count) => switch (_averageUnit) {
    Grouping.week => l.enlWeeks(count),
    Grouping.month => l.enlMonths(count),
    _ => l.enlDays(count),
  };

  String _unitName(int index, DateTime start) => switch (_averageUnit) {
    Grouping.week => '${l.overviewWeekMark(index + 1)} · ${_day(start)}',
    Grouping.month => _cap(
      DateFormat.MMMM(lang)
          .format(BudgetPeriod.containing(start, startDay: p.startDay).month),
    ),
    _ => _weekday(start),
  };

  Widget _average() {
    final unit = _averageUnit;
    final TimeSpan span;
    if (p.scale == PeriodScale.day) {
      final today = DateTime(_reached.year, _reached.month, _reached.day);
      span = TimeSpan(DateTime(today.year, today.month, today.day - 30), today);
    } else {
      span = p.span;
    }
    final units = [
      for (final b in bucketsOf(span, unit, startDay: p.startDay))
        if (!b.start.isAfter(p.now)) b,
    ];
    final values = [
      for (final t in totalsByBucket(units, p.flows, p.main, p.rateFor))
        t.exits.minor,
    ];
    final avg = values.isEmpty
        ? 0
        : (values.fold(0, (a, b) => a + b) / values.length).round();
    final spread = values.isEmpty ? null : spreadOf(values, average: avg);
    final window = p.comparedWindow;
    final comparedAvg = window == null || values.isEmpty
        ? null
        : (totalsWithin(window, p.flows, p.main, p.rateFor).exits.minor /
                  values.length)
              .round();
    final step = values.length <= 7 ? 1 : (values.length <= 14 ? 3 : 5);
    final name = switch (unit) {
      Grouping.week => l.followedAverageWeek,
      Grouping.month => l.followedAverageMonth,
      _ => l.followedAverageDay,
    };
    return EnlargedCard(
      title: '$name · ${p.label}',
      figure: avg == 0 ? money(0) : signed(-avg),
      figureColor: avg == 0 ? KibuoColors.inkMuted : KibuoColors.debtInk,
      line: p.scale == PeriodScale.day
          ? CardNote(l.followedOverDays(30))
          : _change(
              avg,
              comparedAvg,
              lessIsBetter: true,
              text: comparedAvg == null || p.comparedName == null
                  ? null
                  : l.enlComparedPer(
                      p.comparedName!,
                      money(comparedAvg),
                      unit.name,
                    ),
            ),
      action: l.enlSeeOperations,
      onAction: _operations(),
      onClose: close,
      children: [
        AverageBars(
          values: values,
          average: avg,
          marks: [
            for (final (i, u) in units.indexed)
              i % step == 0 || i == units.length - 1
                  ? (unit == Grouping.month
                        ? DateFormat.MMM(lang).format(
                            BudgetPeriod.containing(
                              u.start,
                              startDay: p.startDay,
                            ).month,
                          )
                        : unit == Grouping.week
                        ? l.overviewWeekMark(i + 1)
                        : '${u.start.day}')
                  : null,
          ],
        ),
        if (spread != null)
          LandmarkRows([
            landmark(
              l.enlHighest,
              signed(-values[spread.highest]),
              _unitName(spread.highest, units[spread.highest].start),
            ),
            if (spread.lowest case final low?)
              landmark(
                l.enlLowest,
                signed(-values[low]),
                _unitName(low, units[low].start),
              ),
            landmark(
              l.enlAboveAverage,
              _units(spread.above),
              l.enlOutOf(values.length),
            ),
          ]),
      ],
    );
  }

  Widget _categories() {
    final exits = p.totals.exits.minor;
    final all = topCategories(
      p.span,
      data.spends,
      parentOf: (id) => data.parents[id] ?? id,
      exits: exits,
      main: p.main,
      rateFor: p.rateFor,
      count: 1000,
    );
    final top = all.take(3).toList();
    final first = top.isEmpty ? null : data.categories[top.first.category];
    final restShare = 100 - top.fold<int>(0, (a, c) => a + c.share);
    final restCount = all.length - top.length;
    return EnlargedCard(
      title:
          '${p.scale == PeriodScale.day ? l.followedTopCategoryDay : l.followedTopCategory}'
          ' · ${p.label}',
      figure: first == null ? l.followedNoExit : categoryName(l, first),
      figureColor: first == null ? KibuoColors.inkMuted : KibuoColors.ink,
      line: top.isEmpty
          ? null
          : CardNote(l.enlOfExits(signed(-top.first.amount), top.first.share)),
      action: first == null
          ? l.enlSeeOperations
          : l.enlSeeCategory(categoryName(l, first)),
      onAction: _operations(top.isEmpty ? null : top.first.category),
      onClose: close,
      children: [
        if (top.isNotEmpty)
          RankedBars(
            color: KibuoColors.debtLine,
            items: [
              for (final c in top)
                (
                  name: data.categories[c.category] == null
                      ? '—'
                      : categoryName(l, data.categories[c.category]!),
                  value: signed(-c.amount),
                  sub: '${c.share} %',
                  share: top.first.amount == 0
                      ? 0
                      : c.amount / top.first.amount,
                ),
            ],
          ),
        if (restCount > 0) CardNote(l.enlRest(restShare, restCount)),
      ],
    );
  }

  /// Jour le plus cher as a calendar with amounts (K2), by the period's
  /// scale: hours, days, the month, or months.
  Widget _priciest() {
    final unit = switch (p.scale) {
      PeriodScale.day => Grouping.hour,
      PeriodScale.long => Grouping.month,
      _ => Grouping.day,
    };
    final cells = bucketsOf(p.span, unit, startDay: p.startDay);
    final values = [
      for (final t in totalsByBucket(cells, p.flows, p.main, p.rateFor))
        t.exits.minor,
    ];
    final top = topIndexes(values, 3);
    final digits = p.main.digits;
    final number = NumberFormat.decimalPatternDigits(
      locale: lang,
      decimalDigits: 0,
    );
    String short(int minor) {
      final major = minor / math.pow(10, digits);
      return major >= 100 || major == major.roundToDouble()
          ? number.format(major.round())
          : NumberFormat('#,##0.#', lang).format(major);
    }

    final ahead = {
      for (final (i, c) in cells.indexed)
        if (c.start.isAfter(p.now)) i,
    };
    final List<String> labels;
    var columns = 7;
    var lead = 0;
    List<String>? header;
    var height = 42.0;
    switch (p.scale) {
      case PeriodScale.day:
        labels = [for (final c in cells) l.overviewHourMark(c.start.hour)];
        columns = 6;
        height = 40;
      case PeriodScale.week:
        labels = [
          for (final c in cells)
            '${DateFormat.E(lang).format(c.start).substring(0, 1).toUpperCase()} ${c.start.day}',
        ];
        height = 64;
      case PeriodScale.month:
        labels = [for (final c in cells) '${c.start.day}'];
        lead = (cells.first.start.weekday - 1) % 7;
        final monday = DateTime(2026, 11, 2);
        header = [
          for (var i = 0; i < 7; i++)
            DateFormat.EEEEE(lang)
                .format(DateTime(monday.year, monday.month, monday.day + i)),
        ];
      case PeriodScale.long:
        labels = [
          for (final c in cells)
            DateFormat.MMM(lang).format(
              BudgetPeriod.containing(c.start, startDay: p.startDay).month,
            ),
        ];
        columns = 4;
        height = 48;
    }
    String cellName(int i) {
      final start = cells[i].start;
      return switch (p.scale) {
        PeriodScale.day => l.overviewHourMark(start.hour),
        PeriodScale.long => _cap(labels[i]),
        _ => _dayName(start),
      };
    }

    /// The categories that cost the most in cell [i] (« Repas, Courses »).
    String kinds(int i) => [
      for (final c in topCategories(
        cells[i],
        data.spends,
        parentOf: (id) => data.parents[id] ?? id,
        exits: values[i],
        main: p.main,
        rateFor: p.rateFor,
        count: 2,
      ))
        if (data.categories[c.category] case final category?)
          categoryName(l, category),
    ].join(', ');

    final scope = switch (p.kind) {
      PeriodKind.today ||
      PeriodKind.yesterday ||
      PeriodKind.last24Hours => 'day',
      PeriodKind.last7Days => 'week',
      PeriodKind.month => 'month',
      PeriodKind.year => 'year',
      PeriodKind.custom => 'other',
    };
    final today = p.running && unit == Grouping.day
        ? cells.indexWhere((c) => c.contains(p.now))
        : -1;

    final total = p.totals.exits.minor;
    final name = switch (unit) {
      Grouping.hour => l.followedPriciestHour,
      Grouping.month => l.followedPriciestMonth,
      _ => l.followedPriciestDay,
    };
    final best = top.isEmpty ? null : top.first;
    return EnlargedCard(
      title: '$name · ${p.label}',
      figure: best == null
          ? l.followedNoExit
          : switch (p.scale) {
              PeriodScale.day => l.overviewHourMark(cells[best].start.hour),
              PeriodScale.long => _cap(labels[best]),
              _ => _dayName(cells[best].start),
            },
      figureColor: best == null ? KibuoColors.inkMuted : KibuoColors.ink,
      line: best == null
          ? null
          : CardNote(
              l.enlShareOfPeriod(
                signed(-values[best]),
                total == 0 ? 0 : (values[best] * 100 / total).round(),
                scope,
              ),
            ),
      action: l.enlSeeOperations,
      onAction: _operations(),
      onClose: close,
      children: [
        AmountCalendar(
          labels: labels,
          amounts: [for (final v in values) v == 0 ? '' : short(v)],
          top: top,
          columns: columns,
          ahead: ahead,
          lead: lead,
          header: header,
          cellHeight: height,
          today: today,
        ),
        CardNote(l.enlAmountsIn(currencyOf(p.main.code).symbol)),
        if (top.isNotEmpty)
          LandmarkRows([
            for (final (rank, i) in top.indexed)
              landmark(
                '${rank + 1} · ${cellName(i)}',
                signed(-values[i]),
                kinds(i),
              ),
          ]),
      ],
    );
  }

  String _when(DateTime day) {
    final days = calendarDays(_today, day);
    if (days < 0) return l.enlLateBy(-days);
    if (days == 0) return l.enlDueToday;
    return l.enlInDays(days);
  }

  Widget _upcoming() {
    final coming = data.coming;
    final next = coming.isEmpty ? null : coming.first;
    final days = [
      for (var i = 0; i < 14; i++)
        DateTime(_today.year, _today.month, _today.day + i),
    ];
    Color? dot(DateTime d) {
      final here = coming.where((c) => calendarDays(c.day, d) == 0);
      if (here.isEmpty) return null;
      return here.any((c) => c.out)
          ? KibuoColors.debtLine
          : KibuoColors.accentDash;
    }

    final String figure;
    if (next == null) {
      figure = l.followedNothingComing;
    } else {
      final n = calendarDays(_today, next.day);
      figure = n <= 0
          ? l.followedToday(next.label)
          : n == 1
          ? l.followedTomorrow(next.label)
          : l.followedIn(next.label, n);
    }
    return EnlargedCard(
      title: '${l.followedUpcoming} · ${l.enlNext14Days}',
      figure: figure,
      figureColor: next == null ? KibuoColors.inkMuted : KibuoColors.ink,
      line: next == null
          ? null
          : CardNote(
              l.followedOnDay(
                '${next.out ? '−' : '+'}${money(next.amount.minor.abs(), code: next.amount.currency)}',
                _day(next.day),
              ),
            ),
      action: l.enlSeeRecurrences,
      onAction: () => then(links.recurrences),
      onClose: close,
      children: [
        DayRibbon(
          days: [
            for (final d in days)
              (
                letter: DateFormat.EEEEE(lang).format(d),
                day: d.day,
                dot: dot(d),
              ),
          ],
        ),
        if (coming.isNotEmpty)
          DatedList(
            items: [
              for (final c in coming.take(3))
                (
                  day: '${c.day.day}',
                  month: DateFormat.MMM(lang).format(c.day),
                  name: c.label,
                  sub: switch (c.debt) {
                    DebtDirection.owe => l.enlDebtDue(_when(c.day)),
                    DebtDirection.owed => l.enlReceivableDue(_when(c.day)),
                    null => l.enlRecurrence(_when(c.day)),
                  },
                  late: false,
                  value:
                      '${c.out ? '−' : '+'}${money(c.amount.minor.abs(), code: c.amount.currency)}',
                  color: c.out ? KibuoColors.debtInk : KibuoColors.accent,
                ),
            ],
          ),
      ],
    );
  }

  Widget _budget() {
    final book = this.book;
    final lines = book?.lines ?? const <BudgetLine>[];
    final id = lines.any((b) => b.budget.id == choice.budget)
        ? choice.budget
        : nearestLimit([
            for (final b in lines) (id: b.budget.id, percent: b.status.percent),
          ]);
    final line = lines.where((b) => b.budget.id == id).firstOrNull;
    if (line == null || book == null) {
      return EnlargedCard(
        title: l.followedBudget,
        figure: l.followedNoBudget,
        figureColor: KibuoColors.inkMuted,
        action: l.enlSeeBudget,
        onAction: () => then(links.budgets),
        onClose: close,
        children: const [],
      );
    }
    final status = line.status;
    final level = SpentLevel.share(status.percent);
    final period = book.period;
    final ids = {line.category.id, for (final s in line.category.subs) s.id};
    final days = period.days;
    final first = period.first;
    final perDay = List.filled(days, 0);
    for (final s in data.spends) {
      if (!ids.contains(s.category) || !period.contains(s.at)) continue;
      final d = calendarDays(first, s.at);
      if (d >= 0 && d < days) {
        perDay[d] += inMain(s.amount);
      }
    }
    final running = period.contains(p.now);
    final reached = running ? calendarDays(first, p.now) + 1 : days;
    final amount = status.amount.minor;
    final left = status.left.minor;
    final elapsed = running ? period.elapsed(p.now) : 1.0;
    final gap = paceGap(
      spent: status.spent.minor,
      amount: amount,
      elapsed: elapsed,
    );
    final daysLeft = running ? days - reached + 1 : 0;
    final tint = switch (level.bar) {
      KibuoColors.warning => KibuoColors.warningTint,
      KibuoColors.debtInk => KibuoColors.debtTint,
      _ => KibuoColors.fillSoft,
    };
    final name = categoryName(l, line.category);
    // Calm, the bar is grey like the regular pace: the curve takes the ink
    // so the two lines stay apart.
    final curve = level.bar == KibuoColors.inkMuted
        ? KibuoColors.ink
        : level.bar;
    return EnlargedCard(
      title: '${l.followedBudgetNamed(name)} · ${p.label}',
      figure: '${status.percent} %',
      figureColor: level.ink,
      line: CardNote(
        left < 0
            ? l.followedOver(money(-left))
            : [
                l.followedLeft(money(left)),
                if (status.percent > 80 && status.percent < 100)
                  _lower(l.budgetNear),
              ].join(' · '),
      ),
      action: l.enlSeeBudget,
      onAction: () => then(
        links.budget == null
            ? null
            : () => links.budget!(line.budget.id, book.period.month),
      ),
      onClose: close,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DayLineChart(
              current: runningTotal(perDay.take(reached).toList()),
              compared: [
                for (var i = 0; i < days; i++)
                  days <= 1 ? amount : (amount * i / (days - 1)).round(),
              ],
              points: days,
              color: curve,
              tint: tint,
              dayLabel:
                  '${_day(running ? p.now : period.last)} · ${roundUnsigned(status.spent.minor)}',
              pill: tint,
              pillInk: level.ink,
            ),
            const SizedBox(height: 6),
            AxisLabels(
              _dayAxis(first, period.last, running ? p.now : null),
              at: days <= 1 ? 0 : (reached - 1) / (days - 1),
            ),
            const SizedBox(height: 8),
            ChartLegend(
              color: curve,
              name: l.followedSpent,
              comparedName: l.enlRegularPace(roundUnsigned(amount)),
            ),
          ],
        ),
        LandmarkRows([
          landmark(
            l.followedSpent,
            money(status.spent.minor),
            l.enlOn(money(amount)),
          ),
          if (daysLeft > 0 && left > 0)
            landmark(
              l.enlLeftPerDay,
              money(left ~/ daysLeft),
              l.enlUntil(_day(period.last)),
            ),
          landmark(
            l.enlPace,
            gap >= 0 ? signed(gap) : money(-gap),
            gap > 0 ? l.enlAhead : l.enlMargin,
            color: gap > 0 ? KibuoColors.warningInk : KibuoColors.accent,
          ),
        ]),
      ],
    );
  }

  Widget _debts(DebtDirection direction) {
    final owe = direction == DebtDirection.owe;
    final lines = [
      for (final d in data.debts)
        if (d.direction == direction) d,
    ]..sort((a, b) => inMain(b.left) - inMain(a.left));
    final left = lines.fold(0, (a, d) => a + inMain(d.left));
    final amount = lines.fold(0, (a, d) => a + inMain(d.amount));
    final forgiven = lines.fold(
      0,
      (a, d) => a + (d.forgiven == null ? 0 : inMain(d.forgiven!)),
    );
    final late = lines
        .where((d) => d.due != null && d.due!.isBefore(_today))
        .length;
    final share = amount <= 0 ? 0 : ((amount - left) * 100 / amount).round();
    final recovered = math.max(0, amount - forgiven - left);
    return EnlargedCard(
      title: '${owe ? l.followedDebts : l.followedReceivables} · ${l.enlToday}',
      figure: money(left),
      figureColor: owe ? KibuoColors.debtInk : KibuoColors.accent,
      line: CardNote(
        owe
            ? [
                l.followedDebtCount(lines.length),
                if (late > 0) l.followedLate(late),
              ].join(' · ')
            : [
                l.enlReceivableCount(lines.length),
                l.followedRecovered(money(recovered)),
              ].join(' · '),
      ),
      action: owe ? l.enlSeeDebts : l.enlSeeReceivables,
      onAction: () =>
          then(links.debts == null ? null : () => links.debts!(direction)),
      onClose: close,
      children: [
        Bar(
          share: share / 100,
          color: owe ? KibuoColors.debtLine : KibuoColors.accentDash,
          height: 12,
        ),
        CardNote(owe ? l.enlRepaid(share) : l.enlRecovered(share)),
        if (lines.isNotEmpty)
          DatedList(
            items: [
              for (final d in lines.take(3))
                (
                  day: d.due == null ? '—' : '${d.due!.day}',
                  month: d.due == null
                      ? ''
                      : DateFormat.MMM(lang).format(d.due!),
                  name: d.person,
                  sub: d.due == null ? l.enlNoDate : _when(d.due!),
                  late: d.due != null && d.due!.isBefore(_today),
                  value: money(d.left.minor, code: d.left.currency),
                  color: owe ? KibuoColors.debtInk : KibuoColors.accent,
                ),
            ],
          ),
      ],
    );
  }

  Widget _project() {
    final projects = data.projects;
    if (p.scale == PeriodScale.long) {
      final reached = projects.where((x) => x.reached).length;
      return EnlargedCard(
        title: '${l.followedProjectsReached} · ${p.label}',
        figure: l.followedReachedOf(reached, projects.length),
        figureColor: KibuoColors.projectInk,
        action: l.enlSeeProjects,
        onAction: () => then(links.projects),
        onClose: close,
        children: [
          RankedBars(
            color: KibuoColors.projectLine,
            items: [
              for (final x in projects.take(5))
                (
                  name: x.name,
                  value: '${(x.share * 100).round()} %',
                  sub: money(x.saved.minor, code: x.saved.currency),
                  share: x.share,
                ),
            ],
          ),
        ],
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
      return EnlargedCard(
        title: l.followedProject,
        figure: l.followedNoProject,
        figureColor: KibuoColors.inkMuted,
        action: l.enlSeeProjects,
        onAction: () => then(links.projects),
        onClose: close,
        children: const [],
      );
    }
    final code = project.goal.currency;
    final moved = [
      for (final c
          in data.contributions[project.id] ?? const <ContributionLine>[])
        if (p.span.contains(c.date)) c.amount.minor,
    ].fold(0, (a, b) => a + b);
    final due = project.due;
    final expected = due == null
        ? null
        : expectedShare(today: _today, start: project.startedOn, due: due);
    final planned = due == null || project.reached
        ? null
        : perPeriod(
            goal: project.goal.minor,
            saved: project.saved.minor,
            today: _today,
            due: due,
            period: project.period,
          );
    final gap = expected == null
        ? null
        : projectGap(
            goal: project.goal.minor,
            saved: project.saved.minor,
            share: expected,
          );
    final movedText = p.scale == PeriodScale.month
        ? l.enlThisMonth(signed(moved, code: code))
        : l.enlOverPeriod(signed(moved, code: code));
    return EnlargedCard(
      title: '${l.followedProjectNamed(project.name)} · ${p.label}',
      figure: '${(project.share * 100).round()} %',
      figureColor: KibuoColors.projectInk,
      line: CardNote(
        [
          movedText,
          if (due != null)
            l.enlForDate(
              withFirst(DateFormat.MMMd(lang).format(due), due, lang),
            ),
        ].join(' · '),
      ),
      action: l.enlSeeProject,
      onAction: () =>
          then(links.project == null ? null : () => links.project!(project.id)),
      onClose: close,
      children: [
        Bar(
          share: project.share,
          color: KibuoColors.projectLine,
          height: 12,
          track: KibuoColors.projectTrack,
          mark: expected,
          markLabel: expected == null
              ? null
              : l.enlPlanMark(
                  roundUnsigned(
                    (project.goal.minor * expected).round(),
                    code: code,
                  ),
                ),
        ),
        LandmarkRows([
          landmark(
            l.enlPaid,
            money(project.saved.minor, code: code),
            l.enlOn(money(project.goal.minor, code: code)),
          ),
          if (planned != null)
            landmark(
              l.enlPlanned,
              money(planned, code: code),
              project.period == PlanPeriod.week
                  ? l.enlEveryWeek
                  : l.enlEveryMonth,
            ),
          if (gap != null)
            landmark(
              gap >= 0 ? l.enlAheadPlan : l.enlBehindPlan,
              signed(gap, code: code),
              l.enlOnPlan,
              color: gap >= 0 ? KibuoColors.accent : KibuoColors.danger,
            )
          else
            landmark(
              l.enlLeftToSave,
              money(
                math.max(0, project.goal.minor - project.saved.minor),
                code: code,
              ),
              '',
            ),
        ]),
      ],
    );
  }

  int get _accountsTotal => data.accountsTotal;

  /// What the accounts held at the start of the period.
  int get _accountsAtStart => totalsBack(
    [p.span.start],
    current: data.accountsTotal,
    changes: data.accountChanges,
  ).first;

  Widget _accounts() {
    const shades = [
      KibuoColors.accent,
      KibuoColors.chartIn,
      KibuoColors.mint,
      KibuoColors.accentDash,
      KibuoColors.accentTintOpen,
    ];
    final total = _accountsTotal;
    final accounts = data.accounts;
    double share(int v) => total <= 0 ? 0 : math.max(0, v) / total;
    return EnlargedCard(
      title: '${l.followedAccounts} · ${p.label}',
      figure: total < 0 ? '−${money(-total)}' : money(total),
      line: CardNote(
        l.enlSince(signed(total - _accountsAtStart), _day(p.span.start)),
      ),
      action: l.enlSeeAccounts,
      onAction: () => then(links.accounts),
      onClose: close,
      children: [
        SplitBar(
          parts: [
            for (final (i, a) in accounts.indexed)
              if (a.balance > 0)
                (share: share(a.balance), color: shades[i % shades.length]),
          ],
        ),
        DotRows([
          for (final (i, a) in accounts.indexed)
            (
              color: shades[i % shades.length],
              name: a.name,
              value: a.balance < 0 ? '−${money(-a.balance)}' : money(a.balance),
              sub: '${(share(a.balance) * 100).round()} %',
            ),
        ]),
      ],
    );
  }

  Widget _worth() {
    var owed = 0;
    var owe = 0;
    for (final d in data.debts) {
      final v = inMain(d.left);
      if (d.direction == DebtDirection.owed) {
        owed += v;
      } else {
        owe += v;
      }
    }
    final accounts = _accountsTotal;
    final net = accounts + owed - owe;
    final atStart = totalsBack(
      [p.span.start],
      current: net,
      changes: data.worthChanges,
    ).first;
    return EnlargedCard(
      title: '${l.followedNetWorth} · ${l.enlToday}',
      figure: net < 0 ? '−${money(-net)}' : money(net),
      line: CardNote(l.enlSince(signed(net - atStart), _day(p.span.start))),
      action: l.enlSeeAccounts,
      onAction: () => then(links.accounts),
      onClose: close,
      children: [
        Waterfall(
          steps: [
            (
              label: l.followedAccounts,
              value: accounts,
              color: KibuoColors.chartIn,
              total: true,
            ),
            (
              label: l.followedReceivables,
              value: owed,
              color: KibuoColors.accentDash,
              total: false,
            ),
            (
              label: l.followedDebts,
              value: -owe,
              color: KibuoColors.debtLine,
              total: false,
            ),
            (label: l.enlNet, value: net, color: KibuoColors.ink, total: true),
          ],
        ),
        LandmarkRows([
          landmark(
            l.followedAccounts,
            money(accounts),
            l.enlAccountsCount(data.accounts.length),
          ),
          landmark(
            l.followedReceivables,
            signed(owed),
            l.enlOwedToYou,
            color: KibuoColors.accent,
          ),
          landmark(
            l.followedDebts,
            signed(-owe),
            l.enlYouOwe,
            color: KibuoColors.debtInk,
          ),
        ]),
      ],
    );
  }
}
