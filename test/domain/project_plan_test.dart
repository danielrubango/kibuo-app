import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/projects/project_plan.dart';

void main() {
  final today = DateTime(2026, 11, 24);

  test('periods left, at least one', () {
    final due = DateTime(2026, 12, 20); // 26 days
    expect(periodsLeft(PlanPeriod.week, today, due), 4);
    expect(periodsLeft(PlanPeriod.fortnight, today, due), 2);
    expect(periodsLeft(PlanPeriod.month, today, due), 1);
    expect(periodsLeft(PlanPeriod.week, today, today), 1);
    expect(periodsLeft(PlanPeriod.week, today, DateTime(2026, 11, 1)), 1);
  });

  test('what is left, in equal parts, rounded up', () {
    final due = DateTime(2026, 12, 20);
    expect(
      perPeriod(
        goal: 30000,
        saved: 18000,
        today: today,
        due: due,
        period: PlanPeriod.week,
      ),
      3000,
    );
    expect(
      perPeriod(
        goal: 30000,
        saved: 30500,
        today: today,
        due: due,
        period: PlanPeriod.week,
      ),
      0,
    );
  });

  test('where it should be today, and how far ahead or behind', () {
    final start = DateTime(2026, 11, 1);
    final due = DateTime(2026, 12, 1); // 30 days; 23 gone
    final share = expectedShare(today: today, start: start, due: due);
    expect(share, closeTo(23 / 30, 1e-9));
    // 30 000 goal: 23 000 expected.
    expect(projectGap(goal: 30000, saved: 20000, share: share), -3000);
    expect(projectGap(goal: 30000, saved: 25000, share: share), 2000);
    // Before it starts, nothing expected; after its date, everything.
    expect(expectedShare(today: start, start: start, due: due), 0);
    expect(expectedShare(today: DateTime(2027), start: start, due: due), 1);
  });

  test('parts rounded up to the unit, the last takes the rest', () {
    // 150 $ in 7 weeks: 22 $ six times, then 18 $ (canvas FicheProjet).
    final parts = planParts(
      goal: 30000,
      saved: 15000,
      today: DateTime(2026, 11, 11),
      due: DateTime(2027, 1, 1),
      period: PlanPeriod.week,
      unit: 100,
    );
    expect(parts.map((p) => p.amount), [
      2200,
      2200,
      2200,
      2200,
      2200,
      2200,
      1800,
    ]);
    expect(parts.first.start, DateTime(2026, 11, 11));
    expect(parts.first.end, DateTime(2026, 11, 17));
    expect(parts[1].start, DateTime(2026, 11, 18));
    expect(parts.last.end, DateTime(2026, 12, 31));
  });

  test('the per period amount follows the same rounding', () {
    expect(
      perPeriod(
        goal: 30000,
        saved: 15000,
        today: DateTime(2026, 11, 11),
        due: DateTime(2027, 1, 1),
        period: PlanPeriod.week,
        unit: 100,
      ),
      2200,
    );
  });

  test('no plan once reached, one part when the date is past', () {
    expect(
      planParts(
        goal: 30000,
        saved: 30000,
        today: today,
        due: DateTime(2026, 12, 20),
        period: PlanPeriod.week,
      ),
      isEmpty,
    );
    final late = planParts(
      goal: 30000,
      saved: 10000,
      today: today,
      due: DateTime(2026, 11, 1),
      period: PlanPeriod.month,
      unit: 100,
    );
    expect(late.single.amount, 20000);
  });

  test('a small rest never leaves a part below zero', () {
    final parts = planParts(
      goal: 1000,
      saved: 0,
      today: today,
      due: today.add(const Duration(days: 48)),
      period: PlanPeriod.week,
      unit: 300,
    );
    expect(parts.fold<int>(0, (s, p) => s + p.amount), 1000);
    expect(parts.every((p) => p.amount >= 0), isTrue);
  });
}
