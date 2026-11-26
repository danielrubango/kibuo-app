import 'package:flutter/material.dart';
import 'package:kibuo/domain/overview/followed.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/choice_sheet.dart';
import 'package:kibuo/ui/kit/haptics.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The « Suivre » sheet (canvas ApercuTSuivre): the tiles by family, each
/// with a switch; touching the budget's or the project's name picks
/// another. Changes show at once behind the veil.
Future<void> showFollowSheet(
  BuildContext context, {
  required FollowedChoice choice,
  required List<(String, String)> budgets,
  required List<(String, String)> projects,
  required String? budgetShown,
  required String? projectShown,
  required ValueChanged<FollowedChoice> onChanged,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _FollowSheet(
    choice: choice,
    budgets: budgets,
    projects: projects,
    budgetShown: budgetShown,
    projectShown: projectShown,
    onChanged: onChanged,
  ),
);

class _FollowSheet extends StatefulWidget {
  const _FollowSheet({
    required this.choice,
    required this.budgets,
    required this.projects,
    required this.budgetShown,
    required this.projectShown,
    required this.onChanged,
  });

  final FollowedChoice choice;

  /// Budgets and projects that can be followed: (id, name).
  final List<(String, String)> budgets;
  final List<(String, String)> projects;

  /// The ids the tiles show now.
  final String? budgetShown;
  final String? projectShown;
  final ValueChanged<FollowedChoice> onChanged;

  @override
  State<_FollowSheet> createState() => _FollowSheetState();
}

class _FollowSheetState extends State<_FollowSheet> {
  late FollowedChoice _choice = widget.choice;
  late String? _budget = widget.budgetShown;
  late String? _project = widget.projectShown;

  void _set(FollowedChoice choice) {
    setState(() => _choice = choice);
    widget.onChanged(choice);
  }

  String? _name(List<(String, String)> items, String? id) {
    for (final (key, name) in items) {
      if (key == id) return name;
    }
    return null;
  }

  Future<void> _pickBudget(AppLocalizations l) async {
    final id = await showChoiceSheet<String>(
      context,
      title: l.followWhichBudget,
      options: widget.budgets,
      selected: _budget,
    );
    if (id == null || !mounted) return;
    _budget = id;
    _set(_choice.withBudget(id));
  }

  Future<void> _pickProject(AppLocalizations l) async {
    final id = await showChoiceSheet<String>(
      context,
      title: l.followWhichProject,
      options: widget.projects,
      selected: _project,
    );
    if (id == null || !mounted) return;
    _project = id;
    _set(_choice.withProject(id));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final budget = _name(widget.budgets, _budget);
    final project = _name(widget.projects, _project);
    Widget row(
      Followed tile,
      String name,
      String help, {
      VoidCallback? onName,
    }) => _SwitchLine(
      name: name,
      help: help,
      on: _choice.on.contains(tile),
      onChanged: (on) => _set(_choice.turned(tile, on)),
      onName: onName,
    );
    final families = [
      (
        l.followMoney,
        [
          row(Followed.spent, l.followedSpent, l.followSpentHelp),
          row(Followed.received, l.followedReceived, l.followReceivedHelp),
          row(Followed.savings, l.followedSavings, l.followSavingsHelp),
          row(Followed.average, l.followedAverage, l.followAverageHelp),
        ],
      ),
      (
        l.followMarks,
        [
          row(
            Followed.topCategory,
            l.followedTopCategory,
            l.followTopCategoryHelp,
          ),
          row(Followed.priciest, l.followedPriciest, l.followPriciestHelp),
          row(Followed.upcoming, l.followedUpcoming, l.followUpcomingHelp),
        ],
      ),
      (
        l.followCommitments,
        [
          row(
            Followed.budget,
            l.followedBudget,
            budget == null ? l.followedNoBudget : l.followBudgetHelp(budget),
            onName: widget.budgets.length < 2 ? null : () => _pickBudget(l),
          ),
          row(Followed.debts, l.followedDebts, l.followDebtsHelp),
          row(
            Followed.receivables,
            l.followedReceivables,
            l.followReceivablesHelp,
          ),
          row(
            Followed.project,
            l.followedProject,
            project == null
                ? l.followedNoProject
                : l.followProjectHelp(project),
            onName: widget.projects.length < 2 ? null : () => _pickProject(l),
          ),
        ],
      ),
      (
        l.followWorth,
        [
          row(Followed.accounts, l.followedAccounts, l.followAccountsHelp),
          row(Followed.netWorth, l.followedNetWorth, l.followNetWorthHelp),
        ],
      ),
    ];
    final padding = sheetPadding(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHandle(),
                  SheetHeader(title: l.followSheetTitle),
                  const SizedBox(height: 4),
                  Text(l.followSheetHelp, style: KibuoType.help),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final (i, (title, rows)) in families.indexed) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _Family(title: title, rows: rows),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KibuoButton(
                label: l.followDone,
                kind: ButtonKind.dark,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A white card: the family's name, then its rows, a line between them.
class _Family extends StatelessWidget {
  const _Family({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusField),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Text(
            title,
            style: KibuoType.sectionTitle.copyWith(fontSize: 12),
          ),
        ),
        for (final r in rows) ...[
          const Divider(height: 1, color: KibuoColors.background),
          r,
        ],
      ],
    ),
  );
}

/// A tile's name and what it shows, with its switch. Touching the row flips
/// it, except where [onName] picks what the tile follows.
class _SwitchLine extends StatelessWidget {
  const _SwitchLine({
    required this.name,
    required this.help,
    required this.on,
    required this.onChanged,
    this.onName,
  });

  final String name;
  final String help;
  final bool on;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onName;

  @override
  Widget build(BuildContext context) {
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: KibuoType.rowLabel.copyWith(
            fontWeight: FontWeight.w600,
            fontVariations: const [FontVariation.weight(600)],
          ),
        ),
        Row(
          children: [
            Flexible(child: Text(help, style: KibuoType.caption)),
            if (onName != null) ...[
              const SizedBox(width: 2),
              const Icon(
                KibuoIcons.caretDown,
                size: 14,
                color: KibuoColors.accent,
              ),
            ],
          ],
        ),
      ],
    );
    return MergeSemantics(
      child: InkWell(
        onTap: () {
          Haptics.tap();
          if (onName != null) {
            onName!();
          } else {
            onChanged(!on);
          }
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(child: words),
              const SizedBox(width: 12),
              Switch(
                value: on,
                onChanged: (value) {
                  Haptics.tap();
                  onChanged(value);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
