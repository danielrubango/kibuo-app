import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/home/home_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is RichText && plain(w.text.toPlainText()) == wanted,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late String mpesa;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 9);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
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

  var accountsOpened = 0;
  var monthOpened = 0;

  Future<void> start(WidgetTester tester) async {
    accountsOpened = 0;
    monthOpened = 0;
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
          body: HomeScreen(
            data: data,
            onOpenAccounts: () => accountsOpened++,
            onOpenMonth: () => monthOpened++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a new app: the accounts’ total, and a month at zero', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Aujourd’hui'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(textPlain('1 000,00 \$'), findsOneWidget);
    expect(find.text('à dépenser librement'), findsOneWidget);
    expect(find.text('dont projets'), findsNothing, reason: 'no projects yet');
    expect(find.text('Créer un projet'), findsNothing);
    expect(textPlain('0,00 \$ restants'), findsOneWidget);
    expect(textPlain('0 % dépensés'), findsOneWidget);
    // Nothing yet for the later modules.
    expect(find.text('Je dois'), findsNothing);
    expect(find.text('À traiter'), findsNothing);
    expect(find.text('À venir'), findsNothing);
  });

  testWidgets('the month: what is left, the share spent, out of in', (
    tester,
  ) async {
    final bank = await data.accounts.create(
      name: 'Rawbank',
      type: AccountType.bank,
      opening: const Money(100000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
    Future<void> add(EntryKind kind, String account, String cat, int minor) =>
        data.transactions.create(
          kind: kind,
          accountId: account,
          categoryId: cat,
          paid: Money(minor, 'USD'),
          fees: 0,
          date: today,
        );
    await add(EntryKind.income, bank, 'default-salary', 120000);
    await add(EntryKind.expense, mpesa, 'default-taxi', 50000);
    await add(EntryKind.expense, bank, 'default-rent', 8800);
    await start(tester);
    // 2 000 + 1 200 − 500 − 88
    expect(textPlain('2 612,00 \$'), findsOneWidget);
    expect(textPlain('+612,00 \$ restants'), findsOneWidget);
    expect(textPlain('49 % dépensés'), findsOneWidget);
    expect(textPlain('−588,00 sur +1 200,00'), findsOneWidget);
  });

  testWidgets('an account without a rate stays out, and says so', (
    tester,
  ) async {
    await data.currencies.addCurrency('EUR');
    await data.accounts.create(
      name: 'Euros',
      type: AccountType.cash,
      opening: const Money(5000, 'EUR'),
      openingDate: DateTime.utc(now.year - 1),
    );
    await start(tester);
    expect(textPlain('1 000,00 \$'), findsOneWidget);
    expect(
      find.text('Sans taux, EUR ne compte pas dans le total.'),
      findsOneWidget,
    );
    expect(find.text('Ajouter un taux'), findsOneWidget);
  });

  testWidgets('touching the available opens Comptes, the month the list', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Disponible'));
    await tester.pumpAndSettle();
    expect(accountsOpened, 1);
    await tester.tap(find.textContaining('ce mois-ci', findRichText: true));
    await tester.pumpAndSettle();
    expect(monthOpened, 1);
  });
}
