import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/main.dart';
import 'package:kibuo/ui/app_language.dart';

Future<void> _startIn(WidgetTester tester, List<Locale> phone) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = phone;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const KibuoApp());
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  group('the language follows the phone', () {
    test('French or English when the phone uses it', () {
      expect(
        resolveAppLanguage(const [Locale('fr', 'CD')]),
        const Locale('fr'),
      );
      expect(
        resolveAppLanguage(const [Locale('en', 'US')]),
        const Locale('en'),
      );
    });

    test('the first language Kibuo speaks in the phone’s list', () {
      expect(
        resolveAppLanguage(const [Locale('sw'), Locale('en'), Locale('fr')]),
        const Locale('en'),
      );
    });

    test('French when the phone speaks neither', () {
      expect(
        resolveAppLanguage(const [Locale('sw', 'CD')]),
        const Locale('fr'),
      );
      expect(resolveAppLanguage(const [Locale('ln')]), const Locale('fr'));
      expect(resolveAppLanguage(null), const Locale('fr'));
    });
  });

  testWidgets('an English phone gets English everywhere', (tester) async {
    await _startIn(tester, const [Locale('en', 'GB')]);

    expect(find.text('Today'), findsOneWidget);
    for (final tab in ['Home', 'Transactions', 'Overview', 'More']) {
      expect(find.text(tab), findsOneWidget);
    }

    await tester.tap(find.bySemanticsLabel('Add a transaction'));
    await tester.pumpAndSettle();
    expect(find.text('Add'), findsOneWidget);
    for (final choice in ['Expense', 'Income', 'Transfer', 'Debt', 'Savings']) {
      expect(find.text(choice), findsOneWidget);
    }

    await tester.tap(find.text('Expense'));
    await tester.pumpAndSettle();
    expect(find.text('New expense'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('a Swahili phone gets French', (tester) async {
    await _startIn(tester, const [Locale('sw', 'CD')]);

    expect(find.text('Aujourd’hui'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
  });
}
