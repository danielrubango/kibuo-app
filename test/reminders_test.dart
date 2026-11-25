import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations_fr.dart';
import 'package:kibuo/ui/reminders/notifier.dart';
import 'package:kibuo/ui/reminders/reminder_planner.dart';

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
