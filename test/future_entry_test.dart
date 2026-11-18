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
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late RecurringRepository rules;
  String? saved;
  final now = DateTime(2026, 11, 15, 15, 45);

  setUp(() async {
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
    // A small balance: a planned expense is never refused for it.
    await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(1000, 'USD'),
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

  testWidgets('dated later: planned, not saved, never refused', (tester) async {
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
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  saved = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => EntryScreen(
                        data: data,
                        kind: EntryKind.expense,
                        now: () => now,
                      ),
                    ),
                  );
                },
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await settle(tester);
    // 50,00 $: more than the account holds.
    for (final k in ['5', '0']) {
      await tester.tap(find.text(k).last);
      await tester.pump();
    }
    await tester.tap(find.text('Terminé'));
    await settle(tester);
    await tester.tap(find.text('Catégorie'));
    await settle(tester);
    await tester.tap(find.text('Taxi'));
    await settle(tester);
    await tester.tap(find.text('Date'));
    await settle(tester);
    await tester.tap(find.text('20'));
    await tester.tap(find.text('OK'));
    await settle(tester);
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.text('Pièces jointes'), findsNothing);
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(saved, startsWith('planned:'));
    expect(await data.transactions.all(drafts: true), isEmpty);
    final rule = (await rules.rules()).single;
    expect(rule.amount.minor, 5000);
    expect(rule.schedule.start, DateTime(2026, 11, 20));
    expect(rule.schedule.count, 1);
    // On its day it arrives, once.
    await rules.catchUp(DateTime(2026, 11, 21));
    expect(await data.transactions.all(drafts: true), hasLength(1));
    await tester.pump(const Duration(seconds: 3));
  });
}
