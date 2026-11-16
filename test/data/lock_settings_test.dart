import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/lock_settings.dart';

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

void main() {
  test('the code for important actions is off, then kept once on', () async {
    final store = LockSettingsStore(_MemoryVault());
    expect((await store.load()).protectActions, isFalse);

    final on = (await store.load()).copyWith(protectActions: true);
    await store.save(on);
    expect((await store.load()).protectActions, isTrue);
  });
}
