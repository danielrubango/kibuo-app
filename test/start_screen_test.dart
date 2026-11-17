import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/main.dart';
import 'package:kibuo/ui/brand/kibuo_mark.dart';
import 'package:kibuo/ui/brand/kibuo_wordmark.dart';
import 'package:kibuo/ui/start/start_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  // A French-speaking phone.
  tester.platformDispatcher.localesTestValue = const [Locale('fr')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

void main() {
  testWidgets('the logo and the name stay 1.5 s, then Accueil opens', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(const KibuoApp());
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.bySemanticsLabel('kibuo'), findsWidgets);
    expect(find.text('Aujourd’hui'), findsNothing);
    // The name in lowercase, the coin as the dot of its i, and on a real
    // surface: no debug underline under it.
    expect(find.byType(KibuoWordmark), findsOneWidget);
    expect(find.byKey(const ValueKey('kibuo-coin')), findsOneWidget);
    final name = find.descendant(
      of: find.byType(KibuoWordmark),
      matching: find.byType(RichText),
    );
    final text = tester.widget<RichText>(name.first).text;
    expect(text.toPlainText(), contains('buo'));
    expect(text.style!.decoration, TextDecoration.none);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Aujourd’hui'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Aujourd’hui'), findsOneWidget);
    expect(find.byType(StartScreen), findsNothing);
  });

  testWidgets('a slow start keeps the start screen until the app is ready', (
    tester,
  ) async {
    _phone(tester);
    final ready = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        home: StartGate(ready: ready.future, child: const Text('Suite')),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Suite'), findsNothing);

    ready.complete();
    await tester.pumpAndSettle();
    expect(find.text('Suite'), findsOneWidget);
  });

  testWidgets('the logo is centred on the screen at Android’s size', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(const KibuoApp());
    await tester.pump();

    final logo = find.descendant(
      of: find.byType(StartScreen),
      matching: find.byType(CustomPaint),
    );
    final rect = tester.getRect(logo.first);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(rect.center.dx, closeTo(screen.width / 2, .01));
    expect(rect.center.dy, closeTo(screen.height / 2, .01));
    expect(rect.width, closeTo(StartScreen.logoBox, .01));

    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('with « Supprimer les animations », nothing moves', (
    tester,
  ) async {
    _phone(tester);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const KibuoApp());
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the coin bounces in, the piggy bank takes it, the name closes '
      'up', (tester) async {
    _phone(tester);
    await tester.pumpWidget(
      MaterialApp(theme: KibuoTheme.light(), home: const StartScreen()),
    );
    await tester.pump();
    KibuoMarkPainter mark() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((c) => c.painter)
        .whereType<KibuoMarkPainter>()
        .single;
    double spacing() =>
        tester.widget<KibuoWordmark>(find.byType(KibuoWordmark)).letterSpacing!;

    await tester.pump(const Duration(milliseconds: 300));
    expect(mark().coinDrop, closeTo(4, .2), reason: 'the fall');
    await tester.pump(const Duration(milliseconds: 180));
    expect(mark().squash, greaterThan(.5), reason: 'the piggy bank takes it');
    expect(spacing(), greaterThan(2), reason: 'letters still apart');

    await tester.pump(const Duration(milliseconds: 600));
    expect(mark().coinDrop, 3);
    expect(mark().squash, 0);
    expect(spacing(), closeTo(-.5, .01));
  });
}
