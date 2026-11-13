import 'package:flutter/material.dart';

import 'package:kibuo/ui/shell/app_shell.dart';
import 'package:kibuo/ui/start/start_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  runApp(const KibuoApp());
}

/// Localization comes in the next step.
class KibuoApp extends StatelessWidget {
  const KibuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kibuo',
      debugShowCheckedModeBanner: false,
      theme: KibuoTheme.light(),
      home: const StartGate(child: AppShell()),
    );
  }
}
