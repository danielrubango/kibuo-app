import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';

/// Where the guided first launch stands (PRODUCT): shown once on a new app,
/// started again at the step where it was left, never on an app that
/// already has accounts. Also keeps the language chosen in it when Android
/// cannot.
class FirstLaunchStore {
  FirstLaunchStore(this._db) : _prefs = PreferenceStore(_db);

  final KibuoDatabase _db;
  final PreferenceStore _prefs;

  static const _step = 'first_launch_step';
  static const _done = 'first_launch_done';
  static const _language = 'app_language';

  /// The step to show, 1 to 4.
  Future<int> step() async =>
      int.tryParse(await _prefs.read(_step) ?? '')?.clamp(1, 4) ?? 1;

  /// Whether the first launch is to be shown.
  Future<bool> needed() async {
    if (await _prefs.read(_done) == 'true') return false;
    if (await _prefs.read(_step) != null) return true;
    final repo = AccountRepository(_db);
    final none =
        (await repo.accounts()).isEmpty &&
        (await repo.accounts(archived: true)).isEmpty;
    // An app already in use: never.
    if (!none) await finish();
    return none;
  }

  Future<void> reached(int step) => _prefs.write(_step, '$step');

  Future<void> finish() => _prefs.write(_done, 'true');

  /// « fr » or « en », or null to follow the phone.
  Future<String?> language() async {
    final code = await _prefs.read(_language);
    return code == null || code.isEmpty ? null : code;
  }

  Future<void> setLanguage(String? code) => _prefs.write(_language, code ?? '');
}
