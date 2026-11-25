import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_type_screen.dart';
import 'package:kibuo/ui/accounts/account_types.dart';
import 'package:kibuo/ui/accounts/account_types_screen.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/device_country.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/form_top_bar.dart';
import 'package:kibuo/ui/kit/icon_tile.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/protect_sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
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
    this.categories,
    this.transactions,
    this.intro,
    this.action,
    this.onCreated,
  });

  /// The first launch's step 3 (canvas Lancement3, Lancement3Decouvert):
  /// [intro] in place of the top bar, no balance date (today), [action] on
  /// the button, and [onCreated] instead of closing.
  final Widget? intro;
  final String? action;
  final ValueChanged<String>? onCreated;

  bool get _firstLaunch => intro != null;

  final AccountRepository accounts;
  final CurrencyRepository currencies;

  /// Where a corrected balance's difference goes (PRODUCT: Régularisation);
  /// without them, « Solde actuel » isn't offered.
  final CategoryRepository? categories;
  final TransactionRepository? transactions;
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

  /// A starting balance below zero, with the overdraft only (PRODUCT).
  bool _openingNegative = false;
  DateTime _date = _today();
  bool _keypad = false;
  final _openingKey = GlobalKey();

  // The overdraft (PRODUCT): off at creation; the limit is typed on the
  // same keypad as the starting balance.
  late bool _overdraft = widget.account?.overdraft.allowed ?? false;
  String _limit = '';
  _Typing _typing = _Typing.opening;
  bool get _typingLimit => _typing == _Typing.limit;

  // « Solde actuel » (canvas RegulFormA): today's balance, typed again.
  String _current = '';
  bool _currentNegative = false;
  final _currentKey = GlobalKey();
  final _nameKey = GlobalKey();
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
      if (account != null) {
        _current = typedFrom(account.balance, currency);
        _currentNegative = account.balance.minor < 0;
      }
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
    switch (_typing) {
      case _Typing.opening:
        _typed = typeKey(_typed, k, decimals: decimals);
      case _Typing.limit:
        _limit = typeKey(_limit, k, decimals: decimals);
      case _Typing.current:
        _current = typeKey(_current, k, decimals: decimals);
    }
  });

  String _erase(String s) => s.isEmpty ? s : s.substring(0, s.length - 1);

  void _delete() => setState(() {
    switch (_typing) {
      case _Typing.opening:
        _typed = _erase(_typed);
      case _Typing.limit:
        _limit = _erase(_limit);
      case _Typing.current:
        _current = _erase(_current);
    }
  });

  /// Opens Kibuo's keypad on one of the form's values.
  void _openKeypad(_Typing typing) {
    // The phone's keyboard gives way to Kibuo's.
    FocusScope.of(context).unfocus();
    setState(() {
      _keypad = true;
      _typing = typing;
    });
    revealAboveKeypad(switch (typing) {
      _Typing.opening => _openingKey,
      _Typing.limit => _limitKey,
      _Typing.current => _currentKey,
    });
  }

  bool get _offersCurrent =>
      _editing && widget.categories != null && widget.transactions != null;

  /// The balance typed in « Solde actuel », with its sign.
  Money? get _currentTyped {
    final c = _currency;
    if (!_offersCurrent || c == null) return null;
    final m = typedMoney(_current, c);
    return _currentNegative ? Money(-m.minor, m.currency) : m;
  }

  /// The difference to add, or zero when the balance is unchanged.
  int get _difference {
    final typed = _currentTyped;
    return typed == null ? 0 : typed.minor - widget.account!.balance.minor;
  }

  /// A typed balance below the floor the form's overdraft allows.
  bool get _currentRefused {
    final typed = _currentTyped;
    return typed != null &&
        _difference < 0 &&
        !_overdraftChoice.allows(typed.minor);
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
    final m = Money.fromMajor(typed.endsWith('.') ? '${typed}0' : typed, c);
    return _openingNegative ? Money(-m.minor, m.currency) : m;
  }

  /// A negative starting balance past the overdraft's limit.
  bool get _openingRefused =>
      !_editing &&
      _currency != null &&
      _opening.minor < 0 &&
      !_overdraftChoice.allows(_opening.minor);

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

  Future<void> _manageTypes() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => AccountTypesScreen(accounts: widget.accounts),
      ),
    );
    final custom = await widget.accounts.types();
    if (!mounted) return;
    setState(() {
      _custom = custom;
      // The type chosen here was removed: back to the first one.
      if (!AccountType.provided.contains(_type) &&
          !custom.any((c) => c.type == _type)) {
        _type = AccountType.provided.first;
      }
    });
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
      showMissing(_nameKey);
      return;
    }
    final account = widget.account;
    if (account == null) {
      final id = await widget.accounts.create(
        name: _name.text,
        type: _type,
        opening: _opening,
        openingDate: _date,
        overdraft: _overdraftChoice,
      );
      if (widget.onCreated case final created?) {
        created(id);
        return;
      }
    } else {
      // A new balance: the difference becomes an operation, confirmed in a
      // sheet; closing it saves nothing (PRODUCT: Régularisation).
      final difference = _difference;
      if (difference != 0 && !await _confirmAdjustment(difference)) return;
      if (!mounted) return;
      // Correcting a balance or changing the overdraft are important
      // actions: the code when they ask for it (PRODUCT).
      final l = AppLocalizations.of(context);
      final before = account.overdraft;
      final after = _overdraftChoice;
      final overdraftChanged =
          before.allowed != after.allowed ||
          (after.allowed && (before.limit ?? 0) != (after.limit ?? 0));
      if (difference != 0 &&
          !await confirmWithCode(context, l.protectAdjust(account.name))) {
        return;
      }
      if (!mounted) return;
      if (overdraftChanged &&
          !await confirmWithCode(context, l.protectOverdraft(account.name))) {
        return;
      }
      if (!mounted) return;
      await widget.accounts.update(
        account.id,
        name: _name.text,
        type: _type,
        overdraft: _overdraftChoice,
      );
      if (difference != 0) await _addAdjustment(difference);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  CategoryInfo? _adjustCategory;

  Future<bool> _confirmAdjustment(int difference) async {
    final kind = difference < 0 ? CategoryKind.out : CategoryKind.into;
    final categories = await widget.categories!.categories(kind);
    if (!mounted) return false;
    final account = widget.account!;
    final currency = _currency!;
    String money(int minor) =>
        formatMoney(Money(minor, currency.code), currency, _lang);
    final id = adjustmentCategoryId(kind);
    _adjustCategory = categories.where((c) => c.id == id).firstOrNull;
    final go = await showKibuoSheet<bool>(
      context,
      title: AppLocalizations.of(context).adjustTitle(account.name),
      builder: (context) => _AdjustSheet(
        before: money(account.balance.minor),
        after: money(_currentTyped!.minor),
        amount: money(difference.abs()),
        kind: kind,
        categories: categories,
        initial: _adjustCategory,
        onCategory: (c) => _adjustCategory = c,
      ),
    );
    return (go ?? false) && _adjustCategory != null;
  }

  Future<void> _addAdjustment(int difference) async {
    final account = widget.account!;
    final currency = _currency!;
    String money(int minor) =>
        formatMoney(Money(minor, currency.code), currency, _lang);
    await widget.transactions!.create(
      kind: difference < 0 ? EntryKind.expense : EntryKind.income,
      accountId: account.id,
      categoryId: _adjustCategory!.id,
      paid: Money(difference.abs(), currency.code),
      fees: 0,
      date: DateTime.now(),
      note: AppLocalizations.of(
        context,
      ).adjustNote(money(account.balance.minor), money(_currentTyped!.minor)),
    );
  }

  /// « Archiver M-Pesa ? » (canvas ConfirmArchive), then the code when
  /// important actions ask for it.
  Future<void> _archive() async {
    final l = AppLocalizations.of(context);
    final account = widget.account!;
    final labels = AccountTypeLabels(l, _custom);
    final sure = await confirmRemoval(
      context,
      title: l.confirmArchiveTitle(account.name),
      summary: RemovalSummary(
        leading: _TypeTile(icon: labels.icon(account.type)),
        title: account.name,
        subtitle: '${labels.name(account.type)} · ${account.currency}',
        trailing: formatMoney(
          account.balance,
          currencyOf(account.currency),
          _lang,
        ),
      ),
      text: l.confirmArchiveHelp(account.name),
      action: l.confirmArchiveAction,
    );
    if (!sure || !mounted) return;
    if (!await confirmWithCode(context, l.protectArchive(account.name))) {
      return;
    }
    await widget.accounts.archive(account.id);
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
          SettingsSwitch(
            label: l.overdraftAllow,
            help: l.overdraftAllowHelp,
            value: _overdraft,
            onChanged: (on) => setState(() {
              _overdraft = on;
              if (!on) _openingNegative = false;
              if (!on && _typingLimit) _keypad = false;
            }),
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
                onTap: () => _openKeypad(_Typing.limit),
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
            if (!widget._firstLaunch)
              FormTopBar(
                title: _editing ? l.accountEditTitle : l.accountNewTitle,
                cancel: l.cancel,
              ),
            Expanded(
              child: ListView(
                padding: widget._firstLaunch
                    ? const EdgeInsets.fromLTRB(24, 32, 24, 24)
                    : const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  if (widget.intro case final intro?) ...[
                    intro,
                    const SizedBox(height: 18),
                  ],
                  // « Gérer » where types are met (PRODUCT); never in the
                  // first launch, before there is anything to manage.
                  FieldLabel(
                    l.accountTypeLabel,
                    action: widget._firstLaunch ? null : l.typesManage,
                    onAction: _manageTypes,
                  ),
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
                    key: _nameKey,
                    label: l.accountName,
                    hint: l.accountNameHint,
                    controller: _name,
                    onChanged: (_) {
                      if (!_named) setState(() {});
                    },
                    onFocus: () {
                      if (_keypad) setState(() => _keypad = false);
                    },
                    missing: !_named && _name.text.trim().isEmpty,
                  ),
                  if (_offersCurrent && currency != null) ...[
                    const SizedBox(height: 16),
                    ValueField(
                      key: _currentKey,
                      label: l.accountCurrentBalance,
                      value:
                          '${_currentNegative ? '−' : ''}'
                          '${shownTyped(context, _current)}',
                      unit: currency.code,
                      focused: _keypad && _typing == _Typing.current,
                      onTap: () => _openKeypad(_Typing.current),
                      // While typing it with overdraft allowed, how to make
                      // it negative (canvas SigneD); nothing about it
                      // otherwise.
                      note: _currentRefused
                          ? null
                          : _keypad && _typing == _Typing.current && _overdraft
                          ? l.accountMinusHint
                          : l.accountCurrentHelp(
                              formatMoney(
                                widget.account!.balance,
                                currency,
                                _lang,
                              ),
                            ),
                    ),
                    if (_currentRefused) ...[
                      const SizedBox(height: 4),
                      RefusalLine(
                        text: l.overdraftWouldGo(
                          widget.account!.name,
                          formatMoney(_currentTyped!, currency, _lang),
                        ),
                        action: l.overdraftAuthorize,
                        onAction: () => setState(() => _overdraft = true),
                      ),
                    ],
                  ],
                  // The starting balance and its currency are set once.
                  if (!_editing && currency != null) ...[
                    const SizedBox(height: 16),
                    ValueField(
                      key: _openingKey,
                      label: l.accountOpening,
                      value: '${_openingNegative ? '−' : ''}${_shown()}',
                      unit: currency.code,
                      onUnitTap: _pickCurrency,
                      focused: _keypad && _typing == _Typing.opening,
                      onTap: () => _openKeypad(_Typing.opening),
                      note: l.accountCurrencyNote(
                        currencyName(context, currency),
                        currency.code,
                      ),
                    ),
                    // With the overdraft, how to make it negative (canvas
                    // Lancement3Decouvert).
                    if (_overdraft) ...[
                      const SizedBox(height: 2),
                      HelpText(l.accountMinusHint),
                    ],
                    if (_openingRefused) ...[
                      const SizedBox(height: 4),
                      RefusalLine(
                        text: l.overdraftWouldGo(
                          _name.text.trim().isEmpty
                              ? l.accountOpening
                              : _name.text.trim(),
                          formatMoney(_opening, currency, _lang),
                        ),
                      ),
                    ],
                    if (!widget._firstLaunch) ...[
                      const SizedBox(height: 16),
                      FieldLabel(l.accountOpeningDate),
                      DateField(text: _dateText(l), onTap: _pickDate),
                      const SizedBox(height: 8),
                      HelpText(l.accountOpeningDateHelp),
                    ],
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
                  // « − » only for a balance that may go below zero.
                  onMinus: !_overdraft
                      ? null
                      : _typing == _Typing.current
                      ? () =>
                            setState(() => _currentNegative = !_currentNegative)
                      : _typing == _Typing.opening && !_editing
                      ? () =>
                            setState(() => _openingNegative = !_openingNegative)
                      : null,
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
                padding: widget._firstLaunch
                    ? const EdgeInsets.fromLTRB(24, 8, 24, 24)
                    : const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: KibuoButton(
                  label:
                      widget.action ??
                      (_editing ? l.accountSave : l.accountCreate),
                  onPressed:
                      currency == null ||
                          _currentRefused ||
                          _openingRefused ||
                          // Nothing typed yet (DIRECTION, 25 November).
                          (widget._firstLaunch &&
                              _name.text.trim().isEmpty &&
                              _typed.isEmpty &&
                              _current.isEmpty)
                      ? null
                      : _save,
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

enum _Typing { opening, limit, current }

/// « Corriger le solde de M-Pesa ? » (canvas RegulFeuille): before and
/// after, then the operation that makes up the difference, its category
/// changeable, and « Ajouter la régularisation ».
class _AdjustSheet extends StatefulWidget {
  const _AdjustSheet({
    required this.before,
    required this.after,
    required this.amount,
    required this.kind,
    required this.categories,
    required this.initial,
    required this.onCategory,
  });

  final String before;
  final String after;
  final String amount;
  final CategoryKind kind;
  final List<CategoryInfo> categories;
  final CategoryInfo? initial;
  final ValueChanged<CategoryInfo> onCategory;

  @override
  State<_AdjustSheet> createState() => _AdjustSheetState();
}

class _AdjustSheetState extends State<_AdjustSheet> {
  late CategoryInfo? _category = widget.initial;

  Future<void> _choose() async {
    final picked = await pickCategory(
      context,
      categories: widget.categories,
      current: _category?.id,
    );
    if (picked == null) return;
    widget.onCategory(picked);
    setState(() => _category = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final out = widget.kind == CategoryKind.out;
    Widget side(String label, String value, {bool muted = false}) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: KibuoType.caption),
          Text(
            value,
            style: KibuoType.cardTitle.copyWith(
              color: muted ? KibuoColors.inkMuted : null,
            ),
          ),
        ],
      ),
    );
    final parent = _category?.parentId == null
        ? null
        : widget.categories
              .where((c) => c.id == _category!.parentId)
              .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          ),
          child: Row(
            children: [
              side(l.adjustInKibuo, widget.before, muted: true),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  KibuoIcons.arrowRight,
                  size: 18,
                  color: KibuoColors.inkSecondary,
                ),
              ),
              side(l.adjustReal, widget.after),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l.adjustHelp, style: KibuoType.help),
        ),
        const SizedBox(height: 12),
        Material(
          color: KibuoColors.surface,
          borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              EntryField(
                icon: out ? KibuoIcons.arrowDown : KibuoIcons.arrowUp,
                label: out ? l.entryExpense : l.entryIncome,
                value: '${out ? '−' : '+'}${widget.amount}',
              ),
              EntryField(
                leading: _category == null
                    ? null
                    : CategoryTile(category: _category!, size: 32),
                icon: KibuoIcons.tag,
                label: l.entryCategory,
                value: _category == null
                    ? null
                    : parent == null
                    ? categoryName(l, _category!)
                    : '${categoryName(l, parent)} › '
                          '${categoryName(l, _category!)}',
                placeholder: l.entryChoose,
                onTap: _choose,
              ),
              EntryField(
                icon: KibuoIcons.list,
                label: l.entryNote,
                value: l.adjustNote(widget.before, widget.after),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        KibuoButton(
          label: l.adjustAdd,
          onPressed: _category == null
              ? null
              : () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => IconTile(
    icon: icon,
    tint: KibuoColors.background,
    ink: KibuoColors.inkSecondary,
    iconSize: 20,
    radius: 11,
  );
}
