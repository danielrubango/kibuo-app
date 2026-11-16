import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late TransactionRepository repo;
  late AccountRepository accounts;
  late CurrencyRepository currencies;
  late String mpesa;
  final opened = DateTime.utc(2026, 11, 1);
  final day = DateTime.utc(2026, 11, 10, 15, 45);
  final rate = ExchangeRate(
    base: 'USD',
    quote: 'CDF',
    value: RateValue.parse('2800'),
  );

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    repo = TransactionRepository(db);
    accounts = AccountRepository(db);
    currencies = CurrencyRepository(db);
    await currencies.ensurePrimaryCurrency('US');
    mpesa = await accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(12000, 'USD'),
      openingDate: opened,
    );
  });
  tearDown(() => db.close());

  Future<String> expense({
    Money paid = const Money(500, 'USD'),
    ExchangeRate? rate,
    int fees = 0,
    DateTime? date,
    EntryKind kind = EntryKind.expense,
  }) => repo.create(
    kind: kind,
    accountId: mpesa,
    categoryId: 'default-taxi',
    paid: paid,
    rate: rate,
    fees: fees,
    date: date ?? day,
  );

  test('an expense is kept with what it took from the account', () async {
    final id = await expense();
    final t = (await repo.all()).single;
    expect(t.id, id);
    expect(t.kind, EntryKind.expense);
    expect(t.paid, const Money(500, 'USD'));
    expect(t.total.total, const Money(500, 'USD'));
    expect(t.date, day);
  });

  test('paid in francs: converted once, at the frozen rate', () async {
    await expense(paid: const Money(1400000, 'CDF'), rate: rate, fees: 20);
    await currencies.setRate('USD', 'CDF', RateValue.parse('3000'));

    final t = (await repo.all()).single;
    expect(t.total.converted, const Money(500, 'USD'));
    expect(t.total.total, const Money(520, 'USD'));
    expect(t.rate!.value, RateValue.parse('2800'));
    expect(await currencies.currencyCodes(), contains('CDF'));
  });

  test('changed, then deleted', () async {
    final id = await expense();
    await repo.update(
      id,
      kind: EntryKind.income,
      accountId: mpesa,
      categoryId: 'default-salary',
      paid: const Money(9000, 'USD'),
      fees: 0,
      date: day,
      note: 'Novembre',
    );
    final t = (await repo.get(id))!;
    expect(t.kind, EntryKind.income);
    expect(t.note, 'Novembre');

    await repo.delete(id);
    expect(await repo.all(), isEmpty);
  });

  test('newest first', () async {
    final older = await expense(date: DateTime.utc(2026, 11, 2));
    final newer = await expense(date: DateTime.utc(2026, 11, 9));
    expect([for (final t in await repo.all()) t.id], [newer, older]);
  });

  test('the account’s balance follows its operations from its date', () async {
    await expense(paid: const Money(1400000, 'CDF'), rate: rate, fees: 20);
    await expense(kind: EntryKind.income, paid: const Money(1000, 'USD'));
    await expense(
      date: DateTime.utc(2026, 10, 20),
      paid: const Money(99, 'USD'),
    );

    final account = (await accounts.accounts()).single;
    expect(
      account.balance,
      const Money(12000 - 520 + 1000, 'USD'),
      reason: 'the one before the starting date does not count',
    );
  });

  test('a currency used to pay stays among the user’s currencies', () async {
    await expense(paid: const Money(1400000, 'CDF'), rate: rate);
    expect(await currencies.whyKept('CDF'), const KeptForTransaction());
  });

  group('transfers', () {
    late String wallet;
    late String savings;

    setUp(() async {
      await currencies.addCurrency('CDF');
      wallet = await accounts.create(
        name: 'Portefeuille',
        type: AccountType.cash,
        opening: const Money(5600000, 'CDF'),
        openingDate: opened,
      );
      savings = await accounts.create(
        name: 'Épargne',
        type: AccountType.savings,
        opening: const Money(0, 'USD'),
        openingDate: opened,
      );
    });

    Future<Map<String, Money>> balances() async => {
      for (final a in await accounts.accounts()) a.id: a.balance,
    };

    test(
      'between two accounts in dollars: one loses, the other gains',
      () async {
        await repo.createTransfer(
          fromId: mpesa,
          toId: savings,
          sent: const Money(5000, 'USD'),
          fees: 20,
          date: day,
        );

        final b = await balances();
        expect(b[mpesa], const Money(6980, 'USD'), reason: '120 − 50 − 0,20');
        expect(b[savings], const Money(5000, 'USD'), reason: 'fees stay out');
      },
    );

    test('to francs: what arrived is converted once and kept', () async {
      final id = await repo.createTransfer(
        fromId: mpesa,
        toId: wallet,
        sent: const Money(5000, 'USD'),
        fees: 0,
        date: day,
        rate: ExchangeRate(
          base: 'USD',
          quote: 'CDF',
          value: RateValue.parse('2850'),
        ),
        rateTyped: true,
      );
      await currencies.setRate('USD', 'CDF', RateValue.parse('3000'));

      final t = (await repo.get(id))!;
      expect(t.kind, EntryKind.transfer);
      expect(t.categoryId, isNull);
      expect(t.toAccountId, wallet);
      expect(t.arrived, const Money(14250000, 'CDF'));
      expect(t.total.total, const Money(5000, 'USD'));
      expect((await balances())[wallet], const Money(19850000, 'CDF'));
    });

    test('changed, then deleted: both balances follow', () async {
      final id = await repo.createTransfer(
        fromId: mpesa,
        toId: savings,
        sent: const Money(5000, 'USD'),
        fees: 0,
        date: day,
      );
      await repo.updateTransfer(
        id,
        fromId: mpesa,
        toId: savings,
        sent: const Money(2000, 'USD'),
        fees: 0,
        date: day,
      );
      expect((await balances())[savings], const Money(2000, 'USD'));

      await repo.delete(id);
      final b = await balances();
      expect(b[mpesa], const Money(12000, 'USD'));
      expect(b[savings], const Money(0, 'USD'));
    });

    test(
      'before the receiving account’s start, it changes only the sender',
      () async {
        final late = await accounts.create(
          name: 'Rawbank',
          type: AccountType.bank,
          opening: const Money(10000, 'USD'),
          openingDate: DateTime.utc(2026, 11, 12),
        );
        await repo.createTransfer(
          fromId: mpesa,
          toId: late,
          sent: const Money(5000, 'USD'),
          fees: 0,
          date: day,
        );

        final b = await balances();
        expect(b[mpesa], const Money(7000, 'USD'));
        expect(
          b[late],
          const Money(10000, 'USD'),
          reason: 'counted in its start',
        );
      },
    );
  });
}
