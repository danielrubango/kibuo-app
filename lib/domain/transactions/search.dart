/// The search of operations (PRODUCT): text without accents or capitals,
/// amounts typed as numbers, the recent searches and « Chercher par ».
library;

const _folds = {
  'a': 'àáâãäåāăą',
  'c': 'çćĉċč',
  'd': 'ďđ',
  'e': 'èéêëēĕėęě',
  'g': 'ĝğġģ',
  'i': 'ìíîïĩīĭįı',
  'l': 'ĺļľŀł',
  'n': 'ñńņňŉ',
  'o': 'òóôõöøōŏő',
  'r': 'ŕŗř',
  's': 'śŝşšș',
  't': 'ţťŧț',
  'u': 'ùúûüũūŭůűų',
  'y': 'ýÿŷ',
  'z': 'źżž',
};

final _fold = {
  for (final MapEntry(key: plain, value: marked) in _folds.entries)
    for (final c in marked.split('')) c: plain,
};

/// Lowercase and without accents, one letter for one, so a place found in
/// the folded text is the same place in the original.
String foldText(String s) {
  final out = StringBuffer();
  for (final c in s.split('')) {
    final lower = c.toLowerCase();
    final one = lower.length == 1 ? lower : c;
    out.write(_fold[one] ?? one);
  }
  return out.toString();
}

final _spaces = RegExp('[   ]');
final _number = RegExp(r'^[+\-−]?(\d+)(?:[.,](\d*))?$');

/// What was typed in the search field.
class SearchQuery {
  SearchQuery._(this.text, this._units, this._cents);

  factory SearchQuery.parse(String raw) {
    final trimmed = raw.trim();
    final number = _number.firstMatch(trimmed.replaceAll(_spaces, ''));
    return SearchQuery._(
      foldText(trimmed),
      number == null ? null : int.parse(number.group(1)!),
      number?.group(2),
    );
  }

  /// Folded, see [foldText].
  final String text;
  final int? _units;
  final String? _cents;

  bool get isEmpty => text.isEmpty;

  /// Where the words are in [field] (start, end), or null.
  (int, int)? find(String field) {
    if (isEmpty) return null;
    final at = foldText(field).indexOf(text);
    return at < 0 ? null : (at, at + text.length);
  }

  /// Whether an amount, in minor units with [decimals] digits after the
  /// comma, is the one typed: « 30 » is 30,00 to 30,99, « 30,5 » is 30,50.
  bool matchesAmount(int minor, {int decimals = 2}) {
    final units = _units;
    if (units == null) return false;
    var scale = 1;
    for (var i = 0; i < decimals; i++) {
      scale *= 10;
    }
    final abs = minor.abs();
    if (abs ~/ scale != units) return false;
    final cents = _cents;
    if (cents == null || cents.isEmpty) return true;
    if (cents.length > decimals) {
      return decimals == 0 && int.parse(cents) == 0;
    }
    return int.parse(cents.padRight(decimals, '0')) == abs % scale;
  }
}

/// The recent searches once [query] is searched: newest first, each once
/// (accents and capitals aside), [keep] at most.
List<String> rememberSearch(List<String> recent, String query, {int keep = 5}) {
  final q = query.trim();
  if (q.isEmpty) return recent;
  final key = foldText(q);
  return [
    q,
    for (final r in recent)
      if (foldText(r.trim()) != key) r,
  ].take(keep).toList();
}

/// The things used most over the last [days] days, the most recent first
/// when used as often; « Chercher par » offers them.
List<T> mostUsed<T>(
  Iterable<(T, DateTime)> used, {
  required DateTime now,
  int days = 30,
  int take = 3,
}) {
  final since = now.subtract(Duration(days: days));
  final count = <T, int>{};
  final last = <T, DateTime>{};
  for (final (thing, date) in used) {
    if (date.isBefore(since) || date.isAfter(now)) continue;
    count[thing] = (count[thing] ?? 0) + 1;
    final seen = last[thing];
    if (seen == null || date.isAfter(seen)) last[thing] = date;
  }
  final things = count.keys.toList()
    ..sort((a, b) {
      final byCount = count[b]!.compareTo(count[a]!);
      return byCount != 0 ? byCount : last[b]!.compareTo(last[a]!);
    });
  return things.take(take).toList();
}

/// Results of the [shown] month first, then the other months, newest
/// first, each newest first.
({List<T> shown, List<({DateTime month, List<T> items})> others}) splitByMonth<
  T
>(Iterable<T> items, DateTime Function(T) dateOf, DateTime shown) {
  DateTime monthOf(T t) {
    final d = dateOf(t);
    return DateTime(d.year, d.month);
  }

  final sorted = items.toList()..sort((a, b) => dateOf(b).compareTo(dateOf(a)));
  final mine = <T>[];
  final groups = <DateTime, List<T>>{};
  final month = DateTime(shown.year, shown.month);
  for (final t in sorted) {
    final m = monthOf(t);
    if (m == month) {
      mine.add(t);
    } else {
      (groups[m] ??= []).add(t);
    }
  }
  final months = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  return (
    shown: mine,
    others: [for (final m in months) (month: m, items: groups[m]!)],
  );
}
