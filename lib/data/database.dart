import 'package:drift/drift.dart';
import 'package:kibuo/data/database.steps.dart';

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

/// The currencies the user works with (GLOSSARY: Devise).
class Currencies extends Table with SyncColumns {
  /// ISO 4217 code.
  TextColumn get code => text()();

  /// Decimals in use; amounts stay stored in the smallest ISO unit.
  BoolColumn get usesDecimals => boolean()();
}

/// « 1 [base] = [value] [quote] », typed by the user. A new rate is a new
/// row: the older ones stay, so the previous rate and its date can be shown.
@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table with SyncColumns {
  TextColumn get base => text()();
  TextColumn get quote => text()();

  /// Exact decimal, as typed: « 2800 », « 655.957 ».
  TextColumn get value => text()();

  DateTimeColumn get setOn => dateTime()();
}

/// The user's choices shared by their devices (the main currency…).
class Preferences extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get value => text()();
}

@DriftDatabase(tables: [Devices, Currencies, ExchangeRates, Preferences])
class KibuoDatabase extends _$KibuoDatabase {
  KibuoDatabase(super.executor, {required this.deviceId});

  /// This device, as recorded in the [Devices] table.
  final String deviceId;

  /// Bump with every change to the tables, and add the step to [migration].
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.currencies);
        await m.createTable(schema.exchangeRates);
        await m.createTable(schema.preferences);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// The highest version recorded in any table, to restart the clock.
  Future<int> lastVersion() async {
    final rows = await customSelect(
      'SELECT MAX(v) AS v FROM ('
      '${[for (final t in allTables) 'SELECT MAX(version) AS v FROM ${t.actualTableName}'].join(' UNION ALL ')})',
    ).getSingle();
    return rows.read<int?>('v') ?? 0;
  }

  Future<Device> thisDevice() =>
      (select(devices)..where((d) => d.id.equals(deviceId))).getSingle();
}
