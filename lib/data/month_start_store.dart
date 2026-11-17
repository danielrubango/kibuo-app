import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';

/// Keeps « Début du mois »: the day, 1 to 28, a month starts on.
class MonthStartStore {
  MonthStartStore(KibuoDatabase db) : _prefs = PreferenceStore(db);

  final PreferenceStore _prefs;

  static const _key = 'month_start';

  Future<int> read() async =>
      (int.tryParse(await _prefs.read(_key) ?? '') ?? 1).clamp(1, 28);

  Future<void> write(int day) => _prefs.write(_key, '${day.clamp(1, 28)}');
}
