import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/overview/overview_period.dart';

void main() {
  // The canvas ApercuP2 is drawn on Thursday 12 November 2026, 15 h.
  final now = DateTime(2026, 11, 12, 15, 20);

  TimeSpan span(
    PeriodKind kind, {
    int offset = 0,
    int startDay = 1,
    DateTime? at,
    TimeSpan? custom,
  }) => periodSpan(
    kind,
    now: at ?? now,
    offset: offset,
    startDay: startDay,
    custom: custom,
  );

  group('the period shown, and a step back', () {
    test('Aujourd’hui is today until midnight; back is the day before', () {
      expect(
        span(PeriodKind.today),
        TimeSpan(DateTime(2026, 11, 12), DateTime(2026, 11, 13)),
      );
      expect(
        span(PeriodKind.today, offset: -1),
        TimeSpan(DateTime(2026, 11, 11), DateTime(2026, 11, 12)),
      );
    });

    test('Hier is the day before today, and steps back day by day', () {
      expect(
        span(PeriodKind.yesterday),
        TimeSpan(DateTime(2026, 11, 11), DateTime(2026, 11, 12)),
      );
      expect(
        span(PeriodKind.yesterday, offset: -1),
        TimeSpan(DateTime(2026, 11, 10), DateTime(2026, 11, 11)),
      );
    });

    test('24 h ends with the current hour; back is a day earlier', () {
      expect(
        span(PeriodKind.last24Hours),
        TimeSpan(DateTime(2026, 11, 11, 16), DateTime(2026, 11, 12, 16)),
      );
      expect(
        span(PeriodKind.last24Hours, offset: -1),
        TimeSpan(DateTime(2026, 11, 10, 16), DateTime(2026, 11, 11, 16)),
      );
    });

    test('7 jours ends today; back is the 7 days before', () {
      expect(
        span(PeriodKind.last7Days),
        TimeSpan(DateTime(2026, 11, 6), DateTime(2026, 11, 13)),
      );
      expect(
        span(PeriodKind.last7Days, offset: -1),
        TimeSpan(DateTime(2026, 10, 30), DateTime(2026, 11, 6)),
      );
    });

    test('1 mois is the budget month, from the month start day', () {
      expect(
        span(PeriodKind.month),
        TimeSpan(DateTime(2026, 11), DateTime(2026, 12)),
      );
      expect(
        span(PeriodKind.month, offset: -11),
        TimeSpan(DateTime(2025, 12), DateTime(2026)),
      );
      // From the 25th, the 26 November is already in December's period.
      final late = DateTime(2026, 11, 26, 9);
      expect(
        span(PeriodKind.month, startDay: 25, at: late),
        TimeSpan(DateTime(2026, 11, 25), DateTime(2026, 12, 25)),
      );
      expect(
        span(PeriodKind.month, startDay: 25, at: late, offset: -1),
        TimeSpan(DateTime(2026, 10, 25), DateTime(2026, 11, 25)),
      );
    });

    test('1 an runs from January to December, from the month start day', () {
      expect(span(PeriodKind.year), TimeSpan(DateTime(2026), DateTime(2027)));
      expect(
        span(PeriodKind.year, offset: -1),
        TimeSpan(DateTime(2025), DateTime(2026)),
      );
      expect(
        span(PeriodKind.year, startDay: 25),
        TimeSpan(DateTime(2025, 12, 25), DateTime(2026, 12, 25)),
      );
      // The 26 December is in January's period, so in the next year.
      expect(
        span(PeriodKind.year, startDay: 25, at: DateTime(2026, 12, 26)),
        TimeSpan(DateTime(2026, 12, 25), DateTime(2027, 12, 25)),
      );
    });

    test('a custom period steps by its own length', () {
      final chosen = TimeSpan.days(DateTime(2026, 9), DateTime(2026, 11, 12));
      expect(chosen.days, 73);
      expect(span(PeriodKind.custom, custom: chosen), chosen);
      expect(
        span(PeriodKind.custom, custom: chosen, offset: -1),
        TimeSpan(DateTime(2026, 6, 20), DateTime(2026, 9)),
      );
    });

    test('midnight already belongs to the new day', () {
      expect(
        span(PeriodKind.today, at: DateTime(2026, 11, 13)),
        TimeSpan(DateTime(2026, 11, 13), DateTime(2026, 11, 14)),
      );
      expect(
        span(PeriodKind.today, at: DateTime(2026, 11, 12, 23, 59, 59)),
        TimeSpan(DateTime(2026, 11, 12), DateTime(2026, 11, 13)),
      );
      expect(
        span(PeriodKind.month, at: DateTime(2026, 12)),
        TimeSpan(DateTime(2026, 12), DateTime(2027)),
      );
    });
  });

  group('Regrouper par', () {
    test('each period offers its groupings, the first one by default', () {
      List<Grouping> of(PeriodKind kind) => groupingsFor(kind, span(kind));
      expect(of(PeriodKind.today), [Grouping.hour]);
      expect(of(PeriodKind.yesterday), [Grouping.hour]);
      expect(of(PeriodKind.last24Hours), [Grouping.hour]);
      expect(of(PeriodKind.last7Days), [Grouping.day]);
      expect(of(PeriodKind.month), [Grouping.day, Grouping.week]);
      expect(of(PeriodKind.year), [Grouping.month, Grouping.week]);
    });

    test('a custom period offers what fits its length', () {
      List<Grouping> of(DateTime first, DateTime last) =>
          groupingsFor(PeriodKind.custom, TimeSpan.days(first, last));
      expect(of(DateTime(2026, 11, 3), DateTime(2026, 11, 12)), [Grouping.day]);
      expect(of(DateTime(2026, 9), DateTime(2026, 11, 12)), [
        Grouping.day,
        Grouping.week,
        Grouping.month,
      ]);
      expect(of(DateTime(2026, 4), DateTime(2026, 11, 12)), [
        Grouping.week,
        Grouping.month,
      ]);
      expect(of(DateTime(2024), DateTime(2026, 11, 12)), [Grouping.month]);
    });
  });

  group('the bars', () {
    void expectNoGap(TimeSpan period, List<TimeSpan> bars) {
      expect(bars.first.start, period.start);
      expect(bars.last.end, period.end);
      for (var i = 1; i < bars.length; i++) {
        expect(bars[i].start, bars[i - 1].end);
      }
    }

    test('a day by hour has 24 bars', () {
      final day = span(PeriodKind.today);
      final bars = bucketsOf(day, Grouping.hour);
      expect(bars, hasLength(24));
      expect(
        bars.first,
        TimeSpan(DateTime(2026, 11, 12), DateTime(2026, 11, 12, 1)),
      );
      expectNoGap(day, bars);
    });

    test('a month by day has a bar a day, from the month start day', () {
      final month = span(
        PeriodKind.month,
        startDay: 25,
        at: DateTime(2026, 11, 20),
      );
      final bars = bucketsOf(month, Grouping.day, startDay: 25);
      expect(bars, hasLength(31));
      expect(
        bars.first,
        TimeSpan(DateTime(2026, 10, 25), DateTime(2026, 10, 26)),
      );
      expectNoGap(month, bars);
    });

    test('weeks are 7 days from the first day, the last one shorter', () {
      final october = span(PeriodKind.month, offset: -1);
      final bars = bucketsOf(october, Grouping.week);
      expect(bars, hasLength(5));
      expect(bars.last, TimeSpan(DateTime(2026, 10, 29), DateTime(2026, 11)));
      expectNoGap(october, bars);
    });

    test('a year by month has its 12 budget months', () {
      final year = span(PeriodKind.year, startDay: 25);
      final bars = bucketsOf(year, Grouping.month, startDay: 25);
      expect(bars, hasLength(12));
      expect(
        bars.first,
        TimeSpan(DateTime(2025, 12, 25), DateTime(2026, 1, 25)),
      );
      expect(
        bars.last,
        TimeSpan(DateTime(2026, 11, 25), DateTime(2026, 12, 25)),
      );
      expectNoGap(year, bars);
    });

    test('a custom period by month cuts its first and last months', () {
      final chosen = TimeSpan.days(
        DateTime(2026, 9, 10),
        DateTime(2026, 11, 12),
      );
      final bars = bucketsOf(chosen, Grouping.month);
      expect(bars, [
        TimeSpan(DateTime(2026, 9, 10), DateTime(2026, 10)),
        TimeSpan(DateTime(2026, 10), DateTime(2026, 11)),
        TimeSpan(DateTime(2026, 11), DateTime(2026, 11, 13)),
      ]);
    });
  });

  group('Comparer à', () {
    test(
      'D’avant is the period before; D’après and Actuelle need a past one',
      () {
        expect(comparedOffset(Comparison.previous, offset: 0), -1);
        expect(comparedOffset(Comparison.none, offset: 0), isNull);
        expect(comparisonOpen(Comparison.previous, offset: 0), isTrue);
        expect(comparisonOpen(Comparison.next, offset: 0), isFalse);
        expect(comparisonOpen(Comparison.current, offset: 0), isFalse);
        expect(comparisonOpen(Comparison.next, offset: -2), isTrue);
        expect(comparedOffset(Comparison.next, offset: -2), -1);
        expect(comparedOffset(Comparison.current, offset: -2), 0);
      },
    );

    test('a month in progress is compared up to the same date', () {
      final until = comparedUntil(
        current: span(PeriodKind.month),
        compared: span(PeriodKind.month, offset: -1),
        now: now,
        grouping: Grouping.day,
      );
      // From 1 to 12 November against from 1 to 12 October.
      expect(until, DateTime(2026, 10, 13));
    });

    test('a day in progress is compared up to the same hour', () {
      final until = comparedUntil(
        current: span(PeriodKind.today),
        compared: span(PeriodKind.today, offset: -1),
        now: now,
        grouping: Grouping.hour,
      );
      expect(until, DateTime(2026, 11, 11, 16));
    });

    test('a past period is compared with the whole compared period', () {
      final september = span(PeriodKind.month, offset: -2);
      final until = comparedUntil(
        current: span(PeriodKind.month, offset: -1),
        compared: september,
        now: now,
        grouping: Grouping.day,
      );
      expect(until, september.end);
    });

    test('the same date stops at the end of a shorter month', () {
      final march31 = DateTime(2027, 3, 31, 20);
      final february = span(PeriodKind.month, at: march31, offset: -1);
      final until = comparedUntil(
        current: span(PeriodKind.month, at: march31),
        compared: february,
        now: march31,
        grouping: Grouping.day,
      );
      expect(until, february.end);
    });
  });
}
