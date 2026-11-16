import 'package:flutter/material.dart';
import 'package:kibuo/domain/lock/lock_rules.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/cards.dart';
import 'package:kibuo/ui/lock/create_pin_screen.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/recovery_screens.dart';
import 'package:kibuo/ui/lock/unlock_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

/// Réglages › Sécurité: Verrouillage and Confidentialité. The recovery code
/// row joins at its own step.
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key, required this.lock});

  final LockController lock;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: lock,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lockSummary = !lock.hasPin
        ? l.securityNoCode
        : lock.fingerprintOn
        ? l.securityCodeFingerprint
        : l.securityCode;
    return Scaffold(
      appBar: AppBar(title: Text(l.securityTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsCard(
            children: [
              SettingsRow(
                label: l.securityLock,
                value: lockSummary,
                onTap: () => _open(context, LockSettingsScreen(lock: lock)),
              ),
              SettingsRow(
                label: l.securityPrivacy,
                value: lock.settings.hideInRecents
                    ? l.securityRecentsHidden
                    : l.securityRecentsShown,
                onTap: () => _open(context, PrivacyScreen(lock: lock)),
              ),
              if (lock.recovery != null)
                SettingsRow(
                  label: l.recoveryTitle,
                  value: lock.recoveryCreatedAt == null
                      ? l.securityNoCode
                      : l.securityRecoveryOn(
                          formatRecoveryDate(context, lock.recoveryCreatedAt!),
                        ),
                  onTap: () =>
                      _open(context, RecoverySettingsScreen(lock: lock)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          HelpText(l.securityFooter),
        ],
      ),
    );
  }
}

void _open(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));

/// Sécurité › Verrouillage.
class LockSettingsScreen extends StatelessWidget {
  const LockSettingsScreen({super.key, required this.lock});

  final LockController lock;

  /// Asks for the current code first; true when it was given.
  static Future<bool> _confirmCurrent(
    BuildContext context,
    LockController lock,
  ) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (routeContext) => UnlockScreen(
          controller: lock,
          confirmOnly: true,
          onUnlocked: () => Navigator.of(routeContext).pop(true),
        ),
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: lock,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = lock.settings;

    Future<void> createOrChange() async {
      if (lock.hasPin && !await _confirmCurrent(context, lock)) return;
      if (!context.mounted) return;
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => CreatePinScreen(controller: lock)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.securityLock)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsCard(
            children: [
              SettingsRow(
                label: lock.hasPin
                    ? l.lockSettingsChange
                    : l.lockSettingsCreate,
                value: lock.hasPin ? l.lockDigits(lock.pinLength) : null,
                onTap: createOrChange,
              ),
              if (lock.hasPin && lock.biometricsAvailable)
                SettingsSwitch(
                  label: l.lockFingerprint,
                  value: s.fingerprint,
                  onChanged: (on) async {
                    if (on &&
                        !await lock.biometrics.authenticate(
                          l.fingerprintReason,
                        )) {
                      return;
                    }
                    await lock.updateSettings(s.copyWith(fingerprint: on));
                  },
                ),
              SettingsSwitch(
                label: l.lockShuffle,
                value: s.shuffle,
                onChanged: (on) => lock.updateSettings(s.copyWith(shuffle: on)),
              ),
              if (lock.hasPin)
                SettingsRow(
                  label: l.lockAfterRow,
                  value: delayLabel(l, s.delay),
                  onTap: () async {
                    final delay = await showDelaySheet(context, s.delay);
                    if (delay != null) {
                      await lock.updateSettings(s.copyWith(delay: delay));
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          HelpText(l.lockShuffleHelp),
          if (lock.hasPin) ...[
            const SizedBox(height: 24),
            SettingsCard(
              children: [
                SettingsRow(
                  label: l.lockRemove,
                  danger: true,
                  onTap: () async {
                    if (await _confirmCurrent(context, lock)) {
                      await lock.removePin();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            HelpText(l.lockRemoveHelp),
          ],
        ],
      ),
    );
  }
}

/// Sécurité › Confidentialité.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, required this.lock});

  final LockController lock;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: lock,
    builder: (context, _) => _build(context),
  );

  Widget _build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = lock.settings;
    return Scaffold(
      appBar: AppBar(title: Text(l.securityPrivacy)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsCard(
            children: [
              SettingsSwitch(
                label: l.privacyHideRecents,
                value: s.hideInRecents,
                onChanged: (on) =>
                    lock.updateSettings(s.copyWith(hideInRecents: on)),
              ),
              SettingsSwitch(
                label: l.privacyScreenshots,
                value: s.allowScreenshots,
                onChanged: (on) =>
                    lock.updateSettings(s.copyWith(allowScreenshots: on)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HelpText(l.privacyHelp),
        ],
      ),
    );
  }
}

String delayLabel(AppLocalizations l, AutoLockDelay delay) => switch (delay) {
  AutoLockDelay.immediately => l.delayImmediately,
  AutoLockDelay.thirtySeconds => l.delayThirtySeconds,
  AutoLockDelay.oneMinute => l.delayOneMinute,
  AutoLockDelay.fiveMinutes => l.delayFiveMinutes,
  AutoLockDelay.fifteenMinutes => l.delayFifteenMinutes,
};

/// « Verrouiller après une absence de »: the five delays, the current one
/// ticked. Returns the one picked, or null when the sheet is dismissed.
Future<AutoLockDelay?> showDelaySheet(
  BuildContext context,
  AutoLockDelay current,
) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheet<AutoLockDelay>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                l.lockAfter,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
            ),
            SettingsCard(
              children: [
                for (final delay in AutoLockDelay.values)
                  InkWell(
                    onTap: () => Navigator.of(sheetContext).pop(delay),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              delayLabel(l, delay),
                              style: Theme.of(sheetContext).textTheme.bodyLarge,
                            ),
                          ),
                          if (delay == current)
                            const Icon(
                              KibuoIcons.check,
                              color: KibuoColors.accent,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
