import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:kibuo/data/pin_store.dart' show pbkdf2;
import 'package:kibuo/domain/lock/recovery_code.dart';
import 'package:path/path.dart' as p;

/// A copy of the database key, locked by the recovery code, kept next to the
/// database (and so copied with it by Android, ADR 0010).
///
/// The code goes through PBKDF2-HMAC-SHA256 with a fresh salt into 64 bytes:
/// the first 32 mask the key, the last 32 sign it, so a wrong code is told
/// apart from a right one. Neither the code nor the key is ever written.
class RecoveryStore {
  RecoveryStore(Directory folder, {this.iterations = 300000})
    : _file = File(p.join(folder.path, fileName));

  static const fileName = 'kibuo-key.json';

  final File _file;

  /// Slow on purpose: each guess of a stolen file must cost time.
  final int iterations;

  Future<bool> exists() => _file.exists();

  Future<DateTime?> createdAt() async {
    if (!await _file.exists()) return null;
    final data = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
    return DateTime.tryParse(data['created'] as String? ?? '');
  }

  /// Locks [databaseKey] (hex) with [code]; any older code stops working.
  Future<void> create(String code, String databaseKey) async {
    final random = Random.secure();
    final salt = List.generate(16, (_) => random.nextInt(256));
    final derived = await _derive(
      normalizeRecoveryCode(code),
      salt,
      iterations,
    );
    final key = _fromHex(databaseKey);
    final masked = [for (var i = 0; i < key.length; i++) key[i] ^ derived[i]];
    final mac = Hmac(sha256, derived.sublist(32)).convert(masked).bytes;
    await _file.writeAsString(
      jsonEncode({
        'version': 1,
        'salt': base64.encode(salt),
        'rounds': iterations,
        'key': base64.encode(masked),
        'mac': base64.encode(mac),
        'created': DateTime.now().toUtc().toIso8601String(),
      }),
      flush: true,
    );
  }

  /// The database key (hex) when [typed] is the right code, else null.
  Future<String?> unlock(String typed) async {
    if (!await _file.exists()) return null;
    final code = normalizeRecoveryCode(typed);
    if (!isRecoveryCode(code)) return null;
    final data = jsonDecode(await _file.readAsString()) as Map<String, dynamic>;
    final salt = base64.decode(data['salt'] as String);
    final rounds = data['rounds'] as int;
    final masked = base64.decode(data['key'] as String);
    final mac = base64.decode(data['mac'] as String);
    final derived = await _derive(code, salt, rounds);
    final expected = Hmac(sha256, derived.sublist(32)).convert(masked).bytes;
    if (expected.length != mac.length) return null;
    var diff = 0;
    for (var i = 0; i < expected.length; i++) {
      diff |= expected[i] ^ mac[i];
    }
    if (diff != 0) return null;
    return _toHex([
      for (var i = 0; i < masked.length; i++) masked[i] ^ derived[i],
    ]);
  }

  /// Runs away from the screen's thread: it takes a while on purpose.
  static Future<List<int>> _derive(String code, List<int> salt, int rounds) =>
      Isolate.run(() => pbkdf2(utf8.encode(code), salt, rounds, 64));

  static List<int> _fromHex(String hex) => [
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];

  static String _toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
