import 'package:flutter/material.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';
import 'package:kibuo/domain/usage/usage_event.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';
import 'package:kibuo/ui/backup/backup_password_fields.dart';
import 'package:kibuo/ui/backup/password_sheet.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/confirm_sheet.dart';
import 'package:kibuo/ui/kit/operation_card.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/toast.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_flow.dart' show operationWhen;
import 'package:kibuo/ui/usage/usage_measure.dart';

/// A backup that reached its folder.
class _Done {
  const _Done(this.name, this.folder, this.at, {required this.encrypted});

  final String name;
  final BackupFolder folder;
  final DateTime at;
  final bool encrypted;
}

/// « Sauvegarder maintenant ? » (canvas SauvW2, planche sauvegarde P1, R1):
/// the sheet, then « Sauvegarde faite ». True when a backup was made.
Future<bool> runBackup(
  BuildContext context,
  BackupService service, {
  BackupFolders folders = const DeviceBackupFolders(),
  DateTime Function() now = DateTime.now,
}) async {
  final state = await service.state();
  final folder = state.folder;
  final reachable = folder == null ? true : await folders.reachable(folder);
  if (!context.mounted) return false;
  final done = await showModalBottomSheet<_Done>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _BackupSheet(
      service: service,
      folders: folders,
      state: state,
      reachable: reachable,
      now: now,
    ),
  );
  if (done == null || !context.mounted) return false;
  final l = AppLocalizations.of(context);
  await showConfirmSheet<void>(
    context,
    title: l.backupDone,
    card: SavedLine(
      title: done.name,
      subtitle:
          '${folderLabel(l, done.folder)} · '
          '${operationWhen(context, done.at, now())}',
      trailing: done.encrypted
          ? Icon(
              KibuoIcons.lockSimple,
              size: 18,
              color: KibuoColors.inkSecondary,
              semanticLabel: l.backupEncrypted,
            )
          : null,
    ),
  );
  return true;
}

class _BackupSheet extends StatefulWidget {
  const _BackupSheet({
    required this.service,
    required this.folders,
    required this.state,
    required this.reachable,
    required this.now,
  });

  final BackupService service;
  final BackupFolders folders;
  final BackupState state;
  final bool reachable;
  final DateTime Function() now;

  @override
  State<_BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<_BackupSheet> {
  late BackupFolder? _folder = widget.state.folder;
  late bool _reachable = widget.reachable;
  bool _encrypt = false;

  /// The remembered password: every backup uses it, never asked
  /// (MotDePasseRetenu A3).
  String? _remembered;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  Future<void> _loadRemembered() async {
    final password = await widget.service.rememberedPassword();
    if (mounted) setState(() => _remembered = password);
  }

  Future<void> _changePassword() async {
    if (await showBackupPasswordSheet(context, widget.service)) {
      await _loadRemembered();
    }
  }

  bool _saving = false;
  final _password = TextEditingController();
  final _again = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  bool get _ready =>
      _folder != null &&
      _reachable &&
      !_saving &&
      (_remembered != null ||
          !_encrypt ||
          backupPasswordReady(_password.text, _again.text));

  bool get _encrypted => _remembered != null || _encrypt;

  Future<void> _pick() async {
    final picked = await widget.folders.pick();
    if (picked == null || !mounted) return;
    await widget.service.setFolder(picked);
    setState(() {
      _folder = picked;
      _reachable = true;
    });
  }

  Future<void> _save() async {
    final folder = _folder!;
    final at = widget.now();
    setState(() => _saving = true);
    try {
      final file = await widget.service.write(
        now: at,
        password: _remembered ?? (_encrypt ? _password.text : null),
        // Android 13 and more keep the language outside the data.
        language: Localizations.localeOf(context).languageCode,
      );
      final name = file.uri.pathSegments.last;
      final bool ok;
      try {
        ok = await widget.folders.write(folder, name, file);
      } finally {
        // The temporary copy never stays, written or not.
        if (file.parent.existsSync()) file.parent.deleteSync(recursive: true);
      }
      if (!ok) throw StateError('not written');
      await widget.service.done(at);
      usage.track(UsageEvent.backup(automatic: false, done: true));
      if (!mounted) return;
      Navigator.of(context).pop(_Done(name, folder, at, encrypted: _encrypted));
    } on Object {
      usage.track(UsageEvent.backup(automatic: false, done: false));
      if (!mounted) return;
      setState(() => _saving = false);
      showKibuoToast(context, AppLocalizations.of(context).backupFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = widget.state;
    final first = state.last == null;
    final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
    final now = widget.now();
    final last = state.last;
    final days = last == null ? 0 : backupAgeDays(last, now);
    final Widget? note = typing
        ? null
        : first
        ? NoticeCard(
            icon: KibuoIcons.downloadSimple,
            text: l.backupFirstNote,
            background: KibuoColors.projectTint,
            tile: KibuoColors.surface,
            iconInk: KibuoColors.projectInk,
            ink: KibuoColors.projectDeep,
          )
        : state.old(now)
        ? NoticeCard(
            icon: KibuoIcons.downloadSimple,
            text: l.backupOldNote(days),
            bold: l.backupOldDays(days),
            background: KibuoColors.warningSoft,
            tile: KibuoColors.warningTint,
            iconInk: KibuoColors.warningInk,
            ink: KibuoColors.warningSoftInk,
          )
        : null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: sheetPadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            SheetHeader(title: first ? l.backupFirstTitle : l.backupSheetTitle),
            const SizedBox(height: 8),
            if (note != null) ...[note, const SizedBox(height: 12)],
            _OptionsCard(
              folder: _folder,
              reachable: _reachable,
              encrypt: _encrypt,
              remembered: _remembered != null,
              onChangePassword: _saving ? null : _changePassword,
              onPick: _saving ? null : _pick,
              onEncrypt: _saving ? null : (on) => setState(() => _encrypt = on),
            ),
            if (_encrypt && _remembered == null) ...[
              const SizedBox(height: 12),
              BackupPasswordFields(
                password: _password,
                again: _again,
                onChanged: () => setState(() {}),
              ),
            ],
            if (!typing) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(l.backupEverything, style: KibuoType.caption),
              ),
            ],
            const SizedBox(height: 12),
            KibuoButton(label: l.backupSave, onPressed: _ready ? _save : null),
            if (!typing) ...[
              const SizedBox(height: 12),
              KibuoButton(
                label: l.later,
                kind: ButtonKind.secondary,
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The folder line and the « Chiffrer » switch, in one white card.
class _OptionsCard extends StatelessWidget {
  const _OptionsCard({
    required this.folder,
    required this.reachable,
    required this.encrypt,
    required this.onPick,
    required this.onEncrypt,
    this.remembered = false,
    this.onChangePassword,
  });

  /// A password is remembered: said, with « Changer », no switch.
  final bool remembered;
  final VoidCallback? onChangePassword;

  final BackupFolder? folder;
  final bool reachable;
  final bool encrypt;
  final VoidCallback? onPick;
  final ValueChanged<bool>? onEncrypt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final folder = this.folder;
    final missing = folder != null && !reachable;
    final Widget value = folder == null
        ? Text(
            l.backupNoFolder,
            style: KibuoType.body
                .copyWith(color: KibuoColors.inkMuted)
                .weight(500),
          )
        : missing
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.backupFolderMissing,
                style: KibuoType.body
                    .copyWith(color: KibuoColors.danger)
                    .weight(700),
              ),
              Text(
                l.backupFolderMissingSub(folderLabel(l, folder)),
                style: KibuoType.caption,
              ),
            ],
          )
        : Text(
            folderLabel(l, folder),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KibuoType.body.weight(700),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              children: [
                Icon(
                  KibuoIcons.folderSimple,
                  size: 18,
                  color: missing
                      ? KibuoColors.danger
                      : KibuoColors.inkSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.backupFolder, style: KibuoType.caption),
                        const SizedBox(height: 1),
                        value,
                      ],
                    ),
                  ),
                ),
                TextAction(
                  label: folder == null || missing
                      ? l.backupSelect
                      : l.backupChange,
                  onPressed: onPick,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: KibuoColors.background),
          if (remembered)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Row(
                children: [
                  const Icon(
                    KibuoIcons.lockSimple,
                    size: 18,
                    color: KibuoColors.inkSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.backupEncryptedWith,
                      style: KibuoType.body.weight(600),
                    ),
                  ),
                  TextAction(
                    label: l.backupChange,
                    onPressed: onChangePassword,
                  ),
                ],
              ),
            )
          else
            SwitchRow(
              value: encrypt,
              onChanged: onEncrypt,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    KibuoIcons.lockSimple,
                    size: 18,
                    color: KibuoColors.inkSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.backupEncrypt,
                      style: KibuoType.body.weight(600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
