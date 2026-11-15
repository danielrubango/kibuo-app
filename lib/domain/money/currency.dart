import 'package:kibuo/domain/money/currency_catalog.dart';

/// A currency of the catalogue (ISO 4217), as Kibuo shows it.
class CurrencyInfo {
  const CurrencyInfo(
    this.code, {
    required this.digits,
    required this.usesDecimals,
    required this.symbol,
    required this.nameFr,
    required this.nameEn,
  });

  /// ISO 4217 code: USD, CDF…
  final String code;

  /// Digits of the smallest unit (2 for cents). Amounts are always stored in
  /// that unit, so turning decimals on or off never touches stored amounts.
  final int digits;

  /// Whether decimals are used day to day (not for the franc congolais).
  /// The user can change it for each currency.
  final bool usesDecimals;

  /// The everyday symbol: $, FC, €…
  final String symbol;

  final String nameFr;
  final String nameEn;

  CurrencyInfo withDecimals(bool on) => CurrencyInfo(
    code,
    digits: digits,
    usesDecimals: on && digits > 0,
    symbol: symbol,
    nameFr: nameFr,
    nameEn: nameEn,
  );

  @override
  bool operator ==(Object other) =>
      other is CurrencyInfo &&
      other.code == code &&
      other.usesDecimals == usesDecimals;

  @override
  int get hashCode => Object.hash(code, usesDecimals);
}

final _byCode = {for (final c in currencyCatalog) c.code: c};

/// The catalogue entry for [code]; throws for an unknown code.
CurrencyInfo currencyOf(String code) =>
    _byCode[code] ?? (throw ArgumentError.value(code, 'code', 'unknown'));

List<String> currencyCatalogCodes() => [
  for (final c in currencyCatalog) c.code,
];

/// The choice list: the phone's own currency and the common ones on top,
/// then every other currency.
({List<CurrencyInfo> top, List<CurrencyInfo> rest}) currenciesForChoosing({
  String? countryCode,
}) {
  final first = [?countryCurrency[countryCode], ...commonCurrencies];
  final topCodes = <String>{...first};
  return (
    top: [for (final code in topCodes) currencyOf(code)],
    rest: [
      for (final c in currencyCatalog)
        if (!topCodes.contains(c.code)) c,
    ],
  );
}

/// The main currency to start with: the phone's country's, else the dollar.
String defaultPrimaryCurrency(String? countryCode) =>
    countryCurrency[countryCode] ?? 'USD';
