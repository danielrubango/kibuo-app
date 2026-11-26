import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/domain/overview/overview_choice.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/fading_row.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/tab_strip.dart';
import 'package:kibuo/ui/overview/overview_labels.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// What the Aperçu shows: the choices, and how many periods back.
typedef OverviewView = ({OverviewChoice choice, int offset});

/// The « Période » sheet (canvas ApercuP2Ouvert): each change shows at once
/// behind the veil; « Voir » and ✕ close it.
Future<void> showPeriodSheet(
  BuildContext context, {
  required OverviewView view,
  required int startDay,
  required ValueChanged<OverviewView> onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) =>
      PeriodSheet(view: view, startDay: startDay, onChanged: onChanged),
);

class PeriodSheet extends StatefulWidget {
  const PeriodSheet({
    super.key,
    required this.view,
    required this.startDay,
    required this.onChanged,
  });

  final OverviewView view;
  final int startDay;
  final ValueChanged<OverviewView> onChanged;

  @override
  State<PeriodSheet> createState() => _PeriodSheetState();
}

class _PeriodSheetState extends State<PeriodSheet> {
  late OverviewView _view = widget.view;
  final _chosenChip = GlobalKey();

  @override
  void initState() {
    super.initState();
    // The row opens centred on the chosen period (DIRECTION).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _chosenChip.currentContext;
      if (chip != null && chip.mounted) {
        Scrollable.ensureVisible(chip, alignment: 0.5);
      }
    });
  }

  void _set(OverviewChoice choice, int offset) {
    setState(() => _view = (choice: choice, offset: offset));
    widget.onChanged(_view);
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _pickKind(PeriodKind kind) {
    final choice = _view.choice;
    final today = _today;
    // A first custom period: from the 1st, two months back, to today.
    final custom =
        choice.custom ??
        TimeSpan.days(DateTime(today.year, today.month - 2), today);
    _set(choice.withKind(kind, custom: custom), 0);
  }

  Future<void> _pickFirst(TimeSpan custom) async {
    final day = await showDatePicker(
      context: context,
      initialDate: custom.start,
      firstDate: DateTime(2000),
      lastDate: custom.lastDay,
    );
    if (day == null || !mounted) return;
    _set(_view.choice.withCustom(TimeSpan.days(day, custom.lastDay)), 0);
  }

  Future<void> _pickLast(TimeSpan custom) async {
    final today = _today;
    final last = custom.lastDay.isAfter(today) ? custom.lastDay : today;
    final day = await showDatePicker(
      context: context,
      initialDate: custom.lastDay,
      firstDate: custom.start,
      lastDate: last,
    );
    if (day == null || !mounted) return;
    _set(_view.choice.withCustom(TimeSpan.days(custom.start, day)), 0);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final (:choice, :offset) = _view;
    final span = periodSpan(
      choice.kind,
      now: DateTime.now(),
      offset: offset,
      startDay: widget.startDay,
      custom: choice.custom,
    );
    final offered = groupingsFor(choice.kind, span);
    final comparison = choice.comparisonAt(offset);
    final atDefault = offset == 0 && choice.isDefault(span);
    final custom = choice.custom;

    Widget group(String title, Widget strip) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            style: KibuoType.sectionTitle.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 6),
        strip,
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: sheetPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.overviewPeriodTitle,
                    style: KibuoType.sheetTitle,
                  ),
                ),
                _ResetButton(
                  label: l.overviewReset,
                  onPressed: atDefault ? null : () => _set(choice.reset(), 0),
                ),
                const SizedBox(width: 2),
                Transform.translate(
                  offset: const Offset(10, 0),
                  child: SizedBox.square(
                    dimension: KibuoTheme.heightTouch,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: MaterialLocalizations.of(context)
                          .closeButtonTooltip,
                      icon: const Icon(
                        KibuoIcons.x,
                        size: 22,
                        color: KibuoColors.inkSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // The chips run to the sheet's edges.
            SizedBox(
              height: 40,
              child: LayoutBuilder(
                builder: (context, box) => OverflowBox(
                  maxWidth: box.maxWidth + 32,
                  minWidth: box.maxWidth + 32,
                  child: FadingRow(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final kind in PeriodKind.values)
                        _PeriodChip(
                          key: kind == choice.kind ? _chosenChip : null,
                          label: kindName(l, kind),
                          chosen: kind == choice.kind,
                          onTap: () => _pickKind(kind),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (choice.kind == PeriodKind.custom && custom != null) ...[
              const SizedBox(height: 12),
              SettingsCard(
                children: [
                  SettingsRow(
                    label: l.overviewFrom,
                    value: DateFormat.yMMMd(lang).format(custom.start),
                    onTap: () => _pickFirst(custom),
                  ),
                  SettingsRow(
                    label: l.overviewTo,
                    value: DateFormat.yMMMd(lang).format(custom.lastDay),
                    onTap: () => _pickLast(custom),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            group(
              l.overviewGroupBy,
              TabStrip<Grouping>(
                height: 40,
                items: [
                  for (final g in Grouping.values) (g, groupingName(l, g)),
                ],
                value: choice.groupingFor(span),
                disabled: {
                  for (final g in Grouping.values)
                    if (!offered.contains(g)) g,
                },
                onPick: (g) => _set(choice.withGrouping(g), offset),
              ),
            ),
            const SizedBox(height: 12),
            group(
              l.overviewCompareTo,
              TabStrip<Comparison>(
                height: 40,
                items: [
                  for (final c in Comparison.values) (c, comparisonName(l, c)),
                ],
                value: comparison,
                disabled: {
                  for (final c in Comparison.values)
                    if (!comparisonOpen(c, offset: offset)) c,
                },
                onPick: (c) => _set(choice.withComparison(c), offset),
              ),
            ),
            const SizedBox(height: 12),
            group(
              l.overviewComparedAs,
              TabStrip<ComparedAs>(
                height: 40,
                items: [
                  for (final c in ComparedAs.values) (c, comparedAsName(l, c)),
                ],
                value: choice.comparedAs,
                disabled: comparison == Comparison.none
                    ? ComparedAs.values.toSet()
                    : const {},
                onPick: (c) => _set(choice.withComparedAs(c), offset),
              ),
            ),
            const SizedBox(height: 12),
            KibuoButton(
              label: l.overviewSee,
              kind: ButtonKind.dark,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Réinitialiser » with its arrow, green, greyed when there is nothing to
/// reset.
class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = onPressed == null
        ? KibuoColors.lineStrong
        : KibuoColors.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
      onTap: onPressed == null
          ? null
          : () {
              Haptics.tap();
              onPressed!();
            },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: KibuoTheme.heightTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(KibuoIcons.arrowCounterClockwise, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: KibuoType.buttonSmall.copyWith(
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A period of the sheet's row: ink when chosen, white otherwise.
class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    super.key,
    required this.label,
    required this.chosen,
    required this.onTap,
  });

  final String label;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: chosen,
      button: true,
      child: Material(
        color: chosen ? KibuoColors.ink : KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
        child: InkWell(
          borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
          onTap: () {
            Haptics.tap();
            onTap();
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: KibuoType.buttonSmall.copyWith(
                fontSize: 14,
                color: chosen ? KibuoColors.surface : KibuoColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
