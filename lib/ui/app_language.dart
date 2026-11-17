import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

/// The language chosen inside kibuo (PRODUCT: first launch), or null to
/// follow the phone. MaterialApp listens to it.
final appLanguageChoice = ValueNotifier<Locale?>(null);

const _device = MethodChannel('kibuo/device');

/// Makes [code] kibuo's language: Android 13 and more keep it as the app's
/// own language (« Langue de l'application » in Android's settings, which
/// kibuo then follows); true when Android took it.
Future<bool> setAndroidAppLanguage(String code) async {
  try {
    return await _device.invokeMethod<bool>('appLanguage', code) ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}
