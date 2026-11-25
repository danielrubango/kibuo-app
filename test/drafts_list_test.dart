import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/draft_screen.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';

String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is RichText && plain(w.text.toPlainText()) == wanted,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late RecurringRepository rules;
  late String mpesa;
  final now = DateTime.now();
  // At midnight: never in the future, whatever the hour of the run.
  final today = DateTime(now.year, now.month, now.day);

  setUp(() async {
    OperationsScreen.forget();
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    rules = RecurringRepository(db);
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      recurrences: rules,
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

  /// Internet, 30 $, made today as a draft by its recurrence.
  Future<String> draft({int minor = 3000, String? account}) async {
    final rule = await rules.create(
      kind: EntryKind.expense,
      accountId: account ?? mpesa,
      categoryId: 'default-internet',
      amount: Money(minor, 'USD'),
      note: 'Internet',
      unit: RepeatUnit.month,
      start: today,
      asDraft: true,
    );
    await rules.catchUp(now);
    return (await data.transactions.all(drafts: true))
        .firstWhere((t) => t.recurringId == rule)
        .id;
  }

  /// Database writes need real time; then the frames.
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
        key: UniqueKey(),
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: home,
      ),
    );
    await settle(tester);
  }

  Future<void> list(WidgetTester tester) =>
      show(tester, Scaffold(body: OperationsScreen(data: data)));

  /// The toast goes after a moment.
  Future<void> toastGone(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<String> status(String id) async =>
      (await data.transactions.get(id))!.status;

  testWidgets('a draft: its card, out of the month’s totals', (tester) async {
    await draft();
    await list(tester);
    expect(find.byType(DraftCard), findsOneWidget);
    expect(find.text('Brouillon'), findsOneWidget);
    expect(find.text('Ignorer'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
    expect(find.text('Récurrence · M-Pesa'), findsOneWidget);
    expect(find.text('0 % dépensés'), findsOneWidget);
  });

  testWidgets('« Valider »: counted at once, with a toast', (tester) async {
    final id = await draft();
    await list(tester);
    await tester.tap(find.text('Valider'));
    await settle(tester);
    expect(await status(id), 'done');
    expect(find.text('Validé : Internet, compté dans le mois'), findsOneWidget);
    expect(find.byType(DraftCard), findsNothing);
    expect(textPlain('−30,00 \$'), findsWidgets);
    await toastGone(tester);
    expect(find.text('Validé : Internet, compté dans le mois'), findsNothing);
  });

  testWidgets('below the floor: « Valider » opens the card and says why', (
    tester,
  ) async {
    final poor = await data.accounts.create(
      name: 'Cash',
      type: AccountType.cash,
      opening: const Money(1000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
    final id = await draft(account: poor);
    await list(tester);
    await tester.tap(find.text('Valider'));
    await settle(tester);
    expect(find.byType(DraftScreen), findsOneWidget);
    expect(await status(id), 'draft');
    expect(textPlain('10,00 \$ disponibles sur Cash'), findsOneWidget);
    expect(find.text('Autoriser'), findsOneWidget);
    final validate = tester.widget<KibuoButton>(
      find.widgetWithText(KibuoButton, 'Valider l’opération'),
    );
    expect(validate.onPressed, isNull);
  });
}
