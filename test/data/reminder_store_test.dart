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

  test('due dates: on, 3 days before, and each recurrence its own', () async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    addTearDown(db.close);
    final store = ReminderStore(db);
    expect(await store.dueOn(), isTrue);
    expect(await store.dueDays(), 3);
    expect(await store.ruleDays('r'), isNull);
    await store.setRuleDays('r', -1);
    expect(await store.ruleDays('r'), -1);
    await store.setRuleDays('r', null);
    expect(await store.ruleDays('r'), isNull);
    await store.setDueDays(7);
    await store.setDueOn(false);
    expect(await store.dueDays(), 7);
    expect(await store.dueOn(), isFalse);
  });

  test('budget alerts: on, and what was said this month only', () async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    addTearDown(db.close);
    final store = ReminderStore(db);
    expect(await store.budgetAt80(), isTrue);
    expect(await store.budgetAt100(), isTrue);
    await store.addBudgetAlerted(['budget:r:202610:80'], 202610);
    await store.addBudgetAlerted(['budget:r:202611:80'], 202611);
    expect(await store.budgetAlerted(), {'budget:r:202611:80'});
  });
}
