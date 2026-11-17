import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/ui/kit/cards.dart';

void main() {
  testWidgets('touching the words flips the switch, as on Android', (
    tester,
  ) async {
    var on = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, set) => SettingsSwitch(
              label: 'Autoriser le découvert',
              help: 'Le solde peut descendre sous zéro',
              value: on,
              onChanged: (v) => set(() => on = v),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Le solde peut descendre sous zéro'));
    await tester.pump();
    expect(on, isTrue);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(on, isFalse);
  });
}
