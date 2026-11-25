import 'package:kibuo/domain/usage/usage_event.dart';
import 'package:kibuo/ui/usage/usage_measure.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// The PostHog project kibuo sends to (ADR 0013): its key is public, made to
/// sit in the app. Empty: nothing is sent, PostHog is not even started.
const postHogKey = 'phc_xvJgDQP6CjzENvVk2a6gaqr3rUwGxP4nyTEFT4oaHCyx';

/// PostHog Cloud in Europe.
const postHogHost = 'https://eu.i.posthog.com';

/// The messages, to PostHog (ADR 0013): no person profile, no place from
/// the IP address, no surveys, flags, replay or push; its own random number,
/// renewed when the user says yes again. Not even set up before a yes.
class PostHogSink implements UsageSink {
  PostHogSink();

  Posthog get _posthog => Posthog();

  /// PostHog is set up only after a yes: once set up, its Android side
  /// asks its server for its settings, which must not happen before.
  bool _ready = false;

  @override
  Future<void> start({required bool on}) async {
    if (on) await _setUp();
  }

  Future<void> _setUp() async {
    if (_ready) return;
    // Not while kibuo opens: after its first screens.
    await Future<void>.delayed(const Duration(seconds: 3));
    if (_ready) return;
    final config = PostHogConfig(postHogKey)
      ..host = postHogHost
      ..personProfiles = PostHogPersonProfiles.never
      ..disableGeoIp = true
      ..captureApplicationLifecycleEvents = true
      ..preloadFeatureFlags = false
      ..sendFeatureFlagEvent = false
      ..surveys = false
      ..sessionReplay = false
      ..capturePushNotificationSubscriptions = false
      ..capturePushNotificationOpened = false;
    await _posthog.setup(config);
    _ready = true;
    await _register();
  }

  Future<void> _register() async {
    for (final MapEntry(:key, :value) in _context.entries) {
      await _posthog.register(key, value);
    }
  }

  /// What every message carries, kept until PostHog is set up.
  Map<String, Object> _context = const {};

  @override
  Future<void> turnOn() async {
    await _setUp();
    await _posthog.reset();
    await _posthog.optIn();
    // A reset forgets what was registered.
    await _register();
  }

  @override
  Future<void> turnOff() async {
    if (!_ready) return;
    await _posthog.optOut();
    await _posthog.reset();
  }

  @override
  Future<void> describe(Map<String, Object> context) async {
    _context = context;
    if (_ready) await _register();
  }

  @override
  Future<void> send(String name, Map<String, Object> properties) async {
    if (_ready) await _posthog.capture(eventName: name, properties: properties);
  }

  @override
  Future<void> sendError(RedactedError error, StackTrace? stack) async {
    if (!_ready) return;
    await _posthog.captureException(
      error: error,
      stackTrace: stack,
      properties: {'error_type': error.type},
    );
  }
}
