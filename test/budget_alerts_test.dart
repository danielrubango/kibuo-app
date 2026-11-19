import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/budget_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/budgets/budget_status.dart' show monthKey;
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/budgets/budget_alerts.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late BudgetAlerts alerts;
  late ReminderStore store;
  late String mpesa;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
    );
    store = ReminderStore(db);
    alerts = BudgetAlerts(
      loader: BudgetLoader(data, BudgetRepository(db)),
      store: store,
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
    await BudgetRepository(db).create(
      categoryId: 'default-food',
      amount: const Money(10000, 'USD'),
      fromMonth: monthKey(periodOf(now).month),
    );
  });
  tearDown(() => db.close());

  Future<void> spend(int minor) => data.transactions.create(
    kind: EntryKind.expense,
    accountId: mpesa,
    categoryId: 'default-food',
    paid: Money(minor, 'USD'),
    fees: 0,
    date: today,
  );

  String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');
  Finder said(String text) =>
      find.byWidgetPredicate((w) => w is Text && plain(w.data ?? '') == text);

  Future<void> check(WidgetTester tester, {bool settle = false}) async {
    await tester.tap(find.text(settle ? 'settle' : 'check'));
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  Future<void> start(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () => alerts.check(context, now),
                child: const Text('check'),
              ),
              TextButton(
                onPressed: () => alerts.settle(now),
                child: const Text('settle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> gone(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  }

  testWidgets('80 %: said once, then 100 % once', (tester) async {
    await start(tester);
    await tester.runAsync(() => spend(8500));
    await check(tester);
    expect(said('Repas à 85 % du budget · 15,00 \$ restants'), findsOneWidget);
    expect(find.text('Voir'), findsOneWidget);
    await gone(tester);
    await check(tester);
    expect(find.textContaining('Repas'), findsNothing);
    await tester.runAsync(() => spend(1900));
    await check(tester);
    expect(said('Repas dépassé de 4,00 \$'), findsOneWidget);
    await gone(tester);
  });

  testWidgets('at opening, what was crossed before is not said', (
    tester,
  ) async {
    await start(tester);
    await tester.runAsync(() => spend(9000));
    await check(tester, settle: true);
    await check(tester);
    expect(find.textContaining('Repas'), findsNothing);
  });

  testWidgets('the switch off: nothing', (tester) async {
    await start(tester);
    await tester.runAsync(() async {
      await store.setBudgetAt80(false);
      await spend(8500);
    });
    await check(tester);
    expect(find.textContaining('Repas'), findsNothing);
  });
}
