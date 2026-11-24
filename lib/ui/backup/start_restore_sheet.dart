import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/backup_file.dart';
import 'package:kibuo/data/open_database.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/backup/backup_files.dart';
import 'package:kibuo/ui/backup/restore_sheet.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/icon_tile.dart';
import 'package:kibuo/ui/kit/operation_card.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « J'ai une sauvegarde », with nothing to replace yet: at the first
/// launch, or on unreadable data (canvas RestauNeuf). « Restaurer cette
/// sauvegarde ? », then « Données restaurées »; [afterward] once it is
/// closed (the code to create). No copy before: there is nothing to keep.
Future<void> runStartRestore(
  BuildContext context,
  PickedBackup picked, {
  required Future<void> Function(BackupContents contents) replace,
  Future<void> Function()? afterward,
}) async {
  // The screen below goes once the data is replaced: what follows shows
  // above it, on the app's own navigator.
  final navigator = Navigator.of(context);
  BackupEnvelope? envelope;
  try {
    envelope = await peekBackup(picked.file);
  } on Object {
    envelope = null;
  }
  if (!context.mounted) return;
  if (envelope == null) return showNotBackup(context);
  final manifest = await showModalBottomSheet<BackupManifest>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheet) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
      child: _StartSheet(picked: picked, envelope: envelope!, replace: replace),
    ),
  );
  if (manifest == null || !navigator.mounted) return;
  await showRestoredSheet(navigator.context, manifest);
  await afterward?.call();
}

class _StartSheet extends StatefulWidget {
  const _StartSheet({
    required this.picked,
    required this.envelope,
    required this.replace,
  });

  final PickedBackup picked;
  final BackupEnvelope envelope;
  final Future<void> Function(BackupContents contents) replace;

  @override
  State<_StartSheet> createState() => _StartSheetState();
}

class _StartSheetState extends State<_StartSheet> {
  final _password = TextEditingController();
  Timer? _wait;
  Directory? _work;
  BackupContents? _contents;
  bool _checking = false;
  bool _restoring = false;
  String? _passwordError;
  String? _error;

  @override
  void initState() {
    super.initState();
    // In clear: opened at once, its content shown.
    if (!widget.envelope.encrypted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _password.dispose();
    final work = _work;
    if (work != null && work.existsSync()) work.deleteSync(recursive: true);
    super.dispose();
  }

  void _typed(String _) {
    _wait?.cancel();
    setState(() {
      _passwordError = null;
      _contents = null;
    });
    if (_password.text.isEmpty) return;
    // Checked once the typing stops (PRODUCT).
    _wait = Timer(const Duration(milliseconds: 800), _open);
  }

  Future<void> _open() async {
    final l = AppLocalizations.of(context);
    final tried = _password.text;
    setState(() => _checking = true);
    final old = _work;
    if (old != null && old.existsSync()) old.deleteSync(recursive: true);
    final work = _work = await Directory.systemTemp.createTemp('kibuo-start-');
    try {
      final contents = await openBackup(
        widget.picked.file,
        password: widget.envelope.encrypted ? tried : null,
        into: work,
      );
      if (!mounted || tried != _password.text) return;
      if (backupTooNew(contents)) {
        setState(() => _error = l.restoreTooNew);
        return;
      }
      setState(() => _contents = contents);
    } on BackupWrongPassword {
      if (mounted && tried == _password.text) {
        setState(() => _passwordError = l.restoreWrongPassword);
      }
    } on Object {
      if (mounted) setState(() => _error = l.restoreNotKibuo);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _restore() async {
    final contents = _contents;
    if (contents == null || _restoring) return;
    final l = AppLocalizations.of(context);
    setState(() => _restoring = true);
    try {
      await widget.replace(contents);
      if (mounted) Navigator.of(context).pop(contents.manifest);
    } on BackupTooNew {
      if (mounted) setState(() => _error = l.restoreTooNew);
    } on Object {
      if (mounted) setState(() => _error = l.restoreNotKibuo);
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final at = widget.envelope.createdAt;
    final contents = _contents;
    final counts = contents == null
        ? l.startRestoreHidden
        : l.startRestoreCounts(
            contents.manifest.accounts,
            contents.manifest.operations,
          );
    return SingleChildScrollView(
      padding: sheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          SheetHeader(title: l.startRestoreTitle),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
            decoration: BoxDecoration(
              color: KibuoColors.surface,
              borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
            ),
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 64),
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
                              l.restoreSavedOn(
                                DateFormat.MMMMd(lang).format(at),
                                DateFormat.Hm(lang).format(at),
                              ),
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
                const Divider(height: 1, color: KibuoColors.background),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    children: [
                      Text(
                        l.startRestoreContent,
                        style: KibuoType.body.copyWith(
                          color: KibuoColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Spacer(),
                      if (_checking)
                        const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        // Blurred until the password is right (canvas
                        // RestauNeuf).
                        Flexible(
                          flex: 100,
                          child: ImageFiltered(
                            enabled: contents == null,
                            imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                            child: Text(
                              counts,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: KibuoType.body
                                  .copyWith(
                                    color: contents == null
                                        ? KibuoColors.inkSecondary
                                        : KibuoColors.ink,
                                  )
                                  .weight(700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.envelope.encrypted) ...[
            const SizedBox(height: 12),
            KibuoTextField(
              label: l.restorePassword,
              controller: _password,
              secret: true,
              onChanged: _typed,
              error: _passwordError,
            ),
            if (_passwordError == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Text(l.restorePasswordHelp, style: KibuoType.caption),
              ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(l.startRestoreNote, style: KibuoType.caption),
          ),
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
          KibuoButton(
            label: l.startRestoreAction,
            onPressed: contents == null || _restoring || _error != null
                ? null
                : _restore,
          ),
          const SizedBox(height: 8),
          KibuoButton(
            label: l.cancel,
            kind: ButtonKind.secondary,
            onPressed: _restoring ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// « J'ai une sauvegarde »: the file's icon and the words, in green,
/// under the start's buttons (canvas Lancement1).
class BackupLink extends StatelessWidget {
  const BackupLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: KibuoColors.accent,
        minimumSize: const Size(KibuoTheme.heightTouch, 48),
        textStyle: KibuoType.buttonSmall,
      ),
      icon: const Icon(KibuoIcons.file, size: 18),
      label: Text(AppLocalizations.of(context).startRestoreLink),
    ),
  );
}
