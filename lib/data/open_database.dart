import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/recovery_store.dart';
import 'package:kibuo/domain/lock/recovery_code.dart';
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

/// The file exists but cannot be read: its key is gone from the phone, does
/// not match, or the data came from another phone. The file stays where it
/// is until the user decides.
final class Unreadable extends OpenResult {
  Unreadable._(
    this._folder,
    this._vault,
    this._inBackground,
    this._rounds, {
    required this.canRecover,
  });

  final Directory _folder;
  final KeyVault _vault;
  final bool _inBackground;
  final int? _rounds;

  /// A recovery code was created for this data, so it can be reopened.
  final bool canRecover;

  /// Reopens the data with the recovery code; null when the code is wrong.
  Future<OpenResult?> recover(String code) async {
    final key = await RecoveryStore(
      _folder,
      iterations: _rounds ?? 300000,
    ).unlock(code);
    if (key == null) return null;
    await _vault.write(KeyVault.databaseKey, key);
    return openKibuoDatabase(
      folder: _folder,
      vault: _vault,
      inBackground: _inBackground,
      recoveryRounds: _rounds,
    );
  }

  /// Sets the unreadable file (and its locked key) aside, without deleting
  /// it, and starts with an empty database and a new key.
  Future<OpenResult> startOver() async {
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    await File(p.join(_folder.path, _fileName))
        .rename(p.join(_folder.path, 'kibuo-unreadable-$stamp.db'));
    final keyFile = File(p.join(_folder.path, RecoveryStore.fileName));
    if (keyFile.existsSync()) {
      await keyFile.rename(
        p.join(_folder.path, 'kibuo-unreadable-$stamp-key.json'),
      );
    }
    await _vault.write(KeyVault.databaseKey, _newKey());
    return openKibuoDatabase(
      folder: _folder,
      vault: _vault,
      inBackground: _inBackground,
      recoveryRounds: _rounds,
    );
  }
}

const _fileName = 'kibuo.db';

/// Deletes the database and every file set aside, and forgets all keys, then
/// opens an empty database: « Effacer et repartir de zéro ».
Future<OpenResult> eraseAndStartOver({
  required Directory folder,
  KeyVault vault = const SecureKeyVault(),
  bool inBackground = true,
}) async {
  for (final entry in folder.listSync()) {
    if (entry is File && p.basename(entry.path).startsWith('kibuo')) {
      entry.deleteSync();
    }
  }
  await vault.deleteAll();
  return openKibuoDatabase(
    folder: folder,
    vault: vault,
    inBackground: inBackground,
  );
}

/// Opens the encrypted database in [folder], creating it and its key on the
/// first start (ADR 0005, ADR 0010).
Future<OpenResult> openKibuoDatabase({
  required Directory folder,
  KeyVault vault = const SecureKeyVault(),
  bool inBackground = true,
  int? recoveryRounds,
}) async {
  Future<OpenResult> unreadable() async => Unreadable._(
    folder,
    vault,
    inBackground,
    recoveryRounds,
    canRecover: await RecoveryStore(folder).exists(),
  );

  final file = File(p.join(folder.path, _fileName));
  final existed = file.existsSync();

  var key = await vault.read(KeyVault.databaseKey);
  if (key == null) {
    if (existed) return unreadable();
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
    if (existed) return unreadable();
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

/// Creates a new recovery code for the data in [folder] and returns it, to
/// be shown once: Kibuo keeps only the key it locks. Any older code stops
/// working.
Future<String> createRecoveryCode({
  required Directory folder,
  KeyVault vault = const SecureKeyVault(),
  int? rounds,
}) async {
  final key = await vault.read(KeyVault.databaseKey);
  if (key == null) throw StateError('No database key on this phone.');
  final code = newRecoveryCode(Random.secure());
  await RecoveryStore(folder, iterations: rounds ?? 300000).create(code, key);
  return code;
}

String _newKey() {
  final random = Random.secure();
  return List.generate(
    32,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
