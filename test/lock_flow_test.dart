import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/domain/lock/lock_rules.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/lock_gate.dart';
import 'package:kibuo/ui/lock/pin_pad.dart';
import 'package:kibuo/ui/shell/app_shell.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

class _MemoryVault implements KeyVault {
  final values = <String, String>{};

  @override
  Future<String?> read(String name) async => values[name];

  @override
  Future<void> write(String name, String value) async => values[name] = value;

  @override
  Future<void> delete(String name) async => values.remove(name);

  @override
  Future<void> deleteAll() async => values.clear();
}

class _FakeBiometrics implements Biometrics {
  bool has = false;
  bool succeeds = true;
  int asked = 0;

  @override
  Future<bool> available() async => has;

  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    return succeeds;
  }
}

class _FakePrivacy implements PrivacyPlatform {
  bool? screenshots;
  bool? hidden;

  @override
  Future<bool> canHidePreview() async => true;

  @override
  Future<void> apply({
    required bool allowScreenshots,
    required bool hideInRecents,
  }) async {
    screenshots = allowScreenshots;
    hidden = hideInRecents;
  }
}

void main() {
  late _MemoryVault vault;
  late _FakeBiometrics biometrics;
  late _FakePrivacy privacy;
  late int erased;

  setUp(() {
    vault = _MemoryVault();
    biometrics = _FakeBiometrics();
    privacy = _FakePrivacy();
    erased = 0;
  });

  LockController controller() =>
      LockController(vault: vault, biometrics: biometrics, privacy: privacy);

  Future<LockController> start(WidgetTester tester, {String? pin}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final lock = controller();
    if (pin != null) await lock.pins.setPin(pin);
    await lock.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: LockGate(
          controller: lock,
          eraseAll: () async {
            erased++;
            await vault.deleteAll();
            await lock.load();
          },
          child: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return lock;
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('without a code, Kibuo opens directly', (tester) async {
    await start(tester);

    expect(find.text('Aujourd’hui'), findsOneWidget);
    expect(find.text('Entrez votre code'), findsNothing);
  });

  testWidgets('a code is created from Plus › Sécurité › Verrouillage', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sécurité'));
    await tester.pumpAndSettle();
    expect(find.text('Aucun code'), findsOneWidget);
    await tester.tap(find.text('Verrouillage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un code'));
    await tester.pumpAndSettle();

    await type(tester, '13579');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    expect(find.text('Retapez votre code'), findsOneWidget);
    await type(tester, '13579');

    expect(find.text('Modifier le code'), findsOneWidget);
    expect(find.text('5 chiffres'), findsOneWidget);
    expect(vault.values.values, isNot(contains('13579')));
  });

  testWidgets('codes that differ are asked again', (tester) async {
    await start(tester);
    final lock = KibuoLock.controllerOf(tester.element(find.byType(AppShell)));
    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sécurité'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verrouillage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un code'));
    await tester.pumpAndSettle();

    await type(tester, '1234');
    await tester.tap(find.text('Valider'));
    await tester.pumpAndSettle();
    await type(tester, '4321');

    expect(
      find.text('Les deux codes ne correspondent pas. Recommencez.'),
      findsOneWidget,
    );
    expect(lock.hasPin, isFalse);
  });

  testWidgets('with a code, Kibuo starts locked and the code opens it', (
    tester,
  ) async {
    await start(tester, pin: '2468');
    expect(find.text('Entrez votre code'), findsOneWidget);

    await type(tester, '1111');
    expect(find.text('Code incorrect. Essai 1 sur 5.'), findsOneWidget);

    await type(tester, '2468');
    expect(find.text('Entrez votre code'), findsNothing);
    expect(find.text('Aujourd’hui'), findsOneWidget);
  });

  testWidgets('the boxes and the keypad are centred on the screen', (
    tester,
  ) async {
    await start(tester, pin: '2468');
    final middle =
        tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

    expect(tester.getCenter(find.byType(PinKeypad)).dx, closeTo(middle, 0.5));
    expect(tester.getCenter(find.byType(PinBoxes)).dx, closeTo(middle, 0.5));
  });

  testWidgets('the delay is picked in a sheet', (tester) async {
    final lock = await start(tester, pin: '2468');
    await type(tester, '2468');
    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sécurité'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verrouillage'));
    await tester.pumpAndSettle();
    expect(find.text('1 minute'), findsOneWidget);

    await tester.tap(find.text('Verrouiller après'));
    await tester.pumpAndSettle();
    for (final d in ['Aussitôt', '30 secondes', '5 minutes', '15 minutes']) {
      expect(find.text(d), findsOneWidget);
    }
    await tester.tap(find.text('15 minutes'));
    await tester.pumpAndSettle();

    expect(lock.settings.delay, AutoLockDelay.fifteenMinutes);
    expect(find.text('15 minutes'), findsOneWidget);
  });

  testWidgets('five wrong codes make the user wait', (tester) async {
    await start(tester, pin: '2468');

    for (var i = 0; i < 5; i++) {
      await type(tester, '1111');
    }

    expect(find.text('Trop d’essais'), findsOneWidget);
    expect(find.textContaining('Réessayez dans'), findsOneWidget);
  });

  testWidgets('the fingerprint is asked first when it is on', (tester) async {
    biometrics.has = true;
    await vault.write('lock_fingerprint', 'true');
    await start(tester, pin: '2468');

    expect(biometrics.asked, 1);
    expect(find.text('Aujourd’hui'), findsOneWidget);
  });

  testWidgets('a forgotten code: holding the button erases everything', (
    tester,
  ) async {
    await start(tester, pin: '2468');
    await tester.tap(find.text('Code oublié ?'));
    await tester.pumpAndSettle();

    final hold = await tester.startGesture(
      tester.getCenter(find.text('Maintenir pour effacer')),
    );
    await tester.pump(); // the fill starts on the next frame
    await tester.pump(const Duration(milliseconds: 600));
    expect(erased, 0, reason: 'a short press does nothing');
    await tester.pump(const Duration(milliseconds: 700));
    await hold.up();
    await tester.pumpAndSettle();

    expect(erased, 1);
    expect(find.text('Entrez votre code'), findsNothing);
    expect(find.text('Aujourd’hui'), findsOneWidget);
  });

  test('coming back after the chosen absence locks again', () async {
    var now = DateTime(2026, 11, 15, 10);
    final lock = LockController(
      vault: vault,
      biometrics: biometrics,
      privacy: privacy,
      now: () => now,
    );
    await lock.pins.setPin('2468');
    await lock.load();
    lock.unlock();

    lock.left();
    now = now.add(const Duration(seconds: 30));
    lock.returned();
    expect(lock.locked, isFalse, reason: 'within 1 minute');

    lock.left();
    now = now.add(const Duration(minutes: 2));
    lock.returned();
    expect(lock.locked, isTrue);
  });

  test('privacy choices reach Android', () async {
    final lock = controller();
    await lock.load();
    expect(privacy.hidden, isTrue);
    expect(privacy.screenshots, isTrue);

    await lock.updateSettings(lock.settings.copyWith(allowScreenshots: false));

    expect(privacy.screenshots, isFalse);
  });
}
