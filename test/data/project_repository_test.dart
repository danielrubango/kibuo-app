import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/project_repository.dart';
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
}
