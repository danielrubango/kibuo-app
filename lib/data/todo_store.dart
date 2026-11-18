import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/domain/todo/todo.dart';

/// Keeps the « À traiter » lines put off with « Plus tard » (PRODUCT).
class TodoStore {
  TodoStore(KibuoDatabase db) : _prefs = PreferenceStore(db);

  final PreferenceStore _prefs;

  static const _key = 'todo_put_off';

  Future<PutOff> putOff() async => PutOff.parse(await _prefs.read(_key));

  Future<void> putOffToday(String key, DateTime now) async =>
      _prefs.write(_key, (await putOff()).add(key, now).encode());

  /// « Annuler »: the line is back at once.
  Future<void> bringBack(String key) async =>
      _prefs.write(_key, (await putOff()).remove(key).encode());
}
