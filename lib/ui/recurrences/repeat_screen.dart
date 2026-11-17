import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/choice_strip.dart';
import 'package:kibuo/ui/recurrences/rhythm_text.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

enum RepeatEnd { never, count, date }

/// What « Répéter » was set to: the rhythm, its end, and whether each time
/// waits as a draft.
class RepeatChoice {
  const RepeatChoice({
    required this.unit,
    required this.start,
    this.every = 1,
    this.weekdays = const {},
    this.end = RepeatEnd.never,
    this.count = 6,
    this.until,
    this.asDraft = false,
  });

  final RepeatUnit unit;
  final DateTime start;
  final int every;
  final Set<int> weekdays;
  final RepeatEnd end;
  final int count;
  final DateTime? until;
  final bool asDraft;

  Schedule get schedule => Schedule(
    start: start,
    unit: unit,
    every: every,
    weekdays: weekdays,
    count: end == RepeatEnd.count ? count : null,
    until: end == RepeatEnd.date ? until : null,
  );

  RepeatChoice copyWith({
    RepeatUnit? unit,
    DateTime? start,
    int? every,
    Set<int>? weekdays,
    RepeatEnd? end,
    int? count,
    DateTime? until,
    bool? asDraft,
  }) => RepeatChoice(
    unit: unit ?? this.unit,
    start: start ?? this.start,
    every: every ?? this.every,
    weekdays: weekdays ?? this.weekdays,
    end: end ?? this.end,
    count: count ?? this.count,
    until: until ?? this.until,
    asDraft: asDraft ?? this.asDraft,
  );
}

/// The answer of [RepeatScreen]: a choice, or none to stop repeating.
class RepeatAnswer {
  const RepeatAnswer(this.choice);

  final RepeatChoice? choice;
}

/// « Nouvelle récurrence » (canvas Recurrence): what repeats on top, then
/// Répéter, Fin, the summary with the next dates, and « À chaque
/// échéance ». Pops a [RepeatAnswer], or nothing when left.
class RepeatScreen extends StatefulWidget {
  const RepeatScreen({
    super.key,
    required this.start,
    required this.facts,
    this.initial,
  });

  /// The first time.
  final DateTime start;

  /// What repeats: « Montant · 30,00 $ », « Compte · M-Pesa »…
  final List<(String, String)> facts;
  final RepeatChoice? initial;

  @override
  State<RepeatScreen> createState() => _RepeatScreenState();
}

class _RepeatScreenState extends State<RepeatScreen> {
  late RepeatChoice _c =
      widget.initial?.copyWith(start: widget.start) ??
      RepeatChoice(
        unit: RepeatUnit.month,
        start: widget.start,
        weekdays: {widget.start.weekday},
      );

  String get _lang => Localizations.localeOf(context).languageCode;

  Future<void> _pickUntil() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _c.until ?? DateTime(_c.start.year, _c.start.month + 6, _c.start.day),
      firstDate: _c.start,
      lastDate: DateTime(_c.start.year + 30),
    );
    if (picked != null) setState(() => _c = _c.copyWith(until: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = _c.schedule;
    String short(DateTime d) => d.year == DateTime.now().year
        ? DateFormat.MMMd(_lang).format(d)
        : DateFormat.yMMMd(_lang).format(d);
    final next = s.dates().take(3).map(short).join(', ');
    final every = switch (_c.unit) {
      RepeatUnit.day => l.repeatEveryDay(_c.every),
      RepeatUnit.week => l.repeatEveryWeek(_c.every),
      RepeatUnit.month => l.repeatEveryMonth(_c.every),
      RepeatUnit.year => l.repeatEveryYear(_c.every),
    };
    Widget title(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Text(
        text,
        style: KibuoType.body.copyWith(
          fontWeight: FontWeight.w600,
          fontVariations: const [FontVariation.weight(600)],
        ),
      ),
    );
    Widget card(List<Widget> children, {EdgeInsets? padding}) => Container(
      padding: padding ?? const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
    Widget line(String label, Widget value, {bool top = false}) => Container(
      constraints: const BoxConstraints(minHeight: 44),
      decoration: top
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: KibuoColors.background)),
            )
          : null,
      padding: EdgeInsets.only(top: top ? 8 : 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: KibuoType.rowLabel.copyWith(
                fontWeight: FontWeight.w500,
                fontVariations: const [FontVariation.weight(500)],
              ),
            ),
          ),
          value,
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? l.recurrenceNew : l.repeatTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (widget.facts.isNotEmpty)
                    card(padding: const EdgeInsets.symmetric(horizontal: 16), [
                      for (final (i, (label, value)) in widget.facts.indexed)
                        Container(
                          constraints: const BoxConstraints(minHeight: 48),
                          decoration: i == 0
                              ? null
                              : const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: KibuoColors.background,
                                    ),
                                  ),
                                ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  label,
                                  style: KibuoType.rowLabel.copyWith(
                                    color: KibuoColors.inkSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                value,
                                style: KibuoType.rowLabel.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontVariations: const [
                                    FontVariation.weight(500),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ]),
                  const SizedBox(height: 12),
                  title(l.repeatTitle),
                  const SizedBox(height: 12),
                  card([
                    ChoiceStrip<RepeatUnit>(
                      items: [
                        (RepeatUnit.day, l.repeatDay),
                        (RepeatUnit.week, l.repeatWeek),
                        (RepeatUnit.month, l.repeatMonth),
                        (RepeatUnit.year, l.repeatYear),
                      ],
                      value: _c.unit,
                      onPick: (u) => setState(() => _c = _c.copyWith(unit: u)),
                    ),
                    if (_c.unit == RepeatUnit.week) ...[
                      const SizedBox(height: 12),
                      Text(rhythmOnly(l, _lang, s), style: KibuoType.help),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (var d = 1; d <= 7; d++) ...[
                            if (d > 1) const SizedBox(width: 4),
                            Expanded(child: _weekday(d)),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    line(
                      every,
                      CountStepper(
                        value: _c.every,
                        max: 12,
                        lessLabel: l.repeatLess,
                        moreLabel: l.repeatMore,
                        onChanged: (n) =>
                            setState(() => _c = _c.copyWith(every: n)),
                      ),
                    ),
                    line(
                      l.repeatFirst,
                      Text(
                        short(s.dates().first),
                        style: KibuoType.rowLabel.copyWith(
                          fontWeight: FontWeight.w500,
                          fontVariations: const [FontVariation.weight(500)],
                        ),
                      ),
                      top: true,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  title(l.repeatEnd),
                  const SizedBox(height: 12),
                  card([
                    ChoiceStrip<RepeatEnd>(
                      items: [
                        (RepeatEnd.never, l.repeatEndNever),
                        (RepeatEnd.count, l.repeatEndCount),
                        (RepeatEnd.date, l.repeatEndDate),
                      ],
                      value: _c.end,
                      onPick: (e) {
                        setState(() => _c = _c.copyWith(end: e));
                        if (e == RepeatEnd.date && _c.until == null) {
                          _pickUntil();
                        }
                      },
                    ),
                    if (_c.end == RepeatEnd.count) ...[
                      const SizedBox(height: 12),
                      line(
                        l.repeatCount,
                        CountStepper(
                          value: _c.count,
                          lessLabel: l.repeatLess,
                          moreLabel: l.repeatMore,
                          onChanged: (n) =>
                              setState(() => _c = _c.copyWith(count: n)),
                        ),
                      ),
                    ],
                    if (_c.end == RepeatEnd.date && _c.until != null) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickUntil,
                        child: line(
                          l.repeatLastDate,
                          Text(
                            DateFormat.yMMMMd(_lang).format(_c.until!),
                            style: KibuoType.rowLabel.copyWith(
                              color: KibuoColors.accent,
                              fontWeight: FontWeight.w600,
                              fontVariations: const [FontVariation.weight(600)],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(switch (_c.end) {
                      RepeatEnd.never => l.repeatEndNeverHelp,
                      RepeatEnd.count => l.repeatEndCountHelp,
                      RepeatEnd.date => l.repeatEndDateHelp,
                    }, style: KibuoType.help.copyWith(height: 18 / 13)),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: KibuoColors.mint,
                      borderRadius: BorderRadius.circular(
                        KibuoTheme.radiusCard,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rhythmText(l, _lang, s),
                          style: KibuoType.rowLabel.copyWith(
                            fontWeight: FontWeight.w600,
                            fontVariations: const [FontVariation.weight(600)],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.repeatNext(next),
                          style: KibuoType.help.copyWith(
                            color: KibuoColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  title(l.repeatEach),
                  const SizedBox(height: 12),
                  ChoiceStrip<bool>(
                    onWhite: true,
                    height: 44,
                    items: [
                      (false, l.repeatModeSave),
                      (true, l.repeatModeDraft),
                    ],
                    value: _c.asDraft,
                    onPick: (d) => setState(() => _c = _c.copyWith(asDraft: d)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      _c.asDraft ? l.repeatModeDraftHelp : l.repeatModeSaveHelp,
                      style: KibuoType.body.copyWith(
                        height: 20 / 14,
                        color: KibuoColors.inkSecondary,
                      ),
                    ),
                  ),
                  if (widget.initial != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextAction(
                        label: l.repeatStop,
                        color: KibuoColors.inkSecondary,
                        onPressed: () =>
                            Navigator.of(context).pop(const RepeatAnswer(null)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: KibuoButton(
                label: l.repeatSave,
                onPressed: () => Navigator.of(context).pop(RepeatAnswer(_c)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekday(int d) {
    final on = _c.weekdays.contains(d);
    final name = DateFormat.EEEE(_lang).format(DateTime(2026, 11, 15 + d));
    return Semantics(
      label: name,
      selected: on,
      button: true,
      child: Material(
        color: on ? KibuoColors.accent : KibuoColors.background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => setState(() {
            final days = {..._c.weekdays};
            // At least one day (PRODUCT).
            if (on && days.length > 1) {
              days.remove(d);
            } else {
              days.add(d);
            }
            _c = _c.copyWith(weekdays: days);
          }),
          child: SizedBox(
            height: KibuoTheme.heightTouch,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  name[0].toUpperCase(),
                  style: KibuoType.buttonSmall.copyWith(
                    fontSize: 14,
                    color: on ? KibuoColors.surface : KibuoColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
