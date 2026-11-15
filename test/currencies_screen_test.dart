import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/settings/currency_screens.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is Text && w.data != null && plain(w.data!) == wanted,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late CurrencyRepository repo;
  var now = DateTime.utc(2026, 11, 3, 9);

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    now = DateTime.utc(2026, 11, 3, 9);
    repo = CurrencyRepository(db, now: () => now);
  });
  tearDown(() => db.close());

  Future<void> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr', 'US')];
    tester.platformDispatcher.localeTestValue = const Locale('fr', 'US');
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    // The phone says it is in the United States.
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('kibuo/device'),
      (call) async => 'US',
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('kibuo/device'),
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: CurrenciesScreen(repository: repo),
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

  test('a rate sheet title reads well in French', () {
    expect(frenchOfName('Franc congolais'), 'du franc congolais');
    expect(frenchOfName('Euro'), 'de l’euro');
    expect(frenchOfName('Livre sterling'), 'de la livre sterling');
    expect(frenchOfName('Dollar des États-Unis'), 'du dollar des États-Unis');
  });

  testWidgets('the main currency comes from the phone’s country', (
    tester,
  ) async {
    await start(tester);

    expect(find.text('Devise principale'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
  });

  testWidgets('adding a currency, then its rate', (tester) async {
    await start(tester);

    await tester.tap(find.text('Ajouter une devise'));
    await tester.pumpAndSettle();
    expect(find.text('Les plus courantes'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'congolais');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Franc congolais'));
    await tester.pumpAndSettle();

    expect(find.text('Taux du franc congolais'), findsOneWidget);
    await type(tester, '2800');
    await tester.tap(find.text('Enregistrer le taux'));
    await tester.pumpAndSettle();

    expect(textPlain(r'1 $ = 2 800 FC'), findsOneWidget);
    expect(find.text('Mis à jour le 3 novembre'), findsNothing);
  });

  testWidgets('a new rate shows the previous one and the change', (
    tester,
  ) async {
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('CDF');
    await repo.setRate('USD', 'CDF', RateValue.parse('2800'));
    now = DateTime.utc(2026, 11, 15, 9);
    await start(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(ItemCard),
        matching: find.text('Modifier'),
      ),
    );
    await tester.pumpAndSettle();
    expect(textPlain('Avant : 2 800 FC · 3 novembre'), findsOneWidget);
    await type(tester, '2850');
    await tester.pump();
    expect(textPlain('+50 FC'), findsOneWidget);
    await tester.tap(find.text('Enregistrer le taux'));
    await tester.pumpAndSettle();

    expect(textPlain(r'1 $ = 2 850 FC'), findsOneWidget);
    expect(find.text('Mis à jour le 15 novembre'), findsNothing);
  });

  testWidgets('changing the main currency keeps rates readable', (
    tester,
  ) async {
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('CDF');
    await repo.setRate('USD', 'CDF', RateValue.parse('2800'));
    await start(tester);

    await tester.tap(find.text('Changer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Franc congolais'));
    await tester.pumpAndSettle();

    expect(find.text('CDF'), findsOneWidget);
    expect(
      textPlain(r'1 $ = 2 800 FC'),
      findsOneWidget,
      reason: 'not 0,000357',
    );
  });

  testWidgets('adding a currency: those already added are greyed out', (
    tester,
  ) async {
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('CDF');
    await start(tester);

    await tester.tap(find.text('Ajouter une devise'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Franc congolais'));
    await tester.pumpAndSettle();

    expect(find.text('Choisir une devise'), findsOneWidget, reason: 'stays');
    expect(await repo.currencyCodes(), ['USD', 'CDF']);
  });

  testWidgets('choosing the main currency: yours first, then the others', (
    tester,
  ) async {
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('KES');
    await start(tester);

    await tester.tap(find.text('Changer'));
    await tester.pumpAndSettle();

    final yours = tester.getTopLeft(find.text('Vos devises')).dy;
    final common = tester.getTopLeft(find.text('Les plus courantes')).dy;
    final shilling = tester.getTopLeft(find.text('Shilling kényan')).dy;
    expect(yours, lessThan(shilling));
    expect(shilling, lessThan(common));
  });

  testWidgets('a rate shows the way it was typed: 1 \$ = 0,92 €', (
    tester,
  ) async {
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('EUR');
    await repo.setRate('USD', 'EUR', RateValue.parse('0.92'));
    await start(tester);

    expect(textPlain('1 \$ = 0,92 €'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(ItemCard),
        matching: find.text('Modifier'),
      ),
    );
    await tester.pumpAndSettle();
    expect(textPlain('1 \$ ='), findsOneWidget);
  });

  testWidgets('cents are set in the rate sheet of each currency', (
    tester,
  ) async {
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('EUR');
    await repo.setRate('USD', 'EUR', RateValue.parse('0.92'));
    await start(tester);

    expect(find.text('Centimes'), findsNothing, reason: 'not on Devises');
    await tester.tap(
      find.descendant(
        of: find.byType(ItemCard),
        matching: find.text('Modifier'),
      ),
    );
    await tester.pumpAndSettle();
    final cents = find.ancestor(
      of: find.text('Centimes'),
      matching: find.byType(SettingsSwitch),
    );
    await tester.tap(find.descendant(of: cents, matching: find.byType(Switch)));
    await tester.pump();
    await type(tester, '0,93');
    await tester.tap(find.text('Enregistrer le taux'));
    await tester.pumpAndSettle();

    expect((await repo.currency('EUR')).usesDecimals, isFalse);
  });

  testWidgets('the main currency’s cents are set where it is changed', (
    tester,
  ) async {
    await repo.ensurePrimaryCurrency('US');
    await start(tester);

    await tester.tap(find.text('Changer'));
    await tester.pumpAndSettle();
    final cents = find.ancestor(
      of: find.text('Centimes'),
      matching: find.byType(SettingsSwitch),
    );
    await tester.tap(find.descendant(of: cents, matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    expect((await repo.currency('USD')).usesDecimals, isFalse);
  });

  testWidgets('« Modifier » lets a currency be removed', (tester) async {
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('EUR');
    await repo.setRate('USD', 'EUR', RateValue.parse('0.92'));
    await start(tester);

    await tester.tap(
      find.descendant(of: find.byType(AppBar), matching: find.text('Modifier')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('Ajouter une devise'), findsNothing);
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();

    expect(find.text('Garder'), findsOneWidget, reason: 'struck, not gone');
    expect(await repo.currencyCodes(), ['USD', 'EUR']);
    await tester.tap(find.text('Garder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();

    expect(find.text('Euro, EUR'), findsNothing);
    expect(await repo.currencyCodes(), ['USD']);
    expect(find.text('Ajouter une devise'), findsOneWidget);
  });

  testWidgets('a currency used by an account stays, and says why', (
    tester,
  ) async {
    await repo.ensurePrimaryCurrency('US');
    await AccountRepository(db).create(
      name: 'Airtel',
      type: AccountType.mobile,
      opening: const Money(100, 'CDF'),
      openingDate: now,
    );
    await repo.setRate('USD', 'CDF', RateValue.parse('2800'));
    await start(tester);

    await tester.tap(
      find.descendant(of: find.byType(AppBar), matching: find.text('Modifier')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gardée'), findsOneWidget);
    expect(find.text('Retirer'), findsNothing);
    expect(find.text('Utilisée par le compte Airtel'), findsOneWidget);
  });

  testWidgets('the rate sheet no longer removes the currency', (tester) async {
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('EUR');
    await start(tester);

    await tester.tap(find.text('Euro, EUR'));
    await tester.pumpAndSettle();

    expect(find.text('Retirer cette devise'), findsNothing);
  });
}
