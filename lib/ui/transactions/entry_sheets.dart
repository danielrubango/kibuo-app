import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/categories/category_labels.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

String _lang(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// « 2 850 » while typing « 2850 »: thousands spaced, the comma kept.
String shownTyped(BuildContext context, String typed) {
  final numbers = NumberFormat.decimalPattern(_lang(context));
  final parts = typed.split(',');
  final whole = parts[0].isEmpty
      ? ''
      : numbers.format(int.parse(parts[0])).replaceAll(' ', ' ');
  return parts.length == 2
      ? '$whole${numbers.symbols.DECIMAL_SEP}${parts[1]}'
      : whole;
}

/// A typed amount as [Money] in [currency].
Money typedMoney(String typed, CurrencyInfo currency) {
  final t = typed.isEmpty ? '0' : typed.replaceAll(',', '.');
  return Money.fromMajor(t.endsWith('.') ? '${t}0' : t, currency);
}

/// « 120 » or « 120,5 » from a stored amount, to type on.
String typedFrom(Money money, CurrencyInfo c) {
  final unit = [1, 10, 100, 1000, 10000][c.digits];
  final whole = money.minor.abs() ~/ unit;
  final rest = (money.minor.abs() % unit).toString().padLeft(c.digits, '0');
  final cents = rest.replaceFirst(RegExp(r'0+$'), '');
  return cents.isEmpty || c.digits == 0 ? '$whole' : '$whole,$cents';
}

/// A radio line of a choice card.
class RadioLine extends StatelessWidget {
  const RadioLine({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
    this.help,
    this.enabled = true,
  });

  final String label;
  final String? help;
  final bool on;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = enabled ? KibuoColors.ink : KibuoColors.inkMuted;
    return Semantics(
      selected: on,
      button: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: on ? KibuoColors.accent : KibuoColors.lineStrong,
                    width: 2,
                  ),
                ),
                child: on
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: KibuoColors.accent,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: KibuoType.rowLabel.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation.weight(600)],
                        color: ink,
                      ),
                    ),
                    if (help != null) Text(help!, style: KibuoType.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _choiceCard(List<Widget> lines) => Material(
  color: KibuoColors.surface,
  borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
  clipBehavior: Clip.antiAlias,
  child: Column(
    children: [
      for (final (i, line) in lines.indexed) ...[
        if (i > 0)
          const Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: KibuoColors.background,
          ),
        line,
      ],
    ],
  ),
);

/// « Compte »: the active accounts. Returns the chosen one.
Future<AccountInfo?> pickAccount(
  BuildContext context, {
  required List<AccountInfo> accounts,
  String? current,
  String? question,
}) {
  final l = AppLocalizations.of(context);
  return showKibuoSheet<AccountInfo>(
    context,
    title: l.entryAccount,
    builder: (context) => accounts.isEmpty
        ? Text(l.entryNoAccount, style: KibuoType.body)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // « Vers quel compte ? » for a transfer (canvas TransfertVers).
              if (question != null) ...[
                Text(question, style: KibuoType.help),
                const SizedBox(height: 12),
              ],
              _choiceCard([
                for (final a in accounts)
                  RadioLine(
                    label: a.name,
                    help: a.currency,
                    on: a.id == current,
                    onTap: () => Navigator.of(context).pop(a),
                  ),
              ]),
            ],
          ),
  );
}

/// « Devise payée » (canvas ParcoursDevise): the account's currency first,
/// then the user's others. Returns the chosen code.
Future<String?> pickPaidCurrency(
  BuildContext context, {
  required bool income,
  required String accountName,
  required CurrencyInfo account,
  required List<String> others,
  required String current,
}) {
  final l = AppLocalizations.of(context);
  return showKibuoSheet<String>(
    context,
    title: income ? l.entryReceivedCurrency : l.entryPaidCurrency,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.entryCurrencyHelp(accountName, currencyName(context, account)),
          style: KibuoType.help,
        ),
        const SizedBox(height: 12),
        _choiceCard([
          for (final code in [account.code, ...others])
            RadioLine(
              label: currencyName(context, currencyOf(code)),
              help: code == account.code
                  ? l.entryAccountCurrency
                  : l.entryConverted,
              on: code == current,
              onTap: () => Navigator.of(context).pop(code),
            ),
        ]),
      ],
    ),
  );
}

/// What the rate sheet decided: today's rate, or one typed for this
/// operation.
class RateChoice {
  const RateChoice({required this.typed, this.value});

  final bool typed;
  final String? value;
}

/// « Taux de conversion » (canvas ParcoursTaux): « Taux du jour » or
/// « Autre taux » typed on the keypad.
Future<RateChoice?> pickEntryRate(
  BuildContext context, {
  required bool income,
  required String paid,
  required String base,
  required String quote,
  required ExchangeRate? today,
  required RateChoice current,
  String? paidLabel,
}) {
  final l = AppLocalizations.of(context);
  return showKibuoSheet<RateChoice>(
    context,
    title: l.entryRateTitle,
    builder: (_) => _RateSheet(
      income: income,
      paidLabel: paidLabel,
      paid: paid,
      base: base,
      quote: quote,
      today: today,
      current: current,
      l: l,
    ),
  );
}

class _RateSheet extends StatefulWidget {
  const _RateSheet({
    required this.income,
    required this.paid,
    required this.base,
    required this.quote,
    required this.today,
    required this.current,
    required this.l,
    this.paidLabel,
  });

  final bool income;

  /// « Envoyé » for a transfer, instead of « Payé » or « Reçu ».
  final String? paidLabel;
  final String paid;
  final String base;
  final String quote;
  final ExchangeRate? today;
  final RateChoice current;
  final AppLocalizations l;

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  late bool _typed = widget.current.typed || widget.today == null;
  late String _value = widget.current.typed ? widget.current.value ?? '' : '';

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final today = widget.today;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.paidLabel ??
                    (widget.income ? l.entryReceived : l.entryPaid),
                style: KibuoType.caption,
              ),
              Text(widget.paid, style: KibuoType.cardTitle),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _choiceCard([
          RadioLine(
            label: l.entryRateToday,
            help: today == null
                ? l.entryRateTodayMissing
                : '${l.entryRateTodayHelp} · '
                      '${formatRate(today, _lang(context))}',
            on: !_typed,
            enabled: today != null,
            onTap: () => setState(() => _typed = false),
          ),
          RadioLine(
            label: l.entryRateOther,
            help: l.entryRateOtherHelp,
            on: _typed,
            onTap: () => setState(() => _typed = true),
          ),
        ]),
        if (_typed) ...[
          const SizedBox(height: 12),
          ValueField(
            prefix: '1 ${currencyOf(widget.base).symbol} =',
            value: shownTyped(context, _value),
            placeholder: '',
            unit: currencyOf(widget.quote).symbol,
          ),
          const SizedBox(height: 12),
          KibuoKeypad(
            onKey: (k) =>
                setState(() => _value = typeKey(_value, k, decimals: 6)),
            onDelete: () => setState(() {
              if (_value.isNotEmpty) {
                _value = _value.substring(0, _value.length - 1);
              }
            }),
            decimalSeparator: NumberFormat.decimalPattern(_lang(context))
                .symbols
                .DECIMAL_SEP,
          ),
        ],
        const SizedBox(height: 12),
        KibuoButton(
          label: l.keypadDone,
          kind: ButtonKind.dark,
          onPressed: _typed && RateValue.tryParse(_value) == null
              ? null
              : () =>
                    Navigator.of(context)
                        .pop(RateChoice(typed: _typed, value: _value)),
        ),
      ],
    );
  }
}

/// « Frais supplémentaires » (canvas FraisFeuille), in the account's
/// currency. Returns the typed fees.
Future<String?> pickFees(
  BuildContext context, {
  required CurrencyInfo account,
  required String current,
}) {
  final l = AppLocalizations.of(context);
  return showKibuoSheet<String>(
    context,
    title: l.entryFeesTitle,
    builder: (_) => _FeesSheet(account: account, current: current, l: l),
  );
}

class _FeesSheet extends StatefulWidget {
  const _FeesSheet({
    required this.account,
    required this.current,
    required this.l,
  });

  final CurrencyInfo account;
  final String current;
  final AppLocalizations l;

  @override
  State<_FeesSheet> createState() => _FeesSheetState();
}

class _FeesSheetState extends State<_FeesSheet> {
  late String _value = widget.current;

  @override
  Widget build(BuildContext context) {
    final c = widget.account;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueField(value: shownTyped(context, _value), unit: c.symbol),
        const SizedBox(height: 12),
        KibuoKeypad(
          onKey: (k) => setState(
            () => _value = typeKey(
              _value,
              k,
              decimals: c.usesDecimals ? c.digits : 0,
            ),
          ),
          onDelete: () => setState(() {
            if (_value.isNotEmpty) {
              _value = _value.substring(0, _value.length - 1);
            }
          }),
          allowDecimal: c.usesDecimals,
          decimalSeparator: NumberFormat.decimalPattern(_lang(context))
              .symbols
              .DECIMAL_SEP,
        ),
        const SizedBox(height: 12),
        KibuoButton(
          label: widget.l.keypadDone,
          kind: ButtonKind.dark,
          onPressed: () => Navigator.of(context).pop(_value),
        ),
      ],
    );
  }
}

/// « Catégorie » (canvas SaisieCategorie): each category with a radio, its
/// subcategories as chips under it, and a search. Returns the chosen one.
///
/// For a budget, [withSubs] is false (only top-level categories) and
/// [unavailable] greys those that already have one, with [unavailableNote].
Future<CategoryInfo?> pickCategory(
  BuildContext context, {
  required List<CategoryInfo> categories,
  String? current,
  bool withSubs = true,
  Set<String> unavailable = const {},
  String? unavailableNote,
}) {
  final l = AppLocalizations.of(context);
  return showKibuoSheet<CategoryInfo>(
    context,
    title: l.entryCategory,
    builder: (_) => _CategorySheet(
      categories: categories,
      current: current,
      l: l,
      withSubs: withSubs,
      unavailable: unavailable,
      unavailableNote: unavailableNote,
    ),
  );
}

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({
    required this.categories,
    required this.current,
    required this.l,
    required this.withSubs,
    required this.unavailable,
    required this.unavailableNote,
  });

  final List<CategoryInfo> categories;
  final String? current;
  final AppLocalizations l;
  final bool withSubs;
  final Set<String> unavailable;
  final String? unavailableNote;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  String _query = '';

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final q = _fold(_query.trim());
    bool hit(CategoryInfo c) => _fold(categoryName(l, c)).contains(q);
    final shown = [
      for (final c in widget.categories)
        if (q.isEmpty || hit(c) || c.subs.any(hit)) c,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KibuoTextField(
          hint: l.categorySearch,
          textCapitalization: TextCapitalization.none,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        Material(
          color: KibuoColors.surface,
          borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final c in shown) ...[
                InkWell(
                  onTap: widget.unavailable.contains(c.id)
                      ? null
                      : () => Navigator.of(context).pop(c),
                  child: Opacity(
                    opacity: widget.unavailable.contains(c.id) ? 0.45 : 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          _Radio(on: c.id == widget.current),
                          const SizedBox(width: 12),
                          CategoryTile(category: c),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              categoryName(l, c),
                              style: KibuoType.rowLabel.copyWith(
                                fontWeight: FontWeight.w600,
                                fontVariations: const [
                                  FontVariation.weight(600),
                                ],
                              ),
                            ),
                          ),
                          if (widget.unavailable.contains(c.id) &&
                              widget.unavailableNote != null)
                            Text(
                              widget.unavailableNote!,
                              style: KibuoType.caption,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.withSubs && c.subs.isNotEmpty)
                  Padding(
                    // Under the category's name: 16 + circle 22 + 12 +
                    // tile 28 + 8.
                    padding: const EdgeInsets.fromLTRB(86, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in c.subs)
                          if (q.isEmpty || hit(c) || hit(s))
                            _SubChip(
                              label: categoryName(l, s),
                              on: s.id == widget.current,
                              onTap: () => Navigator.of(context).pop(s),
                            ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: on ? KibuoColors.accent : KibuoColors.lineStrong,
          width: 2,
        ),
      ),
      child: on
          ? const Icon(KibuoIcons.check, size: 14, color: KibuoColors.accent)
          : null,
    );
  }
}

class _SubChip extends StatelessWidget {
  const _SubChip({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: on ? KibuoColors.ink : KibuoColors.background,
      borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusPill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: KibuoType.body.copyWith(
              fontWeight: FontWeight.w500,
              fontVariations: const [FontVariation.weight(500)],
              color: on ? KibuoColors.surface : KibuoColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
