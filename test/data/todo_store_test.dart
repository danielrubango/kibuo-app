import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/todo_store.dart';
import 'package:kibuo/domain/todo/todo.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('a line put off is kept, and comes back on « Annuler »', () async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    addTearDown(db.close);
    final store = TodoStore(db);
    final now = DateTime(2026, 11, 18);
    const drafts = TodoItem(kind: TodoKind.drafts, key: 'drafts');
    await store.putOffToday('drafts', now);
    expect((await store.putOff()).visible([drafts], now), isEmpty);
    await store.bringBack('drafts');
    expect((await store.putOff()).visible([drafts], now), hasLength(1));
  });
}
