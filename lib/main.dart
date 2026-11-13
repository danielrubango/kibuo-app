import 'package:flutter/material.dart';

void main() {
  runApp(const KibuoApp());
}

/// Placeholder shell; navigation, theme and localization come in later steps.
class KibuoApp extends StatelessWidget {
  const KibuoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Kibuo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Kibuo'))),
    );
  }
}
