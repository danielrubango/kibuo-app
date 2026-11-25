import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kibuo/ui/app_language.dart';

void main() {
  group('the language follows the phone', () {
    test('French or English when the phone uses it', () {
      expect(
        resolveAppLanguage(const [Locale('fr', 'CD')]),
        const Locale('fr'),
      );
      expect(
        resolveAppLanguage(const [Locale('en', 'US')]),
        const Locale('en'),
      );
    });

    test('the first language Kibuo speaks in the phone’s list', () {
      expect(
        resolveAppLanguage(const [Locale('sw'), Locale('en'), Locale('fr')]),
        const Locale('en'),
      );
    });

    test('French when the phone speaks neither', () {
      expect(
        resolveAppLanguage(const [Locale('sw', 'CD')]),
        const Locale('fr'),
      );
      expect(resolveAppLanguage(const [Locale('ln')]), const Locale('fr'));
      expect(resolveAppLanguage(null), const Locale('fr'));
    });
  });
}
