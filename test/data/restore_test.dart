import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/backup_file.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:sqlite3/sqlite3.dart';

import '../support/memory_vault.dart';

void main() {
  late Directory folder;
  late Directory scratch;
  late MemoryVault vault;
  late KibuoDatabase db;
  final photo = Uint8List.fromList(List.generate(2000, (i) => i % 251));

  Future<KibuoDatabase> open() async => ((await openKibuoDatabase(
    folder: folder,
    vault: vault,
    inBackground: false,
  )) as Opened).database;

  Future<void> account(KibuoDatabase db, String name) =>
      AccountRepository(db).create(
        name: name,
        type: AccountType.mobile,
        opening: const Money(1000, 'USD'),
        openingDate: DateTime.utc(2026, 11, 1),
      );

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('kibuo_app_');
    scratch = Directory.systemTemp.createTempSync('kibuo_restore_');
    vault = MemoryVault();
    db = await open();
    await account(db, 'M-Pesa');
    Directory('${folder.path}/attachments').createSync();
    File('${folder.path}/attachments/receipt-1').writeAsBytesSync(photo);
  });

  tearDown(() async {
    await db.close();
    folder.deleteSync(recursive: true);
    scratch.deleteSync(recursive: true);
  });

  Future<BackupContents> backupNow() async {
    final out = File('${scratch.path}/out.kibuo');
    await writeBackup(
      db,
      appFolder: folder,
      out: out,
      createdAt: DateTime(2026, 11, 3, 21, 4),
      rounds: 1000,
    );
    return openBackup(
      out,
      into: Directory('${scratch.path}/opened')..createSync(),
    );
  }

  test('the backup replaces everything, under this phone\'s key', () async {
    final contents = await backupNow();
    // After the backup: another account, another attachment.
    await account(db, 'Rawbank');
    File('${folder.path}/attachments/receipt-2').writeAsBytesSync(photo);
    await db.close();

    final result = await replaceWithBackup(
      folder: folder,
      contents: contents,
      vault: vault,
      inBackground: false,
    );
    db = (result as Opened).database;
    final names = [
      for (final a in await AccountRepository(db).accounts()) a.name,
    ];
    expect(names, ['M-Pesa']);
    expect(
      Directory('${folder.path}/attachments')
          .listSync()
          .map((f) => f.uri.pathSegments.last),
      ['receipt-1'],
    );
    // Still encrypted with the phone's key: no plain SQLite header.
    final head = File('${folder.path}/kibuo.db')
        .readAsBytesSync()
        .sublist(0, 15);
    expect(String.fromCharCodes(head), isNot('SQLite format 3'));
    expect(await vault.read(KeyVault.databaseKey), isNotNull);
  });

  test('a backup from a newer kibuo is refused, nothing touched', () async {
    final contents = await backupNow();
    final raw = sqlite3.open(contents.database.path);
    raw.execute('PRAGMA user_version = 999');
    raw.close();
    await account(db, 'Rawbank');
    await db.close();

    expect(
      () => replaceWithBackup(
        folder: folder,
        contents: contents,
        vault: vault,
        inBackground: false,
      ),
      throwsA(isA<BackupTooNew>()),
    );
    db = await open();
    expect((await AccountRepository(db).accounts()).length, 2);
  });
}
