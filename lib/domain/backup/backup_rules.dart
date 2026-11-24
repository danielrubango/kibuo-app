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
