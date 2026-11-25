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
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/todo_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/home/home_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late RecurringRepository rules;
  late BudgetRepository budgets;
  late String mpesa;
  final now = DateTime.now();
  // At midnight: never in the future, whatever the hour of the run.
  final today = DateTime(now.year, now.month, now.day);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    rules = RecurringRepository(db);
    budgets = BudgetRepository(db);
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      recurrences: rules,
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> start(WidgetTester tester, {double height = 2400}) async {
    tester.view.physicalSize = Size(1080, height);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Scaffold(
          body: HomeScreen(
            data: data,
            budgets: BudgetLoader(data, budgets),
            todos: TodoStore(db),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> toastGone(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
  }

  /// Internet, 30 $, made today as a draft by its recurrence.
  Future<String> draft({String note = 'Internet'}) async {
    final rule = await rules.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-internet',
      amount: const Money(3000, 'USD'),
      note: note,
      unit: RepeatUnit.month,
      start: today,
      asDraft: true,
    );
    await rules.catchUp(now);
    return (await data.transactions.all(drafts: true))
        .firstWhere((t) => t.recurringId == rule)
        .id;
  }

  testWidgets('drafts: their sheet, all checked, one left out', (tester) async {
    final a = await draft();
    final b = await draft(note: 'Loyer');
    await start(tester);
    expect(find.text('2 brouillons'), findsOneWidget);
    await tester.tap(find.text('Valider'));
    await settle(tester);
    expect(find.text('2 brouillons à valider'), findsOneWidget);
    expect(find.text('Valider les 2'), findsOneWidget);
    // The box of the first draft.
    final name = find.text('Internet').last;
    await tester.tapAt(
      Offset(tester.getTopLeft(name).dx - 28, tester.getCenter(name).dy),
    );
    await settle(tester);
    await tester.tap(find.text('Valider le brouillon'));
    await settle(tester);
    final statuses = {
      for (final t in await data.transactions.all(drafts: true)) t.id: t.status,
    };
    expect(statuses[b], 'done');
    expect(statuses[a], 'draft');
    expect(find.text('1 brouillon validé'), findsOneWidget);
    await toastGone(tester);
  });
}
