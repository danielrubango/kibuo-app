import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';

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
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late _MemoryVault vault;
  late BackupService backups;

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    vault = _MemoryVault();
    backups = BackupService(
      db: db,
      appFolder: () async => Directory.systemTemp,
      vault: vault,
    );
  });
  tearDown(() => db.close());

  test('nothing yet: no folder, no backup, no operation', () async {
    final state = await backups.state();
    expect(state.folder, isNull);
    expect(state.last, isNull);
    expect(state.firstOperation, isNull);
    expect(state.old(DateTime(2026, 11, 24)), isFalse);
  });

  test('the folder and the last backup are kept on the phone', () async {
    await backups.setFolder(
      const BackupFolder(
        uri: 'content://tree/primary%3ADownload',
        name: 'Download',
      ),
    );
    await backups.done(DateTime(2026, 11, 24, 21, 4));

    final state = await BackupService(
      db: db,
      appFolder: () async => Directory.systemTemp,
      vault: vault,
    ).state();
    expect(state.folder?.uri, 'content://tree/primary%3ADownload');
    expect(state.folder?.name, 'Download');
    expect(state.last, DateTime(2026, 11, 24, 21, 4));
    expect(state.old(DateTime(2026, 12, 1)), isFalse);
    expect(state.old(DateTime(2026, 12, 2)), isTrue);
  });

  test('without a backup, the reminder waits on the first operation', () async {
    await CurrencyRepository(db).ensurePrimaryCurrency('US');
    final account = await AccountRepository(db).create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(12000, 'USD'),
      openingDate: DateTime(2026, 11, 1),
    );
    for (final day in [DateTime(2026, 11, 20), DateTime(2026, 11, 10)]) {
      await TransactionRepository(db).create(
        kind: EntryKind.expense,
        accountId: account,
        categoryId: 'default-taxi',
        paid: const Money(500, 'USD'),
        fees: 0,
        date: day,
      );
    }

    final state = await backups.state();
    expect(state.firstOperation, DateTime(2026, 11, 10));
    expect(state.old(DateTime(2026, 11, 17)), isFalse);
    expect(state.old(DateTime(2026, 11, 18)), isTrue);
  });

  test('a password can be remembered, changed and forgotten', () async {
    expect((await backups.state()).hasPassword, isFalse);
    expect(await backups.rememberedPassword(), isNull);
    await backups.rememberPassword('premier-mot');
    expect((await backups.state()).hasPassword, isTrue);
    expect(await backups.rememberedPassword(), 'premier-mot');
    await backups.rememberPassword('second-mot');
    expect(await backups.rememberedPassword(), 'second-mot');
    await backups.forgetPassword();
    expect((await backups.state()).hasPassword, isFalse);
    expect(await backups.rememberedPassword(), isNull);
  });
}
