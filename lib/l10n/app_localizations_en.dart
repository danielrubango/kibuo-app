// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabOperations => 'Transactions';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabMore => 'More';

  @override
  String get homeTitle => 'Today';

  @override
  String get homePlaceholder =>
      'Your available money, the current month and what’s coming up will be here.';

  @override
  String get operationsPlaceholder => 'This month’s transactions will be here.';

  @override
  String get overviewPlaceholder =>
      'Charts and the items you follow will be here.';

  @override
  String get morePlaceholder => 'Your spaces and settings will be here.';

  @override
  String get plusButton => 'Add a transaction';

  @override
  String get plusButtonHint => 'Hold for quick choices';

  @override
  String get addSheetTitle => 'Add';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get fanHint => 'Slide to a choice, or tap it';

  @override
  String get addExpense => 'Expense';

  @override
  String get addExpenseHint => 'Most frequent';

  @override
  String get addExpenseTitle => 'New expense';

  @override
  String get addIncome => 'Income';

  @override
  String get addIncomeHint => 'Salary, sale';

  @override
  String get addIncomeTitle => 'New income';

  @override
  String get addTransfer => 'Transfer';

  @override
  String get addTransferHint => 'Move money';

  @override
  String get addTransferTitle => 'New transfer';

  @override
  String get addDebt => 'Debt';

  @override
  String get addDebtHint => 'or money owed';

  @override
  String get addDebtFan => 'Debt or\nmoney owed';

  @override
  String get addDebtTitle => 'New debt or money owed';

  @override
  String get addProject => 'Savings';

  @override
  String get addProjectHint => 'Put money aside';

  @override
  String get addProjectFan => 'Put\naside';

  @override
  String get addProjectTitle => 'Put money aside';

  @override
  String get entryComingLater => 'This entry comes in a later step.';

  @override
  String get unreadableTitle => 'Your data can’t be opened';

  @override
  String get unreadableBody =>
      'The key that protects your data is no longer on this phone, or no longer matches. The file is kept aside on the phone, not erased.';

  @override
  String get unreadableStartOver => 'Start over';
}
