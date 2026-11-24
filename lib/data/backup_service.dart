import 'dart:io';

import 'package:kibuo/data/backup_file.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';
import 'package:path/path.dart' as p;

/// The folder chosen for backups: Android's address for it, and its name
/// as the phone shows it (« Download/Kibuo »).
class BackupFolder {
  const BackupFolder({required this.uri, required this.name});

  final String uri;
  final String name;
}

/// Where backups stand on this phone.
class BackupState {
  const BackupState({
    this.folder,
    this.last,
    this.firstOperation,
    this.auto = false,
    this.autoFailedAt,
  });

  final BackupFolder? folder;
  final DateTime? last;
  final DateTime? firstOperation;

  /// « Sauvegarde automatique », off until the user turns it on.
  final bool auto;

  /// When the last automatic backup failed, if none worked since.
  final DateTime? autoFailedAt;

  bool old(DateTime now) =>
      backupIsOld(last: last, firstOperation: firstOperation, now: now);
}

/// The manual backup: its folder and date, kept on this phone only (never
/// in a backup, so a restore does not change them), and the file itself.
class BackupService {
  BackupService({
    required this._db,
    required this._appFolder,
    this._vault = const SecureKeyVault(),
    this.rounds = 300000,
  });

  final KibuoDatabase _db;
  final Future<Directory> Function() _appFolder;
  final KeyVault _vault;

  /// PBKDF2 rounds for the password; fewer in tests.
  final int rounds;

  static const _folderUri = 'backup_folder_uri';
  static const _folderName = 'backup_folder_name';
  static const _last = 'backup_last';

  /// Read with kibuo closed, before the data is opened.
  static const autoKey = 'backup_auto';
  static const _auto = autoKey;
  static const _autoFailed = 'backup_auto_failed';
  static const _language = 'backup_language';

  Future<BackupState> state() async {
    final uri = await _vault.read(_folderUri);
    final name = await _vault.read(_folderName);
    final last = DateTime.tryParse(await _vault.read(_last) ?? '');
    final failed = DateTime.tryParse(await _vault.read(_autoFailed) ?? '');
    final auto = await _vault.read(_auto) == 'on';
    final first = await _db
        .customSelect(
          'SELECT min(date) AS first FROM transactions WHERE deleted = 0',
          readsFrom: {_db.transactions},
        )
        .getSingle();
    final seconds = first.read<int?>('first');
    return BackupState(
      folder: uri == null || name == null
          ? null
          : BackupFolder(uri: uri, name: name),
      last: last,
      auto: auto,
      autoFailedAt: failed,
      firstOperation: seconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
    );
  }

  /// A new folder: the next automatic backup does not wait a week.
  Future<void> setFolder(BackupFolder folder) async {
    await _vault.write(_folderUri, folder.uri);
    await _vault.write(_folderName, folder.name);
    await _vault.delete(_autoFailed);
  }

  /// Writes the backup to a file of the phone's temporary folder, named for
  /// [now], for the folder to copy; the caller deletes it.
  Future<File> write({
    required DateTime now,
    String? password,
    String? language,
  }) async {
    final work = await Directory.systemTemp.createTemp('kibuo-out-');
    final out = File(p.join(work.path, backupFileName(now)));
    await writeBackup(
      _db,
      appFolder: await _appFolder(),
      out: out,
      createdAt: now,
      password: password,
      language: language,
      rounds: rounds,
    );
    return out;
  }

  /// The backup reached its folder: a failure before it is forgotten.
  Future<void> done(DateTime at) async {
    await _vault.write(_last, at.toIso8601String());
    await _vault.delete(_autoFailed);
  }

  /// Turns automatic backups on or off; either way, a past failure is
  /// forgotten.
  Future<void> setAuto({required bool on}) async {
    await _vault.write(_auto, on ? 'on' : 'off');
    await _vault.delete(_autoFailed);
  }

  /// An automatic backup failed at [at]: the next try waits a week.
  Future<void> autoFailed(DateTime at) =>
      _vault.write(_autoFailed, at.toIso8601String());

  /// kibuo's language, for backups made while it is closed (Android 13 and
  /// more keep it outside the data).
  Future<void> rememberLanguage(String code) => _vault.write(_language, code);

  Future<String?> rememberedLanguage() => _vault.read(_language);
}
