import 'package:flutter/material.dart';

import 'package:kibuo/data/backup_file.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/backup/backup_files.dart';
import 'package:kibuo/ui/backup/start_restore_sheet.dart';
import 'package:kibuo/ui/lock/recovery_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// Gives the screens below access to the open database.
class KibuoData extends InheritedWidget {
  const KibuoData({super.key, required this.database, required super.child});

  final KibuoDatabase database;

  static KibuoDatabase of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KibuoData>()!.database;

  /// Null in widget tests without data.
  static KibuoDatabase? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KibuoData>()?.database;

  @override
  bool updateShouldNotify(KibuoData old) => old.database != database;
}

/// Replaces the data with an opened backup (ADR 0006) and reopens the app
/// on it; throws when the backup cannot replace it, the data left as it
/// was.
class KibuoRestore extends InheritedWidget {
  const KibuoRestore({
    super.key,
    required this.replace,
    required super.child,
    this.afterStart,
  });

  final Future<void> Function(BackupContents contents) replace;

  /// After a restore at the start: the code and the fingerprint stayed on
  /// the old phone, creating one is offered (PRODUCT).
  final Future<void> Function()? afterStart;

  /// Null in widget tests without it.
  static KibuoRestore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KibuoRestore>();

  @override
  bool updateShouldNotify(KibuoRestore old) => false;
}

/// Shows [child] once the database is open, or the unreadable-data screen
/// when its key is gone (ADR 0005).
class DataGate extends StatefulWidget {
  const DataGate({
    super.key,
    required this.opening,
    required this.eraseAndStartOver,
    required this.builder,
    this.onRecovered,
    this.replaceWithBackup,
    this.reopen,
  });

  /// Puts a backup in place of the closed data, and opens it.
  final Future<OpenResult> Function(BackupContents contents)? replaceWithBackup;

  /// Opens the data again, when a backup could not replace it.
  final Future<OpenResult> Function()? reopen;

  /// Called once data was reopened with the recovery code.
  final Future<void> Function()? onRecovered;

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

  /// Closes the data, replaces it, and builds the app anew on the backup:
  /// every screen, setting and reminder reloads (PRODUCT: Restauration).
  Future<void> _replace(BackupContents contents) async {
    final current = await _opening;
    if (current is Opened) await current.database.close();
    OpenResult result;
    Object? failed;
    try {
      result = await widget.replaceWithBackup!(contents);
    } on Object catch (e) {
      failed = e;
      result = await widget.reopen!();
    }
    setState(() => _opening = Future.value(result));
    if (failed != null) throw failed;
  }

  /// « J'ai une sauvegarde » on unreadable data: the file set aside, the
  /// backup in its place (PRODUCT: Restauration).
  Future<void> _restoreUnreadable(Unreadable unreadable, PickedBackup picked) =>
      runStartRestore(
        context,
        picked,
        replace: (contents) async {
          final reopened = await unreadable.restore(contents);
          if (mounted) setState(() => _opening = Future.value(reopened));
        },
        afterward: widget.onRecovered,
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _opening,
      builder: (context, snapshot) => switch (snapshot.data) {
        Opened(:final database) => KibuoData(
          database: database,
          child: KibuoRestore(
            replace: _replace,
            afterStart: widget.onRecovered,
            // A new database: the app below starts afresh on it.
            child: KeyedSubtree(
              key: ObjectKey(database),
              child: widget.builder(_eraseAll),
            ),
          ),
        ),
        final Unreadable unreadable => WhenBackupOpened(
          onOpened: (picked) => _restoreUnreadable(unreadable, picked),
          child: UnreadableScreen(
            onBackup: () async {
              final picked = await DeviceBackupFiles.instance.pick();
              if (picked != null) await _restoreUnreadable(unreadable, picked);
            },
            onRecover: !unreadable.canRecover
                ? null
                : () => Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => RecoveryEntryScreen(
                        onCode: (code) async {
                          final reopened = await unreadable.recover(code);
                          if (reopened is! Opened) return false;
                          setState(() {
                            _opening = Future.value(reopened);
                          });
                          await widget.onRecovered?.call();
                          return true;
                        },
                      ),
                    ),
                  ),
            onStartOver: () {
              final reopening = unreadable.startOver();
              setState(() {
                _opening = reopening;
              });
            },
          ),
        ),
        // The start screen covers the opening; this never shows for long.
        null => const ColoredBox(color: KibuoColors.background),
      },
    );
  }
}

class UnreadableScreen extends StatelessWidget {
  const UnreadableScreen({
    super.key,
    required this.onStartOver,
    this.onRecover,
    this.onBackup,
  });

  final VoidCallback onStartOver;

  /// « J'ai une sauvegarde »: none in tests without it.
  final VoidCallback? onBackup;

  /// Opens the recovery-code entry; null when no code was ever created.
  final VoidCallback? onRecover;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
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
              const SizedBox(height: 24),
              Text(l.unreadableTitle, style: text.headlineMedium),
              const SizedBox(height: 12),
              Text(l.unreadableBody, style: text.bodyLarge),
              const Spacer(),
              if (onRecover != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onRecover,
                    child: Text(l.unreadableRecover),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: onRecover == null
                    ? FilledButton(
                        onPressed: onStartOver,
                        child: Text(l.unreadableStartOver),
                      )
                    : OutlinedButton(
                        onPressed: onStartOver,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: KibuoColors.ink,
                          backgroundColor: KibuoColors.surface,
                          side: const BorderSide(color: KibuoColors.line),
                        ),
                        child: Text(l.unreadableStartOver),
                      ),
              ),
              if (onBackup case final restore?) ...[
                const SizedBox(height: 4),
                BackupLink(onPressed: restore),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
