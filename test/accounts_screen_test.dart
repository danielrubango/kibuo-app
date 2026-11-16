import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_type_screen.dart';
import 'package:kibuo/ui/accounts/accounts_screen.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

String plain(String s) => s.replaceAll(RegExp('[\\u00A0\\u202F]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) =>
      w is Text && plain(w.data ?? w.textSpan?.toPlainText() ?? '') == wanted,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late AccountRepository accounts;
  late CurrencyRepository currencies;
  final day = DateTime.utc(2026, 11, 3);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    accounts = AccountRepository(db);
    currencies = CurrencyRepository(db, now: () => DateTime.utc(2026, 11, 3));
    await currencies.ensurePrimaryCurrency('US');
  });
  tearDown(() => db.close());

  Future<void> start(
    WidgetTester tester, {
    Size screen = const Size(1080, 2400),
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'US')];
    tester.platformDispatcher.localeTestValue = const Locale('fr', 'US');
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('kibuo/device'),
      (call) async => 'US',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: AccountsScreen(
          accounts: accounts,
          currencies: currencies,
          categories: CategoryRepository(db),
          transactions: TransactionRepository(db),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
  }

  testWidgets('creating an account with its starting balance', (tester) async {
    await start(tester);

    await tester.tap(find.text('Ajouter un compte'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau compte'), findsOneWidget);
    await tester.tap(find.text('Banque'));
    await tester.enterText(find.byType(TextField), 'Rawbank');
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(
      find.descendant(of: find.byType(ValueField), matching: find.text('0')),
    );
    await tester.pumpAndSettle();
    expect(
      tester.testTextInput.isVisible,
      isFalse,
      reason: 'the phone keyboard gives way to Kibuo’s',
    );
    await type(tester, '120');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer le compte'));
    await tester.pumpAndSettle();

    expect(find.text('Rawbank'), findsOneWidget);
    expect(textPlain('120,00 \$'), findsWidgets);
    expect(find.text('Total de mes comptes'), findsOneWidget);
    final saved = (await accounts.accounts()).single;
    expect(saved.type, AccountType.bank);
    expect(saved.balance, const Money(12000, 'USD'));
  });

  testWidgets('touching the name closes Kibuo’s keypad', (tester) async {
    await start(tester);
    await tester.tap(find.text('Ajouter un compte'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(ValueField), matching: find.text('0')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(KeypadPanel), findsOneWidget);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      find.byType(KeypadPanel),
      findsNothing,
      reason: 'never both keyboards at once',
    );
  });

  testWidgets('on a small screen, the keypad never hides its field', (
    tester,
  ) async {
    await start(tester, screen: const Size(1080, 1500));
    await tester.tap(find.text('Ajouter un compte'));
    await tester.pumpAndSettle();
    final field = find.byType(ValueField);
    await tester.scrollUntilVisible(
      find.descendant(of: field, matching: find.text('0')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.descendant(of: field, matching: find.text('0')));
    await tester.pumpAndSettle();

    final keypadTop = tester.getTopLeft(find.byType(KeypadPanel)).dy;
    final amount = find.descendant(of: field, matching: find.text('0'));
    expect(tester.getBottomLeft(amount).dy, lessThanOrEqualTo(keypadTop));
  });

  testWidgets('an account needs a name', (tester) async {
    await start(tester);

    await tester.tap(find.text('Ajouter un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer le compte'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau compte'), findsOneWidget);
    expect(await accounts.accounts(), isEmpty);
  });

  testWidgets('touching an account edits it', (tester) async {
    await accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(12000, 'USD'),
      openingDate: day,
    );
    await start(tester);

    await tester.tap(find.text('M-Pesa'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier le compte'), findsOneWidget);
    expect(find.text('Solde de départ'), findsNothing);
    expect(find.text('Date du solde'), findsNothing);
    await tester.enterText(find.byType(TextField), 'M-Pesa dollars');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('M-Pesa dollars'), findsOneWidget);
  });

  testWidgets('archiving takes the account out of the list', (tester) async {
    await accounts.create(
      name: 'Ancien',
      type: AccountType.bank,
      opening: const Money(500, 'USD'),
      openingDate: day,
    );
    await start(tester);

    await tester.tap(find.text('Ancien'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Archiver le compte'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Archiver le compte'));
    await tester.pumpAndSettle();
    expect(find.text('Archiver Ancien ?'), findsOneWidget);
    expect(
      find.text(
        'Ancien quitte les listes et les totaux. Ses opérations restent.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Archiver le compte').last);
    await tester.pumpAndSettle();

    expect(find.text('Ancien'), findsNothing);
    expect((await accounts.accounts(archived: true)).single.name, 'Ancien');
  });

  testWidgets('a type of one’s own, with its icon', (tester) async {
    await start(tester);

    await tester.tap(find.text('Ajouter un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un autre type'));
    await tester.pumpAndSettle();
    expect(find.text('Nouveau type'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AccountTypeScreen),
        matching: find.byType(TextField),
      ),
      'Tontine',
    );
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('users'));
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Tontine'),
      findsOneWidget,
      reason: 'chosen for the new account',
    );
    expect((await accounts.types()).single.icon, 'users');
  });

  testWidgets('other currencies: an equivalent, and no rate left out', (
    tester,
  ) async {
    await currencies.addCurrency('CDF');
    await currencies.setRate('USD', 'CDF', RateValue.parse('2800'));
    await accounts.create(
      name: 'Airtel',
      type: AccountType.mobile,
      opening: const Money(8400000, 'CDF'),
      openingDate: day,
    );
    await accounts.create(
      name: 'Poche',
      type: AccountType.cash,
      opening: const Money(2000, 'USD'),
      openingDate: day,
    );
    await accounts.create(
      name: 'Compte euro',
      type: AccountType.bank,
      opening: const Money(1500, 'EUR'),
      openingDate: day,
    );
    await start(tester);

    expect(textPlain('50,00 \$'), findsWidgets, reason: '20 + 84 000 FC');
    expect(textPlain('CDF · ≈ 30,00 \$'), findsOneWidget);
    expect(
      textPlain('Sans taux, EUR ne compte pas dans le total.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Affichage des comptes'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Tout en'));
    await tester.pumpAndSettle();

    expect(textPlain('30,00 \$'), findsWidgets);
    expect(find.text('Pas de taux'), findsOneWidget);
  });

  testWidgets('the icons of a new type fill the width, six per row', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Ajouter un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un autre type'));
    await tester.pumpAndSettle();

    final screen = tester.getRect(find.byType(AccountTypeScreen));
    final first = tester.getRect(find.bySemanticsLabel('wallet'));
    final sixth = tester.getRect(find.bySemanticsLabel('house'));
    expect(first.left - screen.left, closeTo(16, 1));
    expect(screen.right - sixth.right, closeTo(16, 1));
    expect(first.width, closeTo(first.height, 1));
  });

  testWidgets('a new account offers your currencies, then « Autre devise »', (
    tester,
  ) async {
    await currencies.addCurrency('CDF');
    await start(tester);

    await tester.tap(find.text('Ajouter un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();

    expect(find.text('Franc congolais'), findsOneWidget);
    expect(find.text('Euro'), findsNothing, reason: 'not one of yours');
    await tester.tap(find.text('Autre devise…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Euro'));
    await tester.pumpAndSettle();

    expect(find.text('EUR'), findsOneWidget);
  });

  testWidgets('overdraft up to a limit, shown in the list', (tester) async {
    await accounts.create(
      name: 'Rawbank',
      type: AccountType.bank,
      opening: const Money(0, 'USD'),
      openingDate: day,
    );
    await start(tester);
    await tester.tap(find.text('Rawbank'));
    await tester.pumpAndSettle();

    expect(find.text('Jusqu’à'), findsNothing, reason: 'off at first');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sans limite'));
    await tester.pumpAndSettle();
    await type(tester, '100');
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    final o = (await accounts.accounts()).single.overdraft;
    expect(o.allowed, isTrue);
    expect(o.limit, 10000);
    expect(textPlain('USD · Découvert jusqu’à 100,00 \$'), findsOneWidget);
  });

  testWidgets('turning it off below zero warns, and is allowed', (
    tester,
  ) async {
    final id = await accounts.create(
      name: 'Rawbank',
      type: AccountType.bank,
      opening: const Money(0, 'USD'),
      openingDate: day,
      overdraft: const Overdraft(allowed: true),
    );
    await TransactionRepository(db).create(
      kind: EntryKind.expense,
      accountId: id,
      categoryId: 'default-taxi',
      paid: const Money(2000, 'USD'),
      fees: 0,
      date: day,
    );
    await start(tester);
    expect(textPlain('USD · Découvert sans limite'), findsOneWidget);
    await tester.tap(find.text('Rawbank'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(
      textPlain(
        'Rawbank est à −20,00 \$ : aucune sortie ne passera tant qu’il ne '
        'sera pas remonté. Les entrées restent possibles.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect((await accounts.accounts()).single.overdraft.allowed, isFalse);
  });

  group('« Solde actuel »', () {
    Future<void> openMpesa(WidgetTester tester) async {
      await accounts.create(
        name: 'M-Pesa',
        type: AccountType.mobile,
        opening: const Money(12000, 'USD'),
        openingDate: day,
      );
      await start(tester);
      await tester.tap(find.text('M-Pesa'));
      await tester.pumpAndSettle();
    }

    Future<void> typeBalance(WidgetTester tester, String digits) async {
      await tester.tap(find.text('Solde actuel'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.bySemanticsLabel('Effacer').last);
        await tester.pump();
      }
      await type(tester, digits);
      await tester.tap(find.text('Terminé'));
      await tester.pumpAndSettle();
    }

    testWidgets('a lower balance adds a « Régularisation » expense', (
      tester,
    ) async {
      await openMpesa(tester);
      await typeBalance(tester, '100');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('Corriger le solde de M-Pesa ?'), findsOneWidget);
      expect(textPlain('−20,00 \$'), findsOneWidget);
      expect(find.text('Régularisation'), findsOneWidget);
      await tester.tap(find.text('Ajouter la régularisation'));
      await tester.pumpAndSettle();

      final m = (await accounts.accounts()).single;
      expect(m.balance, const Money(10000, 'USD'));
      final t = (await TransactionRepository(db).all()).single;
      expect(t.kind, EntryKind.expense);
      expect(t.categoryId, 'default-adjustExpense');
      expect(
        t.note!.replaceAll(RegExp('[\u00a0\u202f]'), ' '),
        'Solde corrigé : 120,00 \$ → 100,00 \$',
      );
    });

    testWidgets('closing the sheet saves nothing', (tester) async {
      await openMpesa(tester);
      await tester.enterText(find.byType(TextField), 'M-Pesa dollars');
      await typeBalance(tester, '150');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();

      expect(find.text('Modifier le compte'), findsOneWidget);
      final m = (await accounts.accounts()).single;
      expect(m.name, 'M-Pesa');
      expect(m.balance, const Money(12000, 'USD'));
    });
  });

  testWidgets('with « Code pour les actions importantes », archiving asks it', (
    tester,
  ) async {
    await accounts.create(
      name: 'Ancien',
      type: AccountType.cash,
      opening: const Money(0, 'USD'),
      openingDate: day,
    );
    final lock = LockController(
      vault: _MemoryVault(),
      biometrics: _NoBiometrics(),
      privacy: _NoPrivacy(),
    );
    await lock.pins.setPin('2468');
    await lock.load();
    await lock.updateSettings(
      lock.settings.copyWith(protectActions: true, shuffle: false),
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      KibuoLock(
        controller: lock,
        eraseAll: () async {},
        child: MaterialApp(
          theme: KibuoTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appLanguages,
          localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
          home: AccountsScreen(accounts: accounts, currencies: currencies),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ancien'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Archiver le compte'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Archiver le compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archiver le compte').last);
    await tester.pumpAndSettle();

    expect(find.text('Confirmez avec votre code'), findsOneWidget);
    expect(find.text('Pour archiver Ancien'), findsOneWidget);
    for (final d in '1111'.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pumpAndSettle();
    }
    expect(await accounts.accounts(archived: true), isEmpty);
    for (final d in '2468'.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pumpAndSettle();
    }
    expect((await accounts.accounts(archived: true)).single.name, 'Ancien');
  });
}

class _MemoryVault implements KeyVault {
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

class _NoBiometrics implements Biometrics {
  @override
  Future<bool> available() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}

class _NoPrivacy implements PrivacyPlatform {
  @override
  Future<bool> canHidePreview() async => true;

  @override
  Future<void> apply({
    required bool allowScreenshots,
    required bool hideInRecents,
    required bool androidCopy,
  }) async {}
}
