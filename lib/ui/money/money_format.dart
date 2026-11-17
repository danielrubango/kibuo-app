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

/// « −588,00 », « +1 200,00 »: the amount with its sign and without the
/// currency, where the currency is said next to it.
String formatSigned(Money amount, CurrencyInfo currency, String locale) {
  final decimals = currency.usesDecimals ? currency.digits : 0;
  final number = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: decimals,
  ).format(amount.minor.abs() / _pow10(currency.digits));
  if (amount.minor == 0) return number;
  return '${amount.minor < 0 ? _minus : '+'}$number';
}

/// « 1 $ = 2 800 FC », the way the rate is written: at most 4 decimals and
/// 6 digits, so a worked-out rate stays readable.
String formatRate(ExchangeRate rate, String locale) {
  final base = currencyOf(rate.base);
  final quote = currencyOf(rate.quote);
  final value = double.parse(rate.value.toString());
  final whole = value.abs().truncate().toString().length;
  final number = NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: (6 - whole).clamp(0, 4),
  ).format(value);
  final decimal = NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
  final trimmed = number.contains(decimal)
      ? number
            .replaceFirst(RegExp('0*\$'), '')
            .replaceFirst(RegExp('${RegExp.escape(decimal)}\$'), '')
      : number;
  return '${_withSymbol('', '1', base.symbol, locale)} = '
      '${_withSymbol('', trimmed, quote.symbol, locale)}';
}

const _units = [(1000, 'k', 'K'), (1000000, 'M', 'M'), (1000000000, 'Md', 'B')];

/// « 128,5 M FC », « 1,2 k $ » in French; « FC 128.5M », « $1.2K » in
/// English (PRODUCT: Montants longs): one decimal at most, no « ,0 ».
/// Below 1 000 the amount stays whole. Without [symbol], the number alone
/// (« 2,4 M »), where the currency is said next to it.
String formatShort(
  Money amount,
  CurrencyInfo currency,
  String locale, {
  bool symbol = true,
}) {
  final sign = amount.minor < 0 ? _minus : '';
  final scale = _pow10(currency.digits).toInt();
  final abs = amount.minor.abs();
  var i = _units.lastIndexWhere((u) => abs >= u.$1 * scale);
  if (i < 0) {
    if (symbol) return formatMoney(amount, currency, locale);
    final decimals = currency.usesDecimals ? currency.digits : 0;
    return sign +
        NumberFormat.decimalPatternDigits(
          locale: locale,
          decimalDigits: decimals,
        ).format(abs / scale);
  }
  int tenthsIn(int unit) => (abs * 10 + unit * scale ~/ 2) ~/ (unit * scale);
  var tenths = tenthsIn(_units[i].$1);
  // 999 960 is « 1 M », not « 1 000 k ».
  if (tenths >= 10000 && i < _units.length - 1) {
    i++;
    tenths = tenthsIn(_units[i].$1);
  }
  final format = NumberFormat.decimalPattern(locale);
  final whole = format.format(tenths ~/ 10);
  final decimal = tenths % 10 == 0
      ? ''
      : '${format.symbols.DECIMAL_SEP}${tenths % 10}';
  final french = locale.startsWith('fr');
  final unit = french ? '$_nbsp${_units[i].$2}' : _units[i].$3;
  final number = '$whole$decimal$unit';
  return symbol
      ? _withSymbol(sign, number, currency.symbol, locale)
      : '$sign$number';
}

/// [amount] whole, or short (« 128,5 M FC »).
String formatAmount(
  Money amount,
  CurrencyInfo currency,
  String locale, {
  bool short = false,
}) => (short ? formatShort : formatMoney)(amount, currency, locale);

/// From 10 000 in its own currency, « Toujours » shortens an amount.
bool isLong(Money amount) =>
    amount.minor.abs() >= 10000 * _pow10(currencyOf(amount.currency).digits);

String _withSymbol(String sign, String number, String symbol, String locale) {
  final before = !locale.startsWith('fr');
  if (!before) return '$sign$number$_nbsp$symbol';
  // A symbol made of letters gets a space: « FC 2,800 », but « $30.00 ».
  final gap = RegExp('[A-Za-z]').hasMatch(symbol) ? _nbsp : '';
  return '$sign$symbol$gap$number';
}

num _pow10(int digits) => [1, 10, 100, 1000, 10000][digits];
