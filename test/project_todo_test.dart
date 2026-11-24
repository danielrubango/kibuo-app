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
import 'package:kibuo/data/todo_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/home/home_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late ProjectRepository projects;
  late String mpesa;
  final now = DateTime.now();
  // At midnight: never in the future, whatever the hour of the run.
  final today = DateTime(now.year, now.month, now.day);

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
      opening: const Money(100000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
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

  Future<void> start(WidgetTester tester) async {
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
        home: Scaffold(
          body: HomeScreen(data: data, todos: TodoStore(db)),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> trip({required int saved}) async {
    final id = await projects.create(
      name: 'Voyage',
      icon: 'airplane',
      accountId: mpesa,
      goal: 70000,
      startedOn: today.subtract(const Duration(days: 40)),
      due: today.add(const Duration(days: 30)),
    );
    if (saved > 0) {
      await projects.putAside(
        id,
        amount: saved,
        date: today.subtract(const Duration(days: 39)),
      );
    }
  }

  testWidgets('a project behind by a part of its plan: « Mettre de côté »', (
    tester,
  ) async {
    await trip(saved: 0);
    await start(tester);
    expect(find.text('Projet · en retard, 30 jours restants'), findsOneWidget);
    await tester.tap(find.text('Mettre de côté'));
    await settle(tester);
    expect(find.text('Mettre de côté pour Voyage'), findsOneWidget);
    expect(find.text('le retard'), findsOneWidget);
  });

  testWidgets('a little behind: not in « À traiter »', (tester) async {
    // 40 of 70 days gone: 40 000 expected; 38 000 is 2 000 behind, less
    // than a week's part.
    await trip(saved: 38000);
    await start(tester);
    expect(find.textContaining('Projet · en retard'), findsNothing);
  });
}
