import 'dart:convert';

import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/domain/transactions/search.dart';

/// « Recherches récentes » (PRODUCT): the last five searches whose result
/// was opened, kept on this phone.
class SearchHistory {
  SearchHistory(KibuoDatabase db) : _prefs = PreferenceStore(db);

  final PreferenceStore _prefs;

  static const _name = 'search_recent';

  Future<List<String>> recent() async {
    final raw = await _prefs.read(_name);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return [for (final q in jsonDecode(raw) as List) q as String];
    } on FormatException {
      return const [];
    }
  }

  /// A result of [query] was opened.
  Future<List<String>> remember(String query) async {
    final next = rememberSearch(await recent(), query);
    await _prefs.write(_name, jsonEncode(next));
    return next;
  }

  /// « Effacer ».
  Future<void> clear() => _prefs.write(_name, '[]');
}
