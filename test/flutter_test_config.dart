import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/long_amounts.dart';
import 'package:kibuo/ui/money/fit_amount.dart';

/// The test font is far wider than the phone's, so « Automatique » would
/// shorten amounts that fit on a phone: screens are checked with whole
/// amounts, and fit_amount_test covers the three choices.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() => longAmountsChoice.value = LongAmounts.never);
  await testMain();
}
