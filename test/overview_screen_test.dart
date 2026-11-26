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
import 'package:kibuo/ui/overview/overview_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is RichText && plain(w.text.toPlainText()) == wanted,
);

/// The Aperçu counts what the month totals of Opérations count (PRODUCT,
/// 27 November 2026), and follows each save.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late String mpesa;
  late String bank;
  final now = DateTime.now();
  // Early today, so the operations are never ahead of the clock.
  final today = DateTime(now.year, now.month, now.day);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'a');
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
    await data.transactions.create(
      kind: EntryKind.income,
      accountId: bank,
      categoryId: 'default-salary',
      paid: const Money(120000, 'USD'),
      fees: 0,
      date: today,
    );
    await data.transactions.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-taxi',
      paid: const Money(50000, 'USD'),
      fees: 0,
      date: today,
    );
    // Between my own accounts: only its fees go out.
    await data.transactions.createTransfer(
      fromId: mpesa,
      toId: bank,
      sent: const Money(3000, 'USD'),
      fees: 200,
      date: today,
    );
  });
  tearDown(() => db.close());

  testWidgets('I save an expense: Sorties of the Aperçu rises', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final saved = ValueNotifier(0);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Scaffold(
          body: OverviewScreen(data: data, refresh: saved),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(textPlain('−502,00 \$'), findsOneWidget, reason: 'taxi and fees');
    expect(textPlain('+1 200,00 \$'), findsOneWidget);

    await data.transactions.create(
      kind: EntryKind.expense,
      accountId: bank,
      categoryId: 'default-rent',
      paid: const Money(8800, 'USD'),
      fees: 0,
      date: today,
    );
    saved.value++;
    await tester.pumpAndSettle();
    expect(textPlain('−590,00 \$'), findsOneWidget);
    expect(textPlain('+1 200,00 \$'), findsOneWidget);
  });
}
