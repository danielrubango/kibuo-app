import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/open_database.dart';

/// A key vault kept in memory, standing in for the phone's secure storage.
class _MemoryVault implements KeyVault {
  final values = <String, String>{};

  @override
  Future<String?> read(String name) async => values[name];

  @override
  Future<void> write(String name, String value) async => values[name] = value;
}

void main() {
  late Directory folder;
  late _MemoryVault vault;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('kibuo_db_');
    vault = _MemoryVault();
  });
  tearDown(() => folder.deleteSync(recursive: true));

  Future<OpenResult> open() =>
      openKibuoDatabase(folder: folder, vault: vault, inBackground: false);

  test('the first start creates the database and this device', () async {
    final result = await open();

    final db = (result as Opened).database;
    final device = await db.thisDevice();
    expect(device.id, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(device.id[14], '7', reason: 'UUID version 7, sortable by date');
    expect(device.version, greaterThan(0));
    expect(device.deleted, isFalse);
    await db.close();
  });

  test('the file on disk cannot be read without the key', () async {
    final db = ((await open()) as Opened).database;
    await db.close();

    final bytes = File('${folder.path}/kibuo.db').readAsBytesSync();
    final header = String.fromCharCodes(bytes.take(15));
    expect(header, isNot('SQLite format 3'));
    expect(String.fromCharCodes(bytes), isNot(contains('devices')));
  });

  test('the next start opens the same data with the stored key', () async {
    final first = ((await open()) as Opened).database;
    final id = (await first.thisDevice()).id;
    await first.close();

    final again = ((await open()) as Opened).database;
    expect((await again.thisDevice()).id, id);
    await again.close();
  });

  test('a lost key leaves the data unreadable, and the file is kept', () async {
    final db = ((await open()) as Opened).database;
    await db.close();
    vault.values.clear();

    final result = await open();

    expect(result, isA<Unreadable>());
    expect(File('${folder.path}/kibuo.db').existsSync(), isTrue);
  });

  test('a wrong key leaves the data unreadable', () async {
    final db = ((await open()) as Opened).database;
    await db.close();
    vault.values[KeyVault.databaseKey] = 'ab' * 32;

    expect(await open(), isA<Unreadable>());
  });

  test('starting over puts the unreadable file aside and opens anew', () async {
    final db = ((await open()) as Opened).database;
    await db.close();
    vault.values.clear();
    final unreadable = (await open()) as Unreadable;

    final result = await unreadable.startOver();

    final fresh = (result as Opened).database;
    expect(await fresh.thisDevice(), isNotNull);
    await fresh.close();
    final kept = folder.listSync().whereType<File>().where(
      (f) => f.path.contains('kibuo-unreadable-'),
    );
    expect(kept, hasLength(1), reason: 'never deleted, only set aside');
  });

  test('a new phone gets its own device, even with copied data', () async {
    final db = ((await open()) as Opened).database;
    final firstDevice = (await db.thisDevice()).id;
    await db.close();
    // The key came along, the device id did not.
    vault.values.remove(KeyVault.deviceId);

    final moved = ((await open()) as Opened).database;
    expect((await moved.thisDevice()).id, isNot(firstDevice));
    await moved.close();
  });
}
