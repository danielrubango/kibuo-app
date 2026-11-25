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
