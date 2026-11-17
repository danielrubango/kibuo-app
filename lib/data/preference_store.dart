import 'package:drift/drift.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

/// Reads and writes one named value of the preferences table, with the
/// record's version and device (ADR 0003).
class PreferenceStore {
  PreferenceStore(this._db);

  final KibuoDatabase _db;
  HybridClock? _clock;

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  Future<String?> read(String name) async =>
      (await (_db.select(_db.preferences)
                ..where((p) => p.name.equals(name) & p.deleted.not()))
              .getSingleOrNull())
          ?.value;

  Future<void> write(String name, String value) async {
    final existing = await (_db.select(
      _db.preferences,
    )..where((p) => p.name.equals(name))).getSingleOrNull();
    final version = await _nextVersion();
    if (existing == null) {
      await _db
          .into(_db.preferences)
          .insert(
            PreferencesCompanion.insert(
              id: const Uuid().v7(),
              version: version,
              deviceId: _db.deviceId,
              name: name,
              value: value,
            ),
          );
    } else {
      await (_db.update(
        _db.preferences,
      )..where((p) => p.id.equals(existing.id))).write(
        PreferencesCompanion(
          value: Value(value),
          version: Value(version),
          deviceId: Value(_db.deviceId),
          deleted: const Value(false),
        ),
      );
    }
  }
}
