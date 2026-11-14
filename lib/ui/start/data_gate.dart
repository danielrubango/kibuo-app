import 'package:flutter/material.dart';

import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// Gives the screens below access to the open database.
class KibuoData extends InheritedWidget {
  const KibuoData({super.key, required this.database, required super.child});

  final KibuoDatabase database;

  static KibuoDatabase of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KibuoData>()!.database;

  @override
  bool updateShouldNotify(KibuoData old) => old.database != database;
}

/// Shows [child] once the database is open, or the unreadable-data screen
/// when its key is gone (ADR 0005).
class DataGate extends StatefulWidget {
  const DataGate({
    super.key,
    required this.opening,
    required this.eraseAndStartOver,
    required this.builder,
  });

  final Future<OpenResult> opening;

  /// Deletes every Kibuo file and key on this phone, then opens anew.
  final Future<OpenResult> Function() eraseAndStartOver;

  /// Builds the app, given the way to erase everything.
  final Widget Function(Future<void> Function() eraseAll) builder;

  @override
  State<DataGate> createState() => _DataGateState();
}

class _DataGateState extends State<DataGate> {
  late Future<OpenResult> _opening = widget.opening;

  Future<void> _eraseAll() async {
    final current = await _opening;
    if (current is Opened) await current.database.close();
    final reopening = widget.eraseAndStartOver();
    setState(() {
      _opening = reopening;
    });
    await reopening;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _opening,
      builder: (context, snapshot) => switch (snapshot.data) {
        Opened(:final database) => KibuoData(
          database: database,
          child: widget.builder(_eraseAll),
        ),
        final Unreadable unreadable => UnreadableScreen(
          onStartOver: () {
            final reopening = unreadable.startOver();
            setState(() {
              _opening = reopening;
            });
          },
        ),
        // The start screen covers the opening; this never shows for long.
        null => const ColoredBox(color: KibuoColors.background),
      },
    );
  }
}

class UnreadableScreen extends StatelessWidget {
  const UnreadableScreen({super.key, required this.onStartOver});

  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: KibuoColors.warningTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  KibuoIcons.lockKey,
                  color: KibuoColors.warningInk,
                ),
              ),
              const SizedBox(height: 20),
              Text(l.unreadableTitle, style: text.headlineMedium),
              const SizedBox(height: 12),
              Text(l.unreadableBody, style: text.bodyLarge),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStartOver,
                  child: Text(l.unreadableStartOver),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
