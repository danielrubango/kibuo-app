import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/main.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';

Future<void> _start(WidgetTester tester, {bool reduceMotion = false}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  await tester.pumpWidget(const KibuoApp());
  // Past the start screen.
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

List<String> _haptics(WidgetTester tester) {
  final calls = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

void main() {
  testWidgets('tapping + bounces it, then opens the sheet', (tester) async {
    await _start(tester);

    await tester.tap(find.bySemanticsLabel('Ajouter une opération'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Ajouter'), findsOneWidget);
  });

  testWidgets('choosing a tab fills its icon and opens the pill', (
    tester,
  ) async {
    await _start(tester);

    await tester.tap(find.text('Aperçu'));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();

    expect(find.byIcon(KibuoIcons.chartBarFill), findsOneWidget);
    expect(find.byIcon(KibuoIcons.house), findsOneWidget);
  });

  testWidgets('with « Supprimer les animations », the tab changes at once', (
    tester,
  ) async {
    await _start(tester, reduceMotion: true);

    await tester.tap(find.text('Aperçu'));
    await tester.pump();

    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byIcon(KibuoIcons.chartBarFill), findsOneWidget);
  });

  testWidgets('holding + vibrates once, and again on each new choice', (
    tester,
  ) async {
    await _start(tester);
    final haptics = _haptics(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Ajouter une opération')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.mediumImpact']);

    await gesture.moveTo(tester.getCenter(find.text('Revenu')));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('Transfert')));
    await tester.pump();

    expect(haptics, [
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.selectionClick',
    ]);
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
