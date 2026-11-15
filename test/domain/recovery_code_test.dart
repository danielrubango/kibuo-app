import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/lock/recovery_code.dart';

void main() {
  test('a new code has 16 characters, without 0, 1, I or O', () {
    final random = Random(7);
    for (var i = 0; i < 200; i++) {
      final code = newRecoveryCode(random);
      expect(code, hasLength(16));
      expect(code, matches(RegExp(r'^[2-9A-HJ-NP-Z]{16}$')));
    }
  });

  test('two new codes differ', () {
    final random = Random.secure();
    expect(newRecoveryCode(random), isNot(newRecoveryCode(random)));
  });

  test('it is shown in 4 groups of 4', () {
    expect(formatRecoveryCode('KB7Q4M2X9TPAH3WD'), 'KB7Q-4M2X-9TPA-H3WD');
    expect(recoveryGroups('KB7Q4M2X9TPAH3WD'), [
      'KB7Q',
      '4M2X',
      '9TPA',
      'H3WD',
    ]);
  });

  test('dashes, spaces and lowercase do not count when typing it', () {
    expect(normalizeRecoveryCode(' kb7q-4m2x 9tpa_h3wd '), 'KB7Q4M2X9TPAH3WD');
  });

  test('only a full code from the alphabet is a code', () {
    expect(isRecoveryCode('KB7Q4M2X9TPAH3WD'), isTrue);
    expect(isRecoveryCode('KB7Q4M2X9TPAH3W'), isFalse);
    expect(isRecoveryCode('KB7Q4M2X9TPAH3W0'), isFalse);
  });
}
