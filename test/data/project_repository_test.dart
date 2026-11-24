import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late ProjectRepository projects;
  late String mpesa;

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    projects = ProjectRepository(db);
    await CurrencyRepository(db).ensurePrimaryCurrency('US');
    mpesa = await AccountRepository(db).create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(50000, 'USD'),
      openingDate: DateTime.utc(2026),
    );
  });
  tearDown(() => db.close());

  test(
    'a new project: in its account\'s currency, nothing set aside',
    () async {
      final id = await projects.create(
        name: '  Voyage à Goma ',
        icon: 'airplane',
        accountId: mpesa,
        goal: 30000,
        startedOn: DateTime(2026, 11, 24),
        due: DateTime(2026, 12, 20),
        period: PlanPeriod.week,
      );
      final p = (await projects.projects()).single;
      expect(p.id, id);
      expect(p.name, 'Voyage à Goma');
      expect(p.goal, const Money(30000, 'USD'));
      expect(p.saved, const Money(0, 'USD'));
      expect(p.due, DateTime(2026, 12, 20));
      expect(p.period, PlanPeriod.week);
      expect(p.running, isTrue);
      expect(p.account, 'M-Pesa');
    },
  );

  test('what each account holds back, and what is free', () async {
    final id = await projects.create(
      name: 'Moto',
      icon: 'motorcycle',
      accountId: mpesa,
      goal: 80000,
      startedOn: DateTime(2026, 11, 1),
    );
    await projects.addContribution(
      id,
      amount: 20000,
      date: DateTime(2026, 11, 2),
    );
    await projects.addContribution(
      id,
      amount: -5000,
      date: DateTime(2026, 11, 3),
    );
    expect((await projects.projects()).single.saved, const Money(15000, 'USD'));
    expect(await projects.reserved(), {mpesa: 15000});
    expect(await projects.free(mpesa), const Money(35000, 'USD'));
  });

  group('the card and its money', () {
    late String rawbank;
    late String trip;

    setUp(() async {
      rawbank = await AccountRepository(db).create(
        name: 'Rawbank',
        type: AccountType.bank,
        opening: const Money(10000, 'USD'),
        openingDate: DateTime.utc(2026),
      );
      trip = await projects.create(
        name: 'Voyage',
        icon: 'airplane',
        accountId: rawbank,
        goal: 30000,
        startedOn: DateTime(2026, 11, 1),
        due: DateTime(2027, 1, 1),
      );
    });

    test('set aside on its own account: no operation, held back', () async {
      final ok = await projects.putAside(
        trip,
        amount: 6000,
        date: DateTime(2026, 11, 24),
      );
      expect(ok, isNotNull);
      expect((await projects.project(trip))!.saved.minor, 6000);
      expect((await projects.free(rawbank)).minor, 4000);
      expect(await TransactionRepository(db).all(), isEmpty);
      final line = (await projects.contributions(trip)).single;
      expect(line.from, equals(null));
      expect(line.account, 'Rawbank');
    });

    test('never more than what is free on the account', () async {
      final ok = await projects.putAside(
        trip,
        amount: 10001,
        date: DateTime(2026, 11, 24),
      );
      expect(ok, equals(null));
      expect(await projects.contributions(trip), isEmpty);
    });

    test('from another account: a transfer first, then the line', () async {
      final ok = await projects.putAside(
        trip,
        amount: 20000,
        date: DateTime(2026, 11, 24),
        fromAccountId: mpesa,
      );
      expect(ok?.transferId, isNotNull);
      final moved = (await TransactionRepository(db).all()).single;
      expect(moved.accountId, mpesa);
      expect(moved.toAccountId, rawbank);
      expect((await projects.free(rawbank)).minor, 10000);
      expect((await projects.free(mpesa)).minor, 30000);
      final line = (await projects.contributions(trip)).single;
      expect(line.from, 'M-Pesa');
      expect(line.account, 'Rawbank');
    });

    test('from another account, only what is free there', () async {
      final ok = await projects.putAside(
        trip,
        amount: 50001,
        date: DateTime(2026, 11, 24),
        fromAccountId: mpesa,
      );
      expect(ok, equals(null));
      expect(await TransactionRepository(db).all(), isEmpty);
    });

    test('taken back: never more than set aside, newest first', () async {
      await projects.putAside(trip, amount: 6000, date: DateTime(2026, 11, 2));
      expect(
        await projects.takeBack(
          trip,
          amount: 6001,
          date: DateTime(2026, 11, 3),
        ),
        equals(null),
      );
      expect(
        await projects.takeBack(
          trip,
          amount: 2000,
          date: DateTime(2026, 11, 3),
        ),
        isNotNull,
      );
      final lines = await projects.contributions(trip);
      expect(lines.map((c) => c.amount.minor), [-2000, 6000]);
      expect((await projects.free(rawbank)).minor, 6000);
    });

    test('ended: nothing held back any more, still readable', () async {
      await projects.putAside(trip, amount: 6000, date: DateTime(2026, 11, 2));
      await projects.end(trip, ending: 'released', on: DateTime(2026, 11, 4));
      final p = (await projects.project(trip))!;
      expect(p.running, isFalse);
      expect(p.ending, 'released');
      expect(p.endedOn, DateTime(2026, 11, 4));
      expect((await projects.free(rawbank)).minor, 10000);
    });

    test('changed: name, goal, date removed; account kept', () async {
      await projects.edit(
        trip,
        name: ' Goma ',
        icon: 'car',
        goal: 40000,
        due: null,
        period: PlanPeriod.month,
        remind: false,
        accountId: rawbank,
      );
      final p = (await projects.project(trip))!;
      expect(p.name, 'Goma');
      expect(p.icon, 'car');
      expect(p.goal.minor, 40000);
      expect(p.due, equals(null));
      expect(p.period, PlanPeriod.month);
      expect(p.remind, isFalse);
    });

    test('deleted with its lines: the money is free again', () async {
      await projects.putAside(trip, amount: 6000, date: DateTime(2026, 11, 2));
      await projects.delete(trip);
      expect(await projects.project(trip), equals(null));
      expect(await projects.projects(), isEmpty);
      expect((await projects.free(rawbank)).minor, 10000);
    });

    test('undone: the line goes, and its transfer with it', () async {
      final done = await projects.putAside(
        trip,
        amount: 20000,
        date: DateTime(2026, 11, 24),
        fromAccountId: mpesa,
      );
      await projects.undo(done!);
      expect(await projects.contributions(trip), isEmpty);
      expect(await TransactionRepository(db).all(), isEmpty);
      expect((await projects.free(mpesa)).minor, 50000);
    });

    test('reopened after being made available', () async {
      await projects.end(trip, ending: 'released', on: DateTime(2026, 11, 4));
      await projects.reopen(trip);
      final p = (await projects.project(trip))!;
      expect(p.running, isTrue);
      expect(p.endedOn, equals(null));
    });
  });
}
