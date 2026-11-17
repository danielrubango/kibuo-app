import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/domain/lock/lock_rules.dart';

/// Réglages › Sécurité, kept on this phone only (never synced).
class LockSettings {
  const LockSettings({
    this.fingerprint = false,
    this.shuffle = true,
    this.delay = AutoLockDelay.standard,
    this.hideInRecents = true,
    this.allowScreenshots = true,
    this.androidCopy = true,
    this.protectActions = false,
    this.recoveryVerified = true,
  });

  final bool fingerprint;
  final bool shuffle;
  final AutoLockDelay delay;
  final bool hideInRecents;
  final bool allowScreenshots;

  /// Let Android copy Kibuo (Google backup, new phone); applies only once a
  /// recovery code exists (ADR 0010).
  final bool androidCopy;

  /// Ask the code (or fingerprint) before important actions, after their
  /// confirmation (PRODUCT); only with a code.
  final bool protectActions;

  /// The current recovery code was retyped after it was shown (retro, 18
  /// November): Sécurité says when it was not.
  final bool recoveryVerified;

  LockSettings copyWith({
    bool? fingerprint,
    bool? shuffle,
    AutoLockDelay? delay,
    bool? hideInRecents,
    bool? allowScreenshots,
    bool? androidCopy,
    bool? protectActions,
    bool? recoveryVerified,
  }) => LockSettings(
    fingerprint: fingerprint ?? this.fingerprint,
    shuffle: shuffle ?? this.shuffle,
    delay: delay ?? this.delay,
    hideInRecents: hideInRecents ?? this.hideInRecents,
    allowScreenshots: allowScreenshots ?? this.allowScreenshots,
    androidCopy: androidCopy ?? this.androidCopy,
    protectActions: protectActions ?? this.protectActions,
    recoveryVerified: recoveryVerified ?? this.recoveryVerified,
  );
}

class LockSettingsStore {
  const LockSettingsStore(this._vault);

  final KeyVault _vault;

  static const _fingerprint = 'lock_fingerprint';
  static const _shuffle = 'lock_shuffle';
  static const _delay = 'lock_delay';
  static const _hideInRecents = 'privacy_hide_recents';
  static const _allowScreenshots = 'privacy_screenshots';
  static const _androidCopy = 'backup_android_copy';
  static const _protectActions = 'lock_protect_actions';
  static const _recoveryVerified = 'recovery_verified';

  Future<LockSettings> load() async {
    const fallback = LockSettings();
    Future<bool> flag(String name, bool or) async =>
        switch (await _vault.read(name)) {
          'true' => true,
          'false' => false,
          _ => or,
        };
    final delay = await _vault.read(_delay);
    return LockSettings(
      fingerprint: await flag(_fingerprint, fallback.fingerprint),
      shuffle: await flag(_shuffle, fallback.shuffle),
      delay: AutoLockDelay.values.firstWhere(
        (d) => d.name == delay,
        orElse: () => fallback.delay,
      ),
      hideInRecents: await flag(_hideInRecents, fallback.hideInRecents),
      allowScreenshots: await flag(
        _allowScreenshots,
        fallback.allowScreenshots,
      ),
      androidCopy: await flag(_androidCopy, fallback.androidCopy),
      protectActions: await flag(_protectActions, fallback.protectActions),
      recoveryVerified: await flag(
        _recoveryVerified,
        fallback.recoveryVerified,
      ),
    );
  }

  Future<void> save(LockSettings s) async {
    await _vault.write(_fingerprint, '${s.fingerprint}');
    await _vault.write(_shuffle, '${s.shuffle}');
    await _vault.write(_delay, s.delay.name);
    await _vault.write(_hideInRecents, '${s.hideInRecents}');
    await _vault.write(_allowScreenshots, '${s.allowScreenshots}');
    await _vault.write(_androidCopy, '${s.androidCopy}');
    await _vault.write(_protectActions, '${s.protectActions}');
    await _vault.write(_recoveryVerified, '${s.recoveryVerified}');
  }
}
