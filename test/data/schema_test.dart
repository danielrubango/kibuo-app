import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/data/database.dart';

/// Guards the migration rule: any change to the tables must come with a new
/// schema version, saved by `dart run drift_dev make-migrations`, which also
/// generates the tests that migrate real data from each older version.
void main() {
  late KibuoDatabase db;

  setUp(() => db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'test'));
  tearDown(() => db.close());

  Map<String, dynamic> savedSchema(int version) => jsonDecode(
    File('drift_schemas/kibuo/drift_schema_v$version.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('the current tables match the saved schema of this version', () async {
    final saved = savedSchema(db.schemaVersion);
    final tables = (saved['entities'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((e) => e['type'] == 'table');

    for (final entity in tables) {
      final data = entity['data'] as Map<String, dynamic>;
      final name = data['name'] as String;
      final expected = {
        for (final c
            in (data['columns'] as List<dynamic>).cast<Map<String, dynamic>>())
          c['name'] as String: c['nullable'] as bool,
      };

      final rows = await db.customSelect('PRAGMA table_info($name)').get();
      final actual = {
        for (final r in rows)
          r.read<String>('name'): r.read<int>('notnull') == 0,
      };
      expect(actual, expected, reason: 'table $name');
    }
    expect(
      tables.map((e) => (e['data'] as Map<String, dynamic>)['name']).toSet(),
      db.allTables.map((t) => t.actualTableName).toSet(),
    );
  });

  test('every table carries the sync columns', () async {
    for (final table in db.allTables) {
      final names = table.$columns.map((c) => c.name).toSet();
      expect(
        names,
        containsAll(['id', 'version', 'device_id', 'deleted']),
        reason: table.actualTableName,
      );
      expect(table.$primaryKey.map((c) => c.name), ['id']);
    }
  });

  test('records are never deleted for real, only marked', () async {
    final device = await db
        .into(db.devices)
        .insertReturning(
          DevicesCompanion.insert(id: 'a', version: 1, deviceId: 'a'),
        );
    expect(device.deleted, isFalse);

    await (db.update(db.devices)..where((d) => d.id.equals('a'))).write(
      const DevicesCompanion(deleted: Value(true), version: Value(2)),
    );
    final kept = await db.select(db.devices).getSingle();
    expect(kept.deleted, isTrue);
  });
}
