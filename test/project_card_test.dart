import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/projects/project_screen.dart';
import 'package:kibuo/ui/projects/projects_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

String plain(String s) => s.replaceAll(RegExp('[\\u00A0\\u202F]'), ' ');

/// A text, its narrow spaces read as spaces.
Finder shown(String text, {bool part = false}) => find.byWidgetPredicate((w) {
  if (w is! Text) return false;
  final t = plain(w.data ?? w.textSpan?.toPlainText() ?? '');
  return part ? t.contains(text) : t == text;
});

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late ProjectRepository projects;
  late String mpesa;
  final now = DateTime(2026, 11, 24, 10);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    projects = ProjectRepository(db);
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      projects: projects,
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(50000, 'USD'),
      openingDate: DateTime.utc(2026),
    );
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

  Future<String> trip({int saved = 15000, int goal = 30000}) async {
    final id = await projects.create(
      name: 'Voyage',
      icon: 'airplane',
      accountId: mpesa,
      goal: goal,
      startedOn: DateTime(2026, 11, 1),
      due: DateTime(2027, 1, 1),
    );
    await projects.putAside(id, amount: saved, date: DateTime(2026, 11, 2));
    return id;
  }

  Widget card(String id) =>
      ProjectScreen(data: data, projects: projects, id: id, now: () => now);

  /// Without settling: the confirmation closes by itself after a while.
  Future<void> soft(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> done(WidgetTester tester) async {
    // The toast's time runs out.
    await tester.pump(const Duration(seconds: 10));
    await settle(tester);
  }

  testWidgets('put aside: the part of the week, then a new line', (
    tester,
  ) async {
    final id = await trip();
    await show(tester, card(id));
    await tester.tap(find.text('Mettre de côté'));
    await settle(tester);
    expect(find.text('Mettre de côté pour Voyage'), findsOneWidget);
    expect(find.text('cette semaine'), findsOneWidget);
    await tester.tap(find.text('Mettre de côté').last);
    await soft(tester);
    expect((await projects.project(id))!.saved.minor, 18000);
    expect(find.text('Mis de côté'), findsOneWidget);
    await done(tester);
    expect(find.text('Mis de côté'), findsNothing);
    expect(shown('+30,00 \$'), findsOneWidget);
  });

  testWidgets('« Annuler » on the confirmation undoes it', (tester) async {
    final id = await trip();
    await show(tester, card(id));
    await tester.tap(find.text('Mettre de côté'));
    await settle(tester);
    await tester.tap(find.text('Mettre de côté').last);
    await soft(tester);
    await tester.tap(find.text('Annuler'));
    await settle(tester);
    expect((await projects.project(id))!.saved.minor, 15000);
    expect(shown('+30,00 \$'), findsNothing);
  });

  testWidgets('from another account: the transfer said, and refused '
      'beyond what is free there', (tester) async {
    final id = await trip();
    await data.accounts.create(
      name: 'Rawbank',
      type: AccountType.bank,
      opening: const Money(1000, 'USD'),
      openingDate: DateTime.utc(2026),
    );
    await show(tester, card(id));
    await tester.tap(find.text('Mettre de côté'));
    await settle(tester);
    await tester.tap(find.text('Pris sur'));
    await settle(tester);
    await tester.tap(find.text('Rawbank').last);
    await settle(tester);
    expect(
      find.text('Un transfert de Rawbank vers M-Pesa sera enregistré.'),
      findsOneWidget,
    );
    expect(shown('Seulement 10,00 \$ libres sur Rawbank.'), findsOneWidget);
    await tester.tap(find.text('Mettre de côté').last);
    await settle(tester);
    expect((await projects.project(id))!.saved.minor, 15000);
  });

  testWidgets('taken back: all of it, nothing moves', (tester) async {
    final id = await trip();
    await show(tester, card(id));
    await tester.tap(find.text('Reprendre de l’argent'));
    await settle(tester);
    expect(find.text('Tout'), findsOneWidget);
    await tester.tap(find.text('Reprendre'));
    await soft(tester);
    expect((await projects.project(id))!.saved.minor, 0);
    expect(find.text('Argent repris'), findsOneWidget);
    await done(tester);
    expect(shown('−150,00 \$'), findsOneWidget);
    expect(await data.transactions.all(), isEmpty);
  });

  testWidgets('the goal met: « Objectif atteint », then made available', (
    tester,
  ) async {
    final id = await trip(saved: 25000);
    await show(tester, card(id));
    await tester.tap(find.text('Mettre de côté'));
    await settle(tester);
    await tester.tap(find.text('ce qui manque'));
    await settle(tester);
    await tester.tap(find.text('Mettre de côté').last);
    await settle(tester);
    expect(find.text('Objectif atteint'), findsWidgets);
    expect(find.text('Le rendre disponible'), findsOneWidget);
    await tester.tap(find.text('Le rendre disponible'));
    await soft(tester);
    expect(find.text('Voyage est terminé'), findsOneWidget);
    await done(tester);
    final p = (await projects.project(id))!;
    expect(p.running, isFalse);
    expect(p.ending, 'released');
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('Supprimer le projet'), findsOneWidget);
    expect(find.text('Mettre de côté'), findsNothing);
    await done(tester);
  });

  testWidgets('changed, then deleted with its payments', (tester) async {
    final id = await trip();
    await show(
      tester,
      ProjectsScreen(data: data, projects: projects, now: () => now),
    );
    await tester.tap(find.text('Voyage'));
    await settle(tester);
    await tester.tap(find.text('Modifier'));
    await settle(tester);
    expect(find.text('Modifier le projet'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Voyage à Goma');
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect((await projects.project(id))!.name, 'Voyage à Goma');
    expect(find.text('Voyage à Goma'), findsOneWidget);
    await tester.tap(find.text('Modifier'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('Supprimer le projet'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Supprimer le projet'));
    await settle(tester);
    expect(
      shown('Les 150,00 \$ mis de côté redeviennent libres', part: true),
      findsOneWidget,
    );
    await tester.tap(find.text('Supprimer'));
    await settle(tester);
    expect(await projects.project(id), equals(null));
    expect(find.text('Aucun projet'), findsOneWidget);
  });
}
