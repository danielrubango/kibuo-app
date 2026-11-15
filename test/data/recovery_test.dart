import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/data/recovery_store.dart';

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
  late _MemoryVault vault;
  RecoveryStore store() => RecoveryStore(folder, iterations: 1000);

  setUp(() {
    folder = Directory.systemTemp.createTempSync('kibuo_recovery_');
    vault = _MemoryVault();
  });
  tearDown(() => folder.deleteSync(recursive: true));

  Future<OpenResult> open() => openKibuoDatabase(
    folder: folder,
    vault: vault,
    inBackground: false,
    recoveryRounds: 1000,
  );

  test(
    'the right code gives the key back, a wrong one gives nothing',
    () async {
      final key = 'ab' * 32;
      await store().create('KB7Q4M2X9TPAH3WD', key);

      expect(await store().unlock('KB7Q4M2X9TPAH3WD'), key);
      expect(await store().unlock('KB7Q4M2X9TPAH3WE'), isNull);
    },
  );

  test('neither the code nor the key is kept in the file', () async {
    final key = 'cd' * 32;
    await store().create('KB7Q4M2X9TPAH3WD', key);

    final saved = File('${folder.path}/kibuo-key.json').readAsStringSync();
    expect(saved, isNot(contains('KB7Q')));
    expect(saved, isNot(contains('cdcdcdcd')));
  });

  test('a new code replaces the old one, which stops working', () async {
    final key = 'ef' * 32;
    await store().create('KB7Q4M2X9TPAH3WD', key);
    await store().create('ZZZZ2222YYYY3333', key);

    expect(await store().unlock('KB7Q4M2X9TPAH3WD'), isNull);
    expect(await store().unlock('ZZZZ2222YYYY3333'), key);
  });

  test('the creation date is remembered', () async {
    expect(await store().createdAt(), isNull);
    await store().create('KB7Q4M2X9TPAH3WD', 'ab' * 32);
    expect(await store().createdAt(), isNotNull);
  });

  group('on a new phone (data copied, key and device left behind)', () {
    late String code;
    late String firstDevice;

    setUp(() async {
      final db = ((await open()) as Opened).database;
      firstDevice = (await db.thisDevice()).id;
      await db.close();
      code = await createRecoveryCode(
        folder: folder,
        vault: vault,
        rounds: 1000,
      );
      vault.values.clear();
    });

    test('the data cannot be opened, but can be recovered', () async {
      final result = await open();

      expect(result, isA<Unreadable>());
      expect((result as Unreadable).canRecover, isTrue);
    });

    test('a wrong code leaves it unreadable', () async {
      final unreadable = (await open()) as Unreadable;

      expect(await unreadable.recover('2222333344445555'), isNull);
    });

    test('the right code opens the same data on a new device', () async {
      final unreadable = (await open()) as Unreadable;

      final result = await unreadable.recover(code);

      final db = (result! as Opened).database;
      expect((await db.thisDevice()).id, isNot(firstDevice));
      final devices = await db.select(db.devices).get();
      expect(devices.map((d) => d.id), contains(firstDevice));
      await db.close();
      expect(vault.values[KeyVault.databaseKey], isNotNull);
    });

    test('typed with dashes and lowercase, the code still works', () async {
      final unreadable = (await open()) as Unreadable;
      final typed =
          '${code.substring(0, 4).toLowerCase()}-${code.substring(4)}';

      final result = await unreadable.recover(typed);

      await (result! as Opened).database.close();
    });
  });

  test('without a recovery code, the data cannot be recovered', () async {
    await ((await open()) as Opened).database.close();
    vault.values.clear();

    final result = (await open()) as Unreadable;
    expect(result.canRecover, isFalse);
  });

  test('starting over sets the old key file aside with the data', () async {
    await ((await open()) as Opened).database.close();
    await createRecoveryCode(folder: folder, vault: vault, rounds: 1000);
    vault.values.clear();

    final fresh = await ((await open()) as Unreadable).startOver();

    await (fresh as Opened).database.close();
    expect(await store().createdAt(), isNull, reason: 'no code for new data');
  });
}
