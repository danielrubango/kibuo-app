import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/pin_store.dart';

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
  late _MemoryVault vault;
  var now = DateTime(2026, 11, 15, 10);
  PinStore store() => PinStore(vault, now: () => now, iterations: 1000);

  setUp(() {
    vault = _MemoryVault();
    now = DateTime(2026, 11, 15, 10);
  });

  test('PBKDF2-HMAC-SHA256 matches the reference vector', () {
    final key = pbkdf2(utf8.encode('password'), utf8.encode('salt'), 1, 32);
    expect(
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
  });

  test('without a code, Kibuo opens directly', () async {
    expect(await store().hasPin(), isFalse);
  });

  test('the code is checked, and its length remembered', () async {
    await store().setPin('48213');

    expect(await store().hasPin(), isTrue);
    expect(await store().pinLength(), 5);
    expect(await store().check('48213'), const PinCheck.accepted());
    expect(await store().check('48210'), isA<PinRejected>());
  });

  test('the code itself is never kept', () async {
    await store().setPin('482139');

    for (final value in vault.values.values) {
      expect(value, isNot(contains('482139')));
    }
  });

  test('wrong codes are still counted after a restart', () async {
    await store().setPin('1234');
    for (var i = 0; i < 4; i++) {
      await store().check('0000');
    }

    final result = await store().check('0000');

    expect(result, isA<PinLockedOut>());
    expect(
      (result as PinLockedOut).until,
      now.add(const Duration(seconds: 30)),
    );
  });

  test('during the wait even the right code is refused', () async {
    await store().setPin('1234');
    for (var i = 0; i < 5; i++) {
      await store().check('0000');
    }
    now = now.add(const Duration(seconds: 10));

    expect(await store().check('1234'), isA<PinLockedOut>());
  });

  test('after the wait the right code opens and resets the count', () async {
    await store().setPin('1234');
    for (var i = 0; i < 5; i++) {
      await store().check('0000');
    }
    now = now.add(const Duration(seconds: 31));

    expect(await store().check('1234'), const PinCheck.accepted());
    expect(await store().lockedUntil(), isNull);
    for (var i = 0; i < 4; i++) {
      expect(await store().check('0000'), isA<PinRejected>());
    }
  });

  test('a sixth failure after the wait makes it longer', () async {
    await store().setPin('1234');
    for (var i = 0; i < 5; i++) {
      await store().check('0000');
    }
    now = now.add(const Duration(seconds: 31));

    final result = await store().check('0000');

    expect((result as PinLockedOut).until, now.add(const Duration(minutes: 1)));
  });

  test('removing the code leaves no trace of it', () async {
    await store().setPin('1234');
    await store().check('0000');

    await store().removePin();

    expect(await store().hasPin(), isFalse);
    expect(vault.values.keys.where((k) => k.startsWith('pin_')), isEmpty);
  });
}
