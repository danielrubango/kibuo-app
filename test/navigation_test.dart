import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/main.dart';

Future<void> _start(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  // A French-speaking phone.
  tester.platformDispatcher.localesTestValue = const [Locale('fr')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const KibuoApp());
  // Past the start screen.
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Finder _plusButton() => find.bySemanticsLabel('Ajouter une opération');

void main() {
  group('bottom bar', () {
    testWidgets('opens on Accueil with the four tabs and the + button', (
      tester,
    ) async {
      await _start(tester);

      expect(find.text('Aujourd’hui'), findsOneWidget);
      for (final tab in ['Accueil', 'Opérations', 'Aperçu', 'Plus']) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(_plusButton(), findsOneWidget);
      expect(tester.getSize(_plusButton()), const Size(62, 62));
    });

    testWidgets('a tab shows its screen', (tester) async {
      await _start(tester);

      await tester.tap(find.text('Opérations'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('screen-operations')), findsOneWidget);
    });

    testWidgets('back from another tab returns to Accueil', (tester) async {
      await _start(tester);
      await tester.tap(find.text('Aperçu'));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Aujourd’hui'), findsOneWidget);
    });
  });

  group('tapping +', () {
    testWidgets('opens the « Ajouter » sheet with the five choices', (
      tester,
    ) async {
      await _start(tester);

      await tester.tap(_plusButton());
      await tester.pumpAndSettle();

      expect(find.text('Ajouter'), findsOneWidget);
      for (final choice in [
        'Dépense',
        'Revenu',
        'Transfert',
        'Dette',
        'Projet',
      ]) {
        expect(find.text(choice), findsOneWidget);
      }
    });

    testWidgets('a choice opens its entry screen without the bottom bar', (
      tester,
    ) async {
      await _start(tester);
      await tester.tap(_plusButton());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Dépense'));
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle dépense'), findsOneWidget);
      expect(_plusButton(), findsNothing);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      expect(find.text('Nouvelle dépense'), findsNothing);
      expect(_plusButton(), findsOneWidget);
    });
  });

  group('holding +', () {
    testWidgets(
      'shows the fan, and sliding to a choice then lifting opens it',
      (tester) async {
        await _start(tester);

        final gesture = await tester.startGesture(
          tester.getCenter(_plusButton()),
        );
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();

        expect(
          find.text('Glissez vers un choix, ou touchez-le'),
          findsOneWidget,
        );

        await gesture.moveTo(tester.getCenter(find.text('Revenu')));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('Nouveau revenu'), findsOneWidget);
      },
    );

    testWidgets('lifting the finger elsewhere keeps the fan open to tap', (
      tester,
    ) async {
      await _start(tester);

      final gesture = await tester.startGesture(
        tester.getCenter(_plusButton()),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transfert'));
      await tester.pumpAndSettle();

      expect(find.text('Nouveau transfert'), findsOneWidget);
    });

    testWidgets('touching the dark background closes the fan', (tester) async {
      await _start(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(_plusButton()),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(40, 120));
      await tester.pumpAndSettle();

      expect(find.text('Glissez vers un choix, ou touchez-le'), findsNothing);
    });
  });
}
