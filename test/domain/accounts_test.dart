import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/accounts/account_total.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

void main() {
  final usd = currencyOf('USD');
  final rates = {
    'CDF': ExchangeRate(
      base: 'USD',
      quote: 'CDF',
      value: RateValue.parse('2800'),
    ),
  };
  ExchangeRate? rateFor(String code) => rates[code];

  test('accounts in the main currency simply add up', () {
    final total = totalIn(usd, [
      const Money(20000, 'USD'),
      const Money(5050, 'USD'),
    ], rateFor);
    expect(total.amount, const Money(25050, 'USD'));
    expect(total.withoutRate, isEmpty);
  });

  test('another currency is converted at its latest rate', () {
    final total = totalIn(usd, [
      const Money(20000, 'USD'),
      const Money(8400000, 'CDF'),
    ], rateFor);
    expect(
      total.amount,
      const Money(23000, 'USD'),
      reason: '84 000 FC = 30 \$',
    );
  });

  test('an account without a rate is left out, and named', () {
    final total = totalIn(usd, [
      const Money(20000, 'USD'),
      const Money(1500, 'EUR'),
    ], rateFor);
    expect(total.amount, const Money(20000, 'USD'));
    expect(total.withoutRate, ['EUR']);
  });

  test('no account makes zero', () {
    expect(totalIn(usd, const [], rateFor).amount, const Money(0, 'USD'));
  });
}
