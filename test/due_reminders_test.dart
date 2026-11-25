import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations_fr.dart';
import 'package:kibuo/ui/reminders/reminder_planner.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

import 'reminders_test.dart' show FakeNotifier;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late ReminderStore store;
  late FakeNotifier notifier;
  late ReminderPlanner planner;
  late RecurringRepository rules;
  late String mpesa;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    store = ReminderStore(db);
    rules = RecurringRepository(db);
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      recurrences: rules,
      reminders: store,
    );
    notifier = FakeNotifier()..allow = true;
    planner = ReminderPlanner(
      store: store,
      notifier: notifier,
      transactions: data.transactions,
      data: data,
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(10000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
  });
  tearDown(() => db.close());

  Future<String> rent({required int minor, required int inDays}) =>
      rules.create(
        kind: EntryKind.expense,
        accountId: mpesa,
        categoryId: 'default-rent',
        amount: Money(minor, 'USD'),
        note: 'Loyer',
        unit: RepeatUnit.month,
        start: today.add(Duration(days: inDays)),
      );

  String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

  test('3 days before by default, at 9:00, to its card', () async {
    final id = await rent(minor: 2500, inDays: 5);
    await planner.refresh(AppLocalizationsFr(), now);
    final notice = notifier.scheduled.single;
    final due = today.add(const Duration(days: 5));
    expect(notice.at, DateTime(due.year, due.month, due.day - 3, 9));
    expect(notice.title, 'Loyer');
    expect(plain(notice.body), '25,00 \$ dans 3 jours, M-Pesa');
    expect(notice.payload, ReminderPlanner.rulePayload(id));
  });

  test('short: it says what will be missing', () async {
    await rent(minor: 15000, inDays: 5);
    await planner.refresh(AppLocalizationsFr(), now);
    expect(
      plain(notifier.scheduled.single.body),
      'Dans 3 jours : il manque 50,00 \$ sur M-Pesa',
    );
  });

  test('on the day: « aujourd’hui », to Accueil; « Aucun »: nothing', () async {
    final id = await rent(minor: 2500, inDays: 5);
    await store.setRuleDays(id, 0);
    await planner.refresh(AppLocalizationsFr(), now);
    expect(
      plain(notifier.scheduled.single.body),
      '25,00 \$ aujourd’hui, M-Pesa',
    );
    expect(notifier.scheduled.single.payload, ReminderPlanner.homePayload);
    await store.setRuleDays(id, -1);
    await planner.refresh(AppLocalizationsFr(), now);
    expect(notifier.scheduled, isEmpty);
  });

  test('the default turned off: only those with their own', () async {
    await rent(minor: 2500, inDays: 5);
    await store.setDueOn(false);
    await planner.refresh(AppLocalizationsFr(), now);
    expect(notifier.scheduled, isEmpty);
  });
}
