import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/hint_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/choice_menu.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';

String plain(String s) => s.replaceAll(RegExp('[\u00a0\u202f]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is RichText && plain(w.text.toPlainText()) == wanted,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late String mpesa;
  late String bank;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 9);

  setUp(() async {
    OperationsScreen.forget();
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
    );
    await data.currencies.ensurePrimaryCurrency('US');
    final start = DateTime.utc(now.year - 1);
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: start,
    );
    bank = await data.accounts.create(
      name: 'Rawbank',
      type: AccountType.bank,
      opening: const Money(100000, 'USD'),
      openingDate: start,
    );
    Future<void> add(
      EntryKind kind,
      String account,
      String cat,
      int minor,
      DateTime date,
    ) => data.transactions.create(
      kind: kind,
      accountId: account,
      categoryId: cat,
      paid: Money(minor, 'USD'),
      fees: 0,
      date: date,
    );
    await add(EntryKind.income, bank, 'default-salary', 120000, today);
    await add(EntryKind.expense, mpesa, 'default-taxi', 50000, today);
    await add(EntryKind.expense, bank, 'default-rent', 8800, today);
    await data.transactions.createTransfer(
      fromId: mpesa,
      toId: bank,
      sent: const Money(3000, 'USD'),
      fees: 0,
      date: today,
    );
  });
  tearDown(() => db.close());

  Future<void> start(WidgetTester tester, {HintStore? hints}) async {
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
          body: OperationsScreen(data: data, hints: hints),
        ),
      ),
    );
    if (hints == null) {
      await tester.pumpAndSettle();
    } else {
      // The tip loops: settle by time, not by stillness.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  testWidgets('the month: entries, exits, share spent, what is left', (
    tester,
  ) async {
    await start(tester);
    expect(textPlain('+1 200,00 \$'), findsWidgets);
    expect(
      textPlain('−588,00 \$'),
      findsWidgets,
      reason: 'the transfer is out',
    );
    expect(find.text('49 % dépensés'), findsOneWidget);
    expect(textPlain('+612,00 \$'), findsWidgets);
  });

  testWidgets('a filter changes the list, not the month’s totals', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceRow, 'M-Pesa'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Loyer'), findsNothing);
    expect(textPlain('+1 200,00 \$'), findsWidgets);
    expect(textPlain('−588,00 \$'), findsWidgets);
    expect(find.text('49 % dépensés'), findsOneWidget);
  });

  testWidgets(
    'a month from the 2nd: its days, and the period under the title',
    (tester) async {
      monthStartChoice.value = 2;
      final period = BudgetPeriod.containing(now, startDay: 2);
      Future<void> taxi(int minor, DateTime day) => data.transactions.create(
        kind: EntryKind.expense,
        accountId: mpesa,
        categoryId: 'default-taxi',
        paid: Money(minor, 'USD'),
        fees: 0,
        date: day,
      );
      await taxi(333, period.first.add(const Duration(hours: 9)));
      await taxi(777, period.first.subtract(const Duration(hours: 9)));
      await start(tester);
      expect(textPlain('−3,33 \$'), findsWidgets, reason: 'its first day');
      expect(textPlain('−7,77 \$'), findsNothing, reason: 'the day before');
      String d(DateTime x) => DateFormat.MMMd('fr').format(x);
      expect(
        find.text('du ${d(period.first)} au ${d(period.last)}'),
        findsOneWidget,
      );
    },
  );
}
