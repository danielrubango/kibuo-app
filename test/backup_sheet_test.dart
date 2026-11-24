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
import 'package:kibuo/ui/backup/backup_sheet.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Keeps what kibuo would store, and writes nothing to disk.
class _Service extends BackupService {
  _Service(KibuoDatabase db, {this.folder, this.last})
    : super(db: db, appFolder: () async => Directory.systemTemp);

  BackupFolder? folder;
  DateTime? last;
  String? password;

  /// The password kibuo remembers, if any.
  String? remembered;
  bool written = false;

  @override
  Future<BackupState> state() async =>
      BackupState(folder: folder, last: last, hasPassword: remembered != null);

  @override
  Future<String?> rememberedPassword() async => remembered;

  @override
  Future<void> rememberPassword(String password) async => remembered = password;

  @override
  Future<void> setFolder(BackupFolder folder) async => this.folder = folder;

  @override
  Future<File> write({
    required DateTime now,
    String? password,
    String? language,
  }) async {
    this.password = password;
    written = true;
    return File('/tmp/kibuo-out/kibuo-2026-11-24-2104.kibuo');
  }

  @override
  Future<void> done(DateTime at) async => last = at;
}

class _Folders implements BackupFolders {
  _Folders({this.reach = true, this.ok = true});

  bool reach;
  bool ok;
  String? wrote;

  @override
  Future<BackupFolder?> pick() async =>
      const BackupFolder(uri: 'content://tree/dl', name: 'Download/Kibuo');

  @override
  Future<bool> reachable(BackupFolder folder) async => reach;

  @override
  Future<bool> write(BackupFolder folder, String name, File file) async {
    wrote = name;
    return ok;
  }

  @override
  Future<List<String>> list(BackupFolder folder) async => const [];

  @override
  Future<void> delete(BackupFolder folder, String name) async {}
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  final now = DateTime(2026, 11, 24, 21, 4);
  const folder = BackupFolder(uri: 'content://tree/dl', name: 'Download/Kibuo');

  setUp(() => db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p'));
  tearDown(() => db.close());

  Future<void> open(
    WidgetTester tester,
    _Service service,
    _Folders folders,
  ) async {
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
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  runBackup(context, service, folders: folders, now: () => now),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  VoidCallback? save(WidgetTester tester) => tester
      .widget<KibuoButton>(find.widgetWithText(KibuoButton, 'Sauvegarder'))
      .onPressed;

  Future<void> typePasswords(WidgetTester tester, String a, String b) async {
    await tester.enterText(find.byKey(const ValueKey('backup-password')), a);
    await tester.enterText(
      find.byKey(const ValueKey('backup-password-again')),
      b,
    );
    await tester.pump();
  }

  testWidgets('the first backup: choose a folder, a password, then save', (
    tester,
  ) async {
    final service = _Service(db);
    final folders = _Folders();
    await open(tester, service, folders);

    expect(find.text('Première sauvegarde'), findsOneWidget);
    expect(
      find.text('Aucune sauvegarde pour l’instant. Choisissez où la ranger.'),
      findsOneWidget,
    );
    expect(find.text('Aucun dossier choisi'), findsOneWidget);
    expect(save(tester), isNull);

    await tester.tap(find.text('Sélectionner'));
    await tester.pumpAndSettle();
    expect(find.text('Téléchargements/Kibuo'), findsOneWidget);
    expect(find.text('Changer'), findsOneWidget);
    expect(service.folder?.uri, 'content://tree/dl');

    // Not encrypted by default: a folder is enough.
    expect(find.byKey(const ValueKey('backup-password')), findsNothing);
    expect(save(tester), isNotNull);

    // Encrypting asks for the password, twice, 8 long.
    await tester.tap(find.text('Chiffrer avec un mot de passe'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Sans ce mot de passe, la sauvegarde ne pourra pas être ouverte.',
      ),
      findsOneWidget,
    );
    expect(save(tester), isNull);
    await typePasswords(tester, 'secret1', 'secret1');
    expect(save(tester), isNull);
    await typePasswords(tester, 'secret12', 'secret13');
    expect(save(tester), isNull);
    await typePasswords(tester, 'secret12', 'secret12');
    expect(save(tester), isNotNull);

    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sauvegarder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(service.password, 'secret12');
    expect(folders.wrote, 'kibuo-2026-11-24-2104.kibuo');
    expect(service.last, now);
    expect(find.text('Sauvegarde faite'), findsOneWidget);
    expect(find.text('kibuo-2026-11-24-2104.kibuo'), findsOneWidget);
    expect(find.bySemanticsLabel('Chiffrée'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  testWidgets('without encryption, no password is asked', (tester) async {
    final service = _Service(db, folder: folder, last: DateTime(2026, 11, 22));
    await open(tester, service, _Folders());

    expect(find.text('Sauvegarder maintenant ?'), findsOneWidget);
    // A recent backup: no reminder at the top.
    expect(find.textContaining('date de'), findsNothing);
    expect(find.byKey(const ValueKey('backup-password')), findsNothing);
    expect(save(tester), isNotNull);

    await tester.tap(find.text('Sauvegarder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(service.written, isTrue);
    expect(service.password, isNull);
    expect(find.bySemanticsLabel('Chiffrée'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  testWidgets('an old backup is recalled in amber', (tester) async {
    final service = _Service(db, folder: folder, last: DateTime(2026, 11, 12));
    await open(tester, service, _Folders());

    expect(
      find.text('Votre dernière sauvegarde date de 12 jours.'),
      findsOneWidget,
    );
  });

  testWidgets('a folder out of reach must be chosen again', (tester) async {
    final service = _Service(db, folder: folder, last: DateTime(2026, 11, 12));
    final folders = _Folders(reach: false);
    await open(tester, service, folders);

    expect(find.text('Dossier introuvable'), findsOneWidget);
    expect(
      find.text('Téléchargements/Kibuo n’est plus accessible.'),
      findsOneWidget,
    );
    expect(find.text('Sélectionner'), findsOneWidget);
    expect(save(tester), isNull);

    await tester.tap(find.text('Sélectionner'));
    await tester.pumpAndSettle();
    expect(find.text('Dossier introuvable'), findsNothing);
    expect(save(tester), isNotNull);
  });

  testWidgets('a failed write says so and keeps the sheet', (tester) async {
    final service = _Service(db, folder: folder, last: DateTime(2026, 11, 22));
    await open(tester, service, _Folders(ok: false));

    await tester.tap(find.text('Sauvegarder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text(
        'La sauvegarde n’a pas pu être écrite. Vérifiez le dossier et '
        'réessayez.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sauvegarder maintenant ?'), findsOneWidget);
    expect(service.last, DateTime(2026, 11, 22));
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  testWidgets('with a remembered password: encrypted with it, never asked', (
    tester,
  ) async {
    final service = _Service(db, folder: folder, last: DateTime(2026, 11, 22))
      ..remembered = 'retenu-123';
    await open(tester, service, _Folders());

    expect(find.text('Chiffrée avec votre mot de passe'), findsOneWidget);
    expect(find.text('Chiffrer avec un mot de passe'), findsNothing);
    expect(find.byType(Switch), findsNothing);
    expect(find.byKey(const ValueKey('backup-password')), findsNothing);

    await tester.tap(find.text('Sauvegarder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(service.password, 'retenu-123');
    expect(find.bySemanticsLabel('Chiffrée'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 10));
  });

  testWidgets('« Changer » opens the password sheet', (tester) async {
    final service = _Service(db, folder: folder, last: DateTime(2026, 11, 22))
      ..remembered = 'retenu-123';
    await open(tester, service, _Folders());
    // The second « Changer », the first being the folder's.
    await tester.tap(find.text('Changer').last);
    await tester.pumpAndSettle();
    expect(find.text('Mot de passe des sauvegardes'), findsOneWidget);
    expect(find.text('Changer le mot de passe'), findsOneWidget);
  });
}
