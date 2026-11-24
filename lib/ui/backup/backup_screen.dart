import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/backup/auto_backup.dart';
import 'package:kibuo/ui/backup/auto_backup_task.dart';
import 'package:kibuo/ui/backup/backup_files.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';
import 'package:kibuo/ui/backup/backup_sheet.dart';
import 'package:kibuo/ui/backup/restore_sheet.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Plus › Sauvegarde (canvas Sauvegarde): the mint card with the last date
/// and « Sauvegarder maintenant », then « Sauvegarde automatique » and the
/// folder in one card, then « Restaurer une sauvegarde ».
class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.service,
    this.folders = const DeviceBackupFolders(),
    this.now = DateTime.now,
    this.restore,
    this.files,
    this.schedule = scheduleAutoBackup,
  });

  final BackupService service;
  final BackupFolders folders;
  final DateTime Function() now;

  /// Android's daily check, kibuo closed.
  final Future<void> Function({required bool on}) schedule;

  /// « Restaurer une sauvegarde »; none, no restore card.
  final RestoreTools? restore;

  /// Where the backup to restore is chosen.
  final BackupFiles? files;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  BackupState? _state;
  bool _reachable = true;

  late final _auto = AutoBackup(
    service: widget.service,
    folders: widget.folders,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await widget.service.state();
    final folder = state.folder;
    bool reachable;
    try {
      reachable = folder == null || await widget.folders.reachable(folder);
    } on MissingPluginException {
      // No phone behind (tests): nothing to say about the folder.
      reachable = true;
    }
    if (mounted) {
      setState(() {
        _state = state;
        _reachable = reachable;
      });
    }
  }

  /// On: a folder first (none chosen, it stays off), then a backup at once
  /// if the last is a week old (PRODUCT: Sauvegardes automatiques).
  Future<void> _setAuto(bool on) async {
    if (on && _state?.folder == null) {
      final picked = await widget.folders.pick();
      if (picked == null) return;
      await _auto.folderChosen(picked);
    }
    await widget.service.setAuto(on: on);
    await widget.schedule(on: on);
    await _load();
    if (on) await _backUpNow();
  }

  /// The automatic backup, if due; a failure said at the bottom.
  Future<void> _backUpNow() async {
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    final outcome = await _auto.run(
      now: widget.now(),
      language: Localizations.localeOf(context).languageCode,
    );
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    if (outcome == AutoBackupOutcome.folderMissing) {
      showKibuoToast(context, l.autoBackupFolderToast);
    } else if (outcome == AutoBackupOutcome.failed) {
      showKibuoToast(context, l.autoBackupFailed);
    }
  }

  Future<void> _backUp() async {
    await runBackup(
      context,
      widget.service,
      folders: widget.folders,
      now: widget.now,
    );
    await _load();
  }

  Future<void> _restore() async {
    final tools = widget.restore;
    if (tools == null) return;
    final picked = await (widget.files ?? DeviceBackupFiles.instance).pick();
    if (picked == null || !mounted) return;
    await runRestore(context, picked, tools);
    if (mounted) await _load();
  }

  Future<void> _pick() async {
    final picked = await widget.folders.pick();
    if (picked == null) return;
    // A new folder: the automatic backup does not wait a week.
    await _auto.folderChosen(picked);
    await _load();
    if (_state?.auto ?? false) await _backUpNow();
  }

  String _lastText(AppLocalizations l, DateTime? last) {
    if (last == null) return l.backupNever;
    final now = widget.now();
    if (backupAgeDays(last, now) == 0) return l.backupToday;
    final lang = Localizations.localeOf(context).languageCode;
    return last.year == now.year
        ? DateFormat.MMMMd(lang).format(last)
        : DateFormat.yMMMMd(lang).format(last);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = _state;
    final folder = state?.folder;
    return Scaffold(
      appBar: AppBar(title: Text(l.backupTitle)),
      body: state == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: KibuoColors.mint,
                    borderRadius: BorderRadius.circular(
                      KibuoTheme.radiusFeatured,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.backupLast, style: KibuoType.body.weight(500)),
                      Text(
                        _lastText(l, state.last),
                        style: KibuoType.enteredValue,
                      ),
                      const SizedBox(height: 10),
                      KibuoButton(
                        label: l.backupNow,
                        kind: ButtonKind.dark,
                        onPressed: _backUp,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Canvas Sauvegarde: the switch, then the folder, one card.
                Material(
                  color: KibuoColors.surface,
                  borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 64),
                        child: SettingsSwitch(
                          label: l.autoBackup,
                          help: l.autoBackupHelp,
                          value: state.auto,
                          onChanged: _setAuto,
                        ),
                      ),
                      _FolderRow(
                        folder: folder,
                        missing: folder != null && !_reachable,
                        onTap: _pick,
                      ),
                    ],
                  ),
                ),
                if (widget.restore != null) ...[
                  const SizedBox(height: 12),
                  // Canvas Sauvegarde: what restoring means, then the file.
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KibuoColors.surface,
                      borderRadius: BorderRadius.circular(
                        KibuoTheme.radiusCard,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l.restoreTitle,
                          style: KibuoType.rowLabel.weight(600),
                        ),
                        const SizedBox(height: 6),
                        Text(l.restoreBody, style: KibuoType.help),
                        const SizedBox(height: 12),
                        KibuoButton(
                          label: l.restoreChoose,
                          kind: ButtonKind.danger,
                          onPressed: _restore,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// « Dossier » and where backups go; out of reach, « Dossier introuvable »
/// in red and « Sélectionner » (PRODUCT: Sauvegardes automatiques).
class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.folder,
    required this.missing,
    required this.onTap,
  });

  final BackupFolder? folder;
  final bool missing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final folder = this.folder;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: EdgeInsets.only(left: 16, right: missing ? 4 : 16),
        child: Row(
          children: [
            Text(l.backupFolder, style: KibuoType.rowLabel.weight(600)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                folder == null
                    ? l.backupNoFolder
                    : missing
                    ? l.backupFolderMissing
                    : folderLabel(l, folder),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: missing
                    ? KibuoType.body
                          .copyWith(color: KibuoColors.danger)
                          .weight(600)
                    : KibuoType.body.copyWith(
                        color: folder == null
                            ? KibuoColors.inkMuted
                            : KibuoColors.inkSecondary,
                      ),
              ),
            ),
            if (missing) TextAction(label: l.backupSelect, onPressed: onTap),
          ],
        ),
      ),
    );
  }
}

/// « Sauvegarde et export » on Plus, with when the last backup was, in
/// amber once it is old (canvas Plus, PlusAncienne).
class BackupSettingsRow extends StatefulWidget {
  const BackupSettingsRow({super.key, required this.service, this.restore});

  final BackupService service;

  /// Passed on to the screen: « Restaurer une sauvegarde ».
  final RestoreTools? restore;

  @override
  State<BackupSettingsRow> createState() => _BackupSettingsRowState();
}

class _BackupSettingsRowState extends State<BackupSettingsRow> {
  BackupState? _state;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = await widget.service.state();
    if (mounted) setState(() => _state = state);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = _state;
    final now = DateTime.now();
    final last = state?.last;
    final days = last == null ? null : backupAgeDays(last, now);
    return SettingsRow(
      label: l.moreBackup,
      value: state == null
          ? null
          : switch (days) {
              null => l.moreBackupNone,
              0 => l.moreBackupToday,
              1 => l.moreBackupYesterday,
              final d => l.moreBackupDays(d),
            },
      valueColor: state != null && state.old(now)
          ? KibuoColors.warningInk
          : null,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                BackupScreen(service: widget.service, restore: widget.restore),
          ),
        );
        await _load();
      },
    );
  }
}
