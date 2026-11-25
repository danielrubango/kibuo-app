import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/categories/categories_screen.dart';
import 'package:kibuo/ui/categories/category_form_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late CategoryRepository repo;

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'phone-1');
    repo = CategoryRepository(db);
  });
  tearDown(() => db.close());

  Future<void> start(
    WidgetTester tester, {
    Locale locale = const Locale('fr'),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: CategoriesScreen(categories: repo),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field() => find.descendant(
    of: find.byType(CategoryFormScreen),
    matching: find.byType(TextField),
  );

  testWidgets('adding a category, then a subcategory under it', (tester) async {
    await start(tester);

    await tester.tap(find.text('Ajouter une catégorie'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle catégorie'), findsOneWidget);
    await tester.enterText(field(), 'Église');
    await tester.pump();
    await tester.tap(find.text('Créer la catégorie'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Église'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Église'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Église').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajouter une sous-catégorie'));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle sous-catégorie'), findsOneWidget);
    expect(find.text('Église'), findsOneWidget, reason: '« Dans »');
    await tester.enterText(field(), 'Offrande');
    await tester.pump();
    await tester.tap(find.text('Créer la sous-catégorie'));
    await tester.pumpAndSettle();

    final church = (await repo.categories(CategoryKind.out)).last;
    expect(church.subs.single.name, 'Offrande');
  });
}
