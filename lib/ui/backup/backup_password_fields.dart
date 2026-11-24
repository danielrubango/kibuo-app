import 'package:flutter/material.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// The password to encrypt backups, twice, and the amber warning
/// (planche sauvegarde P1, MotDePasseRetenu A2): in « Sauvegarder
/// maintenant ? » and « Mot de passe des sauvegardes ». 12 between them;
/// margins around stay at the call site.
class BackupPasswordFields extends StatelessWidget {
  const BackupPasswordFields({
    super.key,
    required this.password,
    required this.again,
    required this.onChanged,
    this.keyName = 'backup-password',
  });

  final TextEditingController password;
  final TextEditingController again;
  final VoidCallback onChanged;

  /// The fields' keys: [keyName], then « [keyName]-again ».
  final String keyName;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KibuoTextField(
          key: ValueKey(keyName),
          hint: l.backupPassword,
          controller: password,
          secret: true,
          textCapitalization: TextCapitalization.none,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        KibuoTextField(
          key: ValueKey('$keyName-again'),
          hint: l.backupPasswordAgain,
          controller: again,
          secret: true,
          textCapitalization: TextCapitalization.none,
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: 12),
        BackupWarning(l.backupPasswordWarning),
      ],
    );
  }
}

/// « Sans ce mot de passe… », small and amber, with its sign.
class BackupWarning extends StatelessWidget {
  const BackupWarning(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            KibuoIcons.warning,
            size: 14,
            color: KibuoColors.warningInk,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: KibuoType.caption.copyWith(color: KibuoColors.warningInk),
          ),
        ),
      ],
    ),
  );
}
