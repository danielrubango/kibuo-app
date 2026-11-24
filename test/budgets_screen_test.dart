import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/budget_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/budgets/budgets_screen.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';

String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is RichText && plain(w.text.toPlainText()) == wanted,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late BudgetRepository budgets;
  late String mpesa;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 9);
  final month = monthKey(periodOf(now).month);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
    );
    budgets = BudgetRepository(db);
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
    // Seeds the provided categories.
    await data.categories.categories(CategoryKind.out);
  });
  tearDown(() => db.close());

  Future<void> spend(String category, int minor) => data.transactions.create(
    kind: EntryKind.expense,
    accountId: mpesa,
    categoryId: category,
    paid: Money(minor, 'USD'),
    fees: 0,
    date: today,
  );

  Future<void> start(WidgetTester tester) async {
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
        home: BudgetsScreen(
          loader: BudgetLoader(data, budgets),
          prefs: PreferenceStore(db),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('none yet: the empty card, no summary', (tester) async {
    await start(tester);
    expect(find.text('Aucun budget pour l’instant'), findsOneWidget);
    expect(find.text('Ajouter un budget'), findsOneWidget);
    expect(find.textContaining('restants'), findsNothing);
  });

  testWidgets('tiles: what is left, out of the amount; the month sums', (
    tester,
  ) async {
    await budgets.create(
      categoryId: 'default-food',
      amount: const Money(25000, 'USD'),
      fromMonth: month,
    );
    await budgets.create(
      categoryId: 'default-outings',
      amount: const Money(10000, 'USD'),
      fromMonth: month,
    );
    // A subcategory counts with its category.
    await spend('default-restaurant', 20500);
    await spend('default-outings', 10400);
    await start(tester);
    expect(textPlain('45,00 \$'), findsOneWidget);
    expect(textPlain('restants sur 250,00 \$'), findsOneWidget);
    expect(textPlain('−4,00 \$'), findsOneWidget);
    expect(textPlain('de trop sur 100,00 \$'), findsOneWidget);
    expect(find.text('104 %'), findsOneWidget);
    // 350 − 309
    expect(textPlain('41,00 \$ restants'), findsOneWidget);
    expect(textPlain('309,00 \$ sur 350,00 \$'), findsOneWidget);
    // « À surveiller »: Sorties first.
    expect(
      tester.getTopLeft(find.text('Sorties')).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.text('Repas')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Sorties')).dx,
      lessThan(tester.getTopLeft(find.text('Repas')).dx),
    );
  });

  testWidgets('the list groups budgets by state', (tester) async {
    await budgets.create(
      categoryId: 'default-outings',
      amount: const Money(10000, 'USD'),
      fromMonth: month,
    );
    await budgets.create(
      categoryId: 'default-health',
      amount: const Money(10000, 'USD'),
      fromMonth: month,
    );
    await spend('default-outings', 10400);
    await start(tester);
    await tester.tap(find.byTooltip('Affichage des budgets'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(DisplayChoice, 'Liste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    expect(textPlain('Dépassés · 1'), findsOneWidget);
    expect(textPlain('Dans les clous · 1'), findsOneWidget);
    expect(textPlain('104,00 \$ dépensés sur 100,00 \$'), findsOneWidget);
    expect(await PreferenceStore(db).read('budgets_layout'), 'list');
  });

  testWidgets('a new budget: category, amount, then it shows', (tester) async {
    await budgets.create(
      categoryId: 'default-outings',
      amount: const Money(10000, 'USD'),
      fromMonth: month,
    );
    await start(tester);
    await tester.tap(find.text('Ajouter un budget'));
    await settle(tester);
    expect(find.text('Nouveau budget'), findsOneWidget);
    for (final k in ['2', '0', '0']) {
      await tester.tap(find.text(k).last);
    }
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir'));
    await tester.pumpAndSettle();
    expect(find.text('Déjà un budget'), findsOneWidget, reason: 'Sorties');
    await tester.tap(find.text('Transport'));
    await settle(tester);
    await tester.tap(find.text('Créer le budget'));
    await settle(tester);
    expect(textPlain('restants sur 200,00 \$'), findsOneWidget);
    expect((await budgets.budgets()).length, 2);
  });

  testWidgets('deleted from « Modifier le budget », after its sheet', (
    tester,
  ) async {
    await budgets.create(
      categoryId: 'default-outings',
      amount: const Money(10000, 'USD'),
      fromMonth: month,
    );
    await start(tester);
    await tester.tap(find.text('Sorties'));
    await settle(tester);
    await tester.tap(find.text('Modifier'));
    await settle(tester);
    expect(find.text('Modifier le budget'), findsOneWidget);
    await tester.tap(find.text('Supprimer le budget'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer le budget Sorties ?'), findsOneWidget);
    expect(find.text('Les opérations ne changent pas.'), findsOneWidget);
    await tester.tap(find.widgetWithText(KibuoButton, 'Supprimer'));
    await settle(tester);
    expect(find.text('Aucun budget pour l’instant'), findsOneWidget);
    expect(await budgets.budgets(), isEmpty);
  });

  testWidgets('the detail: summary with its state, the month by day', (
    tester,
  ) async {
    await budgets.create(
      categoryId: 'default-food',
      amount: const Money(25000, 'USD'),
      fromMonth: month,
    );
    await spend('default-restaurant', 20500);
    await start(tester);
    await tester.tap(find.text('Repas'));
    await settle(tester);
    expect(find.text('Presque atteint'), findsOneWidget);
    expect(
      textPlain(
        'Novembre · budget 250,00 \$'.replaceFirst('Novembre', () {
          final m = DateFormat.MMMM('fr').format(periodOf(now).month);
          return m[0].toUpperCase() + m.substring(1);
        }()),
      ),
      findsOneWidget,
    );
    expect(textPlain('45,00 \$ restants'), findsOneWidget);
    expect(find.text('Au fil du mois'), findsOneWidget);
    expect(find.text('Aujourd’hui'), findsOneWidget, reason: 'the day');
    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('Repas · M-Pesa'), findsOneWidget);
    // Rythme: the gap to the pace, at today. 205 of 250 runs ahead of the
    // pace early in the month and leaves a margin late in it.
    await tester.tap(find.text('Rythme'));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp('d’avance|de marge')), findsOneWidget);
  });

  testWidgets('without any expense: said, and « Voir dans Opérations »', (
    tester,
  ) async {
    await budgets.create(
      categoryId: 'default-outings',
      amount: const Money(10000, 'USD'),
      fromMonth: month,
    );
    await start(tester);
    await tester.tap(find.text('Sorties'));
    await settle(tester);
    expect(
      find.text('Aucune dépense dans Sorties ce mois-ci.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Voir dans Opérations'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Voir dans Opérations'));
    await tester.pumpAndSettle();
    expect(OperationsScreen.show.value?.category, 'default-outings');
    expect(OperationsScreen.show.value?.month, periodOf(now).month);
  });
}

/// Database work happens outside the test's fake time.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
