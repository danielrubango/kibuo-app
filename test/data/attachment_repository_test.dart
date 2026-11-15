import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late Directory folder;
  late AttachmentRepository repo;
  final receipt = Uint8List.fromList(List.generate(3000, (i) => i % 251));

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    folder = await Directory.systemTemp.createTemp('kibuo-attachments');
    repo = AttachmentRepository(db, folder);
  });
  tearDown(() async {
    await db.close();
    await folder.delete(recursive: true);
  });

  test('a file is kept encrypted, and read back as it was', () async {
    final id = await repo.add(
      transactionId: 'tx-1',
      bytes: receipt,
      name: 'Reçu du taxi',
      kind: AttachmentKind.photo,
    );

    final info = (await repo.list('tx-1')).single;
    expect(info.id, id);
    expect(info.name, 'Reçu du taxi');
    expect(info.size, 3000);
    final stored = folder
        .listSync(recursive: true)
        .whereType<File>()
        .single
        .readAsBytesSync();
    expect(stored, isNot(containsAllInOrder(receipt.sublist(0, 32))));
    expect(await repo.read(id), receipt);
  });

  test('the key is made once and kept in the database', () async {
    final id = await repo.add(
      transactionId: 'tx-1',
      bytes: receipt,
      name: 'a',
      kind: AttachmentKind.photo,
    );
    final again = AttachmentRepository(db, folder);
    expect(await again.read(id), receipt);
  });

  test('five at most per operation', () async {
    for (var i = 0; i < 5; i++) {
      await repo.add(
        transactionId: 'tx-1',
        bytes: receipt,
        name: '$i',
        kind: AttachmentKind.photo,
      );
    }
    await expectLater(
      repo.add(
        transactionId: 'tx-1',
        bytes: receipt,
        name: '6',
        kind: AttachmentKind.photo,
      ),
      throwsA(isA<TooManyAttachments>()),
    );
    expect(
      [for (final a in await repo.list('tx-1')) a.name],
      ['0', '1', '2', '3', '4'],
    );
  });

  test('a file over 10 MB is refused', () async {
    await expectLater(
      repo.add(
        transactionId: 'tx-1',
        bytes: Uint8List(10 * 1024 * 1024 + 1),
        name: 'big.pdf',
        kind: AttachmentKind.pdf,
      ),
      throwsA(isA<AttachmentTooBig>()),
    );
  });

  test('removed, then put back', () async {
    final id = await repo.add(
      transactionId: 'tx-1',
      bytes: receipt,
      name: 'a',
      kind: AttachmentKind.photo,
    );
    await repo.remove(id);
    expect(await repo.list('tx-1'), isEmpty);
    await repo.restore(id);
    expect((await repo.list('tx-1')).single.id, id);
  });

  test('moved to the operation once it is saved', () async {
    final id = await repo.add(
      transactionId: 'draft',
      bytes: receipt,
      name: 'a',
      kind: AttachmentKind.pdf,
    );
    await repo.attach([id], 'tx-9');
    expect((await repo.list('tx-9')).single.kind, AttachmentKind.pdf);
  });
}
