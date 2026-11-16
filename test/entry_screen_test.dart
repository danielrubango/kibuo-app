import 'dart:typed_data';

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
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/attachment_viewer.dart';
import 'package:kibuo/ui/transactions/attachments_card.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_screens.dart';

String plain(String s) => s.replaceAll(RegExp('[\\u00A0\\u202F]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) =>
      w is Text && plain(w.data ?? w.textSpan?.toPlainText() ?? '') == wanted,
);

class _FakeOpener implements AttachmentOpener {
  final opened = <String>[];

  @override
  Future<PdfFirstPage?> firstPage(Uint8List pdf) async => null;

  @override
  Future<bool> openWith(Uint8List bytes, String name) async {
    opened.add(name);
    return true;
  }
}

class _FakePicker implements AttachmentPicker {
  @override
  Future<PickedAttachment?> pick(AttachmentSource source) async =>
      PickedAttachment(
        bytes: Uint8List.fromList(List.filled(2048, 7)),
        name: source == AttachmentSource.file ? 'Facture.pdf' : null,
        kind: source == AttachmentSource.file
            ? AttachmentKind.pdf
            : AttachmentKind.file,
      );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late _FakeOpener opener;
  String? saved;
  final now = DateTime(2026, 11, 15, 15, 45);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    opener = _FakeOpener();
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      picker: _FakePicker(),
      opener: opener,
    );
    await data.currencies.ensurePrimaryCurrency('US');
    await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(12000, 'USD'),
      openingDate: DateTime.utc(2026, 11, 1),
    );
    saved = null;
  });
  tearDown(() => db.close());

  Future<void> start(
    WidgetTester tester, {
    EntryKind kind = EntryKind.expense,
  }) async {
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
                onPressed: () async {
                  saved = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) =>
                          EntryScreen(data: data, kind: kind, now: () => now),
                    ),
                  );
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String keys) async {
    for (final k in keys.split(' ')) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
  }

  Future<void> chooseTaxi(WidgetTester tester) async {
    await tester.tap(find.text('Catégorie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taxi'));
    await tester.pumpAndSettle();
  }

  testWidgets('an expense in the account’s currency', (tester) async {
    await start(tester);
    expect(find.text('Nouvelle dépense'), findsOneWidget);

    await type(tester, '5');
    expect(textPlain('−5'), findsOneWidget);
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.text('Enregistrer')).style?.color,
      isNot(Colors.black),
    );
    await chooseTaxi(tester);
    expect(find.text('Transport › Taxi'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final t = (await data.transactions.all()).single;
    expect(saved, t.id);
    expect(t.paid, const Money(500, 'USD'));
    expect(t.categoryId, 'default-taxi');
    expect(t.date, now.toUtc());
  });

  testWidgets('without a category, nothing is saved', (tester) async {
    await start(tester);
    await type(tester, '5');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle dépense'), findsOneWidget);
    expect(await data.transactions.all(), isEmpty);
  });

  testWidgets('paid in francs at today’s rate, then with fees', (tester) async {
    await data.currencies.addCurrency('CDF');
    await data.currencies.setRate('USD', 'CDF', RateValue.parse('2800'));
    await start(tester);

    await tester.tap(find.text('\$'));
    await tester.pumpAndSettle();
    expect(find.text('Devise payée'), findsOneWidget);
    await tester.tap(find.text('Franc congolais'));
    await tester.pumpAndSettle();
    await type(tester, '1 4 000');
    expect(textPlain('5,00 \$'), findsOneWidget, reason: 'Retiré du compte');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Frais').last);
    await tester.pumpAndSettle();
    expect(find.text('Frais supplémentaires'), findsOneWidget);
    await type(tester, '0 , 2 0');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    expect(textPlain('5,20 \$'), findsOneWidget);

    await chooseTaxi(tester);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final t = (await data.transactions.all()).single;
    expect(t.paid, const Money(1400000, 'CDF'));
    expect(t.total.total, const Money(520, 'USD'));
    expect(t.rateTyped, isFalse);
  });

  testWidgets('the changer’s rate, typed for this expense only', (
    tester,
  ) async {
    await data.currencies.addCurrency('CDF');
    await data.currencies.setRate('USD', 'CDF', RateValue.parse('2800'));
    await start(tester);

    await tester.tap(find.text('\$'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Franc congolais'));
    await tester.pumpAndSettle();
    await type(tester, '1 4 000');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retiré du compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taux pour 1 \$'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autre taux'));
    await tester.pumpAndSettle();
    await type(tester, '2 8 5 0');
    await tester.tap(find.text('Terminé').last);
    await tester.pumpAndSettle();
    await chooseTaxi(tester);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final t = (await data.transactions.all()).single;
    expect(t.rateTyped, isTrue);
    expect(t.rate!.value, RateValue.parse('2850'));
    final today = await data.currencies.latestRate('USD', 'CDF');
    expect(today!.rate.value, RateValue.parse('2800'), reason: 'Devises keeps');
  });

  testWidgets('an income, its own categories and wording', (tester) async {
    await start(tester);
    await tester.tap(find.text('Revenu'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau revenu'), findsOneWidget);
    expect(find.text('Ajouté au compte'), findsOneWidget);
    await type(tester, '9 0');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catégorie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salaire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final t = (await data.transactions.all()).single;
    expect(t.kind, EntryKind.income);
    final account = (await data.accounts.accounts()).single;
    expect(account.balance, const Money(12000 + 9000, 'USD'));
  });

  testWidgets('saved: the recap sheet, « Annuler et modifier », the detail', (
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
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    runEntry(context, data, kind: EntryKind.expense),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await type(tester, '5');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await chooseTaxi(tester);
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dépense enregistrée'), findsOneWidget);
    await tester.tap(find.text('Annuler et modifier'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier la dépense'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(await data.transactions.all(), hasLength(1), reason: 'kept');

    final t = (await data.transactions.all()).single;
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: OperationDetailScreen(data: data, id: t.id),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Taxi'), findsOneWidget);
    expect(textPlain('−5,00 \$'), findsOneWidget);
    expect(find.text('Dupliquer'), findsOneWidget);
  });

  Future<void> host(
    WidgetTester tester, {
    EntryKind kind = EntryKind.expense,
  }) async {
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
                onPressed: () => runEntry(context, data, kind: kind),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('without an account, a sheet explains, then the account', (
    tester,
  ) async {
    final only = (await data.accounts.accounts()).single;
    await data.accounts.archive(only.id);
    await host(tester);

    expect(find.text('D’abord, un compte'), findsOneWidget);
    expect(find.text('Nouvelle dépense'), findsNothing);
    await tester.tap(find.text('Créer mon premier compte'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau compte'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Poche');
    await tester.tap(find.text('Créer le compte'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle dépense'), findsOneWidget);
    expect(find.text('Poche'), findsOneWidget, reason: 'already chosen');
  });

  testWidgets('« Plus tard » opens no entry', (tester) async {
    final only = (await data.accounts.accounts()).single;
    await data.accounts.archive(only.id);
    await host(tester);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle dépense'), findsNothing);
    expect(find.text('ouvrir'), findsOneWidget);
  });

  testWidgets('without a category, the same sheet for a category', (
    tester,
  ) async {
    for (final c in await data.categories.categories(CategoryKind.out)) {
      await data.categories.remove(c.id);
    }
    await host(tester);

    expect(find.text('D’abord, une catégorie'), findsOneWidget);
    await tester.tap(find.text('Créer une catégorie'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle catégorie'), findsOneWidget);
  });

  Future<void> openDetail(WidgetTester tester, String id) async {
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
                    builder: (_) => OperationDetailScreen(data: data, id: id),
                  ),
                ),
                child: const Text('liste'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('liste'));
    await tester.pumpAndSettle();
  }

  Future<String> taxi() async => data.transactions.create(
    kind: EntryKind.expense,
    accountId: (await data.accounts.accounts()).single.id,
    categoryId: 'default-taxi',
    paid: const Money(500, 'USD'),
    fees: 0,
    date: now,
  );

  testWidgets('editing keeps the rate frozen when it was saved', (
    tester,
  ) async {
    await data.currencies.addCurrency('CDF');
    await data.currencies.setRate('USD', 'CDF', RateValue.parse('2800'));
    final id = await data.transactions.create(
      kind: EntryKind.expense,
      accountId: (await data.accounts.accounts()).single.id,
      categoryId: 'default-taxi',
      paid: const Money(1400000, 'CDF'),
      rate: ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        value: RateValue.parse('2800'),
      ),
      fees: 0,
      date: now,
    );
    // Devises gets a newer rate after the expense was saved.
    await data.currencies.setRate('USD', 'CDF', RateValue.parse('3000'));

    await openDetail(tester, id);
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();

    final saved = (await data.transactions.all()).single;
    expect(saved.total.converted, const Money(500, 'USD'));
    expect(saved.rate!.value, RateValue.parse('2800'));
  });

  testWidgets('the detail › « Supprimer l’opération », once confirmed', (
    tester,
  ) async {
    await openDetail(tester, await taxi());

    await tester.scrollUntilVisible(
      find.text('Supprimer l’opération'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Supprimer l’opération'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer cette dépense ?'), findsOneWidget);
    expect(
      textPlain(
        'Elle disparaît de la liste et le solde de M-Pesa reprend 5,00 \$.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();

    expect(await data.transactions.all(), isEmpty);
    expect(find.text('liste'), findsOneWidget, reason: 'back to the list');
  });

  testWidgets('closing the confirmation with ✕ keeps it', (tester) async {
    await openDetail(tester, await taxi());
    await tester.scrollUntilVisible(
      find.text('Supprimer l’opération'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Supprimer l’opération'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();

    expect(await data.transactions.all(), hasLength(1));
    expect(find.text('Dupliquer'), findsOneWidget, reason: 'still the detail');
  });

  testWidgets('attachments wait for « Enregistrer », then belong to it', (
    tester,
  ) async {
    await start(tester);
    await type(tester, '5');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await chooseTaxi(tester);
    await tester.scrollUntilVisible(
      find.text('Ajouter une pièce jointe'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ajouter une pièce jointe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir un fichier'));
    await tester.pumpAndSettle();
    expect(find.text('Facture.pdf'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);

    // Its preview opens it, without choosing it.
    await tester.tap(find.bySemanticsLabel('Voir'));
    await tester.pumpAndSettle();
    expect(find.text('Ouvrir avec…'), findsOneWidget);
    Navigator.of(tester.element(find.text('Ouvrir avec…'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('1 choisie'), findsNothing);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    final t = (await data.transactions.all()).single;
    expect((await data.attachments.list(t.id)).single.name, 'Facture.pdf');
  });

  testWidgets('chosen attachments are removed with the bar', (tester) async {
    await start(tester);
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ajouter une pièce jointe'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ajouter une pièce jointe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prendre une photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo 1'));
    await tester.pumpAndSettle();
    expect(find.text('1 choisie'), findsOneWidget);
    expect(find.text('Voir'), findsOneWidget);
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();

    expect(find.text('Photo 1'), findsNothing);
    expect(find.text('Ajouter une pièce jointe'), findsOneWidget);
  });

  testWidgets('in the detail, attachments are only shown', (tester) async {
    final empty = await taxi();
    await openDetail(tester, empty);
    expect(find.text('Pièces jointes'), findsNothing);
    await tester.pumpWidget(const SizedBox());

    final id = await taxi();
    await data.attachments.add(
      transactionId: id,
      bytes: Uint8List.fromList(List.filled(100, 1)),
      name: 'Reçu',
      kind: AttachmentKind.file,
    );
    await openDetail(tester, id);
    await tester.scrollUntilVisible(
      find.text('Reçu'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Ajouter'), findsNothing);
    await tester.tap(find.text('Reçu'));
    await tester.pumpAndSettle();
    expect(find.text('1 choisie'), findsNothing);

    // The viewer: nothing to change, only « Ouvrir avec… ».
    expect(find.text('Retirer'), findsNothing);
    await tester.tap(find.text('Ouvrir avec…'));
    await tester.pumpAndSettle();
    expect(opener.opened, ['Reçu']);
    expect((await data.attachments.list(id)).single.name, 'Reçu');
  });

  group('transfers', () {
    Future<Map<String, Money>> balances() async => {
      for (final a in await data.accounts.accounts()) a.name: a.balance,
    };

    Future<void> addAccount(String name, String currency) async {
      await data.currencies.addCurrency(currency);
      await data.accounts.create(
        name: name,
        type: AccountType.savings,
        opening: Money(0, currency),
        openingDate: DateTime.utc(2026, 11, 1),
      );
    }

    testWidgets('with one account only, a sheet asks for a second', (
      tester,
    ) async {
      await host(tester, kind: EntryKind.transfer);

      expect(find.text('D’abord, un deuxième compte'), findsOneWidget);
      expect(find.text('Nouveau transfert'), findsNothing);
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Épargne');
      await tester.tap(find.text('Créer le compte'));
      await tester.pumpAndSettle();

      expect(find.text('Nouveau transfert'), findsOneWidget);
    });

    testWidgets('between two accounts in dollars', (tester) async {
      await addAccount('Épargne', 'USD');
      await start(tester, kind: EntryKind.transfer);
      expect(find.text('Nouveau transfert'), findsOneWidget);
      expect(find.text('Catégorie'), findsNothing, reason: 'no category');

      await type(tester, '5 0');
      await tester.tap(find.text('Terminé'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(
        await data.transactions.all(),
        isEmpty,
        reason: '« Vers » is not chosen for you',
      );

      await tester.tap(find.text('Vers'));
      await tester.pumpAndSettle();
      expect(find.text('Vers quel compte ?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('M-Pesa'),
        ),
        findsNothing,
        reason: 'not to the account it leaves',
      );
      await tester.tap(find.text('Épargne'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final b = await balances();
      expect(b['M-Pesa'], const Money(7000, 'USD'));
      expect(b['Épargne'], const Money(5000, 'USD'));
      expect((await data.transactions.all()).single.kind, EntryKind.transfer);
    });

    testWidgets('to francs, at today’s rate, with fees', (tester) async {
      await addAccount('Portefeuille', 'CDF');
      await data.currencies.setRate('USD', 'CDF', RateValue.parse('2800'));
      await start(tester, kind: EntryKind.transfer);

      await type(tester, '5 0');
      await tester.tap(find.text('Terminé'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portefeuille'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Retiré de M-Pesa'));
      await tester.pumpAndSettle();
      expect(find.text('Arrive sur Portefeuille'), findsOneWidget);
      expect(textPlain('140 000 FC'), findsWidgets);

      await tester.tap(find.text('Frais').last);
      await tester.pumpAndSettle();
      await type(tester, '1');
      await tester.tap(find.text('Terminé').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      final b = await balances();
      expect(b['M-Pesa'], const Money(6900, 'USD'), reason: '120 − 50 − 1');
      expect(b['Portefeuille'], const Money(14000000, 'CDF'));
    });

    testWidgets('the detail: « Vers », both accounts, then deleting', (
      tester,
    ) async {
      await addAccount('Épargne', 'USD');
      final from = (await data.accounts.accounts()).first.id;
      final to = (await data.accounts.accounts()).last.id;
      final id = await data.transactions.createTransfer(
        fromId: from,
        toId: to,
        sent: const Money(5000, 'USD'),
        fees: 0,
        date: now,
      );
      await openDetail(tester, id);

      expect(find.text('Vers Épargne'), findsOneWidget);
      expect(find.text('Transfert'), findsOneWidget);
      expect(find.text('Depuis'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Supprimer l’opération'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Supprimer l’opération'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer ce transfert ?'), findsOneWidget);
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();

      final b = await balances();
      expect(b['M-Pesa'], const Money(12000, 'USD'));
      expect(b['Épargne'], const Money(0, 'USD'));
    });
  });

  group('overdraft', () {
    testWidgets('above what is left, a red line and no save', (tester) async {
      await start(tester);
      await type(tester, '1 5 0');
      await tester.tap(find.text('Terminé'));
      await tester.pumpAndSettle();
      await chooseTaxi(tester);

      expect(textPlain('120,00 \$ disponibles sur M-Pesa'), findsOneWidget);
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(await data.transactions.all(), isEmpty);
    });

    testWidgets('« Autoriser » opens the account, then it saves', (
      tester,
    ) async {
      await start(tester);
      await type(tester, '1 5 0');
      await tester.tap(find.text('Terminé'));
      await tester.pumpAndSettle();
      await chooseTaxi(tester);

      await tester.tap(find.text('Autoriser'));
      await tester.pumpAndSettle();
      expect(find.text('Modifier le compte'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Autoriser le découvert'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.textContaining('disponibles sur'), findsNothing);
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      final m = (await data.accounts.accounts()).single;
      expect(m.balance, const Money(-3000, 'USD'));
      expect(m.overdraft.unlimited, isTrue, reason: 'no limit typed');
    });

    testWidgets('deleting an income the balance needs is refused', (
      tester,
    ) async {
      final mpesa = (await data.accounts.accounts()).single.id;
      final salary = await data.transactions.create(
        kind: EntryKind.income,
        accountId: mpesa,
        categoryId: 'default-salary',
        paid: const Money(9000, 'USD'),
        fees: 0,
        date: now,
      );
      await data.transactions.create(
        kind: EntryKind.expense,
        accountId: mpesa,
        categoryId: 'default-taxi',
        paid: const Money(17000, 'USD'),
        fees: 0,
        date: now,
      );
      await openDetail(tester, salary);
      await tester.scrollUntilVisible(
        find.text('Supprimer l’opération'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Supprimer l’opération'));
      await tester.pumpAndSettle();

      expect(textPlain('M-Pesa passerait à −50,00 \$'), findsOneWidget);
      expect(find.text('Supprimer'), findsNothing);
      expect(find.text('Autoriser le découvert'), findsOneWidget);
    });
  });
}
