import 'package:flutter/material.dart';

import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/shell/app_shell.dart';
import 'package:kibuo/ui/start/start_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  runApp(const KibuoApp());
}

/// Kibuo speaks the phone's language when it is French or English, and
/// French otherwise. Choosing it inside the app comes with the settings.
class KibuoApp extends StatelessWidget {
  const KibuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kibuo',
      debugShowCheckedModeBanner: false,
      theme: KibuoTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appLanguages,
      localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
      home: const StartGate(child: AppShell()),
    );
  }
}
