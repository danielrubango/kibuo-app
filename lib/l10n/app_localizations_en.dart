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
  String get accountNameMissing => 'Give the account a name.';

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
  String get firstLockTitle => 'Lock the app';

  @override
  String get firstLockHelp =>
      'PIN or fingerprint. You will be given a recovery code.';

  @override
  String get firstLater =>
      'You can change these choices at any time in the settings.';

  @override
  String get firstStart => 'Start';
}
