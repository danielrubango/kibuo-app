// Builds a backup filled with demonstration data, for the Google Play
// screenshots (backlog/fiche-google-play.md). Not part of the checks.
//
//   flutter test tool/demo_backup_test.dart
//
// The file lands in tool/screens_out/kibuo-demo.kibuo (ignored by git), to be
// restored on a test Android user with « J'ai une sauvegarde ». Every name is
// made up; the amounts are those of a household in Lubumbashi, November 2026.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/backup_file.dart';
import 'package:kibuo/data/budget_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';

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

final _rate = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  value: RateValue.parse('2850'),
);

DateTime _day(int month, int day, [int hour = 9, int minute = 0]) =>
    DateTime(2026, month, day, hour, minute);

Money _fc(int francs) => Money(francs * 100, 'CDF');

Money _usd(int dollars) => Money(dollars * 100, 'USD');

void main() {
  test('demonstration backup', () async {
    final folder = Directory.systemTemp.createTempSync('kibuo_demo_');
    final db = ((await openKibuoDatabase(
      folder: folder,
      vault: _MemoryVault(),
      inBackground: false,
    )) as Opened).database;
    try {
      await _fill(db);
      final out = File('tool/screens_out/kibuo-demo.kibuo');
      out.parent.createSync(recursive: true);
      if (out.existsSync()) out.deleteSync();
      await writeBackup(
        db,
        appFolder: folder,
        out: out,
        createdAt: DateTime(2026, 11, 26, 9),
        language: 'fr',
      );
      // ignore: avoid_print
      print('Written: ${out.path}');
    } finally {
      await db.close();
      folder.deleteSync(recursive: true);
    }
  });
}

Future<void> _fill(KibuoDatabase db) async {
  final currencies = CurrencyRepository(db);
  await currencies.setPrimaryCurrency('CDF');
  await currencies.addCurrency('USD');
  await currencies.setRate('USD', 'CDF', _rate.value);

  final accounts = AccountRepository(db);
  final opened = _day(10, 31);
  final cash = await accounts.create(
    name: 'Espèces',
    type: AccountType.cash,
    opening: _fc(560000),
    openingDate: opened,
  );
  final mpesa = await accounts.create(
    name: 'M-Pesa',
    type: AccountType.mobile,
    opening: _fc(420000),
    openingDate: opened,
  );
  final bank = await accounts.create(
    name: 'Rawbank',
    type: AccountType.bank,
    opening: _usd(640),
    openingDate: opened,
  );
  final savings = await accounts.create(
    name: 'Épargne',
    type: AccountType.savings,
    opening: _usd(900),
    openingDate: opened,
  );

  final moves = TransactionRepository(db);
  Future<void> add(
    EntryKind kind,
    String account,
    String category,
    Money paid,
    DateTime date, {
    String? note,
  }) => moves.create(
    kind: kind,
    accountId: account,
    categoryId: 'default-$category',
    paid: paid,
    fees: 0,
    date: date,
    note: note,
  );

  const out = EntryKind.expense;
  const into = EntryKind.income;
  await add(into, bank, 'salary', _usd(1100), _day(11, 1, 8, 10));
  await add(out, bank, 'rent', _usd(350), _day(11, 2, 9, 30), note: 'Loyer');
  await moves.createTransfer(
    fromId: bank,
    toId: mpesa,
    sent: _usd(200),
    fees: 0,
    date: _day(11, 3, 10, 5),
    rate: _rate,
    rateTyped: true,
  );
  await add(
    out,
    bank,
    'school',
    _usd(150),
    _day(11, 4, 11, 40),
    note: 'Minerval',
  );
  await add(out, cash, 'market', _fc(45000), _day(11, 5, 7, 45));
  await add(out, cash, 'taxi', _fc(8000), _day(11, 6, 18, 20));
  await add(out, mpesa, 'electricity', _fc(60000), _day(11, 7, 12, 15));
  await add(out, mpesa, 'airtime', _fc(10000), _day(11, 8, 16, 50));
  await add(out, cash, 'groceries', _fc(95000), _day(11, 9, 10, 30));
  await add(out, mpesa, 'water', _fc(25000), _day(11, 10, 13, 5));
  await add(out, cash, 'motoTaxi', _fc(3000), _day(11, 11, 8, 55));
  await add(out, cash, 'restaurant', _fc(35000), _day(11, 13, 19, 40));
  await add(into, mpesa, 'sale', _fc(250000), _day(11, 15, 15, 20));
  await add(out, cash, 'fuel', _fc(70000), _day(11, 16, 17, 10));
  await add(out, mpesa, 'family', _fc(50000), _day(11, 18, 11, 25));
  await add(out, cash, 'pharmacy', _fc(18000), _day(11, 19, 9, 45));
  await add(out, cash, 'contributions', _fc(20000), _day(11, 22, 10, 15));
  await add(out, mpesa, 'internet', _fc(30000), _day(11, 23, 20, 5));
  await add(out, cash, 'market', _fc(38000), _day(11, 24, 8, 30));
  await add(out, cash, 'taxi', _fc(6000), _day(11, 25, 18, 45));
  await add(out, cash, 'groceries', _fc(27500), _day(11, 26, 12, 40));

  final budgets = BudgetRepository(db);
  final month = monthKey(_day(11, 1));
  await budgets.create(
    categoryId: 'default-food',
    amount: _fc(300000),
    fromMonth: month,
  );
  await budgets.create(
    categoryId: 'default-transport',
    amount: _fc(120000),
    fromMonth: month,
  );
  await budgets.create(
    categoryId: 'default-communication',
    amount: _fc(45000),
    fromMonth: month,
  );
  await budgets.create(
    categoryId: 'default-outings',
    amount: _fc(60000),
    fromMonth: month,
  );

  final debts = DebtRepository(db);
  await debts.create(
    direction: DebtDirection.owe,
    person: 'Tonton Patrick',
    amount: _fc(150000),
    openedOn: _day(11, 12),
    due: _day(11, 30),
  );
  await debts.create(
    direction: DebtDirection.owe,
    person: 'Boutique Maman Rose',
    amount: _fc(35000),
    openedOn: _day(11, 14),
    due: _day(11, 28),
  );
  final grace = await debts.create(
    direction: DebtDirection.owed,
    person: 'Grâce',
    amount: _fc(80000),
    openedOn: _day(11, 2),
    due: _day(11, 20),
  );
  await debts.repay(
    grace,
    amount: _fc(20000),
    accountId: mpesa,
    date: _day(11, 17),
  );
  await debts.create(
    direction: DebtDirection.owed,
    person: 'Joël',
    amount: _usd(50),
    openedOn: _day(11, 21),
    due: _day(12, 15),
  );

  final projects = ProjectRepository(db);
  final trip = await projects.create(
    name: 'Voyage à Kinshasa',
    icon: 'airplane',
    accountId: savings,
    goal: _usd(800).minor,
    startedOn: _day(9, 1),
    due: _day(12, 20),
    period: PlanPeriod.month,
  );
  for (final (month, dollars) in [(9, 200), (10, 250), (11, 250)]) {
    await projects.addContribution(
      trip,
      amount: _usd(dollars).minor,
      date: _day(month, 1),
    );
  }
  final moto = await projects.create(
    name: 'Moto',
    icon: 'motorcycle',
    accountId: mpesa,
    goal: _fc(2500000).minor,
    startedOn: _day(8, 1),
    due: _day(6, 30).add(const Duration(days: 365)),
  );
  for (final (month, francs) in [
    (8, 250000),
    (9, 250000),
    (10, 300000),
    (11, 300000),
  ]) {
    await projects.addContribution(
      moto,
      amount: _fc(francs).minor,
      date: _day(month, 15),
    );
  }
  final school = await projects.create(
    name: 'Rentrée scolaire',
    icon: 'graduationCap',
    accountId: savings,
    goal: _usd(300).minor,
    startedOn: _day(11, 1),
    due: DateTime(2027, 8, 31),
    period: PlanPeriod.month,
  );
  await projects.addContribution(
    school,
    amount: _usd(60).minor,
    date: _day(11, 20),
  );

  final rules = RecurringRepository(db);
  await rules.create(
    kind: EntryKind.expense,
    accountId: bank,
    amount: _usd(350),
    unit: RepeatUnit.month,
    start: _day(12, 2),
    categoryId: 'default-rent',
    note: 'Loyer',
  );
  await rules.create(
    kind: EntryKind.income,
    accountId: bank,
    amount: _usd(1100),
    unit: RepeatUnit.month,
    start: _day(12, 1),
    categoryId: 'default-salary',
  );
}
