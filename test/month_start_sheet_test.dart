import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/month_start_store.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/settings/month_start_sheet.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  setUp(() => db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p'));
  tearDown(() => db.close());

  String preview(int start) {
    final p = BudgetPeriod.containing(DateTime.now(), startDay: start);
    final m = DateFormat.MMMM('fr').format(p.month);
    String d(DateTime x) {
      final t = DateFormat.MMMMd('fr').format(x);
      return x.day == 1 ? t.replaceFirst(RegExp(r'^1(?=\D)'), '1er') : t;
    }

    return '${m[0].toUpperCase()}${m.substring(1)} ira du '
        '${d(p.first)} au ${d(p.last)}.';
  }

  Future<MonthStartStore> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final store = MonthStartStore(db);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showMonthStartSheet(context, store),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('the wheel says the period it makes; « Enregistrer » keeps it', (
    tester,
  ) async {
    final store = await open(tester);
    expect(find.text('Début du mois'), findsOneWidget);
    expect(find.text(preview(1)), findsOneWidget);
    // Four rows down: from the 1st to the 5th.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -176));
    await tester.pumpAndSettle();
    expect(find.text(preview(5)), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(monthStartChoice.value, 5);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    expect(await store.read(), 5);
  });

  testWidgets('closing changes nothing', (tester) async {
    final store = await open(tester);
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -176));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(monthStartChoice.value, 1);
    expect(await store.read(), 1);
  });
}
