import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/more/about_screen.dart';
import 'package:kibuo/ui/more/licences.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Plus › À propos de kibuo (canvas APropos; PRODUCT, 25 November 2026).
void main() {
  Future<void> show(
    WidgetTester tester,
    Widget screen, {
    Locale locale = const Locale('fr'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the version and its date, the sentence, the lines', (
    tester,
  ) async {
    await show(tester, const AboutScreen(email: ''));
    expect(find.text('À propos'), findsOneWidget);
    expect(find.text('Version 0.1.0 · 25 novembre 2026'), findsOneWidget);
    expect(
      find.textContaining('Vos comptes, vos dettes et vos projets'),
      findsOneWidget,
    );
    expect(find.text('Politique de confidentialité'), findsOneWidget);
    expect(find.text('Ce que kibuo garde, et où'), findsOneWidget);
    expect(find.text('Licences'), findsOneWidget);
    expect(find.text('Fait avec soin'), findsOneWidget);
    // Not before the public site.
    expect(find.text('Conditions d’utilisation'), findsNothing);
    expect(find.text('Site web'), findsNothing);
    // No address: no line to write to.
    expect(find.text('Nous écrire'), findsNothing);
  });

  testWidgets('kibuo writes to contact@kibuo.app', (tester) async {
    await show(tester, const AboutScreen());
    expect(find.text('Nous écrire'), findsOneWidget);
    expect(find.text('contact@kibuo.app'), findsOneWidget);
  });

  testWidgets('in English, the date follows the language', (tester) async {
    await show(
      tester,
      const AboutScreen(email: ''),
      locale: const Locale('en'),
    );
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Version 0.1.0 · November 25, 2026'), findsOneWidget);
    expect(find.text('Made with care'), findsOneWidget);
  });

  testWidgets('Nous écrire opens the e-mail app on the address', (
    tester,
  ) async {
    final written = <String>[];
    await show(
      tester,
      AboutScreen(
        email: 'bonjour@exemple.org',
        writeMail: (to) async {
          written.add(to);
          return true;
        },
      ),
    );
    expect(find.text('bonjour@exemple.org'), findsOneWidget);
    await tester.tap(find.text('Nous écrire'));
    await tester.pumpAndSettle();
    expect(written, ['bonjour@exemple.org']);
  });

  testWidgets('no e-mail app: the address is said', (tester) async {
    await show(
      tester,
      AboutScreen(email: 'bonjour@exemple.org', writeMail: (_) async => false),
    );
    await tester.tap(find.text('Nous écrire'));
    await tester.pump();
    expect(
      find.text(
        'Aucune appli d’e-mail sur ce téléphone. '
        'Écrivez-nous à bonjour@exemple.org.',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('the privacy policy opens in the app, readable offline', (
    tester,
  ) async {
    await show(tester, const AboutScreen(email: ''));
    await tester.tap(find.text('Politique de confidentialité'));
    await tester.pumpAndSettle();
    expect(find.text('Mise à jour le 25 novembre 2026'), findsOneWidget);
    for (final title in [
      'Ce que kibuo garde',
      'Où',
      'Rien ne part',
      'Vos sauvegardes',
      'La copie par Android',
      'Empreinte et photos',
      'Effacer vos données',
    ]) {
      await tester.scrollUntilVisible(
        find.text(title),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Une question ?'), findsNothing);
  });

  testWidgets('the privacy policy ends with the address when there is one', (
    tester,
  ) async {
    await show(tester, const PrivacyPolicyScreen(email: 'bonjour@exemple.org'));
    await tester.scrollUntilVisible(
      find.text('Écrivez-nous à bonjour@exemple.org.'),
      300,
    );
    expect(find.text('Une question ?'), findsOneWidget);
  });

  test('the bundled fonts and icons join the licences', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerBundledLicences();
    final names = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      names.addAll(entry.packages);
    }
    expect(names, containsAll(bundledLicences.keys));
  });
}
