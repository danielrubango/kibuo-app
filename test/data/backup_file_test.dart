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

class _MemoryVault implements KeyVault {
  final values = <String, String>{};

  @override
  Future<String?> read(String name) async => values[name];

  @override
  Future<void> write(String name, String value) async => values[name] = value;

  @override
  Future<void> delete(String name) async => values.remove(name);

  @override
  Future<void> deleteAll() async => values.clear();
}

void main() {
  late Directory folder;
  late Directory scratch;
  late KibuoDatabase db;
  final createdAt = DateTime(2026, 11, 24, 21, 4);
  final photo = Uint8List.fromList(List.generate(3000, (i) => i % 251));

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('kibuo_app_');
    scratch = Directory.systemTemp.createTempSync('kibuo_backup_');
    db = ((await openKibuoDatabase(
      folder: folder,
      vault: _MemoryVault(),
      inBackground: false,
    )) as Opened).database;
    await AccountRepository(db).create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(12000, 'USD'),
      openingDate: DateTime.utc(2026, 11, 1),
    );
    // An attachment, already encrypted by kibuo: copied as it is.
    Directory('${folder.path}/attachments').createSync();
    File('${folder.path}/attachments/receipt-1').writeAsBytesSync(photo);
  });

  tearDown(() async {
    await db.close();
    folder.deleteSync(recursive: true);
    scratch.deleteSync(recursive: true);
  });

  Future<File> backUp({String? password}) async {
    final out = File('${scratch.path}/out.kibuo');
    await writeBackup(
      db,
      appFolder: folder,
      out: out,
      createdAt: createdAt,
      password: password,
      rounds: 1000,
    );
    return out;
  }

  Directory into() => Directory('${scratch.path}/opened')..createSync();

  test('a backup brings back the data and the attachments', () async {
    final file = await backUp();

    final envelope = await peekBackup(file);
    expect(envelope.encrypted, isFalse);
    expect(envelope.createdAt, createdAt);

    final target = into();
    final contents = await openBackup(file, into: target);
    expect(contents.manifest.createdAt, createdAt);
    expect(contents.manifest.schemaVersion, db.schemaVersion);
    expect(contents.manifest.accounts, 1);

    // The database inside opens anywhere, without this phone's key.
    final copy = sqlite3.open(contents.database.path);
    expect(copy.select('SELECT name FROM accounts').single['name'], 'M-Pesa');
    expect(
      copy.select('PRAGMA user_version').single['user_version'],
      db.schemaVersion,
    );
    copy.close();

    expect(
      File('${contents.attachments.path}/receipt-1').readAsBytesSync(),
      photo,
    );
  });

  test('the phone’s own database stays encrypted and open', () async {
    await backUp();

    final header = String.fromCharCodes(
      File('${folder.path}/kibuo.db').readAsBytesSync().take(15),
    );
    expect(header, isNot('SQLite format 3'));
    expect(await AccountRepository(db).accounts(), hasLength(1));
    expect(scratch.listSync().map((e) => e.uri.pathSegments.last), [
      'out.kibuo',
    ], reason: 'No copy in clear is left behind.');
  });

  test('with a password, only the date shows before it is typed', () async {
    final file = await backUp(password: 'mot de passe');

    final envelope = await peekBackup(file);
    expect(envelope.encrypted, isTrue);
    expect(envelope.createdAt, createdAt);

    final bytes = file.readAsBytesSync();
    expect(String.fromCharCodes(bytes), isNot(contains('SQLite format 3')));
    expect(String.fromCharCodes(bytes), isNot(contains('M-Pesa')));

    final contents = await openBackup(
      file,
      password: 'mot de passe',
      into: into(),
    );
    expect(contents.manifest.accounts, 1);
    expect(
      File('${contents.attachments.path}/receipt-1').readAsBytesSync(),
      photo,
    );
  });

  test('a wrong or missing password opens nothing', () async {
    final file = await backUp(password: 'mot de passe');

    await expectLater(
      openBackup(file, password: 'mot de passf', into: into()),
      throwsA(isA<BackupWrongPassword>()),
    );
    await expectLater(
      openBackup(file, into: Directory('${scratch.path}/b')..createSync()),
      throwsA(isA<BackupWrongPassword>()),
    );
  });

  test('a damaged or cut file is refused', () async {
    for (final password in [null, 'mot de passe']) {
      final file = await backUp(password: password);
      final bytes = file.readAsBytesSync();

      final flipped = Uint8List.fromList(bytes);
      flipped[flipped.length - 100] ^= 0x01;
      final damaged = File('${scratch.path}/damaged.kibuo')
        ..writeAsBytesSync(flipped);
      await expectLater(
        openBackup(
          damaged,
          password: password,
          into: Directory('${scratch.path}/d$password')..createSync(),
        ),
        throwsA(isA<BackupDamaged>()),
      );

      final cut = File('${scratch.path}/cut.kibuo')
        ..writeAsBytesSync(bytes.sublist(0, bytes.length - 40));
      await expectLater(
        openBackup(
          cut,
          password: password,
          into: Directory('${scratch.path}/c$password')..createSync(),
        ),
        throwsA(isA<BackupDamaged>()),
      );
    }
  });

  test('another file is not taken for a backup', () async {
    final other = File('${scratch.path}/photo.jpg')..writeAsBytesSync(photo);
    await expectLater(peekBackup(other), throwsA(isA<BackupNotKibuo>()));
  });
}
