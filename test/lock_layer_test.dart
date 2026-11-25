import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/lock/lock_controller.dart';
import 'package:kibuo/ui/lock/lock_gate.dart';
import 'package:kibuo/ui/lock/protect_sheet.dart';
import 'package:kibuo/ui/lock/unlock_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

import 'support/memory_vault.dart';

/// The lock covers every screen, not only Accueil: a screen or a sheet
/// opened over it, left open, must not show again without the code; and an
/// important action started from it asks the code (fixed 25 November 2026).
void main() {
  late DateTime now;
  late LockController lock;

  setUp(() async {
    now = DateTime(2026, 11, 25, 10);
    lock = LockController(
      vault: MemoryVault(),
      biometrics: _NoBiometrics(),
      privacy: _NoPrivacy(),
      now: () => now,
    );
    await lock.pins.setPin('2468');
    await lock.load();
    lock.unlock();
  });

  /// As main.dart builds kibuo: the layer above every route, the gate on
  /// Accueil once the data is open.
  Future<BuildContext> start(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    late BuildContext home;
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        builder: (context, child) => LockLayer(child: child!),
        home: LockGate(
          controller: lock,
          eraseAll: () async {},
          child: Builder(
            builder: (context) {
              home = context;
              return const Scaffold(body: Text('Accueil'));
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return home;
  }

  /// Kibuo left for an hour, then back: locked again.
  Future<void> awayAnHour(WidgetTester tester) async {
    lock.left();
    now = now.add(const Duration(hours: 1));
    lock.returned();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('a screen left open is covered once kibuo locks again', (
    tester,
  ) async {
    final home = await start(tester);
    unawaited(
      Navigator.of(home).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Solde du compte')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Solde du compte').hitTestable(), findsOneWidget);

    await awayAnHour(tester);
    expect(find.byType(UnlockScreen).hitTestable(), findsOneWidget);
    expect(find.text('Solde du compte').hitTestable(), findsNothing);
  });

  testWidgets('a sheet left open is covered too', (tester) async {
    final home = await start(tester);
    unawaited(
      showModalBottomSheet<void>(
        context: home,
        builder: (_) => const SizedBox(height: 200, child: Text('Feuille')),
      ),
    );
    await tester.pumpAndSettle();

    await awayAnHour(tester);
    expect(find.byType(UnlockScreen).hitTestable(), findsOneWidget);
    expect(find.text('Feuille').hitTestable(), findsNothing);
  });

  testWidgets('an important action from a pushed screen asks the code', (
    tester,
  ) async {
    await lock.updateSettings(lock.settings.copyWith(protectActions: true));
    final home = await start(tester);
    late BuildContext pushed;
    unawaited(
      Navigator.of(home).push(
        MaterialPageRoute<void>(
          builder: (context) {
            pushed = context;
            return const Scaffold(body: Text('Opération'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    var answered = false;
    unawaited(
      confirmWithCode(pushed, 'Pour supprimer l’opération').then((ok) {
        answered = ok;
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Confirmez avec votre code'), findsOneWidget);
    expect(answered, isFalse);
  });

  testWidgets('Accueil itself is covered as before', (tester) async {
    await start(tester);
    await awayAnHour(tester);
    expect(find.byType(UnlockScreen).hitTestable(), findsOneWidget);
    expect(find.text('Accueil').hitTestable(), findsNothing);
  });
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
