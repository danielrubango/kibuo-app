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
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

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
    setState(() {
      _custom = custom;
      _currency = currency;
    });
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  void _key(String k) => setState(() {
    final c = _currency;
    if (c == null) return;
    if (k == ',') {
      if (c.usesDecimals && !_typed.contains(',')) {
        _typed = _typed.isEmpty ? '0,' : '$_typed,';
      }
      return;
    }
    final parts = _typed.split(',');
    if (parts.length == 2 && parts[1].length >= c.digits) return;
    if (parts[0].length >= 12) return;
    _typed = _typed == '0' ? k : '$_typed$k';
  });

  void _delete() => setState(() {
    if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
  });

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
      );
    } else {
      await widget.accounts.update(account.id, name: _name.text, type: _type);
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final labels = AccountTypeLabels(l, _custom);
    final currency = _currency;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
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
                    error: _named || _name.text.trim().isNotEmpty
                        ? null
                        : l.accountNameMissing,
                  ),
                  // The starting balance and its currency are set once.
                  if (!_editing && currency != null) ...[
                    const SizedBox(height: 16),
                    ValueField(
                      label: l.accountOpening,
                      value: _shown(),
                      unit: currency.code,
                      onUnitTap: _pickCurrency,
                      focused: _keypad,
                      onTap: () => setState(() => _keypad = true),
                      note: l.accountCurrencyNote(
                        currencyName(context, currency),
                        currency.code,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FieldLabel(l.accountOpeningDate),
                    _DateRow(text: _dateText(l), onTap: _pickDate),
                    const SizedBox(height: 6),
                    HelpText(l.accountOpeningDateHelp),
                  ],
                  if (_editing) ...[
                    const SizedBox(height: 20),
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
            Container(
              padding: EdgeInsets.fromLTRB(16, _keypad ? 10 : 8, 16, 16),
              // Open, the keypad sits on a panel like a sheet's (Lancement3).
              decoration: _keypad
                  ? const BoxDecoration(
                      color: KibuoColors.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(KibuoTheme.radiusSheet),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x2E0E1320),
                          blurRadius: 30,
                          offset: Offset(0, -10),
                        ),
                      ],
                    )
                  : null,
              child: _keypad
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: KibuoColors.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        KibuoKeypad(
                          onKey: _key,
                          onDelete: _delete,
                          allowDecimal: currency?.usesDecimals ?? false,
                          decimalSeparator: NumberFormat.decimalPattern(_lang)
                              .symbols
                              .DECIMAL_SEP,
                        ),
                        const SizedBox(height: 8),
                        KibuoButton(
                          label: l.keypadDone,
                          kind: ButtonKind.dark,
                          onPressed: () => setState(() => _keypad = false),
                        ),
                      ],
                    )
                  : KibuoButton(
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

/// « Annuler » on the left, the title in the middle: the top of a creation
/// screen (DIRECTION).
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.cancel});

  final String title;
  final String cancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextAction(
                label: cancel,
                color: KibuoColors.inkSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: KibuoType.button,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 96),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  KibuoIcons.calendarBlank,
                  size: 20,
                  color: KibuoColors.inkSecondary,
                ),
                const SizedBox(width: 10),
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
