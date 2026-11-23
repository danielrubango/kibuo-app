import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';

/// The one-time hints Kibuo gives (PRODUCT: after a few openings of the +
/// sheet, a bubble shows the hold, once).
class HintStore {
  HintStore(KibuoDatabase db) : _prefs = PreferenceStore(db);

  final PreferenceStore _prefs;

  static const _opens = 'hint_plus_sheet_opens';
  static const _done = 'hint_plus_hold_done';

  /// The sheet opens before the tip shows.
  static const opensBeforeTip = 3;

  Future<String?> _read(String name) => _prefs.read(name);

  Future<void> _write(String name, String value) => _prefs.write(name, value);

  /// Counts an opening of the + sheet by a tap; true when the hold tip
  /// should show now.
  Future<bool> sheetOpened() async {
    if (await _read(_done) == 'true') return false;
    final opens = int.tryParse(await _read(_opens) ?? '') ?? 0;
    await _write(_opens, '${opens + 1}');
    return opens + 1 >= opensBeforeTip;
  }

  /// The tip was read (« Compris »), or the hold was found alone: never
  /// again.
  Future<void> tipDone() => _write(_done, 'true');

  static const _swipe = 'hint_list_swipe_done';

  /// Whether the month swipe was already shown (DIRECTION: a hidden
  /// gesture is shown on the first visit).
  Future<bool> swipeShown() async => await _read(_swipe) == 'true';

  Future<void> swipeDone() => _write(_swipe, 'true');

  static const _debts = 'hint_debts_coach_done';

  /// Whether the debts list's two-step guide was shown (owner, 23
  /// November): once, the first time the list has a line.
  Future<bool> debtsCoachShown() async => await _read(_debts) == 'true';

  Future<void> debtsCoachDone() => _write(_debts, 'true');
}
