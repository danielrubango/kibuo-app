import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';

void main() {
  test('a new recovery code waits to be proved, then is verified', () async {
    final vault = _MemoryVault();
    LockController lock() => LockController(
      vault: vault,
      biometrics: _NoBiometrics(),
      privacy: _NoPrivacy(),
      recovery: _FakeRecovery(),
    );
    final first = lock();
    await first.load();
    expect(first.settings.recoveryVerified, isTrue, reason: 'no false alarm');
    await first.newRecoveryCode();
    expect(first.settings.recoveryVerified, isFalse);
    // Kept when kibuo is closed before the proof.
    final again = lock();
    await again.load();
    expect(again.settings.recoveryVerified, isFalse);
    await again.markRecoveryVerified();
    final last = lock();
    await last.load();
    expect(last.settings.recoveryVerified, isTrue);
  });
}

class _FakeRecovery implements Recovery {
  DateTime? _at;

  @override
  Future<DateTime?> createdAt() async => _at;

  @override
  Future<String> createCode() async {
    _at = DateTime(2026, 11, 18);
    return 'ABCD-EFGH-JKLM-NPQR';
  }

  @override
  Future<bool> check(String typed) async => true;
}

class _MemoryVault implements KeyVault {
  final values = <String, String>{};

  @override
  Future<String?> read(String name) async => values[name];

  @override
  Future<void> write(String name, String value) async => values[name] = value;

  @override
  Future<void> delete(String name) async => values.remove(name);

  @override
  Future<void> deleteAll() async => values.clear();
}

class _NoBiometrics implements Biometrics {
  @override
  Future<bool> available() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}

class _NoPrivacy implements PrivacyPlatform {
  @override
  Future<bool> canHidePreview() async => true;

  @override
  Future<void> apply({
    required bool allowScreenshots,
    required bool hideInRecents,
    required bool androidCopy,
  }) async {}
}
