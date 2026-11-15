import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/device_country.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

String _lang(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String currencyName(BuildContext context, CurrencyInfo c) =>
    _lang(context) == 'fr' ? c.nameFr : c.nameEn;

String _day(BuildContext context, DateTime date) =>
    DateFormat.MMMMd(_lang(context)).format(date.toLocal());

/// One of the user's currencies, with its rate against the main currency.
class _Row {
  const _Row(this.currency, this.rate);

  final CurrencyInfo currency;
  final RateInfo? rate;
}

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key, required this.repository});

  final CurrencyRepository repository;

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  CurrencyInfo? _main;
  String? _country;
  List<_Row> _rows = const [];

  CurrencyRepository get _repo => widget.repository;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final country = _country ??= await deviceCountry();
    await _repo.ensurePrimaryCurrency(country);
    final mainCode = (await _repo.primaryCurrency())!;
    final main = await _repo.currency(mainCode);
    final rows = <_Row>[];
    for (final code in await _repo.currencyCodes()) {
      if (code == mainCode) continue;
      rows.add(
        _Row(
          await _repo.currency(code),
          await _repo.latestRate(mainCode, code),
        ),
      );
    }
    if (mounted) {
      setState(() {
        _main = main;
        _rows = rows;
      });
    }
  }

  Future<void> _changeMain() async {
    final mine = await _repo.currencyCodes();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final code = await pickCurrency(
      context,
      title: l.mainCurrencyPickerTitle,
      help: l.mainCurrencyHelp,
      current: _main?.code,
      country: _country,
      yoursFirst: mine,
    );
    if (code == null) return;
    await _repo.setPrimaryCurrency(code);
    await _load();
  }

  Future<void> _add() async {
    final mine = await _repo.currencyCodes();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final code = await pickCurrency(
      context,
      title: l.currencyPickerTitle,
      country: _country,
      greyed: mine.toSet(),
    );
    if (code == null || code == _main?.code) return;
    await _repo.addCurrency(code);
    await _load();
    final row = _rows.where((r) => r.currency.code == code).firstOrNull;
    if (row != null && mounted) await _editRate(row);
  }

  Future<void> _editRate(_Row row) async {
    await showRateSheet(
      context,
      repository: _repo,
      main: _main!,
      other: row.currency,
      current: row.rate,
    );
    await _load();
  }

  /// « Centimes »: a switch per currency that has cents, the main one first.
  List<Widget> _cents(BuildContext context, CurrencyInfo main) {
    final l = AppLocalizations.of(context);
    final currencies = [
      main,
      for (final r in _rows) r.currency,
    ].where((c) => c.digits > 0).toList();
    if (currencies.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      SectionTitle(l.currenciesCents),
      SettingsCard(
        children: [
          for (final c in currencies)
            SettingsSwitch(
              label: currencyName(context, c),
              value: c.usesDecimals,
              onChanged: (on) async {
                await _repo.setUsesDecimals(c.code, on: on);
                await _load();
              },
            ),
        ],
      ),
      const SizedBox(height: 12),
      HelpText(l.currencyDecimalsHelp),
    ];
  }

  /// A typed rate the way it was typed; a worked-out one the way a new
  /// rate would be typed.
  ExchangeRate _shownRate(_Row row, CurrencyInfo main) {
    final info = row.rate!;
    if (!info.isWorkedOut) return info.rate;
    final (base, quote) = rateDirection(main: main, other: row.currency);
    return info.rate.toward(base, quote);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final main = _main;
    return Scaffold(
      appBar: AppBar(title: Text(l.currenciesTitle)),
      body: main == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                FeaturedCard(
                  label: l.currenciesMain,
                  value: main.code,
                  action: l.currenciesChange,
                  onTap: _changeMain,
                ),
                if (_rows.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SectionTitle(l.currenciesRates),
                  for (final row in _rows) ...[
                    ItemCard(
                      title:
                          '${currencyName(context, row.currency)}, '
                          '${row.currency.code}',
                      lines: [
                        if (row.rate == null)
                          l.currenciesNoRate
                        else ...[
                          formatRate(_shownRate(row, main), _lang(context)),
                          if (row.rate!.isWorkedOut)
                            l.currenciesWorkedOut
                          else
                            l.currenciesUpdatedOn(
                              _day(context, row.rate!.setOn),
                            ),
                        ],
                      ],
                      action: l.currenciesEdit,
                      onTap: () => _editRate(row),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 4),
                  HelpText(l.currenciesRatesHelp),
                ],
                ..._cents(context, main),
              ],
            ),
      bottomNavigationBar: main == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: KibuoButton(label: l.currenciesAdd, onPressed: _add),
            ),
    );
  }
}

/// The currency list: the user's own currencies first ([yoursFirst]) or
/// greyed out ([greyed]), then up to 6 by importance for the country, then
/// all the others by name, with a search field. Returns the chosen code.
Future<String?> pickCurrency(
  BuildContext context, {
  required String title,
  String? help,
  String? current,
  String? country,
  List<String> yoursFirst = const [],
  Set<String> greyed = const {},
}) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    builder: (_) => CurrencyPickerScreen(
      title: title,
      help: help,
      current: current,
      country: country,
      yoursFirst: yoursFirst,
      greyed: greyed,
    ),
  ),
);

class CurrencyPickerScreen extends StatefulWidget {
  const CurrencyPickerScreen({
    super.key,
    required this.title,
    this.help,
    this.current,
    this.country,
    this.yoursFirst = const [],
    this.greyed = const {},
  });

  final String title;
  final String? help;
  final String? current;

  /// The phone's country, whose currency comes first.
  final String? country;

  /// The user's currencies, shown first under « Vos devises ».
  final List<String> yoursFirst;

  /// Currencies shown but not choosable (already added).
  final Set<String> greyed;

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  String _query = '';

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  bool _matches(CurrencyInfo c) {
    if (_query.isEmpty) return true;
    final q = _fold(_query);
    return _fold(c.code).contains(q) ||
        _fold(c.nameFr).contains(q) ||
        _fold(c.nameEn).contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lists = currenciesForChoosing(countryCode: widget.country);
    final yours = widget.yoursFirst.toSet();
    List<CurrencyInfo> keep(List<CurrencyInfo> l) =>
        l.where((c) => !yours.contains(c.code) && _matches(c)).toList();
    final rest = keep(lists.rest)
      ..sort(
        (a, b) =>
            _fold(currencyName(context, a))
                .compareTo(_fold(currencyName(context, b))),
      );
    final groups = [
      (
        l.currencyYours,
        [
          for (final code in widget.yoursFirst)
            if (_matches(currencyOf(code))) currencyOf(code),
        ],
      ),
      (l.currencyCommon, keep(lists.top)),
      (l.currencyOthers, rest),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (widget.help != null) ...[
            HelpText(widget.help!),
            const SizedBox(height: 16),
          ],
          KibuoTextField(
            label: l.currencySearch,
            hint: l.currencySearchHint,
            textCapitalization: TextCapitalization.none,
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          for (final (title, currencies) in groups)
            if (currencies.isNotEmpty) ...[
              const SizedBox(height: 20),
              SectionTitle(title),
              for (final c in currencies) ...[
                _CurrencyTile(
                  name: currencyName(context, c),
                  code: c.code,
                  chosen: c.code == widget.current,
                  onTap: widget.greyed.contains(c.code)
                      ? null
                      : () => Navigator.of(context).pop(c.code),
                ),
                const SizedBox(height: 8),
              ],
            ],
        ],
      ),
    );
  }
}

/// A currency to choose: its name, its code on the right; the current one
/// bordered in green.
class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.name,
    required this.code,
    required this.chosen,
    required this.onTap,
  });

  final String name;
  final String code;
  final bool chosen;

  /// Null for a currency already added: greyed out.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final greyed = onTap == null;
    final ink = greyed ? KibuoColors.inkMuted : KibuoColors.ink;
    return Material(
      color: greyed ? KibuoColors.fill : KibuoColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KibuoTheme.radiusTile),
        side: chosen
            ? const BorderSide(color: KibuoColors.accent, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: KibuoType.rowLabel.copyWith(color: ink),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                code,
                style: KibuoType.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontVariations: const [FontVariation.weight(700)],
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// « du franc congolais », « de l’euro », « de la livre sterling »: the
/// currency's French name after « Taux ».
String frenchOfName(String name) {
  final lower = name.substring(0, 1).toLowerCase() + name.substring(1);
  const feminine = {
    'livre', 'roupie', 'couronne', 'lire', 'hryvnia', 'gourde', 'peseta', //
    'nouvelle', 'roupiah',
  };
  if (RegExp('^[aeiouyhéèêâîôû]').hasMatch(lower)) return 'de l’$lower';
  if (feminine.contains(lower.split(' ').first)) return 'de la $lower';
  return 'du $lower';
}

/// The rate sheet (validated mock-up « Taux depuis Réglages »): « 1 $ = … »
/// typed on the Kibuo keypad with its currency on the right, the previous
/// rate and the change, then « Enregistrer le taux » and « Annuler ».
Future<void> showRateSheet(
  BuildContext context, {
  required CurrencyRepository repository,
  required CurrencyInfo main,
  required CurrencyInfo other,
  RateInfo? current,
}) {
  final name = currencyName(context, other);
  final l = AppLocalizations.of(context);
  return showKibuoSheet<void>(
    context,
    title: l.rateSheetTitle(_lang(context) == 'fr' ? frenchOfName(name) : name),
    builder: (_) => _RateSheet(
      repository: repository,
      main: main,
      other: other,
      current: current,
    ),
  );
}

class _RateSheet extends StatefulWidget {
  const _RateSheet({
    required this.repository,
    required this.main,
    required this.other,
    this.current,
  });

  final CurrencyRepository repository;
  final CurrencyInfo main;
  final CurrencyInfo other;
  final RateInfo? current;

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  late String _base;
  late String _quote;
  String _typed = '';

  @override
  void initState() {
    super.initState();
    // The way the last rate was typed, else the way a new one is.
    final current = widget.current;
    if (current != null && !current.isWorkedOut) {
      _setDirection(current.rate.base, current.rate.quote);
    } else {
      final (base, quote) = rateDirection(
        main: widget.main,
        other: widget.other,
      );
      _setDirection(base, quote);
    }
  }

  void _setDirection(String base, String quote) {
    _base = base;
    _quote = quote;
  }

  RateValue? get _value {
    try {
      return RateValue.parse(_typed);
    } on FormatException {
      return null;
    }
  }

  void _key(String k) => setState(() {
    if (k == ',') {
      if (!_typed.contains(',')) _typed = _typed.isEmpty ? '0,' : '$_typed,';
    } else if (_typed.replaceAll(',', '').length < 12) {
      _typed = _typed == '0' ? k : '$_typed$k';
    }
  });

  void _delete() => setState(() {
    if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
  });

  Future<void> _save() async {
    final value = _value;
    if (value == null) return;
    await widget.repository.setRate(_base, _quote, value);
    if (mounted) Navigator.of(context).pop();
  }

  NumberFormat get _numbers => NumberFormat.decimalPattern(_lang(context));

  /// « 2 850 » while typing « 2850 »: thousands spaced, the comma kept.
  String _shown(String typed) {
    final parts = typed.split(',');
    // A full no-break space: the narrow one almost disappears at this size.
    final whole = parts[0].isEmpty
        ? ''
        : _numbers.format(int.parse(parts[0])).replaceAll('\u202F', '\u00A0');
    return parts.length == 2
        ? '$whole${_numbers.symbols.DECIMAL_SEP}${parts[1]}'
        : whole;
  }

  /// The previous rate in this sheet's direction, as a number.
  double? get _before {
    final current = widget.current;
    if (current == null || current.isWorkedOut) return null;
    return double.parse(current.rate.per(_base, _quote).toString());
  }

  /// « +50 FC » against the previous rate; « Inchangé » when equal.
  String? _change(AppLocalizations l) {
    final value = _value;
    final before = _before;
    if (value == null || before == null) return null;
    final delta = double.parse(value.toString()) - before;
    if (delta.abs() < 1e-9) return l.rateUnchanged;
    final quote = currencyOf(_quote);
    final digits = delta.abs() >= 100 ? 0 : 4;
    final amount = NumberFormat.decimalPatternDigits(
      locale: _lang(context),
      decimalDigits: digits,
    ).format(delta.abs()).replaceFirst(RegExp(r'[,.]?0+$'), '');
    return '${delta > 0 ? '+' : '−'}$amount ${quote.symbol}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final base = currencyOf(_base);
    final quote = currencyOf(_quote);
    final current = widget.current;
    final change = _change(l);
    final before = _before;
    final up = _value != null && before != null
        ? double.parse(_value.toString()) > before
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueField(
          prefix: '1 ${base.symbol} =',
          value: _shown(_typed),
          placeholder: '',
          unit: quote.symbol,
        ),
        if (current != null && !current.isWorkedOut) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.rateBefore(
                      '${_numbers.format(before)} ${quote.symbol}',
                      _day(context, current.setOn),
                    ),
                    style: KibuoType.help,
                  ),
                ),
                if (change != null)
                  Text(
                    change,
                    style: KibuoType.sectionTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation.weight(700)],
                      color: up == null
                          ? KibuoColors.inkSecondary
                          : up
                          ? KibuoColors.debtInk
                          : KibuoColors.accent,
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        KibuoKeypad(
          onKey: _key,
          onDelete: _delete,
          decimalSeparator: _numbers.symbols.DECIMAL_SEP,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l.rateKeepsOld, style: KibuoType.caption),
        ),
        const SizedBox(height: 12),
        KibuoButton(
          label: l.rateSave,
          onPressed: _value == null ? null : _save,
        ),
        const SizedBox(height: 8),
        KibuoButton(
          label: l.cancel,
          kind: ButtonKind.secondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
