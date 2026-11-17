import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/search_history.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  setUp(() => db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p'));
  tearDown(() => db.close());

  test('kept between openings, newest first, then cleared', () async {
    await SearchHistory(db).remember('Taxi');
    await SearchHistory(db).remember('Loyer');
    expect(await SearchHistory(db).recent(), ['Loyer', 'Taxi']);
    await SearchHistory(db).clear();
    expect(await SearchHistory(db).recent(), isEmpty);
  });
}
