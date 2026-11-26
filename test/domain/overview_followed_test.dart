import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/overview/followed.dart';
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
  final now = DateTime(2026, 11, 12, 15, 20);

  DatedFlow out(DateTime at, int minor, [String code = 'USD']) =>
      (at: at, flow: MoneyFlow(outgoing: Money(minor, code)));
  DatedFlow into(DateTime at, int minor) =>
      (at: at, flow: MoneyFlow(incoming: Money(minor, 'USD')));

  group('the scale a period is read at', () {
    TimeSpan days(int n) =>
        TimeSpan.days(DateTime(2026, 11, 1), DateTime(2026, 11, n));
    test('each period has its scale; a custom one goes by its length', () {
      final any = days(1);
      expect(scaleOf(PeriodKind.today, any), PeriodScale.day);
      expect(scaleOf(PeriodKind.yesterday, any), PeriodScale.day);
      expect(scaleOf(PeriodKind.last24Hours, any), PeriodScale.day);
      expect(scaleOf(PeriodKind.last7Days, any), PeriodScale.week);
      expect(scaleOf(PeriodKind.month, any), PeriodScale.month);
      expect(scaleOf(PeriodKind.year, any), PeriodScale.long);
      // PRODUCT: up to 2 days as a day, up to 2 weeks as a week, beyond as
      // a month or a year.
      expect(scaleOf(PeriodKind.custom, days(2)), PeriodScale.day);
      expect(scaleOf(PeriodKind.custom, days(14)), PeriodScale.week);
      expect(scaleOf(PeriodKind.custom, days(30)), PeriodScale.month);
      final long = TimeSpan.days(DateTime(2026, 9), DateTime(2026, 11, 12));
      expect(scaleOf(PeriodKind.custom, long), PeriodScale.long);
    });
  });

  test('the average day: the 30 days before today, today left out', () {
    final flows = [
      out(DateTime(2026, 11, 12, 9), 99900), // today: left out
      out(DateTime(2026, 11, 11, 23, 59), 3000),
      out(DateTime(2026, 10, 13), 1400000, 'CDF'), // 5,00 $, the 30th day
      out(DateTime(2026, 10, 12, 23, 59), 99900), // 31 days back: left out
      into(DateTime(2026, 11, 2), 50000), // money in: not spent
    ];
    // (30,00 $ + 5,00 $) over 30 days, rounded.
    expect(averageDay(flows, now: now, main: usd, rateFor: rateFor), 117);
  });

  group('the average by day, week or month', () {
    final november = TimeSpan(DateTime(2026, 11), DateTime(2026, 12));
    final flows = [
      out(DateTime(2026, 11, 1, 10), 6000),
      out(DateTime(2026, 11, 12, 10), 6000),
    ];

    test('a period in progress divides by the days gone, today included', () {
      final a = averageOf(
        november,
        flows,
        unit: Grouping.day,
        now: now,
        main: usd,
        rateFor: rateFor,
      );
      expect(a.units, 12);
      expect(a.amount, 1000);
    });

    test('a past period divides by all its units', () {
      final october = TimeSpan(DateTime(2026, 10), DateTime(2026, 11));
      final a = averageOf(
        october,
        [out(DateTime(2026, 10, 5), 31000)],
        unit: Grouping.day,
        now: now,
        main: usd,
        rateFor: rateFor,
      );
      expect(a.units, 31);
      expect(a.amount, 1000);
    });

    test('by month over a year: the months begun so far', () {
      final year = TimeSpan(DateTime(2026), DateTime(2027));
      final a = averageOf(
        year,
        [out(DateTime(2026, 3, 3), 110000)],
        unit: Grouping.month,
        now: now,
        main: usd,
        rateFor: rateFor,
      );
      expect(a.units, 11);
      expect(a.amount, 10000);
    });
  });

  test('the priciest bar, the first one when two are equal', () {
    final week = TimeSpan.days(DateTime(2026, 11, 6), DateTime(2026, 11, 12));
    final bars = bucketsOf(week, Grouping.day);
    final p = priciest(
      bars,
      [
        out(DateTime(2026, 11, 7, 9), 1200),
        out(DateTime(2026, 11, 9, 9), 2600),
        out(DateTime(2026, 11, 11, 9), 2600),
      ],
      main: usd,
      rateFor: rateFor,
    )!;
    expect(p.index, 3);
    expect(p.amount, 2600);
    expect(p.values, [0, 1200, 0, 2600, 0, 2600, 0]);
    expect(priciest(bars, const [], main: usd, rateFor: rateFor), isNull);
  });

  test('the first category: subcategories count in their parent', () {
    final november = TimeSpan(DateTime(2026, 11), DateTime(2026, 12));
    final spends = <CategorySpend>[
      (
        at: DateTime(2026, 11, 2),
        category: 'food-restaurant',
        amount: const Money(3000, 'USD'),
      ),
      (
        at: DateTime(2026, 11, 3),
        category: 'food',
        amount: const Money(2000, 'USD'),
      ),
      (
        at: DateTime(2026, 11, 4),
        category: 'rent',
        amount: const Money(4000, 'USD'),
      ),
      (
        at: DateTime(2026, 10, 4),
        category: 'rent',
        amount: const Money(99900, 'USD'),
      ),
    ];
    final top = topCategory(
      november,
      spends,
      parentOf: (id) => id == 'food-restaurant' ? 'food' : id,
      exits: 10000,
      main: usd,
      rateFor: rateFor,
    )!;
    expect(top.category, 'food');
    expect(top.amount, 5000);
    expect(top.share, 50);
    expect(
      topCategory(
        november,
        const [],
        parentOf: (id) => id,
        exits: 0,
        main: usd,
        rateFor: rateFor,
      ),
      isNull,
    );
  });

  test('what is left for today in a monthly budget', () {
    // 300 $ for November, 120 $ spent before today, 19 days left with
    // today: 9,47 $ a day; 4 $ spent today.
    final left = leftForToday(
      amount: 30000,
      spentBefore: 12000,
      spentToday: 400,
      daysLeft: 19,
    );
    expect(left.allowance, 947);
    expect(left.left, 547);
    // Over the budget already: nothing to spend today.
    final over = leftForToday(
      amount: 30000,
      spentBefore: 31000,
      spentToday: 0,
      daysLeft: 19,
    );
    expect(over.allowance, 0);
    expect(over.left, 0);
  });

  test('a running total, bar after bar', () {
    expect(runningTotal([0, 200, 0, 300]), [0, 200, 200, 500]);
  });

  test('a total back in time: today\'s less what changed since', () {
    // 1 000 $ today; 300 $ came in on the 5th, 50 $ went out on the 9th;
    // an account opened on the 3rd with 200 $.
    final changes = [
      (at: DateTime(2026, 11, 5, 10), change: 30000),
      (at: DateTime(2026, 11, 9, 18), change: -5000),
      (at: DateTime(2026, 11, 3), change: 20000),
    ];
    final values = totalsBack(
      [
        DateTime(2026, 11, 3),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 6),
        DateTime(2026, 11, 10),
      ],
      current: 100000,
      changes: changes,
    );
    expect(values, [55000, 75000, 105000, 100000]);
  });

  test('the budget shown at first is the one nearest its limit', () {
    expect(
      nearestLimit([
        (id: 'food', percent: 64),
        (id: 'fun', percent: 104),
        (id: 'rent', percent: 98),
      ]),
      'fun',
    );
    expect(nearestLimit(const []), isNull);
  });

  test('the project shown at first is the running one due soonest', () {
    final projects = [
      (id: 'phone', due: DateTime(2027, 3), running: true),
      (id: 'trip', due: DateTime(2026, 12, 20), running: true),
      (id: 'done', due: DateTime(2026, 11, 20), running: false),
      (id: 'someday', due: null, running: true),
    ];
    expect(soonestDue(projects), 'trip');
    expect(soonestDue([(id: 'someday', due: null, running: true)]), 'someday');
    expect(soonestDue(const []), isNull);
  });
}
