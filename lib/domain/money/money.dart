import 'package:kibuo/domain/money/currency.dart';

/// An amount in the smallest unit of its currency (cents, centimes), as an
/// integer, so sums never drift (ADR 0004).
class Money {
  const Money(this.minor, this.currency);

  /// Reads « 12.34 » (dot as decimal separator) into the smallest unit.
  factory Money.fromMajor(String amount, CurrencyInfo currency) {
    final negative = amount.startsWith('-');
    final digits = negative ? amount.substring(1) : amount;
    final parts = digits.split('.');
    if (parts.length > 2 || parts.first.isEmpty) {
      throw FormatException('Not an amount', amount);
    }
    final fraction = parts.length == 2 ? parts[1] : '';
    if (fraction.length > currency.digits) {
      throw FormatException('Too many decimals', amount);
    }
    final minor =
        BigInt.parse(parts.first) * BigInt.from(10).pow(currency.digits) +
        BigInt.parse(
          fraction.padRight(currency.digits, '0').isEmpty
              ? '0'
              : fraction.padRight(currency.digits, '0'),
        );
    final value = minor.toInt();
    return Money(negative ? -value : value, currency.code);
  }

  final int minor;

  /// ISO 4217 code.
  final String currency;

  Money operator +(Money other) => Money(minor + _same(other).minor, currency);

  Money operator -(Money other) => Money(minor - _same(other).minor, currency);

  Money _same(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('$currency and ${other.currency} cannot be added');
    }
    return other;
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => '$minor $currency';
}
