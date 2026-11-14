import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/domain/lock/lock_rules.dart';

void main() {
  group('waiting after wrong codes', () {
    test('no wait for the first four wrong codes', () {
      for (var failures = 0; failures < 5; failures++) {
        expect(waitAfter(failures), Duration.zero, reason: '$failures');
      }
    });

    test('30 s at the fifth, then longer at each new failure', () {
      expect(waitAfter(5), const Duration(seconds: 30));
      expect(waitAfter(6), const Duration(minutes: 1));
      expect(waitAfter(7), const Duration(minutes: 5));
      expect(waitAfter(8), const Duration(minutes: 15));
      expect(waitAfter(9), const Duration(minutes: 30));
      expect(waitAfter(10), const Duration(hours: 1));
    });

    test('never longer than an hour, and nothing is ever erased', () {
      expect(waitAfter(50), const Duration(hours: 1));
    });
  });

  group('locking again after an absence', () {
    final left = DateTime(2026, 11, 15, 10);

    test('« immédiatement » locks on any return', () {
      expect(
        shouldLockOnReturn(
          left: left,
          now: left,
          delay: AutoLockDelay.immediately,
        ),
        isTrue,
      );
    });

    test('« 1 minute » locks after a minute away, not before', () {
      const delay = AutoLockDelay.oneMinute;
      expect(
        shouldLockOnReturn(
          left: left,
          now: left.add(const Duration(seconds: 59)),
          delay: delay,
        ),
        isFalse,
      );
      expect(
        shouldLockOnReturn(
          left: left,
          now: left.add(const Duration(minutes: 1)),
          delay: delay,
        ),
        isTrue,
      );
    });

    test('« 5 minutes » locks after five minutes away', () {
      expect(
        shouldLockOnReturn(
          left: left,
          now: left.add(const Duration(minutes: 5)),
          delay: AutoLockDelay.fiveMinutes,
        ),
        isTrue,
      );
    });

    test('a phone clock moved back locks, to be safe', () {
      expect(
        shouldLockOnReturn(
          left: left,
          now: left.subtract(const Duration(hours: 1)),
          delay: AutoLockDelay.fiveMinutes,
        ),
        isTrue,
      );
    });

    test('five delays are offered, from right away to 15 minutes', () {
      expect(AutoLockDelay.values.map((d) => d.duration), const [
        Duration.zero,
        Duration(seconds: 30),
        Duration(minutes: 1),
        Duration(minutes: 5),
        Duration(minutes: 15),
      ]);
    });

    test('« 15 minutes » keeps Kibuo open for a quarter of an hour', () {
      const delay = AutoLockDelay.fifteenMinutes;
      expect(
        shouldLockOnReturn(
          left: left,
          now: left.add(const Duration(minutes: 14)),
          delay: delay,
        ),
        isFalse,
      );
      expect(
        shouldLockOnReturn(
          left: left,
          now: left.add(const Duration(minutes: 15)),
          delay: delay,
        ),
        isTrue,
      );
    });

    test('the delay is « 1 minute » until the user changes it', () {
      expect(AutoLockDelay.standard, AutoLockDelay.oneMinute);
    });
  });

  group('a valid code', () {
    test('has 4 to 6 digits', () {
      expect(isValidPin('123'), isFalse);
      expect(isValidPin('1234'), isTrue);
      expect(isValidPin('123456'), isTrue);
      expect(isValidPin('1234567'), isFalse);
      expect(isValidPin('12a4'), isFalse);
    });
  });
}
