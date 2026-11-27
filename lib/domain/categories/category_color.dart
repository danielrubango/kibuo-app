/// A category's colour, kept by its name (ADR 0014): ten to choose from,
/// and the grey of « Autres », never handed out (PRODUCT « Couleur des
/// catégories », 27 November 2026).
enum CategoryColor {
  peach,
  apricot,
  sand,
  coral,
  rose,
  lavender,
  blue,
  sky,
  mint,
  green,
  grey;

  /// The colour stored as [name], or null for none or an unknown one.
  static CategoryColor? named(String? name) {
    for (final c in values) {
      if (c.name == name) return c;
    }
    return null;
  }

  /// The ten a category can take, in the palette's order.
  static const choosable = [
    peach,
    apricot,
    sand,
    coral,
    rose,
    lavender,
    blue,
    sky,
    mint,
    green,
  ];
}

/// The colours of the categories the app provides (PRODUCT); any other
/// provided one (« Autres », debts, receivables, adjustments) is grey.
const _provided = {
  'housing': CategoryColor.peach,
  'groceries': CategoryColor.apricot,
  'food': CategoryColor.rose,
  'transport': CategoryColor.blue,
  'communication': CategoryColor.sky,
  'health': CategoryColor.coral,
  'school': CategoryColor.lavender,
  'family': CategoryColor.sand,
  'outings': CategoryColor.mint,
  'contributions': CategoryColor.green,
  'salary': CategoryColor.mint,
  'business': CategoryColor.green,
  'giftReceived': CategoryColor.rose,
  'refund': CategoryColor.sky,
};

/// The colour of the provided category [key].
CategoryColor providedColor(String key) => _provided[key] ?? CategoryColor.grey;

/// The colour a new category takes: the least used of [used] (its list's),
/// the first in the palette's order among equals. Grey never counts.
CategoryColor leastUsed(Iterable<CategoryColor> used) {
  final counts = {for (final c in CategoryColor.choosable) c: 0};
  for (final c in used) {
    if (counts.containsKey(c)) counts[c] = counts[c]! + 1;
  }
  var best = CategoryColor.choosable.first;
  for (final c in CategoryColor.choosable) {
    if (counts[c]! < counts[best]!) best = c;
  }
  return best;
}

/// A category as the start rule sees it.
typedef StartCategory = ({
  String id,
  String kind,
  String? key,
  String? parentId,
  int position,
  CategoryColor? color,
});

/// The colours categories start with (ADR 0014): a colour already set is
/// kept; a provided category takes its own; the user's own, in their list's
/// order, the least used of their list (Dépenses or Revenus). A subcategory
/// gets none: it shows its category's.
Map<String, CategoryColor> startColors(Iterable<StartCategory> categories) {
  final top = [
    for (final c in categories)
      if (c.parentId == null) c,
  ]..sort((a, b) => a.position.compareTo(b.position));
  final colors = <String, CategoryColor>{};
  final used = <String, List<CategoryColor>>{};
  for (final c in top) {
    final color = c.color ?? (c.key == null ? null : providedColor(c.key!));
    if (color == null) continue;
    colors[c.id] = color;
    (used[c.kind] ??= []).add(color);
  }
  for (final c in top) {
    if (colors.containsKey(c.id)) continue;
    final list = used[c.kind] ??= [];
    final color = leastUsed(list);
    colors[c.id] = color;
    list.add(color);
  }
  return colors;
}
