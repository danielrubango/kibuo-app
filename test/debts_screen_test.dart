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
import 'package:kibuo/data/hint_store.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/obligations/debts_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late DebtRepository debts;
  late String mpesa;
  final now = DateTime(2026, 11, 9, 15);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    debts = DebtRepository(db);
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(10000, 'USD'),
      openingDate: DateTime.utc(2026),
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

  Future<void> show(WidgetTester tester, {HintStore? hints}) async {
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
        home: DebtsScreen(
          data: data,
          debts: debts,
          prefs: PreferenceStore(db),
          hints: hints,
          now: () => now,
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('a new debt, borrowed on M-Pesa, joins its month', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('Aucune dette'), findsOneWidget);
    await tester.tap(find.text('Nouvelle dette'));
    await settle(tester);
    expect(find.text('À qui je dois'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Patrick');
    await tester.tap(find.text('Montant'));
    await settle(tester);
    for (final k in ['2', '0', '0']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    await tester.tap(find.text('Terminé'));
    await settle(tester);
    expect(find.text('M-Pesa, le solde sera mis à jour'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    // Not settled: the sheet's bar runs for six seconds.
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Dette enregistrée'), findsOneWidget);
    // It closes by itself.
    await tester.pump(const Duration(seconds: 7));
    await settle(tester);
    expect(find.text('Dette enregistrée'), findsNothing);
    expect(find.text('Patrick'), findsOneWidget);
    expect(find.text('Sans échéance'), findsWidgets);
    final account = (await data.accounts.accounts()).single;
    expect(account.balance, const Money(30000, 'USD'));
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('late on top in red words, a month, then no date', (
    tester,
  ) async {
    Future<void> add(String name, int amount, DateTime? due) => debts.create(
      direction: DebtDirection.owe,
      person: name,
      amount: Money(amount, 'USD'),
      openedOn: DateTime(2026, 10, 1),
      due: due,
    );
    await add('Oncle Jean', 1000, DateTime(2026, 11, 2));
    await add('Kevin', 1000, DateTime(2026, 11, 9));
    await add('Amani', 4000, DateTime(2026, 11, 11));
    await add('Patrick Mukendi', 2500, DateTime(2026, 11, 28));
    await add('Marie', 2000, null);
    await debts.create(
      direction: DebtDirection.owed,
      person: 'Grâce',
      amount: const Money(2500, 'USD'),
      openedOn: DateTime(2026, 11, 1),
      due: DateTime(2026, 11, 15),
      accountId: mpesa,
    );
    await show(tester);
    expect(find.text('1 en retard'), findsOneWidget);
    String usd(int minor) =>
        formatMoney(Money(minor, 'USD'), currencyOf('USD'), 'fr');
    expect(find.text(usd(10500)), findsOneWidget);
    expect(find.text('En retard'), findsOneWidget);
    expect(find.text('En retard de 7 jours'), findsOneWidget);
    expect(find.text('Novembre'), findsOneWidget);
    expect(find.text(usd(7500)), findsOneWidget);
    expect(find.text('Aujourd’hui'), findsOneWidget);
    expect(find.text('Après-demain'), findsOneWidget);
    expect(find.text('Dans 19 jours'), findsOneWidget);
    expect(find.text('Sans échéance'), findsWidgets);
    expect(find.text('Grâce'), findsNothing);
    await tester.tap(find.text('Oncle Jean'));
    await settle(tester);
    expect(find.text('Échéance dépassée : lundi 2 novembre'), findsWidgets);
    expect(find.text('Rien remboursé pour l’instant.'), findsWidgets);
    // Open, it covers the lines below without moving them; a touch on
    // the veil only closes it.
    await tester.tapAt(const Offset(200, 800));
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);
    expect(find.text('Rien remboursé pour l’instant.'), findsNothing);
    await tester.tap(find.text('Kevin'));
    await settle(tester);
    expect(find.text('Échéance : aujourd’hui, lundi 9 novembre'), findsWidgets);
    // The tabs too: the first touch closes, the next one switches.
    await tester.tap(find.text('On me doit'));
    await settle(tester);
    expect(find.text('Grâce'), findsNothing);
    await tester.tap(find.text('On me doit'));
    await settle(tester);
    expect(find.text('Grâce'), findsOneWidget);
    expect(find.text('Dans 6 jours'), findsOneWidget);
  });

  testWidgets('the guide shows once, then « Essayer » opens a line', (
    tester,
  ) async {
    await debts.create(
      direction: DebtDirection.owe,
      person: 'Kevin',
      amount: const Money(1000, 'USD'),
      openedOn: DateTime(2026, 11, 1),
      due: DateTime(2026, 11, 20),
    );
    final hints = HintStore(db);
    await show(tester, hints: hints);
    expect(find.text('1 sur 2'), findsOneWidget);
    expect(find.text('Chaque ligne, une personne'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await settle(tester);
    expect(find.text('Touchez pour le détail'), findsOneWidget);
    await tester.tap(find.text('Essayer'));
    await settle(tester);
    expect(find.text('Touchez pour le détail'), findsNothing);
    expect(find.text('Échéance : vendredi 20 novembre'), findsWidgets);
    expect(await hints.debtsCoachShown(), isTrue);
  });
}
