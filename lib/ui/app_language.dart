import 'dart:ui';

/// The languages Kibuo speaks.
const appLanguages = [Locale('fr'), Locale('en')];

/// Picks Kibuo's language from the phone's languages, in the user's order of
/// preference: the first one Kibuo speaks, or French when it speaks none.
Locale resolveAppLanguage(List<Locale>? phone) {
  for (final locale in phone ?? const <Locale>[]) {
    for (final language in appLanguages) {
      if (language.languageCode == locale.languageCode) return language;
    }
  }
  return appLanguages.first;
}
