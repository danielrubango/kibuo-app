import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';

void main() {
  // At midnight, where day counts go wrong first.
  final today = DateTime(2026, 11, 24);

  test('the file is named after its date and minute', () {
    expect(
      backupFileName(DateTime(2026, 11, 24, 21, 4)),
      'kibuo-2026-11-24-2104.kibuo',
    );
    expect(
      backupFileName(DateTime(2027, 1, 5, 7, 9)),
      'kibuo-2027-01-05-0709.kibuo',
    );
  });

  group('a backup is old', () {
    test('beyond 7 days', () {
      expect(
        backupIsOld(last: DateTime(2026, 11, 17, 23, 59), now: today),
        isFalse,
      );
      expect(backupIsOld(last: DateTime(2026, 11, 16, 20), now: today), isTrue);
    });

    test('counts days on the calendar, not hours', () {
      expect(
        backupIsOld(
          last: DateTime(2026, 11, 17, 0, 1),
          now: DateTime(2026, 11, 24, 23, 59),
        ),
        isFalse,
      );
      expect(
        backupIsOld(
          last: DateTime(2026, 11, 16, 23, 59),
          now: DateTime(2026, 11, 24, 0, 1),
        ),
        isTrue,
      );
    });

    test('without any backup, 7 days after the first operation', () {
      expect(backupIsOld(last: null, now: today), isFalse);
      expect(
        backupIsOld(
          last: null,
          firstOperation: DateTime(2026, 11, 17),
          now: today,
        ),
        isFalse,
      );
      expect(
        backupIsOld(
          last: null,
          firstOperation: DateTime(2026, 11, 16),
          now: today,
        ),
        isTrue,
      );
    });
  });

  test('the age is in calendar days', () {
    expect(backupAgeDays(DateTime(2026, 11, 24, 0, 1), today), 0);
    expect(backupAgeDays(DateTime(2026, 11, 23, 23, 59), today), 1);
    expect(backupAgeDays(DateTime(2026, 11, 12, 9), today), 12);
    // Across the change to winter time.
    expect(backupAgeDays(DateTime(2026, 10, 20), DateTime(2026, 11, 2)), 13);
  });

  group('the password', () {
    test('needs 8 characters, typed twice the same', () {
      expect(backupPasswordReady('', ''), isFalse);
      expect(backupPasswordReady('1234567', '1234567'), isFalse);
      expect(backupPasswordReady('12345678', '12345679'), isFalse);
      expect(backupPasswordReady('12345678', '12345678'), isTrue);
      expect(backupPasswordReady('mot de passe', 'mot de passe'), isTrue);
    });
  });
}
