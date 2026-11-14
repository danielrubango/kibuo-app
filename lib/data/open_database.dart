import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:uuid/uuid.dart';

/// How opening the database went.
sealed class OpenResult {}

final class Opened extends OpenResult {
  Opened(this.database);

  final KibuoDatabase database;
}

/// The file exists but cannot be read: its key is gone from the phone, or
/// does not match. The file stays where it is until the user decides.
final class Unreadable extends OpenResult {
  Unreadable._(this._startOver);

  final Future<OpenResult> Function() _startOver;

  /// Sets the unreadable file aside, without deleting it, and starts with
  /// an empty database and a new key.
  Future<OpenResult> startOver() => _startOver();
}

const _fileName = 'kibuo.db';

/// Opens the encrypted database in [folder], creating it and its key on the
/// first start (ADR 0005, ADR 0010).
Future<OpenResult> openKibuoDatabase({
  required Directory folder,
  KeyVault vault = const SecureKeyVault(),
  bool inBackground = true,
}) async {
  final file = File(p.join(folder.path, _fileName));
  final existed = file.existsSync();

  var key = await vault.read(KeyVault.databaseKey);
  if (key == null) {
    if (existed) return _unreadable(folder, vault, inBackground);
    key = _newKey();
    await vault.write(KeyVault.databaseKey, key);
  }

  var deviceId = await vault.read(KeyVault.deviceId);
  if (deviceId == null) {
    deviceId = const Uuid().v7();
    await vault.write(KeyVault.deviceId, deviceId);
  }

  final database = KibuoDatabase(
    _executor(file, key, inBackground: inBackground),
    deviceId: deviceId,
  );
  try {
    await _registerDevice(database);
  } on Object {
    await database.close();
    if (existed) return _unreadable(folder, vault, inBackground);
    rethrow;
  }
  return Opened(database);
}

QueryExecutor _executor(File file, String key, {required bool inBackground}) {
  void unlock(sqlite.Database raw) {
    // The key is raw random bytes, so no slow password derivation is needed.
    raw.execute("PRAGMA hexkey = '$key'");
    // Fails here, with « not a database », when the key does not match.
    raw.select('SELECT count(*) FROM sqlite_master');
  }

  return inBackground
      ? NativeDatabase.createInBackground(file, setup: unlock)
      : NativeDatabase(file, setup: unlock);
}

/// Records this device on first use. A copy of the data moved to a new
/// phone gets a second device, never a shared one.
Future<void> _registerDevice(KibuoDatabase db) async {
  final known = await (db.select(
    db.devices,
  )..where((d) => d.id.equals(db.deviceId))).getSingleOrNull();
  if (known != null) return;
  final clock = HybridClock(last: await db.lastVersion());
  await db
      .into(db.devices)
      .insert(
        DevicesCompanion.insert(
          id: db.deviceId,
          version: clock.next(),
          deviceId: db.deviceId,
        ),
      );
}

Future<OpenResult> _unreadable(
  Directory folder,
  KeyVault vault,
  bool inBackground,
) async => Unreadable._(() async {
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
  await File(p.join(folder.path, _fileName))
      .rename(p.join(folder.path, 'kibuo-unreadable-$stamp.db'));
  await vault.write(KeyVault.databaseKey, _newKey());
  return openKibuoDatabase(
    folder: folder,
    vault: vault,
    inBackground: inBackground,
  );
});

String _newKey() {
  final random = Random.secure();
  return List.generate(
    32,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
