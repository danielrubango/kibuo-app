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
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/budgets/budget_status.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/budgets/budgets_screen.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is RichText && plain(w.text.toPlainText()) == wanted,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late BudgetRepository budgets;
  final now = DateTime.now();
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
    await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
    // Seeds the provided categories.
    await data.categories.categories(CategoryKind.out);
  });
  tearDown(() => db.close());

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
