import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';

/// What an automatic backup came to.
enum AutoBackupOutcome {
  /// The user has not turned them on.
  off,

  /// The last backup, or the last failure, is less than a week old.
  notDue,

  done,

  /// No folder, or the folder is out of reach: said once, tried again a
  /// week later.
  folderMissing,

  /// Anything else that stopped it: said once too.
  failed,
}

/// The weekly automatic backup (PRODUCT: Sauvegardes automatiques), at
/// kibuo's opening or in the background, kibuo closed.
class AutoBackup {
  AutoBackup({required this.service, required this.folders});

  final BackupService service;
  final BackupFolders folders;

  /// Makes the backup if one is due. [language] is kibuo's, when kibuo is
  /// open; closed, the last one it remembered.
  Future<AutoBackupOutcome> run({
    required DateTime now,
    String? language,
  }) async {
    final state = await service.state();
    if (!state.auto) return AutoBackupOutcome.off;
    if (!autoBackupDue(
      last: state.last,
      failedAt: state.autoFailedAt,
      now: now,
    )) {
      return AutoBackupOutcome.notDue;
    }
    final folder = state.folder;
    if (folder == null || !await _reachable(folder)) {
      await service.autoFailed(now);
      return AutoBackupOutcome.folderMissing;
    }
    try {
      final file = await service.write(
        now: now,
        language: language ?? await service.rememberedLanguage(),
      );
      final bool ok;
      try {
        ok = await folders.write(folder, autoBackupFileName(now), file);
      } finally {
        // The temporary copy never stays, written or not.
        if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
      }
      if (!ok) throw StateError('not written');
      await service.done(now);
    } on Object {
      await service.autoFailed(now);
      return AutoBackupOutcome.failed;
    }
    // Only once the new one is there; a failure here waits for next week.
    try {
      for (final name in autoBackupsToDelete(await folders.list(folder))) {
        await folders.delete(folder, name);
      }
    } on Object {
      // The older ones stay a week longer: nothing is lost.
    }
    return AutoBackupOutcome.done;
  }

  Future<bool> _reachable(BackupFolder folder) async {
    try {
      return await folders.reachable(folder);
    } on Object {
      return false;
    }
  }

  /// A new folder: kept, and the next backup does not wait a week.
  Future<void> folderChosen(BackupFolder folder) => service.setFolder(folder);
}
