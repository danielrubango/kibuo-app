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
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/recurrences/recurrences_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late RecurringRepository rules;
  late String mpesa;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

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
      reminders: ReminderStore(db),
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(10000, 'USD'),
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

  Future<String> plan({int? count}) => rules.create(
    kind: EntryKind.expense,
    accountId: mpesa,
    categoryId: 'default-taxi',
    amount: const Money(500, 'USD'),
    unit: RepeatUnit.day,
    start: today.add(const Duration(days: 2)),
    endCount: count,
  );

  Future<void> open(WidgetTester tester, String id) async {
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
          builder: (context) => TextButton(
            onPressed: () => openRuleCard(context, data, id),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await settle(tester);
  }

  testWidgets('one time: the planned operation’s card, then cancelled', (
    tester,
  ) async {
    final id = await plan(count: 1);
    await open(tester, id);
    expect(find.text('Dépense prévue'), findsOneWidget);
    expect(find.textContaining('Prévue le '), findsOneWidget);
    expect(find.text('Rappel'), findsOneWidget);
    expect(find.text('Arrêter la récurrence'), findsNothing);
    await tester.tap(find.text('Annuler l’opération prévue'));
    await settle(tester);
    await tester.tap(find.text('Annuler l’opération'));
    await settle(tester);
    expect((await rules.rules()).single.stopped, isTrue);
    expect(find.text('Dépense prévue'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
  });
}
