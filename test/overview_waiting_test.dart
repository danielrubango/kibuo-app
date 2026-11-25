import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/overview/overview_waiting.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The Aperçu until version 0.2: « En attendant » leads to the figures that
/// already exist (PRODUCT, 25 November 2026).
void main() {
  testWidgets('« En attendant » opens the month and the budgets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Scaffold(
          body: OverviewWaiting(
            onMonth: () => opened.add('month'),
            onBudgets: () => opened.add('budgets'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The views to come only say what comes: touching them does nothing.
    await tester.tap(find.text('Évolution'));
    await tester.tap(find.text('Le mois en chiffres'));
    await tester.tap(find.text('Budgets'));
    expect(opened, ['month', 'budgets']);
  });
}
