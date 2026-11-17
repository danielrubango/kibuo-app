import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/transactions/search.dart';

void main() {
  group('text', () {
    test('ignores accents and capitals', () {
      final q = SearchQuery.parse('ecole');
      expect(q.find('École'), (0, 5));
      expect(SearchQuery.parse('TAXI').find('Moto-taxi'), (5, 9));
      expect(SearchQuery.parse('régul').find('Regularisation'), (0, 5));
    });

    test('says where it is found, in the field’s own letters', () {
      expect(SearchQuery.parse('pésa').find('M-Pesa · 01:40'), (2, 6));
      expect(SearchQuery.parse('loyer').find('Transport'), isNull);
    });

    test('spaces around do not count; empty finds nothing', () {
      expect(SearchQuery.parse('  taxi ').find('Taxi'), (0, 4));
      expect(SearchQuery.parse('   ').isEmpty, isTrue);
      expect(SearchQuery.parse('').find('Taxi'), isNull);
    });
  });

  group('amount', () {
    // Two decimals: 3 000 is 30,00.
    bool hits(String typed, int minor, {int decimals = 2}) =>
        SearchQuery.parse(typed).matchesAmount(minor, decimals: decimals);

    test('a whole number finds that amount, any cents', () {
      expect(hits('30', 3000), isTrue);
      expect(hits('30', 3099), isTrue);
      expect(hits('30', 250), isFalse, reason: 'not 2,50');
      expect(hits('50', 25000), isFalse, reason: 'not 250,00');
      expect(hits('50', 150000), isFalse, reason: 'not 1 500,00');
    });

    test('with cents, that exact amount', () {
      expect(hits('30,5', 3050), isTrue);
      expect(hits('30.5', 3050), isTrue);
      expect(hits('30,50', 3050), isTrue);
      expect(hits('30,5', 3005), isFalse);
      expect(hits('30,', 3012), isTrue);
    });

    test('thousands may be spaced', () {
      expect(hits('1 500', 150000), isTrue);
      expect(hits('1 500,00', 150000), isTrue);
      expect(hits('1500', 150000), isTrue);
    });

    test('a currency without cents', () {
      expect(hits('5000', 5000, decimals: 0), isTrue);
      expect(hits('5000,5', 5000, decimals: 0), isFalse);
    });

    test('words are not amounts', () {
      expect(SearchQuery.parse('taxi').matchesAmount(3000), isFalse);
      expect(SearchQuery.parse('3 taxis').matchesAmount(300), isFalse);
    });
  });

  group('recent searches', () {
    test('newest first, five at most, each once', () {
      var recent = <String>[];
      for (final q in ['Taxi', 'Loyer', 'taxi ', '30', 'Eau', 'Bus', 'Pain']) {
        recent = rememberSearch(recent, q);
      }
      expect(recent, ['Pain', 'Bus', 'Eau', '30', 'taxi']);
    });

    test('blank is not remembered', () {
      expect(rememberSearch(['Taxi'], '  '), ['Taxi']);
    });

    test('the same words with other accents count once', () {
      expect(rememberSearch(['École'], 'ecole'), ['ecole']);
    });
  });

  group('search by', () {
    final now = DateTime(2026, 11, 17);

    test('the most used of the last 30 days, then the most recent', () {
      final used = [
        ('food', DateTime(2026, 11, 16)),
        ('taxi', DateTime(2026, 11, 15)),
        ('taxi', DateTime(2026, 11, 2)),
        ('rent', DateTime(2026, 11, 1)),
        ('food', DateTime(2026, 10, 30)),
        ('water', DateTime(2026, 11, 10)),
        ('school', DateTime(2026, 9, 1)),
      ];
      expect(mostUsed(used, now: now, take: 3), ['food', 'taxi', 'water']);
    });

    test('nothing recent, nothing suggested', () {
      expect(mostUsed([('school', DateTime(2026, 9, 1))], now: now), isEmpty);
    });
  });

  group('by month', () {
    test('the shown month first, the others newest first', () {
      final dates = [
        DateTime(2026, 11, 11),
        DateTime(2026, 10, 22),
        DateTime(2026, 11, 2),
        DateTime(2026, 9, 19),
        DateTime(2026, 10, 14),
      ];
      final split = splitByMonth(dates, (d) => d, DateTime(2026, 10));
      expect(split.shown, [DateTime(2026, 10, 22), DateTime(2026, 10, 14)]);
      expect(
        [for (final g in split.others) g.month],
        [DateTime(2026, 11), DateTime(2026, 9)],
      );
      expect(split.others.first.items, [
        DateTime(2026, 11, 11),
        DateTime(2026, 11, 2),
      ]);
    });
  });
}
