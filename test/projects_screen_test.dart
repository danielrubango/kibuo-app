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
import 'package:kibuo/ui/home/home_screen.dart';
import 'package:kibuo/ui/projects/projects_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

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

  testWidgets('a first project, made from the page', (tester) async {
    await show(
      tester,
      ProjectsScreen(data: data, projects: projects, now: () => now),
    );
    expect(find.text('Aucun projet'), findsOneWidget);
    await tester.tap(find.text('Nouveau projet'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Voyage à Goma');
    await tester.tap(find.text('Objectif'));
    await settle(tester);
    for (final k in ['3', '0', '0']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    await tester.tap(find.text('Terminé'));
    await settle(tester);
    expect(find.text('Créer le projet'), findsOneWidget);
    await tester.tap(find.text('Créer le projet'));
    await settle(tester);
    expect(find.text('Voyage à Goma'), findsOneWidget);
    expect(find.text('Mis de côté · 1 projet'), findsOneWidget);
    expect(find.text('À votre rythme'), findsOneWidget);
    final p = (await projects.projects()).single;
    expect(p.goal, const Money(30000, 'USD'));
  });

  testWidgets('home: available less what projects hold back', (tester) async {
    final id = await projects.create(
      name: 'Moto',
      icon: 'motorcycle',
      accountId: mpesa,
      goal: 80000,
      startedOn: DateTime(2026, 11, 1),
    );
    await projects.addContribution(id, amount: 20000, date: now);
    await show(
      tester,
      Scaffold(
        body: HomeScreen(
          data: data,
          onOpenProjects: () {},
          onNewProject: () {},
        ),
      ),
    );
    String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');
    final texts = [
      for (final t in tester.widgetList<RichText>(find.byType(RichText)))
        plain(t.text.toPlainText()),
    ];
    expect(texts, contains('300,00 \$'));
    expect(texts, contains('Total 500,00 \$'));
    expect(texts, contains('dont projets 200,00 \$'));
  });

  testWidgets('a late card says only how far behind', (tester) async {
    await projects.create(
      name: 'Loyer',
      icon: 'house',
      accountId: mpesa,
      goal: 30000,
      startedOn: DateTime(2026, 11, 1),
      due: DateTime(2026, 12, 1),
    );
    await show(
      tester,
      ProjectsScreen(data: data, projects: projects, now: () => now),
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText &&
            w.text.toPlainText().replaceAll(RegExp('[\\u00A0\\u202F]'), ' ') ==
                'En retard de 230,00 \$',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('par semaine'), findsNothing);
    expect(find.text('Mettre de côté ›'), findsOneWidget);
  });
}
