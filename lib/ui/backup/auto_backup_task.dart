import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/backup/auto_backup.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _channel = MethodChannel('kibuo/auto-backup');

/// Turns the daily check with kibuo closed on or off
/// (docs/backlog/ios.md).
Future<void> scheduleAutoBackup({required bool on}) async {
  try {
    await _channel.invokeMethod<void>('schedule', on);
  } on MissingPluginException {
    // Tests and other platforms: nothing runs in the background.
  }
}

/// The notification of a failed automatic backup: one at a time, replaced
/// by the next and kept when kibuo replaces its reminders.
const autoBackupNoticeId = 7001;

/// Touching it opens the Sauvegarde screen.
const autoBackupPayload = 'backup';

/// Called by Android once a day, kibuo closed (AutoBackupWorker): backs up
/// if a week has passed, and says a failure in a notification.
Future<void> backUpInBackground() async {
  try {
    await _backUp();
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    // Nothing to say without the data: kibuo looks again tomorrow.
  } finally {
    await _channel.invokeMethod<void>('finished');
  }
}

Future<void> _backUp() async {
  const vault = SecureKeyVault();
  // Never creates the data: only kibuo itself does, on its first launch.
  if (await vault.read(BackupService.autoKey) != 'on') return;
  final folder = await getApplicationSupportDirectory();
  if (!File(p.join(folder.path, 'kibuo.db')).existsSync()) return;
  final opened = await openKibuoDatabase(folder: folder, vault: vault);
  if (opened is! Opened) return;
  final db = opened.database;
  try {
    final service = BackupService(
      db: db,
      appFolder: getApplicationSupportDirectory,
    );
    final result = await AutoBackup(
      service: service,
      folders: const DeviceBackupFolders(),
    ).run(now: DateTime.now());
    if (result != AutoBackupOutcome.folderMissing &&
        result != AutoBackupOutcome.failed) {
      return;
    }
    final state = await service.state();
    final code =
        await service.rememberedLanguage() ??
        resolveAppLanguage(PlatformDispatcher.instance.locales).languageCode;
    final l = lookupAppLocalizations(Locale(code));
    final missing = state.folder;
    await _notify(
      l,
      result == AutoBackupOutcome.folderMissing && missing != null
          ? l.backupFolderMissingSub(folderLabel(l, missing))
          : l.autoBackupFailed,
    );
  } finally {
    await db.close();
  }
}

Future<void> _notify(AppLocalizations l, String body) async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher_monochrome'),
    ),
  );
  await plugin.show(
    id: autoBackupNoticeId,
    title: l.autoBackupImpossible,
    body: body,
    payload: autoBackupPayload,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'backups',
        l.autoBackupChannel,
        icon: 'ic_launcher_monochrome',
      ),
    ),
  );
}
