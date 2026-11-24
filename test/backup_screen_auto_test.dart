import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';
import 'package:kibuo/ui/backup/backup_screen.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

import 'support/memory_vault.dart';

class _Service extends BackupService {
  _Service(KibuoDatabase db, MemoryVault vault)
    : super(db: db, appFolder: () async => Directory.systemTemp, vault: vault);

  int writes = 0;

  @override
  Future<File> write({
    required DateTime now,
    String? password,
    String? language,
  }) async {
    writes++;
    final work = await Directory.systemTemp.createTemp('kibuo-test-');
    return File('${work.path}/x.kibuo')..writeAsStringSync('backup');
  }
}

class _Folders implements BackupFolders {
  BackupFolder? toPick;
  bool reach = true;
  final names = <String>[];

  @override
  Future<BackupFolder?> pick() async => toPick;

  @override
  Future<bool> reachable(BackupFolder folder) async => reach;

  @override
  Future<bool> write(BackupFolder folder, String name, File file) async {
    names.add(name);
    return true;
  }

  @override
  Future<List<String>> list(BackupFolder folder) async => [...names];

  @override
  Future<void> delete(BackupFolder folder, String name) async =>
      names.remove(name);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late MemoryVault vault;
  late _Service service;
  late _Folders folders;
  final scheduled = <bool>[];
  const dl = BackupFolder(uri: 'content://tree/dl', name: 'Download/Kibuo');
  final now = DateTime(2026, 11, 24);

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    vault = MemoryVault();
    service = _Service(db, vault);
    folders = _Folders();
    scheduled.clear();
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester) async {
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
        home: BackupScreen(
          service: service,
          folders: folders,
          now: () => now,
          schedule: ({required on}) async => scheduled.add(on),
        ),
      ),
    );
    await settle(tester);
  }

  Switch autoSwitch(WidgetTester tester) => tester.widget<Switch>(
    find.descendant(
      of: find.ancestor(
        of: find.text('Sauvegarde automatique'),
        matching: find.byType(InkWell),
      ),
      matching: find.byType(Switch),
    ),
  );

  testWidgets('off at first, under the mint card, with « Chaque semaine »', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Sauvegarde automatique'), findsOneWidget);
    expect(find.text('Chaque semaine'), findsOneWidget);
    expect(autoSwitch(tester).value, isFalse);
  });

  testWidgets('on without a folder: no folder chosen, it stays off', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Sauvegarde automatique'));
    await settle(tester);
    expect(autoSwitch(tester).value, isFalse);
    expect((await service.state()).auto, isFalse);
    expect(scheduled, isEmpty);
  });

  testWidgets('on with a folder chosen: scheduled and made at once', (
    tester,
  ) async {
    folders.toPick = dl;
    await open(tester);
    await tester.tap(find.text('Sauvegarde automatique'));
    await settle(tester);
    expect(autoSwitch(tester).value, isTrue);
    expect(scheduled, [true]);
    expect(folders.names, ['kibuo-auto-2026-11-24.kibuo']);
    expect(find.text('Aujourd’hui'), findsOneWidget);
    expect(find.text('Téléchargements/Kibuo'), findsOneWidget);
  });

  testWidgets('on after a recent backup: nothing made yet', (tester) async {
    await service.setFolder(dl);
    await service.done(DateTime(2026, 11, 20));
    await open(tester);
    await tester.tap(find.text('Sauvegarde automatique'));
    await settle(tester);
    expect(autoSwitch(tester).value, isTrue);
    expect(service.writes, 0);
  });

  testWidgets('off again: no more checks kibuo closed', (tester) async {
    await service.setFolder(dl);
    await service.setAuto(on: true);
    await service.done(DateTime(2026, 11, 20));
    await open(tester);
    await tester.tap(find.text('Sauvegarde automatique'));
    await settle(tester);
    expect(autoSwitch(tester).value, isFalse);
    expect(scheduled, [false]);
  });

  testWidgets('a folder out of reach: in red, with « Sélectionner »', (
    tester,
  ) async {
    await service.setFolder(dl);
    folders.reach = false;
    await open(tester);
    expect(find.text('Dossier introuvable'), findsOneWidget);
    expect(find.text('Sélectionner'), findsOneWidget);

    // A new folder, and automatic backups on: made at once.
    await service.setAuto(on: true);
    folders
      ..reach = true
      ..toPick = const BackupFolder(
        uri: 'content://tree/doc',
        name: 'Documents/Kibuo',
      );
    await tester.tap(find.text('Sélectionner'));
    await settle(tester);
    expect(find.text('Documents/Kibuo'), findsOneWidget);
    expect(find.text('Dossier introuvable'), findsNothing);
    expect(folders.names, ['kibuo-auto-2026-11-24.kibuo']);
  });

  testWidgets('« Mot de passe »: none, remembered, changed, then removed', (
    tester,
  ) async {
    await service.setFolder(dl);
    await open(tester);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Aucun'), findsOneWidget);

    await tester.tap(find.text('Mot de passe'));
    await tester.pumpAndSettle();
    expect(find.text('Mot de passe des sauvegardes'), findsOneWidget);
    expect(
      find.text(
        'kibuo le retient sur ce téléphone et chiffre avec lui toutes vos '
        'sauvegardes, automatiques et manuelles.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retirer le mot de passe'), findsNothing);
    Future<void> type(String a, String b) async {
      await tester.enterText(
        find.byKey(const ValueKey('remember-password')),
        a,
      );
      await tester.enterText(
        find.byKey(const ValueKey('remember-password-again')),
        b,
      );
      await tester.pump();
    }

    VoidCallback? keep() => tester
        .widget<KibuoButton>(
          find.widgetWithText(KibuoButton, 'Retenir le mot de passe'),
        )
        .onPressed;
    expect(keep(), isNull);
    await type('court', 'court');
    expect(keep(), isNull);
    await type('premier-mot', 'premier-mos');
    expect(keep(), isNull);
    await type('premier-mot', 'premier-mot');
    expect(keep(), isNotNull);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retenir le mot de passe'));
    await settle(tester);
    expect(await service.rememberedPassword(), 'premier-mot');
    expect(find.text('Retenu'), findsOneWidget);

    // Changed.
    await tester.tap(find.text('Mot de passe'));
    await tester.pumpAndSettle();
    await type('second-mot', 'second-mot');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Changer le mot de passe'));
    await settle(tester);
    expect(await service.rememberedPassword(), 'second-mot');

    // Removed: the next backups are plain.
    await tester.tap(find.text('Mot de passe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retirer le mot de passe'));
    await settle(tester);
    expect(await service.rememberedPassword(), isNull);
    expect(find.text('Aucun'), findsOneWidget);
  });
}

/// Real files and the database need real time between frames.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}
