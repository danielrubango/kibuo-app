import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/overview/enlarged_parts.dart';
import 'package:kibuo/ui/overview/overview_screen.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is RichText && plain(w.text.toPlainText()) == wanted,
);

/// The Aperçu counts what the month totals of Opérations count (PRODUCT,
/// 27 November 2026), and follows each save.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late String mpesa;
  late String bank;
  final now = DateTime.now();
  // Early today, so the operations are never ahead of the clock.
  final today = DateTime(now.year, now.month, now.day);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'a');
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
    await data.transactions.create(
      kind: EntryKind.income,
      accountId: bank,
      categoryId: 'default-salary',
      paid: const Money(120000, 'USD'),
      fees: 0,
      date: today,
    );
    await data.transactions.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-taxi',
      paid: const Money(50000, 'USD'),
      fees: 0,
      date: today,
    );
    // Between my own accounts: only its fees go out.
    await data.transactions.createTransfer(
      fromId: mpesa,
      toId: bank,
      sent: const Money(3000, 'USD'),
      fees: 200,
      date: today,
    );
  });
  tearDown(() => db.close());

  testWidgets('I save an expense: Sorties of the Aperçu rises', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final saved = ValueNotifier(0);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Scaffold(
          body: OverviewScreen(data: data, refresh: saved),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Sorties, and the Dépensé tile under it.
    expect(textPlain('−502,00 \$'), findsWidgets, reason: 'taxi and fees');
    expect(textPlain('+1 200,00 \$'), findsWidgets);

    await data.transactions.create(
      kind: EntryKind.expense,
      accountId: bank,
      categoryId: 'default-rent',
      paid: const Money(8800, 'USD'),
      fees: 0,
      date: today,
    );
    saved.value++;
    await tester.pumpAndSettle();
    expect(textPlain('−590,00 \$'), findsWidgets);
    expect(textPlain('+1 200,00 \$'), findsWidgets);
  });

  testWidgets('I follow Épargne: its tile shows money in less money out', (
    tester,
  ) async {
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
        home: Scaffold(body: OverviewScreen(data: data)),
      ),
    );
    await tester.pumpAndSettle();
    expect(textPlain('+698,00 \$'), findsNothing);
    await tester.scrollUntilVisible(find.text('Suivre'), 200);
    await tester.tap(find.text('Suivre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Épargne'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    // 1 200 $ in, 500 $ of taxi and 2 $ of fees out.
    await tester.scrollUntilVisible(textPlain('+698,00 \$'), 200);
    expect(textPlain('+698,00 \$'), findsOneWidget);
  });

  testWidgets('I touch Dépensé: it opens large, the next tile follows', (
    tester,
  ) async {
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
        home: Scaffold(body: OverviewScreen(data: data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Dépensé').first, 200);
    await tester.tap(find.text('Dépensé').first);
    await tester.pumpAndSettle();
    // The month's spending, and where it goes: the taxi, under Transport.
    expect(find.textContaining('Dépensé · '), findsOneWidget);
    expect(find.text('Où ça part le plus'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(EnlargedCard),
        matching: find.text('Transport'),
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reçu · '), findsOneWidget);
    expect(find.text('Plus grosse entrée'), findsOneWidget);

    // A touch beside the card closes it.
    await tester.tapAt(const Offset(20, 860));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reçu · '), findsNothing);
  });

  testWidgets(
    'I open Catégories: Transport and the fees make the total, then its page',
    (tester) async {
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
          home: Scaffold(body: OverviewScreen(data: data)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Catégories'));
      await tester.pumpAndSettle();
      // 502 $ out: 500 $ of taxi, under Transport, and 2 $ of a transfer's
      // fees.
      expect(find.text('Où part mon argent'), findsOneWidget);
      expect(find.text('Transport'), findsOneWidget);
      expect(textPlain('−500,00 \$'), findsOneWidget);
      expect(find.text('Frais de transfert'), findsOneWidget);
      expect(textPlain('−2,00 \$'), findsOneWidget);

      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();
      // Its page: the taxi, its only operation.
      expect(find.text('Taxi'), findsWidgets);
      expect(find.textContaining('1 opération'), findsOneWidget);

      // The fees open too: the transfer, counted for its 2 $ of fees.
      await tester.tap(find.byIcon(KibuoIcons.caretLeft).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Frais de transfert'));
      await tester.pumpAndSettle();
      expect(textPlain('−2,00 \$'), findsOneWidget);
      expect(find.textContaining('frais :'), findsOneWidget);
    },
  );

  testWidgets('I open Patrimoine: what I have, and what each account did', (
    tester,
  ) async {
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
        home: Scaffold(body: OverviewScreen(data: data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Patrimoine'));
    await tester.pumpAndSettle();
    // 2 × 1 000 $ opened, +1 200 $ of salary, −500 $ of taxi, −2 $ of fees.
    // The total, and all of it available: no project, no debt.
    expect(textPlain('2 698,00 \$'), findsNWidgets(2));
    expect(find.textContaining('+698,00'), findsOneWidget);
    expect(find.textContaining('ce mois-ci'), findsOneWidget);
    // Rawbank: the salary and the transfer in; M-Pesa: the taxi, the
    // transfer out and its fees.
    expect(textPlain('+1 230,00 \$'), findsOneWidget);
    expect(textPlain('−532,00 \$'), findsOneWidget);

    // Its page (variant B, canvas CompteB): what M-Pesa has, what it lost
    // this month, and the transfer it sent, fees included.
    await tester.ensureVisible(find.text('M-Pesa'));
    await tester.tap(find.text('M-Pesa'));
    await tester.pumpAndSettle();
    expect(textPlain('468,00 \$'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            plain(w.text.toPlainText()) == '−532,00 \$ ce mois-ci',
      ),
      findsOneWidget,
    );
    expect(textPlain('−532,00 \$'), findsOneWidget, reason: 'Sorties');
    expect(textPlain('−500,00 \$'), findsOneWidget, reason: 'the taxi');
    expect(textPlain('−32,00 \$'), findsOneWidget, reason: 'the transfer');
  });
}
