import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
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

  testWidgets('the main currency comes from the phone’s country', (
    tester,
  ) async {
    await start(tester);

    expect(find.text('Dollar des États-Unis · USD'), findsOneWidget);
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

    expect(find.text('Taux · Franc congolais'), findsOneWidget);
    await type(tester, '2800');
    await tester.tap(find.text('Enregistrer le taux'));
    await tester.pumpAndSettle();

    expect(textPlain(r'1 $ = 2 800 FC'), findsOneWidget);
    expect(find.text('Mis à jour le 3 novembre'), findsOneWidget);
  });

  testWidgets('a new rate shows the previous one and the change', (
    tester,
  ) async {
    await repo.ensurePrimaryCurrency('US');
    await repo.addCurrency('CDF');
    await repo.setRate('USD', 'CDF', RateValue.parse('2800'));
    now = DateTime.utc(2026, 11, 15, 9);
    await start(tester);

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    expect(textPlain(r'Avant : 1 $ = 2 800 FC · 3 novembre'), findsOneWidget);
    await type(tester, '2850');
    await tester.pump();
    expect(textPlain('+1,8 %'), findsOneWidget);
    await tester.tap(find.text('Enregistrer le taux'));
    await tester.pumpAndSettle();

    expect(textPlain(r'1 $ = 2 850 FC'), findsOneWidget);
    expect(find.text('Mis à jour le 15 novembre'), findsOneWidget);
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

    expect(find.text('Franc congolais · CDF'), findsOneWidget);
    expect(
      textPlain(r'1 $ = 2 800 FC'),
      findsOneWidget,
      reason: 'not 0,000357',
    );
  });
}
