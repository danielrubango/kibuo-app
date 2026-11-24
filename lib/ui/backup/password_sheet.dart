import 'package:flutter/material.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/domain/backup/backup_rules.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/backup/backup_sheet.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/protect_sheet.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Mot de passe des sauvegardes » (MotDePasseRetenu, variant A): the
/// password kibuo remembers for every backup, chosen, changed or removed.
/// Changing or removing it asks the code of important actions if it is on.
/// True when something changed.
Future<bool> showBackupPasswordSheet(
  BuildContext context,
  BackupService service,
) async {
  final has = (await service.state()).hasPassword;
  if (!context.mounted) return false;
  final changed = await showKibuoSheet<bool>(
    context,
    title: AppLocalizations.of(context).backupPasswordSheetTitle,
    builder: (_) => _PasswordSheet(service: service, has: has),
  );
  return changed ?? false;
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet({required this.service, required this.has});

  final BackupService service;

  /// A password is already remembered: change it, or remove it.
  final bool has;

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _password = TextEditingController();
  final _again = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  bool get _ready =>
      !_working && backupPasswordReady(_password.text, _again.text);

  Future<void> _keep() async {
    final l = AppLocalizations.of(context);
    if (widget.has &&
        !await confirmWithCode(context, l.protectBackupPasswordChange)) {
      return;
    }
    setState(() => _working = true);
    await widget.service.rememberPassword(_password.text);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    if (!await confirmWithCode(context, l.protectBackupPasswordRemove)) return;
    setState(() => _working = true);
    await widget.service.forgetPassword();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l.backupPasswordSheetBody,
            style: KibuoType.body.copyWith(color: KibuoColors.inkSecondary),
          ),
        ),
        const SizedBox(height: 12),
        KibuoTextField(
          key: const ValueKey('remember-password'),
          hint: l.backupPassword,
          controller: _password,
          secret: true,
          textCapitalization: TextCapitalization.none,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        KibuoTextField(
          key: const ValueKey('remember-password-again'),
          hint: l.backupPasswordAgain,
          controller: _again,
          secret: true,
          textCapitalization: TextCapitalization.none,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        BackupWarning(l.backupPasswordWarning),
        const SizedBox(height: 24),
        KibuoButton(
          label: widget.has ? l.backupPasswordChange : l.backupPasswordKeep,
          onPressed: _ready ? _keep : null,
        ),
        if (widget.has) ...[
          const SizedBox(height: 8),
          ActionUnderCard(
            label: l.backupPasswordRemove,
            color: KibuoColors.danger,
            onPressed: _working ? null : _remove,
          ),
        ],
      ],
    );
  }
}
