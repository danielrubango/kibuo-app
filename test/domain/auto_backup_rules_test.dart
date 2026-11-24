import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';

void main() {
  // At midnight, where day counts go wrong first.
  final today = DateTime(2026, 11, 24);

  test('an automatic backup is named after its day only', () {
    expect(
      autoBackupFileName(DateTime(2026, 11, 24, 21, 4)),
      'kibuo-auto-2026-11-24.kibuo',
    );
    expect(
      autoBackupFileName(DateTime(2027, 1, 5, 7, 9)),
      'kibuo-auto-2027-01-05.kibuo',
    );
  });

  group('an automatic backup is due', () {
    test('when there was never any backup', () {
      expect(autoBackupDue(last: null, failedAt: null, now: today), isTrue);
    });

    test('once the last one is 7 days old or more', () {
      expect(
        autoBackupDue(
          last: DateTime(2026, 11, 18, 23, 59),
          failedAt: null,
          now: today,
        ),
        isFalse,
      );
      expect(
        autoBackupDue(
          last: DateTime(2026, 11, 17, 21),
          failedAt: null,
          now: today,
        ),
        isTrue,
      );
    });

    test('counts days on the calendar, not hours', () {
      // 6 days and 1 minute, but 7 days on the calendar.
      expect(
        autoBackupDue(
          last: DateTime(2026, 11, 17, 23, 59),
          failedAt: null,
          now: DateTime(2026, 11, 24, 0, 0),
        ),
        isTrue,
      );
    });

    test('a failure waits a week before trying again', () {
      final last = DateTime(2026, 11, 1);
      expect(
        autoBackupDue(last: last, failedAt: DateTime(2026, 11, 20), now: today),
        isFalse,
      );
      expect(
        autoBackupDue(last: last, failedAt: DateTime(2026, 11, 17), now: today),
        isTrue,
      );
      // Never any backup, and a failure yesterday.
      expect(
        autoBackupDue(last: null, failedAt: DateTime(2026, 11, 23), now: today),
        isFalse,
      );
    });

    test('a failure older than the last backup does not count', () {
      expect(
        autoBackupDue(
          last: DateTime(2026, 11, 10),
          failedAt: DateTime(2026, 11, 3),
          now: today,
        ),
        isTrue,
      );
    });
  });

  group('the automatic backups to delete', () {
    test('only the oldest beyond the 4 newest', () {
      expect(
        autoBackupsToDelete([
          'kibuo-auto-2026-11-24.kibuo',
          'kibuo-auto-2026-10-27.kibuo',
          'kibuo-auto-2026-11-17.kibuo',
          'kibuo-auto-2026-11-03.kibuo',
          'kibuo-auto-2026-11-10.kibuo',
          'kibuo-auto-2026-10-20.kibuo',
        ]),
        ['kibuo-auto-2026-10-27.kibuo', 'kibuo-auto-2026-10-20.kibuo'],
      );
    });

    test('never a manual backup, a copy before a restore or another file', () {
      expect(
        autoBackupsToDelete([
          'kibuo-auto-2026-11-24.kibuo',
          'kibuo-auto-2026-11-17.kibuo',
          'kibuo-auto-2026-11-10.kibuo',
          'kibuo-auto-2026-11-03.kibuo',
          'kibuo-2025-01-01-0900.kibuo',
          'kibuo-avant-restauration-2025-01-01-0900.kibuo',
          'kibuo-auto-2025-01-01.kibuo.txt',
          'kibuo-auto-notes.kibuo',
          'photo.jpg',
        ]),
        isEmpty,
      );
    });

    test('nothing while there are 4 or fewer', () {
      expect(
        autoBackupsToDelete([
          'kibuo-auto-2026-11-24.kibuo',
          'kibuo-auto-2026-11-17.kibuo',
        ]),
        isEmpty,
      );
    });
  });
}
