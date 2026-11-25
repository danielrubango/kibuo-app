import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/usage/usage_event.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/settings/security_screens.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/usage/usage_measure.dart';
import 'package:kibuo/ui/usage/usage_sheet.dart';

import 'support/memory_vault.dart';

/// « Aider à améliorer kibuo » (ADR 0013): nothing leaves before a yes.
void main() {
  late MemoryVault vault;
  late _Sink sink;
  late UsageMeasure measure;

  setUp(() async {
    vault = MemoryVault();
    sink = _Sink();
    measure = UsageMeasure();
    await measure.attach(vault: vault, sink: sink);
  });

  group('the answer', () {
    test('never asked: the question is to ask, and nothing leaves', () {
      expect(measure.toAsk, isTrue);
      expect(sink.startedOn, isFalse);
      measure.track(UsageEvent.tab(UsageTab.more));
      measure.error(StateError('x'), StackTrace.current);
      expect(sink.sent, isEmpty);
      expect(sink.errors, isEmpty);
    });

    test('a yes: kept on the phone, and the messages leave', () async {
      await measure.answer(yes: true);
      expect(vault.values[UsageMeasure.consentKey], 'yes');
      expect(sink.calls, ['on']);
      measure.track(UsageEvent.operationSaved(UsageOperation.income));
      expect(sink.sent, ['operation_saved']);

      // At the next opening, it is still yes and not asked again.
      final again = UsageMeasure();
      final next = _Sink();
      await again.attach(vault: vault, sink: next);
      expect(again.toAsk, isFalse);
      expect(next.startedOn, isTrue);
    });

    test('a no: kept too, and nothing leaves', () async {
      await measure.answer(yes: false);
      expect(vault.values[UsageMeasure.consentKey], 'no');
      expect(measure.toAsk, isFalse);
      measure.track(UsageEvent.tab(UsageTab.more));
      expect(sink.sent, isEmpty);
    });

    test('turned off then on: the random number is renewed', () async {
      await measure.answer(yes: true);
      await measure.answer(yes: false);
      await measure.answer(yes: true);
      // turnOff forgets the number; turnOn draws a new one.
      expect(sink.calls, ['on', 'off', 'on']);
    });

    test('an event that does not fit never leaves', () async {
      await measure.answer(yes: true);
      measure.track(const _Odd());
      expect(sink.sent, isEmpty);
    });

    test('an error leaves as its type only', () async {
      await measure.answer(yes: true);
      measure.error(const FormatException('Loyer 300 000 FC'), null);
      await Future<void>.delayed(Duration.zero);
      expect(sink.errors.single.toString(), 'FormatException');
    });
  });

  group('the sheet (variant B)', () {
    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.localesTestValue = const [Locale('fr')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      await tester.pumpWidget(
        MaterialApp(
          theme: KibuoTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appLanguages,
          localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => askUsageConsent(context, measure),
                child: const Text('Accueil'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Accueil'));
      await tester.pumpAndSettle();
    }

    testWidgets('« Non merci » is a no', (tester) async {
      await open(tester);
      await tester.tap(find.text('Non merci'));
      await tester.pumpAndSettle();
      expect(measure.consent, isFalse);
    });

    testWidgets('closed with ✕: a no, never asked again', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Fermer'));
      await tester.pumpAndSettle();
      expect(measure.consent, isFalse);
      expect(measure.toAsk, isFalse);
    });
  });

  testWidgets('Confidentialité: the switch says and changes the answer', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final lock = LockController(
      vault: MemoryVault(),
      biometrics: _NoBiometrics(),
      privacy: _NoPrivacy(),
    );
    await lock.load();
    await measure.answer(yes: true);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: PrivacyScreen(lock: lock, usageMeasure: measure),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aider à améliorer kibuo'), findsOneWidget);
    expect(find.textContaining('numéro tiré au sort'), findsOneWidget);
    final row = find.ancestor(
      of: find.text('Aider à améliorer kibuo'),
      matching: find.byType(Row),
    );
    await tester.tap(
      find.descendant(of: row.first, matching: find.byType(Switch)),
    );
    await tester.pumpAndSettle();
    expect(measure.consent, isFalse);
    expect(sink.calls.last, 'off');
  });
}

class _Odd implements UsageEvent {
  const _Odd();

  @override
  String get name => 'operation_saved';

  @override
  Map<String, Object> get properties => const {'label': 'Loyer'};
}

class _Sink implements UsageSink {
  bool? startedOn;
  final calls = <String>[];
  final sent = <String>[];
  final errors = <RedactedError>[];

  @override
  Future<void> start({required bool on}) async => startedOn = on;

  @override
  Future<void> turnOn() async => calls.add('on');

  @override
  Future<void> turnOff() async => calls.add('off');

  @override
  Future<void> describe(Map<String, Object> context) async {}

  @override
  Future<void> send(String name, Map<String, Object> properties) async =>
      sent.add(name);

  @override
  Future<void> sendError(RedactedError error, StackTrace? stack) async =>
      errors.add(error);

  @override
  Future<void> flush() async {}
}

class _NoBiometrics implements Biometrics {
  @override
  Future<bool> available() async => false;

  @override
  Future<bool> authenticate(String reason) async => false;
}

class _NoPrivacy implements PrivacyPlatform {
  @override
  Future<bool> canHidePreview() async => true;

  @override
  Future<void> apply({
    required bool allowScreenshots,
    required bool hideInRecents,
    required bool androidCopy,
  }) async {}
}
