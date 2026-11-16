import 'package:flutter/material.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/domain/accounts/account_total.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_form_screen.dart';
import 'package:kibuo/ui/accounts/account_types.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/sheet.dart';
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
  });

  final AccountRepository accounts;
  final CurrencyRepository currencies;

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

  String _money(Money m) => formatMoney(m, _infos[m.currency]!, _lang);

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
        ),
      ),
    );
    if (changed ?? false) await _load();
  }

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
              _DisplayChoice(
                label: l.accountsDisplayEach,
                help: l.accountsDisplayEachHelp,
                on: !_allInMain,
                onTap: () => Navigator.of(context).pop(false),
              ),
              _DisplayChoice(
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
    final several =
        {for (final a in _list) a.currency}.length > 1 ||
        _list.any((a) => a.currency != main?.code);
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
          if (several && main != null)
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
                  amount: _money(_total(shown).amount),
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
                const SizedBox(height: 16),
                if (_chip == null)
                  for (final t in types) ..._group(l, labels, t)
                else
                  for (final a in shown) ...[
                    _card(l, a),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 4),
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
    return [
      _GroupHeader(
        icon: labels.icon(type),
        name: labels.name(type),
        count: folded ? l.accountsCount(accounts.length) : null,
        total: _money(_total(accounts).amount),
        folded: folded,
        onTap: () =>
            setState(() => folded ? _folded.remove(type) : _folded.add(type)),
      ),
      if (!folded)
        for (final a in accounts) ...[_card(l, a), const SizedBox(height: 8)],
      const SizedBox(height: 8),
    ];
  }

  Widget _card(AppLocalizations l, AccountInfo a) {
    final inMain = _inMain(a.balance);
    final String amount;
    String? detail;
    var muted = false;
    if (_allInMain && a.currency != _main!.code) {
      if (inMain == null) {
        amount = l.accountsNoRate;
        muted = true;
      } else {
        amount = _money(inMain);
      }
      detail = _money(a.balance);
    } else {
      amount = _money(a.balance);
      if (a.currency != _main!.code && inMain != null) {
        detail = '≈ ${_money(inMain)}';
      }
    }
    return _AccountCard(
      name: a.name,
      code: a.currency,
      detail: detail,
      amount: amount,
      muted: muted,
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
  const _TotalCard({required this.label, required this.amount});

  final String label;
  final String amount;

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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: KibuoType.highlight.copyWith(fontSize: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.icon,
    required this.name,
    required this.total,
    required this.folded,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String name;
  final String? count;
  final String total;
  final bool folded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      expanded: !folded,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: KibuoTheme.heightTouch,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(icon, size: 18, color: KibuoColors.inkSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: name,
                      children: [
                        if (count != null)
                          TextSpan(
                            text: ' · $count',
                            style: KibuoType.sectionTitle.copyWith(
                              fontWeight: FontWeight.w500,
                              fontVariations: const [FontVariation.weight(500)],
                              color: KibuoColors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                    style: KibuoType.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  total,
                  style: KibuoType.sectionTitle.copyWith(
                    color: KibuoColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  folded ? KibuoIcons.caretDown : KibuoIcons.caretUp,
                  size: 16,
                  color: KibuoColors.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.name,
    required this.code,
    required this.amount,
    required this.onTap,
    this.detail,
    this.muted = false,
  });

  final String name;
  final String code;
  final String? detail;
  final String amount;
  final bool muted;
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
          Text(
            amount,
            style: muted
                ? KibuoType.buttonSmall.copyWith(color: KibuoColors.inkMuted)
                : KibuoType.cardTitle,
          ),
        ],
      ),
    );
  }
}

class _DisplayChoice extends StatelessWidget {
  const _DisplayChoice({
    required this.label,
    required this.help,
    required this.on,
    required this.onTap,
  });

  final String label;
  final String help;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: on,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: KibuoType.rowLabel),
                    Text(help, style: KibuoType.caption),
                  ],
                ),
              ),
              if (on) const Icon(KibuoIcons.check, color: KibuoColors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
