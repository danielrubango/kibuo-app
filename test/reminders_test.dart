import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/l10n/app_localizations_fr.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/reminders/notifier.dart';
import 'package:kibuo/ui/reminders/reminder_planner.dart';
import 'package:kibuo/ui/reminders/reminders_screen.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

class FakeNotifier implements Notifier {
  bool allow = false;
  bool answer = false;
  int asked = 0;
  int settingsOpened = 0;
  List<Notice> scheduled = const [];

  @override
  Future<String?> start(void Function(String payload) onOpen) async => null;

  @override
  Future<bool> allowed() async => allow;

  @override
  Future<bool> ask() async {
    asked++;
    allow = answer;
    return answer;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<void> replace(List<Notice> notices) async => scheduled = notices;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late ReminderStore store;
  late FakeNotifier notifier;
  late ReminderPlanner planner;

  setUp(() {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    store = ReminderStore(db);
    notifier = FakeNotifier();
    planner = ReminderPlanner(
      store: store,
      notifier: notifier,
      transactions: TransactionRepository(db),
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

  Future<void> show(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: RemindersScreen(
          store: store,
          notifier: notifier,
          onChanged: () =>
              planner.refresh(AppLocalizationsFr(), DateTime.now()),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('off by default; refused, it stays off and says so', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('Noter mes opérations'), findsOneWidget);
    expect(find.text('Heure'), findsNothing);
    await tester.tap(find.text('Noter mes opérations'));
    await settle(tester);
    expect(notifier.asked, 1);
    expect(find.text('Notifications bloquées'), findsOneWidget);
    expect(await store.entryOn(), isFalse);
    await tester.tap(find.text('Ouvrir les réglages du téléphone'));
    expect(notifier.settingsOpened, 1);
  });

  testWidgets('allowed: on, every day at 20:00, then another time', (
    tester,
  ) async {
    notifier.answer = true;
    await show(tester);
    await tester.tap(find.text('Noter mes opérations'));
    await settle(tester);
    expect(await store.entryOn(), isTrue);
    expect(find.text('Chaque jour à 20:00'), findsOneWidget);
    expect(notifier.scheduled, hasLength(30));
    expect(notifier.scheduled.first.payload, ReminderPlanner.entryPayload);
    await tester.tap(find.text('Heure'));
    await settle(tester);
    expect(find.text('Heure du rappel'), findsOneWidget);
    await tester.drag(find.text('20:00').last, const Offset(0, -44));
    await settle(tester);
    await tester.tap(find.text('Enregistrer'));
    await settle(tester);
    expect(await store.entryMinute(), 20 * 60 + 15);
    expect(notifier.scheduled.first.at.minute, 15);
  });

  test('noted by hand today: no reminder today', () async {
    notifier.allow = true;
    await store.setEntryOn(true);
    await CurrencyRepository(db).ensurePrimaryCurrency('US');
    final account = await AccountRepository(db).create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(0, 'USD'),
      openingDate: DateTime.utc(2026),
    );
    final now = DateTime(2026, 11, 19, 10);
    await planner.refresh(AppLocalizationsFr(), now);
    expect(notifier.scheduled.first.at, DateTime(2026, 11, 19, 20));
    await TransactionRepository(db).create(
      kind: EntryKind.expense,
      accountId: account,
      categoryId: 'default-food',
      paid: const Money(500, 'USD'),
      fees: 0,
      date: DateTime(2026, 11, 19),
    );
    // Noted now: the real clock, so plan from the real today.
    final today = DateTime.now();
    await planner.refresh(AppLocalizationsFr(), today);
    expect(
      notifier.scheduled.first.at.day,
      DateTime(today.year, today.month, today.day + 1).day,
    );
  });

  test('not allowed: nothing scheduled', () async {
    await store.setEntryOn(true);
    await planner.refresh(AppLocalizationsFr(), DateTime(2026, 11, 19, 10));
    expect(notifier.scheduled, isEmpty);
  });
}
