import 'package:drift/drift.dart';

import 'package:kibuo/domain/sync/hybrid_clock.dart';

part 'database.g.dart';

/// Columns every synced record carries from the first version (ADR 0003):
/// a UUID v7 id, a version from the [HybridClock], the device that made the
/// change, and a deletion flag instead of real deletion.
mixin SyncColumns on Table {
  TextColumn get id => text()();
  IntColumn get version => integer()();
  TextColumn get deviceId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The phones and other devices that hold the user's data.
class Devices extends Table with SyncColumns {}

@DriftDatabase(tables: [Devices])
class KibuoDatabase extends _$KibuoDatabase {
  KibuoDatabase(super.executor, {required this.deviceId});

  /// This device, as recorded in the [Devices] table.
  final String deviceId;

  /// Bump with every change to the tables, and add the step to [migration].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// The highest version recorded on this device, to restart the clock.
  Future<int> lastVersion() async {
    final max = devices.version.max();
    final row = await (selectOnly(devices)..addColumns([max])).getSingle();
    return row.read(max) ?? 0;
  }

  Future<Device> thisDevice() =>
      (select(devices)..where((d) => d.id.equals(deviceId))).getSingle();
}
