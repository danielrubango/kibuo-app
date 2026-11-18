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
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/domain/todo/todo.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/home/home_screen.dart';
import 'package:kibuo/ui/home/todo.dart';
import 'package:kibuo/ui/month_start.dart';
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

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
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

  Future<void> overBudget() async {
    await budgets.create(
      categoryId: 'default-outings',
      amount: const Money(1000, 'USD'),
      fromMonth: monthKey(periodOf(now).month),
    );
    await data.transactions.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-outings',
      paid: const Money(1200, 'USD'),
      fees: 0,
      date: today,
    );
  }

  testWidgets('nothing to do: no « À traiter »', (tester) async {
    await start(tester);
    expect(find.text('À traiter'), findsNothing);
    expect(find.text('À venir'), findsNothing);
  });

  testWidgets('a budget over: its line, in red, first', (tester) async {
    await draft();
    await overBudget();
    await start(tester);
    expect(find.text('À traiter'), findsOneWidget);
    expect(find.text('Sorties · 120 %'), findsOneWidget);
    expect(find.text('Budget dépassé'), findsOneWidget);
    expect(find.text('1 brouillon'), findsOneWidget);
    final budget = tester.getTopLeft(find.text('Sorties · 120 %')).dy;
    final drafts = tester.getTopLeft(find.text('1 brouillon')).dy;
    expect(budget, lessThan(drafts));
    expect(find.textContaining('Tout voir ·'), findsNothing);
  });

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

  testWidgets('one draft: « Valider ce brouillon ? »', (tester) async {
    final id = await draft();
    await start(tester);
    await tester.tap(find.text('Valider'));
    await settle(tester);
    expect(find.text('Valider ce brouillon ?'), findsOneWidget);
    await tester.tap(find.text('Valider').last);
    await settle(tester);
    expect((await data.transactions.get(id))!.status, 'done');
    expect(find.text('1 brouillon'), findsNothing);
    await toastGone(tester);
  });

  testWidgets('swiped past half: put off, with « Annuler »', (tester) async {
    await draft();
    await start(tester);
    await tester.drag(find.text('1 brouillon'), const Offset(-800, 0));
    await settle(tester);
    expect(find.text('1 brouillon'), findsNothing);
    expect(find.text('Reporté à demain : 1 brouillon'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await settle(tester);
    expect(find.text('1 brouillon'), findsOneWidget);
  });

  testWidgets('swiped a little: « Plus tard » stays, and puts off', (
    tester,
  ) async {
    await draft();
    await start(tester);
    await tester.drag(find.text('1 brouillon'), const Offset(-80, 0));
    await settle(tester);
    expect(find.text('1 brouillon'), findsOneWidget);
    await tester.tap(find.text('Plus tard'));
    await settle(tester);
    expect(find.text('1 brouillon'), findsNothing);
    expect(
      (await TodoStore(db).putOff()).visible(const [
        TodoItem(kind: TodoKind.drafts, key: 'drafts'),
      ], now),
      isEmpty,
    );
    await toastGone(tester);
  });

  testWidgets('more than 3: « Tout voir · 4 » opens the groups', (
    tester,
  ) async {
    await draft();
    await overBudget();
    for (final (cat, spent) in [
      ('default-food', 900),
      ('default-transport', 1100),
    ]) {
      await budgets.create(
        categoryId: cat,
        amount: const Money(1000, 'USD'),
        fromMonth: monthKey(periodOf(now).month),
      );
      await data.transactions.create(
        kind: EntryKind.expense,
        accountId: mpesa,
        categoryId: cat,
        paid: Money(spent, 'USD'),
        fees: 0,
        date: today,
      );
    }
    await start(tester);
    expect(find.text('Tout voir · 4'), findsOneWidget);
    await tester.tap(find.text('Tout voir · 4'));
    await settle(tester);
    expect(find.text('Urgent · 2'), findsOneWidget);
    expect(find.text('Cette semaine · 2'), findsOneWidget);
  });

  testWidgets('« À venir »: the next days’ recurrences, « Prévu »', (
    tester,
  ) async {
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    await rules.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-internet',
      amount: const Money(1500, 'USD'),
      unit: RepeatUnit.week,
      start: tomorrow,
    );
    await start(tester);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Prévu'), findsNWidgets(2));
  });

  testWidgets('an old rate: a reminder, 30 days on', (tester) async {
    await data.currencies.setRate('USD', 'CDF', RateValue.parse('2800'));
    await data.accounts.create(
      name: 'Cash',
      type: AccountType.cash,
      opening: const Money(100000, 'CDF'),
      openingDate: DateTime.utc(now.year - 1),
    );
    late List<HomeTodo> items;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        home: Builder(
          builder: (context) {
            final loader = TodoLoader(data: data);
            Future<void> load(DateTime at) async =>
                items = await loader.load(context, at);
            return TextButton(
              onPressed: () async {
                await load(now);
                expect(items, isEmpty);
                await load(now.add(const Duration(days: 31)));
              },
              child: const Text('go'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await settle(tester);
    expect(items.single.kind, TodoKind.oldRate);
    expect(items.single.rateDays, 31);
    expect(BudgetState.values, isNotEmpty);
  });
}
