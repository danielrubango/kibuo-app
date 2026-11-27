import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/overview/overview_period.dart';
import 'package:kibuo/domain/overview/worth.dart';

/// The Patrimoine tab's figures (PRODUCT, 27 November 2026): what the
/// worth was at each moment, what the planned operations would make of it,
/// and what each account did over the period.
void main() {
  final november = TimeSpan.days(DateTime(2026, 11, 1), DateTime(2026, 11, 30));
  final now = DateTime(2026, 11, 12, 15);

  test('the worth back in time: today less what came after', () {
    // 1 000 $ today: +300 $ on the 5th, −50 $ on the 10th.
    final changes = [
      (at: DateTime(2026, 11, 5, 9), change: 30000),
      (at: DateTime(2026, 11, 10, 18), change: -5000),
    ];
    final values = worthAt(
      [DateTime(2026, 11, 1), DateTime(2026, 11, 6), DateTime(2026, 11, 11)],
      current: 100000,
      changes: changes,
    );
    expect(values, [75000, 105000, 100000]);
  });

  test('the change over the period: from its start to now', () {
    final changes = [(at: DateTime(2026, 11, 5), change: 30000)];
    expect(
      worthChange(november, current: 100000, changes: changes, now: now),
      30000,
    );
  });

  test('a past period ends at its end, not today', () {
    final october = TimeSpan.days(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 31),
    );
    final changes = [
      (at: DateTime(2026, 10, 20), change: 10000),
      (at: DateTime(2026, 11, 5), change: 30000),
    ];
    expect(
      worthChange(october, current: 100000, changes: changes, now: now),
      10000,
    );
  });

  test('ahead, the planned operations add up from today', () {
    final planned = [
      (at: DateTime(2026, 11, 15), change: -28000),
      (at: DateTime(2026, 11, 25), change: 120000),
      // Already behind us: not counted again.
      (at: DateTime(2026, 11, 2), change: 999),
    ];
    final values = projectedAt(
      [DateTime(2026, 11, 20), DateTime(2026, 12, 1)],
      from: 100000,
      now: now,
      planned: planned,
    );
    expect(values, [72000, 192000]);
  });

  test('each account: what it gained or lost over the period', () {
    final moves = [
      (account: 'bank', at: DateTime(2026, 11, 3), change: 38000),
      (account: 'bank', at: DateTime(2026, 10, 30), change: 999),
      (account: 'mpesa', at: DateTime(2026, 11, 8), change: 4210),
      (account: 'cash', at: DateTime(2026, 11, 9), change: -1800),
      (account: 'cash', at: DateTime(2026, 11, 10), change: 1800),
    ];
    final changes = accountChanges(november, moves);
    expect(changes, {'bank': 38000, 'mpesa': 4210, 'cash': 0});
  });

  test("an account's page: what came in and went out over the period", () {
    // A transfer counts for the account it leaves and the one it reaches.
    final moves = [
      (at: DateTime(2026, 11, 7, 17), change: -19040),
      (at: DateTime(2026, 11, 10, 18), change: -5000),
      (at: DateTime(2026, 11, 12, 9), change: 30000),
      (at: DateTime(2026, 11, 20), change: 1200),
      // October: outside.
      (at: DateTime(2026, 10, 31, 23), change: 999),
    ];
    final flows = flowsWithin(november, moves);
    expect(flows.entries, 31200);
    expect(flows.exits, 24040);
  });
}
