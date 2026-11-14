import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The phone's secure storage (Android Keystore), where the database key and
/// this device's id live. It is never copied by Android's backups, so a new
/// phone starts without them (ADR 0005).
abstract interface class KeyVault {
  /// The key that opens the database, 32 random bytes as hex.
  static const databaseKey = 'database_key';

  /// This device's id. A new phone gets a new one, even with copied data.
  static const deviceId = 'device_id';

  Future<String?> read(String name);
  Future<void> write(String name, String value);
}

class SecureKeyVault implements KeyVault {
  const SecureKeyVault();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String name) => _storage.read(key: name);

  @override
  Future<void> write(String name, String value) =>
      _storage.write(key: name, value: value);
}
