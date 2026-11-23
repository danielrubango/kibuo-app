import 'package:flutter/material.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// « Affichage de la liste » (canvas BrouillonA3): the three choices of
/// recurrences and drafts, each applied at once, then « Terminé ».
Future<void> showListDisplaySheet(
  BuildContext context,
  RecurringRepository recurrences, {
  DebtRepository? debts,
}) {
  final l = AppLocalizations.of(context);
  return showKibuoSheet<void>(
    context,
    title: l.listDisplay,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecurrenceChoices(recurrences: recurrences),
        if (debts != null) ...[
          const SizedBox(height: 16),
          DebtTotalsChoice(debts: debts),
        ],
        const SizedBox(height: 8),
        HelpText(l.displayFoot),
        const SizedBox(height: 16),
        KibuoButton(
          label: l.displayDone,
          kind: ButtonKind.dark,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// Plus › « Récurrences et brouillons » (canvas ReglagesBrouillons): the
/// same three choices as the list's display sheet, each said in full.
class RecurrencesSettingsScreen extends StatelessWidget {
  const RecurrencesSettingsScreen({super.key, required this.recurrences});

  final RecurringRepository recurrences;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsRecurrences)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          RecurrenceChoices(recurrences: recurrences, full: true),
          const SizedBox(height: 8),
          HelpText(l.settingsRecurrencesFoot),
        ],
      ),
    );
  }
}

/// The three choices, read from and written to [recurrences]: validate
/// automatically or always ask, drafts at their date or on top, planned
/// operations shown or hidden. [full] gives each choice's whole sentence.
class RecurrenceChoices extends StatefulWidget {
  const RecurrenceChoices({
    super.key,
    required this.recurrences,
    this.full = false,
  });

  final RecurringRepository recurrences;
  final bool full;

  @override
  State<RecurrenceChoices> createState() => _RecurrenceChoicesState();
}

class _RecurrenceChoicesState extends State<RecurrenceChoices> {
  bool? _ask;
  bool _onTop = false;
  bool _planned = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = widget.recurrences;
    final ask = await r.alwaysAsk();
    final onTop = await r.draftsOnTop();
    final planned = await r.showPlanned();
    if (!mounted) return;
    setState(() {
      _ask = ask;
      _onTop = onTop;
      _planned = planned;
    });
  }

  Future<void> _set({bool? ask, bool? onTop, bool? planned}) async {
    final r = widget.recurrences;
    setState(() {
      _ask = ask ?? _ask;
      _onTop = onTop ?? _onTop;
      _planned = planned ?? _planned;
    });
    if (ask != null) await r.setAlwaysAsk(ask);
    if (onTop != null) await r.setDraftsOnTop(onTop);
    if (planned != null) await r.setShowPlanned(planned);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ask = _ask;
    if (ask == null) return const SizedBox.shrink();
    final full = widget.full;
    Widget choice(
      IconData icon,
      String label,
      String help,
      String long, {
      required bool on,
      required VoidCallback onTap,
    }) => DisplayChoice(
      icon: icon,
      label: label,
      help: full ? long : help,
      helpLines: full ? null : 1,
      on: on,
      onTap: onTap,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.displayWhenDue),
        SettingsCard(
          children: [
            choice(
              KibuoIcons.checkCircle,
              l.displayAuto,
              l.displayAutoHelp,
              l.displayAutoLong,
              on: !ask,
              onTap: () => _set(ask: false),
            ),
            choice(
              KibuoIcons.warningCircle,
              l.displayAsk,
              l.displayAskHelp,
              l.displayAskLong,
              on: ask,
              onTap: () => _set(ask: true),
            ),
          ],
        ),
        const SizedBox(height: GroupTitle.gap),
        SectionTitle(l.displayDrafts),
        SettingsCard(
          children: [
            choice(
              KibuoIcons.calendarBlank,
              l.displayAtDate,
              l.displayAtDateHelp,
              l.displayAtDateLong,
              on: !_onTop,
              onTap: () => _set(onTop: false),
            ),
            choice(
              KibuoIcons.arrowLineUp,
              l.displayOnTop,
              l.displayOnTopHelp,
              l.displayOnTopLong,
              on: _onTop,
              onTap: () => _set(onTop: true),
            ),
          ],
        ),
        const SizedBox(height: GroupTitle.gap),
        SectionTitle(l.displayPlanned),
        SettingsCard(
          children: [
            choice(
              KibuoIcons.eye,
              l.displayAtDate,
              l.displayPlannedHelp,
              l.displayPlannedLong,
              on: _planned,
              onTap: () => _set(planned: true),
            ),
            choice(
              KibuoIcons.eyeSlash,
              l.displayHidden,
              l.displayHiddenHelp,
              l.displayHiddenLong,
              on: !_planned,
              onTap: () => _set(planned: false),
            ),
          ],
        ),
      ],
    );
  }
}

/// The Plus row that opens [RecurrencesSettingsScreen], with how
/// recurrences arrive: « Automatique » or « Toujours demander ».
class RecurrencesSettingsRow extends StatefulWidget {
  const RecurrencesSettingsRow({super.key, required this.recurrences});

  final RecurringRepository recurrences;

  @override
  State<RecurrencesSettingsRow> createState() => _RecurrencesSettingsRowState();
}

class _RecurrencesSettingsRowState extends State<RecurrencesSettingsRow> {
  bool? _ask;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ask = await widget.recurrences.alwaysAsk();
    if (mounted) setState(() => _ask = ask);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ask = _ask;
    return SettingsRow(
      label: l.settingsRecurrences,
      value: ask == null
          ? null
          : ask
          ? l.displayAsk
          : l.displayAutoShort,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                RecurrencesSettingsScreen(recurrences: widget.recurrences),
          ),
        );
        await _load();
      },
    );
  }
}

/// « Dettes et créances »: their operations in Entrées and Sorties, or
/// apart (PRODUCT). Applied at once.
class DebtTotalsChoice extends StatefulWidget {
  const DebtTotalsChoice({super.key, required this.debts});

  final DebtRepository debts;

  @override
  State<DebtTotalsChoice> createState() => _DebtTotalsChoiceState();
}

class _DebtTotalsChoiceState extends State<DebtTotalsChoice> {
  bool? _count;

  @override
  void initState() {
    super.initState();
    widget.debts.countInTotals().then((on) {
      if (mounted) setState(() => _count = on);
    });
  }

  Future<void> _set(bool on) async {
    setState(() => _count = on);
    await widget.debts.setCountInTotals(on);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final count = _count;
    if (count == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l.debtsTitle),
        SettingsCard(
          children: [
            DisplayChoice(
              icon: KibuoIcons.arrowsDownUp,
              label: l.debtsInTotals,
              help: l.debtsInTotalsHelp,
              on: count,
              onTap: () => _set(true),
            ),
            DisplayChoice(
              icon: KibuoIcons.handCoins,
              label: l.debtsApart,
              help: l.debtsApartHelp,
              on: !count,
              onTap: () => _set(false),
            ),
          ],
        ),
      ],
    );
  }
}
