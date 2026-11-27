import 'dart:convert';

import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/preference_store.dart';
import 'package:kibuo/domain/overview/followed.dart';
import 'package:kibuo/domain/overview/overview_choice.dart';
import 'package:kibuo/domain/overview/overview_period.dart';

/// Keeps the Aperçu's « Période » choices.
class OverviewStore {
  OverviewStore(KibuoDatabase db) : _prefs = PreferenceStore(db);

  final PreferenceStore _prefs;

  static const _key = 'overview_period';

  Future<OverviewChoice> read() async {
    final text = await _prefs.read(_key);
    if (text == null) return const OverviewChoice();
    try {
      final json = jsonDecode(text) as Map<String, Object?>;
      T? named<T extends Enum>(List<T> values, Object? name) =>
          values.asNameMap()[name];
      final from = DateTime.tryParse('${json['from']}');
      final to = DateTime.tryParse('${json['to']}');
      return OverviewChoice(
        kind: named(PeriodKind.values, json['kind']) ?? PeriodKind.month,
        grouping: named(Grouping.values, json['grouping']),
        comparison:
            named(Comparison.values, json['comparison']) ?? Comparison.previous,
        comparedAs:
            named(ComparedAs.values, json['comparedAs']) ?? ComparedAs.curve,
        custom: from == null || to == null || to.isBefore(from)
            ? null
            : TimeSpan.days(from, to),
      );
    } on FormatException {
      return const OverviewChoice();
    } on TypeError {
      return const OverviewChoice();
    }
  }

  Future<void> write(OverviewChoice choice) {
    String day(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final custom = choice.custom;
    return _prefs.write(
      _key,
      jsonEncode({
        'kind': choice.kind.name,
        'grouping': choice.grouping?.name,
        'comparison': choice.comparison.name,
        'comparedAs': choice.comparedAs.name,
        if (custom != null) 'from': day(custom.start),
        if (custom != null) 'to': day(custom.lastDay),
      }),
    );
  }

  static const _followedKey = 'overview_followed';

  /// The tiles of « Points suivis » and the budget and project picked.
  Future<FollowedChoice> readFollowed() async {
    final text = await _prefs.read(_followedKey);
    if (text == null) return const FollowedChoice();
    try {
      final json = jsonDecode(text) as Map<String, Object?>;
      final names = Followed.values.asNameMap();
      return FollowedChoice(
        on: {for (final n in json['on'] as List<Object?>) ?names[n]},
        budget: json['budget'] as String?,
        project: json['project'] as String?,
        bars: json['bars'] == true,
      );
    } on FormatException {
      return const FollowedChoice();
    } on TypeError {
      return const FollowedChoice();
    }
  }

  Future<void> writeFollowed(FollowedChoice choice) => _prefs.write(
    _followedKey,
    jsonEncode({
      'on': [for (final f in choice.shown) f.name],
      'budget': choice.budget,
      'project': choice.project,
      'bars': choice.bars,
    }),
  );
}
