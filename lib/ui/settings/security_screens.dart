import 'package:flutter/material.dart';
import 'package:kibuo/domain/lock/lock_rules.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/lock/create_pin_screen.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/unlock_screen.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

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
            ],
          ),
          const SizedBox(height: 10),
          SettingsHelp(l.securityFooter),
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
          const SizedBox(height: 10),
          SettingsHelp(l.lockShuffleHelp),
          if (lock.hasPin) ...[
            const SizedBox(height: 20),
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
            const SizedBox(height: 10),
            SettingsHelp(l.lockRemoveHelp),
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
          const SizedBox(height: 10),
          SettingsHelp(l.privacyHelp),
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                            const Icon(Icons.check, color: KibuoColors.accent),
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

/// A white card of settings rows, as on the Réglages mock-ups.
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: KibuoColors.surface,
        borderRadius: BorderRadius.circular(KibuoTheme.radiusCard),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: KibuoColors.background),
            children[i],
          ],
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.danger = false,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: text.bodyLarge?.copyWith(
                  color: danger ? KibuoColors.danger : KibuoColors.ink,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: text.bodyMedium?.copyWith(
                  color: KibuoColors.inkSecondary,
                ),
              ),
            if (!danger)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.chevron_right, color: KibuoColors.inkMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class SettingsHelp extends StatelessWidget {
  const SettingsHelp(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: KibuoColors.inkSecondary),
      ),
    );
  }
}
