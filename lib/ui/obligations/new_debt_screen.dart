import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/choice_sheet.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/form_top_bar.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/kit/segmented_tabs.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/obligations/debt_saved_sheet.dart';
import 'package:kibuo/ui/recurrences/recurrences_screen.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/entry_sheets.dart';
import 'package:uuid/uuid.dart';

/// « Nouvelle dette ou créance » (canvas NouvelleDette): who, how much in
/// the debt's own currency, the due date, and whether money moved on an
/// account. Pops with what was saved.
class NewDebtScreen extends StatefulWidget {
  const NewDebtScreen({
    super.key,
    required this.data,
    required this.debts,
    this.direction = DebtDirection.owe,
    this.now = DateTime.now,
  });

  final EntryData data;
  final DebtRepository debts;
  final DebtDirection direction;
  final DateTime Function() now;

  @override
  State<NewDebtScreen> createState() => _NewDebtScreenState();
}

class _NewDebtScreenState extends State<NewDebtScreen> {
  late DebtDirection _direction = widget.direction;

  /// Its id from the start: its « Rappel » is kept under it.
  final _id = const Uuid().v7();
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _amountKey = GlobalKey();
  String _typed = '';
  bool _keypad = false;
  bool _tried = false;
  bool _saving = false;
  bool _typingName = false;

  List<AccountInfo> _accounts = const [];
  List<String> _codes = const [];
  List<String> _people = const [];
  String? _currency;
  AccountInfo? _account;
  bool _link = true;
  DateTime? _due;

  /// Today's rate between the debt's and the account's currencies, and
  /// one typed instead.
  ExchangeRate? _today;
  bool _rateTyped = false;
  String _rateText = '';

  @override
  void initState() {
    super.initState();
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
    final codes = await widget.data.currencies.currencyCodes();
    final primary = await widget.data.currencies.primaryCurrency();
    final people = await widget.debts.people();
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _codes = codes;
      _people = people;
      _account = accounts.isEmpty ? null : accounts.first;
      _link = accounts.isNotEmpty;
      _currency = _account?.currency ?? primary ?? codes.firstOrNull;
    });
    await _loadToday();
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  bool get _owe => _direction == DebtDirection.owe;

  bool get _converts =>
      _link &&
      _account != null &&
      _currency != null &&
      _account!.currency != _currency;

  (String, String) get _rateWay => rateDirection(
    main: currencyOf(_account!.currency),
    other: currencyOf(_currency!),
  );

  ExchangeRate? get _rate {
    if (!_converts) return null;
    if (!_rateTyped) return _today;
    final value = RateValue.tryParse(_rateText);
    if (value == null) return null;
    final (base, quote) = _rateWay;
    return ExchangeRate(base: base, quote: quote, value: value);
  }

  Future<void> _loadToday() async {
    if (!_converts) {
      setState(() => _today = null);
      return;
    }
    final (base, quote) = _rateWay;
    final info = await widget.data.currencies.latestRate(
      _account!.currency,
      _currency!,
    );
    if (!mounted) return;
    setState(() {
      _today = info?.rate.toward(base, quote);
      _rateTyped = _today == null;
      _rateText = '';
    });
  }

  Money get _amount => typedMoney(_typed, currencyOf(_currency!));

  void _key(String k) => setState(() {
    final c = currencyOf(_currency!);
    _typed = typeKey(_typed, k, decimals: c.usesDecimals ? c.digits : 0);
  });

  void _delete() => setState(() {
    if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
  });

  void _openKeypad() {
    FocusScope.of(context).unfocus();
    setState(() {
      _keypad = true;
      _typingName = false;
    });
    revealAboveKeypad(_amountKey);
  }

  Future<void> _pickCurrency() async {
    _nameFocus.unfocus();
    final picked = await showChoiceSheet<String>(
      context,
      title: AppLocalizations.of(context).debtCurrency,
      selected: _currency,
      options: [
        for (final code in _codes)
          (code, '${currencyName(context, currencyOf(code))} · $code'),
      ],
    );
    _nameFocus.unfocus();
    if (picked == null || picked == _currency) return;
    setState(() {
      _currency = picked;
      _typed = '';
    });
    await _loadToday();
  }

  Future<void> _pickAccount() async {
    _nameFocus.unfocus();
    final picked = await pickAccount(
      context,
      accounts: _accounts,
      current: _account?.id,
    );
    _nameFocus.unfocus();
    if (picked == null) return;
    setState(() => _account = picked);
    await _loadToday();
  }

  Future<void> _pickRate() async {
    final (base, quote) = _rateWay;
    final choice = await pickEntryRate(
      context,
      income: _owe,
      paid: formatMoney(_amount, currencyOf(_currency!), _lang),
      base: base,
      quote: quote,
      today: _today,
      current: RateChoice(typed: _rateTyped, value: _rateText),
    );
    if (choice != null) {
      setState(() {
        _rateTyped = choice.typed;
        _rateText = choice.value ?? '';
      });
    }
  }

  Future<void> _pickDue() async {
    _nameFocus.unfocus();
    final now = widget.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime(now.year, now.month, now.day + 7),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 30),
    );
    // Closing the calendar gives the name its focus back: the keyboard
    // stays closed.
    _nameFocus.unfocus();
    if (picked != null) {
      setState(() => _due = DateTime(picked.year, picked.month, picked.day));
    }
  }

  String _dueText(AppLocalizations l) {
    final due = _due;
    if (due == null) return l.debtsNoDue;
    final t = DateFormat.yMMMMd(_lang).format(due);
    return t[0].toUpperCase() + t.substring(1);
  }

  bool get _named => _name.text.trim().isNotEmpty;

  bool get _ready =>
      _currency != null &&
      _amount.minor > 0 &&
      (!_link || (_account != null && (!_converts || _rate != null)));

  Future<void> _save() async {
    setState(() => _tried = true);
    if (!_named || !_ready || _saving) return;
    setState(() => _saving = true);
    final now = widget.now();
    final id = await widget.debts.create(
      id: _id,
      direction: _direction,
      person: _name.text,
      amount: _amount,
      // Its operation shows the time it was noted, like any other.
      openedOn: now,
      due: _due,
      accountId: _link ? _account?.id : null,
      rate: _rate,
      rateTyped: _rateTyped,
    );
    if (mounted) {
      Navigator.of(context).pop(
        SavedDebt(
          id: id,
          direction: _direction,
          account: _link ? _account?.name : null,
        ),
      );
    }
  }

  /// The names already used that start like the one typed.
  List<String> get _suggestions {
    if (!_typingName) return const [];
    final typed = debtPersonKey(_name.text);
    if (typed.isEmpty) return const [];
    return [
      for (final p in _people)
        if (debtPersonKey(p).startsWith(typed) && debtPersonKey(p) != typed) p,
    ].take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = _currency;
    final account = _account;
    final suggestions = _suggestions;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FormTopBar(title: l.addDebtTitle, cancel: l.cancel),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  SegmentedTabs<DebtDirection>(
                    items: [
                      (DebtDirection.owe, l.debtsOwe),
                      (DebtDirection.owed, l.debtsOwed),
                    ],
                    value: _direction,
                    onPick: (d) => setState(() => _direction = d),
                  ),
                  const SizedBox(height: 16),
                  KibuoTextField(
                    label: _owe ? l.debtPersonOwe : l.debtPersonOwed,
                    hint: l.debtPersonHint,
                    controller: _name,
                    focusNode: _nameFocus,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() => _typingName = true),
                    onFocus: () {
                      if (_keypad) setState(() => _keypad = false);
                    },
                    error: _tried && !_named ? l.debtPersonMissing : null,
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SettingsCard(
                      children: [
                        for (final p in suggestions)
                          _Suggestion(
                            name: p,
                            onTap: () {
                              _name.text = p;
                              _name.selection = TextSelection.collapsed(
                                offset: p.length,
                              );
                              setState(() => _typingName = false);
                            },
                          ),
                      ],
                    ),
                  ],
                  if (currency != null) ...[
                    const SizedBox(height: 16),
                    ValueField(
                      key: _amountKey,
                      label: _link ? l.entryAmount : l.debtLeft,
                      value: shownTyped(context, _typed),
                      unit: currency,
                      onUnitTap: _pickCurrency,
                      focused: _keypad,
                      onTap: _openKeypad,
                      error: _tried && _amount.minor <= 0
                          ? l.debtAmountMissing
                          : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  FieldLabel(l.debtDue),
                  DateField(text: _dueText(l), onTap: _pickDue),
                  if (_due != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextAction(
                        label: l.debtDueClear,
                        onPressed: () => setState(() => _due = null),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SettingsCard(
                    children: [
                      SettingsSwitch(
                        label: _owe ? l.debtLinkOwe : l.debtLinkOwed,
                        help: !_link
                            ? l.debtLinkOffHelp
                            : account == null
                            ? l.entryNoAccount
                            : l.debtLinkHelp(account.name),
                        value: _link,
                        onChanged: _accounts.isEmpty
                            ? null
                            : (on) async {
                                setState(() => _link = on);
                                await _loadToday();
                              },
                      ),
                      if (_link && account != null && _accounts.length > 1)
                        SettingsRow(
                          label: l.entryAccount,
                          value: account.name,
                          onTap: _pickAccount,
                        ),
                      if (_converts)
                        SettingsRow(
                          label: l.entryRateTitle,
                          value: _rate == null ? '' : formatRate(_rate!, _lang),
                          onTap: _pickRate,
                        ),
                    ],
                  ),
                  // Its own reminder, once it has a due date (PRODUCT).
                  if (_due != null && widget.data.reminders != null) ...[
                    const SizedBox(height: 16),
                    SettingsCard(
                      children: [
                        RuleReminderField(
                          store: widget.data.reminders!,
                          ruleId: _id,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_keypad && currency != null)
              KeypadPanel(
                keypad: KibuoKeypad(
                  onKey: _key,
                  onDelete: _delete,
                  allowDecimal: currencyOf(currency).usesDecimals,
                  decimalSeparator: NumberFormat.decimalPattern(_lang)
                      .symbols
                      .DECIMAL_SEP,
                ),
                done: l.keypadDone,
                onDone: () => setState(() => _keypad = false),
              )
            else
              Padding(
                // The screen rises with the phone's keyboard: 8 above it.
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.viewInsetsOf(context).bottom > 0 ? 8 : 24,
                ),
                child: KibuoButton(
                  label: l.entrySave,
                  onPressed: _saving ? null : _save,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A name already used, offered while typing.
class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      height: KibuoTheme.heightTouch,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: KibuoType.body.copyWith(fontSize: 15, color: KibuoColors.ink),
      ),
    ),
  );
}

/// The form, then « Dette enregistrée »; « Nouvelle dette » there opens the
/// form again. Returns the direction of the last debt saved, if any.
Future<DebtDirection?> runNewDebt(
  BuildContext context, {
  required EntryData data,
  required DebtRepository debts,
  DebtDirection direction = DebtDirection.owe,
  DateTime Function() now = DateTime.now,
  VoidCallback? onSaved,
}) async {
  DebtDirection? last;
  var next = direction;
  while (true) {
    if (!context.mounted) return last;
    final saved = await Navigator.of(context).push<SavedDebt>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            NewDebtScreen(data: data, debts: debts, direction: next, now: now),
      ),
    );
    if (saved == null || !context.mounted) return last;
    last = saved.direction;
    onSaved?.call();
    final debt = (await debts.debts()).where((d) => d.id == saved.id);
    if (debt.isEmpty || !context.mounted) return last;
    final again = await showDebtSavedSheet(
      context,
      debt.single,
      account: saved.account,
    );
    if (again != true) return last;
    next = saved.direction;
  }
}
