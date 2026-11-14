import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/data/lock_settings.dart';
import 'package:kibuo/data/pin_store.dart';
import 'package:kibuo/domain/lock/lock_rules.dart';
import 'package:local_auth/local_auth.dart';

/// The phone's fingerprint (or face) unlock.
abstract interface class Biometrics {
  Future<bool> available();
  Future<bool> authenticate(String reason);
}

class DeviceBiometrics implements Biometrics {
  const DeviceBiometrics();

  static final _auth = LocalAuthentication();

  @override
  Future<bool> available() async {
    try {
      return await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}

/// Screenshots and the preview in recent apps (Android only).
abstract interface class PrivacyPlatform {
  /// Android 13+ can hide the preview on its own; before, Kibuo covers it.
  Future<bool> canHidePreview();
  Future<void> apply({
    required bool allowScreenshots,
    required bool hideInRecents,
  });
}

class AndroidPrivacy implements PrivacyPlatform {
  const AndroidPrivacy();

  static const _channel = MethodChannel('kibuo/privacy');

  @override
  Future<bool> canHidePreview() async =>
      (await _channel.invokeMethod<int>('sdk') ?? 0) >= 33;

  @override
  Future<void> apply({
    required bool allowScreenshots,
    required bool hideInRecents,
  }) async {
    await _channel.invokeMethod<void>('allowScreenshots', allowScreenshots);
    await _channel.invokeMethod<void>('hideInRecents', hideInRecents);
  }
}

/// Whether Kibuo is locked, and the lock settings.
class LockController extends ChangeNotifier {
  LockController({
    required KeyVault vault,
    this.biometrics = const DeviceBiometrics(),
    this.privacy = const AndroidPrivacy(),
    DateTime Function()? now,
  }) : pins = PinStore(vault, now: now),
       _settingsStore = LockSettingsStore(vault),
       _now = now ?? DateTime.now;

  final PinStore pins;
  final Biometrics biometrics;
  final PrivacyPlatform privacy;
  final LockSettingsStore _settingsStore;
  final DateTime Function() _now;

  bool _ready = false;
  bool _hasPin = false;
  bool _locked = false;
  int? _pinLength;
  bool _biometricsAvailable = false;
  bool _canHidePreview = true;
  LockSettings _settings = const LockSettings();
  DateTime? _leftAt;

  bool get ready => _ready;
  bool get hasPin => _hasPin;
  bool get locked => _locked;
  int get pinLength => _pinLength ?? 4;
  bool get biometricsAvailable => _biometricsAvailable;
  LockSettings get settings => _settings;

  /// Fingerprint is offered only when the phone has one and it is turned on.
  bool get fingerprintOn => _settings.fingerprint && _biometricsAvailable;

  /// Android 8 to 12 cannot hide the preview: Kibuo shows its cover instead.
  bool get coversPreview => _settings.hideInRecents && !_canHidePreview;

  /// On a real start, Kibuo is locked when it has a code.
  Future<void> load() async {
    _hasPin = await pins.hasPin();
    _pinLength = await pins.pinLength();
    _settings = await _settingsStore.load();
    _biometricsAvailable = await biometrics.available();
    try {
      _canHidePreview = await privacy.canHidePreview();
      await _applyPrivacy();
    } on MissingPluginException {
      // Widget tests: no Android side.
    }
    _locked = _hasPin;
    _ready = true;
    notifyListeners();
  }

  void unlock() {
    _locked = false;
    notifyListeners();
  }

  /// Kibuo went to the background.
  void left() => _leftAt = _now();

  /// Kibuo came back: lock again after the chosen absence.
  void returned() {
    final left = _leftAt;
    _leftAt = null;
    if (!_hasPin || _locked || left == null) return;
    if (shouldLockOnReturn(left: left, now: _now(), delay: _settings.delay)) {
      _locked = true;
      notifyListeners();
    }
  }

  Future<void> setPin(String pin) async {
    await pins.setPin(pin);
    _hasPin = true;
    _pinLength = pin.length;
    notifyListeners();
  }

  Future<void> removePin() async {
    await pins.removePin();
    _hasPin = false;
    _pinLength = null;
    await updateSettings(_settings.copyWith(fingerprint: false));
  }

  Future<void> updateSettings(LockSettings settings) async {
    _settings = settings;
    await _settingsStore.save(settings);
    try {
      await _applyPrivacy();
    } on MissingPluginException {
      // Widget tests.
    }
    notifyListeners();
  }

  Future<void> _applyPrivacy() => privacy.apply(
    allowScreenshots: _settings.allowScreenshots,
    hideInRecents: _settings.hideInRecents,
  );
}

/// Gives the screens below the [LockController], and the way to erase
/// everything when the code is forgotten.
class KibuoLock extends InheritedNotifier<LockController> {
  const KibuoLock({
    super.key,
    required LockController controller,
    required this.eraseAll,
    required super.child,
  }) : super(notifier: controller);

  /// Erases all of Kibuo's data on this phone and starts again empty.
  final Future<void> Function() eraseAll;

  static KibuoLock of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KibuoLock>()!;

  static LockController controllerOf(BuildContext context) =>
      of(context).notifier!;

  /// Null where no lock applies (widget tests without data).
  static LockController? maybeControllerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<KibuoLock>()?.notifier;
}
