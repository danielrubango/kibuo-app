import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Bottom bar tab: the home screen.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get tabHome;

  /// Bottom bar tab: the list of transactions.
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get tabOperations;

  /// Bottom bar tab: charts and tracked items.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get tabOverview;

  /// Bottom bar tab: spaces and settings.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get tabMore;

  /// Title of the home screen.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get homeTitle;

  /// Temporary text on the home screen until it is built.
  ///
  /// In fr, this message translates to:
  /// **'Le disponible, le mois en cours et ce qui arrive viendront ici.'**
  String get homePlaceholder;

  /// Temporary text on the transactions screen until it is built.
  ///
  /// In fr, this message translates to:
  /// **'Les opérations du mois viendront ici.'**
  String get operationsPlaceholder;

  /// Temporary text on the overview screen until it is built.
  ///
  /// In fr, this message translates to:
  /// **'Les graphiques et les points suivis viendront ici.'**
  String get overviewPlaceholder;

  /// Temporary text on the More screen until it is built.
  ///
  /// In fr, this message translates to:
  /// **'Mes espaces et les réglages viendront ici.'**
  String get morePlaceholder;

  /// Screen reader label of the central + button.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une opération'**
  String get plusButton;

  /// Screen reader hint of the + button: a long press opens the fan.
  ///
  /// In fr, this message translates to:
  /// **'Maintenir pour les choix rapides'**
  String get plusButtonHint;

  /// Title of the sheet opened by tapping +.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addSheetTitle;

  /// Closes a sheet or the fan.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// Leaves an entry screen without saving.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Hint shown above the fan opened by holding +.
  ///
  /// In fr, this message translates to:
  /// **'Glissez vers un choix, ou touchez-le'**
  String get fanHint;

  /// Choice in the + menu: record an expense.
  ///
  /// In fr, this message translates to:
  /// **'Dépense'**
  String get addExpense;

  /// Small text under the expense choice.
  ///
  /// In fr, this message translates to:
  /// **'Le plus fréquent'**
  String get addExpenseHint;

  /// Title of the new expense screen.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dépense'**
  String get addExpenseTitle;

  /// Choice in the + menu: record income.
  ///
  /// In fr, this message translates to:
  /// **'Revenu'**
  String get addIncome;

  /// Small text under the income choice.
  ///
  /// In fr, this message translates to:
  /// **'Salaire, vente'**
  String get addIncomeHint;

  /// Title of the new income screen.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau revenu'**
  String get addIncomeTitle;

  /// Choice in the + menu: move money between accounts.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get addTransfer;

  /// Small text under the transfer choice.
  ///
  /// In fr, this message translates to:
  /// **'Entre comptes'**
  String get addTransferHint;

  /// Title of the new transfer screen.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau transfert'**
  String get addTransferTitle;

  /// Choice in the + menu: a debt, or money owed to the user.
  ///
  /// In fr, this message translates to:
  /// **'Dette'**
  String get addDebt;

  /// Small text under the debt choice.
  ///
  /// In fr, this message translates to:
  /// **'ou créance'**
  String get addDebtHint;

  /// Debt choice in the fan, on two lines.
  ///
  /// In fr, this message translates to:
  /// **'Dette ou\ncréance'**
  String get addDebtFan;

  /// Title of the new debt screen.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dette ou créance'**
  String get addDebtTitle;

  /// Choice in the + menu: put money aside for a savings project.
  ///
  /// In fr, this message translates to:
  /// **'Projet'**
  String get addProject;

  /// Small text under the project choice.
  ///
  /// In fr, this message translates to:
  /// **'Mettre de côté'**
  String get addProjectHint;

  /// Project choice in the fan, on two lines.
  ///
  /// In fr, this message translates to:
  /// **'Mettre\nde côté'**
  String get addProjectFan;

  /// Title of the screen that puts money aside.
  ///
  /// In fr, this message translates to:
  /// **'Mettre de côté'**
  String get addProjectTitle;

  /// Temporary text on entry screens until they are built.
  ///
  /// In fr, this message translates to:
  /// **'Cette saisie arrive à une prochaine étape.'**
  String get entryComingLater;

  /// Title when the encrypted data cannot be opened.
  ///
  /// In fr, this message translates to:
  /// **'Vos données ne peuvent pas être ouvertes'**
  String get unreadableTitle;

  /// Explains why the data cannot be opened and that the file is kept.
  ///
  /// In fr, this message translates to:
  /// **'Elles viennent peut-être d’un autre téléphone, ou la clé qui les protège n’est plus sur celui-ci. Le fichier est gardé de côté, il n’est pas effacé.'**
  String get unreadableBody;

  /// Button: set the unreadable data aside and start with empty data.
  ///
  /// In fr, this message translates to:
  /// **'Repartir de zéro'**
  String get unreadableStartOver;

  /// Title of the screens that create or change the app-lock code.
  ///
  /// In fr, this message translates to:
  /// **'Créer votre code'**
  String get lockCreateTitle;

  /// First step of creating the code.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre code'**
  String get lockChoose;

  /// Under the title when choosing the code.
  ///
  /// In fr, this message translates to:
  /// **'De 4 à 6 chiffres.'**
  String get lockChooseHint;

  /// Second step: confirm the code.
  ///
  /// In fr, this message translates to:
  /// **'Retapez votre code'**
  String get lockConfirm;

  /// Under the title when confirming.
  ///
  /// In fr, this message translates to:
  /// **'Pour vérifier que vous l’avez bien en tête.'**
  String get lockConfirmHint;

  /// When the confirmation differs.
  ///
  /// In fr, this message translates to:
  /// **'Les deux codes ne correspondent pas. Recommencez.'**
  String get lockMismatch;

  /// Button under the keypad once 4 digits are typed.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get lockValidate;

  /// After the code is confirmed.
  ///
  /// In fr, this message translates to:
  /// **'Code créé'**
  String get lockCreatedTitle;

  /// After the code is confirmed.
  ///
  /// In fr, this message translates to:
  /// **'Kibuo demandera ce code à chaque ouverture.'**
  String get lockCreatedBody;

  /// Generic button to go on.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueAction;

  /// Title of the unlock screen.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code'**
  String get lockEnterTitle;

  /// Before changing or removing the code.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre code actuel'**
  String get lockCurrentTitle;

  /// Title while the user must wait.
  ///
  /// In fr, this message translates to:
  /// **'Trop d’essais'**
  String get lockTooMany;

  /// Link under the code boxes.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser l’empreinte'**
  String get lockUseFingerprint;

  /// Link under the code boxes, and title of its sheet.
  ///
  /// In fr, this message translates to:
  /// **'Code oublié ?'**
  String get lockForgot;

  /// Screen-reader label of the keypad’s delete key.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get keypadDelete;

  /// Offered right after creating the code.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir Kibuo avec votre empreinte ?'**
  String get fingerprintOfferTitle;

  /// Under the fingerprint offer.
  ///
  /// In fr, this message translates to:
  /// **'Plus rapide que le code, qui reste possible à tout moment.'**
  String get fingerprintOfferBody;

  /// Accepts the fingerprint offer.
  ///
  /// In fr, this message translates to:
  /// **'Activer l’empreinte'**
  String get fingerprintEnable;

  /// Declines an offer for now.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get later;

  /// Shown by Android in the fingerprint prompt.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir Kibuo'**
  String get fingerprintReason;

  /// Option in the forgotten-code sheet.
  ///
  /// In fr, this message translates to:
  /// **'Effacer et repartir de zéro'**
  String get forgotErase;

  /// Warning before erasing.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les données de Kibuo sur ce téléphone seront effacées. Vous pourrez ensuite restaurer une sauvegarde, si vous en avez une.'**
  String get forgotEraseBody;

  /// Button that erases after a long press.
  ///
  /// In fr, this message translates to:
  /// **'Maintenir pour effacer'**
  String get forgotHold;

  /// Settings page title and row on the More tab.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get securityTitle;

  /// Row in Security.
  ///
  /// In fr, this message translates to:
  /// **'Verrouillage'**
  String get securityLock;

  /// Row in Security.
  ///
  /// In fr, this message translates to:
  /// **'Confidentialité'**
  String get securityPrivacy;

  /// Summary when no code is set.
  ///
  /// In fr, this message translates to:
  /// **'Aucun code'**
  String get securityNoCode;

  /// Summary when a code is set.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get securityCode;

  /// Summary when code and fingerprint are on.
  ///
  /// In fr, this message translates to:
  /// **'Code · empreinte'**
  String get securityCodeFingerprint;

  /// Privacy summary.
  ///
  /// In fr, this message translates to:
  /// **'Récentes masquées'**
  String get securityRecentsHidden;

  /// Privacy summary.
  ///
  /// In fr, this message translates to:
  /// **'Récentes visibles'**
  String get securityRecentsShown;

  /// Under the Security rows.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont chiffrées et restent sur ce téléphone.'**
  String get securityFooter;

  /// Row when no code is set.
  ///
  /// In fr, this message translates to:
  /// **'Créer un code'**
  String get lockSettingsCreate;

  /// Row when a code is set.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le code'**
  String get lockSettingsChange;

  /// Switch in App lock.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte'**
  String get lockFingerprint;

  /// Switch in App lock.
  ///
  /// In fr, this message translates to:
  /// **'Clavier mélangé'**
  String get lockShuffle;

  /// Help under the switches.
  ///
  /// In fr, this message translates to:
  /// **'Le clavier mélangé change la place des chiffres à chaque fois : un regard par-dessus l’épaule ne suffit pas à deviner le code.'**
  String get lockShuffleHelp;

  /// Title above the delay choices.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller après une absence de'**
  String get lockAfter;

  /// Auto-lock delay.
  ///
  /// In fr, this message translates to:
  /// **'Aussitôt'**
  String get delayImmediately;

  /// Auto-lock delay.
  ///
  /// In fr, this message translates to:
  /// **'1 minute'**
  String get delayOneMinute;

  /// Auto-lock delay.
  ///
  /// In fr, this message translates to:
  /// **'5 minutes'**
  String get delayFiveMinutes;

  /// Removes the app-lock code.
  ///
  /// In fr, this message translates to:
  /// **'Retirer le code'**
  String get lockRemove;

  /// Help under Remove the code.
  ///
  /// In fr, this message translates to:
  /// **'Sans code, Kibuo s’ouvre directement. Vos données restent chiffrées.'**
  String get lockRemoveHelp;

  /// Privacy switch.
  ///
  /// In fr, this message translates to:
  /// **'Masquer Kibuo dans les applications récentes'**
  String get privacyHideRecents;

  /// Privacy switch.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les captures d’écran'**
  String get privacyScreenshots;

  /// Help under the privacy switches.
  ///
  /// In fr, this message translates to:
  /// **'Masqué, l’aperçu des applications récentes montre le logo de Kibuo au lieu de vos soldes.'**
  String get privacyHelp;

  /// After a wrong code.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. Essai {count} sur 5.'**
  String lockWrong(int count);

  /// Countdown while waiting, e.g. 0:28.
  ///
  /// In fr, this message translates to:
  /// **'Réessayez dans {time}.'**
  String lockRetryIn(String time);

  /// Length of the current code.
  ///
  /// In fr, this message translates to:
  /// **'{count} chiffres'**
  String lockDigits(int count);

  /// Row in App lock; opens the delay sheet.
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller après'**
  String get lockAfterRow;

  /// Auto-lock delay.
  ///
  /// In fr, this message translates to:
  /// **'30 secondes'**
  String get delayThirtySeconds;

  /// Auto-lock delay.
  ///
  /// In fr, this message translates to:
  /// **'15 minutes'**
  String get delayFifteenMinutes;

  /// Screen title and Security row.
  ///
  /// In fr, this message translates to:
  /// **'Code de récupération'**
  String get recoveryTitle;

  /// Title when the new code is shown.
  ///
  /// In fr, this message translates to:
  /// **'Notez votre code de récupération'**
  String get recoveryShowTitle;

  /// Under the new code.
  ///
  /// In fr, this message translates to:
  /// **'Il rend l’accès à Kibuo si vous oubliez votre code et que l’empreinte ne marche pas, et il rouvre vos données sur un nouveau téléphone. Notez-le sur papier et gardez-le en lieu sûr.'**
  String get recoveryShowBody;

  /// Warning under the new code.
  ///
  /// In fr, this message translates to:
  /// **'Kibuo ne le garde pas : il ne pourra plus vous le montrer.'**
  String get recoveryShowWarning;

  /// Copies the recovery code.
  ///
  /// In fr, this message translates to:
  /// **'Copier le code'**
  String get recoveryCopy;

  /// After copying.
  ///
  /// In fr, this message translates to:
  /// **'Code copié'**
  String get recoveryCopied;

  /// Goes on to the proof step.
  ///
  /// In fr, this message translates to:
  /// **'J’ai noté mon code'**
  String get recoveryNoted;

  /// Under the proof title.
  ///
  /// In fr, this message translates to:
  /// **'Pour vérifier que vous avez bien noté votre code.'**
  String get recoveryProofBody;

  /// Wrong group typed.
  ///
  /// In fr, this message translates to:
  /// **'Ce n’est pas ce groupe. Regardez votre note.'**
  String get recoveryProofWrong;

  /// Back to the code from the proof step.
  ///
  /// In fr, this message translates to:
  /// **'Revoir le code'**
  String get recoverySeeAgain;

  /// Title of the entry screen.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre code de récupération'**
  String get recoveryEnterTitle;

  /// Under the entry title.
  ///
  /// In fr, this message translates to:
  /// **'Le code de 16 caractères remis à sa création, en 4 groupes.'**
  String get recoveryEnterBody;

  /// Under the code boxes.
  ///
  /// In fr, this message translates to:
  /// **'Les tirets et les minuscules ne comptent pas.'**
  String get recoveryEnterHint;

  /// Wrong recovery code.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect. Vérifiez chaque groupe et réessayez.'**
  String get recoveryWrong;

  /// Checks the recovery code.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir Kibuo'**
  String get recoveryOpen;

  /// In the forgotten-code sheet.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser le code de récupération'**
  String get recoveryUse;

  /// On the recovery settings page.
  ///
  /// In fr, this message translates to:
  /// **'Kibuo ne le garde pas : vous seul le connaissez.'**
  String get recoveryNotKept;

  /// Replaces the recovery code.
  ///
  /// In fr, this message translates to:
  /// **'Obtenir un nouveau code'**
  String get recoveryNew;

  /// Under Get a new code.
  ///
  /// In fr, this message translates to:
  /// **'L’ancien code de récupération cessera de fonctionner.'**
  String get recoveryNewHelp;

  /// When there is no recovery code.
  ///
  /// In fr, this message translates to:
  /// **'Créer un code de récupération'**
  String get recoveryCreate;

  /// Why create a recovery code.
  ///
  /// In fr, this message translates to:
  /// **'Sans code de récupération, un code oublié ou un nouveau téléphone obligent à repartir de zéro, et Android ne copie pas les données de Kibuo.'**
  String get recoveryCreateHelp;

  /// Switch for Android backup and transfer.
  ///
  /// In fr, this message translates to:
  /// **'Laisser Android copier Kibuo'**
  String get recoveryAndroidCopy;

  /// Under the Android copy switch.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde Google et transfert vers un nouveau téléphone. Les données copiées restent chiffrées et ne s’ouvrent qu’avec ce code.'**
  String get recoveryAndroidCopyHelp;

  /// On the unreadable-data screen.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code de récupération'**
  String get unreadableRecover;

  /// Proof step title.
  ///
  /// In fr, this message translates to:
  /// **'Retapez le groupe {group}'**
  String recoveryProofTitle(int group);

  /// When the code was created.
  ///
  /// In fr, this message translates to:
  /// **'Code noté le {date}'**
  String recoveryNotedOn(String date);

  /// Security row summary.
  ///
  /// In fr, this message translates to:
  /// **'Noté le {date}'**
  String securityRecoveryOn(String date);

  /// Settings page and More row.
  ///
  /// In fr, this message translates to:
  /// **'Devises'**
  String get currenciesTitle;

  /// Card title on Currencies.
  ///
  /// In fr, this message translates to:
  /// **'Devise principale'**
  String get currenciesMain;

  /// Changes the main currency.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get currenciesChange;

  /// Section title.
  ///
  /// In fr, this message translates to:
  /// **'Taux de conversion'**
  String get currenciesRates;

  /// A rate not typed but derived.
  ///
  /// In fr, this message translates to:
  /// **'Calculé d’après vos autres taux'**
  String get currenciesWorkedOut;

  /// A currency without a rate.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de taux'**
  String get currenciesNoRate;

  /// Opens the rate sheet.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get currenciesEdit;

  /// Under the rates.
  ///
  /// In fr, this message translates to:
  /// **'Modifier un taux ne change pas les opérations déjà enregistrées.'**
  String get currenciesRatesHelp;

  /// Adds a currency.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une devise'**
  String get currenciesAdd;

  /// Picker title.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une devise'**
  String get currencyPickerTitle;

  /// Picker title for the main currency.
  ///
  /// In fr, this message translates to:
  /// **'Votre devise principale'**
  String get mainCurrencyPickerTitle;

  /// Under the main currency picker title.
  ///
  /// In fr, this message translates to:
  /// **'Elle sert au suivi et aux rapports. Chaque compte gardera sa propre devise.'**
  String get mainCurrencyHelp;

  /// Search field hint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une devise'**
  String get currencySearch;

  /// The user's own currencies, first when choosing the main one.
  ///
  /// In fr, this message translates to:
  /// **'Vos devises'**
  String get currencyYours;

  /// First part of the list.
  ///
  /// In fr, this message translates to:
  /// **'Les plus courantes'**
  String get currencyCommon;

  /// Second part of the list.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les autres'**
  String get currencyOthers;

  /// In the rate sheet.
  ///
  /// In fr, this message translates to:
  /// **'Les opérations déjà enregistrées gardent leur taux.'**
  String get rateKeepsOld;

  /// Saves the rate.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le taux'**
  String get rateSave;

  /// Section of Devises with a cents switch per currency.
  ///
  /// In fr, this message translates to:
  /// **'Centimes'**
  String get currenciesCents;

  /// Under the decimals switch.
  ///
  /// In fr, this message translates to:
  /// **'Désactivés, les montants s’affichent et se saisissent sans centimes.'**
  String get currencyDecimalsHelp;

  /// When a rate was last set.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour le {date}'**
  String currenciesUpdatedOn(String date);

  /// Rate sheet title; ofName carries its French article: « du franc congolais », « de l’euro ».
  ///
  /// In fr, this message translates to:
  /// **'Taux {ofName}'**
  String rateSheetTitle(String ofName);

  /// Previous rate and its date.
  ///
  /// In fr, this message translates to:
  /// **'Avant : {rate} · {date}'**
  String rateBefore(String rate, String date);

  /// Hint of the currency search field.
  ///
  /// In fr, this message translates to:
  /// **'Nom ou code'**
  String get currencySearchHint;

  /// The new rate equals the previous one.
  ///
  /// In fr, this message translates to:
  /// **'Inchangé'**
  String get rateUnchanged;

  /// Accounts: accountsTitle
  ///
  /// In fr, this message translates to:
  /// **'Comptes'**
  String get accountsTitle;

  /// Accounts: accountsAll
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get accountsAll;

  /// Accounts: accountsTotal
  ///
  /// In fr, this message translates to:
  /// **'Total de mes comptes'**
  String get accountsTotal;

  /// Accounts: accountsTotalOf
  ///
  /// In fr, this message translates to:
  /// **'Total {type}'**
  String accountsTotalOf(String type);

  /// Accounts: accountsAdd
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un compte'**
  String get accountsAdd;

  /// Accounts: accountsCount
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 compte} other{{count} comptes}}'**
  String accountsCount(int count);

  /// Accounts: accountTypeCash
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get accountTypeCash;

  /// Accounts: accountTypeBank
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get accountTypeBank;

  /// Accounts: accountTypeMobile
  ///
  /// In fr, this message translates to:
  /// **'Mobile money'**
  String get accountTypeMobile;

  /// Accounts: accountTypeSavings
  ///
  /// In fr, this message translates to:
  /// **'Épargne'**
  String get accountTypeSavings;

  /// Accounts: accountNewTitle
  ///
  /// In fr, this message translates to:
  /// **'Nouveau compte'**
  String get accountNewTitle;

  /// Accounts: accountEditTitle
  ///
  /// In fr, this message translates to:
  /// **'Modifier le compte'**
  String get accountEditTitle;

  /// Accounts: accountTypeLabel
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get accountTypeLabel;

  /// Accounts: accountTypeCreate
  ///
  /// In fr, this message translates to:
  /// **'Créer un autre type'**
  String get accountTypeCreate;

  /// Accounts: accountName
  ///
  /// In fr, this message translates to:
  /// **'Nom du compte'**
  String get accountName;

  /// Accounts: accountNameHint
  ///
  /// In fr, this message translates to:
  /// **'M-Pesa, Rawbank, poche…'**
  String get accountNameHint;

  /// Accounts: accountOpening
  ///
  /// In fr, this message translates to:
  /// **'Solde de départ'**
  String get accountOpening;

  /// Accounts: accountCurrencyNote
  ///
  /// In fr, this message translates to:
  /// **'{name}. Touchez {code} pour changer de devise.'**
  String accountCurrencyNote(String name, String code);

  /// Accounts: accountOpeningDate
  ///
  /// In fr, this message translates to:
  /// **'Date du solde'**
  String get accountOpeningDate;

  /// Accounts: accountOpeningDateHelp
  ///
  /// In fr, this message translates to:
  /// **'Ce que contient le compte ce jour-là. Les opérations d’avant n’y changent rien.'**
  String get accountOpeningDateHelp;

  /// Accounts: accountToday
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui, {date}'**
  String accountToday(String date);

  /// Accounts: accountCreate
  ///
  /// In fr, this message translates to:
  /// **'Créer le compte'**
  String get accountCreate;

  /// Accounts: accountSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get accountSave;

  /// Accounts: accountArchive
  ///
  /// In fr, this message translates to:
  /// **'Archiver le compte'**
  String get accountArchive;

  /// Accounts: accountArchiveHelp
  ///
  /// In fr, this message translates to:
  /// **'Un compte archivé quitte les listes et les totaux ; ses opérations restent.'**
  String get accountArchiveHelp;

  /// Accounts: keypadDone
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get keypadDone;

  /// Accounts: typeNewTitle
  ///
  /// In fr, this message translates to:
  /// **'Nouveau type'**
  String get typeNewTitle;

  /// Accounts: typeName
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get typeName;

  /// Accounts: typeNameHint
  ///
  /// In fr, this message translates to:
  /// **'Tontine, carte prépayée…'**
  String get typeNameHint;

  /// Accounts: typeIcon
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get typeIcon;

  /// Accounts: typeSave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get typeSave;

  /// Accounts: accountsDisplay
  ///
  /// In fr, this message translates to:
  /// **'Affichage des comptes'**
  String get accountsDisplay;

  /// Accounts: accountsDisplayAmounts
  ///
  /// In fr, this message translates to:
  /// **'Montants'**
  String get accountsDisplayAmounts;

  /// Accounts: accountsDisplayEach
  ///
  /// In fr, this message translates to:
  /// **'Devise de chaque compte'**
  String get accountsDisplayEach;

  /// Accounts: accountsDisplayEachHelp
  ///
  /// In fr, this message translates to:
  /// **'Chaque compte reste dans sa devise'**
  String get accountsDisplayEachHelp;

  /// Accounts: accountsDisplayAll
  ///
  /// In fr, this message translates to:
  /// **'Tout en {name} ({code})'**
  String accountsDisplayAll(String name, String code);

  /// Accounts: accountsDisplayAllHelp
  ///
  /// In fr, this message translates to:
  /// **'Converti au dernier taux'**
  String get accountsDisplayAllHelp;

  /// Accounts: accountsDisplayNote
  ///
  /// In fr, this message translates to:
  /// **'Visible seulement quand vos comptes ont plusieurs devises.'**
  String get accountsDisplayNote;

  /// Accounts: accountsNoRate
  ///
  /// In fr, this message translates to:
  /// **'Pas de taux'**
  String get accountsNoRate;

  /// Accounts: accountsNoRateNote
  ///
  /// In fr, this message translates to:
  /// **'Sans taux, {codes} ne compte pas dans le total.'**
  String accountsNoRateNote(String codes);

  /// Accounts: accountsAddRate
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un taux'**
  String get accountsAddRate;

  /// Error under an empty account name.
  ///
  /// In fr, this message translates to:
  /// **'Donnez un nom au compte.'**
  String get accountNameMissing;

  /// Currencies: currencyKeptMain
  ///
  /// In fr, this message translates to:
  /// **'Votre devise principale'**
  String get currencyKeptMain;

  /// Currencies: currencyKeptAccount
  ///
  /// In fr, this message translates to:
  /// **'Utilisée par le compte {name}'**
  String currencyKeptAccount(String name);

  /// Currencies: currencyOther
  ///
  /// In fr, this message translates to:
  /// **'Autre devise…'**
  String get currencyOther;

  /// Devises in edit mode: currencyRemoveShort
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get currencyRemoveShort;

  /// Devises in edit mode: currencyKept
  ///
  /// In fr, this message translates to:
  /// **'Gardée'**
  String get currencyKept;

  /// Devises in edit mode: undo a struck currency.
  ///
  /// In fr, this message translates to:
  /// **'Garder'**
  String get currencyKeep;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
