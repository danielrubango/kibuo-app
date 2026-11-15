import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/ui/money/money_format.dart';

/// Spaces in numbers are non-breaking, so « 2 800 FC » never splits.
String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

void main() {
  final usd = currencyOf('USD');
  final cdf = currencyOf('CDF');

  test('in French: spaces between thousands, comma, symbol after', () {
    expect(
      plain(formatMoney(Money.fromMajor('2800', cdf), cdf, 'fr')),
      '2 800 FC',
    );
    expect(
      plain(formatMoney(Money.fromMajor('30', usd), usd, 'fr')),
      r'30,00 $',
    );
    expect(
      plain(formatMoney(Money.fromMajor('-1234.5', usd), usd, 'fr')),
      r'−1 234,50 $',
    );
  });

  test('in English: commas between thousands, dot, symbol before', () {
    expect(formatMoney(Money.fromMajor('30', usd), usd, 'en'), r'$30.00');
    expect(
      plain(formatMoney(Money.fromMajor('2800', cdf), cdf, 'en')),
      'FC 2,800',
    );
    expect(
      formatMoney(Money.fromMajor('-1234.5', usd), usd, 'en'),
      r'−$1,234.50',
    );
  });

  test('a currency with decimals turned off shows whole units', () {
    final noCents = usd.withDecimals(false);
    expect(
      plain(formatMoney(const Money(3049, 'USD'), noCents, 'fr')),
      r'30 $',
    );
  });

  test(r'a rate reads « 1 $ = 2 800 FC »', () {
    final rate = ExchangeRate(
      base: 'USD',
      quote: 'CDF',
      value: RateValue.parse('2800'),
    );
    expect(plain(formatRate(rate, 'fr')), r'1 $ = 2 800 FC');
    expect(plain(formatRate(rate, 'en')), r'$1 = FC 2,800');
  });

  test('a rate reads the way it was typed', () {
    final rate = ExchangeRate(
      base: 'USD',
      quote: 'EUR',
      value: RateValue.parse('0.92'),
    );
    expect(plain(formatRate(rate, 'fr')), '1 \$ = 0,92 €');
  });

  test('a long rate shows 4 decimals and 6 digits at most', () {
    ExchangeRate r(String v) =>
        ExchangeRate(base: 'EUR', quote: 'USD', value: RateValue.parse(v));
    expect(plain(formatRate(r('1.0869565'), 'fr')), '1 € = 1,087 \$');
    expect(plain(formatRate(r('3043.4782608'), 'fr')), '1 € = 3 043,48 \$');
    expect(plain(formatRate(r('0.000357'), 'fr')), '1 € = 0,0004 \$');
  });
}
