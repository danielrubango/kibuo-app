import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/money/money.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late AccountRepository repo;
  final day = DateTime.utc(2026, 11, 15);

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    repo = AccountRepository(db);
  });
  tearDown(() => db.close());

  test('a new account keeps its starting balance as its balance', () async {
    final id = await repo.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(12000, 'USD'),
      openingDate: day,
    );

    final account = (await repo.accounts()).single;
    expect(account.id, id);
    expect(account.name, 'M-Pesa');
    expect(account.type, AccountType.mobile);
    expect(account.balance, const Money(12000, 'USD'));
    expect(account.openingDate, day);
  });

  test('an account’s currency joins the user’s currencies', () async {
    await repo.create(
      name: 'Airtel',
      type: AccountType.mobile,
      opening: const Money(8400000, 'CDF'),
      openingDate: day,
    );

    expect(await CurrencyRepository(db).currencyCodes(), contains('CDF'));
  });

  test('the name is required and trimmed', () async {
    expect(
      () => repo.create(
        name: '  ',
        type: AccountType.cash,
        opening: const Money(0, 'USD'),
        openingDate: day,
      ),
      throwsArgumentError,
    );
    await repo.create(
      name: '  Poche ',
      type: AccountType.cash,
      opening: const Money(0, 'USD'),
      openingDate: day,
    );
    expect((await repo.accounts()).single.name, 'Poche');
  });

  test(
    'editing changes the name and type, never the starting balance',
    () async {
      final id = await repo.create(
        name: 'M-Pesa',
        type: AccountType.mobile,
        opening: const Money(12000, 'USD'),
        openingDate: day,
      );
      await repo.update(id, name: 'M-Pesa dollars', type: AccountType.bank);

      final account = (await repo.accounts()).single;
      expect(account.id, id);
      expect(account.name, 'M-Pesa dollars');
      expect(account.type, AccountType.bank);
      expect(account.opening, const Money(12000, 'USD'));
      expect(account.openingDate, day);
    },
  );

  test('an archived account leaves the list, and can come back', () async {
    final id = await repo.create(
      name: 'Ancien',
      type: AccountType.bank,
      opening: const Money(0, 'USD'),
      openingDate: day,
    );
    await repo.archive(id);
    expect(await repo.accounts(), isEmpty);
    expect((await repo.accounts(archived: true)).single.id, id);

    await repo.archive(id, archived: false);
    expect((await repo.accounts()).single.id, id);
  });

  test('accounts come in the order they were created', () async {
    for (final name in ['B', 'A', 'C']) {
      await repo.create(
        name: name,
        type: AccountType.cash,
        opening: const Money(0, 'USD'),
        openingDate: day,
      );
    }
    expect([for (final a in await repo.accounts()) a.name], ['B', 'A', 'C']);
  });

  test('the user’s own types, with their icon', () async {
    final tontine = await repo.createType(name: 'Tontine', icon: 'users');
    await repo.create(
      name: 'Tontine du quartier',
      type: AccountType.custom(tontine),
      opening: const Money(0, 'CDF'),
      openingDate: day,
    );

    final types = await repo.types();
    expect([for (final t in types) t.name], ['Tontine']);
    expect(types.single.icon, 'users');
    expect((await repo.accounts()).single.type, AccountType.custom(tontine));
  });

  test('the display choice is kept', () async {
    expect(await repo.allInMain(), isFalse);
    await repo.setAllInMain(true);
    expect(await repo.allInMain(), isTrue);
    await repo.setAllInMain(false);
    expect(await repo.allInMain(), isFalse);
  });

  test('no overdraft at creation, then allowed up to a limit', () async {
    final id = await repo.create(
      name: 'Rawbank',
      type: AccountType.bank,
      opening: const Money(0, 'USD'),
      openingDate: DateTime.utc(2026, 11, 1),
    );
    expect((await repo.accounts()).single.overdraft.allowed, isFalse);

    await repo.update(
      id,
      name: 'Rawbank',
      type: AccountType.bank,
      overdraft: const Overdraft(allowed: true, limit: 10000),
    );
    var o = (await repo.accounts()).single.overdraft;
    expect(o.allowed, isTrue);
    expect(o.limit, 10000);

    await repo.update(
      id,
      name: 'Rawbank',
      type: AccountType.bank,
      overdraft: const Overdraft(allowed: false, limit: 10000),
    );
    o = (await repo.accounts()).single.overdraft;
    expect(o.allowed, isFalse);
    expect(o.limit, 10000, reason: 'kept for when it comes back');
  });
}
