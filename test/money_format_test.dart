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

  group('short amounts (PRODUCT: Montants longs)', () {
    String short(
      String major,
      CurrencyInfo c,
      String lang, {
      bool symbol = true,
    }) =>
        plain(formatShort(Money.fromMajor(major, c), c, lang, symbol: symbol));

    test('k, M, Md, one decimal at most, no « ,0 »', () {
      expect(short('128450300', cdf, 'fr'), '128,5 M FC');
      expect(short('1245', cdf, 'fr'), '1,2 k FC');
      expect(short('55000', cdf, 'fr'), '55 k FC');
      expect(short('2100000000', cdf, 'fr'), '2,1 Md FC');
      expect(short('707500', cdf, 'fr'), '707,5 k FC');
      expect(short('-2412500', cdf, 'fr'), '−2,4 M FC');
    });

    test('rounding up to the next unit', () {
      expect(short('999960', cdf, 'fr'), '1 M FC');
      expect(short('999940', cdf, 'fr'), '999,9 k FC');
    });

    test('cents count, and small amounts stay whole', () {
      expect(short('1234.56', usd, 'fr'), r'1,2 k $');
      expect(short('950', usd, 'fr'), r'950,00 $');
    });

    test('in English: K, M, B, symbol before', () {
      expect(short('128450300', cdf, 'en'), 'FC 128.5M');
      expect(short('1245', usd, 'en'), r'$1.2K');
      expect(short('2100000000', usd, 'en'), r'$2.1B');
      expect(short('-2412500', usd, 'en'), r'−$2.4M');
    });

    test('without the currency, where it is said next to it', () {
      expect(short('2412500', cdf, 'fr', symbol: false), '2,4 M');
    });

    test('« Toujours » shortens from 10 000 in the amount’s currency', () {
      expect(isLong(Money.fromMajor('9999.99', usd)), isFalse);
      expect(isLong(Money.fromMajor('10000', usd)), isTrue);
      expect(isLong(Money.fromMajor('-10000', cdf)), isTrue);
    });
  });
}
