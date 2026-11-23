import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/ui/kit/scrolling_line.dart';

void main() {
  const style = TextStyle(fontSize: 12);
  const long =
      'Avec les autres, à leur date. Sans date : dans « Sans échéance ».';

  Future<void> show(
    WidgetTester tester,
    String text, {
    bool still = false,
    int? runs,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: still),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 120,
            child: ScrollingLine(text, style: style, runs: runs),
          ),
        ),
      ),
    ),
  );

  double offset(WidgetTester tester) => tester
      .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
      .controller!
      .offset;

  testWidgets('a cut line waits, slides to its end, comes back', (
    tester,
  ) async {
    await show(tester, long);
    await tester.pump();
    expect(offset(tester), 0);
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(seconds: 1));
    expect(offset(tester), greaterThan(0));
    // To its end, the pause, the fade: back at the start.
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(offset(tester), 0);
  });

  testWidgets('a line that fits, or fewer animations: still', (tester) async {
    await show(tester, 'Court');
    expect(find.byType(SingleChildScrollView), findsNothing);
    await show(tester, long, still: true);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text(long), findsOneWidget);
  });

  testWidgets('with runs, it stops at its start after them', (tester) async {
    await show(tester, long, runs: 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(offset(tester), 0);
    // No new slide after the pause.
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(offset(tester), 0);
  });
}
