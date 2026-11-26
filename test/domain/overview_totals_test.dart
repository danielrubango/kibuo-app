import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/overview/overview_totals.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';

void main() {
  final usd = currencyOf('USD');
  final rate = ExchangeRate(
    base: 'USD',
    quote: 'CDF',
    value: RateValue.parse('2800'),
  );
  ExchangeRate? rateFor(String code) => code == 'CDF' ? rate : null;

  final november = TimeSpan(DateTime(2026, 11), DateTime(2026, 12));
  final days = bucketsOf(november, Grouping.day);

  DatedFlow out(DateTime at, int minor, [String code = 'USD']) =>
      (at: at, flow: MoneyFlow(outgoing: Money(minor, code)));
  DatedFlow into(DateTime at, int minor) =>
      (at: at, flow: MoneyFlow(incoming: Money(minor, 'USD')));

  test('bars and total count the same operations, in the main currency', () {
    final flows = [
      out(DateTime(2026, 11, 1, 9), 1200),
      out(DateTime(2026, 11, 1, 18), 1400000, 'CDF'), // 5,00 $
      into(DateTime(2026, 11, 3, 8), 50000),
      out(DateTime(2026, 11, 30, 23, 59), 300),
      // Outside November: counted nowhere.
      out(DateTime(2026, 10, 31, 23, 59, 59), 9900),
      into(DateTime(2026, 12), 9900),
    ];
    final bars = totalsByBucket(days, flows, usd, rateFor);
    final total = totalsWithin(november, flows, usd, rateFor);

    expect(bars[0].exits, const Money(1700, 'USD'));
    expect(bars[2].entries, const Money(50000, 'USD'));
    expect(bars[29].exits, const Money(300, 'USD'));
    expect(total.exits, const Money(2000, 'USD'));
    expect(total.entries, const Money(50000, 'USD'));
    expect(bars.fold(0, (sum, b) => sum + b.exits.minor), total.exits.minor);
    expect(
      bars.fold(0, (sum, b) => sum + b.entries.minor),
      total.entries.minor,
    );
  });

  test('an operation at midnight goes to the new day', () {
    final bars = totalsByBucket(
      days,
      [
        out(DateTime(2026, 11, 2), 100),
        out(DateTime(2026, 11, 1, 23, 59, 59), 7),
      ],
      usd,
      rateFor,
    );
    expect(bars[0].exits.minor, 7);
    expect(bars[1].exits.minor, 100);
  });

  test('an amount without a rate is left out, and the total says so', () {
    final flows = [
      out(DateTime(2026, 11, 4), 1000, 'EUR'),
      out(DateTime(2026, 11, 5), 250),
    ];
    final total = totalsWithin(november, flows, usd, rateFor);
    expect(total.exits, const Money(250, 'USD'));
    expect(total.approximate, isTrue);
    expect(totalsByBucket(days, flows, usd, rateFor)[3].approximate, isTrue);
  });

  group('the change against the compared period', () {
    test('spending less than before is a good sign', () {
      final c = changeOf(8000, 10000, lessIsBetter: true)!;
      expect(c.percent, 20);
      expect(c.up, isFalse);
      expect(c.good, isTrue);
    });

    test('spending more is not', () {
      final c = changeOf(13300, 10000, lessIsBetter: true)!;
      expect(c.percent, 33);
      expect(c.up, isTrue);
      expect(c.good, isFalse);
    });

    test('receiving less than before is not a good sign', () {
      final c = changeOf(8000, 10000, lessIsBetter: false)!;
      expect(c.up, isFalse);
      expect(c.good, isFalse);
    });

    test('nothing to compare with: no change shown', () {
      expect(changeOf(500, 0, lessIsBetter: true), isNull);
    });
  });
}
