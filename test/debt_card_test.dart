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
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/obligations/debt_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late DebtRepository debts;
  late String mpesa;
  late String debt;
  final now = DateTime(2026, 11, 23, 15);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    debts = DebtRepository(db);
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      debts: debts,
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(10000, 'USD'),
      openingDate: DateTime.utc(2026),
    );
    debt = await debts.create(
      direction: DebtDirection.owe,
      person: 'Patrick',
      amount: const Money(20000, 'USD'),
      openedOn: DateTime(2026, 11, 1),
      due: DateTime(2026, 12, 5),
      accountId: mpesa,
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

  Future<void> show(WidgetTester tester) async {
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
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DebtScreen(
                      data: data,
                      debts: debts,
                      id: debt,
                      now: () => now,
                    ),
                  ),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await settle(tester);
  }

  testWidgets('the card, then paying back all that is left', (tester) async {
    await show(tester);
    expect(find.text('Je dois encore'), findsOneWidget);
    expect(find.text('Aucun remboursement pour l’instant.'), findsOneWidget);
    await tester.tap(find.text('Rembourser'));
    await settle(tester);
    expect(find.text('Rembourser Patrick'), findsOneWidget);
    expect(find.text('Plus tard'), findsOneWidget);
    await tester.tap(find.text('Rembourser').last);
    // Not settled: the confirmation closes by itself after six seconds.
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Dette soldée'), findsOneWidget);
    expect(find.text('Remboursé à Patrick'), findsOneWidget);
    expect(find.text('Annuler et modifier'), findsOneWidget);
    // From the card, no « Voir la dette ».
    expect(find.text('Voir la dette'), findsNothing);
    await tester.pump(const Duration(seconds: 7));
    await settle(tester);
    expect(find.text('M-Pesa'), findsOneWidget);
    expect((await debts.debts()).single.settled, isTrue);
    // Settled: nothing more to pay back.
    expect(find.text('Rembourser'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('deleting, from « Modifier », takes its operation', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text('Modifier'));
    await settle(tester);
    expect(find.text('Modifier la dette'), findsOneWidget);
    await tester.tap(find.text('Supprimer la dette'));
    await settle(tester);
    expect(
      find.text(
        'Son opération sera aussi supprimée, et le solde de son compte '
        'reviendra comme avant.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Supprimer la dette').last);
    await settle(tester);
    expect(await debts.debts(), isEmpty);
    expect(await data.transactions.all(), isEmpty);
    expect(find.text('ouvrir'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
