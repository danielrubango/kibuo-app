import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/hint_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  setUp(() => db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p'));
  tearDown(() => db.close());

  test('the hold tip comes on the third opening, once', () async {
    final hints = HintStore(db);
    expect(await hints.sheetOpened(), isFalse);
    expect(await hints.sheetOpened(), isFalse);
    expect(await hints.sheetOpened(), isTrue);
    await hints.tipDone();
    expect(await hints.sheetOpened(), isFalse);
    expect(await HintStore(db).sheetOpened(), isFalse, reason: 'kept');
  });

  test('never once the fan was used', () async {
    final hints = HintStore(db);
    await hints.tipDone();
    for (var i = 0; i < 4; i++) {
      expect(await hints.sheetOpened(), isFalse);
    }
  });
}
