import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/domain/transactions/flow_totals.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/kit/spent_bar.dart';
import 'package:kibuo/ui/theme/kibuo_colors.dart';

FlowTotals month(int inMinor, int outMinor) => FlowTotals(
  entries: Money(inMinor, 'USD'),
  exits: Money(outMinor, 'USD'),
  approximate: false,
);

void main() {
  test('grey to 80 %, amber to 100 %, peach beyond or without entry', () {
    expect(SpentLevel(month(100, 49)).bar, KibuoColors.inkMuted);
    expect(SpentLevel(month(100, 85)).bar, KibuoColors.warning);
    expect(SpentLevel(month(100, 112)).bar, KibuoColors.debtInk);
    final outOnly = SpentLevel(month(0, 10));
    expect(outOnly.outOnly, isTrue);
    expect(outOnly.bar, KibuoColors.debtInk);
    expect(SpentLevel(month(0, 0)).level, 0);
  });

  Future<void> show(WidgetTester tester, (DateTime, BudgetPeriod)? today) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: SpentBar(
                  spent: SpentLevel(month(100, 49)),
                  today: today,
                ),
              ),
            ),
          ),
        ),
      );

  testWidgets('10 high; this month, the day marked with its date', (
    tester,
  ) async {
    await show(tester, null);
    expect(tester.getSize(find.byType(LinearProgressIndicator)).height, 10);
    expect(find.text('17 nov.'), findsNothing);
    await show(tester, (
      DateTime(2026, 11, 17),
      BudgetPeriod.named(2026, 11, startDay: 1),
    ));
    expect(tester.getSize(find.byType(LinearProgressIndicator)).height, 10);
    expect(find.text('17 nov.'), findsOneWidget);
  });
}
