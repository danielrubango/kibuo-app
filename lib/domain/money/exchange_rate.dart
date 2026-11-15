import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';

/// A positive decimal number kept exactly: [units] / 10^[scale].
class RateValue {
  RateValue._(this.units, this.scale);

  /// Reads a rate as typed: « 2 800 », « 0,92 », « 655.957 ».
  factory RateValue.parse(String typed) {
    final clean = typed.replaceAll(RegExp(r'[\s  ]'), '').replaceAll(',', '.');
    final match = RegExp(r'^(\d+)(?:\.(\d+))?$').firstMatch(clean);
    if (match == null) throw FormatException('Not a rate', typed);
    final fraction = match.group(2) ?? '';
    final value = RateValue._(
      BigInt.parse('${match.group(1)}$fraction'),
      fraction.length,
    )._trimmed();
    if (value.units == BigInt.zero) throw FormatException('Zero rate', typed);
    return value;
  }

  /// [RateValue.parse], or null for a typed text that is not a rate yet.
  static RateValue? tryParse(String typed) {
    try {
      return RateValue.parse(typed);
    } on FormatException {
      return null;
    }
  }

  final BigInt units;
  final int scale;

  BigInt get _denominator => BigInt.from(10).pow(scale);

  bool get isBelowOne => units < _denominator;

  /// 1 / this, kept to 8 significant digits.
  RateValue inverted() {
    const precision = 8;
    final digits = units.toString().length - scale;
    final scaleOut = (precision - (1 - digits)).clamp(0, 40);
    final numerator = _denominator * BigInt.from(10).pow(scaleOut);
    return RateValue._(_divideRounded(numerator, units), scaleOut)._trimmed();
  }

  /// this × [other], kept to 12 decimals.
  RateValue times(RateValue other) => RateValue._fraction(
    units * other.units,
    _denominator * other._denominator,
  );

  /// this ÷ [other], kept to 12 decimals.
  RateValue dividedBy(RateValue other) => RateValue._fraction(
    units * other._denominator,
    _denominator * other.units,
  );

  factory RateValue._fraction(BigInt numerator, BigInt denominator) {
    const scale = 12;
    return RateValue._(
      _divideRounded(numerator * BigInt.from(10).pow(scale), denominator),
      scale,
    )._trimmed();
  }

  RateValue _trimmed() {
    var u = units;
    var s = scale;
    while (s > 0 && u % BigInt.from(10) == BigInt.zero) {
      u ~/= BigInt.from(10);
      s--;
    }
    return RateValue._(u, s);
  }

  @override
  bool operator ==(Object other) {
    if (other is! RateValue) return false;
    final a = _trimmed();
    final b = other._trimmed();
    return a.units == b.units && a.scale == b.scale;
  }

  @override
  int get hashCode {
    final t = _trimmed();
    return Object.hash(t.units, t.scale);
  }

  /// « 655.957 »: kept as is in the database.
  @override
  String toString() {
    final t = _trimmed();
    if (t.scale == 0) return t.units.toString();
    final s = t.units.toString().padLeft(t.scale + 1, '0');
    return '${s.substring(0, s.length - t.scale)}.${s.substring(s.length - t.scale)}';
  }
}

/// « 1 [base] = [value] [quote] », as the user typed it (ADR 0004).
class ExchangeRate {
  const ExchangeRate({
    required this.base,
    required this.quote,
    required this.value,
  });

  final String base;
  final String quote;
  final RateValue value;

  /// How many [to] for one [from]; [from] and [to] are this rate's currencies.
  RateValue per(String from, String to) {
    if (from == base && to == quote) return value;
    if (from == quote && to == base) {
      return RateValue._fraction(value._denominator, value.units);
    }
    throw ArgumentError('$from → $to is not $base ↔ $quote');
  }

  /// « 1 [from] = … [to] » worked out through a third currency: [first]
  /// links [from] to it, [second] links it to [to].
  static ExchangeRate through({
    required String from,
    required String to,
    required ExchangeRate first,
    required ExchangeRate second,
  }) {
    final pivot = first.base == from ? first.quote : first.base;
    return ExchangeRate(
      base: from,
      quote: to,
      value: first.per(from, pivot).times(second.per(pivot, to)),
    );
  }

  /// The same rate written « 1 [base] = … [quote] ».
  ExchangeRate toward(String base, String quote) =>
      ExchangeRate(base: base, quote: quote, value: per(base, quote));

  /// Converts [amount] (in either currency of the rate) into [to], rounded
  /// to its smallest unit in use, halves away from zero.
  Money convert(Money amount, {required CurrencyInfo to}) {
    final from = currencyOf(amount.currency);
    final ten = BigInt.from(10);
    final BigInt numerator;
    final BigInt denominator;
    if (amount.currency == base && to.code == quote) {
      numerator = BigInt.from(amount.minor) * value.units * ten.pow(to.digits);
      denominator = ten.pow(from.digits) * value._denominator;
    } else if (amount.currency == quote && to.code == base) {
      numerator =
          BigInt.from(amount.minor) * value._denominator * ten.pow(to.digits);
      denominator = ten.pow(from.digits) * value.units;
    } else {
      throw ArgumentError(
        '${amount.currency} → ${to.code} is not $base ↔ $quote',
      );
    }
    // Without decimals in use, round to whole units of the currency.
    final step = to.usesDecimals ? BigInt.one : ten.pow(to.digits);
    final rounded = _divideRounded(numerator, denominator * step) * step;
    return Money(rounded.toInt(), to.code);
  }
}

/// a / b rounded to the nearest integer, halves away from zero.
BigInt _divideRounded(BigInt a, BigInt b) {
  final negative = a.isNegative != b.isNegative;
  final q = (a.abs() * BigInt.two + b.abs()) ~/ (b.abs() * BigInt.two);
  return negative ? -q : q;
}

/// Which way a new rate is typed: « 1 [main] = … », except when the main
/// currency is used without cents and the other with them (franc, yen):
/// « 1 $ = … FC » rather than « 1 FC = 0,000357 $ ».
(String, String) rateDirection({
  required CurrencyInfo main,
  required CurrencyInfo other,
}) => !main.usesDecimals && other.usesDecimals
    ? (other.code, main.code)
    : (main.code, other.code);
