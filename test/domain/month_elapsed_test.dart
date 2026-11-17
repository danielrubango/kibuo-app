import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';

void main() {
  test('the share of the month gone by, today included', () {
    expect(monthElapsed(DateTime(2026, 11, 11)), closeTo(11 / 30, 1e-9));
    expect(monthElapsed(DateTime(2026, 11, 30, 23)), 1);
    expect(monthElapsed(DateTime(2026, 2, 1)), closeTo(1 / 28, 1e-9));
    expect(monthElapsed(DateTime(2028, 2, 14)), closeTo(14 / 29, 1e-9));
  });
}
