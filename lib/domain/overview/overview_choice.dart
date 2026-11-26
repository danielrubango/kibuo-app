import 'package:kibuo/domain/overview/overview_period.dart';

/// « Période comparée en »: a soft curve, or wide grey sticks behind
/// thinner bars (DIRECTION, Aperçu).
enum ComparedAs { curve, sticks }

/// What the user chose in the Aperçu's « Période » sheet; the phone keeps
/// it from one launch to the next.
class OverviewChoice {
  const OverviewChoice({
    this.kind = PeriodKind.month,
    this.grouping,
    this.comparison = Comparison.previous,
    this.comparedAs = ComparedAs.curve,
    this.custom,
  });

  final PeriodKind kind;

  /// Null: the period's own default.
  final Grouping? grouping;
  final Comparison comparison;
  final ComparedAs comparedAs;

  /// The custom period's days, once chosen.
  final TimeSpan? custom;

  /// The grouping shown for [span]: the chosen one if it fits, else the
  /// first one offered.
  Grouping groupingFor(TimeSpan span) {
    final offered = groupingsFor(kind, span);
    return offered.contains(grouping) ? grouping! : offered.first;
  }

  /// The comparison shown [offset] steps back: the period before when the
  /// chosen one does not exist there.
  Comparison comparisonAt(int offset) =>
      comparisonOpen(comparison, offset: offset)
      ? comparison
      : Comparison.previous;

  /// Already 1 mois by day, compared with the period before: « Réinitialiser »
  /// is greyed (DIRECTION).
  bool isDefault(TimeSpan span) =>
      kind == PeriodKind.month &&
      groupingFor(span) == Grouping.day &&
      comparison == Comparison.previous;

  /// « Réinitialiser »: 1 mois by day, compared with the period before; the
  /// custom days and the compared period's form stay.
  OverviewChoice reset() =>
      OverviewChoice(comparedAs: comparedAs, custom: custom);

  /// Another period: its default grouping, compared with the one before.
  OverviewChoice withKind(PeriodKind kind, {TimeSpan? custom}) =>
      OverviewChoice(
        kind: kind,
        comparedAs: comparedAs,
        custom: custom ?? this.custom,
      );

  OverviewChoice withGrouping(Grouping grouping) => OverviewChoice(
    kind: kind,
    grouping: grouping,
    comparison: comparison,
    comparedAs: comparedAs,
    custom: custom,
  );

  OverviewChoice withComparison(Comparison comparison) => OverviewChoice(
    kind: kind,
    grouping: grouping,
    comparison: comparison,
    comparedAs: comparedAs,
    custom: custom,
  );

  OverviewChoice withComparedAs(ComparedAs comparedAs) => OverviewChoice(
    kind: kind,
    grouping: grouping,
    comparison: comparison,
    comparedAs: comparedAs,
    custom: custom,
  );

  /// New custom days: the grouping goes back to what fits them.
  OverviewChoice withCustom(TimeSpan custom) => OverviewChoice(
    kind: kind,
    comparison: comparison,
    comparedAs: comparedAs,
    custom: custom,
  );
}
