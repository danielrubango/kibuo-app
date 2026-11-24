import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/backup_file.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';
import 'package:kibuo/domain/calendar.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/backup/backup_files.dart';
import 'package:kibuo/ui/backup/backup_folders.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/hatched_bar.dart';
import 'package:kibuo/ui/kit/hold_button.dart';
import 'package:kibuo/ui/kit/icon_tile.dart';
import 'package:kibuo/ui/kit/operation_card.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/kit/value_row.dart';
import 'package:kibuo/ui/lock/protect_sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// What a restore needs from the app: the backups' service and folders,
/// the current operations, and the way to put a backup in place.
class RestoreTools {
  const RestoreTools({
    required this.service,
    required this.transactions,
    required this.replace,
    this.folders = const DeviceBackupFolders(),
    this.now = DateTime.now,
  });

  final BackupService service;
  final TransactionRepository transactions;
  final Future<void> Function(BackupContents contents) replace;
  final BackupFolders folders;
  final DateTime Function() now;
}

/// What was put back, for « Données restaurées ».
class _Restored {
  const _Restored(this.manifest, this.copy, this.folder);

  final BackupManifest manifest;
  final String copy;
  final String folder;
}

/// Restores [picked] (PRODUCT: Restauration): « Revenir au 3 novembre ? »
/// (canvas RestauC1), then « Données restaurées » (RestauC3), whose
/// « Aller à l'accueil » goes back to the home, opened on the backup.
Future<void> runRestore(
  BuildContext context,
  PickedBackup picked,
  RestoreTools tools,
) async {
  BackupEnvelope? envelope;
  try {
    envelope = await peekBackup(picked.file);
  } on Object {
    envelope = null;
  }
  if (!context.mounted) return;
  if (envelope == null) {
    await showNotBackup(context);
    return;
  }
  final now = tools.now();
  final ops = [
    for (final t in await tools.transactions.all())
      if (t.counts) t,
  ];
  final after = ops.where((t) => t.date.isAfter(envelope!.createdAt)).length;
  final state = await tools.service.state();
  final folder = state.folder;
  final reachable = folder != null && await tools.folders.reachable(folder);
  if (!context.mounted) return;
  final done = await showModalBottomSheet<_Restored>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _RestoreSheet(
        picked: picked,
        envelope: envelope!,
        tools: tools,
        replaced: after,
        hasData: ops.isNotEmpty,
        first: state.firstOperation,
        folder: reachable ? folder : null,
        now: now,
      ),
    ),
  );
  if (done == null || !context.mounted) return;
  await showRestoredSheet(
    context,
    done.manifest,
    copy: done.copy,
    folder: done.folder,
  );
  if (context.mounted) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _RestoreSheet extends StatefulWidget {
  const _RestoreSheet({
    required this.picked,
    required this.envelope,
    required this.tools,
    required this.replaced,
    required this.hasData,
    required this.first,
    required this.folder,
    required this.now,
  });

  final PickedBackup picked;
  final BackupEnvelope envelope;
  final RestoreTools tools;

  /// The current operations dated after the backup.
  final int replaced;

  /// Whether there is anything to replace at all.
  final bool hasData;
  final DateTime? first;
  final BackupFolder? folder;
  final DateTime now;

  @override
  State<_RestoreSheet> createState() => _RestoreSheetState();
}

class _RestoreSheetState extends State<_RestoreSheet> {
  final _password = TextEditingController();
  late BackupFolder? _folder = widget.folder;
  String? _passwordError;
  String? _error;
  bool _working = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickFolder() async {
    final picked = await widget.tools.folders.pick();
    if (picked == null) return;
    await widget.tools.service.setFolder(picked);
    if (mounted) setState(() => _folder = picked);
  }

  bool get _ready =>
      _folder != null &&
      !_working &&
      (!widget.envelope.encrypted || _password.text.isNotEmpty);

  Future<void> _restore() async {
    final l = AppLocalizations.of(context);
    final folder = _folder;
    if (folder == null) return;
    setState(() {
      _working = true;
      _error = null;
      _passwordError = null;
    });
    final work = await Directory.systemTemp.createTemp('kibuo-restore-');
    try {
      BackupContents contents;
      try {
        contents = await openBackup(
          widget.picked.file,
          password: widget.envelope.encrypted ? _password.text : null,
          into: work,
        );
      } on BackupWrongPassword {
        setState(() => _passwordError = l.restoreWrongPassword);
        return;
      } on Object {
        setState(() => _error = l.restoreNotKibuo);
        return;
      }
      if (backupTooNew(contents)) {
        setState(() => _error = l.restoreTooNew);
        return;
      }
      if (!mounted || !await confirmWithCode(context, l.protectRestore)) {
        return;
      }
      // The copy first: without it, nothing is replaced (PRODUCT).
      final at = widget.tools.now();
      final copyName = restoreCopyName(at);
      File? copy;
      var copied = false;
      try {
        copy = await widget.tools.service.write(now: at);
        copied = await widget.tools.folders.write(folder, copyName, copy);
      } on Object {
        copied = false;
      } finally {
        if (copy != null && copy.existsSync()) copy.deleteSync();
      }
      if (!copied) {
        setState(() => _error = l.restoreCopyFailed);
        return;
      }
      if (!mounted) return;
      final label = folderLabel(l, folder);
      try {
        await widget.tools.replace(contents);
      } on BackupTooNew {
        setState(() => _error = l.restoreTooNew);
        return;
      } on Object {
        setState(() => _error = l.restoreNotKibuo);
        return;
      }
      if (mounted) {
        Navigator.of(context)
            .pop(_Restored(contents.manifest, copyName, label));
      }
    } finally {
      if (work.existsSync()) work.deleteSync(recursive: true);
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final at = widget.envelope.createdAt;
    final day = DateFormat.MMMMd(lang).format(at);
    final short = DateFormat.MMMd(lang).format(at);
    final from = widget.first != null && widget.first!.isBefore(at)
        ? widget.first!
        : at;
    final span = calendarDays(from, widget.now);
    final kept = span <= 0
        ? 0.0
        : (calendarDays(from, at) / span).clamp(0, 1).toDouble();
    return SingleChildScrollView(
      padding: sheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          SheetHeader(title: l.restoreSheetTitle(day)),
          const SizedBox(height: 12),
          // The file: its name, when it was saved, locked if encrypted.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
            ),
            child: Row(
              children: [
                const IconTile(
                  icon: KibuoIcons.file,
                  tint: KibuoColors.projectTint,
                  ink: KibuoColors.projectInk,
                  size: 40,
                  iconSize: 20,
                  radius: 13,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.picked.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KibuoType.body.weight(700),
                      ),
                      Text(
                        l.restoreSavedOn(day, DateFormat.Hm(lang).format(at)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KibuoType.caption.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (widget.envelope.encrypted)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      KibuoIcons.lockSimple,
                      size: 18,
                      color: KibuoColors.inkSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.hasData) ...[
            const SizedBox(height: 12),
            // What stays as the backup has it, and what is replaced.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat.MMMd(lang).format(from),
                          style: KibuoType.caption,
                        ),
                      ),
                      Text(l.backupToday, style: KibuoType.caption),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 22,
                    child: LayoutBuilder(
                      builder: (context, box) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // The full width, 12 high, centred on the mark.
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 5,
                            bottom: 5,
                            child: HatchedBar(
                              done: kept,
                              after: 1,
                              ink: KibuoColors.accentSoft,
                              track: KibuoColors.debtTint,
                              hatch: KibuoColors.debtLine,
                            ),
                          ),
                          Positioned(
                            left: (box.maxWidth * kept - 2).clamp(
                              0,
                              box.maxWidth - 4,
                            ),
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: KibuoColors.projectInk,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.restoreBackupDay(short),
                              style: KibuoType.caption
                                  .copyWith(
                                    fontSize: 13,
                                    color: KibuoColors.projectInk,
                                  )
                                  .weight(600),
                            ),
                            Text(
                              l.restoreKept,
                              style: KibuoType.caption.copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l.restoreReplacedCount(
                              calendarDays(at, widget.now).clamp(0, 99999),
                              widget.replaced,
                            ),
                            style: KibuoType.caption
                                .copyWith(
                                  fontSize: 13,
                                  color: KibuoColors.debtInk,
                                )
                                .weight(600),
                          ),
                          Text(
                            l.restoreReplaced,
                            style: KibuoType.caption.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (widget.envelope.encrypted) ...[
            const SizedBox(height: 12),
            KibuoTextField(
              label: l.restorePassword,
              controller: _password,
              secret: true,
              onChanged: (_) => setState(() => _passwordError = null),
              error: _passwordError,
            ),
            if (_passwordError == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Text(l.restorePasswordHelp, style: KibuoType.caption),
              ),
          ],
          if (_folder == null) ...[
            const SizedBox(height: 12),
            NoticeCard(
              icon: KibuoIcons.warning,
              text: l.restoreNoFolder,
              background: KibuoColors.warningSoft,
              ink: KibuoColors.warningSoftInk,
            ),
            ActionUnderCard(
              label: l.backupSelect,
              color: KibuoColors.accent,
              onPressed: _pickFolder,
            ),
          ] else ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Icon(
                    KibuoIcons.lockKey,
                    size: 14,
                    color: KibuoColors.inkSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l.restoreCopyNote, style: KibuoType.caption),
                  ),
                ],
              ),
            ),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            NoticeCard(
              icon: KibuoIcons.warningCircle,
              text: error,
              background: KibuoColors.dangerTint,
              ink: KibuoColors.danger,
            ),
          ],
          const SizedBox(height: 16),
          // Nothing to replace: a plain button (PRODUCT).
          if (widget.hasData)
            HoldToConfirm(
              label: l.restoreHold,
              holding: l.restoreHolding,
              dark: true,
              duration: const Duration(milliseconds: 1500),
              onConfirmed: _ready ? _restore : null,
            )
          else
            KibuoButton(
              label: l.restoreReplace,
              kind: ButtonKind.dark,
              onPressed: _ready ? _restore : null,
            ),
          const SizedBox(height: 8),
          KibuoButton(
            label: l.cancel,
            kind: ButtonKind.secondary,
            onPressed: _working ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// « Données restaurées » (canvas RestauC3): what came back and, after a
/// restore over data, the copy made before; « Voir mes données ».
Future<void> showRestoredSheet(
  BuildContext context,
  BackupManifest manifest, {
  String? copy,
  String? folder,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  builder: (context) =>
      _DoneSheet(manifest: manifest, copy: copy, folder: folder),
);

/// A file that is not a backup: said, nothing else.
Future<void> showNotBackup(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showKibuoSheet<void>(
    context,
    title: l.restoreTitle,
    builder: (_) => NoticeCard(
      icon: KibuoIcons.warningCircle,
      text: l.restoreNotKibuo,
      background: KibuoColors.dangerTint,
      ink: KibuoColors.danger,
    ),
  );
}

class _DoneSheet extends StatelessWidget {
  const _DoneSheet({required this.manifest, this.copy, this.folder});

  final BackupManifest manifest;
  final String? copy;
  final String? folder;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final m = manifest;
    return SingleChildScrollView(
      padding: sheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          Text(l.restoreDoneTitle, style: KibuoType.sheetTitle),
          const SizedBox(height: 12),
          const Center(
            child: IconTile(
              icon: KibuoIcons.checkBold,
              tint: KibuoColors.accentSoft,
              ink: KibuoColors.accent,
              size: 64,
              iconSize: 32,
              radius: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: l.restoreDoneBefore,
              children: [
                TextSpan(
                  text: DateFormat.MMMMd(lang).format(m.createdAt),
                  style: const TextStyle(color: KibuoColors.ink).weight(700),
                ),
                TextSpan(text: l.restoreDoneAfter),
              ],
            ),
            textAlign: TextAlign.center,
            style: KibuoType.body.copyWith(
              fontSize: 15,
              color: KibuoColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SettingsCard(
            children: [
              ValueRow(label: l.restoreAccounts, value: '${m.accounts}'),
              ValueRow(label: l.restoreOperations, value: '${m.operations}'),
              ValueRow(label: l.restoreProjects, value: '${m.projects}'),
            ],
          ),
          if (copy case final copy?) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
              ),
              child: Row(
                children: [
                  const Icon(
                    KibuoIcons.lockKey,
                    size: 18,
                    color: KibuoColors.inkSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.restoreCopyWhere(folder ?? ''),
                          style: KibuoType.caption,
                        ),
                        Text(
                          copy,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KibuoType.body.weight(700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          KibuoButton(
            label: l.restoreGoHome,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
