import 'package:flutter/foundation.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/domain/usage/usage_event.dart';

/// Where the messages go. PostHog in the app, nothing in the tests.
abstract interface class UsageSink {
  /// Prepared once at start, sending only if [on].
  Future<void> start({required bool on});

  /// Sending again, under a new random number.
  Future<void> turnOn();

  /// Nothing more leaves, and the random number is forgotten.
  Future<void> turnOff();

  /// What every following message carries (ADR 0013).
  Future<void> describe(Map<String, Object> context);

  Future<void> send(String name, Map<String, Object> properties);

  Future<void> sendError(RedactedError error, StackTrace? stack);
}

/// Sends nothing: the tests, or a build without a PostHog key.
class NoUsageSink implements UsageSink {
  const NoUsageSink();

  @override
  Future<void> start({required bool on}) async {}

  @override
  Future<void> turnOn() async {}

  @override
  Future<void> turnOff() async {}

  @override
  Future<void> describe(Map<String, Object> context) async {}

  @override
  Future<void> send(String name, Map<String, Object> properties) async {}

  @override
  Future<void> sendError(RedactedError error, StackTrace? stack) async {}
}

/// « Aider à améliorer kibuo » (ADR 0013): the user's answer, kept on this
/// phone, and the messages, sent only after a yes.
class UsageMeasure extends ChangeNotifier {
  /// « yes » or « no »; absent while the question was never answered.
  static const consentKey = 'usage_consent';

  KeyVault? _vault;
  UsageSink _sink = const NoUsageSink();
  bool? _consent;
  bool _loaded = false;

  /// Null while never asked; then the answer.
  bool? get consent => _consent;
  bool get on => _consent ?? false;

  /// Whether the question is still to ask, once the answer is read.
  bool get toAsk => _loaded && _consent == null;

  /// Set once in main (in a test, with a memory vault), before anything
  /// is sent.
  Future<void> attach({required KeyVault vault, required UsageSink sink}) {
    _vault = vault;
    _sink = sink;
    return load();
  }

  Future<void> load() async {
    String? stored;
    try {
      stored = await _vault?.read(consentKey);
    } on Object {
      stored = null;
    }
    _consent = switch (stored) {
      'yes' => true,
      'no' => false,
      _ => null,
    };
    _loaded = true;
    await _safely(() => _sink.start(on: on));
    notifyListeners();
  }

  /// The answer to the sheet, or the switch of Confidentialité.
  Future<void> answer({required bool yes}) async {
    if (_consent == yes) return;
    _consent = yes;
    await _vault?.write(consentKey, yes ? 'yes' : 'no');
    await _safely(yes ? _sink.turnOn : _sink.turnOff);
    notifyListeners();
  }

  Future<void> describe({
    required String? language,
    required String? country,
    required String? currency,
  }) => _safely(
    () => _sink.describe(
      usageContext(language: language, country: country, currency: currency),
    ),
  );

  void track(UsageEvent event) {
    if (!on || !usageEventAllowed(event.name, event.properties)) return;
    _safely(() => _sink.send(event.name, event.properties));
  }

  /// A crash, as its type and its stack only.
  void error(Object error, StackTrace? stack) {
    if (!on) return;
    _safely(() => _sink.sendError(RedactedError.of(error), stack));
  }

  /// Measuring never breaks kibuo.
  Future<void> _safely(Future<void> Function() run) async {
    try {
      await run();
    } on Object {
      // No network, no plugin: nothing to do.
    }
  }
}

/// The app's one measure, attached in main.
final usage = UsageMeasure();
