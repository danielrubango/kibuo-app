import 'package:kibuo/domain/money/currency.dart';
import 'package:kibuo/domain/money/exchange_rate.dart';
import 'package:kibuo/domain/overview/followed.dart';
import 'package:kibuo/domain/overview/overview_period.dart';

/// What a line of the Catégories tab stands for.
enum CategoryLineKind {
  /// A category, its subcategories included.
  category,

  /// Money lent, borrowed or paid back (« Dettes et créances »).
  debts,

  /// What no category explains: a transfer's fees (« Frais de transfert »).
  fees,
}

/// A line of the Catégories tab: its [category] (a category's id, else
/// null), its amount in the main currency and its share of the total.
typedef CategoryLine = ({
  CategoryLineKind kind,
  String? category,
  int amount,
  int share,
});

/// The lines of the Catégories tab over [span] (PRODUCT, 27 November
/// 2026): each category with its subcategories ([parentOf]), the debts'
/// and receivables' categories ([isDebt]) together, and, [withFees], what
/// is left of [total] once the categories are counted, as transfer fees;
/// so the lines add up to [total]. The most first.
List<CategoryLine> categoryLines(
  TimeSpan span,
  Iterable<CategorySpend> spends, {
  required String Function(String id) parentOf,
  required bool Function(String id) isDebt,
  required int total,
  required bool withFees,
  required CurrencyInfo main,
  required ExchangeRate? Function(String code) rateFor,
}) {
  const debts = '\u0000debts';
  final found = topCategories(
    span,
    spends,
    parentOf: (id) => isDebt(id) ? debts : parentOf(id),
    exits: total,
    main: main,
    rateFor: rateFor,
    count: 1 << 30,
  );
  final lines = <CategoryLine>[
    for (final c in found)
      c.category == debts
          ? (
              kind: CategoryLineKind.debts,
              category: null,
              amount: c.amount,
              share: c.share,
            )
          : (
              kind: CategoryLineKind.category,
              category: c.category,
              amount: c.amount,
              share: c.share,
            ),
  ];
  final counted = lines.fold(0, (a, l) => a + l.amount);
  final left = total - counted;
  if (withFees && left > 0) {
    lines.add((
      kind: CategoryLineKind.fees,
      category: null,
      amount: left,
      share: total <= 0 ? 0 : (left * 100 / total).round(),
    ));
    // Stable: equal amounts keep their order.
    final order = {for (final (i, l) in lines.indexed) l: i};
    lines.sort(
      (a, b) =>
          a.amount != b.amount ? b.amount - a.amount : order[a]! - order[b]!,
    );
  }
  return lines;
}

/// The lines shown, and the rest under « Autres » : up to five all show;
/// beyond, the first four (PRODUCT).
({List<CategoryLine> shown, List<CategoryLine> rest}) splitLines(
  List<CategoryLine> lines,
) => lines.length <= 5
    ? (shown: lines, rest: const [])
    : (shown: lines.take(4).toList(), rest: lines.skip(4).toList());
