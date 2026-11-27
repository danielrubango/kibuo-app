// Draws the built screens at 390 × 844, with the real fonts, to compare them
// with the validated mock-ups of the design canvas. Not part of the checks.
//
//   flutter test --update-goldens tool/capture_screens_test.dart
//
// Images land in tool/screens_out/ (ignored by git).
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/budget_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/accounts_screen.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/budgets/budget_book.dart';
import 'package:kibuo/ui/categories/categories_screen.dart';
import 'package:kibuo/ui/kit/design_system_screen.dart';
import 'package:kibuo/ui/lock/create_pin_screen.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/recovery_screens.dart';
import 'package:kibuo/ui/lock/unlock_screen.dart';
import 'package:kibuo/ui/overview/categories_card.dart';
import 'package:kibuo/ui/overview/overview_screen.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/settings/security_screens.dart';
import 'package:kibuo/ui/start/data_gate.dart';
import 'package:kibuo/ui/start/first_launch.dart';
import 'package:kibuo/ui/start/start_screen.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_screens.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';

class _Vault implements KeyVault {
  final values = <String, String>{};
  @override
  Future<String?> read(String name) async => values[name];
  @override
  Future<void> write(String name, String value) async => values[name] = value;
  @override
  Future<void> delete(String name) async => values.remove(name);
  @override
  Future<void> deleteAll() async => values.clear();
}

class _Bio implements Biometrics {
  @override
  Future<bool> available() async => true;
  @override
  Future<bool> authenticate(String reason) async => false;
}

class _Privacy implements PrivacyPlatform {
  @override
  Future<bool> canHidePreview() async => true;
  @override
  Future<void> apply({
    required bool allowScreenshots,
    required bool hideInRecents,
    required bool androidCopy,
  }) async {}
}

class _Recovery implements Recovery {
  @override
  Future<DateTime?> createdAt() async => DateTime(2026, 11, 15);
  @override
  Future<String> createCode() async => 'KB7Q4M2X9TPAH3WD';
  @override
  Future<bool> check(String typed) async => false;
}

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      loader.addFont(
        File(f).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  }

  await load('Inter', ['assets/fonts/Inter.ttf']);
  await load('PlusJakartaSans', ['assets/fonts/PlusJakartaSans.ttf']);
  await load('SpaceGrotesk', ['assets/fonts/SpaceGrotesk.ttf']);
  await load('PhosphorRegular', ['assets/icons/Phosphor.ttf']);
  await load('PhosphorBold', ['assets/icons/Phosphor-Bold.ttf']);
  await load('PhosphorFill', ['assets/icons/Phosphor-Fill.ttf']);
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  await load('MaterialIcons', [
    '${sdk.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  setUpAll(_loadFonts);

  Future<void> show(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    // The phone's status bar and gesture bar (24 each), as on the device,
    // so a button too close to the edge shows in the capture.
    tester.view.padding = const FakeViewPadding(top: 48, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 48);
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('kibuo/device'),
      (call) async => 'US',
    );
    // A new key per screen, so no sheet or route is left over from the last.
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        debugShowCheckedModeBanner: false,
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: home,
        builder: (context, child) => Stack(
          children: [
            child!,
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 24,
              child: IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: 108,
                    height: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0x660E1320),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // The green caret blinks forever: past a field, wait instead of settling.
  Future<void> snap(
    WidgetTester tester,
    String name, {
    bool settle = true,
  }) async {
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 400));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('screens_out/$name.png'),
    );
  }

  Future<LockController> lock({bool pin = true}) async {
    final c = LockController(
      vault: _Vault(),
      biometrics: _Bio(),
      privacy: _Privacy(),
      recovery: _Recovery(),
    );
    if (pin) await c.pins.setPin('2468');
    await c.load();
    await c.updateSettings(c.settings.copyWith(fingerprint: true));
    return c;
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
  }

  testWidgets('Design system', (tester) async {
    await show(tester, const DesignSystemScreen());
    await snap(tester, 'DesignSystem1');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2400));
    await snap(tester, 'DesignSystem2', settle: false);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1400));
    await snap(tester, 'DesignSystem3', settle: false);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
    await snap(tester, 'DesignSystem4', settle: false);
  });

  testWidgets('Devises, then the rate sheet', (tester) async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    addTearDown(db.close);
    var now = DateTime.utc(2026, 11, 3, 9);
    final repo = CurrencyRepository(db, now: () => now);
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('CDF');
    await repo.setRate('USD', 'CDF', RateValue.parse('2800'));
    await repo.addCurrency('EUR');
    await repo.setRate('USD', 'EUR', RateValue.parse('0.92'));
    now = DateTime.utc(2026, 11, 15, 9);
    await show(tester, CurrenciesScreen(repository: repo));
    await snap(tester, 'Devises');

    await tester.tap(find.text('Franc congolais, CDF'));
    await tester.pumpAndSettle();
    await type(tester, '2850');
    await snap(tester, 'TauxReglages');
  });

  testWidgets('Currency picker', (tester) async {
    await show(
      tester,
      const CurrencyPickerScreen(
        title: 'Votre devise principale',
        help:
            'Elle sert au suivi et aux rapports. Chaque compte gardera sa '
            'propre devise.',
        country: 'CD',
      ),
    );
    await snap(tester, 'Lancement2');
  });

  testWidgets('Security screens', (tester) async {
    final c = await lock();
    await show(tester, LockSettingsScreen(lock: c));
    await snap(tester, 'DelaiB');
    await tester.tap(find.text('Verrouiller après'));
    await snap(tester, 'DelaiB-feuille');
    await show(tester, PrivacyScreen(lock: c));
    await snap(tester, 'SecuConfid');
    await show(tester, RecoverySettingsScreen(lock: c));
    await snap(tester, 'RecupReglage');
  });

  testWidgets('Code screens', (tester) async {
    final c = await lock();
    await show(
      tester,
      KibuoLock(
        controller: c,
        eraseAll: () async {},
        child: UnlockScreen(controller: c, onUnlocked: () {}),
      ),
    );
    await type(tester, '2');
    await snap(tester, 'VerrouC2');
    await tester.tap(find.text('Code oublié ?'));
    await snap(tester, 'CodeOublie');

    final fresh = await lock(pin: false);
    await show(tester, CreatePinScreen(controller: fresh));
    await type(tester, '1357');
    await snap(tester, 'PinCreaC2');
    await show(tester, FingerprintOfferScreen(controller: fresh));
    await snap(tester, 'PinEmpreinte');
  });

  testWidgets('Recovery screens', (tester) async {
    await show(tester, const RecoveryShowScreen(code: 'KB7Q4M2X9TPAH3WD'));
    await snap(tester, 'CodeRecup');
    await show(
      tester,
      const RecoveryProofScreen(code: 'KB7Q4M2X9TPAH3WD', group: 3),
    );
    await tester.enterText(find.byType(TextField), '9TP');
    await snap(tester, 'RecupPreuve');
    await show(tester, RecoveryEntryScreen(onCode: (_) async => false));
    await tester.enterText(find.byType(TextField).first, 'KB7Q4M2X9TPAH3W');
    await snap(tester, 'RecupSaisie');
    await show(tester, UnreadableScreen(onStartOver: () {}, onRecover: () {}));
    await snap(tester, 'RecupIllisible');
  });

  testWidgets('Comptes', (tester) async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    addTearDown(db.close);
    final currencies = CurrencyRepository(
      db,
      now: () => DateTime.utc(2026, 11, 3),
    );
    await currencies.ensurePrimaryCurrency('US');
    await currencies.addCurrency('CDF');
    await currencies.setRate('USD', 'CDF', RateValue.parse('2800'));
    final accounts = AccountRepository(db);
    final day = DateTime.utc(2026, 11, 3);
    for (final (name, type, money) in [
      ('M-Pesa dollars', AccountType.mobile, const Money(20000, 'USD')),
      ('Airtel Money', AccountType.mobile, const Money(8400000, 'CDF')),
      ('Rawbank', AccountType.bank, const Money(93000, 'USD')),
      ('Poche', AccountType.cash, const Money(1850, 'USD')),
    ]) {
      await accounts.create(
        name: name,
        type: type,
        opening: money,
        openingDate: day,
      );
    }
    await show(
      tester,
      AccountsScreen(accounts: accounts, currencies: currencies),
    );
    await snap(tester, 'Comptes');
    await tester.tap(find.text('Rawbank'));
    await snap(tester, 'CompteModif');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solde de départ'));
    await tester.pump();
    for (final d in '120'.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await snap(tester, 'CompteNouveau', settle: false);
  });

  testWidgets('Catégories', (tester) async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    addTearDown(db.close);
    final repo = CategoryRepository(db);
    await show(tester, CategoriesScreen(categories: repo));
    await tester.tap(find.bySemanticsLabel('Transport · 5 sous-catégories'));
    await snap(tester, 'Categories');
    await tester.tap(find.text('Ajouter une sous-catégorie'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Train');
    await snap(tester, 'CatNouvelle');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Repas'));
    await snap(tester, 'CatModif');
  });

  testWidgets('Saisie', (tester) async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    addTearDown(db.close);
    final data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
    );
    await data.currencies.ensurePrimaryCurrency('US');
    await data.currencies.addCurrency('CDF');
    await data.currencies.setRate('USD', 'CDF', RateValue.parse('2800'));
    final mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(20000, 'USD'),
      openingDate: DateTime.utc(2026, 11, 1),
    );
    final id = await data.transactions.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-taxi',
      paid: const Money(1400000, 'CDF'),
      rate: ExchangeRate(
        base: 'USD',
        quote: 'CDF',
        value: RateValue.parse('2850'),
      ),
      rateTyped: true,
      fees: 20,
      date: DateTime.now().subtract(const Duration(minutes: 5)),
      note: 'Vers le marché de Gambela avec maman pour les courses.',
    );
    await data.transactions.create(
      kind: EntryKind.income,
      accountId: mpesa,
      categoryId: 'default-salary',
      paid: const Money(90000, 'USD'),
      fees: 0,
      date: DateTime.now().subtract(const Duration(days: 1)),
    );
    await show(
      tester,
      Scaffold(
        body: SafeArea(child: OperationsScreen(data: data)),
      ),
    );
    await snap(tester, 'Operations');
    for (final (name, kind) in [
      ('Reçu taxi.pdf', AttachmentKind.pdf),
      ('Facture.docx', AttachmentKind.file),
    ]) {
      await tester.runAsync(
        () => data.attachments.add(
          transactionId: id,
          bytes: Uint8List(27000),
          name: name,
          kind: kind,
        ),
      );
    }
    await show(tester, OperationDetailScreen(data: data, id: id));
    await snap(tester, 'OperationDetail');
    await tester.scrollUntilVisible(find.text('Facture.docx'), 200);
    await snap(tester, 'OperationDetailAttachments');
    await tester.tap(find.text('Reçu taxi.pdf'));
    await tester.pumpAndSettle();
    await snap(tester, 'AttachmentViewer');
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Supprimer l’opération'), 200);
    await tester.tap(find.text('Supprimer l’opération'));
    await tester.pumpAndSettle();
    await snap(tester, 'DeleteSheet');
    await show(
      tester,
      EntryScreen(
        data: data,
        kind: EntryKind.expense,
        initial: await data.transactions.get(id),
        editing: true,
      ),
    );
    await tester.tap(find.text('Retiré du compte'));
    await snap(tester, 'SaisieDecompte', settle: false);
    await show(tester, EntryScreen(data: data, kind: EntryKind.expense));
    await tester.tap(find.text('7').last);
    await snap(tester, 'SaisieNouvelle', settle: false);
  });

  testWidgets('Démarrage, image par image', (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: KibuoTheme.light(),
        home: const StartScreen(),
      ),
    );
    await tester.pump();
    var at = 0;
    for (final ms in [300, 480, 620, 1000]) {
      await tester.pump(Duration(milliseconds: ms - at));
      at = ms;
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('screens_out/demarrage_$ms.png'),
      );
    }
  });

  testWidgets('Aperçu', (tester) async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'ap');
    addTearDown(db.close);
    final data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      debts: DebtRepository(db),
      projects: ProjectRepository(db),
    );
    await data.currencies.ensurePrimaryCurrency('US');
    final mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(500000, 'USD'),
      openingDate: DateTime.utc(2025, 12),
    );
    // The canvas ApercuP2 is drawn on 12 November 2026 at 15 h.
    final now = DateTime(2026, 11, 12, 15, 20);
    var seed = 7;
    int next(int max) =>
        (seed = (seed * 1103515245 + 12345) & 0x7fffffff) % max;
    await db.transaction(() async {
      for (
        var d = DateTime(2025, 12);
        d.isBefore(now);
        d = DateTime(d.year, d.month, d.day + 1)
      ) {
        for (var k = 0; k < 1 + next(3); k++) {
          final at = DateTime(d.year, d.month, d.day, 7 + next(15), next(60));
          if (at.isAfter(now)) continue;
          await data.transactions.create(
            kind: EntryKind.expense,
            accountId: mpesa,
            categoryId: 'default-taxi',
            paid: Money(300 + next(2500), 'USD'),
            fees: 0,
            date: at,
          );
        }
        if (d.day == 1 || next(9) == 0) {
          await data.transactions.create(
            kind: EntryKind.income,
            accountId: mpesa,
            categoryId: 'default-salary',
            paid: Money(d.day == 1 ? 100000 : 3000 + next(9000), 'USD'),
            fees: 0,
            date: DateTime(d.year, d.month, d.day, 9),
          );
        }
      }
    });
    final taxi = await data.categories.category('default-taxi');
    await BudgetRepository(db).create(
      categoryId: taxi!.parentId ?? taxi.id,
      amount: const Money(45000, 'USD'),
      fromMonth: 202601,
    );
    await data.debts!.create(
      direction: DebtDirection.owe,
      person: 'Patrick',
      amount: const Money(17500, 'USD'),
      openedOn: DateTime(2026, 10),
      due: DateTime(2026, 11, 10),
      accountId: mpesa,
    );
    await data.debts!.create(
      direction: DebtDirection.owed,
      person: 'Grace',
      amount: const Money(9500, 'USD'),
      openedOn: DateTime(2026, 10, 15),
      due: DateTime(2026, 11, 20),
      accountId: mpesa,
    );
    final trip = await data.projects!.create(
      name: 'Voyage',
      icon: 'airplane',
      accountId: mpesa,
      goal: 50000,
      startedOn: DateTime(2026, 9),
      due: DateTime(2027, 3),
    );
    await data.projects!.putAside(
      trip,
      amount: 30000,
      date: DateTime(2026, 11, 5),
    );
    Future<void> open() => show(
      tester,
      Scaffold(
        body: SafeArea(
          child: OverviewScreen(
            data: data,
            clock: () => now,
            budgets: BudgetLoader(data, BudgetRepository(db)),
          ),
        ),
      ),
    );
    Future<void> tiles(String name) async {
      await tester.scrollUntilVisible(find.text('Suivre'), 300);
      await tester.drag(find.byType(ListView).first, const Offset(0, -260));
      await tester.pumpAndSettle();
      await snap(tester, name);
      await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
    }

    Future<void> choose(List<String> taps) async {
      await tester.tap(find.byIcon(KibuoIcons.caretDown));
      await tester.pumpAndSettle();
      for (final t in taps) {
        await tester.ensureVisible(find.text(t).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(t).last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Voir'));
      await tester.pumpAndSettle();
    }

    await open();
    await snap(tester, 'Apercu_mois');
    await tiles('Apercu_tuiles_mois');
    await tester.scrollUntilVisible(find.text('Suivre'), 300);
    await tester.tap(find.text('Suivre'));
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_suivre');
    for (final t in [
      'Épargne',
      'Moyenne',
      'Jour ou mois le plus cher',
      'À venir',
      'Patrimoine net',
    ]) {
      await tester.scrollUntilVisible(
        find.text(t).last,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text(t).last);
      await tester.pumpAndSettle();
    }
    await snap(tester, 'Apercu_suivre_tout');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('Voir les'), 300);
    await tester.tap(find.textContaining('Voir les'));
    await tester.pumpAndSettle();
    await tiles('Apercu_tuiles_mois_toutes');
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_tuiles_mois_bas');
    await tester.ensureVisible(find.text('Dépensé').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dépensé').first);
    await tester.pumpAndSettle();
    for (var i = 1; i <= 13; i++) {
      await snap(tester, 'Apercu_grand_${i.toString().padLeft(2, '0')}');
      if (i < 13) {
        await tester.drag(find.byType(PageView), const Offset(-330, 0));
        await tester.pumpAndSettle();
      }
    }
    await tester.tapAt(const Offset(20, 820));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(KibuoIcons.caretDown));
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_feuille');
    await tester.tap(find.text('Voir'));
    await tester.pumpAndSettle();
    await choose(['Bâtonnets']);
    await snap(tester, 'Apercu_batonnets');
    await tester.tap(find.text('Entrées'));
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_entrees');
    await tester.tap(find.text('Sorties'));
    await choose(['Courbe', 'Semaine']);
    await snap(tester, 'Apercu_semaines');
    await choose(['1 an']);
    await snap(tester, 'Apercu_an');
    await tiles('Apercu_an_tuiles');
    await choose(['Semaine']);
    await snap(tester, 'Apercu_an_semaines');
    await choose(['7 jours']);
    await snap(tester, 'Apercu_7jours');
    await tiles('Apercu_7jours_tuiles');
    await choose(['Aujourd’hui']);
    await snap(tester, 'Apercu_jour');
    await tiles('Apercu_jour_tuiles');
    await choose(['24 h']);
    await snap(tester, 'Apercu_24h');
    await tester.tap(find.byIcon(KibuoIcons.caretLeft));
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_24h_avant');
    await tester.tap(find.byIcon(KibuoIcons.caretDown));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Personnalisée'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personnalisée'));
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_perso_feuille');
    await tester.tap(find.text('Voir'));
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_perso');
    await tiles('Apercu_perso_tuiles');
    await tester.tap(find.byIcon(KibuoIcons.caretLeft));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(KibuoIcons.caretLeft));
    await tester.pumpAndSettle();
    await choose(['1 mois']);
    await tester.tap(find.byIcon(KibuoIcons.caretLeft));
    await tester.pumpAndSettle();
    await choose(['D’après']);
    await snap(tester, 'Apercu_octobre_apres');
    await tester.tap(find.text('Catégories'));
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_categories');
    final rest = find.textContaining('autres catégories');
    if (rest.evaluate().isNotEmpty) {
      await tester.ensureVisible(rest);
      await tester.pumpAndSettle();
      await tester.tap(rest);
      await tester.pumpAndSettle();
      await snap(tester, 'Apercu_categories_autres');
    }
    await tester.tap(
      find
          .descendant(
            of: find.byType(CategoriesCard),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_categorie_page');
    await tester.tap(find.byIcon(KibuoIcons.caretLeft).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrées'));
    await tester.pumpAndSettle();
    await snap(tester, 'Apercu_categories_entrees');
  });

  testWidgets('Premier lancement', (tester) async {
    final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'cap');
    addTearDown(db.close);
    await CurrencyRepository(db).ensurePrimaryCurrency('US');
    await show(
      tester,
      KibuoData(
        database: db,
        child: const FirstLaunchGate(child: Text('Accueil')),
      ),
    );
    await snap(tester, 'lancement_1');
    await tester.tap(find.text('Continuer'));
    await snap(tester, 'lancement_2');
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'M-Pesa');
    FocusManager.instance.primaryFocus?.unfocus();
    await snap(tester, 'lancement_3');
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await snap(tester, 'lancement_3_decouvert');
    await tester.tap(find.text('Continuer'));
    await snap(tester, 'lancement_4');
  });
}
