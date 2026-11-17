import 'package:drift/drift.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:uuid/uuid.dart';

/// A recurrence as the screens use it (GLOSSARY: Récurrence).
class RecurringInfo {
  const RecurringInfo({
    required this.id,
    required this.kind,
    required this.accountId,
    required this.amount,
    required this.fees,
    required this.schedule,
    required this.stopped,
    this.toAccountId,
    this.categoryId,
    this.note,
    this.asDraft,
    this.doneUntil,
  });

  final String id;
  final EntryKind kind;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;

  /// Paid each time, in its own currency; fees in the account's.
  final Money amount;
  final int fees;
  final String? note;
  final Schedule schedule;

  /// True: always a draft; false: always saved; null: the global setting.
  final bool? asDraft;
  final DateTime? doneUntil;
  final bool stopped;

  /// The next [count] dates still to come on [now]: after today's if it
  /// was made already, from today otherwise.
  List<DateTime> upcoming(DateTime now, {int count = 3}) {
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final done = doneUntil;
    return next(
      after: done != null && done.isAfter(yesterday) ? done : yesterday,
      count: count,
    );
  }

  /// The next [count] dates after [after].
  List<DateTime> next({required DateTime after, int count = 3}) {
    final day = DateTime(after.year, after.month, after.day);
    return schedule.dates().where((d) => d.isAfter(day)).take(count).toList();
  }
}

/// The user's recurrences, and catching up on their dates (PRODUCT:
/// Récurrences). Every write carries the sync metadata of ADR 0003.
class RecurringRepository {
  RecurringRepository(this._db)
    : _transactions = TransactionRepository(_db),
      _prefs = PreferenceStore(_db);

  final KibuoDatabase _db;
  final TransactionRepository _transactions;
  final PreferenceStore _prefs;
  HybridClock? _clock;

  static const _askKey = 'recurrence_always_ask';

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  /// « Toujours demander »: every recurrence that follows the global
  /// setting arrives as a draft.
  Future<bool> alwaysAsk() async => await _prefs.read(_askKey) == 'true';

  Future<void> setAlwaysAsk(bool on) => _prefs.write(_askKey, '$on');

  static int _weekdayBits(Set<int> days) =>
      days.fold(0, (bits, d) => bits | (1 << (d - 1)));

  static Set<int> _weekdays(int bits) => {
    for (var d = 1; d <= 7; d++)
      if (bits & (1 << (d - 1)) != 0) d,
  };

  static int _day(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  Future<String> create({
    required EntryKind kind,
    required String accountId,
    required Money amount,
    required RepeatUnit unit,
    required DateTime start,
    String? toAccountId,
    String? categoryId,
    int fees = 0,
    String? note,
    int every = 1,
    Set<int> weekdays = const {},
    int? endCount,
    DateTime? endDate,
    bool? asDraft,
    String? firstMade,
  }) async {
    final id = const Uuid().v7();
    final first = DateTime(start.year, start.month, start.day);
    await _db
        .into(_db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: id,
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            kind: kind.stored,
            accountId: accountId,
            toAccountId: Value(toAccountId),
            categoryId: Value(categoryId),
            amount: amount.minor,
            currency: amount.currency,
            fees: Value(fees),
            note: Value(note),
            unit: unit.name,
            every: Value(every),
            weekdays: Value(_weekdayBits(weekdays)),
            start: DateTime(start.year, start.month, start.day),
            endCount: Value(endCount),
            endDate: Value(endDate),
            asDraft: Value(asDraft),
            // Made from an entry: that operation is its first time.
            doneUntil: Value(firstMade == null ? null : first),
          ),
        );
    if (firstMade != null) {
      await (_db.update(
        _db.transactions,
      )..where((t) => t.id.equals(firstMade))).write(
        TransactionsCompanion(
          recurringId: Value(id),
          occurrence: Value(_day(first)),
          version: Value(await _nextVersion()),
          deviceId: Value(_db.deviceId),
        ),
      );
    }
    return id;
  }

  /// Changes [id] for the times to come (PRODUCT): what it already made
  /// stays as it is.
  Future<void> update(
    String id, {
    required EntryKind kind,
    required String accountId,
    required Money amount,
    required RepeatUnit unit,
    required DateTime start,
    String? toAccountId,
    String? categoryId,
    int fees = 0,
    String? note,
    int every = 1,
    Set<int> weekdays = const {},
    int? endCount,
    DateTime? endDate,
    bool? asDraft,
  }) async {
    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        kind: Value(kind.stored),
        accountId: Value(accountId),
        toAccountId: Value(toAccountId),
        categoryId: Value(categoryId),
        amount: Value(amount.minor),
        currency: Value(amount.currency),
        fees: Value(fees),
        note: Value(note),
        unit: Value(unit.name),
        every: Value(every),
        weekdays: Value(_weekdayBits(weekdays)),
        start: Value(DateTime(start.year, start.month, start.day)),
        endCount: Value(endCount),
        endDate: Value(endDate),
        asDraft: Value(asDraft),
        version: Value(await _nextVersion()),
        deviceId: Value(_db.deviceId),
      ),
    );
  }

  Future<List<RecurringInfo>> rules() async {
    final rows = await (_db.select(
      _db.recurringRules,
    )..where((r) => r.deleted.not())).get();
    return [
      for (final r in rows)
        RecurringInfo(
          id: r.id,
          kind: EntryKind.fromStored(r.kind),
          accountId: r.accountId,
          toAccountId: r.toAccountId,
          categoryId: r.categoryId,
          amount: Money(r.amount, r.currency),
          fees: r.fees,
          note: r.note,
          schedule: Schedule(
            start: r.start,
            unit: RepeatUnit.values.byName(r.unit),
            every: r.every,
            weekdays: _weekdays(r.weekdays),
            count: r.endCount,
            until: r.endDate,
          ),
          asDraft: r.asDraft,
          doneUntil: r.doneUntil,
          stopped: r.stopped,
        ),
    ];
  }

  /// Stops [id]: what it made stays; its drafts waiting go (PRODUCT).
  Future<void> stop(String id) => _db.transaction(() async {
    final version = await _nextVersion();
    await (_db.update(_db.recurringRules)..where((r) => r.id.equals(id))).write(
      RecurringRulesCompanion(
        stopped: const Value(true),
        version: Value(version),
        deviceId: Value(_db.deviceId),
      ),
    );
    await (_db.update(
      _db.transactions,
    )..where((t) => t.recurringId.equals(id) & t.status.equals('draft'))).write(
      TransactionsCompanion(
        deleted: const Value(true),
        version: Value(version),
        deviceId: Value(_db.deviceId),
      ),
    );
  });

  /// Makes every date due by [now] that was not made yet, at its own date,
  /// as an operation or a draft (PRODUCT). Returns how many were made.
  Future<int> catchUp(DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final alwaysAsk = await this.alwaysAsk();
    final currencies = CurrencyRepository(_db);
    var made = 0;
    for (final rule in await rules()) {
      if (rule.stopped) continue;
      final from = rule.doneUntil == null
          ? rule.schedule.start
          : DateTime(
              rule.doneUntil!.year,
              rule.doneUntil!.month,
              rule.doneUntil!.day + 1,
            );
      for (final day in rule.schedule.due(from: from, until: today)) {
        final key = _day(day);
        final already =
            await (_db.select(_db.transactions)..where(
                  (t) =>
                      t.recurringId.equals(rule.id) & t.occurrence.equals(key),
                ))
                .getSingleOrNull();
        if (already == null) {
          await _make(rule, day, key, alwaysAsk, currencies);
          made++;
        }
      }
      await (_db.update(_db.recurringRules)..where((r) => r.id.equals(rule.id)))
          .write(RecurringRulesCompanion(doneUntil: Value(today)));
    }
    return made;
  }

  Future<void> _make(
    RecurringInfo rule,
    DateTime day,
    int key,
    bool alwaysAsk,
    CurrencyRepository currencies,
  ) async {
    final account = (await AccountRepository(
      _db,
    ).accounts()).where((a) => a.id == rule.accountId).firstOrNull;
    if (account == null) return;
    var draft = rule.asDraft ?? alwaysAsk;
    // Paid in another currency: today's rate, or a draft to give one.
    ExchangeRate? rate;
    if (rule.amount.currency != account.currency) {
      rate = (await currencies.latestRate(
        account.currency,
        rule.amount.currency,
      ))?.rate;
      if (rate == null) draft = true;
    }
    // Below the floor: a draft, whose validation says so (PRODUCT).
    if (!draft && rule.kind != EntryKind.income) {
      final out = rate == null
          ? rule.amount.minor
          : rate.convert(rule.amount, to: currencyOf(account.currency)).minor;
      if (!account.overdraft.allows(account.balance.minor - out - rule.fees)) {
        draft = true;
      }
    }
    final occurrence = Occurrence(
      ruleId: rule.id,
      day: key,
      status: draft ? 'draft' : 'done',
    );
    // At noon, so the day holds whatever the phone's time zone.
    final date = DateTime(day.year, day.month, day.day, 12);
    if (rule.kind == EntryKind.transfer) {
      await _transactions.createTransfer(
        fromId: rule.accountId,
        toId: rule.toAccountId!,
        sent: rule.amount,
        fees: rule.fees,
        date: date,
        rate: rate,
        note: rule.note,
        occurrence: occurrence,
      );
    } else {
      await _transactions.create(
        kind: rule.kind,
        accountId: rule.accountId,
        categoryId: rule.categoryId!,
        paid: rule.amount,
        fees: rule.fees,
        date: date,
        // Without a rate, the draft waits for one: kept in its currency.
        rate: rate,
        note: rule.note,
        occurrence: occurrence,
      );
    }
  }
}
