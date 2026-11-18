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
}
