import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/main.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  testWidgets('the app starts on the validated light theme', (tester) async {
    await tester.pumpWidget(const KibuoApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.scaffoldBackgroundColor, KibuoColors.background);
    expect(app.theme?.colorScheme.primary, KibuoColors.mint);
    await tester.pump(const Duration(seconds: 2));
  });

  test('titles and amounts use Plus Jakarta Sans, running text uses Inter', () {
    final text = KibuoTheme.textTheme();

    expect(text.displayLarge?.fontFamily, KibuoTheme.displayFont);
    expect(text.headlineLarge?.fontFamily, KibuoTheme.displayFont);
    expect(text.bodyLarge?.fontFamily, KibuoTheme.textFont);
    expect(text.labelLarge?.fontFamily, KibuoTheme.textFont);
  });

  test('variable fonts get their weight axis set', () {
    final bold = KibuoTheme.textTheme().displayLarge!;

    expect(bold.fontWeight, FontWeight.w700);
    expect(bold.fontVariations?.single.value, 700);
  });
}
