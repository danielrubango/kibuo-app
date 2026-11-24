import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/backup_file.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/backup/backup_files.dart';
import 'package:kibuo/ui/backup/start_restore_sheet.dart';
import 'package:kibuo/ui/start/data_gate.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

import 'support/memory_vault.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory folder;
  late Directory scratch;
  late KibuoDatabase db;
  late File plain;
  late File locked;

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('kibuo_app_');
    scratch = Directory.systemTemp.createTempSync('kibuo_start_');
    db = ((await openKibuoDatabase(
      folder: folder,
      vault: MemoryVault(),
      inBackground: false,
    )) as Opened).database;
    for (final name in ['M-Pesa', 'Rawbank']) {
      await AccountRepository(db).create(
        name: name,
        type: AccountType.mobile,
        opening: const Money(1000, 'USD'),
        openingDate: DateTime.utc(2026, 11, 1),
      );
    }
    plain = File('${scratch.path}/kibuo-2026-11-03-2104.kibuo');
    locked = File('${scratch.path}/locked.kibuo');
    for (final (file, password) in [(plain, null), (locked, 'secret-123')]) {
      await writeBackup(
        db,
        appFolder: folder,
        out: file,
        createdAt: DateTime(2026, 11, 3, 21, 4),
        password: password,
        rounds: 1000,
      );
    }
  });

  tearDown(() async {
    await db.close();
    folder.deleteSync(recursive: true);
    scratch.deleteSync(recursive: true);
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<(List<BackupContents>, List<int>)> open(
    WidgetTester tester,
    File file,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final replaced = <BackupContents>[];
    final after = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => runStartRestore(
                context,
                PickedBackup(file: file, name: file.uri.pathSegments.last),
                replace: (contents) async => replaced.add(contents),
                afterward: () async => after.add(1),
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await settle(tester);
    return (replaced, after);
  }

  testWidgets('a backup in clear: its content, « Restaurer », then the '
      'code offered', (tester) async {
    final (replaced, after) = await open(tester, plain);
    expect(find.text('Restaurer cette sauvegarde ?'), findsOneWidget);
    expect(find.text('2 comptes · aucune opération'), findsOneWidget);
    await tester.tap(find.text('Restaurer'));
    await settle(tester);
    expect(replaced, hasLength(1));
    expect(find.text('Données restaurées'), findsOneWidget);
    // No copy before: nothing was there.
    expect(find.textContaining('Copie d’avant'), findsNothing);
    await tester.tap(find.text('Voir mes données'));
    await settle(tester);
    expect(after, [1]);
  });

  testWidgets('a locked backup: grey until the right password', (tester) async {
    final (replaced, _) = await open(tester, locked);
    expect(find.text('• comptes · • opérations'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'wrong-one');
    await tester.pump(const Duration(milliseconds: 900));
    await settle(tester);
    expect(
      find.text('Ce n’est pas le bon mot de passe. Réessayez.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), 'secret-123');
    await tester.pump(const Duration(milliseconds: 900));
    await settle(tester);
    expect(find.text('2 comptes · aucune opération'), findsOneWidget);
    await tester.tap(find.text('Restaurer'));
    await settle(tester);
    expect(replaced, hasLength(1));
  });

  testWidgets('the unreadable screen offers « J’ai une sauvegarde »', (
    tester,
  ) async {
    var asked = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        locale: const Locale('fr'),
        home: UnreadableScreen(onStartOver: () {}, onBackup: () => asked++),
      ),
    );
    await tester.tap(find.text('J’ai une sauvegarde'));
    expect(asked, 1);
  });
}
