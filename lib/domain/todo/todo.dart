import 'dart:convert';

/// The three groups of « À traiter », most urgent first (PRODUCT).
enum TodoGroup { urgent, week, reminders }

/// What a line of « À traiter » is about, in the order PRODUCT gives.
enum TodoKind {
  budgetOver(TodoGroup.urgent),
  recovery(TodoGroup.urgent),
  drafts(TodoGroup.week),
  budgetNear(TodoGroup.week),
  oldRate(TodoGroup.reminders);

  const TodoKind(this.group);

  final TodoGroup group;
}

/// One line of « À traiter ». [key] names it for « Plus tard »: the same
/// budget, the drafts, the recovery code, a currency's rate.
class TodoItem {
  const TodoItem({required this.kind, required this.key});

  final TodoKind kind;
  final String key;

  TodoGroup get group => kind.group;
}

/// [items] from the most urgent: by group, then by kind, keeping the order
/// they came in otherwise.
List<T> sortTodos<T extends TodoItem>(Iterable<T> items) {
  final list = [...items];
  final at = {for (final (i, t) in list.indexed) t: i};
  list.sort((a, b) {
    final byKind = a.kind.index.compareTo(b.kind.index);
    return byKind != 0 ? byKind : at[a]!.compareTo(at[b]!);
  });
  return list;
}

/// The colour of the dot before « À traiter »: its most urgent group.
TodoGroup? mostUrgent(Iterable<TodoItem> items) {
  TodoGroup? best;
  for (final t in items) {
    if (best == null || t.group.index < best.index) best = t.group;
  }
  return best;
}

/// A rate set [days] or more calendar days before [now] is old.
bool rateIsOld(DateTime setOn, DateTime now, {int days = 30}) {
  final from = DateTime(setOn.year, setOn.month, setOn.day);
  final to = DateTime(now.year, now.month, now.day);
  return to.difference(from).inDays >= days;
}

/// Lines put off with « Plus tard »: each comes back the day after.
class PutOff {
  const PutOff._(this._days);

  static const empty = PutOff._({});

  /// Key → the day it was put off (yyyymmdd).
  final Map<String, int> _days;

  static int _day(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  factory PutOff.parse(String? text) {
    if (text == null) return empty;
    try {
      final map = jsonDecode(text) as Map<String, dynamic>;
      return PutOff._({
        for (final e in map.entries)
          if (e.value is int) e.key: e.value as int,
      });
    } on FormatException {
      return empty;
    }
  }

  String encode() => jsonEncode(_days);

  PutOff add(String key, DateTime now) => PutOff._({..._days, key: _day(now)});

  PutOff remove(String key) => PutOff._({..._days}..remove(key));

  /// [items] without those put off today; older ones are back.
  List<T> visible<T extends TodoItem>(Iterable<T> items, DateTime now) {
    final today = _day(now);
    return [
      for (final t in items)
        if ((_days[t.key] ?? 0) < today) t,
    ];
  }
}
