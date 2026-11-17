import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/recurrences/rhythm_text.dart';

void main() {
  setUpAll(() => initializeDateFormatting('fr'));
  final fr = lookupAppLocalizations(const Locale('fr'));
  String say(Schedule s) => rhythmText(fr, 'fr', s);

  test('in French, as on the canvas', () {
    expect(
      say(Schedule(start: DateTime(2026, 11, 8), unit: RepeatUnit.month)),
      'Le 8 de chaque mois, sans fin',
    );
    expect(
      say(
        Schedule(
          start: DateTime(2026, 11, 1),
          unit: RepeatUnit.month,
          every: 3,
          count: 4,
        ),
      ),
      'Le 1er, tous les 3 mois, 4 fois en tout',
    );
    expect(
      say(
        Schedule(
          start: DateTime(2026, 11, 16),
          unit: RepeatUnit.week,
          weekdays: {DateTime.monday, DateTime.thursday},
        ),
      ),
      'Chaque lundi et jeudi, sans fin',
    );
    expect(
      say(
        Schedule(
          start: DateTime(2026, 11, 16),
          unit: RepeatUnit.week,
          every: 2,
          weekdays: {DateTime.monday, DateTime.thursday},
        ),
      ),
      'Le lundi et le jeudi, une semaine sur deux, sans fin',
    );
    expect(
      say(
        Schedule(
          start: DateTime(2026, 11, 8),
          unit: RepeatUnit.day,
          every: 2,
          until: DateTime(2027, 6, 8),
        ),
      ),
      'Tous les 2 jours, jusqu’au 8 juin 2027',
    );
    expect(
      say(Schedule(start: DateTime(2026, 11, 8), unit: RepeatUnit.year)),
      'Chaque 8 novembre, sans fin',
    );
  });
}
