import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

void main() {
  final usd = currencyOf('USD');
  final cdf = currencyOf('CDF');
  final eur = currencyOf('EUR');
  final rwf = currencyOf('RWF');

  group('the catalogue', () {
    test('knows 150 or so currencies, each once', () {
      final codes = currencyCatalogCodes();
      expect(codes.length, greaterThan(140));
      expect(codes.toSet(), hasLength(codes.length));
    });

    test('names currencies in French and English, with everyday symbols', () {
      expect(cdf.nameFr, 'Franc congolais');
      expect(cdf.nameEn, 'Congolese Franc');
      expect(cdf.symbol, 'FC');
      expect(usd.symbol, r'$');
    });

    test('franc congolais has no decimals in use, the dollar has cents', () {
      expect(cdf.usesDecimals, isFalse);
      expect(usd.usesDecimals, isTrue);
      expect(rwf.digits, 0);
    });

    test('the phone’s country comes first, then the common currencies', () {
      final order = currenciesForChoosing(countryCode: 'RW');
      expect(order.top.first.code, 'RWF');
      expect(order.top.map((c) => c.code), containsAll(['CDF', 'USD', 'EUR']));
      expect(order.top.where((c) => c.code == 'RWF'), hasLength(1));
      expect(order.rest.map((c) => c.code), isNot(contains('USD')));
      expect(
        order.top.length + order.rest.length,
        currencyCatalogCodes().length,
      );
    });

    test('the default main currency follows the phone’s country', () {
      expect(defaultPrimaryCurrency('CD'), 'CDF');
      expect(defaultPrimaryCurrency('US'), 'USD');
      expect(defaultPrimaryCurrency(null), 'USD');
      expect(defaultPrimaryCurrency('ZZ'), 'USD');
    });
  });

  group('amounts', () {
    test('are kept in the smallest unit', () {
      expect(Money.fromMajor('12.34', usd), const Money(1234, 'USD'));
      expect(Money.fromMajor('2800', cdf), const Money(280000, 'CDF'));
      expect(Money.fromMajor('500', rwf), const Money(500, 'RWF'));
    });

    test('add and subtract in the same currency only', () {
      const a = Money(1000, 'USD');
      expect(a + const Money(250, 'USD'), const Money(1250, 'USD'));
      expect(a - const Money(1250, 'USD'), const Money(-250, 'USD'));
      expect(() => a + const Money(1, 'EUR'), throwsArgumentError);
    });
  });

  group('rates', () {
    test('are read as typed, with a comma or a dot, and spaces', () {
      expect(RateValue.parse('2 800'), RateValue.parse('2800'));
      expect(RateValue.parse('0,92'), RateValue.parse('0.92'));
      expect(RateValue.parse('655,957').toString(), '655.957');
      expect(() => RateValue.parse('0'), throwsFormatException);
      expect(() => RateValue.parse('abc'), throwsFormatException);
    });

    test('are written « 1 of the more valuable currency = … »', () {
      final rate = ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        value: RateValue.parse('2800'),
      );
      final shown = rate.forDisplay();
      expect((shown.base, shown.quote), ('USD', 'CDF'));

      final flipped = ExchangeRate(
        base: 'CDF',
        quote: 'USD',
        value: RateValue.parse('0.0005'),
      ).forDisplay();
      expect((flipped.base, flipped.quote), ('USD', 'CDF'));
      expect(flipped.value, RateValue.parse('2000'));
    });
  });

  group('converting', () {
    final dollarToFranc = ExchangeRate(
      base: 'USD',
      quote: 'CDF',
      value: RateValue.parse('2800'),
    );

    test('francs to dollars, rounded to the nearest cent', () {
      // 5 000 FC at 1 $ = 2 800 FC is 1.7857 $.
      final result = dollarToFranc.convert(
        Money.fromMajor('5000', cdf),
        to: usd,
      );
      expect(result, const Money(179, 'USD'));
    });

    test('dollars to francs, the other way', () {
      expect(
        dollarToFranc.convert(Money.fromMajor('30', usd), to: cdf),
        Money.fromMajor('84000', cdf),
      );
    });

    test('halves are rounded up, away from zero', () {
      final rate = ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        value: RateValue.parse('2000'),
      );
      // 25 FC is 0.0125 $: half a cent up to 0.01; 30 FC is 0.015 → 0.02.
      expect(
        rate.convert(Money.fromMajor('30', cdf), to: usd),
        const Money(2, 'USD'),
      );
      expect(
        rate.convert(Money.fromMajor('-30', cdf), to: usd),
        const Money(-2, 'USD'),
      );
    });

    test('a currency without decimals in use rounds to whole units', () {
      // 1.79 $ at 2 800 is 5 012 FC, not 5 012,00 with cents.
      expect(
        dollarToFranc.convert(const Money(179, 'USD'), to: cdf),
        Money.fromMajor('5012', cdf),
      );
    });

    test('precise rates keep their precision', () {
      final euroToCfa = ExchangeRate(
        base: 'EUR',
        quote: 'XAF',
        value: RateValue.parse('655.957'),
      );
      expect(
        euroToCfa.convert(Money.fromMajor('100', eur), to: currencyOf('XAF')),
        const Money(65596, 'XAF'),
      );
    });

    test('very large amounts do not overflow', () {
      expect(
        dollarToFranc.convert(Money.fromMajor('3000000000', usd), to: cdf),
        Money.fromMajor('8400000000000', cdf),
      );
    });

    test('only between the rate’s two currencies', () {
      expect(
        () => dollarToFranc.convert(Money.fromMajor('1', eur), to: usd),
        throwsArgumentError,
      );
    });
  });
}
