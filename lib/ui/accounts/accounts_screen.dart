import 'package:flutter/material.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/accounts/account_total.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_form_screen.dart';
import 'package:kibuo/ui/accounts/account_types.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/group_title.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Plus › Comptes (canvas: Comptes): chips by type, the total of the
/// accounts, then one card per account, grouped by type under « Tous ».
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({
    super.key,
    required this.accounts,
    required this.currencies,
    this.categories,
    this.transactions,
  });

  final AccountRepository accounts;
  final CurrencyRepository currencies;

  /// For « Solde actuel » in an account's form.
  final CategoryRepository? categories;
  final TransactionRepository? transactions;

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<AccountInfo> _list = const [];
  List<CustomAccountType> _custom = const [];
  CurrencyInfo? _main;
  final _infos = <String, CurrencyInfo>{};
  final _rates = <String, ExchangeRate>{};
  bool _allInMain = false;
  AccountType? _chip;
  final _folded = <AccountType>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.accounts.accounts();
    final custom = await widget.accounts.types();
    final mainCode = await widget.currencies.primaryCurrency() ?? 'USD';
    final main = await widget.currencies.currency(mainCode);
    final allInMain = await widget.accounts.allInMain();
    final infos = <String, CurrencyInfo>{mainCode: main};
    final rates = <String, ExchangeRate>{};
    for (final code in {for (final a in list) a.currency}) {
      infos[code] = await widget.currencies.currency(code);
      if (code == mainCode) continue;
      final rate = await widget.currencies.latestRate(mainCode, code);
      if (rate != null) rates[code] = rate.rate;
    }
    if (!mounted) return;
    setState(() {
      _list = list;
      _custom = custom;
      _main = main;
      _allInMain = allInMain;
      _infos
        ..clear()
        ..addAll(infos);
      _rates
        ..clear()
        ..addAll(rates);
      if (_chip != null && !list.any((a) => a.type == _chip)) _chip = null;
    });
  }

  String get _lang => Localizations.localeOf(context).languageCode;

  String _money(Money m, {bool short = false}) =>
      formatAmount(m, _infos[m.currency]!, _lang, short: short);

  AccountTotal _total(Iterable<AccountInfo> accounts) => totalIn(_main!, [
    for (final a in accounts) a.balance,
  ], (code) => _rates[code]);

  /// [m] in the main currency, or null without a rate.
  Money? _inMain(Money m) {
    if (m.currency == _main!.code) return m;
    final rate = _rates[m.currency];
    return rate?.convert(m, to: _main!);
  }

  Future<void> _open([AccountInfo? account]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AccountFormScreen(
          accounts: widget.accounts,
          currencies: widget.currencies,
          account: account,
          categories: widget.categories,
          transactions: widget.transactions,
        ),
      ),
    );
    if (changed ?? false) await _load();
  }

  /// Accounts in more than one currency, or another than the main one.
  bool get _several =>
      {for (final a in _list) a.currency}.length > 1 ||
      _list.any((a) => a.currency != _main?.code);

  Future<void> _openDisplay() async {
    final l = AppLocalizations.of(context);
    final main = _main!;
    final choice = await showKibuoSheet<bool>(
      context,
      title: l.accountsDisplay,
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(l.accountsDisplayAmounts),
          SettingsCard(
            children: [
              DisplayChoice(
                icon: KibuoIcons.wallet,
                label: l.accountsDisplayEach,
                help: l.accountsDisplayEachHelp,
                on: !_allInMain,
                onTap: () => Navigator.of(context).pop(false),
              ),
              DisplayChoice(
                icon: KibuoIcons.arrowsLeftRight,
                label: l.accountsDisplayAll(
                  currencyName(context, main).toLowerCase(),
                  main.code,
                ),
                help: l.accountsDisplayAllHelp,
                on: _allInMain,
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HelpText(l.accountsDisplayNote),
        ],
      ),
    );
    if (choice == null || choice == _allInMain) return;
    await widget.accounts.setAllInMain(choice);
    await _load();
  }

  Future<void> _openCurrencies() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CurrenciesScreen(repository: widget.currencies),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final main = _main;
    final labels = AccountTypeLabels(l, _custom);
    final shown = _chip == null
        ? _list
        : _list.where((a) => a.type == _chip).toList();
    final types = [
      for (final t in labels.all)
        if (_list.any((a) => a.type == t)) t,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.accountsTitle),
        actions: [
          if (_several && main != null)
            IconButton(
              tooltip: l.accountsDisplay,
              color: KibuoColors.accent,
              onPressed: _openDisplay,
              icon: const Icon(KibuoIcons.slidersHorizontal),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: main == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                if (types.length > 1) ...[
                  _Chips(
                    all: l.accountsAll,
                    count: _list.length,
                    types: [
                      for (final t in types)
                        (
                          t,
                          labels.name(t),
                          _list.where((a) => a.type == t).length,
                        ),
                    ],
                    chosen: _chip,
                    onPick: (t) => setState(() => _chip = t),
                  ),
                  const SizedBox(height: 16),
                ],
                _TotalCard(
                  label: _chip == null
                      ? l.accountsTotal
                      : l.accountsTotalOf(_lowerFirst(labels.name(_chip!))),
                  long: isLong(_total(shown).amount),
                  amount: (short) => _money(_total(shown).amount, short: short),
                ),
                if (_total(shown).withoutRate.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  HelpText(
                    l.accountsNoRateNote(_total(shown).withoutRate.join(', ')),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextAction(
                      label: l.accountsAddRate,
                      onPressed: _openCurrencies,
                    ),
                  ),
                ],
                // Each group brings its own gap (DIRECTION: Groupes).
                if (_chip == null)
                  for (final t in types) ..._group(l, labels, t)
                else ...[
                  const SizedBox(height: 16),
                  for (final (i, a) in shown.indexed) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _card(l, a),
                  ],
                ],
                const SizedBox(height: 16),
                KibuoButton(
                  label: l.accountsAdd,
                  kind: ButtonKind.create,
                  icon: KibuoIcons.plusBold,
                  onPressed: () => _open(),
                ),
              ],
            ),
    );
  }

  static String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  List<Widget> _group(
    AppLocalizations l,
    AccountTypeLabels labels,
    AccountType type,
  ) {
    final accounts = _list.where((a) => a.type == type).toList();
    final folded = _folded.contains(type);
    final total = _total(accounts).amount;
    return [
      const SizedBox(height: GroupTitle.before),
      GroupTitle(
        title: labels.name(type),
        count: folded ? l.accountsCount(accounts.length) : null,
        leading: Icon(
          labels.icon(type),
          size: 18,
          color: KibuoColors.inkSecondary,
        ),
        trailing: FitAmount(
          long: isLong(total),
          alignment: Alignment.centerRight,
          maxWidth: MediaQuery.sizeOf(context).width * 0.45,
          style: KibuoType.sectionTitle.copyWith(
            color: total.minor < 0 ? KibuoColors.danger : KibuoColors.ink,
          ),
          span: (short) => TextSpan(text: _money(total, short: short)),
        ),
        folded: folded,
        onTap: () =>
            setState(() => folded ? _folded.remove(type) : _folded.add(type)),
      ),
      if (!folded)
        for (final (i, a) in accounts.indexed) ...[
          if (i > 0) const SizedBox(height: 8),
          _card(l, a),
        ],
    ];
  }

  Widget _card(AppLocalizations l, AccountInfo a) {
    final inMain = _inMain(a.balance);
    final String Function(bool short) amount;
    var long = false;
    String? detail;
    var muted = false;
    if (_allInMain && a.currency != _main!.code) {
      if (inMain == null) {
        amount = (_) => l.accountsNoRate;
        muted = true;
      } else {
        amount = (short) => _money(inMain, short: short);
        long = isLong(inMain);
      }
      detail = _money(a.balance);
    } else {
      amount = (short) => _money(a.balance, short: short);
      long = isLong(a.balance);
      if (a.currency != _main!.code && inMain != null) {
        detail = '≈ ${_money(inMain)}';
      }
    }
    // « Découvert jusqu'à 100 $ » or « Découvert sans limite » (PRODUCT).
    final o = a.overdraft;
    final overdraft = !o.allowed
        ? null
        : o.unlimited
        ? l.overdraftCaptionNoLimit
        : l.overdraftCaptionUpTo(_money(Money(o.limit!, a.currency)));
    return _AccountCard(
      name: a.name,
      code: a.currency,
      detail: [?detail, ?overdraft].join(' · ').ifEmpty,
      amount: amount,
      long: long,
      muted: muted,
      negative: a.balance.minor < 0,
      onTap: () => _open(a),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.all,
    required this.count,
    required this.types,
    required this.chosen,
    required this.onPick,
  });

  final String all;
  final int count;
  final List<(AccountType, String, int)> types;
  final AccountType? chosen;
  final ValueChanged<AccountType?> onPick;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int n, bool on, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: on ? KibuoColors.ink : KibuoColors.surface,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: KibuoTheme.heightTouch,
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: KibuoType.body.copyWith(
                    fontWeight: FontWeight.w500,
                    fontVariations: const [FontVariation.weight(500)],
                    color: on ? KibuoColors.surface : KibuoColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 24),
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? KibuoColors.mint : KibuoColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$n',
                    style: KibuoType.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      fontVariations: const [FontVariation.weight(600)],
                      color: on ? KibuoColors.ink : KibuoColors.inkSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          chip(all, count, chosen == null, () => onPick(null)),
          for (final (type, label, n) in types)
            chip(label, n, chosen == type, () => onPick(type)),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.long,
  });

  final String label;
  final String Function(bool short) amount;
  final bool long;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusFeatured),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: KibuoType.body.copyWith(color: KibuoColors.inkSecondary),
          ),
          const SizedBox(height: 4),
          FitAmount(
            long: long,
            style: KibuoType.highlight.copyWith(fontSize: 30),
            span: (short) => TextSpan(text: amount(short)),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.code,
    required this.amount,
    required this.long,
    required this.onTap,
    this.detail,
    this.muted = false,
    this.negative = false,
  });

  final String name;
  final String code;
  final String? detail;
  final String Function(bool short) amount;
  final bool long;
  final bool muted;

  /// Below zero: the amount in red.
  final bool negative;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KibuoCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KibuoType.rowLabel.copyWith(
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation.weight(600)],
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: code,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontVariations: [FontVariation.weight(600)],
                          letterSpacing: 0.4,
                        ),
                      ),
                      if (detail != null) TextSpan(text: ' · $detail'),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KibuoType.help,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FitAmount(
            long: long,
            alignment: Alignment.centerRight,
            maxWidth: MediaQuery.sizeOf(context).width * 0.45,
            style: muted
                ? KibuoType.buttonSmall.copyWith(color: KibuoColors.inkMuted)
                : KibuoType.cardTitle.copyWith(
                    color: negative ? KibuoColors.danger : null,
                  ),
            span: (short) => TextSpan(text: amount(short)),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String? get ifEmpty => isEmpty ? null : this;
}
