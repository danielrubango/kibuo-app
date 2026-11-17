import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/search_history.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';
import 'package:kibuo/ui/transactions/search_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late String mpesa;
  late String bank;
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month);
  final today = DateTime(now.year, now.month, now.day, 9);
  final lastMonth = DateTime(now.year, now.month - 1, 12, 9);

  Future<void> add(
    EntryKind kind,
    String account,
    String cat,
    int minor,
    DateTime date, {
    String? note,
  }) => data.transactions.create(
    kind: kind,
    accountId: account,
    categoryId: cat,
    paid: Money(minor, 'USD'),
    fees: 0,
    date: date,
    note: note,
  );

  setUp(() async {
    OperationsScreen.forget();
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
    );
    await data.currencies.ensurePrimaryCurrency('US');
    final start = DateTime.utc(now.year - 1);
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: start,
    );
    bank = await data.accounts.create(
      name: 'Rawbank',
      type: AccountType.bank,
      opening: const Money(100000, 'USD'),
      openingDate: start,
    );
    await add(EntryKind.income, bank, 'default-salary', 120000, today);
    await add(EntryKind.expense, mpesa, 'default-taxi', 50000, today);
    await add(
      EntryKind.expense,
      bank,
      'default-rent',
      8800,
      today,
      note: 'Anniversaire maman',
    );
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester, {DateTime? month}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: SearchScreen(
          data: data,
          month: month ?? thisMonth,
          history: SearchHistory(db),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String q) async {
    await tester.enterText(find.byType(TextField), q);
    await tester.pumpAndSettle();
  }

  int rows(WidgetTester tester) => find.byType(OperationRow).evaluate().length;

  testWidgets('before typing: search by the month’s categories and accounts', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Recherches récentes'), findsNothing);
    expect(find.text('Chercher par'), findsOneWidget);
    for (final name in ['Transport', 'Logement', 'Salaire', 'Rawbank']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    await tester.tap(find.text('Transport'));
    await tester.pumpAndSettle();
    expect(rows(tester), 1);
  });

  testWidgets('without accents or capitals, in name, category or note', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'TAXI');
    expect(rows(tester), 1);
    expect(find.text('1 résultat'), findsOneWidget);
    await type(tester, 'logement');
    expect(rows(tester), 1, reason: 'the rent, by its category');
    await type(tester, 'maman');
    expect(rows(tester), 1, reason: 'the rent, by its note');
    expect(find.textContaining('Anniversaire'), findsWidgets);
  });

  testWidgets('a number is an amount, not a piece of one', (tester) async {
    await open(tester);
    await type(tester, '500');
    expect(rows(tester), 1, reason: 'the taxi, 500,00');
    await type(tester, '88,00');
    expect(rows(tester), 1, reason: 'the rent');
    await type(tester, '50');
    expect(rows(tester), 0);
    expect(find.text('Aucun résultat pour « 50 »'), findsOneWidget);
    await tester.tap(find.text('Effacer la recherche'));
    await tester.pumpAndSettle();
    expect(find.text('Chercher par'), findsOneWidget);
  });

  testWidgets('the other months wait under a dashed card', (tester) async {
    await add(EntryKind.expense, mpesa, 'default-taxi', 700, lastMonth);
    await open(tester);
    await type(tester, 'taxi');
    expect(rows(tester), 1);
    expect(find.text('1 autre résultat'), findsOneWidget);
    expect(find.text('Dans les mois précédents'), findsOneWidget);
    await tester.tap(find.text('1 autre résultat'));
    await tester.pumpAndSettle();
    expect(rows(tester), 2);
    expect(find.text('Mois précédents · 1'), findsOneWidget);
    await tester.tap(find.text('Replier'));
    await tester.pumpAndSettle();
    expect(rows(tester), 1);
  });

  testWidgets('nothing in the shown month: the others open by themselves', (
    tester,
  ) async {
    await add(EntryKind.expense, mpesa, 'default-water', 700, lastMonth);
    await open(tester);
    await type(tester, 'eau');
    expect(find.textContaining('Rien en'), findsOneWidget);
    expect(rows(tester), 1);
  });

  testWidgets('from an earlier month, the later ones are « autres »', (
    tester,
  ) async {
    await add(EntryKind.expense, mpesa, 'default-taxi', 700, lastMonth);
    await open(tester, month: DateTime(lastMonth.year, lastMonth.month));
    await type(tester, 'taxi');
    expect(rows(tester), 1);
    expect(find.text('Dans les autres mois'), findsOneWidget);
  });

  testWidgets('an opened result is remembered, and « Effacer » forgets', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'Taxi');
    await tester.tap(find.byType(OperationRow));
    await tester.pumpAndSettle();
    expect(await SearchHistory(db).recent(), ['Taxi']);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await type(tester, '');
    expect(find.text('Recherches récentes'), findsOneWidget);
    await tester.tap(find.text('Effacer'));
    await tester.pumpAndSettle();
    expect(find.text('Recherches récentes'), findsNothing);
    expect(await SearchHistory(db).recent(), isEmpty);
  });
}
