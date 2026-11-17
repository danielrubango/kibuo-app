import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/long_amounts_store.dart';
import 'package:kibuo/domain/money/long_amounts.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/settings/long_amounts_sheet.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    longAmountsChoice.value = LongAmounts.auto;
  });
  tearDown(() => db.close());

  testWidgets('three choices, automatic checked; « Toujours » is kept', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final store = LongAmountsStore(db);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLongAmountsSheet(context, store),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('Montants longs'), findsOneWidget);
    expect(find.text('Automatique'), findsOneWidget);
    expect(find.text('Jamais'), findsOneWidget);
    expect(
      tester
          .widget<CheckChoice>(find.widgetWithText(CheckChoice, 'Automatique'))
          .on,
      isTrue,
    );
    await tester.tap(find.text('Toujours'));
    await tester.pumpAndSettle();
    expect(find.text('Montants longs'), findsNothing);
    expect(longAmountsChoice.value, LongAmounts.always);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await store.read(), LongAmounts.always);
  });
}
