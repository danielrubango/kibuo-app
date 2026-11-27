import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/amount_sheet.dart';
import 'package:kibuo/ui/kit/keypad.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  String typeAll(String keys, {int decimals = 2}) {
    var typed = '';
    for (final k in keys.split(' ')) {
      typed = typeKey(typed, k, decimals: decimals);
    }
    return typed;
  }

  test('digits, then a comma and at most the currency’s decimals', () {
    expect(typeAll('1 2 , 5 0 7'), '12,50');
    expect(typeAll(', 5'), '0,5');
    expect(typeAll('1 , , 2'), '1,2');
  });

  test('without cents: no comma, and « 000 » adds three zeros', () {
    expect(typeAll('1 4 000', decimals: 0), '14000');
    expect(typeAll('1 , 2', decimals: 0), '12');
    expect(typeAll('000', decimals: 0), '', reason: 'not a leading zero');
  });

  test('a leading zero is replaced', () {
    expect(typeAll('0 7'), '7');
  });

  group('an amount already there (PRODUCT, 27 November 2026)', () {
    test('the first key replaces it', () {
      final typed = KeypadText('40000')..key('5', decimals: 0);
      expect(typed.text, '5');
      expect(typed.selected, isFalse);
      typed.key('0', decimals: 0);
      expect(typed.text, '50', reason: 'then the keys follow on');
    });

    test('the comma first starts a new amount', () {
      final typed = KeypadText('12,50')..key(',', decimals: 2);
      expect(typed.text, '0,');
    });

    test('« ← » takes the last digit off and keeps the rest', () {
      final typed = KeypadText('40000')..delete();
      expect(typed.text, '4000');
      expect(typed.selected, isFalse);
      typed.key('5', decimals: 0);
      expect(typed.text, '40005');
    });

    test('touching the amount keeps it, the keys follow on', () {
      final typed = KeypadText('40000')
        ..keep()
        ..key('5', decimals: 0);
      expect(typed.text, '400005');
    });

    test('an empty field is not selected', () {
      final typed = KeypadText('');
      expect(typed.selected, isFalse);
      typed.key('7', decimals: 2);
      expect(typed.text, '7');
    });
  });

  testWidgets('I repay: 40 000 FC proposed, I type 5, it pays 5 FC', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    Money? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await typeAmount(
              context,
              title: 'Montant',
              start: const Money(4000000, 'CDF'),
            ),
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();
    expect(picked, const Money(500, 'CDF'));
  });
}
