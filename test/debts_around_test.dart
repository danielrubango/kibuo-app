import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/l10n/app_localizations_fr.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/home/home_screen.dart';
import 'package:kibuo/ui/reminders/reminder_planner.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

import 'reminders_test.dart' show FakeNotifier;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late DebtRepository debts;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    debts = DebtRepository(db);
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      reminders: ReminderStore(db),
      debts: debts,
    );
    await data.currencies.ensurePrimaryCurrency('US');
    await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
    // Late, mine to pay; lent, late; due in five days.
    await debts.create(
      direction: DebtDirection.owe,
      person: 'Joseph',
      amount: const Money(1500, 'USD'),
      openedOn: today.subtract(const Duration(days: 20)),
      due: today.subtract(const Duration(days: 3)),
    );
    await debts.create(
      direction: DebtDirection.owed,
      person: 'Patience',
      amount: const Money(3000, 'USD'),
      openedOn: today.subtract(const Duration(days: 20)),
      due: today.subtract(const Duration(days: 5)),
    );
    await debts.create(
      direction: DebtDirection.owe,
      person: 'Amani',
      amount: const Money(4000, 'USD'),
      openedOn: today.subtract(const Duration(days: 2)),
      due: today.add(const Duration(days: 5)),
    );
  });
  tearDown(() => db.close());

  testWidgets('home: the two cards, À traiter and À venir', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    DebtDirection? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Scaffold(
          body: HomeScreen(data: data, onOpenDebts: (d) => opened = d),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Je dois'), findsOneWidget);
    expect(find.text('On me doit'), findsOneWidget);
    expect(find.textContaining('2 dettes'), findsOneWidget);
    // À traiter: the late ones, with their action.
    expect(find.text('Rembourser'), findsWidgets);
    expect(find.text('Réclamer'), findsOneWidget);
    // À venir: Amani's due date, as a planned one.
    expect(find.text('Rembourser Amani'), findsOneWidget);
    await tester.tap(find.text('On me doit'));
    expect(opened, DebtDirection.owed);
  });

  test('a debt\'s reminder, at the due dates\' delay by default', () async {
    final notifier = FakeNotifier()..allow = true;
    final store = ReminderStore(db);
    await store.setDueOn(true);
    final planner = ReminderPlanner(
      store: store,
      notifier: notifier,
      transactions: data.transactions,
      data: data,
    );
    await planner.refresh(AppLocalizationsFr(), now);
    final titles = [for (final n in notifier.scheduled) n.title];
    expect(titles.where((t) => t.startsWith('Rembourser Amani')), hasLength(1));
    // Late ones: no reminder in the past.
    expect(titles.where((t) => t.contains('Joseph')), isEmpty);
    // « Aucun » for this one: nothing.
    final amani = (await debts.debts()).firstWhere((d) => d.person == 'Amani');
    await store.setRuleDays(amani.id, -1);
    await planner.refresh(AppLocalizationsFr(), now);
    expect(notifier.scheduled.where((n) => n.title.contains('Amani')), isEmpty);
  });
}
