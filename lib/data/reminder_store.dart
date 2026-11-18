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
}
