import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/accounts/overdraft.dart';

void main() {
  test('without overdraft, the balance stops at zero', () {
    const o = Overdraft.none;
    expect(o.allows(0), isTrue);
    expect(o.allows(-1), isFalse);
    expect(o.available(4500), 4500, reason: 'what may still leave');
  });

  test('up to a limit: down to minus that limit', () {
    const o = Overdraft(allowed: true, limit: 10000);
    expect(o.allows(-10000), isTrue);
    expect(o.allows(-10001), isFalse);
    expect(o.available(4500), 14500);
  });

  test('allowed with no limit, or a limit of 0: no floor', () {
    for (final o in const [
      Overdraft(allowed: true),
      Overdraft(allowed: true, limit: 0),
    ]) {
      expect(o.allows(-999999999), isTrue);
      expect(o.available(4500), isNull);
      expect(o.unlimited, isTrue);
    }
  });

  test('a limit kept while overdraft is off changes nothing', () {
    const o = Overdraft(allowed: false, limit: 10000);
    expect(o.allows(-1), isFalse);
  });
}
