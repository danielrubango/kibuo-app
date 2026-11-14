import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/domain/sync/hybrid_clock.dart';

void main() {
  test('a version carries the time it was made', () {
    final clock = HybridClock(last: 0, now: () => 1_700_000_000_000);

    final version = clock.next();

    expect(
      HybridClock.timeOf(version),
      DateTime.fromMillisecondsSinceEpoch(1_700_000_000_000, isUtc: true),
    );
  });

  test('versions made in the same millisecond still increase', () {
    final clock = HybridClock(last: 0, now: () => 1_700_000_000_000);

    final first = clock.next();
    final second = clock.next();

    expect(second, greaterThan(first));
  });

  test('versions keep increasing when the phone clock goes back', () {
    var now = 1_700_000_000_000;
    final clock = HybridClock(last: 0, now: () => now);
    final before = clock.next();

    now -= const Duration(hours: 3).inMilliseconds;
    final after = clock.next();

    expect(after, greaterThan(before));
  });

  test('a clock restarted from the last version never goes back', () {
    final first = HybridClock(last: 0, now: () => 1_700_000_000_000);
    final last = first.next();

    final restarted = HybridClock(last: last, now: () => 1_600_000_000_000);

    expect(restarted.next(), greaterThan(last));
  });
}
