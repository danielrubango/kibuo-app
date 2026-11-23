import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/obligations/debt_list.dart';

void main() {
  final today = DateTime(2026, 11, 9);

  DebtLine line(
    String person, {
    DateTime? due,
    int amount = 1000,
    int left = 1000,
    DateTime? settledOn,
    String id = '',
  }) => DebtLine(
    id: id.isEmpty ? person : id,
    direction: DebtDirection.owe,
    person: person,
    amount: Money(amount, 'USD'),
    left: Money(left, 'USD'),
    due: due,
    settledOn: settledOn,
  );

  group('state', () {
    test('by the due day, at midnight', () {
      expect(debtState(line('a', due: DateTime(2026, 11, 2)), today), (
        DebtState.late,
        -7,
      ));
      expect(debtState(line('a', due: DateTime(2026, 11, 9)), today), (
        DebtState.today,
        0,
      ));
      expect(debtState(line('a', due: DateTime(2026, 11, 10)), today), (
        DebtState.soon,
        1,
      ));
      expect(debtState(line('a', due: DateTime(2026, 11, 11)), today), (
        DebtState.soon,
        2,
      ));
      expect(debtState(line('a', due: DateTime(2026, 11, 28)), today), (
        DebtState.normal,
        19,
      ));
      expect(debtState(line('a'), today), (DebtState.none, null));
    });

    test('nothing left: settled, even late', () {
      final paid = line(
        'a',
        due: DateTime(2026, 11, 2),
        left: 0,
        settledOn: DateTime(2026, 11, 3),
      );
      expect(debtState(paid, today), (DebtState.paid, -7));
    });

    test('later today still counts as today', () {
      expect(
        debtState(
          line('a', due: DateTime(2026, 11, 9)),
          DateTime(2026, 11, 9, 23, 30),
        ),
        (DebtState.today, 0),
      );
    });
  });

  group('by due date', () {
    test('late on top, then each month, then « Sans échéance »', () {
      final listing = arrangeDebts([
        line('Marie'),
        line('Patrick', due: DateTime(2026, 12, 5)),
        line('Amani', due: DateTime(2026, 11, 11)),
        line('Oncle Jean', due: DateTime(2026, 11, 2)),
        line('Kevin', due: DateTime(2026, 11, 9)),
        line('Ruth', due: DateTime(2027, 1, 3)),
      ], today: today);
      expect(
        [for (final g in listing.groups) g.key],
        [
          const DebtGroupKey.late(),
          DebtGroupKey.month(2026, 11),
          DebtGroupKey.month(2026, 12),
          DebtGroupKey.month(2027, 1),
          const DebtGroupKey.none(),
        ],
      );
      expect(
        [
          for (final g in listing.groups)
            for (final l in g.lines) l.person,
        ],
        ['Oncle Jean', 'Kevin', 'Amani', 'Patrick', 'Ruth', 'Marie'],
      );
      expect(listing.paid, isEmpty);
    });

    test('settled: in their month by default, below or hidden', () {
      final paid = line(
        'Papa',
        due: DateTime(2026, 11, 3),
        left: 0,
        settledOn: DateTime(2026, 11, 3),
      );
      final kevin = line('Kevin', due: DateTime(2026, 11, 9));
      final inline = arrangeDebts([kevin, paid], today: today);
      expect(inline.groups.single.key, DebtGroupKey.month(2026, 11));
      expect(
        [for (final l in inline.groups.single.lines) l.person],
        ['Papa', 'Kevin'],
      );

      final below = arrangeDebts(
        [kevin, paid],
        today: today,
        paidPlace: PaidPlace.bottom,
      );
      expect(below.groups.single.lines.single.person, 'Kevin');
      expect(below.paid.single.person, 'Papa');

      final hidden = arrangeDebts(
        [kevin, paid],
        today: today,
        paidPlace: PaidPlace.hidden,
      );
      expect(hidden.groups.single.lines.single.person, 'Kevin');
      expect(hidden.paid, isEmpty);
    });

    test('a settled one without a date goes to « Sans échéance »', () {
      final listing = arrangeDebts([
        line('Sarah', left: 0, settledOn: DateTime(2026, 11, 1)),
      ], today: today);
      expect(listing.groups.single.key, const DebtGroupKey.none());
    });
  });

  test('by person: one group each, in alphabetical order', () {
    final listing = arrangeDebts(
      [
        line('patrick', due: DateTime(2026, 12, 5), id: 'p1'),
        line('Amani', due: DateTime(2026, 12, 12), id: 'a1'),
        line('Patrick', due: DateTime(2026, 11, 28), id: 'p2'),
        line('Amani', due: DateTime(2026, 11, 11), id: 'a2'),
        line('Élodie', id: 'e1'),
      ],
      today: today,
      grouping: DebtGrouping.person,
    );
    expect(
      [for (final g in listing.groups) g.key],
      [
        const DebtGroupKey.person('Amani'),
        const DebtGroupKey.person('Élodie'),
        const DebtGroupKey.person('Patrick'),
      ],
    );
    expect([for (final l in listing.groups.last.lines) l.id], ['p2', 'p1']);
    expect([for (final l in listing.groups.first.lines) l.id], ['a2', 'a1']);
  });

  test('how much is paid back, as a share', () {
    expect(line('a', amount: 20000, left: 12000).repaidShare, 0.4);
    expect(line('a', amount: 0, left: 0).repaidShare, 1);
  });
}
