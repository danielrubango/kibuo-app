import 'package:intl/intl.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

const _minus = '−';
const _nbsp = ' ';

/// « 2 800 FC », « 30,00 $ » in French; « FC 2,800 », « $30.00 » in English.
/// Decimals follow [currency]'s use (none for the franc congolais).
String formatMoney(Money amount, CurrencyInfo currency, String locale) {
  final decimals = currency.usesDecimals ? currency.digits : 0;
  final number = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimals,
  ).format(amount.minor.abs() / _pow10(currency.digits));
  final sign = amount.minor < 0 ? _minus : '';
  return _withSymbol(sign, number, currency.symbol, locale);
}

/// « 1 $ = 2 800 FC », with 1 unit of the more valuable currency.
String formatRate(ExchangeRate rate, String locale) {
  final shown = rate.forDisplay();
  final base = currencyOf(shown.base);
  final quote = currencyOf(shown.quote);
  final value = shown.value.toString().split('.');
  final whole = NumberFormat.decimalPattern(locale).format(int.parse(value[0]));
  final decimal = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  final number = value.length == 2 ? '$whole$decimal${value[1]}' : whole;
  return '${_withSymbol('', '1', base.symbol, locale)} = '
      '${_withSymbol('', number, quote.symbol, locale)}';
}

String _withSymbol(String sign, String number, String symbol, String locale) {
  final before = !locale.startsWith('fr');
  if (!before) return '$sign$number$_nbsp$symbol';
  // A symbol made of letters gets a space: « FC 2,800 », but « $30.00 ».
  final gap = RegExp('[A-Za-z]').hasMatch(symbol) ? _nbsp : '';
  return '$sign$symbol$gap$number';
}

num _pow10(int digits) => [1, 10, 100, 1000, 10000][digits];
