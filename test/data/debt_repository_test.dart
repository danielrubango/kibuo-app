import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late DebtRepository debts;
  late AccountRepository accounts;
  late TransactionRepository transactions;
  late String mpesa;

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    debts = DebtRepository(db);
    accounts = AccountRepository(db);
    transactions = TransactionRepository(db);
    await CurrencyRepository(db).ensurePrimaryCurrency('US');
    mpesa = await accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(10000, 'USD'),
      openingDate: DateTime.utc(2026),
    );
  });
  tearDown(() => db.close());

  Future<Money> balance() async =>
      (await accounts.accounts()).singleWhere((a) => a.id == mpesa).balance;

  test('borrowed into an account: an entry marked « Dette »', () async {
    final id = await debts.create(
      direction: DebtDirection.owe,
      person: '  Patrick ',
      amount: const Money(20000, 'USD'),
      openedOn: DateTime(2026, 11, 23),
      due: DateTime(2026, 12, 5),
      accountId: mpesa,
    );
    expect(await balance(), const Money(30000, 'USD'));
    final op = (await transactions.all()).single;
    expect(op.kind, EntryKind.income);
    expect(op.debtId, id);
    expect(op.note, 'Patrick');
    expect(op.categoryId, debtCategoryId(owe: true, kind: CategoryKind.into));
    final line = (await debts.debts()).single;
    expect(line.person, 'Patrick');
    expect(line.direction, DebtDirection.owe);
    expect(line.left, const Money(20000, 'USD'));
    expect(line.due, DateTime(2026, 12, 5));
    expect(line.settled, isFalse);
  });

  test('lent from an account: an expense marked « Créance »', () async {
    await debts.create(
      direction: DebtDirection.owed,
      person: 'Grâce',
      amount: const Money(2500, 'USD'),
      openedOn: DateTime(2026, 11, 23),
      accountId: mpesa,
    );
    expect(await balance(), const Money(7500, 'USD'));
    final op = (await transactions.all()).single;
    expect(op.kind, EntryKind.expense);
    expect(op.categoryId, debtCategoryId(owe: false, kind: CategoryKind.out));
  });

  test('an old debt, without an account: no operation', () async {
    await debts.create(
      direction: DebtDirection.owe,
      person: 'Marie',
      amount: const Money(2000, 'USD'),
      openedOn: DateTime(2026, 11, 23),
    );
    expect(await transactions.all(), isEmpty);
    expect(await balance(), const Money(10000, 'USD'));
    expect((await debts.debts()).single.due, isNull);
  });

  test('in its own currency, converted for the account', () async {
    await debts.create(
      direction: DebtDirection.owed,
      person: 'Sarah',
      amount: const Money(2800000, 'CDF'),
      openedOn: DateTime(2026, 11, 23),
      accountId: mpesa,
      rate: ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        value: RateValue.parse('2800'),
      ),
    );
    expect(await balance(), const Money(9000, 'USD'));
    expect((await debts.debts()).single.left, const Money(2800000, 'CDF'));
  });

  test('its categories are never offered', () async {
    await debts.create(
      direction: DebtDirection.owe,
      person: 'Kevin',
      amount: const Money(1000, 'USD'),
      openedOn: DateTime(2026, 11, 23),
      accountId: mpesa,
    );
    final categories = CategoryRepository(db);
    final offered = [
      for (final kind in CategoryKind.values)
        for (final c in await categories.categories(kind)) c.id,
    ];
    expect(offered.where((id) => id.contains('debt')), isEmpty);
    final shown = await categories.category(
      debtCategoryId(owe: true, kind: CategoryKind.into),
    );
    expect(shown?.key, 'debtIn');
  });

  test('the names already used, the latest first, once each', () async {
    for (final name in ['Amani', 'Patrick', 'amani ', 'Kevin']) {
      await debts.create(
        direction: DebtDirection.owe,
        person: name,
        amount: const Money(1000, 'USD'),
        openedOn: DateTime(2026, 11, 23),
      );
    }
    expect(await debts.people(), ['Kevin', 'amani', 'Patrick']);
  });

  group('repaying', () {
    late String debt;
    setUp(() async {
      debt = await debts.create(
        direction: DebtDirection.owe,
        person: 'Patrick',
        amount: const Money(20000, 'USD'),
        openedOn: DateTime(2026, 11, 1),
        accountId: mpesa,
      );
    });

    test('a repayment leaves the account and lowers what is left', () async {
      await debts.repay(
        debt,
        amount: const Money(8000, 'USD'),
        accountId: mpesa,
        date: DateTime(2026, 11, 10),
      );
      final line = (await debts.debts()).single;
      expect(line.left, const Money(12000, 'USD'));
      expect(line.settled, isFalse);
      // 100 + 200 borrowed − 80 repaid.
      expect(await balance(), const Money(22000, 'USD'));
      final detail = (await debts.detail(debt))!;
      expect(detail.repayments.single.amount, const Money(8000, 'USD'));
      expect(detail.repayments.single.account, 'M-Pesa');
      expect(detail.openingAccountId, mpesa);
    });

    test('never more than what is left; reaching it settles', () async {
      expect(
        () => debts.repay(
          debt,
          amount: const Money(20001, 'USD'),
          accountId: mpesa,
          date: DateTime(2026, 11, 10),
        ),
        throwsArgumentError,
      );
      await debts.repay(
        debt,
        amount: const Money(20000, 'USD'),
        accountId: mpesa,
        date: DateTime(2026, 11, 12),
      );
      final line = (await debts.debts()).single;
      expect(line.settled, isTrue);
      expect(line.settledOn, DateTime(2026, 11, 12));
    });

    test('a receivable is paid back into the account', () async {
      final lent = await debts.create(
        direction: DebtDirection.owed,
        person: 'Grâce',
        amount: const Money(3000, 'USD'),
        openedOn: DateTime(2026, 11, 1),
        accountId: mpesa,
      );
      await debts.repay(
        lent,
        amount: const Money(1000, 'USD'),
        accountId: mpesa,
        date: DateTime(2026, 11, 5),
      );
      // 100 + 200 borrowed − 30 lent + 10 back.
      expect(await balance(), const Money(28000, 'USD'));
      final op = (await transactions.all()).firstWhere(
        (t) => t.debtId == lent && t.kind == EntryKind.income,
      );
      expect(
        op.categoryId,
        debtCategoryId(owe: false, kind: CategoryKind.into),
      );
    });

    test('editing: name, due date and amount, its operation follows', () async {
      await debts.repay(
        debt,
        amount: const Money(5000, 'USD'),
        accountId: mpesa,
        date: DateTime(2026, 11, 10),
      );
      expect(
        () => debts.edit(
          debt,
          person: 'Patrick',
          amount: const Money(4000, 'USD'),
        ),
        throwsArgumentError,
      );
      await debts.edit(
        debt,
        person: 'Patrick M.',
        amount: const Money(15000, 'USD'),
        due: DateTime(2026, 12, 5),
      );
      final line = (await debts.debts()).single;
      expect(line.person, 'Patrick M.');
      expect(line.amount, const Money(15000, 'USD'));
      expect(line.left, const Money(10000, 'USD'));
      expect(line.due, DateTime(2026, 12, 5));
      // 100 + 150 borrowed − 50 repaid.
      expect(await balance(), const Money(20000, 'USD'));
    });

    test('deleting takes its operations with it', () async {
      await debts.repay(
        debt,
        amount: const Money(5000, 'USD'),
        accountId: mpesa,
        date: DateTime(2026, 11, 10),
      );
      expect((await debts.detail(debt))!.operations, 2);
      await debts.delete(debt);
      expect(await debts.debts(), isEmpty);
      expect(await transactions.all(), isEmpty);
      expect(await balance(), const Money(10000, 'USD'));
    });
  });
}
