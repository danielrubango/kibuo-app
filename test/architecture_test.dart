import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Domain code must stay portable to iOS, web and a future server, so it may
/// only import Dart itself, pure packages, and other domain files.
void main() {
  test('domain code imports no Flutter or app layer', () {
    final importPattern = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
    );
    const forbidden = [
      'package:flutter/',
      'package:flutter_test/',
      'dart:ui',
      'dart:io',
      'dart:html',
    ];
    final offenders = <String>[];

    final files = Directory('lib/domain')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in files) {
      for (final line in file.readAsLinesSync()) {
        final match = importPattern.firstMatch(line);
        if (match == null) continue;
        final target = match.group(1)!;
        final reachesOutside =
            target.startsWith('package:kibuo/') &&
            !target.startsWith('package:kibuo/domain/');
        if (forbidden.any(target.startsWith) || reachesOutside) {
          offenders.add('${file.path}: $target');
        }
      }
    }

    expect(offenders, isEmpty, reason: 'Domain files must stay pure Dart.');
  });
}
