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

  @override
  String get lockCreateTitle => 'Create your code';

  @override
  String get lockChoose => 'Choose your code';

  @override
  String get lockChooseHint => '4 to 6 digits.';

  @override
  String get lockConfirm => 'Type your code again';

  @override
  String get lockConfirmHint => 'To check you have it in mind.';

  @override
  String get lockMismatch => 'The two codes don’t match. Start again.';

  @override
  String get lockValidate => 'Confirm';

  @override
  String get lockCreatedTitle => 'Code created';

  @override
  String get lockCreatedBody =>
      'Kibuo will ask for this code each time it opens.';

  @override
  String get continueAction => 'Continue';

  @override
  String get lockEnterTitle => 'Enter your code';

  @override
  String get lockCurrentTitle => 'Enter your current code';

  @override
  String get lockTooMany => 'Too many attempts';

  @override
  String get lockUseFingerprint => 'Use fingerprint';

  @override
  String get lockForgot => 'Forgot your code?';

  @override
  String get keypadDelete => 'Delete';

  @override
  String get fingerprintOfferTitle => 'Open Kibuo with your fingerprint?';

  @override
  String get fingerprintOfferBody =>
      'Faster than the code, which you can still use at any time.';

  @override
  String get fingerprintEnable => 'Turn on fingerprint';

  @override
  String get later => 'Not now';

  @override
  String get fingerprintReason => 'Open Kibuo';

  @override
  String get forgotErase => 'Erase and start over';

  @override
  String get forgotEraseBody =>
      'All of Kibuo’s data on this phone will be erased. You can then restore a backup, if you have one.';

  @override
  String get forgotHold => 'Hold to erase';

  @override
  String get securityTitle => 'Security';

  @override
  String get securityLock => 'App lock';

  @override
  String get securityPrivacy => 'Privacy';

  @override
  String get securityNoCode => 'No code';

  @override
  String get securityCode => 'Code';

  @override
  String get securityCodeFingerprint => 'Code · fingerprint';

  @override
  String get securityRecentsHidden => 'Hidden in recents';

  @override
  String get securityRecentsShown => 'Shown in recents';

  @override
  String get securityFooter =>
      'Your data is encrypted and stays on this phone.';

  @override
  String get lockSettingsCreate => 'Create a code';

  @override
  String get lockSettingsChange => 'Change the code';

  @override
  String get lockFingerprint => 'Fingerprint';

  @override
  String get lockShuffle => 'Shuffled keypad';

  @override
  String get lockShuffleHelp =>
      'The shuffled keypad moves the digits around each time, so a glance over your shoulder isn’t enough to guess the code.';

  @override
  String get lockAfter => 'Lock after being away for';

  @override
  String get delayImmediately => 'Right away';

  @override
  String get delayOneMinute => '1 minute';

  @override
  String get delayFiveMinutes => '5 minutes';

  @override
  String get lockRemove => 'Remove the code';

  @override
  String get lockRemoveHelp =>
      'Without a code, Kibuo opens directly. Your data stays encrypted.';

  @override
  String get privacyHideRecents => 'Hide Kibuo in recent apps';

  @override
  String get privacyScreenshots => 'Allow screenshots';

  @override
  String get privacyHelp =>
      'When hidden, the recent apps preview shows Kibuo’s logo instead of your balances.';

  @override
  String lockWrong(int count) {
    return 'Wrong code. Attempt $count of 5.';
  }

  @override
  String lockRetryIn(String time) {
    return 'Try again in $time.';
  }

  @override
  String lockDigits(int count) {
    return '$count digits';
  }

  @override
  String get lockAfterRow => 'Lock after';

  @override
  String get delayThirtySeconds => '30 seconds';

  @override
  String get delayFifteenMinutes => '15 minutes';
}
