/// Rules of the manual backup (PRODUCT, « Sauvegarde manuelle »).
library;

import 'package:kibuo/domain/calendar.dart';

/// Beyond this many days, a backup is old: Plus turns amber and « À traiter »
/// shows « Sauvegarde ancienne ».
const backupOldAfterDays = 7;

/// The shortest password that encrypts a backup.
const backupPasswordMinLength = 8;

/// « kibuo-2026-11-24-2104.kibuo »: they sort by date in a folder.
String backupFileName(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'kibuo-${at.year}-${two(at.month)}-${two(at.day)}-'
      '${two(at.hour)}${two(at.minute)}.kibuo';
}

/// Whole days on the calendar from [from] to [to], whatever the hours.
int backupAgeDays(DateTime from, DateTime to) => calendarDays(from, to);

/// Whether the reminder to back up shows: the last backup is more than
/// [backupOldAfterDays] old or, without any, the first operation is.
bool backupIsOld({
  required DateTime? last,
  DateTime? firstOperation,
  required DateTime now,
}) {
  final since = last ?? firstOperation;
  if (since == null) return false;
  return backupAgeDays(since, now) > backupOldAfterDays;
}

/// Whether « Sauvegarder » can go with these two typed passwords.
bool backupPasswordReady(String password, String again) =>
    password.runes.length >= backupPasswordMinLength && password == again;

/// The copy made just before a restore (PRODUCT: Restauration):
/// « kibuo-avant-restauration-2026-11-24-1723.kibuo ».
String restoreCopyName(DateTime at) =>
    backupFileName(at).replaceFirst('kibuo-', 'kibuo-avant-restauration-');

/// How many automatic backups kibuo keeps (PRODUCT: about a month).
const autoBackupsKept = 4;

/// Days between two automatic backups, and between two tries after a
/// failure (PRODUCT: Sauvegardes automatiques).
const autoBackupEveryDays = 7;

/// « kibuo-auto-2026-11-24.kibuo »: one a day at most; a second one the
/// same day replaces the first.
String autoBackupFileName(DateTime at) {
  String two(int n) => n.toString().padLeft(2, '0');
  return 'kibuo-auto-${at.year}-${two(at.month)}-${two(at.day)}.kibuo';
}

final _autoName = RegExp(r'^kibuo-auto-\d{4}-\d{2}-\d{2}\.kibuo$');

/// Whether an automatic backup should run now: the last backup, manual or
/// automatic, is [autoBackupEveryDays] days old or more on the calendar,
/// and a failure since then is as old (one try, and one signal, a week).
bool autoBackupDue({
  required DateTime? last,
  required DateTime? failedAt,
  required DateTime now,
}) {
  DateTime? since = last;
  if (failedAt != null && (since == null || failedAt.isAfter(since))) {
    since = failedAt;
  }
  if (since == null) return true;
  return backupAgeDays(since, now) >= autoBackupEveryDays;
}

/// Among a folder's [names], the automatic backups beyond the
/// [autoBackupsKept] newest. Nothing else is ever deleted.
List<String> autoBackupsToDelete(Iterable<String> names) {
  final autos = names.where(_autoName.hasMatch).toList()
    ..sort((a, b) => b.compareTo(a));
  return autos.skip(autoBackupsKept).toList();
}
