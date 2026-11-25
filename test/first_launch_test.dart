import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/first_launch_store.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/start/data_gate.dart';
import 'package:kibuo/ui/start/first_launch.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late _MemoryVault vault;
  late BackupService backups;
  late _Folders folders;
  final scheduled = <bool>[];
  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    vault = _MemoryVault();
    backups = BackupService(
      db: db,
      appFolder: () async => Directory.systemTemp,
      vault: vault,
    );
    folders = _Folders();
    scheduled.clear();
    // As the app does when its data opens (main.dart).
    await CurrencyRepository(db).ensurePrimaryCurrency('US');
  });
  tearDown(() async {
    appLanguageChoice.value = null;
    await db.close();
  });

  Future<void> start(WidgetTester tester, {LockController? lock}) async {
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
        home: KibuoData(
          database: db,
          child: FirstLaunchGate(
            backups: LaunchBackups(
              service: (_) => backups,
              folders: folders,
              schedule: ({required on}) async => scheduled.add(on),
            ),
            child: const Text('Accueil'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      lock == null
          ? app
          : KibuoLock(controller: lock, eraseAll: () async {}, child: app),
    );
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester, [String label = 'Continuer']) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> name(WidgetTester tester, String name) async {
    await tester.enterText(find.byType(TextField).first, name);
    await tester.pumpAndSettle();
  }

  testWidgets('a new app: language, currency, first account, then Accueil', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Bienvenue sur kibuo'), findsOneWidget);
    // Under « Continuer », at the first step only (PRODUCT: Restauration).
    expect(find.text('J’ai une sauvegarde'), findsOneWidget);

    await next(tester);
    expect(find.text('Étape 2 sur 4'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'congo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Franc congolais'));
    await tester.pumpAndSettle();
    await next(tester);
    expect(await CurrencyRepository(db).primaryCurrency(), 'CDF');

    expect(find.text('Étape 3 sur 4'), findsOneWidget);
    expect(find.text('Solde du'), findsNothing, reason: 'no balance date');
    final cont = find.widgetWithText(KibuoButton, 'Continuer');
    expect(tester.widget<KibuoButton>(cont).onPressed, isNull);
    await name(tester, 'M-Pesa');
    await next(tester);
    final accounts = await AccountRepository(db).accounts();
    expect(accounts.single.name, 'M-Pesa');
    expect(accounts.single.currency, 'CDF');
    expect(accounts.single.overdraft.allowed, isFalse);

    expect(find.text('Étape 4 sur 4'), findsOneWidget);
    expect(find.text('Verrouiller l’application'), findsOneWidget);
    expect(find.text('Sauvegardes automatiques'), findsOneWidget);
    expect(
      find.text('Chaque semaine, dans le dossier de votre choix.'),
      findsOneWidget,
    );
    await next(tester, 'Commencer');
    expect(find.text('Accueil'), findsOneWidget);
    expect(await FirstLaunchStore(db).needed(), isFalse);
  });

  group('step 4, left while the code was being made', () {
    late LockController lock;
    setUp(() async {
      lock = LockController(
        vault: _MemoryVault(),
        biometrics: _NoBiometrics(),
        privacy: _NoPrivacy(),
      );
      await lock.pins.setPin('2580');
      await lock.load();
      lock.unlock();
      await FirstLaunchStore(db).reached(4);
    });

    testWidgets('turned off, « Commencer » removes the code', (tester) async {
      await start(tester, lock: lock);
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await next(tester, 'Commencer');
      expect(find.text('Accueil'), findsOneWidget);
      expect(lock.hasPin, isFalse);
    });
  });

  group('step 4, automatic backups (PRODUCT, 24 and 25 November)', () {
    setUp(() => FirstLaunchStore(db).reached(4));

    Switch backupSwitch(WidgetTester tester) =>
        tester.widget<Switch>(find.byType(Switch).last);

    testWidgets('a folder chosen: on, kept at « Commencer »', (tester) async {
      folders.toPick = const BackupFolder(
        uri: 'content://tree/dl',
        name: 'Download/Kibuo',
      );
      await start(tester);
      await tester.tap(find.text('Sauvegardes automatiques'));
      await tester.pumpAndSettle();
      expect(backupSwitch(tester).value, isTrue);
      // Variant 3 A: the card keeps its words.
      expect(
        find.text('Chaque semaine, dans le dossier de votre choix.'),
        findsOneWidget,
      );
      expect((await backups.state()).auto, isFalse, reason: 'not yet');
      await next(tester, 'Commencer');
      expect(find.text('Accueil'), findsOneWidget);
      final state = await backups.state();
      expect(state.auto, isTrue);
      expect(state.folder?.name, 'Download/Kibuo');
      expect(scheduled, [true]);
    });
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

class _Folders implements BackupFolders {
  BackupFolder? toPick;
  int asked = 0;

  @override
  Future<BackupFolder?> pick() async {
    asked++;
    return toPick;
  }

  @override
  Future<bool> reachable(BackupFolder folder) async => true;

  @override
  Future<bool> write(BackupFolder folder, String name, File file) async => true;

  @override
  Future<List<String>> list(BackupFolder folder) async => const [];

  @override
  Future<void> delete(BackupFolder folder, String name) async {}
}
