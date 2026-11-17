import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/domain/money/long_amounts.dart';

/// Keeps the « Montants longs » choice.
class LongAmountsStore {
  LongAmountsStore(KibuoDatabase db) : _prefs = PreferenceStore(db);

  final PreferenceStore _prefs;

  static const _key = 'long_amounts';

  Future<LongAmounts> read() async {
    final name = await _prefs.read(_key);
    return LongAmounts.values.asNameMap()[name] ?? LongAmounts.auto;
  }

  Future<void> write(LongAmounts choice) => _prefs.write(_key, choice.name);
}
