import 'package:flutter/material.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/shell/app_shell.dart';
import 'package:kibuo/ui/start/data_gate.dart';
import 'package:kibuo/ui/start/start_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Opens while the start screen shows.
  final opening = getApplicationSupportDirectory().then(
    (folder) => openKibuoDatabase(folder: folder),
  );
  runApp(KibuoApp(opening: opening));
}

/// Kibuo speaks the phone's language when it is French or English, and
/// French otherwise. Choosing it inside the app comes with the settings.
class KibuoApp extends StatelessWidget {
  const KibuoApp({super.key, this.opening});

  /// The encrypted database being opened. Left out in widget tests that do
  /// not touch the data.
  final Future<OpenResult>? opening;

  @override
  Widget build(BuildContext context) {
    final opening = this.opening;
    return MaterialApp(
      title: 'Kibuo',
      debugShowCheckedModeBanner: false,
      theme: KibuoTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appLanguages,
      localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
      home: StartGate(
        ready: opening,
        child: opening == null
            ? const AppShell()
            : DataGate(opening: opening, child: const AppShell()),
      ),
    );
  }
}
