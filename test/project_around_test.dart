import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/l10n/app_localizations_fr.dart';
import 'package:kibuo/ui/reminders/reminder_planner.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

import 'reminders_test.dart' show FakeNotifier;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late ProjectRepository projects;
  late String mpesa;
  // A Tuesday, at noon.
  final now = DateTime(2026, 11, 24, 12);

  setUp(() async {
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    projects = ProjectRepository(db);
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      reminders: ReminderStore(db),
      projects: projects,
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: DateTime.utc(2025),
    );
  });
  tearDown(() => db.close());

  Future<List<String>> planned() async {
    final notifier = FakeNotifier()..allow = true;
    await ReminderPlanner(
      store: ReminderStore(db),
      notifier: notifier,
      transactions: data.transactions,
      data: data,
    ).refresh(AppLocalizationsFr(), now);
    return [
      for (final n in notifier.scheduled)
        if (n.payload.startsWith('project:')) '${n.at} ${n.title}: ${n.body}',
    ];
  }

  test('each Monday at 9, what the week asks', () async {
    final id = await projects.create(
      name: 'Voyage',
      icon: 'airplane',
      accountId: mpesa,
      goal: 30000,
      startedOn: DateTime(2026, 11, 1),
      due: DateTime(2027, 1, 1),
    );
    await projects.putAside(id, amount: 15000, date: DateTime(2026, 11, 2));
    final shown = await planned();
    expect(shown, hasLength(4));
    // 150 $ left over 5 weeks from 30 November: 30 $.
    expect(
      shown.first.replaceAll(RegExp('[\\u00A0\\u202F]'), ' '),
      '2026-11-30 09:00:00.000 Voyage: 30,00 \$ à mettre de côté cette semaine',
    );
  });

  test(
    'without a date: a gentle word; switched off or reached: none',
    () async {
      await projects.create(
        name: 'Moto',
        icon: 'motorcycle',
        accountId: mpesa,
        goal: 80000,
        startedOn: DateTime(2026, 11, 1),
        period: PlanPeriod.month,
      );
      await projects.create(
        name: 'Télé',
        icon: 'star',
        accountId: mpesa,
        goal: 20000,
        startedOn: DateTime(2026, 11, 1),
        remind: false,
      );
      final done = await projects.create(
        name: 'Loyer',
        icon: 'house',
        accountId: mpesa,
        goal: 1000,
        startedOn: DateTime(2026, 11, 1),
      );
      await projects.putAside(done, amount: 1000, date: DateTime(2026, 11, 2));
      final shown = await planned();
      expect(shown, [
        '2026-12-01 09:00:00.000 Moto: Un peu de côté ce mois-ci ?',
      ]);
    },
  );
}
