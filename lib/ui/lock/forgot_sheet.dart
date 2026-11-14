import 'package:flutter/material.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

/// « Code oublié ? »: the fingerprint when it is on, or erasing everything
/// on this phone by a long press. The recovery code joins at its own step.
Future<void> showForgotSheet(BuildContext context) {
  final lock = KibuoLock.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _ForgotSheet(controller: lock.notifier!, eraseAll: lock.eraseAll),
  );
}

class _ForgotSheet extends StatelessWidget {
  const _ForgotSheet({required this.controller, required this.eraseAll});

  final LockController controller;
  final Future<void> Function() eraseAll;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                  trailing: const Icon(Icons.chevron_right),
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

/// A button that acts only after being held for 1.2 s, filling up meanwhile.
class HoldToConfirm extends StatefulWidget {
  const HoldToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
  });

  final String label;
  final VoidCallback onConfirmed;

  @override
  State<HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<HoldToConfirm>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onConfirmed();
      });

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      // Starts filling the moment the finger lands; letting go early undoes it.
      child: Listener(
        onPointerDown: (_) => _hold.forward(),
        onPointerUp: (_) => _hold.isCompleted ? null : _hold.reverse(),
        onPointerCancel: (_) => _hold.isCompleted ? null : _hold.reverse(),
        child: AnimatedBuilder(
          animation: _hold,
          builder: (context, _) => Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: KibuoColors.danger, width: 1.5),
              gradient: LinearGradient(
                colors: const [Color(0xFFFBE3DE), KibuoColors.surface],
                stops: [_hold.value, _hold.value],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: const TextStyle(
                color: KibuoColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
