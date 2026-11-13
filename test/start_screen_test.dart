import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/main.dart';
import 'package:kibuo/ui/start/start_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('the logo and the name stay 1.5 s, then Accueil opens', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(const KibuoApp());
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.bySemanticsLabel('Kibuo'), findsOneWidget);
    expect(find.text('Aujourd’hui'), findsNothing);
    // On a real surface: no debug underline under the name.
    final name = tester.widget<Text>(find.text('Kibuo'));
    final style = DefaultTextStyle.of(tester.element(find.text('Kibuo'))).style
        .merge(name.style);
    expect(style.decoration, isNot(TextDecoration.underline));

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
}
