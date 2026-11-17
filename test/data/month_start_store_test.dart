import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/month_start_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  setUp(() => db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p'));
  tearDown(() => db.close());

  test('the 1st until changed, then kept', () async {
    final store = MonthStartStore(db);
    expect(await store.read(), 1);
    await store.write(25);
    expect(await MonthStartStore(db).read(), 25);
  });
}
