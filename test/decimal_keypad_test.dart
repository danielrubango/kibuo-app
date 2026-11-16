import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/accounts_screen.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  for (final lang in ['fr', 'en']) {
    // The keypad shows « . » in English: the app must still read it as the
    // decimal comma, not a digit (it froze on « 20. »).
    testWidgets('a decimal in « Solde actuel » ($lang)', (tester) async {
      final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
      addTearDown(db.close);
      final accounts = AccountRepository(db);
      final currencies = CurrencyRepository(db);
      await currencies.ensurePrimaryCurrency('US');
      await accounts.create(
        name: 'M-Pesa',
        type: AccountType.mobile,
        opening: const Money(2000, 'USD'),
        openingDate: DateTime.utc(2026, 11, 1),
      );
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.localesTestValue = [Locale(lang, 'US')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('kibuo/device'),
        (call) async => 'US',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: KibuoTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appLanguages,
          localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
          home: AccountsScreen(
            accounts: accounts,
            currencies: currencies,
            categories: CategoryRepository(db),
            transactions: TransactionRepository(db),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('M-Pesa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();
      final sep = lang == 'fr' ? ',' : '.';
      await tester.tap(find.text(sep).last);
      await tester.pump();
      await tester.tap(find.text('5').last);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('20${lang == 'fr' ? ',' : '.'}5'),
        findsOneWidget,
      );
    });
  }

  for (final allowed in [true, false]) {
    testWidgets(
      'holding « , » flips the sign, only with overdraft ($allowed)',
      (tester) async {
        final db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
        addTearDown(db.close);
        final accounts = AccountRepository(db);
        final currencies = CurrencyRepository(db);
        await currencies.ensurePrimaryCurrency('US');
        await accounts.create(
          name: 'Rawbank',
          type: AccountType.bank,
          opening: const Money(2000, 'USD'),
          openingDate: DateTime.utc(2026, 11, 1),
          overdraft: Overdraft(allowed: allowed),
        );
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.localesTestValue = const [Locale('fr', 'US')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('kibuo/device'),
          (call) async => 'US',
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: KibuoTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: appLanguages,
            localeListResolutionCallback: (phone, _) =>
                resolveAppLanguage(phone),
            home: AccountsScreen(
              accounts: accounts,
              currencies: currencies,
              categories: CategoryRepository(db),
              transactions: TransactionRepository(db),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Rawbank'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('20'));
        await tester.pumpAndSettle();

        expect(
          find.text('Maintenez « , » pour un solde négatif.'),
          allowed ? findsOneWidget : findsNothing,
        );
        expect(find.text('−'), allowed ? findsOneWidget : findsNothing);
        await tester.longPress(find.text(',').last);
        await tester.pumpAndSettle();
        expect(find.text('−20'), allowed ? findsOneWidget : findsNothing);
      },
    );
  }
}
