import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/accounts/account_type_screen.dart';
import 'package:kibuo/ui/accounts/account_types_screen.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/shell/add_sheet.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late AccountRepository accounts;

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    accounts = AccountRepository(db);
  });
  tearDown(() => db.close());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> show(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: home,
      ),
    );
    await settle(tester);
  }

  testWidgets('the + sheet: « Dépense » 72 high, the others 64', (
    tester,
  ) async {
    await show(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showAddSheet(context),
          child: const Text('+'),
        ),
      ),
    );
    await tester.tap(find.text('+'));
    await settle(tester);
    double height(String label) => tester
        .getSize(
          find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first,
        )
        .height;
    // The title about 32 from the sheet's edge (canvas PlusBtnB1).
    final sheetTop = tester.getTopLeft(find.byType(BottomSheet)).dy;
    final titleTop = tester.getTopLeft(find.text('Ajouter')).dy;
    expect(titleTop - sheetTop, inInclusiveRange(28, 36));
    expect(height('Dépense'), 72);
    expect(height('Revenu'), 64);
    expect(height('Transfert'), 64);
  });

  testWidgets('« Enregistrer » rides above the keyboard', (tester) async {
    await show(tester, AccountTypeScreen(accounts: accounts));
    tester.view.viewInsets = const FakeViewPadding(bottom: 800);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final button = tester.getRect(find.byType(KibuoButton));
    final keyboardTop = 2400 / 2.75 - 800 / 2.75;
    expect(button.bottom, lessThanOrEqualTo(keyboardTop - 8));
  });

  testWidgets('types: the provided ones fixed, one’s own changed', (
    tester,
  ) async {
    final id = await accounts.createType(name: 'Tontine', icon: 'users');
    await show(tester, AccountTypesScreen(accounts: accounts));
    expect(find.text('Fournis par kibuo'), findsOneWidget);
    expect(find.text('Espèces'), findsOneWidget);
    await tester.tap(find.text('Tontine'));
    await settle(tester);
    expect(find.text('Modifier le type'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Likelemba');
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(find.text('Likelemba'), findsOneWidget);
    expect((await accounts.types()).single.id, id);
  });

  testWidgets('a type in use cannot be deleted; unused, it can', (
    tester,
  ) async {
    final id = await accounts.createType(name: 'Tontine', icon: 'users');
    final account = await accounts.create(
      name: 'Tontine du quartier',
      type: AccountType.custom(id),
      opening: const Money(0, 'CDF'),
      openingDate: DateTime.utc(2026),
    );
    await show(tester, AccountTypesScreen(accounts: accounts));
    await tester.tap(find.text('Tontine'));
    await settle(tester);
    expect(
      find.text('1 compte est de ce type : changez-le d’abord.'),
      findsOneWidget,
    );
    final delete = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Supprimer ce type'),
        matching: find.byType(TextButton),
      ),
    );
    expect(delete.onPressed, isNull);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await accounts.update(account, name: 'Tontine', type: AccountType.cash);
    await tester.tap(find.text('Tontine'));
    await settle(tester);
    await tester.tap(find.text('Supprimer ce type'));
    await settle(tester);
    await tester.tap(find.text('Supprimer'));
    await settle(tester);
    expect(await accounts.types(), isEmpty);
    expect(find.text('Les vôtres'), findsNothing);
  });
}
