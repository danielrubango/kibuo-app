import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/long_amounts_store.dart';
import 'package:kibuo/domain/money/long_amounts.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  setUp(() => db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p'));
  tearDown(() => db.close());

  test('automatic until changed, then kept', () async {
    final store = LongAmountsStore(db);
    expect(await store.read(), LongAmounts.auto);
    await store.write(LongAmounts.never);
    expect(await LongAmountsStore(db).read(), LongAmounts.never);
  });
}
