import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/long_amounts.dart';
import 'package:kibuo/ui/money/fit_amount.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';

/// The test font is far wider than the phone's, so « Automatique » would
/// shorten amounts that fit on a phone: screens are checked with whole
/// amounts, and fit_amount_test covers the three choices. Months start
/// on the 1st unless a test says otherwise.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() {
    longAmountsChoice.value = LongAmounts.never;
    monthStartChoice.value = 1;
    OperationsScreen.show.value = null;
  });
  await testMain();
}
