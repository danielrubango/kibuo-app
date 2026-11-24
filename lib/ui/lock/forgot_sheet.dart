import 'package:flutter/material.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/hold_button.dart';
import 'package:kibuo/ui/kit/sheet.dart';
import 'package:kibuo/ui/lock/create_pin_screen.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/recovery_screens.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Code oublié ? »: the fingerprint when it is on, or erasing everything
/// on this phone by a long press. The recovery code joins at its own step.
Future<void> showForgotSheet(BuildContext context) {
  final lock = KibuoLock.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => withSheetHandle(
      _ForgotSheet(controller: lock.notifier!, eraseAll: lock.eraseAll),
    ),
  );
}

class _ForgotSheet extends StatelessWidget {
  const _ForgotSheet({required this.controller, required this.eraseAll});

  final LockController controller;
  final Future<void> Function() eraseAll;

  /// The right recovery code opens Kibuo; the forgotten PIN is dropped and a
  /// new one asked for at once, with « Plus tard » (PRODUCT.md).
  Future<void> _useRecoveryCode(BuildContext context) async {
    final root = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop();
    final ok = await root.push<bool>(
      MaterialPageRoute(
        builder: (_) => RecoveryEntryScreen(onCode: controller.recovery!.check),
      ),
    );
    if (ok != true) return;
    await controller.removePin();
    controller.unlock();
    await root.push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            CreatePinScreen(controller: controller, allowLater: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(l.lockForgot, style: text.headlineSmall),
            ),
            if (controller.fingerprintOn) ...[
              Material(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
                child: ListTile(
                  title: Text(l.lockUseFingerprint),
                  trailing: const Icon(
                    KibuoIcons.caretRight,
                    size: 16,
                    color: KibuoColors.inkMuted,
                  ),
                  onTap: () async {
                    final ok = await controller.biometrics.authenticate(
                      l.fingerprintReason,
                    );
                    if (ok) {
                      controller.unlock();
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (controller.recoveryCreatedAt != null) ...[
              Material(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
                child: ListTile(
                  title: Text(l.recoveryUse),
                  trailing: const Icon(
                    KibuoIcons.caretRight,
                    size: 16,
                    color: KibuoColors.inkMuted,
                  ),
                  onTap: () => _useRecoveryCode(context),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KibuoColors.surface,
                borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.forgotErase,
                    style: text.titleMedium?.copyWith(
                      color: KibuoColors.danger,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l.forgotEraseBody, style: text.bodyMedium),
                  const SizedBox(height: 12),
                  HoldToConfirm(
                    label: l.forgotHold,
                    onConfirmed: () async {
                      Navigator.of(context).pop();
                      await eraseAll();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
