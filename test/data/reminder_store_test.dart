import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/reminder_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('the entry reminder: off at 20:00, then as set', () async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    addTearDown(db.close);
    final store = ReminderStore(db);
    expect(await store.entryOn(), isFalse);
    expect(await store.entryMinute(), 20 * 60);
    await store.setEntryOn(true);
    await store.setEntryMinute(21 * 60 + 30);
    expect(await store.entryOn(), isTrue);
    expect(await store.entryMinute(), 21 * 60 + 30);
  });
}
