import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/backup/backup_files.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';
import 'package:kibuo/ui/backup/backup_sheet.dart';
import 'package:kibuo/ui/backup/restore_sheet.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// Plus › Sauvegarde, while only the manual backup exists (planche
/// sauvegarde S1): the mint card with the last date and « Sauvegarder
/// maintenant », then the folder.
class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.service,
    this.folders = const DeviceBackupFolders(),
    this.now = DateTime.now,
    this.restore,
    this.files,
  });

  final BackupService service;
  final BackupFolders folders;
  final DateTime Function() now;

  /// « Restaurer une sauvegarde »; none, no restore card.
  final RestoreTools? restore;

  /// Where the backup to restore is chosen.
  final BackupFiles? files;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
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
    await widget.service.setFolder(picked);
    await _load();
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
                Material(
                  color: KibuoColors.surface,
                  borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _pick,
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 52),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            l.backupFolder,
                            style: KibuoType.rowLabel.weight(600),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              folder == null
                                  ? l.backupNoFolder
                                  : folderLabel(l, folder),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KibuoType.body.copyWith(
                                color: folder == null
                                    ? KibuoColors.inkMuted
                                    : KibuoColors.inkSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
