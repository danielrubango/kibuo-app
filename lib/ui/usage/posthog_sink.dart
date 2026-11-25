import 'package:kibuo/domain/usage/usage_event.dart';
import 'package:kibuo/ui/usage/usage_measure.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// The PostHog project kibuo sends to (ADR 0013): its key is public, made to
/// sit in the app. Empty: nothing is sent, PostHog is not even started.
const postHogKey = '';

/// PostHog Cloud in Europe.
const postHogHost = 'https://eu.i.posthog.com';

/// The messages, to PostHog (ADR 0013): no person profile, no place from
/// the IP address, no surveys, flags, replay or push; its own random number,
/// renewed when the user says yes again.
class PostHogSink implements UsageSink {
  const PostHogSink();

  Posthog get _posthog => Posthog();

  @override
  Future<void> start({required bool on}) async {
    final config = PostHogConfig(postHogKey)
      ..host = postHogHost
      ..optOut = !on
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
  }

  @override
  Future<void> turnOn() async {
    await _posthog.reset();
    await _posthog.optIn();
  }

  @override
  Future<void> turnOff() async {
    await _posthog.optOut();
    await _posthog.reset();
  }

  @override
  Future<void> describe(Map<String, Object> context) async {
    for (final MapEntry(:key, :value) in context.entries) {
      await _posthog.register(key, value);
    }
  }

  @override
  Future<void> send(String name, Map<String, Object> properties) =>
      _posthog.capture(eventName: name, properties: properties);

  @override
  Future<void> sendError(RedactedError error, StackTrace? stack) =>
      _posthog.captureException(
        error: error,
        stackTrace: stack,
        properties: {'error_type': error.type},
      );
}
