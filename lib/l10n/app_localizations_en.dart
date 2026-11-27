// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String transferTitle(String account) {
    return 'To $account';
  }

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
  String get longAmounts => 'Long amounts';

  @override
  String get longAmountsAuto => 'Automatic';

  @override
  String get longAmountsAutoHelp => 'Shortens only what doesn’t fit';

  @override
  String get longAmountsAlways => 'Always';

  @override
  String get longAmountsAlwaysHelp => 'From 10,000: 1.2M instead of 1,245,000';

  @override
  String get longAmountsNever => 'Never';

  @override
  String get longAmountsNeverHelp => 'Always whole, smaller if needed';

  @override
  String get longAmountsNote =>
      'Entry, an operation’s details and confirmations always show the whole amount.';

  @override
  String listPeriod(String first, String last) {
    return '$first to $last';
  }

  @override
  String get monthStart => 'Start of the month';

  @override
  String get monthStartHelp => 'The day your month starts, for example payday.';

  @override
  String monthStartValue(int day) {
    return 'Day $day';
  }

  @override
  String monthStartPreview(String month, String first, String last) {
    return '$month will run from $first to $last.';
  }

  @override
  String get monthStartSave => 'Save';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsEmptyTitle => 'No budgets yet';

  @override
  String get budgetsEmptyHelp =>
      'Set an amount per category to follow your spending.';

  @override
  String get budgetsAdd => 'Add a budget';

  @override
  String budgetsDays(String first, String last) {
    return '$first to $last';
  }

  @override
  String budgetsOutOf(String spent, String amount) {
    return '$spent of $amount';
  }

  @override
  String get budgetsTooMuch => 'over';

  @override
  String budgetsLeftOf(String amount) {
    return 'left of $amount';
  }

  @override
  String budgetsOverOf(String amount) {
    return 'over $amount';
  }

  @override
  String budgetsSpentOf(String spent, String amount) {
    return '$spent spent of $amount';
  }

  @override
  String get budgetsGroupOver => 'Over';

  @override
  String get budgetsGroupNear => 'Nearly reached';

  @override
  String get budgetsGroupOk => 'On track';

  @override
  String get budgetsDisplay => 'Budgets display';

  @override
  String get budgetsLayout => 'Layout';

  @override
  String get budgetsTiles => 'Tiles';

  @override
  String get budgetsTilesHelp => 'Two columns, what’s left large';

  @override
  String get budgetsList => 'List';

  @override
  String get budgetsListHelp => 'One row per budget, grouped by state';

  @override
  String get budgetsOrder => 'Order';

  @override
  String get budgetsWatch => 'To watch';

  @override
  String get budgetsWatchHelp => 'Most used first';

  @override
  String get budgetsMine => 'My order';

  @override
  String get budgetsMineHelp => 'The one you choose, by dragging';

  @override
  String get budgetsDone => 'Done';

  @override
  String get budgetNew => 'New budget';

  @override
  String get budgetEdit => 'Edit budget';

  @override
  String get budgetAmount => 'Amount per month';

  @override
  String budgetAverage(String amount, String category) {
    return 'You spend $amount a month on average on $category';
  }

  @override
  String get budgetCategory => 'Category';

  @override
  String get budgetChoose => 'Choose';

  @override
  String get budgetPeriod => 'Period';

  @override
  String get budgetEveryMonth => 'Every month';

  @override
  String get budgetNoCarry =>
      'What’s left doesn’t carry over to the next month.';

  @override
  String get budgetCreate => 'Create the budget';

  @override
  String get budgetSave => 'Save';

  @override
  String get budgetDelete => 'Delete the budget';

  @override
  String budgetDeleteTitle(String category) {
    return 'Delete the $category budget?';
  }

  @override
  String get budgetDeleteText => 'Operations don’t change.';

  @override
  String get budgetDeleteConfirm => 'Delete';

  @override
  String get budgetAlready => 'Already has a budget';

  @override
  String protectDeleteBudget(String name) {
    return 'To delete the $name budget';
  }

  @override
  String budgetDetailBudget(String amount) {
    return 'budget $amount';
  }

  @override
  String get budgetOver => 'Over';

  @override
  String get budgetNear => 'Nearly reached';

  @override
  String get budgetChart => 'Through the month';

  @override
  String get budgetChartTotal => 'Total';

  @override
  String get budgetChartPace => 'Pace';

  @override
  String budgetChartBudget(String amount) {
    return 'Budget $amount';
  }

  @override
  String get budgetLegendSpent => 'Spent';

  @override
  String get budgetLegendOver => 'Over budget';

  @override
  String get budgetLegendPace => 'Steady pace';

  @override
  String get budgetLegendFast => 'Too fast';

  @override
  String get budgetLegendSlow => 'Margin';

  @override
  String budgetAhead(String amount) {
    return '$amount ahead';
  }

  @override
  String budgetMargin(String amount) {
    return '$amount to spare';
  }

  @override
  String get budgetOps => 'This month’s operations';

  @override
  String budgetNoOps(String category) {
    return 'No expense in $category this month.';
  }

  @override
  String get budgetSeeInList => 'See in Operations';

  @override
  String get budgetEditAction => 'Edit';

  @override
  String confirmCategoryBudget(String amount) {
    return 'Its $amount monthly budget is deleted too.';
  }

  @override
  String get securityRecoveryUnverified => 'Not checked';

  @override
  String get rhythmDaily => 'Every day';

  @override
  String rhythmEveryDays(String n) {
    return 'Every $n days';
  }

  @override
  String rhythmWeekly(String days) {
    return 'Every $days';
  }

  @override
  String rhythmEveryOtherWeek(String days) {
    return '$days, every other week';
  }

  @override
  String rhythmEveryWeeks(String days, String n) {
    return '$days, every $n weeks';
  }

  @override
  String rhythmMonthly(String day) {
    return 'On the $day of every month';
  }

  @override
  String rhythmEveryMonths(String day, String n) {
    return 'On the $day, every $n months';
  }

  @override
  String rhythmYearly(String date) {
    return 'Every $date';
  }

  @override
  String rhythmEveryYears(String date, String n) {
    return 'On $date, every $n years';
  }

  @override
  String get rhythmEndNever => 'no end';

  @override
  String rhythmEndCount(String n) {
    return '$n times in all';
  }

  @override
  String rhythmEndDate(String date) {
    return 'until $date';
  }

  @override
  String get rhythmAnd => 'and';

  @override
  String rhythmThe(String day) {
    return '$day';
  }

  @override
  String get recurrenceNew => 'New recurrence';

  @override
  String get recurrenceEdit => 'Edit recurrence';

  @override
  String get repeatTitle => 'Repeat';

  @override
  String get repeatDay => 'Day';

  @override
  String get repeatWeek => 'Week';

  @override
  String get repeatMonth => 'Month';

  @override
  String get repeatYear => 'Year';

  @override
  String repeatEveryDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryYear(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Every $n years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String get repeatFirst => 'First time';

  @override
  String get repeatEnd => 'End';

  @override
  String get repeatEndNever => 'Never';

  @override
  String get repeatEndCount => 'After X times';

  @override
  String get repeatEndDate => 'On a date';

  @override
  String get repeatCount => 'Number of times';

  @override
  String get repeatLastDate => 'Last possible date';

  @override
  String get repeatEndNeverHelp => 'It goes on until you stop it.';

  @override
  String get repeatEndCountHelp =>
      'Handy for a loan or instalments: it stops by itself.';

  @override
  String get repeatEndDateHelp => 'No operation will be made after this date.';

  @override
  String repeatNext(String dates) {
    return 'Next dates: $dates';
  }

  @override
  String get repeatEach => 'Each time';

  @override
  String get repeatModeSave => 'Save';

  @override
  String get repeatModeDraft => 'Prepare a draft';

  @override
  String get repeatModeSaveHelp =>
      'The operation is added by itself on its date.';

  @override
  String get repeatModeDraftHelp =>
      'A draft waits for your approval, handy when the amount varies.';

  @override
  String get repeatNever => 'Never';

  @override
  String get repeatStop => 'Stop repeating';

  @override
  String get repeatLess => 'Less';

  @override
  String get repeatMore => 'More';

  @override
  String get repeatSave => 'Save';

  @override
  String get entryAmount => 'Amount';

  @override
  String get recurrencesTitle => 'Recurrences';

  @override
  String get recurrencesExpenses => 'Expenses';

  @override
  String get recurrencesIncome => 'Income';

  @override
  String get recurrencesTransfers => 'Transfers';

  @override
  String get recurrencesEmptyTitle => 'No recurrences yet';

  @override
  String get recurrencesEmptyHelp =>
      'Rent, salary, subscriptions: note them once, kibuo remembers.';

  @override
  String get recurrenceToValidate => 'To approve';

  @override
  String recurrenceNextOn(String date) {
    return 'on $date';
  }

  @override
  String get recurrenceTitle => 'Recurrence';

  @override
  String get recurrenceEditAction => 'Edit';

  @override
  String get recurrenceNextTimes => 'Next times';

  @override
  String get recurrencePast => 'Last times';

  @override
  String get recurrenceIgnored => 'Ignored';

  @override
  String get recurrenceDraft => 'Draft';

  @override
  String get recurrenceStop => 'Stop the recurrence';

  @override
  String recurrenceStopTitle(String name) {
    return 'Stop the $name recurrence?';
  }

  @override
  String get recurrenceStopText =>
      'What was already made stays; drafts waiting are deleted.';

  @override
  String get recurrenceStopAction => 'Stop';

  @override
  String recurrenceToAccount(String name) {
    return 'to $name';
  }

  @override
  String get recurrenceAskDraft => 'Prepare a draft';

  @override
  String get recurrenceSaveDirect => 'Save';

  @override
  String get recurrenceNone => 'No next time';

  @override
  String get homeAvailable => 'Available';

  @override
  String get homeAvailableHelp => 'free to spend';

  @override
  String get homeOpenAccounts => 'See my accounts';

  @override
  String get homeThisMonth => 'this month';

  @override
  String get homeLeft => 'left';

  @override
  String homeOutOfIn(String out, String income) {
    return '$out of $income';
  }

  @override
  String get operationsPlaceholder => 'This month’s transactions will be here.';

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
      'It may come from another phone, or the key that protects it is no longer on this one. The file is kept aside, not erased.';

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
      'kibuo will ask for this code each time it opens.';

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
  String get fingerprintOfferTitle => 'Open kibuo with your fingerprint?';

  @override
  String get fingerprintOfferBody =>
      'Faster than the code, which you can still use at any time.';

  @override
  String get fingerprintEnable => 'Turn on fingerprint';

  @override
  String get later => 'Not now';

  @override
  String get fingerprintReason => 'Open kibuo';

  @override
  String get forgotErase => 'Erase and start over';

  @override
  String get forgotEraseBody =>
      'All of kibuo’s data on this phone will be erased. You can then restore a backup, if you have one.';

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
      'Without a code, kibuo opens directly. Your data stays encrypted.';

  @override
  String get privacyHideRecents => 'Hide kibuo in recent apps';

  @override
  String get privacyScreenshots => 'Allow screenshots';

  @override
  String get privacyHelp =>
      'When hidden, the recent apps preview shows kibuo’s logo instead of your balances.';

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

  @override
  String get recoveryTitle => 'Recovery code';

  @override
  String get recoveryShowTitle => 'Write down your recovery code';

  @override
  String get recoveryShowBody =>
      'It gets you back into kibuo if you forget your code and the fingerprint doesn’t work, and it reopens your data on a new phone. Write it on paper and keep it somewhere safe.';

  @override
  String get recoveryShowWarning =>
      'kibuo doesn’t keep it, so it can’t show it to you again.';

  @override
  String get recoveryCopy => 'Copy the code';

  @override
  String get recoveryCopied => 'Code copied';

  @override
  String get recoveryNoted => 'I’ve written it down';

  @override
  String get recoveryProofBody => 'To check you wrote your code down.';

  @override
  String get recoveryProofWrong => 'That’s not this group. Look at your note.';

  @override
  String get recoverySeeAgain => 'See the code again';

  @override
  String get recoveryEnterTitle => 'Enter your recovery code';

  @override
  String get recoveryEnterBody =>
      'The 16-character code you were given, in 4 groups.';

  @override
  String get recoveryEnterHint => 'Dashes and lowercase don’t matter.';

  @override
  String get recoveryWrong => 'Wrong code. Check each group and try again.';

  @override
  String get recoveryOpen => 'Open kibuo';

  @override
  String get recoveryUse => 'Use the recovery code';

  @override
  String get recoveryNotKept => 'kibuo doesn’t keep it: only you know it.';

  @override
  String get recoveryNew => 'Get a new code';

  @override
  String get recoveryNewHelp => 'The old recovery code will stop working.';

  @override
  String get recoveryCreate => 'Create a recovery code';

  @override
  String get recoveryCreateHelp =>
      'Without a recovery code, a forgotten code or a new phone means starting over, and Android doesn’t copy kibuo’s data.';

  @override
  String get recoveryAndroidCopy => 'Let Android copy kibuo';

  @override
  String get recoveryAndroidCopyHelp =>
      'Google backup and transfer to a new phone. Copied data stays encrypted and only opens with this code.';

  @override
  String get unreadableRecover => 'Enter the recovery code';

  @override
  String recoveryProofTitle(int group) {
    return 'Type group $group again';
  }

  @override
  String recoveryNotedOn(String date) {
    return 'Written down on $date';
  }

  @override
  String securityRecoveryOn(String date) {
    return 'Written down $date';
  }

  @override
  String get currenciesTitle => 'Currencies';

  @override
  String get currenciesMain => 'Main currency';

  @override
  String get currenciesChange => 'Change';

  @override
  String get currenciesRates => 'Exchange rates';

  @override
  String get currenciesWorkedOut => 'Worked out from your other rates';

  @override
  String get currenciesNoRate => 'No rate yet';

  @override
  String get currenciesEdit => 'Edit';

  @override
  String get currenciesRatesHelp =>
      'Changing a rate doesn’t change transactions already recorded.';

  @override
  String get currenciesAdd => 'Add a currency';

  @override
  String get currencyPickerTitle => 'Choose a currency';

  @override
  String get mainCurrencyPickerTitle => 'Your main currency';

  @override
  String get mainCurrencyHelp =>
      'It’s used for tracking and reports. Each account keeps its own currency.';

  @override
  String get currencySearch => 'Search for a currency';

  @override
  String get currencyYours => 'Your currencies';

  @override
  String get currencyCommon => 'Most used';

  @override
  String get currencyOthers => 'All the others';

  @override
  String get rateKeepsOld => 'Transactions already recorded keep their rate.';

  @override
  String get rateSave => 'Save the rate';

  @override
  String get currenciesCents => 'Cents';

  @override
  String get currencyDecimalsHelp =>
      'When off, amounts are shown and typed without cents.';

  @override
  String currenciesUpdatedOn(String date) {
    return 'Updated $date';
  }

  @override
  String rateSheetTitle(String ofName) {
    return '$ofName rate';
  }

  @override
  String rateBefore(String rate, String date) {
    return 'Before: $rate · $date';
  }

  @override
  String get currencySearchHint => 'Name or code';

  @override
  String get rateUnchanged => 'Unchanged';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsAll => 'All';

  @override
  String get accountsTotal => 'Total of my accounts';

  @override
  String accountsTotalOf(String type) {
    return 'Total $type';
  }

  @override
  String get accountsAdd => 'Add an account';

  @override
  String accountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
    );
    return '$_temp0';
  }

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeMobile => 'Mobile money';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get accountNewTitle => 'New account';

  @override
  String get accountEditTitle => 'Edit account';

  @override
  String get accountTypeLabel => 'Type';

  @override
  String get accountTypeCreate => 'Create another type';

  @override
  String get accountName => 'Account name';

  @override
  String get accountNameHint => 'M-Pesa, my bank, pocket…';

  @override
  String get accountOpening => 'Starting balance';

  @override
  String accountCurrencyNote(String name, String code) {
    return '$name. Tap $code to change the currency.';
  }

  @override
  String get accountOpeningDate => 'Balance date';

  @override
  String get accountOpeningDateHelp =>
      'What the account held that day. Earlier transactions don’t change it.';

  @override
  String accountToday(String date) {
    return 'Today, $date';
  }

  @override
  String get accountCreate => 'Create the account';

  @override
  String get accountSave => 'Save';

  @override
  String get accountArchive => 'Archive the account';

  @override
  String get accountArchiveHelp =>
      'An archived account leaves lists and totals; its transactions stay.';

  @override
  String get keypadDone => 'Done';

  @override
  String get typeNewTitle => 'New type';

  @override
  String get typeName => 'Name';

  @override
  String get typeNameHint => 'Savings group, prepaid card…';

  @override
  String get typeIcon => 'Icon';

  @override
  String get typeSave => 'Save';

  @override
  String get accountsDisplay => 'Account display';

  @override
  String get accountsDisplayAmounts => 'Amounts';

  @override
  String get accountsDisplayEach => 'Each account’s currency';

  @override
  String get accountsDisplayEachHelp => 'Each account stays in its currency';

  @override
  String accountsDisplayAll(String name, String code) {
    return 'All in $name ($code)';
  }

  @override
  String get accountsDisplayAllHelp => 'Converted at the latest rate';

  @override
  String get accountsDisplayNote =>
      'Shown only when your accounts use several currencies.';

  @override
  String get accountsNoRate => 'No rate';

  @override
  String accountsNoRateNote(String codes) {
    return 'Without a rate, $codes is left out of the total.';
  }

  @override
  String get accountsAddRate => 'Add a rate';

  @override
  String get currencyKeptMain => 'Your main currency';

  @override
  String currencyKeptAccount(String name) {
    return 'Used by the account $name';
  }

  @override
  String get currencyOther => 'Other currency…';

  @override
  String get currencyRemoveShort => 'Remove';

  @override
  String get currencyKept => 'Kept';

  @override
  String get currencyKeep => 'Keep';

  @override
  String categoryName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'food': 'Food',
      'restaurant': 'Restaurant',
      'market': 'Market',
      'transport': 'Transport',
      'taxi': 'Taxi',
      'motoTaxi': 'Motorbike taxi',
      'bus': 'Bus',
      'fuel': 'Fuel',
      'toll': 'Toll',
      'groceries': 'Groceries',
      'housing': 'Housing',
      'rent': 'Rent',
      'electricity': 'Electricity',
      'water': 'Water',
      'communication': 'Phone and internet',
      'airtime': 'Airtime',
      'internet': 'Internet',
      'health': 'Health',
      'pharmacy': 'Pharmacy',
      'school': 'School',
      'family': 'Family',
      'outings': 'Going out',
      'contributions': 'Contributions',
      'otherExpense': 'Other',
      'salary': 'Salary',
      'business': 'Business',
      'sale': 'Sales',
      'service': 'Services',
      'giftReceived': 'Gift received',
      'refund': 'Refund',
      'otherIncome': 'Other',
      'adjustExpense': 'Adjustment',
      'adjustIncome': 'Adjustment',
      'debtIn': 'Debt',
      'debtOut': 'Debt',
      'receivableIn': 'Money owed',
      'receivableOut': 'Money owed',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesExpenses => 'Expenses';

  @override
  String get categoriesIncome => 'Income';

  @override
  String categoriesSubCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count subcategories',
      one: '1 subcategory',
    );
    return '$_temp0';
  }

  @override
  String get categoriesAddSub => 'Add a subcategory';

  @override
  String get categoriesAdd => 'Add a category';

  @override
  String get categoryNewTitle => 'New category';

  @override
  String get categoryNewSubTitle => 'New subcategory';

  @override
  String get categoryEditTitle => 'Edit category';

  @override
  String get categoryEditSubTitle => 'Edit subcategory';

  @override
  String get categoryIn => 'In';

  @override
  String get categoryNameLabel => 'Name';

  @override
  String get categoryIcon => 'Icon';

  @override
  String get categoryColor => 'Colour';

  @override
  String categoryColorName(String color) {
    String _temp0 = intl.Intl.selectLogic(color, {
      'peach': 'Peach',
      'apricot': 'Apricot',
      'sand': 'Sand',
      'coral': 'Coral',
      'rose': 'Rose',
      'lavender': 'Lavender',
      'blue': 'Blue',
      'sky': 'Sky',
      'mint': 'Mint',
      'green': 'Green',
      'other': 'Grey',
    });
    return '$_temp0';
  }

  @override
  String get categoryCreate => 'Create the category';

  @override
  String get categoryCreateSub => 'Create the subcategory';

  @override
  String get categorySave => 'Save';

  @override
  String get categoryRemove => 'Remove the category';

  @override
  String get categoryRemoveSub => 'Remove the subcategory';

  @override
  String get categoryRemoveHelp =>
      'It leaves the choices; its transactions keep it.';

  @override
  String categoryRemoveSubsToo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Its $count subcategories go with it.',
      one: 'Its subcategory goes with it.',
    );
    return '$_temp0';
  }

  @override
  String get categoryNameHint => 'Church, Motorbike taxi…';

  @override
  String get currencyKeptTransaction => 'Used by a transaction';

  @override
  String get entryNewExpense => 'New expense';

  @override
  String get entryNewIncome => 'New income';

  @override
  String get entryEditExpense => 'Edit expense';

  @override
  String get entryEditIncome => 'Edit income';

  @override
  String get entryExpense => 'Expense';

  @override
  String get entryIncome => 'Income';

  @override
  String get entryTakenFrom => 'Taken from the account';

  @override
  String get entryAddedTo => 'Added to the account';

  @override
  String get entryAccount => 'Account';

  @override
  String get entryCategory => 'Category';

  @override
  String get entryDate => 'Date';

  @override
  String get entryFees => 'Fees';

  @override
  String get entryNone => 'None';

  @override
  String get entryChoose => 'Choose';

  @override
  String get entryNote => 'Note';

  @override
  String get entryNoteHint => 'Add a note';

  @override
  String get entryToday => 'Today';

  @override
  String get entryYesterday => 'Yesterday';

  @override
  String get entrySave => 'Save';

  @override
  String get entrySaveChanges => 'Save the changes';

  @override
  String get entryPaidCurrency => 'Currency paid';

  @override
  String get entryReceivedCurrency => 'Currency received';

  @override
  String entryCurrencyHelp(String account, String currency) {
    return 'The account $account is in $currency.';
  }

  @override
  String get entryAccountCurrency => 'The account’s currency, no conversion';

  @override
  String get entryConverted => 'Converted at the chosen rate';

  @override
  String get entryRateTitle => 'Exchange rate';

  @override
  String get entryPaid => 'Paid';

  @override
  String get entryReceived => 'Received';

  @override
  String get entryRateToday => 'Today’s rate';

  @override
  String get entryRateTodayHelp => 'Your current rate, in Currencies';

  @override
  String get entryRateTodayMissing => 'No rate in Currencies yet';

  @override
  String get entryRateOther => 'Another rate';

  @override
  String get entryRateOtherHelp => 'Type the changer’s rate';

  @override
  String entryRateFor(String symbol) {
    return 'Rate for 1 $symbol';
  }

  @override
  String get entryRateTodayTag => 'Today';

  @override
  String get entryRateTypedTag => 'Custom';

  @override
  String get entrySo => 'That is';

  @override
  String get entryFeesTitle => 'Extra fees';

  @override
  String get entrySavedExpense => 'Expense saved';

  @override
  String get entrySavedIncome => 'Income saved';

  @override
  String get entryUndoEdit => 'Undo and edit';

  @override
  String get entryClosesSoon => 'Closes by itself in a moment';

  @override
  String entryRateFrozen(String symbol) {
    return 'Rate frozen for 1 $symbol';
  }

  @override
  String get entryDuplicate => 'Duplicate';

  @override
  String entryPaidChip(String amount, String rate) {
    return '$amount paid · $rate';
  }

  @override
  String entryReceivedChip(String amount, String rate) {
    return '$amount received · $rate';
  }

  @override
  String get entryReadNote => 'Read the whole note';

  @override
  String get entryNoAccount => 'Add an account first.';

  @override
  String get categorySearch => 'Search for a category';

  @override
  String get operationsTitle => 'Transactions';

  @override
  String get operationsEmpty => 'No transactions yet. The + adds one.';

  @override
  String get entryFirstAccountTitle => 'First, an account';

  @override
  String get entryFirstAccountExpense =>
      'Every expense leaves an account, and every income lands in one: your pocket, your mobile money, your bank. Create the first one, then note your expense.';

  @override
  String get entryFirstAccountIncome =>
      'Every expense leaves an account, and every income lands in one: your pocket, your mobile money, your bank. Create the first one, then note your income.';

  @override
  String get entryFirstAccountAction => 'Create my first account';

  @override
  String get entryFirstCategoryTitle => 'First, a category';

  @override
  String get entryFirstCategoryExpense =>
      'Every expense goes in a category: food, transport, rent… Create one, then note your expense.';

  @override
  String get entryFirstCategoryIncome =>
      'Every income goes in a category: salary, sales… Create one, then note your income.';

  @override
  String get entryFirstCategoryAction => 'Create a category';

  @override
  String get entryLater => 'Later';

  @override
  String get entryDeleteOperation => 'Delete operation';

  @override
  String get entryDeleteExpenseTitle => 'Delete this expense?';

  @override
  String get entryDeleteIncomeTitle => 'Delete this income?';

  @override
  String entryDeleteExpenseHelp(String account, String amount) {
    return 'It leaves the list and $account gets $amount back.';
  }

  @override
  String entryDeleteIncomeHelp(String account, String amount) {
    return 'It leaves the list and $account loses $amount.';
  }

  @override
  String get entryDeleteConfirm => 'Delete';

  @override
  String get attachTitle => 'Attachments';

  @override
  String get attachAdd => 'Add';

  @override
  String get attachEmpty => 'Add an attachment';

  @override
  String get attachEmptyHelp => 'Photo of a receipt or a document, 5 at most';

  @override
  String get attachPhoto => 'Take a photo';

  @override
  String get attachGallery => 'Choose from the gallery';

  @override
  String get attachFile => 'Choose a file';

  @override
  String get attachKindPhoto => 'Photo';

  @override
  String get attachKindPdf => 'PDF';

  @override
  String get attachKindFile => 'File';

  @override
  String get attachTooBig => 'This file is over 10 MB: choose a lighter one.';

  @override
  String attachChosen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chosen',
      one: '1 chosen',
    );
    return '$_temp0';
  }

  @override
  String get attachRemove => 'Remove';

  @override
  String get attachView => 'View';

  @override
  String get attachOpenWith => 'Open with…';

  @override
  String attachPage(int pages) {
    return 'Page 1 of $pages';
  }

  @override
  String get attachNoApp => 'No app on this phone opens this file.';

  @override
  String attachPhotoName(int n) {
    return 'Photo $n';
  }

  @override
  String get entryTransfer => 'Transfer';

  @override
  String get entryNewTransfer => 'New transfer';

  @override
  String get entryEditTransfer => 'Edit transfer';

  @override
  String get transferFrom => 'From';

  @override
  String get transferTo => 'To';

  @override
  String get transferToQuestion => 'To which account?';

  @override
  String get transferSent => 'Sent';

  @override
  String transferArrives(String account) {
    return 'Arrives in $account';
  }

  @override
  String transferTakenFrom(String account) {
    return 'Taken from $account';
  }

  @override
  String get transferSaved => 'Transfer saved';

  @override
  String transferSavedSub(String from, String to, String when) {
    return '$from to $to · $when';
  }

  @override
  String get transferAnother => 'New transfer';

  @override
  String get transferKind => 'Transfer';

  @override
  String get transferDepuis => 'From';

  @override
  String transferArrivedChip(String amount, String rate) {
    return '$amount arrived · $rate';
  }

  @override
  String get transferFirstAccountText =>
      'A transfer moves money between two of your accounts: your pocket, your mobile money, your bank. Create the first one, then a second.';

  @override
  String get transferSecondTitle => 'First, a second account';

  @override
  String get transferSecondText =>
      'A transfer moves money between two of your accounts. Create a second one, then note your transfer.';

  @override
  String get transferSecondAction => 'Create an account';

  @override
  String get entryDeleteTransferTitle => 'Delete this transfer?';

  @override
  String entryDeleteTransferHelp(
    String from,
    String withdrawn,
    String to,
    String arrived,
  ) {
    return 'It leaves the list: $from gets $withdrawn back and $to loses $arrived.';
  }

  @override
  String get overdraftLabel => 'Overdraft';

  @override
  String get overdraftAllow => 'Allow overdraft';

  @override
  String get overdraftAllowHelp => 'The balance can go below zero';

  @override
  String get overdraftUpTo => 'Up to';

  @override
  String get overdraftNoLimitHelp => 'Empty or 0: no limit.';

  @override
  String get overdraftNoLimit => 'No limit';

  @override
  String overdraftBelowZero(String account, String balance) {
    return '$account is at $balance: nothing can leave it until it comes back up. Money can still come in.';
  }

  @override
  String overdraftCaptionUpTo(String amount) {
    return 'Overdraft up to $amount';
  }

  @override
  String get overdraftCaptionNoLimit => 'Unlimited overdraft';

  @override
  String overdraftAvailable(String amount, String account) {
    return '$amount available in $account';
  }

  @override
  String get overdraftAuthorize => 'Allow';

  @override
  String overdraftWouldGo(String account, String amount) {
    return '$account would go to $amount';
  }

  @override
  String get accountCurrentBalance => 'Current balance';

  @override
  String accountCurrentHelp(String balance) {
    return 'In kibuo today: $balance. Type what the account really holds.';
  }

  @override
  String adjustTitle(String account) {
    return 'Correct $account’s balance?';
  }

  @override
  String get adjustInKibuo => 'In kibuo';

  @override
  String get adjustReal => 'Real balance';

  @override
  String get adjustHelp =>
      'The difference is added as a transaction, which you can change later.';

  @override
  String adjustNote(String before, String after) {
    return 'Balance corrected: $before → $after';
  }

  @override
  String get adjustAdd => 'Add the adjustment';

  @override
  String get lockProtect => 'Code for important actions';

  @override
  String get lockProtectHelp => 'Delete, archive, correct a balance';

  @override
  String get protectTitle => 'Confirm with your code';

  @override
  String protectArchive(String name) {
    return 'To archive $name';
  }

  @override
  String get protectDeleteOperation => 'To delete the transaction';

  @override
  String protectDeleteCategory(String name) {
    return 'To delete $name';
  }

  @override
  String protectRemoveCurrencies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count currencies',
      one: 'a currency',
    );
    return 'To remove $_temp0';
  }

  @override
  String protectAdjust(String name) {
    return 'To correct $name’s balance';
  }

  @override
  String protectOverdraft(String name) {
    return 'To change $name’s overdraft';
  }

  @override
  String confirmArchiveTitle(String name) {
    return 'Archive $name?';
  }

  @override
  String confirmArchiveHelp(String name) {
    return '$name leaves lists and totals. Its transactions stay.';
  }

  @override
  String get confirmArchiveAction => 'Archive the account';

  @override
  String confirmCategoryTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String confirmCategoryHelp(String name, int subs) {
    String _temp0 = intl.Intl.pluralLogic(
      subs,
      locale: localeName,
      other:
          '$name and its $subs subcategories leave the choices. Transactions already noted keep them.',
      one:
          '$name and its subcategory leave the choices. Transactions already noted keep them.',
      zero: '$name leaves the choices. Transactions already noted keep it.',
    );
    return '$_temp0';
  }

  @override
  String get confirmCategoryAction => 'Delete the category';

  @override
  String confirmCurrenciesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Remove $count currencies?',
      one: 'Remove a currency?',
    );
    return '$_temp0';
  }

  @override
  String confirmCurrenciesHelp(String names, int count) {
    return '$names will no longer be offered.';
  }

  @override
  String get confirmCurrenciesAction => 'Remove';

  @override
  String get accountMinusHint => 'Hold « . » for a negative balance.';

  @override
  String get addRedo => 'Do again';

  @override
  String get plusHoldTip =>
      'Tip: hold + then slide to a choice, without lifting your finger.';

  @override
  String get plusHoldTipDone => 'Got it';

  @override
  String get listEntries => 'In';

  @override
  String get listExits => 'Out';

  @override
  String listSpent(int percent) {
    return '$percent % spent';
  }

  @override
  String get listRest => 'Left';

  @override
  String get listThisMonth => 'This month';

  @override
  String get filterType => 'Type';

  @override
  String get filterAccount => 'Account';

  @override
  String get filterCategory => 'Category';

  @override
  String get filterAll => 'All';

  @override
  String filterTypes(int count) {
    return '$count types';
  }

  @override
  String filterAccounts(int count) {
    return '$count accounts';
  }

  @override
  String filterCategories(int count) {
    return '$count categories';
  }

  @override
  String get emptyMonthTitle => 'No transactions';

  @override
  String emptyMonthHelp(String month) {
    return 'Expenses, income and transfers of $month will show here.';
  }

  @override
  String get emptyFilterTitle => 'Nothing with these filters';

  @override
  String get emptyFilterHelp => 'Try other choices, or clear the filters.';

  @override
  String get clearFilters => 'Clear the filters';

  @override
  String get backToThisMonth => 'Back to this month';

  @override
  String get swipeTipTitle => 'Change month with a swipe';

  @override
  String get swipeTipText =>
      'Swipe the list right for the month before, left for the month after. Or tap the month’s title.';

  @override
  String get filterAllType => 'All';

  @override
  String get filterAllCategories => 'All';

  @override
  String get filterExpenses => 'Expenses';

  @override
  String get filterIncomes => 'Income';

  @override
  String get filterTransfers => 'Transfers';

  @override
  String filterMore(int count) {
    return 'Show $count more';
  }

  @override
  String get listNoEntries => 'No income';

  @override
  String get listSearch => 'Search';

  @override
  String get searchHint => 'Name, category, account, amount';

  @override
  String get searchClose => 'Close search';

  @override
  String get searchClear => 'Clear the search';

  @override
  String get searchRecent => 'Recent searches';

  @override
  String get searchRecentClear => 'Clear';

  @override
  String get searchBy => 'Search by';

  @override
  String get searchHelp =>
      'Search covers every month: name, category, account, note and amount.';

  @override
  String searchResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
    );
    return '$_temp0';
  }

  @override
  String searchOthers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more results',
      one: '1 more result',
    );
    return '$_temp0';
  }

  @override
  String get searchEarlierMonths => 'In earlier months';

  @override
  String get searchOtherMonths => 'In other months';

  @override
  String searchEarlierFold(int count) {
    return 'Earlier months · $count';
  }

  @override
  String searchOtherFold(int count) {
    return 'Other months · $count';
  }

  @override
  String get searchFold => 'Fold';

  @override
  String searchNothingInMonth(String month, String query) {
    return 'Nothing in $month for “$query”.';
  }

  @override
  String searchNoResultTitle(String query) {
    return 'No result for “$query”';
  }

  @override
  String get searchNoResultHelp =>
      'Check the spelling or search for an amount.';

  @override
  String get firstWelcome => 'Welcome to kibuo';

  @override
  String get firstWelcomeText =>
      'Your accounts, debts and projects in one place. Your data stays on your phone.';

  @override
  String get firstLanguage => 'Choose your language';

  @override
  String get firstContinue => 'Continue';

  @override
  String firstStep(int step, int count) {
    return 'Step $step of $count';
  }

  @override
  String get firstCurrencyTitle => 'Your main currency';

  @override
  String get firstCurrencyText =>
      'It is used for tracking and reports. Each account keeps its own currency.';

  @override
  String get firstCurrencySearch => 'Search for a currency';

  @override
  String get firstCurrencySearchHint => 'Name or code';

  @override
  String get firstAccountTitle => 'Your first account';

  @override
  String get firstAccountText =>
      'Start with the one you use most. You can add others later.';

  @override
  String get firstProtectTitle => 'Protect your data';

  @override
  String get firstProtectText =>
      'Your data stays on this phone. Without a backup, it is lost if you lose the phone.';

  @override
  String get firstBackupTitle => 'Automatic backups';

  @override
  String get firstBackupHelp => 'Every week, in the folder of your choice.';

  @override
  String get firstLockTitle => 'Lock the app';

  @override
  String get firstLockHelp =>
      'PIN or fingerprint. You will be given a recovery code.';

  @override
  String get firstLater =>
      'You can change these choices at any time in the settings.';

  @override
  String get firstStart => 'Start';

  @override
  String get draftLabel => 'Draft';

  @override
  String get draftIgnore => 'Ignore';

  @override
  String get draftValidate => 'Confirm';

  @override
  String get plannedTag => 'Planned';

  @override
  String draftValidated(String name) {
    return 'Confirmed: $name, counted in the month';
  }

  @override
  String draftIgnoredToast(String name) {
    return 'Ignored: $name. Confirm it from its details.';
  }

  @override
  String draftsToValidate(String count) {
    return 'To confirm · $count';
  }

  @override
  String draftFromRecurrence(String account) {
    return 'Recurrence · $account';
  }

  @override
  String draftStatus(String status, String unit) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'ignored': 'Ignored',
      'other': 'Draft',
    });
    String _temp1 = intl.Intl.selectLogic(unit, {
      'day': 'daily',
      'week': 'weekly',
      'year': 'yearly',
      'other': 'monthly',
    });
    return '$_temp0 · $_temp1 recurrence';
  }

  @override
  String draftDueToday(String date) {
    return 'Due today, $date';
  }

  @override
  String draftDueYesterday(String date) {
    return 'Due yesterday, $date';
  }

  @override
  String draftDueOn(String date) {
    return 'Due on $date';
  }

  @override
  String get draftNotice =>
      'This operation is waiting for your go-ahead. Check the amount, it sometimes changes, then confirm to add it to the account.';

  @override
  String get ignoredNotice =>
      'You ignored it this time: it doesn’t count in the account. If it did happen, confirm it here.';

  @override
  String get draftValidateAction => 'Confirm the operation';

  @override
  String get draftChangeAmount => 'Change the amount';

  @override
  String get draftIgnoreOnce => 'Ignore this time';

  @override
  String draftNoRate(String currency) {
    return 'The $currency rate is missing: give it with “Change the amount”.';
  }

  @override
  String get listDisplay => 'List display';

  @override
  String get displayWhenDue => 'When a recurrence reaches its date';

  @override
  String get displayAuto => 'Confirm automatically';

  @override
  String get displayAutoHelp => 'Made and counted on its date.';

  @override
  String get displayAsk => 'Always ask';

  @override
  String get displayAskHelp => 'Arrives as a draft, to confirm.';

  @override
  String get displayDrafts => 'Drafts to confirm';

  @override
  String get displayAtDate => 'On their date';

  @override
  String get displayAtDateHelp => 'On their day, in the list.';

  @override
  String get displayOnTop => 'Grouped at the top';

  @override
  String get displayOnTopHelp => 'Late and today’s, at the top.';

  @override
  String get displayPlanned => 'Planned operations this month';

  @override
  String get displayPlannedHelp => 'Dashed, marked “Planned”.';

  @override
  String get displayHidden => 'Hidden';

  @override
  String get displayHiddenHelp => 'Shown once their date comes.';

  @override
  String get displayFoot =>
      'Also in Settings. A recurrence can always ask for confirmation.';

  @override
  String get displayDone => 'Done';

  @override
  String get settingsRecurrences => 'Recurrences and drafts';

  @override
  String get displayAutoLong =>
      'The operation is made and counted, except for recurrences that ask for confirmation.';

  @override
  String get displayAskLong =>
      'Each operation arrives as a draft and waits for your go-ahead.';

  @override
  String get displayAtDateLong => 'Each draft stays on its day.';

  @override
  String get displayOnTopLong =>
      'Late ones and today’s are gathered at the top of the list.';

  @override
  String get displayPlannedLong =>
      'They stay on their day, dashed, marked “Planned”.';

  @override
  String get displayHiddenLong => 'They only show once their date comes.';

  @override
  String get settingsRecurrencesFoot =>
      'These choices are also in the operations list display. Each recurrence can ask for its own confirmation, in its card.';

  @override
  String get displayAutoShort => 'Automatic';

  @override
  String get draftsLateAndToday => 'Late and today';

  @override
  String get todoTitle => 'To do';

  @override
  String todoSeeAll(String count) {
    return 'See all · $count';
  }

  @override
  String todoListHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things',
      one: '1 thing',
    );
    return '$_temp0, most urgent first';
  }

  @override
  String get todoUrgent => 'Urgent';

  @override
  String get todoWeek => 'This week';

  @override
  String get todoReminders => 'Reminders';

  @override
  String get todoBudgetOverSub => 'Budget exceeded';

  @override
  String todoBudgetNearSub(String amount) {
    return 'Budget · $amount left';
  }

  @override
  String get todoSee => 'See';

  @override
  String todoDrafts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts',
      one: '1 draft',
    );
    return '$_temp0';
  }

  @override
  String get todoValidate => 'Confirm';

  @override
  String get todoRecovery => 'Recovery code';

  @override
  String get todoRecoverySub => 'Not checked';

  @override
  String get todoRecoveryAction => 'Check';

  @override
  String todoRate(String currency) {
    return '$currency rate';
  }

  @override
  String todoRateSub(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get todoRateAction => 'Edit';

  @override
  String get todoLater => 'Later';

  @override
  String todoPutOff(String name) {
    return 'Put off until tomorrow: $name';
  }

  @override
  String get toastUndo => 'Undo';

  @override
  String get upcomingTitle => 'Coming up';

  @override
  String get upcomingSeeAll => 'See all';

  @override
  String draftsSheetTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts to confirm',
      one: 'Confirm this draft?',
    );
    return '$_temp0';
  }

  @override
  String get draftsSheetHelp =>
      'Touch a draft to change it or confirm it alone.';

  @override
  String draftsSheetValidate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Confirm the $count',
      one: 'Confirm the draft',
      zero: 'Nothing to confirm',
    );
    return '$_temp0';
  }

  @override
  String get draftsSheetValidateOne => 'Confirm';

  @override
  String get draftsSheetLater => 'Later';

  @override
  String get draftsSheetNoRate => 'Rate missing: confirm it alone';

  @override
  String get draftsSheetFloor => 'Would go below the floor: confirm it alone';

  @override
  String draftsSheetLine(String kind, String day, String account) {
    return '$kind · $day · $account';
  }

  @override
  String draftsValidated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts confirmed',
      one: '1 draft confirmed',
    );
    return '$_temp0';
  }

  @override
  String get typesTitle => 'Account types';

  @override
  String get typesProvided => 'Provided by kibuo';

  @override
  String get typesYours => 'Yours';

  @override
  String get typesProvidedHelp => 'Provided types can’t be changed.';

  @override
  String get typeEditTitle => 'Edit the type';

  @override
  String get typeDelete => 'Delete this type';

  @override
  String typeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts are of this type: change them first.',
      one: '1 account is of this type: change it first.',
    );
    return '$_temp0';
  }

  @override
  String typeDeleteTitle(String name) {
    return 'Delete the type $name?';
  }

  @override
  String get typeDeleteText =>
      'It leaves the list of types; no account uses it.';

  @override
  String get typeDeleteAction => 'Delete';

  @override
  String get typesManage => 'Manage';

  @override
  String get remindersTitle => 'Reminders and alerts';

  @override
  String get remindersEntryGroup => 'Entries';

  @override
  String get remindersEntry => 'Note my operations';

  @override
  String remindersEntryHelp(String time) {
    return 'Every day at $time';
  }

  @override
  String get remindersEntryOffHelp =>
      'An evening reminder, if nothing was noted';

  @override
  String get remindersTime => 'Time';

  @override
  String get remindersBlocked => 'Notifications blocked';

  @override
  String get remindersOpenSettings => 'Open the phone’s settings';

  @override
  String get remindersTimeTitle => 'Reminder time';

  @override
  String get remindersTimeSave => 'Save';

  @override
  String get reminderEntryTitle => 'Note my operations';

  @override
  String get reminderEntryBody => 'Nothing noted today. An expense, an income?';

  @override
  String reminderDueSoon(String amount, int days, String account) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$amount in $_temp0, $account';
  }

  @override
  String reminderDueShort(int days, String missing, String account) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'In $_temp0: $missing short on $account';
  }

  @override
  String reminderDueToday(String amount, String account) {
    return '$amount today, $account';
  }

  @override
  String reminderDueTodayShort(String missing, String account) {
    return 'Today: $missing short on $account';
  }

  @override
  String get remindersDueGroup => 'Due dates';

  @override
  String get remindersDue => 'Remind before a due date';

  @override
  String remindersDueHelp(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before each due date',
      one: '1 day before each due date',
      zero: 'On each due date',
    );
    return '$_temp0';
  }

  @override
  String get remindersDueOffHelp => 'No reminder before due dates';

  @override
  String get remindersDelay => 'Notice';

  @override
  String daysBefore(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days before',
      one: '1 day before',
      zero: 'On the day',
    );
    return '$_temp0';
  }

  @override
  String get remindersRuleNote =>
      'Each recurrence can have its own reminder, set in its card.';

  @override
  String get reminderRule => 'Reminder';

  @override
  String reminderRuleDefault(String when) {
    return 'Default ($when)';
  }

  @override
  String get reminderRuleNone => 'None';

  @override
  String get reminderRuleOff => 'None (reminders off)';

  @override
  String todoShortfall(String name, String date) {
    return '$name · on $date';
  }

  @override
  String todoShortfallSub(String missing, String account) {
    return '$missing short on $account';
  }

  @override
  String entryPlannedToast(String date) {
    return 'Planned for $date: it will arrive that day.';
  }

  @override
  String plannedStatus(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'income': 'Planned income',
      'transfer': 'Planned transfer',
      'other': 'Planned expense',
    });
    return '$_temp0';
  }

  @override
  String plannedOn(String date) {
    return 'Planned for $date';
  }

  @override
  String get plannedNotice =>
      'It doesn’t count yet. On its day, it arrives like the others: counted, or as a draft to confirm.';

  @override
  String get plannedCancel => 'Cancel the planned operation';

  @override
  String get plannedCancelTitle => 'Cancel the planned operation?';

  @override
  String get plannedCancelText =>
      'It leaves the planned operations; nothing was counted yet.';

  @override
  String get plannedCancelAction => 'Cancel the operation';

  @override
  String plannedCancelled(String name) {
    return 'Planned operation cancelled: $name';
  }

  @override
  String budgetAlertNear(String name, String percent, String left) {
    return '$name at $percent% of its budget · $left left';
  }

  @override
  String budgetAlertFull(String name) {
    return '$name at 100% of its budget';
  }

  @override
  String budgetAlertOver(String name, String over) {
    return '$name over by $over';
  }

  @override
  String get budgetAlertSee => 'See';

  @override
  String get remindersBudgetGroup => 'Budgets';

  @override
  String get remindersAt80 => 'At 80% of the budget';

  @override
  String get remindersAt100 => 'At 100% of the budget';

  @override
  String get remindersBudgetHelp => 'One alert per category';

  @override
  String get debtsTitle => 'Debts and money owed';

  @override
  String get debtsOwe => 'I owe';

  @override
  String get debtsOwed => 'Owed to me';

  @override
  String debtsLateCount(int count) {
    return '$count overdue';
  }

  @override
  String get debtsLateGroup => 'Overdue';

  @override
  String get debtsNoDue => 'No due date';

  @override
  String debtsAbout(String amount) {
    return '~$amount';
  }

  @override
  String debtWordLate(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String get debtWordToday => 'Today';

  @override
  String get debtWordTomorrow => 'Tomorrow';

  @override
  String get debtWordAfterTomorrow => 'In 2 days';

  @override
  String debtWordIn(int days) {
    return 'In $days days';
  }

  @override
  String debtWordSettled(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Settled $days days ago',
      one: 'Settled yesterday',
      zero: 'Settled today',
    );
    return '$_temp0';
  }

  @override
  String debtWordReceived(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Received $days days ago',
      one: 'Received yesterday',
      zero: 'Received today',
    );
    return '$_temp0';
  }

  @override
  String debtDueLine(String date) {
    return 'Due: $date';
  }

  @override
  String debtDueTodayLine(String date) {
    return 'Due: today, $date';
  }

  @override
  String debtDueLateLine(String date) {
    return 'Was due: $date';
  }

  @override
  String get debtNoDueLine => 'No date set';

  @override
  String get debtNothingRepaid => 'Nothing paid back yet.';

  @override
  String get debtNothingReceived => 'Nothing received yet.';

  @override
  String debtRepaidLine(String paid, String total) {
    return '$paid already paid back of $total.';
  }

  @override
  String debtReceivedLine(String paid, String total) {
    return '$paid already received of $total.';
  }

  @override
  String debtAboutLine(String amount) {
    return 'About $amount at today’s rate.';
  }

  @override
  String debtSettledOwe(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settled debts',
      one: '1 settled debt',
    );
    return '$_temp0';
  }

  @override
  String debtSettledOwed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paid back to me',
      one: '1 paid back to me',
    );
    return '$_temp0';
  }

  @override
  String get debtsEmptyOwe => 'No debts';

  @override
  String get debtsEmptyOweHelp =>
      'Note what you owe, with or without a due date.';

  @override
  String get debtsEmptyOwed => 'Nobody owes you anything';

  @override
  String get debtsEmptyOwedHelp =>
      'Note the money you lend, to know who has to pay back.';

  @override
  String get debtsGroupBy => 'Sort by';

  @override
  String get debtsByDue => 'Due date';

  @override
  String get debtsByDueHelp => 'The closest first, overdue ones on top.';

  @override
  String get debtsByPerson => 'Person';

  @override
  String get debtsByPersonHelp => 'One group per name, in alphabetical order.';

  @override
  String get debtsPaidTitle => 'Settled debts and money owed';

  @override
  String get debtsPaidInline => 'In their month';

  @override
  String get debtsPaidInlineHelp =>
      'With the others, at their date. Without a date: in “No due date”.';

  @override
  String get debtsPaidBottom => 'Grouped at the bottom';

  @override
  String get debtsPaidBottomHelp => 'A separate “settled” block that unfolds.';

  @override
  String get debtsPaidHidden => 'Hidden';

  @override
  String get debtsPaidHiddenHelp => 'Not in the list.';

  @override
  String get debtPersonOwe => 'Who I owe';

  @override
  String get debtPersonOwed => 'Who owes me';

  @override
  String get debtPersonHint => 'A name';

  @override
  String get debtLeft => 'Still owed';

  @override
  String get debtDue => 'Due date';

  @override
  String get debtDueClear => 'Remove the due date';

  @override
  String get debtLinkOwe => 'Money received in an account';

  @override
  String get debtLinkOwed => 'Money paid from an account';

  @override
  String debtLinkHelp(String account) {
    return '$account, its balance will change';
  }

  @override
  String get debtLinkOffHelp => 'An old one: only what is left is noted';

  @override
  String get debtSavedOwe => 'Debt saved';

  @override
  String get debtSavedOwed => 'Money owed saved';

  @override
  String get debtCurrency => 'Currency of the debt';

  @override
  String get debtNewOwe => 'New debt';

  @override
  String get debtNewOwed => 'New money owed';

  @override
  String get debtNoAccount => 'No account';

  @override
  String get debtsOpenTitle => 'Opening a line';

  @override
  String get debtsDetailsAbove => 'Details above';

  @override
  String get debtsDetailsAboveHelp =>
      'The line moves down, the details come from the top.';

  @override
  String get debtsDetailsBelow => 'Details below';

  @override
  String get debtsDetailsBelowHelp =>
      'The line stays, the details unfold below it.';

  @override
  String debtsCoachStep(int step) {
    return '$step of 2';
  }

  @override
  String get debtsCoach1Title => 'One line, one person';

  @override
  String get debtsCoach1Text =>
      'Red means the due date has passed. The square around the day fills as money is paid back.';

  @override
  String get debtsCoach2Title => 'Touch for details';

  @override
  String get debtsCoach2Text =>
      'The full date and what is already paid back show on touch. Where they appear is chosen in Display.';

  @override
  String get debtsCoachSkip => 'Skip';

  @override
  String get debtsCoachNext => 'Next';

  @override
  String get debtsCoachTry => 'Try it';

  @override
  String get debtLeftOwe => 'I still owe';

  @override
  String get debtLeftOwed => 'Still owed to me';

  @override
  String debtRepaidOf(String paid, String total) {
    return '$paid paid back of $total';
  }

  @override
  String debtReceivedOf(String paid, String total) {
    return '$paid received of $total';
  }

  @override
  String get debtRepayments => 'Repayments';

  @override
  String debtRepaymentsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: 'once',
    );
    return '$_temp0';
  }

  @override
  String get debtNoRepayment => 'No repayment yet.';

  @override
  String get debtRepay => 'Pay back';

  @override
  String get debtCollect => 'Collect';

  @override
  String get debtDetails => 'Details';

  @override
  String get debtEditAction => 'Edit';

  @override
  String debtRepayTitle(String name) {
    return 'Pay back $name';
  }

  @override
  String debtCollectTitle(String name) {
    return 'Collect from $name';
  }

  @override
  String debtBorrowedOn(String date) {
    return 'borrowed $date';
  }

  @override
  String debtLentOn(String date) {
    return 'lent $date';
  }

  @override
  String get debtFrom => 'From';

  @override
  String get debtTo => 'To';

  @override
  String get debtLater => 'Later';

  @override
  String get debtRepaySaved => 'Repayment saved';

  @override
  String get debtCollectSaved => 'Money received saved';

  @override
  String get debtSettledOweToast => 'Debt settled';

  @override
  String get debtSettledOwedToast => 'Money owed settled';

  @override
  String get debtEditTitleOwe => 'Edit the debt';

  @override
  String get debtEditTitleOwed => 'Edit the money owed';

  @override
  String debtAmountMin(String amount) {
    return 'At least $amount, already paid back.';
  }

  @override
  String get debtDeleteOwe => 'Delete the debt';

  @override
  String get debtDeleteOwed => 'Delete the money owed';

  @override
  String debtDeleteText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Its $count operations will be deleted too, and their accounts\' balances will be as before.',
      one: 'Its operation will be deleted too, and its account\'s balance will be as before.',
      zero: 'Nothing moved on your accounts: only the line goes.',
    );
    return '$_temp0';
  }

  @override
  String debtDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get debtOpLocked =>
      'Amount, currency and category are changed from the debt\'s card.';

  @override
  String get debtSeeDebt => 'See the debt';

  @override
  String debtLeftCap(String amount) {
    return 'At most $amount, what is left.';
  }

  @override
  String get debtTagOwe => 'Debt';

  @override
  String get debtTagOwed => 'Money owed';

  @override
  String get debtsInTotals => 'In Money in and out';

  @override
  String get debtsInTotalsHelp =>
      'Money borrowed counts as money in, a repayment as money out.';

  @override
  String get debtsApart => 'Apart';

  @override
  String get debtsApartHelp => 'In the list, but out of the month\'s totals.';

  @override
  String accountBalanceLine(String amount) {
    return 'Balance: $amount';
  }

  @override
  String debtTitleBorrow(String name) {
    return 'Borrowed from $name';
  }

  @override
  String debtTitleRepayTo(String name) {
    return 'Paid back to $name';
  }

  @override
  String debtTitleRepayToShort(String name) {
    return 'Paid back to $name';
  }

  @override
  String debtTitleLend(String name) {
    return 'Lent to $name';
  }

  @override
  String debtTitleRepayFrom(String name) {
    return 'Paid back by $name';
  }

  @override
  String debtTitleRepayFromShort(String name) {
    return 'Paid back by $name';
  }

  @override
  String debtLeftOf(String left, String total) {
    return '$left left of $total';
  }

  @override
  String get debtForgive => 'Settle without payment';

  @override
  String debtForgiveText(String amount) {
    return 'What is left ($amount) will be given up. Nothing moves on your accounts, and it can\'t be taken back.';
  }

  @override
  String debtForgivenOn(String date, String amount) {
    return 'Settled without payment on $date: $amount given up';
  }

  @override
  String debtForgivenNote(String date, String amount) {
    return 'Settled without payment on $date, given up: $amount';
  }

  @override
  String get debtNoRepaymentForgiven =>
      'No repayment: settled without payment.';

  @override
  String debtsCountOwe(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count debts',
      one: '1 debt',
    );
    return '$_temp0';
  }

  @override
  String debtsCountOwed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count owed to me',
      one: '1 owed to me',
    );
    return '$_temp0';
  }

  @override
  String get debtsNothing => 'Nothing';

  @override
  String debtClaimTitle(String name) {
    return 'Claim from $name';
  }

  @override
  String debtClaimOwes(String name, String amount) {
    return '$name owes you $amount';
  }

  @override
  String get debtClaimMessageLabel => 'Message';

  @override
  String debtClaimMessage(String name, String amount) {
    return 'Hi $name, a small reminder about the $amount you owe me. Thanks!';
  }

  @override
  String debtClaimMessageDue(String name, String amount, String date) {
    return 'Hi $name, a small reminder about the $amount you were to give back on $date. Thanks!';
  }

  @override
  String get debtClaimSend => 'Send';

  @override
  String get debtClaimAction => 'Claim';

  @override
  String debtComingOwe(String name) {
    return 'Pay back $name';
  }

  @override
  String debtComingOwed(String name) {
    return '$name pays me back';
  }

  @override
  String reminderDebtOwe(String name, String amount, String day) {
    return 'Pay back $name: $amount, due $day';
  }

  @override
  String reminderDebtOwed(String name, String amount, String day) {
    return '$name is to pay you back $amount on $day';
  }

  @override
  String get reminderDebtToday => 'It\'s today.';

  @override
  String reminderDebtSoon(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days days.',
      one: 'It\'s tomorrow.',
    );
    return '$_temp0';
  }

  @override
  String get projectsTitle => 'Projects';

  @override
  String get projectsEmpty => 'No project';

  @override
  String get projectsEmptyHelp =>
      'Set money aside for a goal: a trip, a purchase, a reserve.';

  @override
  String get projectsMarkLegend => 'Where you should be today to meet the date';

  @override
  String get projectsEnded => 'Finished';

  @override
  String get projectsNew => 'New project';

  @override
  String projectsSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Set aside · $count projects',
      one: 'Set aside · 1 project',
    );
    return '$_temp0';
  }

  @override
  String projectsOf(String amount) {
    return 'of $amount';
  }

  @override
  String get projectsOfTotal => 'of the total';

  @override
  String projectsLeft(String amount) {
    return 'Left to set aside: $amount';
  }

  @override
  String get projectsNoDate => 'No date';

  @override
  String projectsBefore(String date) {
    return 'Before $date';
  }

  @override
  String get projectsPerWeek => 'a week';

  @override
  String get projectsPerFortnight => 'a fortnight';

  @override
  String get projectsPerMonth => 'a month';

  @override
  String get projectsEndedSpent => 'Spent, finished';

  @override
  String get projectsEndedReleased => 'Made available, finished';

  @override
  String get projectsReached => 'Goal reached';

  @override
  String projectsBehind(String amount) {
    return '$amount behind';
  }

  @override
  String projectsAhead(String amount) {
    return '$amount ahead';
  }

  @override
  String get projectsOwnPace => 'At your own pace';

  @override
  String get projectsLate => 'Behind';

  @override
  String get projectIconTitle => 'Change the icon';

  @override
  String get projectPeriod => 'Divide the plan by';

  @override
  String get projectWeek => 'Week';

  @override
  String get projectFortnight => 'Fortnight';

  @override
  String get projectMonth => 'Month';

  @override
  String get projectRemindWeek => 'Every Monday';

  @override
  String get projectRemindFortnight => 'On the 1st and the 15th';

  @override
  String get projectRemindMonth => 'On the 1st of the month';

  @override
  String get projectNewTitle => 'New project';

  @override
  String get projectName => 'Name';

  @override
  String get projectNameHint => 'Trip, motorbike, rent in advance…';

  @override
  String get projectGoal => 'Goal';

  @override
  String projectFree(String amount) {
    return '$amount free';
  }

  @override
  String get projectOptional => 'optional';

  @override
  String get projectNoDate => 'Remove the date';

  @override
  String projectEffort(String amount, String period, String date) {
    return 'It will take $amount a $period until $date.';
  }

  @override
  String get projectRemind => 'Remind me to set money aside';

  @override
  String get projectCreate => 'Create the project';

  @override
  String homeTotal(String amount) {
    return 'Total $amount';
  }

  @override
  String homeOfProjects(String amount) {
    return 'of which projects $amount';
  }

  @override
  String get homeNewProject => 'Create a project';

  @override
  String get homeTotalLabel => 'Total';

  @override
  String get homeOfProjectsLabel => 'of which projects';

  @override
  String get projectsOnTrack => 'On track';

  @override
  String get projectEffortLead => 'It will take ';

  @override
  String projectEffortAmount(String amount, String period) {
    return '$amount a $period';
  }

  @override
  String projectEffortUntil(String date) {
    return ' until $date.';
  }

  @override
  String get projectEdit => 'Edit';

  @override
  String projectDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String projectWeeksLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String projectMonthsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get projectAheadTag => 'Ahead';

  @override
  String get projectOnPace => ' on the pace';

  @override
  String projectOn(String account) {
    return 'On $account';
  }

  @override
  String get projectPutAside => 'Put aside';

  @override
  String get projectPlan => 'The plan';

  @override
  String projectPlanLeft(String amount) {
    return '$amount to go';
  }

  @override
  String projectUntil(String date) {
    return 'until $date';
  }

  @override
  String get projectThisWeek => 'This week';

  @override
  String projectWeekN(int n) {
    return 'Week $n';
  }

  @override
  String get projectThisFortnight => 'These 2 wks';

  @override
  String projectFortnightN(int n) {
    return '2 wks $n';
  }

  @override
  String get projectThisMonth => 'This month';

  @override
  String get projectPayments => 'Payments';

  @override
  String get projectTakeBack => 'Take money back';

  @override
  String projectTakenBack(String account) {
    return 'Taken back · $account';
  }

  @override
  String projectFromTo(String from, String to) {
    return '$from → $to';
  }

  @override
  String get projectWhatNow => 'What now?';

  @override
  String projectEndedOn(String date) {
    return 'Ended on $date';
  }

  @override
  String get projectEndedTag => 'Ended';

  @override
  String get projectSpentWord => 'Spent';

  @override
  String get projectReleasedWord => 'Made available';

  @override
  String projectReachedEarly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reached $count days early',
      one: 'Reached 1 day early',
      zero: 'Goal reached on the day',
    );
    return '$_temp0';
  }

  @override
  String get projectDelete => 'Delete the project';

  @override
  String projectDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String projectDeleteText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The project and its $count payments will be erased.',
      one: 'The project and its payment will be erased.',
      zero: 'The project will be erased.',
    );
    return '$_temp0';
  }

  @override
  String projectDeleteFree(String amount, String account) {
    return ' The $amount put aside is free again on $account.';
  }

  @override
  String get projectDeleteAction => 'Delete';

  @override
  String projectPutAsideFor(String name) {
    return 'Put aside for $name';
  }

  @override
  String projectSavedAmount(String amount) {
    return '$amount put aside';
  }

  @override
  String get projectQuickMissing => 'what is missing';

  @override
  String get projectQuickWeek => 'this week';

  @override
  String get projectQuickFortnight => 'these 2 weeks';

  @override
  String get projectQuickMonth => 'this month';

  @override
  String get projectQuickHalf => 'half';

  @override
  String get projectQuickAll => 'All';

  @override
  String get projectTakenFrom => 'Taken from';

  @override
  String projectTransferNote(String from, String to) {
    return 'A transfer from $from to $to will be recorded.';
  }

  @override
  String projectOnlyFree(String amount, String account) {
    return 'Only $amount free on $account.';
  }

  @override
  String projectWillLeave(String amount, String account) {
    return '$amount will be left available on $account.';
  }

  @override
  String get projectSheetOn => 'On';

  @override
  String projectTakeBackNote(String amount, String account) {
    return 'No operation: the $amount is free again on $account.';
  }

  @override
  String get projectTakeBackAction => 'Take back';

  @override
  String projectSavedCap(String amount) {
    return 'At most $amount, what is put aside';
  }

  @override
  String projectFreeCap(String amount) {
    return 'At most $amount, what is free';
  }

  @override
  String projectReachedText(String amount, String name) {
    return '$amount put aside for $name.';
  }

  @override
  String projectReachedEarlyText(String amount, String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$amount put aside for $name, $_temp0 early.';
  }

  @override
  String get projectSpent => 'I spent it';

  @override
  String get projectSpentHelp => 'Record the expense, the project ends';

  @override
  String get projectKeep => 'Keep it aside';

  @override
  String get projectKeepHelp => 'For later, or raise the goal';

  @override
  String get projectRelease => 'Make it available';

  @override
  String projectReleaseHelp(String account) {
    return 'The money is free again on $account';
  }

  @override
  String get projectEditTitle => 'Edit the project';

  @override
  String get projectSave => 'Save';

  @override
  String get projectAccountLocked =>
      'The account can’t change after a first payment.';

  @override
  String get projectDetails => 'Details';

  @override
  String get projectPutAsideSaved => 'Put aside';

  @override
  String get projectTakenBackSaved => 'Money taken back';

  @override
  String projectEndedSaved(String name) {
    return '$name has ended';
  }

  @override
  String projectReleasedLine(String account) {
    return 'Made available · $account';
  }

  @override
  String projectSpentLine(String account) {
    return 'Spent · $account';
  }

  @override
  String projectProgress(String saved, String goal) {
    return '$saved of $goal';
  }

  @override
  String projectsLateBy(String amount) {
    return '$amount behind';
  }

  @override
  String get todoProjectLate => 'Project · behind';

  @override
  String todoProjectLateLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Project · behind, $count days left',
      one: 'Project · behind, 1 day left',
    );
    return '$_temp0';
  }

  @override
  String get projectQuickLate => 'catch up';

  @override
  String reminderProjectWeek(String amount) {
    return '$amount to put aside this week';
  }

  @override
  String reminderProjectFortnight(String amount) {
    return '$amount to put aside these two weeks';
  }

  @override
  String reminderProjectMonth(String amount) {
    return '$amount to put aside this month';
  }

  @override
  String get reminderProjectFreeWeek => 'A little aside this week?';

  @override
  String get reminderProjectFreeFortnight => 'A little aside these two weeks?';

  @override
  String get reminderProjectFreeMonth => 'A little aside this month?';

  @override
  String get projectRemindShort => 'Remind me';

  @override
  String get accountsAvailable => 'Available';

  @override
  String get accountsReserved => 'Held for projects';

  @override
  String get secretShow => 'Show the password';

  @override
  String get secretHide => 'Hide the password';

  @override
  String get backupTitle => 'Backup';

  @override
  String get backupLast => 'Last backup';

  @override
  String get backupNever => 'Never';

  @override
  String get backupToday => 'Today';

  @override
  String get backupNow => 'Back up now';

  @override
  String get backupFolder => 'Folder';

  @override
  String get backupNoFolder => 'No folder chosen';

  @override
  String get backupSheetTitle => 'Back up now?';

  @override
  String get backupFirstTitle => 'First backup';

  @override
  String backupOldNote(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'Your last backup is $_temp0 old.';
  }

  @override
  String backupOldDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get backupFirstNote => 'No backup yet. Choose where to keep it.';

  @override
  String get backupChange => 'Change';

  @override
  String get backupSelect => 'Select';

  @override
  String get backupFolderMissing => 'Folder not found';

  @override
  String backupFolderMissingSub(String folder) {
    return '$folder can no longer be reached.';
  }

  @override
  String get backupEncrypt => 'Encrypt with a password';

  @override
  String get backupPassword => 'Password';

  @override
  String get backupPasswordAgain => 'Confirm the password';

  @override
  String get backupPasswordWarning =>
      'Without this password, the backup cannot be opened.';

  @override
  String get backupEverything =>
      'All your data is backed up: accounts, operations, projects, debts and settings.';

  @override
  String get backupSave => 'Back up';

  @override
  String get backupDone => 'Backup done';

  @override
  String get backupEncrypted => 'Encrypted';

  @override
  String get backupFailed =>
      'The backup could not be written. Check the folder and try again.';

  @override
  String get backupFolderDownload => 'Downloads';

  @override
  String get backupFolderDocuments => 'Documents';

  @override
  String get autoBackup => 'Automatic backup';

  @override
  String get autoBackupHelp => 'Every week';

  @override
  String get autoBackupImpossible => 'Automatic backup failed';

  @override
  String get autoBackupFolderToast =>
      'Automatic backup failed · Folder not found';

  @override
  String get autoBackupFailed => 'The automatic backup could not be made.';

  @override
  String get autoBackupChannel => 'Backups';

  @override
  String get backupPasswordNone => 'None';

  @override
  String get backupPasswordKept => 'Remembered';

  @override
  String get backupPasswordSheetTitle => 'Backup password';

  @override
  String get backupPasswordSheetBody =>
      'kibuo remembers it on this phone and encrypts all your backups with it, automatic and manual.';

  @override
  String get backupPasswordKeep => 'Remember the password';

  @override
  String get backupPasswordChange => 'Change the password';

  @override
  String get backupPasswordRemove => 'Remove the password';

  @override
  String get backupEncryptedWith => 'Encrypted with your password';

  @override
  String get protectBackupPasswordChange => 'To change the backup password';

  @override
  String get protectBackupPasswordRemove => 'To remove the backup password';

  @override
  String get plusSpaces => 'My spaces';

  @override
  String get plusSettings => 'Settings';

  @override
  String plusFooter(String version) {
    return 'kibuo $version · Your data stays on this phone';
  }

  @override
  String get plusBackupToday => 'Last backup today';

  @override
  String get plusBackupYesterday => 'Last backup yesterday';

  @override
  String plusBackupDays(int days) {
    return 'Last backup $days days ago';
  }

  @override
  String get plusBackupNone => 'No backup yet';

  @override
  String plusMonthStart(int day) {
    String _temp0 = intl.Intl.pluralLogic(
      day,
      locale: localeName,
      other: 'starts on day $day',
    );
    return '$_temp0';
  }

  @override
  String get plusLock => 'lock';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsBackup => 'Backup and restore';

  @override
  String get settingsLockOn => 'On';

  @override
  String get settingsLockOff => 'Off';

  @override
  String get languageHelp => 'Numbers and dates follow the language.';

  @override
  String get languageFrenchIn => 'French';

  @override
  String get languageEnglishIn => 'English';

  @override
  String get todoBackup => 'Backup';

  @override
  String todoBackupSub(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0 ago';
  }

  @override
  String get todoBackupNone => 'No backup yet';

  @override
  String get todoBackupAction => 'Start';

  @override
  String get moreBackup => 'Backup and export';

  @override
  String get moreBackupToday => 'Today';

  @override
  String get moreBackupYesterday => 'Yesterday';

  @override
  String moreBackupDays(int days) {
    return '$days days ago';
  }

  @override
  String get moreBackupNone => 'None yet';

  @override
  String get restoreTitle => 'Restore a backup';

  @override
  String get restoreBody =>
      'All the current data will be replaced. A copy of it is saved just before.';

  @override
  String get restoreChoose => 'Choose a file';

  @override
  String restoreSheetTitle(String date) {
    return 'Go back to $date?';
  }

  @override
  String restoreSavedOn(String date, String time) {
    return 'Saved on $date at $time';
  }

  @override
  String restoreBackupDay(String date) {
    return 'Backup · $date';
  }

  @override
  String get restoreKept => 'Restored as it was';

  @override
  String restoreReplacedCount(int days, int ops) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'Today',
    );
    String _temp1 = intl.Intl.pluralLogic(
      ops,
      locale: localeName,
      other: '$ops operations',
      one: '1 operation',
      zero: 'no operation',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get restoreReplaced => 'Replaced';

  @override
  String get restorePassword => 'The backup’s password';

  @override
  String get restorePasswordHelp => 'The one chosen when it was saved.';

  @override
  String get restoreWrongPassword =>
      'That’s not the right password. Try again.';

  @override
  String get restoreCopyNote =>
      'A copy of your current data is made just before.';

  @override
  String get restoreNoFolder =>
      'First choose the folder for the copy made before.';

  @override
  String get restoreHold => 'Hold to replace';

  @override
  String get restoreHolding => 'Keep holding…';

  @override
  String get restoreReplace => 'Replace';

  @override
  String get restoreNotKibuo =>
      'This file is not a kibuo backup, or it is damaged.';

  @override
  String get restoreTooNew =>
      'This backup comes from a newer kibuo. Update kibuo to open it.';

  @override
  String get restoreCopyFailed =>
      'The copy made before failed: nothing was replaced.';

  @override
  String get restoreDoneTitle => 'Data restored';

  @override
  String get restoreDoneBefore => 'Your data from ';

  @override
  String get restoreDoneAfter => ' is back.';

  @override
  String get restoreAccounts => 'Accounts';

  @override
  String get restoreOperations => 'Operations';

  @override
  String get restoreProjects => 'Projects';

  @override
  String restoreCopyWhere(String folder) {
    return 'Copy made before, in $folder';
  }

  @override
  String get restoreGoHome => 'See my data';

  @override
  String get protectRestore => 'To restore a backup';

  @override
  String get startRestoreLink => 'I have a backup';

  @override
  String get startRestoreTitle => 'Restore this backup?';

  @override
  String get startRestoreContent => 'Contents';

  @override
  String startRestoreCounts(int accounts, int ops) {
    String _temp0 = intl.Intl.pluralLogic(
      accounts,
      locale: localeName,
      other: '$accounts accounts',
      one: '1 account',
    );
    String _temp1 = intl.Intl.pluralLogic(
      ops,
      locale: localeName,
      other: '$ops operations',
      one: '1 operation',
      zero: 'no operation',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get startRestoreHidden => '• accounts · • operations';

  @override
  String get startRestoreNote =>
      'You get back the backup’s language, currency and settings; the next steps are skipped.';

  @override
  String get startRestoreAction => 'Restore';

  @override
  String get plusAbout => 'About kibuo';

  @override
  String get aboutTitle => 'About';

  @override
  String aboutVersion(String version, String date) {
    return 'Version $version · $date';
  }

  @override
  String get aboutTagline =>
      'Your accounts, debts and projects in one place. Your data stays on this phone.';

  @override
  String get aboutPrivacy => 'Privacy policy';

  @override
  String get aboutPrivacyDetail => 'What kibuo keeps, and where';

  @override
  String get aboutLicences => 'Licences';

  @override
  String get aboutLicencesDetail => 'The open-source software used';

  @override
  String get aboutWrite => 'Write to us';

  @override
  String get aboutMadeWithCare => 'Made with care';

  @override
  String aboutNoMailApp(String email) {
    return 'No e-mail app on this phone. Write to us at $email.';
  }

  @override
  String privacyUpdated(String date) {
    return 'Updated on $date';
  }

  @override
  String get privacyIntro =>
      'kibuo is an account book that stays on your device. Here is what it keeps, where, and what it does not do.';

  @override
  String get privacyKeepsTitle => 'What kibuo keeps';

  @override
  String get privacyKeepsBody =>
      'What you write in it: accounts, transactions and their attachments, categories, budgets, recurrences, debts and money owed, projects, currencies and rates, reminders, and your settings. kibuo does not ask for your name, your number or your location, and reads neither your contacts nor your text messages.';

  @override
  String get privacyWhereTitle => 'Where';

  @override
  String get privacyWhereBody =>
      'On your device only, in an encrypted database. Its key is kept by the device’s system, in its secure vault.';

  @override
  String get privacyNothingTitle => 'Nothing else leaves';

  @override
  String get privacyNothingBody =>
      'Without your consent, kibuo sends nothing, to us or to anyone. No account, no ads, and nothing is sold.';

  @override
  String get privacyBackupsTitle => 'Your backups';

  @override
  String get privacyBackupsBody =>
      'A backup is a file you store wherever you like. With a password, it is encrypted; without one, anyone who has the file can read it. Stored in an online service or shared, it follows that service’s rules.';

  @override
  String get privacyCopyTitle => 'The system’s copy';

  @override
  String get privacyCopyBody =>
      'Once the recovery code is created, your device’s system may copy kibuo’s data to its online backup or to a new device. It stays encrypted there and opens only with the recovery code. You can prevent it in Settings › Recovery code.\n\nOn Android: the phone’s Google backup, and the transfer to a new phone.';

  @override
  String get privacyDeviceTitle => 'Fingerprint and photos';

  @override
  String get privacyDeviceBody =>
      'Your fingerprint or face is checked by the device’s system: kibuo never sees it. The camera and the gallery are used only when you add an attachment.';

  @override
  String get privacyEraseTitle => 'Erasing your data';

  @override
  String get privacyEraseBody =>
      'Uninstalling kibuo, or clearing its data in the system settings, erases everything it keeps on the device. Your backups stay where you stored them.\n\nOn Android: long-press kibuo’s icon › Uninstall, or Settings › Apps › kibuo › Storage, then clear the data (names vary between phones).';

  @override
  String get privacyPublisherTitle => 'Who publishes kibuo';

  @override
  String privacyPublisherBody(String email) {
    return 'kibuo is published by Daniel Rubango. For any question about your data or this policy, write to $email.';
  }

  @override
  String get usageTitle => 'Help improve kibuo?';

  @override
  String get usageIntro =>
      'kibuo can send us anonymous statistics, to see what works and what gets in the way.';

  @override
  String get usageSentTitle => 'What is sent';

  @override
  String get usageSentText =>
      'The screens opened, the actions taken and the errors, with a random number.';

  @override
  String get usageNeverTitle => 'Never';

  @override
  String get usageNeverText =>
      'Your amounts, your names, your notes, your location.';

  @override
  String get usageReadPolicy => 'Read the privacy policy';

  @override
  String get usageNo => 'No thanks';

  @override
  String get usageYes => 'Yes, share';

  @override
  String get usageSwitch => 'Help improve kibuo';

  @override
  String get usageHelp =>
      'Anonymous statistics and errors, with a random number. Never your amounts, your names, your notes or your location. ';

  @override
  String get usagePolicyLink => 'Privacy policy';

  @override
  String get privacyStatsTitle => 'Statistics, if you agree';

  @override
  String get privacyStatsBody =>
      'If you agree to “Help improve kibuo”, kibuo sends analytics data that helps us improve the app: the screens opened, the actions taken (without their content), the errors, and a description of the device (model, system and its version, language, country, main currency). It carries a random number, linked neither to you nor to the device. Never your amounts, your names, your notes or your location, and your IP address is not kept.\n\nThis data is stored in Europe for the time needed to analyse it, about one year. You can stop at any time in Settings › Privacy: the number and whatever was waiting to be sent are then forgotten.';

  @override
  String get overviewEvolution => 'Trends';

  @override
  String get overviewCategories => 'Categories';

  @override
  String get overviewCategoriesText =>
      'Where your money goes, where it comes from';

  @override
  String get overviewWorth => 'Net worth';

  @override
  String get overviewWorthText =>
      'Your accounts, plus what you are owed, less your debts';

  @override
  String get overviewPeriodTitle => 'Period';

  @override
  String get overviewReset => 'Reset';

  @override
  String get overviewKindToday => 'Today';

  @override
  String get overviewKindYesterday => 'Yesterday';

  @override
  String get overviewKind24h => '24 h';

  @override
  String get overviewKind7Days => '7 days';

  @override
  String get overviewKindMonth => '1 month';

  @override
  String get overviewKindYear => '1 year';

  @override
  String get overviewKindCustom => 'Custom';

  @override
  String get overviewFrom => 'From';

  @override
  String get overviewTo => 'To';

  @override
  String get overviewGroupBy => 'Group by';

  @override
  String get overviewByHour => 'Hour';

  @override
  String get overviewByDay => 'Day';

  @override
  String get overviewByWeek => 'Week';

  @override
  String get overviewByMonth => 'Month';

  @override
  String get overviewCompareTo => 'Compare with';

  @override
  String get overviewComparePrevious => 'Before';

  @override
  String get overviewCompareNext => 'After';

  @override
  String get overviewCompareCurrent => 'Current';

  @override
  String get overviewCompareNone => 'None';

  @override
  String get overviewComparedAs => 'Compared period as';

  @override
  String get overviewCurve => 'Curve';

  @override
  String get overviewSticks => 'Columns';

  @override
  String get overviewSee => 'Show';

  @override
  String get overviewExits => 'Out';

  @override
  String get overviewEntries => 'In';

  @override
  String get overviewPreviousPeriod => 'Previous period';

  @override
  String get overviewNextPeriod => 'Next period';

  @override
  String get overviewLast24h => 'Last 24 hours';

  @override
  String overviewUntil(String day, int hour) {
    return 'Until $day, $hour:00';
  }

  @override
  String get overviewLast7Days => 'Last 7 days';

  @override
  String overviewRange(String first, String last) {
    return '$first – $last';
  }

  @override
  String overviewHourMark(int hour) {
    return '$hour:00';
  }

  @override
  String overviewWeekMark(int week) {
    return 'W$week';
  }

  @override
  String get overviewSoon => 'Coming soon';

  @override
  String get overviewWhereOut => 'Where my money goes';

  @override
  String get overviewWhereIn => 'Where my money comes from';

  @override
  String overviewTotalOut(String amount) {
    return '$amount out';
  }

  @override
  String overviewTotalIn(String amount) {
    return '$amount in';
  }

  @override
  String get overviewDebtsLine => 'Debts and money owed';

  @override
  String get overviewFeesLine => 'Transfer fees';

  @override
  String overviewOtherCategories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count other categories',
      one: '1 other category',
    );
    return '$_temp0';
  }

  @override
  String get overviewCategoriesHelp => 'Touch a category to see its details.';

  @override
  String get overviewNoExitPeriod => 'Nothing went out over the period';

  @override
  String get overviewNoEntryPeriod => 'Nothing came in over the period';

  @override
  String categoryPageOut(int share, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operations',
      one: '1 operation',
    );
    return '$share % of money out · $_temp0';
  }

  @override
  String categoryPageIn(int share, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count operations',
      one: '1 operation',
    );
    return '$share % of money in · $_temp0';
  }

  @override
  String followedTitle(String period) {
    return 'Followed · $period';
  }

  @override
  String get followedThisMonth => 'This month';

  @override
  String get followedThisYear => 'This year';

  @override
  String followedDays(int count) {
    return '$count days';
  }

  @override
  String get followedFollow => 'Follow';

  @override
  String followedMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show the $count others',
      one: 'Show the other one',
    );
    return '$_temp0';
  }

  @override
  String get followedLess => 'Show less';

  @override
  String get followedSpent => 'Spent';

  @override
  String get followedReceived => 'Received';

  @override
  String get followedSavings => 'Savings';

  @override
  String get followedSavingsYear => 'Savings this year';

  @override
  String get followedAverage => 'Average';

  @override
  String get followedAverageDay => 'Average per day';

  @override
  String get followedAverageWeek => 'Average per week';

  @override
  String get followedAverageMonth => 'Average per month';

  @override
  String get followedTopCategory => 'Top category';

  @override
  String get followedTopCategoryDay => 'Category of the day';

  @override
  String get followedPriciest => 'Priciest day or month';

  @override
  String get followedPriciestHour => 'Priciest hour';

  @override
  String get followedPriciestDay => 'Priciest day';

  @override
  String get followedPriciestMonth => 'Priciest month';

  @override
  String get followedUpcoming => 'Coming up';

  @override
  String get followedBudget => 'A budget';

  @override
  String followedBudgetNamed(String name) {
    return '$name budget';
  }

  @override
  String get followedLeftToday => 'Left for today';

  @override
  String get followedDebts => 'Debts';

  @override
  String get followedReceivables => 'Owed to you';

  @override
  String get followedProject => 'A project';

  @override
  String followedProjectNamed(String name) {
    return '$name project';
  }

  @override
  String get followedProjectsReached => 'Projects reached';

  @override
  String get followedAccounts => 'Accounts';

  @override
  String get followedNetWorth => 'Net worth';

  @override
  String followedAverageDayDetail(String amount) {
    return 'average day: $amount';
  }

  @override
  String followedPerDay(String amount) {
    return 'per day: $amount';
  }

  @override
  String followedEntriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'no money in',
    );
    return '$_temp0';
  }

  @override
  String get followedSavingsDetail => 'in − out';

  @override
  String followedOverDays(int count) {
    return 'over $count days';
  }

  @override
  String followedPriciestOf(String name) {
    return 'priciest: $name';
  }

  @override
  String followedAmountShare(String amount, int share) {
    return '$amount · $share %';
  }

  @override
  String get followedNoExit => 'Nothing out';

  @override
  String followedLeft(String amount) {
    return '$amount left';
  }

  @override
  String followedOver(String amount) {
    return '$amount over';
  }

  @override
  String followedMonthRunning(String month) {
    return '$month, in progress';
  }

  @override
  String followedMonthBudget(String name) {
    return '$name · from the month’s budget';
  }

  @override
  String get followedNoBudget => 'No budget';

  @override
  String followedLate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count late',
      one: '1 late',
    );
    return '$_temp0';
  }

  @override
  String followedDebtCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count debts',
      one: '1 debt',
      zero: 'no debt',
    );
    return '$_temp0';
  }

  @override
  String followedRecovered(String amount) {
    return '$amount recovered';
  }

  @override
  String followedPutAside(String amount) {
    return '+$amount put aside';
  }

  @override
  String followedTakenBack(String amount) {
    return '−$amount taken back';
  }

  @override
  String get followedNoProject => 'No project';

  @override
  String followedReachedOf(int reached, int total) {
    return '$reached of $total';
  }

  @override
  String get followedNoneReached => 'none yet';

  @override
  String followedIn(String label, int days) {
    return '$label in $days d';
  }

  @override
  String followedToday(String label) {
    return '$label today';
  }

  @override
  String followedTomorrow(String label) {
    return '$label tomorrow';
  }

  @override
  String followedOnDay(String amount, String date) {
    return '$amount on $date';
  }

  @override
  String get followedNothingComing => 'Nothing coming';

  @override
  String get followedNext14Days => 'in the next 14 days';

  @override
  String get followSheetHelp =>
      'Each tile fits the chosen period. The first 4 show; the others are under « Show the others ».';

  @override
  String get followMoney => 'Money';

  @override
  String get followMarks => 'Landmarks';

  @override
  String get followCommitments => 'Commitments';

  @override
  String get followWorth => 'Net worth';

  @override
  String get followSpentHelp =>
      'Compared with the chosen period; for a day, with an average day';

  @override
  String get followReceivedHelp => 'Money in, with its change';

  @override
  String get followSavingsHelp => 'Money in less money out';

  @override
  String get followAverageHelp => 'Per day, per week or per month, by period';

  @override
  String get followTopCategoryHelp =>
      'The one that weighs most over the period';

  @override
  String get followPriciestHelp => 'By the length of the period';

  @override
  String get followUpcomingHelp => 'The next due date';

  @override
  String followBudgetHelp(String name) {
    return '$name · what is left';
  }

  @override
  String get followDebtsHelp => 'Total and late ones';

  @override
  String get followReceivablesHelp => 'Total and repaid';

  @override
  String followProjectHelp(String name) {
    return '$name · progress';
  }

  @override
  String get followAccountsHelp => 'The total and its curve';

  @override
  String get followNetWorthHelp => 'Accounts + owed to you − debts';

  @override
  String get followDone => 'Done';

  @override
  String get followWhichBudget => 'Which budget to follow?';

  @override
  String get followWhichProject => 'Which project to follow?';

  @override
  String get followSheetTitle => 'Followed';

  @override
  String enlAtThisDate(String period, String amount) {
    return '$period at this date: $amount';
  }

  @override
  String get enlWhereMost => 'Where it goes most';

  @override
  String get enlBiggestEntry => 'Biggest entry';

  @override
  String get enlWhereFrom => 'Where it comes from most';

  @override
  String get enlEntriesCount => 'Number of entries';

  @override
  String enlOfEntries(int share) {
    return '$share % of money in';
  }

  @override
  String get enlSavedShare => 'Share saved';

  @override
  String enlKept(int share) {
    return '$share % kept';
  }

  @override
  String get enlOfEntriesShort => 'of money in';

  @override
  String get enlHighest => 'The highest';

  @override
  String get enlLowest => 'The lowest';

  @override
  String get enlAboveAverage => 'Above average';

  @override
  String enlDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String enlWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String enlMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String enlOutOf(int count) {
    return 'out of $count';
  }

  @override
  String enlPeriodValue(String period, String amount) {
    return '$period: $amount';
  }

  @override
  String enlOfExits(String amount, int share) {
    return '$amount · $share % of money out';
  }

  @override
  String enlRest(int share, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return 'The rest: $share % in $_temp0';
  }

  @override
  String get enlSeeOperations => 'See the operations';

  @override
  String enlSeeCategory(String name) {
    return 'See the $name operations';
  }

  @override
  String get enlSeeBudget => 'See the budget';

  @override
  String get enlSeeProject => 'See the project';

  @override
  String get enlSeeProjects => 'See the projects';

  @override
  String get enlSeeDebts => 'See the debts';

  @override
  String get enlSeeReceivables => 'See what is owed to you';

  @override
  String get enlSeeAccounts => 'See the accounts';

  @override
  String get enlSeeRecurrences => 'See the recurring ones';

  @override
  String enlShareOfPeriod(String amount, int share, String scope) {
    String _temp0 = intl.Intl.selectLogic(scope, {
      'day': 'day',
      'week': 'week',
      'month': 'month',
      'year': 'year',
      'other': 'period',
    });
    return '$amount · $share % of the $_temp0';
  }

  @override
  String enlAxisDay(int day) {
    return '$day';
  }

  @override
  String enlComparedPer(String period, String amount, String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'week': 'week',
      'month': 'month',
      'other': 'day',
    });
    return '$period: $amount a $_temp0';
  }

  @override
  String get enlNext14Days => 'Next 14 days';

  @override
  String get enlToday => 'today';

  @override
  String enlReceivableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count amounts owed to you',
      one: '1 amount owed to you',
      zero: 'nothing owed to you',
    );
    return '$_temp0';
  }

  @override
  String enlAmountsIn(String symbol) {
    return 'Amounts in $symbol · the three priciest in colour';
  }

  @override
  String enlInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'tomorrow',
    );
    return '$_temp0';
  }

  @override
  String get enlDueToday => 'today';

  @override
  String enlLateBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days late',
      one: 'one day late',
    );
    return '$_temp0';
  }

  @override
  String get enlNoDate => 'no date';

  @override
  String enlRecurrence(String when) {
    return '$when · recurring';
  }

  @override
  String enlDebtDue(String when) {
    return 'debt due · $when';
  }

  @override
  String enlReceivableDue(String when) {
    return 'owed to you · $when';
  }

  @override
  String enlOn(String amount) {
    return 'of $amount';
  }

  @override
  String get enlLeftPerDay => 'Left per day';

  @override
  String enlUntil(String date) {
    return 'until $date';
  }

  @override
  String get enlPace => 'Pace';

  @override
  String get enlAhead => 'ahead of the even pace';

  @override
  String get enlMargin => 'to spare on the even pace';

  @override
  String enlRegularPace(String amount) {
    return 'Even pace $amount';
  }

  @override
  String enlRepaid(int share) {
    return '$share % already repaid';
  }

  @override
  String enlRecovered(int share) {
    return '$share % already recovered';
  }

  @override
  String enlThisMonth(String amount) {
    return '$amount this month';
  }

  @override
  String enlOverPeriod(String amount) {
    return '$amount over the period';
  }

  @override
  String enlForDate(String date) {
    return 'for $date';
  }

  @override
  String get enlPaid => 'Put aside';

  @override
  String get enlPlanned => 'Planned saving';

  @override
  String get enlEveryWeek => 'every week';

  @override
  String get enlEveryMonth => 'every month';

  @override
  String get enlAheadPlan => 'Ahead';

  @override
  String get enlBehindPlan => 'Behind';

  @override
  String get enlOnPlan => 'on the plan';

  @override
  String enlPlanMark(String amount) {
    return 'plan: $amount';
  }

  @override
  String get enlLeftToSave => 'Left to put aside';

  @override
  String enlSince(String amount, String date) {
    return '$amount since $date';
  }

  @override
  String enlAccountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
    );
    return '$_temp0';
  }

  @override
  String get enlOwedToYou => 'owed to you';

  @override
  String get enlYouOwe => 'what you owe';

  @override
  String get enlNet => 'Net';

  @override
  String get followAffichage => 'Display';

  @override
  String get followShownAs => 'Spent, Received and Savings as';
}
