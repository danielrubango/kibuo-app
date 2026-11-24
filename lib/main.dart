import 'package:flutter/material.dart';
import 'package:kibuo/data/backup_file.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/backup/auto_backup_task.dart';
import 'package:kibuo/ui/device_country.dart';
import 'package:kibuo/ui/lock/create_pin_screen.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/lock_gate.dart';
import 'package:kibuo/ui/reminders/notifier.dart';
import 'package:kibuo/ui/shell/app_shell.dart';
import 'package:kibuo/ui/start/data_gate.dart';
import 'package:kibuo/ui/start/first_launch.dart';
import 'package:kibuo/ui/start/start_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:path_provider/path_provider.dart';

/// The app's navigator, to show screens from outside a screen's context.
final navigator = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const vault = SecureKeyVault();
  final folder = getApplicationSupportDirectory();
  final lock = LockController(
    vault: vault,
    recovery: FileRecovery(folder: folder, vault: vault),
  );
  // Both happen while the start screen shows.
  final opening = folder.then((f) async {
    final result = await openKibuoDatabase(folder: f);
    if (result is Opened) {
      // The phone's country's currency, until the first launch asks.
      await CurrencyRepository(result.database)
          .ensurePrimaryCurrency(await deviceCountry());
    }
    return result;
  });
  final lockLoading = lock.load();
  runApp(
    KibuoApp(
      opening: opening,
      lock: lock,
      ready: Future.wait([opening, lockLoading]),
      eraseAndStartOver: () async {
        final result = await eraseAndStartOver(folder: await folder);
        await lock.load();
        return result;
      },
      replaceWithBackup: (contents) async =>
          replaceWithBackup(folder: await folder, contents: contents),
      reopen: () async => openKibuoDatabase(folder: await folder),
      // A new phone: the code and settings stayed on the old one.
      onRecovered: () async {
        await lock.load();
        if (lock.hasPin) return;
        await navigator.currentState?.push<bool>(
          MaterialPageRoute(
            builder: (_) => CreatePinScreen(controller: lock, allowLater: true),
          ),
        );
      },
    ),
  );
}

/// Android's daily call, kibuo closed (AutoBackupWorker): the automatic
/// backup, without a screen.
@pragma('vm:entry-point')
Future<void> autoBackupMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await backUpInBackground();
}

/// Kibuo speaks the phone's language when it is French or English, and
/// French otherwise. Choosing it inside the app comes with the settings.

/// The phone's notifications (PRODUCT: Rappels), one for the whole app.
final _notifier = LocalNotifier();

class KibuoApp extends StatelessWidget {
  const KibuoApp({
    super.key,
    this.opening,
    this.lock,
    this.ready,
    this.eraseAndStartOver,
    this.onRecovered,
    this.replaceWithBackup,
    this.reopen,
  });

  /// Restauration: the backup in place of the data, or the data again.
  final Future<OpenResult> Function(BackupContents contents)? replaceWithBackup;
  final Future<OpenResult> Function()? reopen;

  /// After data was reopened with the recovery code.
  final Future<void> Function()? onRecovered;

  /// The encrypted database being opened. Left out, with [lock], in widget
  /// tests that do not touch the data.
  final Future<OpenResult>? opening;

  /// The app lock; the app opens without one when left out.
  final LockController? lock;

  /// What the start screen waits for; [opening] when left out.
  final Future<void>? ready;

  /// « Effacer et repartir de zéro ».
  final Future<OpenResult> Function()? eraseAndStartOver;

  @override
  Widget build(BuildContext context) {
    final opening = this.opening;
    final lock = this.lock;
    final erase = eraseAndStartOver;
    // The language chosen in kibuo, else the phone's (PRODUCT).
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLanguageChoice,
      builder: (context, language, _) => MaterialApp(
        locale: language,
        title: 'kibuo',
        navigatorKey: navigator,
        debugShowCheckedModeBanner: false,
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: StartGate(
          ready: ready ?? opening,
          child: opening == null || erase == null
              ? const AppShell()
              : DataGate(
                  opening: opening,
                  eraseAndStartOver: erase,
                  onRecovered: onRecovered,
                  replaceWithBackup: replaceWithBackup,
                  reopen: reopen,
                  // On a new app, the guided first launch comes first.
                  builder: (eraseAll) => lock == null
                      ? FirstLaunchGate(child: AppShell(notifier: _notifier))
                      : LockGate(
                          controller: lock,
                          eraseAll: eraseAll,
                          child: FirstLaunchGate(
                            child: AppShell(notifier: _notifier),
                          ),
                        ),
                ),
        ),
      ),
    );
  }
}
