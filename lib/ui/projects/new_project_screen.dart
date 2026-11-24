import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/choice_sheet.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/form_top_bar.dart';
import 'package:kibuo/ui/kit/icon_grid.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/projects/project_parts.dart';
import 'package:kibuo/ui/projects/project_screen.dart';
import 'package:kibuo/ui/projects/projects_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/entry_sheets.dart';

/// The icons a project may take.
const projectIcons = [
  'airplane',
  'house',
  'car',
  'motorcycle',
  'graduationCap',
  'heart',
  'gift',
  'shoppingCart',
  'briefcase',
  'piggyBank',
  'deviceMobile',
  'baby',
  'tShirt',
  'plant',
  'star',
  'target',
];

/// « Nouveau projet » (canvas ProjetNouveau): the name with its icon, the
/// goal in large, the account with what is free on it, the date
/// (optional), what the plan asks per period, « Diviser le plan par » and
/// the reminder; « Créer le projet » at the bottom. Pops true once made,
/// changed or deleted.
class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({
    super.key,
    required this.data,
    required this.projects,
    this.now = DateTime.now,
    this.editing,
    this.payments = 0,
  });

  final EntryData data;
  final ProjectRepository projects;
  final DateTime Function() now;

  /// « Modifier le projet »: the same form, filled, « Enregistrer », and
  /// « Supprimer le projet » at the bottom.
  final ProjectInfo? editing;

  /// Its payments: after the first one, the account no longer changes.
  final int payments;

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _goalKey = GlobalKey();
  late String _icon = widget.editing?.icon ?? projectIcons.first;
  String _typed = '';
  bool _keypad = false;
  bool _tried = false;
  bool _saving = false;
  List<AccountInfo> _accounts = const [];
  AccountInfo? _account;
  Money? _free;
  late DateTime? _due = widget.editing?.due;
  late PlanPeriod _period = widget.editing?.period ?? PlanPeriod.week;
  late bool _remind = widget.editing?.remind ?? true;

  @override
  void initState() {
    super.initState();
    if (widget.editing case final p?) {
      _name.text = p.name;
      _typed = typedFrom(p.goal, currencyOf(p.goal.currency));
    }
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final accounts = await widget.data.accounts.accounts();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _account =
          accounts
              .where((a) => a.id == widget.editing?.accountId)
              .firstOrNull ??
          accounts.firstOrNull;
    });
    await _loadFree();
  }

  Future<void> _loadFree() async {
    final account = _account;
    if (account == null) return;
    final free = await widget.projects.free(account.id);
    if (mounted) setState(() => _free = free);
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  CurrencyInfo? get _currency =>
      _account == null ? null : currencyOf(_account!.currency);

  Money get _goal => typedMoney(_typed, _currency!);

  void _openKeypad() {
    _nameFocus.unfocus();
    setState(() => _keypad = true);
    revealAboveKeypad(_goalKey);
  }

  Future<void> _pickIcon() async {
    _nameFocus.unfocus();
    final l = AppLocalizations.of(context);
    final picked = await showKibuoSheet<String>(
      context,
      title: l.projectIconTitle,
      builder: (context) => IconGrid(
        icons: {for (final n in projectIcons) n: projectIcon(n)},
        chosen: _icon,
        onPick: (n) => Navigator.of(context).pop(n),
      ),
    );
    _nameFocus.unfocus();
    if (picked != null) setState(() => _icon = picked);
  }

  Future<void> _pickAccount() async {
    _nameFocus.unfocus();
    // Its money is held on that account (PRODUCT: Projets).
    if (widget.editing != null && widget.payments > 0) {
      showKibuoToast(
        context,
        AppLocalizations.of(context).projectAccountLocked,
      );
      return;
    }
    final picked = await pickAccount(
      context,
      accounts: _accounts,
      current: _account?.id,
    );
    _nameFocus.unfocus();
    if (picked == null) return;
    setState(() {
      if (picked.currency != _account?.currency) _typed = '';
      _account = picked;
    });
    await _loadFree();
  }

  Future<void> _pickDue() async {
    _nameFocus.unfocus();
    final now = widget.now();
    final first = DateTime(now.year, now.month, now.day + 1);
    final start = _due ?? DateTime(now.year, now.month + 1, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: start.isBefore(first) ? first : start,
      firstDate: first,
      lastDate: DateTime(now.year + 30),
    );
    _nameFocus.unfocus();
    if (picked != null) {
      setState(() => _due = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickPeriod() async {
    final l = AppLocalizations.of(context);
    final picked = await showChoiceSheet<PlanPeriod>(
      context,
      title: l.projectPeriod,
      selected: _period,
      options: [
        (PlanPeriod.week, l.projectWeek),
        (PlanPeriod.fortnight, l.projectFortnight),
        (PlanPeriod.month, l.projectMonth),
      ],
    );
    if (picked != null) setState(() => _period = picked);
  }

  bool get _ready =>
      _name.text.trim().isNotEmpty && _account != null && _goal.minor > 0;

  Future<void> _save() async {
    setState(() => _tried = true);
    if (!_ready || _saving) return;
    setState(() => _saving = true);
    if (widget.editing case final p?) {
      await widget.projects.edit(
        p.id,
        name: _name.text,
        icon: _icon,
        goal: _goal.minor,
        due: _due,
        period: _period,
        remind: _remind,
        accountId: _account!.id,
      );
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    final now = widget.now();
    await widget.projects.create(
      name: _name.text,
      icon: _icon,
      accountId: _account!.id,
      goal: _goal.minor,
      startedOn: DateTime(now.year, now.month, now.day),
      due: _due,
      period: _period,
      remind: _remind,
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = _currency;
    final account = _account;
    final due = _due;
    final periodName = switch (_period) {
      PlanPeriod.week => l.projectWeek,
      PlanPeriod.fortnight => l.projectFortnight,
      PlanPeriod.month => l.projectMonth,
    };
    final rhythm = switch (_period) {
      PlanPeriod.week => l.projectRemindWeek,
      PlanPeriod.fortnight => l.projectRemindFortnight,
      PlanPeriod.month => l.projectRemindMonth,
    };
    final now = widget.now();
    final per = currency == null || due == null || _goal.minor <= 0
        ? null
        : perPeriod(
            goal: _goal.minor,
            saved: widget.editing?.saved.minor ?? 0,
            today: now,
            due: due,
            period: _period,
            unit: unitOf(currency.code),
          );
    Widget row({
      required IconData icon,
      required String label,
      required String value,
      String? side,
      required VoidCallback onTap,
    }) => InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: KibuoColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: KibuoColors.inkSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: KibuoType.caption),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KibuoType.rowLabel.weight(600),
                  ),
                ],
              ),
            ),
            if (side != null) ...[
              const SizedBox(width: 8),
              Text(
                side,
                style: KibuoType.body.copyWith(
                  fontSize: 13,
                  color: KibuoColors.inkSecondary,
                ),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(
              KibuoIcons.caretRight,
              size: 18,
              color: KibuoColors.lineStrong,
            ),
          ],
        ),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FormTopBar(
              title: widget.editing == null
                  ? l.projectNewTitle
                  : l.projectEditTitle,
              cancel: l.cancel,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                    decoration: BoxDecoration(
                      color: KibuoColors.surface,
                      borderRadius: BorderRadius.circular(
                        KibuoTheme.radiusCard,
                      ),
                    ),
                    child: Row(
                      children: [
                        Semantics(
                          button: true,
                          label: l.projectIconTitle,
                          child: GestureDetector(
                            onTap: _pickIcon,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: KibuoColors.projectTint,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    projectIcon(_icon),
                                    size: 22,
                                    color: KibuoColors.projectInk,
                                  ),
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: KibuoColors.surface,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x330E1320),
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      KibuoIcons.caretDown,
                                      size: 12,
                                      color: KibuoColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.projectName, style: KibuoType.caption),
                              TextField(
                                controller: _name,
                                focusNode: _nameFocus,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                onChanged: (_) => setState(() {}),
                                onTap: () {
                                  if (_keypad) {
                                    setState(() => _keypad = false);
                                  }
                                },
                                style: KibuoType.itemName.copyWith(
                                  fontSize: 18,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: l.projectNameHint,
                                  hintStyle: KibuoType.itemName.copyWith(
                                    fontSize: 18,
                                    color: KibuoColors.inkMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_tried && _name.text.trim().isEmpty) ...[
                    const SizedBox(height: 4),
                    HelpText(l.projectNameMissing),
                  ],
                  if (currency != null) ...[
                    const SizedBox(height: 14),
                    ValueField(
                      key: _goalKey,
                      label: l.projectGoal,
                      value: shownTyped(context, _typed),
                      unit: currency.code,
                      focused: _keypad,
                      onTap: _openKeypad,
                      error: _tried && _goal.minor <= 0
                          ? l.projectGoalMissing
                          : null,
                    ),
                  ],
                  const SizedBox(height: 14),
                  SettingsCard(
                    children: [
                      row(
                        icon: KibuoIcons.wallet,
                        label: l.entryAccount,
                        value: account?.name ?? l.entryNoAccount,
                        side: _free == null
                            ? null
                            : l.projectFree(
                                formatMoney(_free!, currency!, _lang),
                              ),
                        onTap: _pickAccount,
                      ),
                      row(
                        icon: KibuoIcons.calendarBlank,
                        label: l.entryDate,
                        value: due == null
                            ? l.projectsNoDate
                            : l.projectsBefore(
                                DateFormat.MMMMd(_lang).format(due),
                              ),
                        side: l.projectOptional,
                        onTap: _pickDue,
                      ),
                    ],
                  ),
                  if (due != null)
                    ActionUnderCard(
                      label: l.projectNoDate,
                      color: KibuoColors.accent,
                      onPressed: () => setState(() => _due = null),
                    ),
                  if (per != null && per > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: KibuoColors.projectTint,
                        borderRadius: BorderRadius.circular(
                          KibuoTheme.radiusTile,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            KibuoIcons.info,
                            size: 16,
                            color: KibuoColors.projectInk,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            // The amount per period in bold (canvas
                            // ProjetNouveau).
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: l.projectEffortLead),
                                  TextSpan(
                                    text: l.projectEffortAmount(
                                      formatMoney(
                                        Money(per, currency!.code),
                                        currency,
                                        _lang,
                                      ),
                                      periodName.toLowerCase(),
                                    ),
                                    style: const TextStyle().weight(700),
                                  ),
                                  TextSpan(
                                    text: l.projectEffortUntil(
                                      DateFormat.MMMMd(_lang).format(due!),
                                    ),
                                  ),
                                ],
                              ),
                              style: KibuoType.body.copyWith(
                                fontSize: 13,
                                height: 18 / 13,
                                color: KibuoColors.projectInk,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SettingsCard(
                    children: [
                      row(
                        icon: KibuoIcons.calendarBlank,
                        label: l.projectPeriod,
                        value: periodName,
                        onTap: _pickPeriod,
                      ),
                      SettingsSwitch(
                        label: l.projectRemind,
                        help: rhythm,
                        value: _remind,
                        onChanged: (on) => setState(() => _remind = on),
                      ),
                    ],
                  ),
                  if (widget.editing case final p?)
                    ActionUnderCard(
                      label: l.projectDelete,
                      color: KibuoColors.danger,
                      onPressed: () async {
                        final gone = await deleteProject(
                          context,
                          projects: widget.projects,
                          project: p,
                          payments: widget.payments,
                        );
                        if (gone && context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                    ),
                ],
              ),
            ),
            if (_keypad && currency != null)
              KeypadPanel(
                keypad: KibuoKeypad(
                  onKey: (k) => setState(
                    () => _typed = typeKey(
                      _typed,
                      k,
                      decimals: currency.usesDecimals ? currency.digits : 0,
                    ),
                  ),
                  onDelete: () => setState(() {
                    if (_typed.isNotEmpty) {
                      _typed = _typed.substring(0, _typed.length - 1);
                    }
                  }),
                  allowDecimal: currency.usesDecimals,
                  decimalSeparator: NumberFormat.decimalPattern(_lang)
                      .symbols
                      .DECIMAL_SEP,
                ),
                done: l.keypadDone,
                onDone: () => setState(() => _keypad = false),
              )
            else
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.viewInsetsOf(context).bottom > 0 ? 8 : 24,
                ),
                child: KibuoButton(
                  label: widget.editing == null
                      ? l.projectCreate
                      : l.projectSave,
                  onPressed: _saving ? null : _save,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
