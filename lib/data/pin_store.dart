import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/domain/lock/lock_rules.dart';

/// How a code check went.
sealed class PinCheck {
  const PinCheck();
  const factory PinCheck.accepted() = PinAccepted;
}

final class PinAccepted extends PinCheck {
  const PinAccepted();

  @override
  bool operator ==(Object other) => other is PinAccepted;

  @override
  int get hashCode => 0;
}

/// Wrong code; [failures] in a row so far.
final class PinRejected extends PinCheck {
  const PinRejected(this.failures);

  final int failures;
}

/// Too many wrong codes: no code is checked before [until].
final class PinLockedOut extends PinCheck {
  const PinLockedOut(this.until);

  final DateTime until;
}

/// Keeps the app-lock code in the phone's secure storage, only as a salted,
/// slow hash, with the count of wrong codes, so closing the app does not
/// reset the wait.
class PinStore {
  PinStore(this._vault, {DateTime Function()? now, this.iterations = 120000})
    : _now = now ?? DateTime.now;

  final KeyVault _vault;
  final DateTime Function() _now;

  /// PBKDF2 rounds: slow enough to resist guessing if the hash ever leaked.
  final int iterations;

  static const _hash = 'pin_hash';
  static const _salt = 'pin_salt';
  static const _rounds = 'pin_rounds';
  static const _length = 'pin_length';
  static const _failures = 'pin_failures';
  static const _lockedUntil = 'pin_locked_until';

  Future<bool> hasPin() async => await _vault.read(_hash) != null;

  Future<int?> pinLength() async =>
      int.tryParse(await _vault.read(_length) ?? '');

  Future<void> setPin(String pin) async {
    assert(isValidPin(pin), 'a code has 4 to 6 digits');
    final salt = _randomBytes(16);
    await _vault.write(_salt, base64.encode(salt));
    await _vault.write(_rounds, '$iterations');
    await _vault.write(_hash, base64.encode(_derive(pin, salt, iterations)));
    await _vault.write(_length, '${pin.length}');
    await _reset();
  }

  Future<void> removePin() async {
    for (final name in [
      _hash,
      _salt,
      _rounds,
      _length,
      _failures,
      _lockedUntil,
    ]) {
      await _vault.delete(name);
    }
  }

  /// When the current wait ends, if there is one.
  Future<DateTime?> lockedUntil() async {
    final raw = await _vault.read(_lockedUntil);
    final until = raw == null ? null : DateTime.tryParse(raw);
    if (until == null || !until.isAfter(_now())) return null;
    return until;
  }

  Future<PinCheck> check(String pin) async {
    final until = await lockedUntil();
    if (until != null) return PinLockedOut(until);

    final salt = base64.decode(await _vault.read(_salt) ?? '');
    final rounds = int.parse(await _vault.read(_rounds) ?? '$iterations');
    final expected = base64.decode(await _vault.read(_hash) ?? '');
    if (_sameBytes(_derive(pin, salt, rounds), expected)) {
      await _reset();
      return const PinCheck.accepted();
    }

    final failures = int.parse(await _vault.read(_failures) ?? '0') + 1;
    await _vault.write(_failures, '$failures');
    final wait = waitAfter(failures);
    if (wait == Duration.zero) return PinRejected(failures);
    final lockEnd = _now().add(wait);
    await _vault.write(_lockedUntil, lockEnd.toIso8601String());
    return PinLockedOut(lockEnd);
  }

  Future<void> _reset() async {
    await _vault.delete(_failures);
    await _vault.delete(_lockedUntil);
  }

  static List<int> _derive(String pin, List<int> salt, int rounds) =>
      pbkdf2(utf8.encode(pin), salt, rounds, 32);

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// Compares without stopping at the first difference.
  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// PBKDF2 with HMAC-SHA256 (RFC 8018).
List<int> pbkdf2(List<int> password, List<int> salt, int rounds, int length) {
  final hmac = Hmac(sha256, password);
  final out = <int>[];
  for (var block = 1; out.length < length; block++) {
    var u = hmac.convert([
      ...salt,
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ]).bytes;
    final t = List<int>.of(u);
    for (var i = 1; i < rounds; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.addAll(t);
  }
  return out.sublist(0, length);
}
