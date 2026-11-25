import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/first_launch_store.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/more/plus_page.dart';
import 'package:kibuo/ui/more/plus_summary.dart';
import 'package:kibuo/ui/settings/settings_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

import 'support/memory_vault.dart';

/// Thin spaces of money as plain ones.
String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late MemoryVault vault;
  late BackupService backups;
  final now = DateTime(2026, 11, 25);

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    vault = MemoryVault();
    backups = BackupService(
      db: db,
      appFolder: () async => Directory.systemTemp,
      vault: vault,
    );
  });
  tearDown(() async {
    appLanguageChoice.value = null;
    await db.close();
  });

  const summary = PlusSummary(
    accounts: Money(124850, 'USD'),
    budgets: 6,
    projects: 2,
    debts: 6,
    recurrences: 4,
    categories: 14,
    mainCurrency: 'USD',
  );

  Future<void> show(
    WidgetTester tester,
    Widget home, {
    LockController? lock,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final app = ValueListenableBuilder<Locale?>(
      valueListenable: appLanguageChoice,
      builder: (context, language, _) => MaterialApp(
        locale: language,
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Scaffold(body: home),
      ),
    );
    await tester.pumpWidget(
      lock == null
          ? app
          : KibuoLock(controller: lock, eraseAll: () async {}, child: app),
    );
    await settle(tester);
  }

  group('Plus (canvas Plus)', () {
    testWidgets('my spaces with their figures, then Réglages and the backup', (
      tester,
    ) async {
      final opened = <PlusEntry>[];
      await show(
        tester,
        PlusPage(
          load: () async => summary,
          onOpen: (e) async => opened.add(e),
          backups: backups,
          now: () => now,
        ),
      );
      expect(find.text('Plus'), findsOneWidget);
      expect(find.text('Mes espaces'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && plain(w.data ?? '') == '1 248,50 \$',
        ),
        findsOneWidget,
      );
      for (final (label, value) in [
        ('Budgets', '6'),
        ('Projets', '2'),
        ('Récurrences', '4'),
        ('Catégories', '14'),
      ]) {
        expect(find.text(label), findsOneWidget);
        expect(find.text(value), findsWidgets);
      }
      expect(find.text('Dettes et créances'), findsOneWidget);
      expect(find.text('Réglages'), findsOneWidget);
      expect(find.text('Français · USD · début le 1er'), findsOneWidget);
      expect(find.text('Sauvegarde et export'), findsOneWidget);
      expect(find.text('Aucune sauvegarde'), findsOneWidget);
      // Only À propos in the last card: Aide and Noter come later.
      expect(find.text('À propos de kibuo'), findsOneWidget);
      expect(find.text('Aide et support'), findsNothing);
      expect(find.text('Noter kibuo'), findsNothing);
      expect(
        find.text('kibuo 0.1.0 · Vos données restent sur ce téléphone'),
        findsOneWidget,
      );

      await tester.tap(find.text('Budgets'));
      await settle(tester);
      await tester.tap(find.text('Réglages'));
      await settle(tester);
      await tester.ensureVisible(find.text('À propos de kibuo'));
      await tester.tap(find.text('À propos de kibuo'));
      await settle(tester);
      expect(opened, [PlusEntry.budgets, PlusEntry.settings, PlusEntry.about]);
    });

    testWidgets('an old backup: amber, with its dot', (tester) async {
      await backups.done(DateTime(2026, 11, 13));
      await show(
        tester,
        PlusPage(
          load: () async => summary,
          onOpen: (_) async {},
          backups: backups,
          now: () => now,
        ),
      );
      final text = tester.widget<Text>(
        find.text('Dernière sauvegarde il y a 12 jours'),
      );
      expect(text.style?.color, const Color(0xFF8A5A00));
    });

    testWidgets('a recent backup: said plainly', (tester) async {
      await backups.done(DateTime(2026, 11, 24, 21));
      await show(
        tester,
        PlusPage(
          load: () async => summary,
          onOpen: (_) async {},
          backups: backups,
          now: () => now,
        ),
      );
      expect(find.text('Dernière sauvegarde hier'), findsOneWidget);
    });
  });

  group('Réglages (canvas Reglages)', () {
    Future<void> open(WidgetTester tester, {LockController? lock}) => show(
      tester,
      SettingsScreen(db: db, backups: backups),
      lock: lock,
    );

    testWidgets('Général in its order; no CSV export before 0.3', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Général'), findsOneWidget);
      final order = [
        'Langue',
        'Types de compte',
        'Devises',
        'Début du mois',
        'Montants longs',
        'Récurrences et brouillons',
      ];
      final tops = [for (final l in order) tester.getTopLeft(find.text(l)).dy];
      expect(tops, [...tops]..sort());
      expect(find.text('Français'), findsOneWidget);
      // Not settings: they stay in Plus (25 November 2026).
      expect(find.text('Comptes'), findsNothing);
      expect(find.text('Catégories'), findsNothing);
      expect(find.text('4'), findsOneWidget, reason: 'the 4 provided types');
      expect(find.text('Données'), findsOneWidget);
      expect(find.text('Sauvegarde et restauration'), findsOneWidget);
      expect(find.text('Exporter en CSV'), findsNothing);
      // No lock, no reminders here: no such sections.
      expect(find.text('Sécurité'), findsNothing);
      expect(find.text('Notifications'), findsNothing);
    });

    testWidgets('Sécurité: three lines, the lock said on or off', (
      tester,
    ) async {
      final lock = LockController(
        vault: _Vault(),
        biometrics: _NoBiometrics(),
        privacy: _NoPrivacy(),
      );
      await lock.load();
      await open(tester, lock: lock);
      await tester.scrollUntilVisible(find.text('Confidentialité'), 200);
      expect(find.text('Sécurité'), findsOneWidget);
      expect(find.text('Verrouillage'), findsOneWidget);
      expect(find.text('Désactivé'), findsOneWidget);
    });

    testWidgets('Langue: touching English switches at once, and is kept', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.text('Langue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Les nombres et les dates suivent la langue.'),
        findsOneWidget,
      );
      expect(find.text('Anglais'), findsOneWidget);
      await tester.tap(find.text('English'));
      await settle(tester);
      expect(appLanguageChoice.value, const Locale('en'));
      expect(find.text('Settings'), findsOneWidget);
      // Without Android 13's own setting (tests), kibuo keeps it.
      expect(await FirstLaunchStore(db).language(), 'en');
    });
  });
}

/// The database and files need real time between frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

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
