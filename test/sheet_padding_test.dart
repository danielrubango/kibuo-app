import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/ui/kit/sheet.dart';

void main() {
  Future<EdgeInsets> paddingWith(
    WidgetTester tester, {
    required double keyboard,
  }) async {
    late EdgeInsets padding;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          viewPadding: const EdgeInsets.only(bottom: 24),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: Builder(
          builder: (context) {
            padding = sheetPadding(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return padding;
  }

  testWidgets('keyboard closed: 24 above the phone’s own bar', (tester) async {
    final padding = await paddingWith(tester, keyboard: 0);
    expect(padding.bottom, 24 + 24);
    expect(padding.left, 16);
    expect(padding.right, 16);
  });

  testWidgets('keyboard open: 8 above it, like a screen (25 November)', (
    tester,
  ) async {
    // The phone's bar is under the keyboard: it does not count.
    final padding = await paddingWith(tester, keyboard: 300);
    expect(padding.bottom, 8);
  });
}
