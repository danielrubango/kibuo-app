import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';

/// The reminders' settings (PRODUCT: Rappels): the entry reminder, off by
/// default, at 20:00 to begin with.
class ReminderStore {
  ReminderStore(KibuoDatabase db) : _prefs = PreferenceStore(db);

  final PreferenceStore _prefs;

  static const _entryOn = 'reminder_entry_on';
  static const _entryMinute = 'reminder_entry_minute';
  static const defaultEntryMinute = 20 * 60;

  Future<bool> entryOn() async => await _prefs.read(_entryOn) == 'true';

  Future<void> setEntryOn(bool on) => _prefs.write(_entryOn, '$on');

  /// The time of day, in minutes after midnight.
  Future<int> entryMinute() async =>
      int.tryParse(await _prefs.read(_entryMinute) ?? '') ?? defaultEntryMinute;

  Future<void> setEntryMinute(int minute) =>
      _prefs.write(_entryMinute, '$minute');

  static const _dueOn = 'reminder_due_on';
  static const _dueDays = 'reminder_due_days';
  static const defaultDueDays = 3;

  /// The days a reminder may come before a date (PRODUCT).
  static const dueChoices = [0, 1, 2, 3, 7];

  /// « Rappeler avant une échéance »: on by default.
  Future<bool> dueOn() async => await _prefs.read(_dueOn) != 'false';

  Future<void> setDueOn(bool on) => _prefs.write(_dueOn, '$on');

  Future<int> dueDays() async =>
      int.tryParse(await _prefs.read(_dueDays) ?? '') ?? defaultDueDays;

  Future<void> setDueDays(int days) => _prefs.write(_dueDays, '$days');

  /// A recurrence's own reminder: null follows the default, -1 is none,
  /// otherwise the days before.
  Future<int?> ruleDays(String ruleId) async =>
      int.tryParse(await _prefs.read('reminder_rule_$ruleId') ?? '');

  Future<void> setRuleDays(String ruleId, int? days) =>
      _prefs.write('reminder_rule_$ruleId', days == null ? '' : '$days');

  static const _at80 = 'budget_alert_80';
  static const _at100 = 'budget_alert_100';
  static const _alerted = 'budget_alerted';

  /// « À 80 % du budget », « À 100 % du budget »: on by default.
  Future<bool> budgetAt80() async => await _prefs.read(_at80) != 'false';
  Future<bool> budgetAt100() async => await _prefs.read(_at100) != 'false';
  Future<void> setBudgetAt80(bool on) => _prefs.write(_at80, '$on');
  Future<void> setBudgetAt100(bool on) => _prefs.write(_at100, '$on');

  /// The thresholds already said (« budget:id:202611:80 »).
  Future<Set<String>> budgetAlerted() async =>
      (await _prefs.read(_alerted) ?? '')
          .split(',')
          .where((k) => k.isNotEmpty)
          .toSet();

  /// Keeps [keys] said, and forgets the months before [month].
  Future<void> addBudgetAlerted(Iterable<String> keys, int month) async {
    final kept = {
      for (final k in await budgetAlerted())
        if ((int.tryParse(k.split(':').elementAtOrNull(2) ?? '') ?? 0) >= month)
          k,
      ...keys,
    };
    await _prefs.write(_alerted, kept.join(','));
  }
}
