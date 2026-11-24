import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/backup_file.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/backup/backup_files.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';
import 'package:kibuo/ui/backup/backup_screen.dart';
import 'package:kibuo/ui/backup/restore_sheet.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

import 'support/memory_vault.dart';

class _Files implements BackupFiles {
  _Files(this.picked);

  final PickedBackup picked;

  @override
  Future<PickedBackup?> pick() async => picked;

  @override
  Future<PickedBackup?> takeOpened() async => null;

  @override
  Listenable get opened => ValueNotifier(0);
}

class _Folders implements BackupFolders {
  String? wrote;
  bool? wroteEncrypted;

  @override
  Future<BackupFolder?> pick() async => null;

  @override
  Future<bool> reachable(BackupFolder folder) async => true;

  @override
  Future<bool> write(BackupFolder folder, String name, File file) async {
    wrote = name;
    wroteEncrypted = (await peekBackup(file)).encrypted;
    return true;
  }

  @override
  Future<List<String>> list(BackupFolder folder) async => const [];

  @override
  Future<void> delete(BackupFolder folder, String name) async {}
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory folder;
  late Directory scratch;
  late KibuoDatabase db;
  late BackupService service;
  late File plain;
  late File locked;
  final now = DateTime(2026, 11, 24, 17, 23);

  setUp(() async {
    folder = Directory.systemTemp.createTempSync('kibuo_app_');
    scratch = Directory.systemTemp.createTempSync('kibuo_restore_ui_');
    final vault = MemoryVault();
    db = ((await openKibuoDatabase(
      folder: folder,
      vault: vault,
      inBackground: false,
    )) as Opened).database;
    await AccountRepository(db).create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(1000, 'USD'),
      openingDate: DateTime.utc(2026, 11, 1),
    );
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
    service = BackupService(
      db: db,
      appFolder: () async => folder,
      vault: vault,
      rounds: 1000,
    );
    await service.setFolder(
      const BackupFolder(uri: 'content://tree/doc', name: 'Documents'),
    );
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

  Future<(_Folders, List<BackupContents>)> open(
    WidgetTester tester,
    File file,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final folders = _Folders();
    final replaced = <BackupContents>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: BackupScreen(
          service: service,
          now: () => now,
          files: _Files(
            PickedBackup(file: file, name: file.uri.pathSegments.last),
          ),
          restore: RestoreTools(
            service: service,
            transactions: TransactionRepository(db),
            folders: folders,
            now: () => now,
            replace: (contents) async => replaced.add(contents),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Choisir un fichier'));
    await settle(tester);
    return (folders, replaced);
  }

  Future<void> hold(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(find.text(label)),
    );
    await tester.pump(); // the fill starts on the next frame
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Continuez d’appuyer…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await gesture.up();
    await settle(tester);
  }

  testWidgets('a backup: what is kept, the copy before, then « Données '
      'restaurées »', (tester) async {
    final (folders, replaced) = await open(tester, plain);
    expect(find.text('Revenir au 3 novembre ?'), findsOneWidget);
    expect(find.text('kibuo-2026-11-03-2104.kibuo'), findsOneWidget);
    // No operation yet: nothing to replace, a plain button.
    await tester.tap(find.text('Remplacer'));
    await settle(tester);
    await settle(tester);
    expect(replaced, hasLength(1));
    expect(replaced.single.manifest.accounts, 1);
    expect(folders.wrote, startsWith('kibuo-avant-restauration-2026-11-24'));
    expect(find.text('Données restaurées'), findsOneWidget);
    expect(find.text('Voir mes données'), findsOneWidget);
  });

  testWidgets('a locked backup with the wrong password: said, nothing '
      'replaced', (tester) async {
    final (_, replaced) = await open(tester, locked);
    expect(find.text('Mot de passe de la sauvegarde'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'wrong-one');
    await tester.pump();
    await tester.tap(find.text('Remplacer'));
    await settle(tester);
    await settle(tester);
    expect(
      find.text('Ce n’est pas le bon mot de passe. Réessayez.'),
      findsOneWidget,
    );
    expect(replaced, isEmpty);
  });

  testWidgets('not a backup: said, nothing else', (tester) async {
    final junk = File('${scratch.path}/photo.kibuo')..writeAsStringSync('nope');
    final (_, replaced) = await open(tester, junk);
    expect(
      find.text('Ce fichier n’est pas une sauvegarde kibuo, ou il est abîmé.'),
      findsOneWidget,
    );
    expect(replaced, isEmpty);
  });

  testWidgets('with operations, a long press replaces', (tester) async {
    final tx = TransactionRepository(db);
    final account = (await AccountRepository(db).accounts()).single;
    final categoryId = await CategoryRepository(db)
        .create(kind: CategoryKind.out, name: 'Repas', icon: 'forkKnife');
    await tx.create(
      kind: EntryKind.expense,
      accountId: account.id,
      categoryId: categoryId,
      paid: const Money(500, 'USD'),
      fees: 0,
      date: DateTime(2026, 11, 20),
    );
    final (_, replaced) = await open(tester, plain);
    expect(find.textContaining('1 opération'), findsOneWidget);
    await hold(tester, 'Maintenir pour remplacer');
    await settle(tester);
    expect(replaced, hasLength(1));
  });

  testWidgets('with the password remembered: no field, and the copy before '
      'is encrypted', (tester) async {
    await service.rememberPassword('secret-123');
    final (folders, replaced) = await open(tester, locked);
    expect(find.text('Revenir au 3 novembre ?'), findsOneWidget);
    expect(find.text('Mot de passe de la sauvegarde'), findsNothing);
    await tester.tap(find.text('Remplacer'));
    await settle(tester);
    await settle(tester);
    expect(replaced, hasLength(1));
    expect(folders.wroteEncrypted, isTrue);
  });

  testWidgets('an older password: the field, as before', (tester) async {
    await service.rememberPassword('another-one');
    await open(tester, locked);
    expect(find.text('Mot de passe de la sauvegarde'), findsOneWidget);
  });

  testWidgets('without a password remembered, the copy before is plain', (
    tester,
  ) async {
    final (folders, _) = await open(tester, plain);
    await tester.tap(find.text('Remplacer'));
    await settle(tester);
    await settle(tester);
    expect(folders.wroteEncrypted, isFalse);
  });
}
