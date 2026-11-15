import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/design_system_screen.dart';
import 'package:kibuo/ui/kit/fields.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  Future<void> show(WidgetTester tester, Widget home, {double width = 360}) {
    tester.view.physicalSize = Size(width * 2, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
  }

  testWidgets('every piece of the design system fits a small phone', (
    tester,
  ) async {
    await show(tester, const DesignSystemScreen(), width: 340);
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 40; i++) {
      await tester.drag(list, const Offset(0, -400));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a typed value sits on the left, its currency on the right', (
    tester,
  ) async {
    await show(
      tester,
      const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: ValueField(prefix: '1 \$ =', value: '2 850', unit: 'FC'),
        ),
      ),
    );
    final field = tester.getRect(find.byType(ValueField));
    final value = tester.getRect(find.text('2 850'));
    final unit = tester.getRect(find.byType(CurrencyPill));
    expect(value.left - field.left, lessThan(field.width / 3));
    expect(field.right - unit.right, lessThanOrEqualTo(10));
  });
}
