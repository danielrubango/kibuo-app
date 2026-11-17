import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/recurrences/recurrences_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late String mpesa;
  final now = DateTime(2026, 11, 15, 15, 45);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      recurrences: RecurringRepository(db),
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(12000, 'USD'),
      openingDate: DateTime.utc(2026, 11, 1),
    );
    await data.categories.categories(CategoryKind.out);
  });
  tearDown(() => db.close());

  Future<void> show(WidgetTester tester, Widget home) async {
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
        home: home,
      ),
    );
    await settle(tester);
  }

  testWidgets('« Répéter » in an entry: the operation is its first time', (
    tester,
  ) async {
    await show(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push<String>(
            MaterialPageRoute(
              builder: (_) => EntryScreen(
                data: data,
                kind: EntryKind.expense,
                now: () => now,
              ),
            ),
          ),
          child: const Text('ouvrir'),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await settle(tester);
    for (final k in ['3', '0']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catégorie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taxi'));
    await tester.pumpAndSettle();
    expect(
      find.text('Jamais'),
      findsOneWidget,
      reason: '« Répéter » by default',
    );
    await tester.tap(find.text('Répéter'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle récurrence'), findsOneWidget);
    expect(find.text('Le 15 de chaque mois, sans fin'), findsOneWidget);
    await tester.tap(find.widgetWithText(KibuoButton, 'Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Le 15 de chaque mois, sans fin'), findsOneWidget);
    await tester.tap(find.widgetWithText(KibuoButton, 'Enregistrer'));
    await settle(tester);

    final op = (await data.transactions.all()).single;
    final rule = (await data.recurrences!.rules()).single;
    expect(op.recurringId, rule.id);
    expect(rule.schedule.unit, RepeatUnit.month);
    // Not made again; next on 15 December.
    expect(await data.recurrences!.catchUp(DateTime(2026, 11, 20)), 0);
    expect(
      rule.next(after: DateTime(2026, 11, 15)).first,
      DateTime(2026, 12, 15),
    );
    // Today's is made: the next to come is next month's.
    expect(
      rule.upcoming(DateTime(2026, 11, 15, 18)).first,
      DateTime(2026, 12, 15),
    );
  });

  testWidgets('Récurrences by type; its card stops it', (tester) async {
    await data.recurrences!.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-internet',
      amount: const Money(3000, 'USD'),
      unit: RepeatUnit.month,
      start: DateTime(2026, 12, 8),
      asDraft: true,
    );
    await show(tester, RecurrencesScreen(data: data));
    expect(find.text('Dépenses · 1'), findsOneWidget);
    expect(find.text('Internet'), findsOneWidget);
    expect(find.text('À valider'), findsOneWidget);
    expect(find.text('Le 8 de chaque mois'), findsOneWidget);
    await tester.tap(find.text('Internet'));
    await settle(tester);
    expect(find.text('Le 8 de chaque mois, sans fin'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Arrêter la récurrence'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Arrêter la récurrence'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(KibuoButton, 'Arrêter'));
    await settle(tester);
    expect(find.text('Aucune récurrence pour l’instant'), findsOneWidget);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}
