import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late RecurringRepository rules;
  late TransactionRepository transactions;
  late AccountRepository accounts;
  late String mpesa;
  late String savings;

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    rules = RecurringRepository(db);
    transactions = TransactionRepository(db);
    accounts = AccountRepository(db);
    await CurrencyRepository(db).ensurePrimaryCurrency('US');
    mpesa = await accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(10000, 'USD'),
      openingDate: DateTime.utc(2026),
    );
    savings = await accounts.create(
      name: 'Épargne',
      type: AccountType.savings,
      opening: const Money(0, 'USD'),
      openingDate: DateTime.utc(2026),
    );
  });
  tearDown(() => db.close());

  Future<String> internet({bool? asDraft, int amount = 3000}) => rules.create(
    kind: EntryKind.expense,
    accountId: mpesa,
    categoryId: 'default-internet',
    amount: Money(amount, 'USD'),
    note: 'Internet',
    unit: RepeatUnit.month,
    start: DateTime(2026, 9, 8),
    asDraft: asDraft,
  );

  Future<int> balance(String id) async =>
      (await accounts.accounts()).firstWhere((a) => a.id == id).balance.minor;

  test('missed dates are made at their own date, once', () async {
    await internet();
    expect(await rules.catchUp(DateTime(2026, 11, 18, 10)), 3);
    final ops = await transactions.all();
    expect([for (final t in ops) t.date.toLocal().day], [8, 8, 8]);
    expect([for (final t in ops) t.date.toLocal().month], [11, 10, 9]);
    expect(await balance(mpesa), 10000 - 3 * 3000);
    // Coming back the same day makes nothing more.
    expect(await rules.catchUp(DateTime(2026, 11, 18, 22)), 0);
    expect((await transactions.all()).length, 3);
  });

  test('a draft waits: out of balances and of the list', () async {
    await internet(asDraft: true);
    await rules.catchUp(DateTime(2026, 9, 9));
    expect(await transactions.all(), isEmpty);
    expect((await transactions.all(drafts: true)).single.status, 'draft');
    expect(await balance(mpesa), 10000);
  });

  test('« Toujours demander » makes drafts of rules that follow it', () async {
    await rules.setAlwaysAsk(true);
    await internet();
    await rules.catchUp(DateTime(2026, 9, 9));
    expect((await transactions.all(drafts: true)).single.status, 'draft');
  });

  test('an expense that would go below the floor becomes a draft', () async {
    await internet(amount: 20000);
    await rules.catchUp(DateTime(2026, 9, 9));
    expect((await transactions.all(drafts: true)).single.status, 'draft');
    expect(await balance(mpesa), 10000);
  });

  test('another currency: the latest rate, or a draft without one', () async {
    final franc = await accounts.create(
      name: 'Espèces',
      type: AccountType.cash,
      opening: const Money(10000000, 'CDF'),
      openingDate: DateTime.utc(2026),
    );
    await rules.create(
      kind: EntryKind.expense,
      accountId: franc,
      categoryId: 'default-internet',
      amount: const Money(1000, 'USD'),
      unit: RepeatUnit.month,
      start: DateTime(2026, 9, 8),
    );
    await rules.catchUp(DateTime(2026, 9, 9));
    expect((await transactions.all(drafts: true)).single.status, 'draft');
    await CurrencyRepository(db).setRate('USD', 'CDF', RateValue.parse('2800'));
    await rules.catchUp(DateTime(2026, 10, 9));
    final october = (await transactions.all()).single;
    expect(october.total.total, Money.fromMajor('28000', currencyOf('CDF')));
  });

  test('a transfer each month moves money between accounts', () async {
    await rules.create(
      kind: EntryKind.transfer,
      accountId: mpesa,
      toAccountId: savings,
      amount: const Money(1000, 'USD'),
      unit: RepeatUnit.month,
      start: DateTime(2026, 10, 1),
    );
    await rules.catchUp(DateTime(2026, 11, 1));
    expect(await balance(savings), 2000);
  });

  test('stopping keeps what was made, and drops the drafts waiting', () async {
    final id = await internet(asDraft: true);
    await rules.catchUp(DateTime(2026, 10, 9));
    await transactions.validate((await transactions.all(drafts: true)).last.id);
    await rules.stop(id);
    final left = await transactions.all(drafts: true);
    expect(left.length, 1);
    expect(left.single.status, 'done');
    expect(await rules.catchUp(DateTime(2027, 1, 1)), 0);
  });

  test('an end after three times', () async {
    await rules.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-internet',
      amount: const Money(100, 'USD'),
      unit: RepeatUnit.month,
      start: DateTime(2026, 1, 8),
      endCount: 3,
    );
    expect(await rules.catchUp(DateTime(2026, 11, 18)), 3);
  });
}
