import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/hint_store.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/transactions/budget_period.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/choice_menu.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/screens/placeholders.dart';
import 'package:kibuo/ui/theme/kibuo_icons.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';

String plain(String s) => s.replaceAll(RegExp('[\u00a0\u202f]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is RichText && plain(w.text.toPlainText()) == wanted,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late String mpesa;
  late String bank;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 9);

  setUp(() async {
    OperationsScreen.forget();
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
    );
    await data.currencies.ensurePrimaryCurrency('US');
    final start = DateTime.utc(now.year - 1);
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: start,
    );
    bank = await data.accounts.create(
      name: 'Rawbank',
      type: AccountType.bank,
      opening: const Money(100000, 'USD'),
      openingDate: start,
    );
    Future<void> add(
      EntryKind kind,
      String account,
      String cat,
      int minor,
      DateTime date,
    ) => data.transactions.create(
      kind: kind,
      accountId: account,
      categoryId: cat,
      paid: Money(minor, 'USD'),
      fees: 0,
      date: date,
    );
    await add(EntryKind.income, bank, 'default-salary', 120000, today);
    await add(EntryKind.expense, mpesa, 'default-taxi', 50000, today);
    await add(EntryKind.expense, bank, 'default-rent', 8800, today);
    await data.transactions.createTransfer(
      fromId: mpesa,
      toId: bank,
      sent: const Money(3000, 'USD'),
      fees: 0,
      date: today,
    );
  });
  tearDown(() => db.close());

  Future<void> start(WidgetTester tester, {HintStore? hints}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Scaffold(
          body: OperationsScreen(data: data, hints: hints),
        ),
      ),
    );
    if (hints == null) {
      await tester.pumpAndSettle();
    } else {
      // The tip loops: settle by time, not by stillness.
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
  }

  testWidgets('the month: entries, exits, share spent, what is left', (
    tester,
  ) async {
    await start(tester);
    expect(textPlain('+1 200,00 \$'), findsWidgets);
    expect(
      textPlain('−588,00 \$'),
      findsWidgets,
      reason: 'the transfer is out',
    );
    expect(find.text('49 % dépensés'), findsOneWidget);
    expect(textPlain('+612,00 \$'), findsWidgets);
  });

  testWidgets('a filter changes the list, not the month’s totals', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceRow, 'M-Pesa'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Loyer'), findsNothing);
    expect(textPlain('+1 200,00 \$'), findsWidgets);
    expect(textPlain('−588,00 \$'), findsWidgets);
    expect(find.text('49 % dépensés'), findsOneWidget);
  });

  testWidgets('the bar is always there: grey at 0 %, alert without entry', (
    tester,
  ) async {
    final last = DateTime(now.year, now.month - 1, 10, 9);
    final before = DateTime(now.year, now.month - 2, 10, 9);
    await data.transactions.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-taxi',
      paid: const Money(700, 'USD'),
      fees: 0,
      date: before,
    );
    await start(tester);
    // Last month: nothing in, nothing out.
    await tester.fling(find.byType(ListView).first, const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('0 % dépensés'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
    // The month before: out, nothing in.
    await tester.fling(find.byType(ListView).first, const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(last.month, isNot(before.month));
    expect(find.text('Aucune entrée'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
  });

  testWidgets('a day folds, showing how many operations it hides', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(textPlain('Aujourd’hui'));
    await tester.pumpAndSettle();
    expect(find.text('Taxi'), findsNothing);
    expect(textPlain('Aujourd’hui · 4'), findsOneWidget);
  });

  testWidgets('swiping right: the month before, empty, with a way back', (
    tester,
  ) async {
    await start(tester);
    await tester.fling(find.byType(ListView).first, const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Aucune opération'), findsOneWidget);
    await tester.tap(find.text('Revenir au mois en cours'));
    await tester.pumpAndSettle();
    expect(find.text('Taxi'), findsOneWidget);
  });

  testWidgets('the check and the dot share one end column: numbers line up', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Compte'));
    await tester.pumpAndSettle();
    final ends = find.byKey(const ValueKey('choice-end'));
    expect(ends, findsNWidgets(3), reason: 'Tous, M-Pesa, Rawbank');
    final rects = [
      for (final e in ends.evaluate()) tester.getRect(find.byWidget(e.widget)),
    ];
    for (final r in rects) {
      expect(r.width, 18);
      expect(r.left, rects.first.left);
    }
    Rect countOf(String row) => tester.getRect(
      find.descendant(
        of: find.widgetWithText(ChoiceRow, row),
        matching: find.byWidgetPredicate(
          (w) => w is Text && RegExp(r'^\d+$').hasMatch(w.data ?? ''),
        ),
      ),
    );
    expect(countOf('Tous').right, countOf('M-Pesa').right);
  });

  testWidgets('a chosen filter turns its chip black, labelled with it', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceRow, 'M-Pesa'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    final chip = tester.widget<FilterChipButton>(
      find.widgetWithText(FilterChipButton, 'M-Pesa'),
    );
    expect(chip.active, isTrue);
  });

  testWidgets('a choice without operations is greyed and cannot be picked', (
    tester,
  ) async {
    await data.accounts.create(
      name: 'Espèces',
      type: AccountType.cash,
      opening: const Money(0, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
    await start(tester);
    await tester.tap(find.text('Compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceRow, 'Espèces'));
    await tester.pumpAndSettle();
    final row = tester.widget<ChoiceRow>(
      find.widgetWithText(ChoiceRow, 'Espèces'),
    );
    expect(row.selected, isFalse);
  });

  testWidgets('Catégorie: the month’s categories by group, the others apart', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Catégorie'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceGroupTitle, 'Dépenses'), findsOneWidget);
    expect(find.widgetWithText(ChoiceGroupTitle, 'Revenus'), findsOneWidget);
    expect(find.widgetWithText(ChoiceRow, 'Transport'), findsOneWidget);
    expect(find.widgetWithText(ChoiceRow, 'Salaire'), findsOneWidget);
    expect(find.widgetWithText(ChoiceRow, 'Santé'), findsNothing);
    // 12 expense and 6 income categories, 3 used this month.
    await tester.tap(find.text('Afficher les 15 autres'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceRow, 'Santé'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceRow, 'Logement'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChipButton, 'Logement'), findsOneWidget);
    // « Toutes » clears the filter and closes the sheet.
    await tester.tap(find.widgetWithText(ChoiceRow, 'Toutes'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceRow, 'Santé'), findsNothing);
    expect(find.text('Catégorie'), findsOneWidget);
  });

  testWidgets('« Toutes » counts what the other filters keep', (tester) async {
    await start(tester);
    await tester.tap(find.text('Type'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceRow, 'Dépenses'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    // The longer chip pushes « Catégorie » past the edge: the row scrolls.
    await tester.ensureVisible(find.text('Catégorie'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catégorie'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.widgetWithText(ChoiceRow, 'Toutes'),
        matching: find.text('2'),
      ),
      findsOneWidget,
      reason: 'the taxi and the rent',
    );
  });

  testWidgets('the first visit shows the swipe, once', (tester) async {
    final hints = HintStore(db);
    await start(tester, hints: hints);
    expect(find.text('Changez de mois d’un geste'), findsOneWidget);
    await tester.tap(find.text('Compris'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Changez de mois d’un geste'), findsNothing);
    expect(await hints.swipeShown(), isTrue);
  });

  testWidgets('the tip waits for the tab to be shown', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final shown = ValueNotifier(false);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: shown,
            builder: (_, on, child) => TickerMode(enabled: on, child: child!),
            child: OperationsScreen(data: data, hints: HintStore(db)),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Changez de mois d’un geste'), findsNothing);
    shown.value = true;
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Changez de mois d’un geste'), findsOneWidget);
  });

  testWidgets('the menu stays under its chip after a choice', (tester) async {
    await start(tester);
    await tester.tap(find.text('Catégorie'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceRow, 'Transport'));
    await tester.pumpAndSettle();
    final chips = find.byType(FilterChipButton);
    final all = tester.widgetList<FilterChipButton>(chips).toList();
    final inRow = chips.at(all.indexWhere((c) => !c.open && c.active));
    final copy = chips.at(all.indexWhere((c) => c.open));
    // To the fraction of a pixel.
    expect(tester.getRect(copy), rectMoreOrLessEquals(tester.getRect(inRow)));
    expect(
      tester.getTopLeft(find.byType(ChoiceMenu)).dy,
      moreOrLessEquals(tester.getBottomLeft(inRow).dy + 6),
    );
  });

  testWidgets('« Tous » clears the filter and closes the menu', (tester) async {
    await start(tester);
    await tester.tap(find.text('Compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceRow, 'M-Pesa'));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceMenu), findsOneWidget, reason: 'several at once');
    await tester.tap(find.widgetWithText(ChoiceRow, 'Tous'));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceMenu), findsNothing);
    expect(find.text('Compte'), findsOneWidget);
  });

  String monthTitle(DateTime m) {
    final t = DateFormat.MMMM('fr').format(m);
    return t[0].toUpperCase() + t.substring(1);
  }

  // The full month, or the short one when the full does not fit.
  Finder titled(DateTime m) {
    final short = DateFormat.MMM('fr').format(m);
    final shortTitle = short[0].toUpperCase() + short.substring(1);
    return find.byWidgetPredicate((w) {
      if (w is! RichText) return false;
      final t = plain(w.text.toPlainText());
      return t.startsWith('${monthTitle(m)} ${m.year}') ||
          t.startsWith('$shortTitle ${m.year}');
    });
  }

  testWidgets('the month before slides in under the finger', (tester) async {
    await start(tester);
    final thisMonth = DateTime(now.year, now.month);
    final before = DateTime(now.year, now.month - 1);
    final finger = await tester.startGesture(const Offset(100, 500));
    await finger.moveBy(const Offset(40, 0));
    await finger.moveBy(const Offset(120, 0));
    await tester.pump();
    expect(titled(thisMonth), findsOneWidget);
    expect(titled(before), findsOneWidget, reason: 'both pages show');
    // Too short a slide: back to this month.
    await finger.up();
    await tester.pumpAndSettle();
    expect(titled(thisMonth), findsOneWidget);
    expect(titled(before), findsNothing);
    expect(find.text('Taxi'), findsOneWidget);
  });

  testWidgets('no month after this one', (tester) async {
    await start(tester);
    await tester.fling(
      find.byType(ListView).first,
      const Offset(-400, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(titled(DateTime(now.year, now.month)), findsOneWidget);
    expect(find.text('Taxi'), findsOneWidget);
  });

  testWidgets('the magnifier opens the search', (tester) async {
    await start(tester);
    await tester.tap(find.byTooltip('Rechercher'));
    await tester.pumpAndSettle();
    expect(find.text('Libellé, catégorie, compte, montant'), findsOneWidget);
  });

  testWidgets('the month sits where the other tabs put their title', (
    tester,
  ) async {
    await start(tester);
    final month = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('${now.year}'),
    );
    final listTitle = tester.getRect(month.first);
    await tester.pumpWidget(
      MaterialApp(
        theme: KibuoTheme.light(),
        home: const Scaffold(
          body: TabPlaceholder(
            title: 'Accueil',
            icon: KibuoIcons.house,
            message: '…',
          ),
        ),
      ),
    );
    final other = tester.getRect(find.text('Accueil'));
    expect(listTitle.center.dy, closeTo(other.center.dy, 1));
    expect(listTitle.left, closeTo(other.left, 1));
  });

  testWidgets(
    'a month from the 2nd: its days, and the period under the title',
    (tester) async {
      monthStartChoice.value = 2;
      final period = BudgetPeriod.containing(now, startDay: 2);
      Future<void> taxi(int minor, DateTime day) => data.transactions.create(
        kind: EntryKind.expense,
        accountId: mpesa,
        categoryId: 'default-taxi',
        paid: Money(minor, 'USD'),
        fees: 0,
        date: day,
      );
      await taxi(333, period.first.add(const Duration(hours: 9)));
      await taxi(777, period.first.subtract(const Duration(hours: 9)));
      await start(tester);
      expect(textPlain('−3,33 \$'), findsWidgets, reason: 'its first day');
      expect(textPlain('−7,77 \$'), findsNothing, reason: 'the day before');
      String d(DateTime x) => DateFormat.MMMd('fr').format(x);
      expect(
        find.text('du ${d(period.first)} au ${d(period.last)}'),
        findsOneWidget,
      );
    },
  );
}
