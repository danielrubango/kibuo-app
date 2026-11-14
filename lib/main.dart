import 'package:flutter/material.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/lock_gate.dart';
import 'package:kibuo/ui/shell/app_shell.dart';
import 'package:kibuo/ui/start/data_gate.dart';
import 'package:kibuo/ui/start/start_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const vault = SecureKeyVault();
  final folder = getApplicationSupportDirectory();
  final lock = LockController(vault: vault);
  // Both happen while the start screen shows.
  final opening = folder.then((f) => openKibuoDatabase(folder: f));
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
    ),
  );
}

/// Kibuo speaks the phone's language when it is French or English, and
/// French otherwise. Choosing it inside the app comes with the settings.
class KibuoApp extends StatelessWidget {
  const KibuoApp({
    super.key,
    this.opening,
    this.lock,
    this.ready,
    this.eraseAndStartOver,
  });

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
    return MaterialApp(
      title: 'Kibuo',
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
                builder: (eraseAll) => lock == null
                    ? const AppShell()
                    : LockGate(
                        controller: lock,
                        eraseAll: eraseAll,
                        child: const AppShell(),
                      ),
              ),
      ),
    );
  }
}
