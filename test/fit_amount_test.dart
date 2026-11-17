import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/long_amounts.dart';
import 'package:kibuo/ui/money/fit_amount.dart';

void main() {
  setUp(() => longAmountsChoice.value = LongAmounts.auto);

  Future<void> show(WidgetTester tester, double width, {bool long = true}) =>
      tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: width,
              child: FitAmount(
                long: long,
                style: const TextStyle(fontSize: 20),
                span: (short) =>
                    TextSpan(text: short ? '128,5 M FC' : '128 450 300 FC'),
              ),
            ),
          ),
        ),
      );

  testWidgets('automatic: whole when it fits, short when it does not', (
    tester,
  ) async {
    await show(tester, 600);
    expect(find.text('128 450 300 FC'), findsOneWidget);
    await show(tester, 120);
    expect(find.text('128,5 M FC'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(FitAmount)).label,
      '128 450 300 FC',
      reason: 'read whole',
    );
  });

  testWidgets('always: short from 10 000, even with room', (tester) async {
    longAmountsChoice.value = LongAmounts.always;
    await show(tester, 600);
    expect(find.text('128,5 M FC'), findsOneWidget);
    await show(tester, 600, long: false);
    expect(find.text('128 450 300 FC'), findsOneWidget);
  });

  testWidgets('never: whole, even without room', (tester) async {
    longAmountsChoice.value = LongAmounts.never;
    await show(tester, 120);
    expect(find.text('128 450 300 FC'), findsOneWidget);
  });
}
