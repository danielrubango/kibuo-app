import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/ui/kit/keypad.dart';

void main() {
  String typeAll(String keys, {int decimals = 2}) {
    var typed = '';
    for (final k in keys.split(' ')) {
      typed = typeKey(typed, k, decimals: decimals);
    }
    return typed;
  }

  test('digits, then a comma and at most the currency’s decimals', () {
    expect(typeAll('1 2 , 5 0 7'), '12,50');
    expect(typeAll(', 5'), '0,5');
    expect(typeAll('1 , , 2'), '1,2');
  });

  test('without cents: no comma, and « 000 » adds three zeros', () {
    expect(typeAll('1 4 000', decimals: 0), '14000');
    expect(typeAll('1 , 2', decimals: 0), '12');
    expect(typeAll('000', decimals: 0), '', reason: 'not a leading zero');
  });

  test('a leading zero is replaced', () {
    expect(typeAll('0 7'), '7');
  });
}
