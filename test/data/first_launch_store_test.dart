import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/first_launch_store.dart';
import 'package:kibuo/domain/money/money.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  setUp(() => db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p'));
  tearDown(() => db.close());

  Future<void> anAccount() => AccountRepository(db).create(
    name: 'M-Pesa',
    type: AccountType.mobile,
    opening: const Money(0, 'USD'),
    openingDate: DateTime.utc(2026, 11, 1),
  );

  test('a new app, without any account, starts with it, at step 1', () async {
    final store = FirstLaunchStore(db);
    expect(await store.needed(), isTrue);
    expect(await store.step(), 1);
  });

  test('an app that already has accounts never shows it', () async {
    await anAccount();
    final store = FirstLaunchStore(db);
    expect(await store.needed(), isFalse);
    // And it stays so, even if the accounts go.
    expect(await FirstLaunchStore(db).needed(), isFalse);
  });

  test('left half way, it starts again where it was left', () async {
    await FirstLaunchStore(db).reached(3);
    expect(await FirstLaunchStore(db).needed(), isTrue);
    expect(await FirstLaunchStore(db).step(), 3);
  });

  test('left at the last step, once the first account exists', () async {
    await anAccount();
    await FirstLaunchStore(db).reached(4);
    expect(await FirstLaunchStore(db).needed(), isTrue);
    expect(await FirstLaunchStore(db).step(), 4);
  });

  test('finished, it never comes back', () async {
    await FirstLaunchStore(db).reached(4);
    await FirstLaunchStore(db).finish();
    expect(await FirstLaunchStore(db).needed(), isFalse);
  });

  test('the chosen language is remembered', () async {
    expect(await FirstLaunchStore(db).language(), isNull);
    await FirstLaunchStore(db).setLanguage('en');
    expect(await FirstLaunchStore(db).language(), 'en');
    await FirstLaunchStore(db).setLanguage(null);
    expect(await FirstLaunchStore(db).language(), isNull);
  });
}
