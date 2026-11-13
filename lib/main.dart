import 'package:flutter/material.dart';

import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/theme_preview.dart';

void main() {
  runApp(const KibuoApp());
}

/// Navigation and localization come in later steps.
class KibuoApp extends StatelessWidget {
  const KibuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kibuo',
      debugShowCheckedModeBanner: false,
      theme: KibuoTheme.light(),
      home: const ThemePreview(),
    );
  }
}
