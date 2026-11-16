import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_type_screen.dart';
import 'package:kibuo/ui/accounts/account_types.dart';
import 'package:kibuo/ui/device_country.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/form_top_bar.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_sheets.dart';

/// « Nouveau compte » (canvas: CompteNouveau): type, name, starting balance
/// with its currency on the right, and the balance's date. For [account],
/// « Modifier le compte » (CompteModifA): type and name only, the starting
/// balance being set once; then « Archiver le compte ». Pops true when
/// something changed.
class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({
    super.key,
    required this.accounts,
    required this.currencies,
    this.account,
  });

  final AccountRepository accounts;
  final CurrencyRepository currencies;
  final AccountInfo? account;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  late final _name = TextEditingController(text: widget.account?.name ?? '');
  late AccountType _type = widget.account?.type ?? AccountType.mobile;
  List<CustomAccountType> _custom = const [];
  CurrencyInfo? _currency;
  String _typed = '';
  DateTime _date = _today();
  bool _keypad = false;
  final _openingKey = GlobalKey();

  // The overdraft (PRODUCT): off at creation; the limit is typed on the
  // same keypad as the starting balance.
  late bool _overdraft = widget.account?.overdraft.allowed ?? false;
  String _limit = '';
  bool _typingLimit = false;
  final _limitKey = GlobalKey();
  bool _named = true;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  bool get _editing => widget.account != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final custom = await widget.accounts.types();
    final account = widget.account;
    final code =
        account?.currency ??
        await widget.currencies.primaryCurrency() ??
        defaultPrimaryCurrency(await deviceCountry());
    final currency = await widget.currencies.currency(code);
    if (!mounted) return;
    final limit = account?.overdraft.limit;
    setState(() {
      _custom = custom;
      _currency = currency;
      if (limit != null && limit > 0) {
        _limit = typedFrom(Money(limit, currency.code), currency);
      }
    });
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  void _key(String k) => setState(() {
    final c = _currency;
    if (c == null) return;
    // The keypad shows « , » with cents, « 000 » without (PRODUCT).
    final decimals = c.usesDecimals ? c.digits : 0;
    if (_typingLimit) {
      _limit = typeKey(_limit, k, decimals: decimals);
    } else {
      _typed = typeKey(_typed, k, decimals: decimals);
    }
  });

  void _delete() => setState(() {
    if (_typingLimit) {
      if (_limit.isNotEmpty) _limit = _limit.substring(0, _limit.length - 1);
    } else if (_typed.isNotEmpty) {
      _typed = _typed.substring(0, _typed.length - 1);
    }
  });

  /// Opens Kibuo's keypad on the starting balance or on the limit.
  void _openKeypad({required bool limit}) {
    // The phone's keyboard gives way to Kibuo's.
    FocusScope.of(context).unfocus();
    setState(() {
      _keypad = true;
      _typingLimit = limit;
    });
    revealAboveKeypad(limit ? _limitKey : _openingKey);
  }

  Overdraft get _overdraftChoice {
    final limit = typedMoney(_limit, _currency!).minor;
    return Overdraft(allowed: _overdraft, limit: limit == 0 ? null : limit);
  }

  /// « 1 200,5 » as the field shows it.
  String _shown() {
    final numbers = NumberFormat.decimalPattern(_lang);
    final parts = _typed.split(',');
    final whole = parts[0].isEmpty
        ? ''
        : numbers.format(int.parse(parts[0])).replaceAll(' ', ' ');
    return parts.length == 2
        ? '$whole${numbers.symbols.DECIMAL_SEP}${parts[1]}'
        : whole;
  }

  Money get _opening {
    final c = _currency!;
    final typed = _typed.isEmpty ? '0' : _typed.replaceAll(',', '.');
    return Money.fromMajor(typed.endsWith('.') ? '${typed}0' : typed, c);
  }

  Future<void> _pickCurrency() async {
    final l = AppLocalizations.of(context);
    final mine = await widget.currencies.currencyCodes();
    final country = await deviceCountry();
    if (!mounted) return;
    final code = await pickCurrency(
      context,
      title: l.currencyPickerTitle,
      current: _currency?.code,
      country: country,
      yoursFirst: mine,
      onlyYours: true,
    );
    if (code == null) return;
    final currency = await widget.currencies.currency(code);
    if (mounted) {
      setState(() {
        _currency = currency;
        _typed = '';
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.toLocal(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime.utc(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _newType() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AccountTypeScreen(accounts: widget.accounts),
      ),
    );
    if (id == null) return;
    final custom = await widget.accounts.types();
    if (mounted) {
      setState(() {
        _custom = custom;
        _type = AccountType.custom(id);
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _named = false);
      return;
    }
    final account = widget.account;
    if (account == null) {
      await widget.accounts.create(
        name: _name.text,
        type: _type,
        opening: _opening,
        openingDate: _date,
        overdraft: _overdraftChoice,
      );
    } else {
      await widget.accounts.update(
        account.id,
        name: _name.text,
        type: _type,
        overdraft: _overdraftChoice,
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _archive() async {
    await widget.accounts.archive(widget.account!.id);
    if (mounted) Navigator.of(context).pop(true);
  }

  String _dateText(AppLocalizations l) {
    final day = DateFormat.MMMMd(_lang).format(_date);
    if (_date == _today()) return l.accountToday(day);
    return DateFormat.yMMMMd(_lang).format(_date);
  }

  /// « Autoriser le découvert » and, once on, « Jusqu'à » in the same card
  /// (canvas DecouvertA).
  Widget _overdraftCard(AppLocalizations l, CurrencyInfo currency) {
    return Container(
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.overdraftAllow, style: KibuoType.rowLabel),
                      Text(l.overdraftAllowHelp, style: KibuoType.caption),
                    ],
                  ),
                ),
                Switch(
                  value: _overdraft,
                  onChanged: (on) => setState(() {
                    _overdraft = on;
                    if (!on && _typingLimit) _keypad = false;
                  }),
                ),
              ],
            ),
          ),
          if (_overdraft) ...[
            const Divider(height: 1, color: KibuoColors.background),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ValueField(
                key: _limitKey,
                label: l.overdraftUpTo,
                value: shownTyped(context, _limit),
                placeholder: l.overdraftNoLimit,
                unit: currency.code,
                fill: KibuoColors.background,
                focused: _keypad && _typingLimit,
                onTap: () => _openKeypad(limit: true),
                note: l.overdraftNoLimitHelp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Turning the overdraft off on an account already below zero is allowed,
  /// with a warning (canvas DecouvertSousZero).
  List<Widget> _belowZeroWarning(AppLocalizations l) {
    final account = widget.account;
    if (_overdraft || account == null || account.balance.minor >= 0) {
      return const [];
    }
    final balance = formatMoney(
      account.balance,
      currencyOf(account.currency),
      _lang,
    );
    return [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: KibuoColors.warningTint,
          borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
        ),
        child: Text(
          l.overdraftBelowZero(account.name, balance),
          style: KibuoType.help.copyWith(color: KibuoColors.warningInk),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = AccountTypeLabels(l, _custom);
    final currency = _currency;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FormTopBar(
              title: _editing ? l.accountEditTitle : l.accountNewTitle,
              cancel: l.cancel,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  FieldLabel(l.accountTypeLabel),
                  _TypeGrid(
                    labels: labels,
                    chosen: _type,
                    onPick: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: 8),
                  KibuoButton(
                    label: l.accountTypeCreate,
                    kind: ButtonKind.create,
                    onPressed: _newType,
                  ),
                  const SizedBox(height: 16),
                  KibuoTextField(
                    label: l.accountName,
                    hint: l.accountNameHint,
                    controller: _name,
                    onFocus: () {
                      if (_keypad) setState(() => _keypad = false);
                    },
                    error: _named || _name.text.trim().isNotEmpty
                        ? null
                        : l.accountNameMissing,
                  ),
                  // The starting balance and its currency are set once.
                  if (!_editing && currency != null) ...[
                    const SizedBox(height: 16),
                    ValueField(
                      key: _openingKey,
                      label: l.accountOpening,
                      value: _shown(),
                      unit: currency.code,
                      onUnitTap: _pickCurrency,
                      focused: _keypad && !_typingLimit,
                      onTap: () => _openKeypad(limit: false),
                      note: l.accountCurrencyNote(
                        currencyName(context, currency),
                        currency.code,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(l.accountOpeningDate),
                    _DateRow(text: _dateText(l), onTap: _pickDate),
                    const SizedBox(height: 8),
                    HelpText(l.accountOpeningDateHelp),
                  ],
                  if (currency != null) ...[
                    const SizedBox(height: 16),
                    FieldLabel(l.overdraftLabel),
                    _overdraftCard(l, currency),
                    ..._belowZeroWarning(l),
                  ],
                  if (_editing) ...[
                    const SizedBox(height: 24),
                    SettingsCard(
                      children: [
                        SettingsRow(
                          label: l.accountArchive,
                          danger: true,
                          onTap: _archive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    HelpText(l.accountArchiveHelp),
                  ],
                ],
              ),
            ),
            if (_keypad)
              KeypadPanel(
                keypad: KibuoKeypad(
                  onKey: _key,
                  onDelete: _delete,
                  allowDecimal: currency?.usesDecimals ?? false,
                  decimalSeparator: NumberFormat.decimalPattern(_lang)
                      .symbols
                      .DECIMAL_SEP,
                ),
                done: l.keypadDone,
                onDone: () => setState(() => _keypad = false),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: KibuoButton(
                  label: _editing ? l.accountSave : l.accountCreate,
                  onPressed: currency == null ? null : _save,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeGrid extends StatelessWidget {
  const _TypeGrid({
    required this.labels,
    required this.chosen,
    required this.onPick,
  });

  final AccountTypeLabels labels;
  final AccountType chosen;
  final ValueChanged<AccountType> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in labels.all)
              SizedBox(
                width: width,
                child: _TypeChip(
                  icon: labels.icon(t),
                  label: labels.name(t),
                  on: t == chosen,
                  onTap: () => onPick(t),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = on ? KibuoColors.surface : KibuoColors.ink;
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? KibuoColors.ink : KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: KibuoTheme.heightTouch,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KibuoType.rowLabel.copyWith(color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KibuoColors.surface,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: KibuoTheme.heightField,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  KibuoIcons.calendarBlank,
                  size: 20,
                  color: KibuoColors.inkSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: KibuoType.body.copyWith(fontSize: 16),
                  ),
                ),
                const Icon(
                  KibuoIcons.caretRight,
                  size: 16,
                  color: KibuoColors.inkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
