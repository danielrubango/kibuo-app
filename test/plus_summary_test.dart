import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/app_version.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/budget_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/ui/more/plus_summary.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      projects: ProjectRepository(db),
      debts: DebtRepository(db),
      recurrences: RecurringRepository(db),
    );
    await data.currencies.ensurePrimaryCurrency('US');
  });
  tearDown(() => db.close());

  test('the version shown is the one in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: ([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
  });

  test('a new app: nothing yet, no total', () async {
    final s = await loadPlusSummary(db, data);
    expect(s.accounts, isNull);
    expect(s.budgets, 0);
    expect(s.projects, 0);
    expect(s.debts, 0);
    expect(s.recurrences, 0);
    expect(s.categories, greaterThan(0), reason: 'the default ones');
  });

  test('the accounts in the main currency, others at their rate; only what '
      'is still going on counts', () async {
    final usd = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(10000, 'USD'),
      openingDate: DateTime.utc(2026),
    );
    await data.currencies.setRate('USD', 'CDF', RateValue.parse('2800'));
    await data.accounts.create(
      name: 'Poche',
      type: AccountType.cash,
      opening: const Money(2800000, 'CDF'),
      openingDate: DateTime.utc(2026),
    );
    // 100,00 $ and 28 000 FC = 10,00 $.
    var s = await loadPlusSummary(db, data);
    expect(s.accounts, const Money(11000, 'USD'));

    await BudgetRepository(db).create(
      categoryId: 'default-food',
      amount: const Money(5000, 'USD'),
      fromMonth: monthKey(DateTime.now()),
    );
    final projects = ProjectRepository(db);
    await projects.create(
      name: 'Voyage',
      icon: 'airplane',
      accountId: usd,
      goal: 5000,
      startedOn: DateTime(2026, 11),
    );
    final ended = await projects.create(
      name: 'Vélo',
      icon: 'gift',
      accountId: usd,
      goal: 5000,
      startedOn: DateTime(2026, 11),
    );
    await projects.end(ended, ending: 'given_up', on: DateTime(2026, 11, 20));
    final debts = DebtRepository(db);
    await debts.create(
      direction: DebtDirection.owe,
      person: 'Joseph',
      amount: const Money(1500, 'USD'),
      openedOn: DateTime(2026, 11, 2),
    );
    final rules = RecurringRepository(db);
    await rules.create(
      kind: EntryKind.expense,
      accountId: usd,
      categoryId: 'default-food',
      amount: const Money(500, 'USD'),
      unit: RepeatUnit.month,
      start: DateTime(2026, 12),
    );
    final stopped = await rules.create(
      kind: EntryKind.expense,
      accountId: usd,
      categoryId: 'default-food',
      amount: const Money(500, 'USD'),
      unit: RepeatUnit.month,
      start: DateTime(2026, 12),
    );
    await rules.stop(stopped);

    s = await loadPlusSummary(db, data);
    expect(s.budgets, 1);
    expect(s.projects, 1);
    expect(s.debts, 1);
    expect(s.recurrences, 1);
    final categories = CategoryRepository(db);
    expect(
      s.categories,
      (await categories.categories(CategoryKind.out)).length +
          (await categories.categories(CategoryKind.into)).length,
    );
  });
}
