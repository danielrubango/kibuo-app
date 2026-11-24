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
import 'package:kibuo/ui/accounts/accounts_screen.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/projects/project_screen.dart';
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

  testWidgets('Comptes: available and held, the project under its account', (
    tester,
  ) async {
    final id = await projects.create(
      name: 'Voyage',
      icon: 'airplane',
      accountId: mpesa,
      goal: 30000,
      startedOn: DateTime(2026, 11, 1),
    );
    await projects.putAside(id, amount: 18000, date: DateTime(2026, 11, 2));
    await show(
      tester,
      AccountsScreen(
        accounts: data.accounts,
        currencies: data.currencies,
        data: data,
      ),
    );
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Réservé aux projets'), findsOneWidget);
    expect(shown('320,00 \$'), findsOneWidget);
    // Held in the total, and under its account.
    expect(shown('180,00 \$'), findsNWidgets(2));
    expect(shown('USD · 320,00 \$ libres'), findsOneWidget);
    await tester.tap(find.text('Voyage'));
    await settle(tester);
    expect(find.byType(ProjectScreen), findsOneWidget);
  });

  testWidgets('Comptes without projects stays as it was', (tester) async {
    await show(
      tester,
      AccountsScreen(
        accounts: data.accounts,
        currencies: data.currencies,
        data: data,
      ),
    );
    expect(find.text('Disponible'), findsNothing);
    expect(find.textContaining('libres'), findsNothing);
  });
}
