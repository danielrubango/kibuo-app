import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/reminders/due_reminder.dart';
import 'package:kibuo/domain/reminders/entry_reminder.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/money/money_format.dart';
import 'package:kibuo/ui/reminders/due_forecast.dart';
import 'package:kibuo/ui/reminders/notifier.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';

/// Schedules the next 30 days' reminders, at every opening and change
/// (PRODUCT: Rappels; no work in the background for the V1).
class ReminderPlanner {
  ReminderPlanner({
    required this.store,
    required this.notifier,
    required this.transactions,
    this.data,
  });

  final ReminderStore store;
  final Notifier notifier;
  final TransactionRepository transactions;

  /// For the due dates' reminders; none, no such reminder.
  final EntryData? data;

  /// Where an entry reminder leads: a new expense.
  static const entryPayload = 'entry';

  /// A due date's reminder leads to its recurrence's card; on the day
  /// itself, to Accueil.
  static const homePayload = 'home';
  static String rulePayload(String id) => 'rule:$id';

  Future<void> refresh(AppLocalizations l, DateTime now) async {
    final notices = <Notice>[];
    if (await store.entryOn() && await notifier.allowed()) {
      final today = DateTime(now.year, now.month, now.day);
      // Noted by hand today; a recurrence's own operations don't count.
      final noted = (await transactions.all(drafts: true)).any((t) {
        if (t.recurringId != null) return false;
        final at = notedAt(t.id)?.toLocal();
        return at != null && !at.isBefore(today);
      });
      final times = entryReminderTimes(
        now: now,
        minuteOfDay: await store.entryMinute(),
        notedToday: noted,
      );
      for (final (i, at) in times.indexed) {
        notices.add(
          Notice(
            id: 1000 + i,
            at: at,
            title: l.reminderEntryTitle,
            body: l.reminderEntryBody,
            payload: entryPayload,
          ),
        );
      }
    }
    if (data case final data? when await notifier.allowed()) {
      notices.addAll(await _dues(data, l, now));
    }
    await notifier.replace(notices);
  }

  /// One notification per due date, at its delay (PRODUCT: Rappels).
  Future<List<Notice>> _dues(
    EntryData data,
    AppLocalizations l,
    DateTime now,
  ) async {
    final dueOn = await store.dueOn();
    final dueDays = await store.dueDays();
    final items = await dueForecast(data, now);
    final name = await dueNames(data, l);
    final lang = l.localeName;
    String money(Money m) => formatMoney(m, currencyOf(m.currency), lang);
    final notices = <Notice>[];
    for (final item in items) {
      final own = await store.ruleDays(item.planned.rule.id);
      final days = own ?? (dueOn ? dueDays : -1);
      if (days < 0) continue;
      final at = reminderAt(item.planned.day, days);
      if (!at.isAfter(now)) continue;
      final missing = item.missing;
      final account = item.account.name;
      final body = switch ((days, missing)) {
        (0, null) => l.reminderDueToday(money(item.amount), account),
        (0, final m?) => l.reminderDueTodayShort(money(m), account),
        (_, null) => l.reminderDueSoon(money(item.amount), days, account),
        (_, final m?) => l.reminderDueShort(days, money(m), account),
      };
      notices.add(
        Notice(
          id: 2000 + notices.length,
          at: at,
          title: name(item),
          body: body,
          payload: days == 0 ? homePayload : rulePayload(item.planned.rule.id),
        ),
      );
    }
    return notices;
  }
}
