import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/data/account_repository.dart';
import 'package:kibuo/data/attachment_repository.dart';
import 'package:kibuo/data/category_repository.dart';
import 'package:kibuo/data/currency_repository.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/recurring_repository.dart';
import 'package:kibuo/data/transaction_repository.dart';
import 'package:kibuo/domain/money/money.dart';
import 'package:kibuo/domain/recurrences/schedule.dart';
import 'package:kibuo/l10n/app_localizations.dart';
import 'package:kibuo/ui/app_language.dart';
import 'package:kibuo/ui/kit/buttons.dart';
import 'package:kibuo/ui/month_start.dart';
import 'package:kibuo/ui/recurrences/list_display.dart';
import 'package:kibuo/ui/theme/kibuo_theme.dart';
import 'package:kibuo/ui/transactions/draft_screen.dart';
import 'package:kibuo/ui/transactions/entry_screen.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';
import 'package:kibuo/ui/transactions/operations_list.dart';
import 'package:kibuo/ui/transactions/search_screen.dart';

String plain(String s) => s.replaceAll(RegExp('[  ]'), ' ');

Finder textPlain(String wanted) => find.byWidgetPredicate(
  (w) => w is RichText && plain(w.text.toPlainText()) == wanted,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late KibuoDatabase db;
  late EntryData data;
  late RecurringRepository rules;
  late String mpesa;
  final now = DateTime.now();
  // At midnight: never in the future, whatever the hour of the run.
  final today = DateTime(now.year, now.month, now.day);

  setUp(() async {
    OperationsScreen.forget();
    db = KibuoDatabase(NativeDatabase.memory(), deviceId: 'p');
    rules = RecurringRepository(db);
    data = EntryData(
      accounts: AccountRepository(db),
      categories: CategoryRepository(db),
      currencies: CurrencyRepository(db),
      transactions: TransactionRepository(db),
      attachments: AttachmentRepository.withFiles(db, MemoryFiles()),
      recurrences: rules,
    );
    await data.currencies.ensurePrimaryCurrency('US');
    mpesa = await data.accounts.create(
      name: 'M-Pesa',
      type: AccountType.mobile,
      opening: const Money(100000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
  });
  tearDown(() => db.close());

  /// Internet, 30 $, made today as a draft by its recurrence.
  Future<String> draft({int minor = 3000, String? account}) async {
    final rule = await rules.create(
      kind: EntryKind.expense,
      accountId: account ?? mpesa,
      categoryId: 'default-internet',
      amount: Money(minor, 'USD'),
      note: 'Internet',
      unit: RepeatUnit.month,
      start: today,
      asDraft: true,
    );
    await rules.catchUp(now);
    return (await data.transactions.all(drafts: true))
        .firstWhere((t) => t.recurringId == rule)
        .id;
  }

  /// Database writes need real time; then the frames.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> show(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: KibuoTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appLanguages,
        localeListResolutionCallback: (phone, _) => resolveAppLanguage(phone),
        home: home,
      ),
    );
    await settle(tester);
  }

  Future<void> list(WidgetTester tester) =>
      show(tester, Scaffold(body: OperationsScreen(data: data)));

  /// The toast goes after a moment.
  Future<void> toastGone(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  Future<String> status(String id) async =>
      (await data.transactions.get(id))!.status;

  testWidgets('a draft: its card, out of the month’s totals', (tester) async {
    await draft();
    await list(tester);
    expect(find.byType(DraftCard), findsOneWidget);
    expect(find.text('Brouillon'), findsOneWidget);
    expect(find.text('Ignorer'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
    expect(find.text('Récurrence · M-Pesa'), findsOneWidget);
    expect(find.text('0 % dépensés'), findsOneWidget);
  });

  testWidgets('« Valider »: counted at once, with a toast', (tester) async {
    final id = await draft();
    await list(tester);
    await tester.tap(find.text('Valider'));
    await settle(tester);
    expect(await status(id), 'done');
    expect(find.text('Validé : Internet, compté dans le mois'), findsOneWidget);
    expect(find.byType(DraftCard), findsNothing);
    expect(textPlain('−30,00 \$'), findsWidgets);
    await toastGone(tester);
    expect(find.text('Validé : Internet, compté dans le mois'), findsNothing);
  });

  testWidgets('« Ignorer »: stays at its date, struck, marked « Ignoré »', (
    tester,
  ) async {
    final id = await draft();
    await list(tester);
    await tester.tap(find.text('Ignorer'));
    await settle(tester);
    expect(await status(id), 'ignored');
    expect(
      find.text('Ignoré : Internet. Validez-le depuis son détail.'),
      findsOneWidget,
    );
    expect(find.byType(DraftCard), findsNothing);
    expect(find.text('Ignoré'), findsOneWidget);
    await toastGone(tester);
  });

  testWidgets('below the floor: « Valider » opens the card and says why', (
    tester,
  ) async {
    final poor = await data.accounts.create(
      name: 'Cash',
      type: AccountType.cash,
      opening: const Money(1000, 'USD'),
      openingDate: DateTime.utc(now.year - 1),
    );
    final id = await draft(account: poor);
    await list(tester);
    await tester.tap(find.text('Valider'));
    await settle(tester);
    expect(find.byType(DraftScreen), findsOneWidget);
    expect(await status(id), 'draft');
    expect(textPlain('10,00 \$ disponibles sur Cash'), findsOneWidget);
    expect(find.text('Autoriser'), findsOneWidget);
    final validate = tester.widget<KibuoButton>(
      find.widgetWithText(KibuoButton, 'Valider l’opération'),
    );
    expect(validate.onPressed, isNull);
  });

  testWidgets('the draft’s card: « Ignorer cette fois »', (tester) async {
    final id = await draft();
    await show(tester, DraftScreen(data: data, id: id));
    expect(find.text('Brouillon · récurrence mensuelle'), findsOneWidget);
    expect(find.text('Le ${today.day} de chaque mois'), findsOneWidget);
    await tester.tap(find.text('Ignorer cette fois'));
    await settle(tester);
    expect(await status(id), 'ignored');
    await toastGone(tester);
  });

  testWidgets('« Changer le montant »: saving validates the draft', (
    tester,
  ) async {
    final id = await draft();
    await show(tester, DraftScreen(data: data, id: id));
    await tester.tap(find.text('Changer le montant'));
    await settle(tester);
    await tester.tap(find.text('Enregistrer les modifications'));
    await settle(tester);
    expect(await status(id), 'done');
    await toastGone(tester);
  });

  testWidgets('an ignored one’s card: no « Ignorer cette fois »', (
    tester,
  ) async {
    final id = await draft();
    await data.transactions.ignore(id);
    await show(tester, DraftScreen(data: data, id: id));
    expect(find.text('Ignoré · récurrence mensuelle'), findsOneWidget);
    expect(find.text('Valider l’opération'), findsOneWidget);
    expect(find.text('Ignorer cette fois'), findsNothing);
    await tester.tap(find.text('Valider l’opération'));
    await settle(tester);
    expect(await status(id), 'done');
    await toastGone(tester);
  });

  testWidgets('planned dates: dashed, « Prévu », in no total, hideable', (
    tester,
  ) async {
    final tomorrow = DateTime(today.year, today.month, today.day + 1);
    final inPeriod = periodOf(now).contains(tomorrow);
    await rules.create(
      kind: EntryKind.expense,
      accountId: mpesa,
      categoryId: 'default-internet',
      amount: const Money(1500, 'USD'),
      unit: RepeatUnit.day,
      start: tomorrow,
    );
    await list(tester);
    expect(find.text('Prévu'), inPeriod ? findsWidgets : findsNothing);
    expect(find.text('0 % dépensés'), findsOneWidget);
    await rules.setShowPlanned(false);
    OperationsScreen.forget();
    await list(tester);
    expect(find.text('Prévu'), findsNothing);
  });

  testWidgets('« Groupés en haut »: drafts under « À valider · 1 »', (
    tester,
  ) async {
    await draft();
    await rules.setDraftsOnTop(true);
    await list(tester);
    expect(find.text('À valider · 1'), findsOneWidget);
    expect(find.byType(DraftCard), findsOneWidget);
  });

  testWidgets('the display sheet: three choices, kept', (tester) async {
    await list(tester);
    await tester.tap(find.byTooltip('Affichage de la liste'));
    await settle(tester);
    expect(find.text('Quand une récurrence arrive à sa date'), findsOneWidget);
    await tester.tap(find.text('Toujours demander'));
    await tester.tap(find.text('Groupés en haut'));
    await tester.tap(find.text('Masquées'));
    await settle(tester);
    await tester.tap(find.text('Terminé'));
    await settle(tester);
    expect(await rules.alwaysAsk(), isTrue);
    expect(await rules.draftsOnTop(), isTrue);
    expect(await rules.showPlanned(), isFalse);
  });

  testWidgets('Plus › « Récurrences et brouillons »: the whole sentences', (
    tester,
  ) async {
    await show(tester, RecurrencesSettingsScreen(recurrences: rules));
    expect(
      find.text('Chaque opération arrive en brouillon et attend votre accord.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Toujours demander'));
    await settle(tester);
    expect(await rules.alwaysAsk(), isTrue);
  });

  testWidgets('the search finds drafts, with their card', (tester) async {
    await draft();
    await show(tester, SearchScreen(data: data, month: periodOf(now).month));
    await tester.enterText(find.byType(TextField), 'internet');
    await settle(tester);
    expect(find.byType(DraftCard), findsOneWidget);
  });
}
