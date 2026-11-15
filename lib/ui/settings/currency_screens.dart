import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/device_country.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/settings/security_screens.dart';
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

/// Réglages › Devises: the main currency, and each other currency with its
/// rate against it (validated mock-up « Devises »).
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
    final l = AppLocalizations.of(context);
    final code = await pickCurrency(
      context,
      title: l.mainCurrencyPickerTitle,
      help: l.mainCurrencyHelp,
      current: _main?.code,
      country: _country,
    );
    if (code == null) return;
    await _repo.setPrimaryCurrency(code);
    await _load();
  }

  Future<void> _add() async {
    final l = AppLocalizations.of(context);
    final code = await pickCurrency(
      context,
      title: l.currencyPickerTitle,
      country: _country,
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final main = _main;
    return Scaffold(
      appBar: AppBar(title: Text(l.currenciesTitle)),
      body: main == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(l.currenciesMain),
                SettingsCard(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${currencyName(context, main)} · ${main.code}',
                              style: text.bodyLarge,
                            ),
                          ),
                          TextButton(
                            onPressed: _changeMain,
                            child: Text(l.currenciesChange),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_rows.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _Section(l.currenciesRates),
                  SettingsCard(
                    children: [
                      for (final row in _rows)
                        InkWell(
                          onTap: () => _editRate(row),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${currencyName(context, row.currency)}, ${row.currency.code}',
                                        style: text.bodyLarge,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        row.rate == null
                                            ? l.currenciesNoRate
                                            : formatRate(
                                                row.rate!.rate,
                                                _lang(context),
                                              ),
                                        style: text.titleMedium,
                                      ),
                                      if (row.rate != null)
                                        Text(
                                          row.rate!.isWorkedOut
                                              ? l.currenciesWorkedOut
                                              : l.currenciesUpdatedOn(
                                                  _day(
                                                    context,
                                                    row.rate!.setOn,
                                                  ),
                                                ),
                                          style: text.bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  l.currenciesEdit,
                                  style: text.labelLarge?.copyWith(
                                    color: KibuoColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SettingsHelp(l.currenciesRatesHelp),
                ],
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: _add,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KibuoColors.ink,
                    backgroundColor: KibuoColors.surface,
                    side: const BorderSide(color: KibuoColors.line),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(l.currenciesAdd),
                ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: KibuoColors.inkSecondary),
      ),
    );
  }
}

/// The currency list: the phone's country's and the common ones on top,
/// then all the others, with a search field. Returns the chosen code.
Future<String?> pickCurrency(
  BuildContext context, {
  required String title,
  String? help,
  String? current,
  String? country,
}) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    builder: (_) => CurrencyPickerScreen(
      title: title,
      help: help,
      current: current,
      country: country,
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
  });

  final String title;
  final String? help;
  final String? current;

  /// The phone's country, whose currency comes first.
  final String? country;

  @override
  State<CurrencyPickerScreen> createState() => _CurrencyPickerScreenState();
}

class _CurrencyPickerScreenState extends State<CurrencyPickerScreen> {
  String _query = '';

  bool _matches(BuildContext context, CurrencyInfo c) {
    if (_query.isEmpty) return true;
    String fold(String s) => s
        .toLowerCase()
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[àâä]'), 'a')
        .replaceAll(RegExp('[îï]'), 'i')
        .replaceAll(RegExp('[ôö]'), 'o')
        .replaceAll(RegExp('[ùûü]'), 'u')
        .replaceAll('ç', 'c');
    final q = fold(_query);
    return fold(c.code).contains(q) ||
        fold(c.nameFr).contains(q) ||
        fold(c.nameEn).contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final lists = currenciesForChoosing(countryCode: widget.country);
    final top = lists.top.where((c) => _matches(context, c)).toList();
    final rest = lists.rest.where((c) => _matches(context, c)).toList();

    Widget tile(CurrencyInfo c) => ListTile(
      title: Text(currencyName(context, c)),
      subtitle: Text('${c.code} · ${c.symbol}'),
      trailing: c.code == widget.current
          ? const Icon(Icons.check, color: KibuoColors.accent)
          : null,
      onTap: () => Navigator.of(context).pop(c.code),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          if (widget.help != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(widget.help!, style: text.bodyMedium),
            ),
          TextField(
            autofocus: false,
            decoration: InputDecoration(
              hintText: l.currencySearch,
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: KibuoColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
          if (top.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(l.currencyCommon),
            _ListCard(children: [for (final c in top) tile(c)]),
          ],
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(l.currencyOthers),
            _ListCard(children: [for (final c in rest) tile(c)]),
          ],
        ],
      ),
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: KibuoColors.surface,
    borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

/// The rate sheet (validated mock-up « Taux depuis Réglages »): « 1 $ = … FC »
/// with a keypad, the previous rate and its date, and « Enregistrer ».
Future<void> showRateSheet(
  BuildContext context, {
  required CurrencyRepository repository,
  required CurrencyInfo main,
  required CurrencyInfo other,
  RateInfo? current,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _RateSheet(
    repository: repository,
    main: main,
    other: other,
    current: current,
  ),
);

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
  late bool _decimals = widget.other.usesDecimals;

  @override
  void initState() {
    super.initState();
    final shown = widget.current?.rate.forDisplay();
    if (shown != null) {
      _setDirection(shown.base, shown.quote);
    } else if (widget.other.usesDecimals && !widget.main.usesDecimals) {
      // « 1 $ = … FC » rather than « 1 FC = … $ ».
      _setDirection(widget.other.code, widget.main.code);
    } else {
      _setDirection(widget.main.code, widget.other.code);
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
    if (k == '⌫') {
      if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
    } else if (k == ',') {
      if (!_typed.contains(',')) _typed = _typed.isEmpty ? '0,' : '$_typed,';
    } else if (_typed.replaceAll(',', '').length < 12) {
      _typed = _typed == '0' ? k : '$_typed$k';
    }
  });

  Future<void> _save() async {
    final value = _value;
    if (value == null) return;
    await widget.repository.setRate(_base, _quote, value);
    if (_decimals != widget.other.usesDecimals) {
      await widget.repository.setUsesDecimals(widget.other.code, on: _decimals);
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// « +1,8 % » against the previous rate, in this sheet's direction.
  String? _variation() {
    final value = _value;
    final current = widget.current;
    if (value == null || current == null || current.isWorkedOut) return null;
    final before = current.rate.per(_base, _quote);
    final ratio =
        double.parse(value.toString()) / double.parse(before.toString()) - 1;
    if (ratio.abs() < 0.0005) return null;
    final percent = NumberFormat.decimalPatternDigits(
      locale: _lang(context),
      decimalDigits: 1,
    ).format(ratio.abs() * 100);
    return '${ratio > 0 ? '+' : '−'}$percent %';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final base = currencyOf(_base);
    final quote = currencyOf(_quote);
    final current = widget.current;
    final variation = _variation();
    final mono = TextStyle(
      fontFamily: KibuoTheme.displayFont,
      fontVariations: const [FontVariation.weight(600)],
      fontSize: 24,
      color: KibuoColors.ink,
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                l.rateSheetTitle(currencyName(context, widget.other)),
                style: text.titleLarge,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: KibuoColors.accent, width: 2),
              ),
              child: Row(
                children: [
                  Text('1 ${base.symbol} =', style: mono),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _typed.isEmpty ? '…' : _typed,
                      style: mono.copyWith(
                        color: _typed.isEmpty
                            ? KibuoColors.inkMuted
                            : KibuoColors.ink,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(quote.symbol, style: mono),
                  IconButton(
                    tooltip: l.rateSwap,
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => setState(() {
                      _setDirection(_quote, _base);
                      _typed = '';
                    }),
                  ),
                ],
              ),
            ),
            if (current != null && !current.isWorkedOut) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.rateBefore(
                        formatRate(current.rate, _lang(context)),
                        _day(context, current.setOn),
                      ),
                      style: text.bodySmall,
                    ),
                  ),
                  if (variation != null)
                    Text(
                      variation,
                      style: text.labelMedium?.copyWith(
                        color: KibuoColors.warningInk,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _RateKeypad(onKey: _key),
            if (widget.other.digits > 0) ...[
              SettingsSwitch(
                label: l.currencyDecimals,
                value: _decimals,
                onChanged: (on) => setState(() => _decimals = on),
              ),
              SettingsHelp(l.currencyDecimalsHelp),
            ],
            const SizedBox(height: 8),
            SettingsHelp(l.rateKeepsOld),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _value == null ? null : _save,
              child: Text(l.rateSave),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: KibuoColors.inkSecondary,
              ),
              child: Text(l.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

class _RateKeypad extends StatelessWidget {
  const _RateKeypad({required this.onKey});

  final ValueChanged<String> onKey;

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', ',', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.6,
      children: [
        for (final k in keys)
          Material(
            color: KibuoColors.surface,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onKey(k),
              child: Center(
                child: k == '⌫'
                    ? Icon(
                        Icons.backspace_outlined,
                        semanticLabel: AppLocalizations.of(context)
                            .keypadDelete,
                      )
                    : Text(
                        k,
                        style: const TextStyle(
                          fontFamily: KibuoTheme.displayFont,
                          fontVariations: [FontVariation.weight(500)],
                          fontSize: 22,
                          color: KibuoColors.ink,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
