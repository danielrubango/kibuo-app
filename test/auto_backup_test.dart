import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/ui/backup/auto_backup.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';

import 'support/memory_vault.dart';

/// The real service on a vault in memory; the file itself is a stand-in.
class _Service extends BackupService {
  _Service(KibuoDatabase db, MemoryVault vault)
    : super(db: db, appFolder: () async => Directory.systemTemp, vault: vault);

  String? language;
  String? password;
  int writes = 0;
  bool breaks = false;

  @override
  Future<File> write({
    required DateTime now,
    String? password,
    String? language,
  }) async {
    if (breaks) throw StateError('disk full');
    writes++;
    this.language = language;
    this.password = password;
    final work = await Directory.systemTemp.createTemp('kibuo-test-');
    return File('${work.path}/x.kibuo')..writeAsStringSync('backup');
  }
}

/// A folder in memory: the names in it.
class _Folders implements BackupFolders {
  _Folders(this.names);

  final List<String> names;
  bool reach = true;
  bool ok = true;
  String? picked;

  @override
  Future<BackupFolder?> pick() async => picked == null
      ? null
      : BackupFolder(uri: 'content://tree/$picked', name: picked!);

  @override
  Future<bool> reachable(BackupFolder folder) async => reach;

  @override
  Future<bool> write(BackupFolder folder, String name, File file) async {
    if (!ok) return false;
    names
      ..remove(name)
      ..add(name);
    return true;
  }

  @override
  Future<List<String>> list(BackupFolder folder) async => [...names];

  @override
  Future<void> delete(BackupFolder folder, String name) async =>
      names.remove(name);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late MemoryVault vault;
  late _Service service;
  late _Folders folders;
  late AutoBackup auto;
  const folder = BackupFolder(uri: 'content://tree/dl', name: 'Download/Kibuo');
  // At midnight, where day counts go wrong first.
  final now = DateTime(2026, 11, 24);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    vault = MemoryVault();
    service = _Service(db, vault);
    folders = _Folders([]);
    auto = AutoBackup(service: service, folders: folders);
    await service.setFolder(folder);
  });
  tearDown(() => db.close());

  test('off by default: nothing happens', () async {
    expect((await service.state()).auto, isFalse);
    expect(await auto.run(now: now), AutoBackupOutcome.off);
    expect(service.writes, 0);
  });

  test('on, without any backup: one is made, named for the day', () async {
    await service.setAuto(on: true);
    expect(await auto.run(now: now, language: 'fr'), AutoBackupOutcome.done);
    expect(folders.names, ['kibuo-auto-2026-11-24.kibuo']);
    expect(service.language, 'fr');
    expect((await service.state()).last, now);
  });

  test('not again before 7 days, manual backups included', () async {
    await service.setAuto(on: true);
    await service.done(DateTime(2026, 11, 18, 21));
    expect(await auto.run(now: now), AutoBackupOutcome.notDue);
    await service.done(DateTime(2026, 11, 17, 21));
    expect(await auto.run(now: now), AutoBackupOutcome.done);
  });

  test('keeps the 4 newest automatic backups, nothing else', () async {
    folders.names.addAll([
      'kibuo-auto-2026-11-17.kibuo',
      'kibuo-auto-2026-11-10.kibuo',
      'kibuo-auto-2026-11-03.kibuo',
      'kibuo-auto-2026-10-27.kibuo',
      'kibuo-2026-01-01-0900.kibuo',
      'kibuo-avant-restauration-2026-01-01-0900.kibuo',
    ]);
    await service.setAuto(on: true);
    await service.done(DateTime(2026, 11, 17));
    expect(await auto.run(now: now), AutoBackupOutcome.done);
    expect(folders.names, [
      'kibuo-auto-2026-11-17.kibuo',
      'kibuo-auto-2026-11-10.kibuo',
      'kibuo-auto-2026-11-03.kibuo',
      'kibuo-2026-01-01-0900.kibuo',
      'kibuo-avant-restauration-2026-01-01-0900.kibuo',
      'kibuo-auto-2026-11-24.kibuo',
    ]);
  });

  test('a failed backup deletes nothing', () async {
    folders.names.addAll([
      'kibuo-auto-2026-11-17.kibuo',
      'kibuo-auto-2026-11-10.kibuo',
      'kibuo-auto-2026-11-03.kibuo',
      'kibuo-auto-2026-10-27.kibuo',
      'kibuo-auto-2026-10-20.kibuo',
    ]);
    folders.ok = false;
    await service.setAuto(on: true);
    await service.done(DateTime(2026, 11, 17));
    expect(await auto.run(now: now), AutoBackupOutcome.failed);
    expect(folders.names, hasLength(5));
  });

  test('a folder out of reach is said, and tried again a week later', () async {
    await service.setAuto(on: true);
    folders.reach = false;
    expect(await auto.run(now: now), AutoBackupOutcome.folderMissing);
    expect(service.writes, 0);
    expect((await service.state()).last, isNull);

    // Every opening of the week after: silent.
    folders.reach = true;
    expect(
      await auto.run(now: DateTime(2026, 11, 30, 23)),
      AutoBackupOutcome.notDue,
    );
    expect(await auto.run(now: DateTime(2026, 12, 1)), AutoBackupOutcome.done);
  });

  test('no folder at all counts as a folder out of reach', () async {
    await vault.deleteAll();
    await service.setAuto(on: true);
    expect(await auto.run(now: now), AutoBackupOutcome.folderMissing);
  });

  test('any other failure is said once too', () async {
    await service.setAuto(on: true);
    service.breaks = true;
    expect(await auto.run(now: now), AutoBackupOutcome.failed);
    service.breaks = false;
    expect(
      await auto.run(now: DateTime(2026, 11, 25)),
      AutoBackupOutcome.notDue,
    );
  });

  test('a new folder tries again at once, despite a recent failure', () async {
    await service.setAuto(on: true);
    folders.reach = false;
    expect(await auto.run(now: now), AutoBackupOutcome.folderMissing);
    folders.reach = true;
    await auto.folderChosen(
      const BackupFolder(uri: 'content://tree/doc', name: 'Documents/Kibuo'),
    );
    expect((await service.state()).folder?.name, 'Documents/Kibuo');
    expect(await auto.run(now: DateTime(2026, 11, 25)), AutoBackupOutcome.done);
  });

  test('a second one the same day replaces the first', () async {
    // Already there: written, but its date was never kept.
    folders.names.add('kibuo-auto-2026-11-24.kibuo');
    await service.setAuto(on: true);
    expect(
      await auto.run(now: DateTime(2026, 11, 24, 18)),
      AutoBackupOutcome.done,
    );
    expect(folders.names, ['kibuo-auto-2026-11-24.kibuo']);
  });

  test('turning it off forgets a failure', () async {
    await service.setAuto(on: true);
    folders.reach = false;
    await auto.run(now: now);
    await service.setAuto(on: false);
    await service.setAuto(on: true);
    folders.reach = true;
    expect(await auto.run(now: DateTime(2026, 11, 25)), AutoBackupOutcome.done);
  });

  test('the language is remembered for backups made kibuo closed', () async {
    await service.setAuto(on: true);
    await service.rememberLanguage('en');
    expect(await auto.run(now: now), AutoBackupOutcome.done);
    expect(service.language, 'en');
  });

  test('encrypted with the remembered password, if there is one', () async {
    await service.setAuto(on: true);
    expect(await auto.run(now: now), AutoBackupOutcome.done);
    expect(service.password, isNull);
    await service.rememberPassword('secret-123');
    expect(await auto.run(now: DateTime(2026, 12, 1)), AutoBackupOutcome.done);
    expect(service.password, 'secret-123');
  });
}
