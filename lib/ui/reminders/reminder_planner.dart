import 'package:kibuo/data/reminder_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/reminders/entry_reminder.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/reminders/notifier.dart';

/// Schedules the next 30 days' reminders, at every opening and change
/// (PRODUCT: Rappels; no work in the background for the V1).
class ReminderPlanner {
  ReminderPlanner({
    required this.store,
    required this.notifier,
    required this.transactions,
  });

  final ReminderStore store;
  final Notifier notifier;
  final TransactionRepository transactions;

  /// Where an entry reminder leads: a new expense.
  static const entryPayload = 'entry';

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
    await notifier.replace(notices);
  }
}
