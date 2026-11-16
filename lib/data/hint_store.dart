import 'package:drift/drift.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

/// The one-time hints Kibuo gives (PRODUCT: after a few openings of the +
/// sheet, a bubble shows the hold, once).
class HintStore {
  HintStore(this._db);

  final KibuoDatabase _db;
  HybridClock? _clock;

  static const _opens = 'hint_plus_sheet_opens';
  static const _done = 'hint_plus_hold_done';

  /// The sheet opens before the tip shows.
  static const opensBeforeTip = 3;

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  Future<String?> _read(String name) async =>
      (await (_db.select(_db.preferences)
                ..where((p) => p.name.equals(name) & p.deleted.not()))
              .getSingleOrNull())
          ?.value;

  Future<void> _write(String name, String value) async {
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

  /// Counts an opening of the + sheet by a tap; true when the hold tip
  /// should show now.
  Future<bool> sheetOpened() async {
    if (await _read(_done) == 'true') return false;
    final opens = int.tryParse(await _read(_opens) ?? '') ?? 0;
    await _write(_opens, '${opens + 1}');
    return opens + 1 >= opensBeforeTip;
  }

  /// The tip was read (« Compris »), or the hold was found alone: never
  /// again.
  Future<void> tipDone() => _write(_done, 'true');
}
