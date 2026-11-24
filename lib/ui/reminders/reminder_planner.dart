import 'package:intl/intl.dart';
import 'package:kibuo/data/debt_repository.dart';
import 'package:kibuo/data/project_repository.dart';
import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/projects/project_reminder.dart';
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

  /// A project's reminder opens its card.
  static String projectPayload(String id) => 'project:$id';

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
      notices.addAll(await _debts(data, l, now));
      notices.addAll(await _projects(data, l, now));
    }
    await notifier.replace(notices);
  }

  /// Each debt's own reminder, at its delay; « Par défaut » follows the
  /// due dates' setting; none without a due date (PRODUCT: Dettes).
  Future<List<Notice>> _debts(
    EntryData data,
    AppLocalizations l,
    DateTime now,
  ) async {
    final debts = data.debts;
    if (debts == null) return const [];
    final dueOn = await store.dueOn();
    final dueDays = await store.dueDays();
    final lang = l.localeName;
    final notices = <Notice>[];
    for (final d in await debts.debts()) {
      final due = d.due;
      if (d.settled || due == null) continue;
      final own = await store.ruleDays(d.id);
      final days = own ?? (dueOn ? dueDays : -1);
      if (days < 0) continue;
      final at = reminderAt(DateTime(due.year, due.month, due.day), days);
      if (!at.isAfter(now) || at.isAfter(now.add(const Duration(days: 30)))) {
        continue;
      }
      final amount = formatMoney(d.left, currencyOf(d.left.currency), lang);
      final day = DateFormat.EEEE(lang).format(due);
      notices.add(
        Notice(
          id: 3000 + notices.length,
          at: at,
          title: d.direction == DebtDirection.owe
              ? l.reminderDebtOwe(d.person, amount, day)
              : l.reminderDebtOwed(d.person, amount, day),
          body: days == 0 ? l.reminderDebtToday : l.reminderDebtSoon(days),
          payload: homePayload,
        ),
      );
    }
    return notices;
  }

  /// Each project's reminder at its plan's rhythm, at 9 (PRODUCT:
  /// Projets): what the period asks; nothing once its part is set aside,
  /// for a project reached or ended, or switched off.
  Future<List<Notice>> _projects(
    EntryData data,
    AppLocalizations l,
    DateTime now,
  ) async {
    final projects = data.projects;
    if (projects == null) return const [];
    final lang = l.localeName;
    final notices = <Notice>[];
    for (final p in await projects.projects()) {
      if (!p.running || p.reached || !p.remind) continue;
      final due = p.due;
      final lines = await projects.contributions(p.id);
      for (final at in projectReminderTimes(p.period, now)) {
        if (due != null && !at.isBefore(due)) break;
        final String body;
        if (due == null) {
          body = switch (p.period) {
            PlanPeriod.week => l.reminderProjectFreeWeek,
            PlanPeriod.fortnight => l.reminderProjectFreeFortnight,
            PlanPeriod.month => l.reminderProjectFreeMonth,
          };
        } else {
          final per = perPeriod(
            goal: p.goal.minor,
            saved: p.saved.minor,
            today: at,
            due: due,
            period: p.period,
            unit: unitOf(p.goal.currency),
          );
          // Its part already set aside in that period: nothing to say.
          final end = reminderPeriodEnd(p.period, at);
          final inPeriod = lines
              .where(
                (c) =>
                    !c.date.isBefore(DateTime(at.year, at.month, at.day)) &&
                    c.date.isBefore(end),
              )
              .fold<int>(0, (s, c) => s + c.amount.minor);
          if (per <= 0 || inPeriod >= per) continue;
          final amount = formatMoney(
            Money(per, p.goal.currency),
            currencyOf(p.goal.currency),
            lang,
          );
          body = switch (p.period) {
            PlanPeriod.week => l.reminderProjectWeek(amount),
            PlanPeriod.fortnight => l.reminderProjectFortnight(amount),
            PlanPeriod.month => l.reminderProjectMonth(amount),
          };
        }
        notices.add(
          Notice(
            id: 4000 + notices.length,
            at: at,
            title: p.name,
            body: body,
            payload: projectPayload(p.id),
          ),
        );
      }
    }
    return notices;
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
