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

  /// Transfer: its title, after the receiving account
  ///
  /// In fr, this message translates to:
  /// **'Vers {account}'**
  String transferTitle(String account);

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

  /// Setting: how long amounts are written.
  ///
  /// In fr, this message translates to:
  /// **'Montants longs'**
  String get longAmounts;

  /// Long amounts: shortened only when they do not fit.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get longAmountsAuto;

  /// Long amounts: under Automatique.
  ///
  /// In fr, this message translates to:
  /// **'Raccourcit seulement ce qui ne tient pas'**
  String get longAmountsAutoHelp;

  /// Long amounts: shortened from 10 000.
  ///
  /// In fr, this message translates to:
  /// **'Toujours'**
  String get longAmountsAlways;

  /// Long amounts: under Toujours.
  ///
  /// In fr, this message translates to:
  /// **'Dès 10 000 : 1,2 M au lieu de 1 245 000'**
  String get longAmountsAlwaysHelp;

  /// Long amounts: always whole.
  ///
  /// In fr, this message translates to:
  /// **'Jamais'**
  String get longAmountsNever;

  /// Long amounts: under Jamais.
  ///
  /// In fr, this message translates to:
  /// **'Toujours en entier, plus petit s’il le faut'**
  String get longAmountsNeverHelp;

  /// Long amounts: under the choices.
  ///
  /// In fr, this message translates to:
  /// **'La saisie, le détail d’une opération et les confirmations montrent toujours le montant entier.'**
  String get longAmountsNote;

  /// Under the list's title when the month does not start on the 1st.
  ///
  /// In fr, this message translates to:
  /// **'du {first} au {last}'**
  String listPeriod(String first, String last);

  /// Setting: the day a month starts on.
  ///
  /// In fr, this message translates to:
  /// **'Début du mois'**
  String get monthStart;

  /// Début du mois: under the title.
  ///
  /// In fr, this message translates to:
  /// **'Le jour où votre mois commence, par exemple le jour de la paie.'**
  String get monthStartHelp;

  /// Début du mois: the value in Réglages.
  ///
  /// In fr, this message translates to:
  /// **'{day, plural, =1{Le 1er} other{Le {day}}}'**
  String monthStartValue(int day);

  /// Début du mois: what the current month will cover.
  ///
  /// In fr, this message translates to:
  /// **'{month} ira du {first} au {last}.'**
  String monthStartPreview(String month, String first, String last);

  /// Début du mois: the button.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get monthStartSave;

  /// Budgets page title and Plus row.
  ///
  /// In fr, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// Budgets: none yet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun budget pour l’instant'**
  String get budgetsEmptyTitle;

  /// Budgets: none yet, the help.
  ///
  /// In fr, this message translates to:
  /// **'Fixez un montant par catégorie pour suivre vos dépenses.'**
  String get budgetsEmptyHelp;

  /// Budgets: the dashed button.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un budget'**
  String get budgetsAdd;

  /// Budgets summary: a period within one month, days only.
  ///
  /// In fr, this message translates to:
  /// **'du {first} au {last}'**
  String budgetsDays(String first, String last);

  /// Budgets summary: spent out of the budgets' total.
  ///
  /// In fr, this message translates to:
  /// **'{spent} sur {amount}'**
  String budgetsOutOf(String spent, String amount);

  /// Budgets: after an amount past its budget.
  ///
  /// In fr, this message translates to:
  /// **'de trop'**
  String get budgetsTooMuch;

  /// Budget tile: under what is left.
  ///
  /// In fr, this message translates to:
  /// **'restants sur {amount}'**
  String budgetsLeftOf(String amount);

  /// Budget tile: under what went past.
  ///
  /// In fr, this message translates to:
  /// **'de trop sur {amount}'**
  String budgetsOverOf(String amount);

  /// Budget row: spent out of its amount.
  ///
  /// In fr, this message translates to:
  /// **'{spent} dépensés sur {amount}'**
  String budgetsSpentOf(String spent, String amount);

  /// Budgets list group.
  ///
  /// In fr, this message translates to:
  /// **'Dépassés'**
  String get budgetsGroupOver;

  /// Budgets list group.
  ///
  /// In fr, this message translates to:
  /// **'Presque atteints'**
  String get budgetsGroupNear;

  /// Budgets list group.
  ///
  /// In fr, this message translates to:
  /// **'Dans les clous'**
  String get budgetsGroupOk;

  /// Budgets display sheet title.
  ///
  /// In fr, this message translates to:
  /// **'Affichage des budgets'**
  String get budgetsDisplay;

  /// Budgets display: layout section.
  ///
  /// In fr, this message translates to:
  /// **'Disposition'**
  String get budgetsLayout;

  /// Budgets display: tiles.
  ///
  /// In fr, this message translates to:
  /// **'Tuiles'**
  String get budgetsTiles;

  /// Budgets display: tiles help.
  ///
  /// In fr, this message translates to:
  /// **'Deux colonnes, ce qui reste en grand'**
  String get budgetsTilesHelp;

  /// Budgets display: list.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get budgetsList;

  /// Budgets display: list help.
  ///
  /// In fr, this message translates to:
  /// **'Une ligne par budget, groupée par état'**
  String get budgetsListHelp;

  /// Budgets display: order section.
  ///
  /// In fr, this message translates to:
  /// **'Ordre'**
  String get budgetsOrder;

  /// Budgets display: most used first.
  ///
  /// In fr, this message translates to:
  /// **'À surveiller'**
  String get budgetsWatch;

  /// Budgets display: watch help.
  ///
  /// In fr, this message translates to:
  /// **'Les plus consommés d’abord'**
  String get budgetsWatchHelp;

  /// Budgets display: the user's order.
  ///
  /// In fr, this message translates to:
  /// **'Mon ordre'**
  String get budgetsMine;

  /// Budgets display: own order help.
  ///
  /// In fr, this message translates to:
  /// **'Celui que vous choisissez, en glissant'**
  String get budgetsMineHelp;

  /// Budgets display: closes the sheet.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get budgetsDone;

  /// New budget screen title.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau budget'**
  String get budgetNew;

  /// Edit budget screen title.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le budget'**
  String get budgetEdit;

  /// Budget form: the amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant par mois'**
  String get budgetAmount;

  /// Budget form: the average under the amount.
  ///
  /// In fr, this message translates to:
  /// **'Vous dépensez en moyenne {amount} par mois en {category}'**
  String budgetAverage(String amount, String category);

  /// Budget form: category row.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get budgetCategory;

  /// Budget form: no category yet.
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get budgetChoose;

  /// Budget form: period row.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get budgetPeriod;

  /// Budget form: the period.
  ///
  /// In fr, this message translates to:
  /// **'Chaque mois'**
  String get budgetEveryMonth;

  /// Budget form: the note.
  ///
  /// In fr, this message translates to:
  /// **'Le reste ne se reporte pas sur le mois suivant.'**
  String get budgetNoCarry;

  /// Budget form: create.
  ///
  /// In fr, this message translates to:
  /// **'Créer le budget'**
  String get budgetCreate;

  /// Budget form: save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get budgetSave;

  /// Budget form: delete, in red.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le budget'**
  String get budgetDelete;

  /// Delete budget sheet title.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le budget {category} ?'**
  String budgetDeleteTitle(String category);

  /// Delete budget sheet: the consequence.
  ///
  /// In fr, this message translates to:
  /// **'Les opérations ne changent pas.'**
  String get budgetDeleteText;

  /// Delete budget sheet: the button.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get budgetDeleteConfirm;

  /// Budget form: a category that has one.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un budget'**
  String get budgetAlready;

  /// Code sheet reason when deleting a budget.
  ///
  /// In fr, this message translates to:
  /// **'Pour supprimer le budget {name}'**
  String protectDeleteBudget(String name);

  /// Budget detail: after the month.
  ///
  /// In fr, this message translates to:
  /// **'budget {amount}'**
  String budgetDetailBudget(String amount);

  /// Budget state badge.
  ///
  /// In fr, this message translates to:
  /// **'Dépassé'**
  String get budgetOver;

  /// Budget state badge.
  ///
  /// In fr, this message translates to:
  /// **'Presque atteint'**
  String get budgetNear;

  /// Budget detail: chart title.
  ///
  /// In fr, this message translates to:
  /// **'Au fil du mois'**
  String get budgetChart;

  /// Budget chart: running total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get budgetChartTotal;

  /// Budget chart: against the regular pace.
  ///
  /// In fr, this message translates to:
  /// **'Rythme'**
  String get budgetChartPace;

  /// Budget chart: the budget's line.
  ///
  /// In fr, this message translates to:
  /// **'Budget {amount}'**
  String budgetChartBudget(String amount);

  /// Budget chart legend.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé'**
  String get budgetLegendSpent;

  /// Budget chart legend.
  ///
  /// In fr, this message translates to:
  /// **'Hors budget'**
  String get budgetLegendOver;

  /// Budget chart legend.
  ///
  /// In fr, this message translates to:
  /// **'Rythme régulier'**
  String get budgetLegendPace;

  /// Budget chart legend.
  ///
  /// In fr, this message translates to:
  /// **'Trop vite'**
  String get budgetLegendFast;

  /// Budget chart legend.
  ///
  /// In fr, this message translates to:
  /// **'Marge'**
  String get budgetLegendSlow;

  /// Budget pace: spending faster than the pace.
  ///
  /// In fr, this message translates to:
  /// **'+{amount} d’avance'**
  String budgetAhead(String amount);

  /// Budget pace: spending slower than the pace.
  ///
  /// In fr, this message translates to:
  /// **'{amount} de marge'**
  String budgetMargin(String amount);

  /// Budget detail: the operations' title.
  ///
  /// In fr, this message translates to:
  /// **'Opérations du mois'**
  String get budgetOps;

  /// Budget detail: no expense.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dépense dans {category} ce mois-ci.'**
  String budgetNoOps(String category);

  /// Budget detail: opens the list filtered.
  ///
  /// In fr, this message translates to:
  /// **'Voir dans Opérations'**
  String get budgetSeeInList;

  /// Budget detail: opens the form.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get budgetEditAction;

  /// Category removal sheet: its budget goes too.
  ///
  /// In fr, this message translates to:
  /// **'Son budget de {amount} par mois est supprimé aussi.'**
  String confirmCategoryBudget(String amount);

  /// Sécurité: a recovery code shown but never retyped.
  ///
  /// In fr, this message translates to:
  /// **'Non vérifié'**
  String get securityRecoveryUnverified;

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour'**
  String get rhythmDaily;

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'Tous les {n} jours'**
  String rhythmEveryDays(String n);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'Chaque {days}'**
  String rhythmWeekly(String days);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'{days}, une semaine sur deux'**
  String rhythmEveryOtherWeek(String days);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'{days}, toutes les {n} semaines'**
  String rhythmEveryWeeks(String days, String n);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'Le {day} de chaque mois'**
  String rhythmMonthly(String day);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'Le {day}, tous les {n} mois'**
  String rhythmEveryMonths(String day, String n);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'Chaque {date}'**
  String rhythmYearly(String date);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'Le {date}, tous les {n} ans'**
  String rhythmEveryYears(String date, String n);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'sans fin'**
  String get rhythmEndNever;

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'{n} fois en tout'**
  String rhythmEndCount(String n);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'jusqu’au {date}'**
  String rhythmEndDate(String date);

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'et'**
  String get rhythmAnd;

  /// Recurrence rhythm text.
  ///
  /// In fr, this message translates to:
  /// **'le {day}'**
  String rhythmThe(String day);

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle récurrence'**
  String get recurrenceNew;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la récurrence'**
  String get recurrenceEdit;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Répéter'**
  String get repeatTitle;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get repeatDay;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get repeatWeek;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get repeatMonth;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get repeatYear;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Tous les jours} other{Tous les {n} jours}}'**
  String repeatEveryDay(int n);

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Toutes les semaines} other{Toutes les {n} semaines}}'**
  String repeatEveryWeek(int n);

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Tous les mois} other{Tous les {n} mois}}'**
  String repeatEveryMonth(int n);

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{Tous les ans} other{Tous les {n} ans}}'**
  String repeatEveryYear(int n);

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Première fois'**
  String get repeatFirst;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get repeatEnd;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Jamais'**
  String get repeatEndNever;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Après X fois'**
  String get repeatEndCount;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'À une date'**
  String get repeatEndDate;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de fois'**
  String get repeatCount;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Dernière date possible'**
  String get repeatLastDate;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'La récurrence continue jusqu’à ce que vous l’arrêtiez.'**
  String get repeatEndNeverHelp;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Utile pour un crédit ou des mensualités : elle s’arrête toute seule.'**
  String get repeatEndCountHelp;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération ne sera créée après cette date.'**
  String get repeatEndDateHelp;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines dates : {dates}'**
  String repeatNext(String dates);

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'À chaque échéance'**
  String get repeatEach;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get repeatModeSave;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Préparer un brouillon'**
  String get repeatModeDraft;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'L’opération est ajoutée automatiquement à sa date.'**
  String get repeatModeSaveHelp;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Un brouillon attend votre validation, utile si le montant varie.'**
  String get repeatModeDraftHelp;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Jamais'**
  String get repeatNever;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Ne plus répéter'**
  String get repeatStop;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Moins'**
  String get repeatLess;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get repeatMore;

  /// Recurrence form.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get repeatSave;

  /// Nouvelle récurrence: the amount in what repeats.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get entryAmount;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Récurrences'**
  String get recurrencesTitle;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get recurrencesExpenses;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get recurrencesIncome;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Transferts'**
  String get recurrencesTransfers;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Aucune récurrence pour l’instant'**
  String get recurrencesEmptyTitle;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Loyer, salaire, abonnements : notez-les une fois, kibuo s’en souvient.'**
  String get recurrencesEmptyHelp;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'À valider'**
  String get recurrenceToValidate;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'le {date}'**
  String recurrenceNextOn(String date);

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Récurrence'**
  String get recurrenceTitle;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get recurrenceEditAction;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Prochaines fois'**
  String get recurrenceNextTimes;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Dernières fois'**
  String get recurrencePast;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Ignoré'**
  String get recurrenceIgnored;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get recurrenceDraft;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la récurrence'**
  String get recurrenceStop;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la récurrence {name} ?'**
  String recurrenceStopTitle(String name);

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui a déjà été créé reste ; les brouillons en attente sont supprimés.'**
  String get recurrenceStopText;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get recurrenceStopAction;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'vers {name}'**
  String recurrenceToAccount(String name);

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Préparer un brouillon'**
  String get recurrenceAskDraft;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get recurrenceSaveDirect;

  /// Recurrences page and card.
  ///
  /// In fr, this message translates to:
  /// **'Plus de prochaine fois'**
  String get recurrenceNone;

  /// Home: what can be spent freely, all accounts together.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get homeAvailable;

  /// Home: the line under the available amount.
  ///
  /// In fr, this message translates to:
  /// **'à dépenser librement'**
  String get homeAvailableHelp;

  /// Home: what touching the available amount does, for screen readers.
  ///
  /// In fr, this message translates to:
  /// **'Voir mes comptes'**
  String get homeOpenAccounts;

  /// Home: after the month's name in the month card.
  ///
  /// In fr, this message translates to:
  /// **'ce mois-ci'**
  String get homeThisMonth;

  /// Home: after what is left of the month's income.
  ///
  /// In fr, this message translates to:
  /// **'restants'**
  String get homeLeft;

  /// Home: the month's exits out of its entries.
  ///
  /// In fr, this message translates to:
  /// **'{out} sur {income}'**
  String homeOutOfIn(String out, String income);

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
  /// **'kibuo demandera ce code à chaque ouverture.'**
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
  /// **'Ouvrir kibuo avec votre empreinte ?'**
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
  /// **'Ouvrir kibuo'**
  String get fingerprintReason;

  /// Option in the forgotten-code sheet.
  ///
  /// In fr, this message translates to:
  /// **'Effacer et repartir de zéro'**
  String get forgotErase;

  /// Warning before erasing.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les données de kibuo sur ce téléphone seront effacées. Vous pourrez ensuite restaurer une sauvegarde, si vous en avez une.'**
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
  /// **'Sans code, kibuo s’ouvre directement. Vos données restent chiffrées.'**
  String get lockRemoveHelp;

  /// Privacy switch.
  ///
  /// In fr, this message translates to:
  /// **'Masquer kibuo dans les applications récentes'**
  String get privacyHideRecents;

  /// Privacy switch.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser les captures d’écran'**
  String get privacyScreenshots;

  /// Help under the privacy switches.
  ///
  /// In fr, this message translates to:
  /// **'Masqué, l’aperçu des applications récentes montre le logo de kibuo au lieu de vos soldes.'**
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
  /// **'Il rend l’accès à kibuo si vous oubliez votre code et que l’empreinte ne marche pas, et il rouvre vos données sur un nouveau téléphone. Notez-le sur papier et gardez-le en lieu sûr.'**
  String get recoveryShowBody;

  /// Warning under the new code.
  ///
  /// In fr, this message translates to:
  /// **'kibuo ne le garde pas : il ne pourra plus vous le montrer.'**
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
  /// **'Ouvrir kibuo'**
  String get recoveryOpen;

  /// In the forgotten-code sheet.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser le code de récupération'**
  String get recoveryUse;

  /// On the recovery settings page.
  ///
  /// In fr, this message translates to:
  /// **'kibuo ne le garde pas : vous seul le connaissez.'**
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
  /// **'Sans code de récupération, un code oublié ou un nouveau téléphone obligent à repartir de zéro, et Android ne copie pas les données de kibuo.'**
  String get recoveryCreateHelp;

  /// Switch for Android backup and transfer.
  ///
  /// In fr, this message translates to:
  /// **'Laisser Android copier kibuo'**
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

  /// Categories: categoryName
  ///
  /// In fr, this message translates to:
  /// **'{key, select, food{Repas} restaurant{Restaurant} market{Marché} transport{Transport} taxi{Taxi} motoTaxi{Moto-taxi} bus{Bus} fuel{Carburant} toll{Péage} groceries{Courses} housing{Logement} rent{Loyer} electricity{Électricité} water{Eau} communication{Communication} airtime{Crédit} internet{Internet} health{Santé} pharmacy{Pharmacie} school{École} family{Famille} outings{Sorties} contributions{Cotisations} otherExpense{Autres} salary{Salaire} business{Activité} sale{Vente} service{Prestation} giftReceived{Cadeau reçu} refund{Remboursement} otherIncome{Autres} adjustExpense{Régularisation} adjustIncome{Régularisation} debtIn{Dette} debtOut{Dette} receivableIn{Créance} receivableOut{Créance} other{}}'**
  String categoryName(String key);

  /// Categories: categoriesTitle
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categoriesTitle;

  /// Categories: categoriesExpenses
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get categoriesExpenses;

  /// Categories: categoriesIncome
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get categoriesIncome;

  /// Categories: categoriesSubCount
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 sous-catégorie} other{{count} sous-catégories}}'**
  String categoriesSubCount(int count);

  /// Categories: categoriesAddSub
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une sous-catégorie'**
  String get categoriesAddSub;

  /// Categories: categoriesAdd
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une catégorie'**
  String get categoriesAdd;

  /// Categories: categoryNewTitle
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle catégorie'**
  String get categoryNewTitle;

  /// Categories: categoryNewSubTitle
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle sous-catégorie'**
  String get categoryNewSubTitle;

  /// Categories: categoryEditTitle
  ///
  /// In fr, this message translates to:
  /// **'Modifier la catégorie'**
  String get categoryEditTitle;

  /// Categories: categoryEditSubTitle
  ///
  /// In fr, this message translates to:
  /// **'Modifier la sous-catégorie'**
  String get categoryEditSubTitle;

  /// Categories: categoryIn
  ///
  /// In fr, this message translates to:
  /// **'Dans'**
  String get categoryIn;

  /// Categories: categoryNameLabel
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get categoryNameLabel;

  /// Categories: categoryIcon
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get categoryIcon;

  /// Categories: categoryCreate
  ///
  /// In fr, this message translates to:
  /// **'Créer la catégorie'**
  String get categoryCreate;

  /// Categories: categoryCreateSub
  ///
  /// In fr, this message translates to:
  /// **'Créer la sous-catégorie'**
  String get categoryCreateSub;

  /// Categories: categorySave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get categorySave;

  /// Categories: categoryRemove
  ///
  /// In fr, this message translates to:
  /// **'Retirer la catégorie'**
  String get categoryRemove;

  /// Categories: categoryRemoveSub
  ///
  /// In fr, this message translates to:
  /// **'Retirer la sous-catégorie'**
  String get categoryRemoveSub;

  /// Categories: categoryRemoveHelp
  ///
  /// In fr, this message translates to:
  /// **'Elle disparaît des choix ; ses opérations la gardent.'**
  String get categoryRemoveHelp;

  /// Categories: categoryRemoveSubsToo
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Sa sous-catégorie est retirée avec elle.} other{Ses {count} sous-catégories sont retirées avec elle.}}'**
  String categoryRemoveSubsToo(int count);

  /// Categories: categoryNameHint
  ///
  /// In fr, this message translates to:
  /// **'Église, Moto-taxi…'**
  String get categoryNameHint;

  /// Devises in edit mode: why a currency stays.
  ///
  /// In fr, this message translates to:
  /// **'Utilisée par une opération'**
  String get currencyKeptTransaction;

  /// Entry: entryNewExpense
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dépense'**
  String get entryNewExpense;

  /// Entry: entryNewIncome
  ///
  /// In fr, this message translates to:
  /// **'Nouveau revenu'**
  String get entryNewIncome;

  /// Entry: entryEditExpense
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dépense'**
  String get entryEditExpense;

  /// Entry: entryEditIncome
  ///
  /// In fr, this message translates to:
  /// **'Modifier le revenu'**
  String get entryEditIncome;

  /// Entry: entryExpense
  ///
  /// In fr, this message translates to:
  /// **'Dépense'**
  String get entryExpense;

  /// Entry: entryIncome
  ///
  /// In fr, this message translates to:
  /// **'Revenu'**
  String get entryIncome;

  /// Entry: entryTakenFrom
  ///
  /// In fr, this message translates to:
  /// **'Retiré du compte'**
  String get entryTakenFrom;

  /// Entry: entryAddedTo
  ///
  /// In fr, this message translates to:
  /// **'Ajouté au compte'**
  String get entryAddedTo;

  /// Entry: entryAccount
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get entryAccount;

  /// Entry: entryCategory
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get entryCategory;

  /// Entry: entryDate
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get entryDate;

  /// Entry: entryFees
  ///
  /// In fr, this message translates to:
  /// **'Frais'**
  String get entryFees;

  /// Entry: entryNone
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get entryNone;

  /// Entry: entryChoose
  ///
  /// In fr, this message translates to:
  /// **'Choisir'**
  String get entryChoose;

  /// Entry: entryNote
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get entryNote;

  /// Entry: entryNoteHint
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une note'**
  String get entryNoteHint;

  /// Entry: entryToday
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get entryToday;

  /// Entry: entryYesterday
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get entryYesterday;

  /// Entry: entrySave
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get entrySave;

  /// Entry: entrySaveChanges
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get entrySaveChanges;

  /// Entry: entryPaidCurrency
  ///
  /// In fr, this message translates to:
  /// **'Devise payée'**
  String get entryPaidCurrency;

  /// Entry: entryReceivedCurrency
  ///
  /// In fr, this message translates to:
  /// **'Devise reçue'**
  String get entryReceivedCurrency;

  /// Entry: entryCurrencyHelp
  ///
  /// In fr, this message translates to:
  /// **'Le compte {account} est en {currency}.'**
  String entryCurrencyHelp(String account, String currency);

  /// Entry: entryAccountCurrency
  ///
  /// In fr, this message translates to:
  /// **'La devise du compte, pas de conversion'**
  String get entryAccountCurrency;

  /// Entry: entryConverted
  ///
  /// In fr, this message translates to:
  /// **'Converti au taux choisi'**
  String get entryConverted;

  /// Entry: entryRateTitle
  ///
  /// In fr, this message translates to:
  /// **'Taux de conversion'**
  String get entryRateTitle;

  /// Entry: entryPaid
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get entryPaid;

  /// Entry: entryReceived
  ///
  /// In fr, this message translates to:
  /// **'Reçu'**
  String get entryReceived;

  /// Entry: entryRateToday
  ///
  /// In fr, this message translates to:
  /// **'Taux du jour'**
  String get entryRateToday;

  /// Entry: entryRateTodayHelp
  ///
  /// In fr, this message translates to:
  /// **'Votre taux en cours, dans Devises'**
  String get entryRateTodayHelp;

  /// Entry: entryRateTodayMissing
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de taux dans Devises'**
  String get entryRateTodayMissing;

  /// Entry: entryRateOther
  ///
  /// In fr, this message translates to:
  /// **'Autre taux'**
  String get entryRateOther;

  /// Entry: entryRateOtherHelp
  ///
  /// In fr, this message translates to:
  /// **'Tapez le taux du changeur'**
  String get entryRateOtherHelp;

  /// Entry: entryRateFor
  ///
  /// In fr, this message translates to:
  /// **'Taux pour 1 {symbol}'**
  String entryRateFor(String symbol);

  /// Entry: entryRateTodayTag
  ///
  /// In fr, this message translates to:
  /// **'Du jour'**
  String get entryRateTodayTag;

  /// Entry: entryRateTypedTag
  ///
  /// In fr, this message translates to:
  /// **'Personnalisé'**
  String get entryRateTypedTag;

  /// Entry: entrySo
  ///
  /// In fr, this message translates to:
  /// **'Soit'**
  String get entrySo;

  /// Entry: entryFeesTitle
  ///
  /// In fr, this message translates to:
  /// **'Frais supplémentaires'**
  String get entryFeesTitle;

  /// Entry: entrySavedExpense
  ///
  /// In fr, this message translates to:
  /// **'Dépense enregistrée'**
  String get entrySavedExpense;

  /// Entry: entrySavedIncome
  ///
  /// In fr, this message translates to:
  /// **'Revenu enregistré'**
  String get entrySavedIncome;

  /// Entry: entryUndoEdit
  ///
  /// In fr, this message translates to:
  /// **'Annuler et modifier'**
  String get entryUndoEdit;

  /// Entry: entryClosesSoon
  ///
  /// In fr, this message translates to:
  /// **'Se ferme seule dans un instant'**
  String get entryClosesSoon;

  /// Entry: entryRateFrozen
  ///
  /// In fr, this message translates to:
  /// **'Taux figé pour 1 {symbol}'**
  String entryRateFrozen(String symbol);

  /// Entry: entryDuplicate
  ///
  /// In fr, this message translates to:
  /// **'Dupliquer'**
  String get entryDuplicate;

  /// Entry: entryPaidChip
  ///
  /// In fr, this message translates to:
  /// **'{amount} payés · {rate}'**
  String entryPaidChip(String amount, String rate);

  /// Entry: entryReceivedChip
  ///
  /// In fr, this message translates to:
  /// **'{amount} reçus · {rate}'**
  String entryReceivedChip(String amount, String rate);

  /// Entry: entryReadNote
  ///
  /// In fr, this message translates to:
  /// **'Lire toute la note'**
  String get entryReadNote;

  /// Entry: entryNoAccount
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez d’abord un compte.'**
  String get entryNoAccount;

  /// Entry: categorySearch
  ///
  /// In fr, this message translates to:
  /// **'Chercher une catégorie'**
  String get categorySearch;

  /// Entry: operationsTitle
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get operationsTitle;

  /// Entry: operationsEmpty
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération pour l’instant. Le + en ajoute une.'**
  String get operationsEmpty;

  /// Entry: entryFirstAccountTitle
  ///
  /// In fr, this message translates to:
  /// **'D’abord, un compte'**
  String get entryFirstAccountTitle;

  /// Entry: entryFirstAccountExpense
  ///
  /// In fr, this message translates to:
  /// **'Chaque dépense sort d’un compte, et chaque revenu y arrive : votre poche, votre mobile money, votre banque. Créez le premier, puis notez votre dépense.'**
  String get entryFirstAccountExpense;

  /// Entry: entryFirstAccountIncome
  ///
  /// In fr, this message translates to:
  /// **'Chaque dépense sort d’un compte, et chaque revenu y arrive : votre poche, votre mobile money, votre banque. Créez le premier, puis notez votre revenu.'**
  String get entryFirstAccountIncome;

  /// Entry: entryFirstAccountAction
  ///
  /// In fr, this message translates to:
  /// **'Créer mon premier compte'**
  String get entryFirstAccountAction;

  /// Entry: entryFirstCategoryTitle
  ///
  /// In fr, this message translates to:
  /// **'D’abord, une catégorie'**
  String get entryFirstCategoryTitle;

  /// Entry: entryFirstCategoryExpense
  ///
  /// In fr, this message translates to:
  /// **'Chaque dépense se range dans une catégorie : repas, transport, loyer… Créez-en une, puis notez votre dépense.'**
  String get entryFirstCategoryExpense;

  /// Entry: entryFirstCategoryIncome
  ///
  /// In fr, this message translates to:
  /// **'Chaque revenu se range dans une catégorie : salaire, ventes… Créez-en une, puis notez votre revenu.'**
  String get entryFirstCategoryIncome;

  /// Entry: entryFirstCategoryAction
  ///
  /// In fr, this message translates to:
  /// **'Créer une catégorie'**
  String get entryFirstCategoryAction;

  /// Entry: entryLater
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get entryLater;

  /// Operation detail: red action under Dupliquer
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l’opération'**
  String get entryDeleteOperation;

  /// Entry: entryDeleteExpenseTitle
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette dépense ?'**
  String get entryDeleteExpenseTitle;

  /// Entry: entryDeleteIncomeTitle
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce revenu ?'**
  String get entryDeleteIncomeTitle;

  /// Entry: entryDeleteExpenseHelp
  ///
  /// In fr, this message translates to:
  /// **'Elle disparaît de la liste et le solde de {account} reprend {amount}.'**
  String entryDeleteExpenseHelp(String account, String amount);

  /// Entry: entryDeleteIncomeHelp
  ///
  /// In fr, this message translates to:
  /// **'Il disparaît de la liste et le solde de {account} perd {amount}.'**
  String entryDeleteIncomeHelp(String account, String amount);

  /// Entry: entryDeleteConfirm
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get entryDeleteConfirm;

  /// Attachments: attachTitle
  ///
  /// In fr, this message translates to:
  /// **'Pièces jointes'**
  String get attachTitle;

  /// Attachments: attachAdd
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get attachAdd;

  /// Attachments: attachEmpty
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une pièce jointe'**
  String get attachEmpty;

  /// Attachments: attachEmptyHelp
  ///
  /// In fr, this message translates to:
  /// **'Photo d’un reçu ou document, 5 au plus'**
  String get attachEmptyHelp;

  /// Attachments: attachPhoto
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get attachPhoto;

  /// Attachments: attachGallery
  ///
  /// In fr, this message translates to:
  /// **'Choisir dans la galerie'**
  String get attachGallery;

  /// Attachments: attachFile
  ///
  /// In fr, this message translates to:
  /// **'Choisir un fichier'**
  String get attachFile;

  /// Attachments: attachKindPhoto
  ///
  /// In fr, this message translates to:
  /// **'Photo'**
  String get attachKindPhoto;

  /// Attachments: attachKindPdf
  ///
  /// In fr, this message translates to:
  /// **'PDF'**
  String get attachKindPdf;

  /// Attachments: attachKindFile
  ///
  /// In fr, this message translates to:
  /// **'Fichier'**
  String get attachKindFile;

  /// Attachments: attachTooBig
  ///
  /// In fr, this message translates to:
  /// **'Ce fichier dépasse 10 Mo : choisissez-en un plus léger.'**
  String get attachTooBig;

  /// Attachments: attachChosen
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 choisie} other{{count} choisies}}'**
  String attachChosen(int count);

  /// Attachments: attachRemove
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get attachRemove;

  /// Attachments: opens the one chosen attachment
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get attachView;

  /// Attachments viewer: hands the file to another app
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir avec…'**
  String get attachOpenWith;

  /// Attachments viewer: under a PDF's first page
  ///
  /// In fr, this message translates to:
  /// **'Page 1 sur {pages}'**
  String attachPage(int pages);

  /// Attachments viewer: no app opens the file
  ///
  /// In fr, this message translates to:
  /// **'Aucune appli du téléphone n\'ouvre ce fichier.'**
  String get attachNoApp;

  /// Attachments: attachPhotoName
  ///
  /// In fr, this message translates to:
  /// **'Photo {n}'**
  String attachPhotoName(int n);

  /// Entry: the transfer tab
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get entryTransfer;

  /// Entry: title
  ///
  /// In fr, this message translates to:
  /// **'Nouveau transfert'**
  String get entryNewTransfer;

  /// Entry: title
  ///
  /// In fr, this message translates to:
  /// **'Modifier le transfert'**
  String get entryEditTransfer;

  /// Transfer: the sending account
  ///
  /// In fr, this message translates to:
  /// **'De'**
  String get transferFrom;

  /// Transfer: the receiving account
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get transferTo;

  /// Transfer: account sheet help
  ///
  /// In fr, this message translates to:
  /// **'Vers quel compte ?'**
  String get transferToQuestion;

  /// Transfer: amount sent
  ///
  /// In fr, this message translates to:
  /// **'Envoyé'**
  String get transferSent;

  /// Transfer: what reaches the account
  ///
  /// In fr, this message translates to:
  /// **'Arrive sur {account}'**
  String transferArrives(String account);

  /// Transfer: total taken from the sender
  ///
  /// In fr, this message translates to:
  /// **'Retiré de {account}'**
  String transferTakenFrom(String account);

  /// Transfer: saved sheet
  ///
  /// In fr, this message translates to:
  /// **'Transfert enregistré'**
  String get transferSaved;

  /// Transfer: saved sheet line
  ///
  /// In fr, this message translates to:
  /// **'{from} vers {to} · {when}'**
  String transferSavedSub(String from, String to, String when);

  /// Transfer: saved sheet action
  ///
  /// In fr, this message translates to:
  /// **'Nouveau transfert'**
  String get transferAnother;

  /// Transfer: under its title in the detail
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get transferKind;

  /// Transfer detail: sending account label
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get transferDepuis;

  /// Transfer detail: chip when converted
  ///
  /// In fr, this message translates to:
  /// **'{amount} arrivés · {rate}'**
  String transferArrivedChip(String amount, String rate);

  /// Transfer: no account yet
  ///
  /// In fr, this message translates to:
  /// **'Un transfert déplace de l’argent entre deux de vos comptes : votre poche, votre mobile money, votre banque. Créez le premier, puis un deuxième.'**
  String get transferFirstAccountText;

  /// Transfer: one account only
  ///
  /// In fr, this message translates to:
  /// **'D’abord, un deuxième compte'**
  String get transferSecondTitle;

  /// Transfer: one account only
  ///
  /// In fr, this message translates to:
  /// **'Un transfert déplace de l’argent entre deux de vos comptes. Créez-en un deuxième, puis notez votre transfert.'**
  String get transferSecondText;

  /// Transfer: one account only
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get transferSecondAction;

  /// Delete sheet title
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce transfert ?'**
  String get entryDeleteTransferTitle;

  /// Delete sheet help
  ///
  /// In fr, this message translates to:
  /// **'Il disparaît de la liste : {from} reprend {withdrawn} et {to} perd {arrived}.'**
  String entryDeleteTransferHelp(
    String from,
    String withdrawn,
    String to,
    String arrived,
  );

  /// Account form: section label
  ///
  /// In fr, this message translates to:
  /// **'Découvert'**
  String get overdraftLabel;

  /// Account form: switch
  ///
  /// In fr, this message translates to:
  /// **'Autoriser le découvert'**
  String get overdraftAllow;

  /// Account form: switch help
  ///
  /// In fr, this message translates to:
  /// **'Le solde peut descendre sous zéro'**
  String get overdraftAllowHelp;

  /// Account form: limit field
  ///
  /// In fr, this message translates to:
  /// **'Jusqu’à'**
  String get overdraftUpTo;

  /// Account form: limit help
  ///
  /// In fr, this message translates to:
  /// **'Vide ou 0 : sans limite.'**
  String get overdraftNoLimitHelp;

  /// Account form: limit placeholder
  ///
  /// In fr, this message translates to:
  /// **'Sans limite'**
  String get overdraftNoLimit;

  /// Account form: overdraft off while below zero
  ///
  /// In fr, this message translates to:
  /// **'{account} est à {balance} : aucune sortie ne passera tant qu’il ne sera pas remonté. Les entrées restent possibles.'**
  String overdraftBelowZero(String account, String balance);

  /// Accounts list caption
  ///
  /// In fr, this message translates to:
  /// **'Découvert jusqu’à {amount}'**
  String overdraftCaptionUpTo(String amount);

  /// Accounts list caption
  ///
  /// In fr, this message translates to:
  /// **'Découvert sans limite'**
  String get overdraftCaptionNoLimit;

  /// Entry refused: what may still leave
  ///
  /// In fr, this message translates to:
  /// **'{amount} disponibles sur {account}'**
  String overdraftAvailable(String amount, String account);

  /// Entry refused: opens the account form
  ///
  /// In fr, this message translates to:
  /// **'Autoriser'**
  String get overdraftAuthorize;

  /// Delete refused
  ///
  /// In fr, this message translates to:
  /// **'{account} passerait à {amount}'**
  String overdraftWouldGo(String account, String amount);

  /// Account form: today's balance
  ///
  /// In fr, this message translates to:
  /// **'Solde actuel'**
  String get accountCurrentBalance;

  /// Account form: under Solde actuel
  ///
  /// In fr, this message translates to:
  /// **'Dans kibuo aujourd’hui : {balance}. Tapez ce que contient vraiment le compte.'**
  String accountCurrentHelp(String balance);

  /// Adjustment sheet title
  ///
  /// In fr, this message translates to:
  /// **'Corriger le solde de {account} ?'**
  String adjustTitle(String account);

  /// Adjustment sheet: balance before
  ///
  /// In fr, this message translates to:
  /// **'Dans kibuo'**
  String get adjustInKibuo;

  /// Adjustment sheet: balance typed
  ///
  /// In fr, this message translates to:
  /// **'Solde réel'**
  String get adjustReal;

  /// Adjustment sheet help
  ///
  /// In fr, this message translates to:
  /// **'La différence est ajoutée comme une opération, que vous pourrez modifier ensuite.'**
  String get adjustHelp;

  /// Note of an adjustment
  ///
  /// In fr, this message translates to:
  /// **'Solde corrigé : {before} → {after}'**
  String adjustNote(String before, String after);

  /// Adjustment sheet button
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la régularisation'**
  String get adjustAdd;

  /// Verrouillage: protect important actions
  ///
  /// In fr, this message translates to:
  /// **'Code pour les actions importantes'**
  String get lockProtect;

  /// Verrouillage: under the switch
  ///
  /// In fr, this message translates to:
  /// **'Supprimer, archiver, corriger un solde'**
  String get lockProtectHelp;

  /// Code sheet title
  ///
  /// In fr, this message translates to:
  /// **'Confirmez avec votre code'**
  String get protectTitle;

  /// Code sheet reason
  ///
  /// In fr, this message translates to:
  /// **'Pour archiver {name}'**
  String protectArchive(String name);

  /// Code sheet reason
  ///
  /// In fr, this message translates to:
  /// **'Pour supprimer l’opération'**
  String get protectDeleteOperation;

  /// Code sheet reason
  ///
  /// In fr, this message translates to:
  /// **'Pour supprimer {name}'**
  String protectDeleteCategory(String name);

  /// Code sheet reason
  ///
  /// In fr, this message translates to:
  /// **'Pour retirer {count, plural, =1{une devise} other{{count} devises}}'**
  String protectRemoveCurrencies(int count);

  /// Code sheet reason
  ///
  /// In fr, this message translates to:
  /// **'Pour corriger le solde de {name}'**
  String protectAdjust(String name);

  /// Code sheet reason
  ///
  /// In fr, this message translates to:
  /// **'Pour changer le découvert de {name}'**
  String protectOverdraft(String name);

  /// Confirm sheet
  ///
  /// In fr, this message translates to:
  /// **'Archiver {name} ?'**
  String confirmArchiveTitle(String name);

  /// Confirm sheet
  ///
  /// In fr, this message translates to:
  /// **'{name} quitte les listes et les totaux. Ses opérations restent.'**
  String confirmArchiveHelp(String name);

  /// Confirm sheet button
  ///
  /// In fr, this message translates to:
  /// **'Archiver le compte'**
  String get confirmArchiveAction;

  /// Confirm sheet
  ///
  /// In fr, this message translates to:
  /// **'Supprimer {name} ?'**
  String confirmCategoryTitle(String name);

  /// Confirm sheet
  ///
  /// In fr, this message translates to:
  /// **'{subs, plural, =0{{name} disparaît des choix. Les opérations déjà notées la gardent.} =1{{name} et sa sous-catégorie disparaissent des choix. Les opérations déjà notées les gardent.} other{{name} et ses {subs} sous-catégories disparaissent des choix. Les opérations déjà notées les gardent.}}'**
  String confirmCategoryHelp(String name, int subs);

  /// Confirm sheet button
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la catégorie'**
  String get confirmCategoryAction;

  /// Confirm sheet
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Retirer une devise ?} other{Retirer {count} devises ?}}'**
  String confirmCurrenciesTitle(int count);

  /// Confirm sheet
  ///
  /// In fr, this message translates to:
  /// **'{names} ne {count, plural, =1{sera} other{seront}} plus {count, plural, =1{proposé} other{proposés}}.'**
  String confirmCurrenciesHelp(String names, int count);

  /// Confirm sheet button
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get confirmCurrenciesAction;

  /// Account form: how to type a negative balance
  ///
  /// In fr, this message translates to:
  /// **'Maintenez « , » pour un solde négatif.'**
  String get accountMinusHint;

  /// + sheet: the latest operations to do again
  ///
  /// In fr, this message translates to:
  /// **'Refaire'**
  String get addRedo;

  /// Tip bubble over + after a few openings
  ///
  /// In fr, this message translates to:
  /// **'Astuce : maintenez + puis glissez vers un choix, sans lever le doigt.'**
  String get plusHoldTip;

  /// Tip bubble button
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get plusHoldTipDone;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get listEntries;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Sorties'**
  String get listExits;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'{percent} % dépensés'**
  String listSpent(int percent);

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get listRest;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Ce mois-ci'**
  String get listThisMonth;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get filterType;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get filterAccount;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get filterCategory;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filterAll;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'{count} types'**
  String filterTypes(int count);

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'{count} comptes'**
  String filterAccounts(int count);

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'{count} catégories'**
  String filterCategories(int count);

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération'**
  String get emptyMonthTitle;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Les dépenses, revenus et transferts de {month} apparaîtront ici.'**
  String emptyMonthHelp(String month);

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Rien avec ces filtres'**
  String get emptyFilterTitle;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Essayez d’autres choix, ou effacez les filtres.'**
  String get emptyFilterHelp;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Effacer les filtres'**
  String get clearFilters;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Revenir au mois en cours'**
  String get backToThisMonth;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Changez de mois d’un geste'**
  String get swipeTipTitle;

  /// Operations list
  ///
  /// In fr, this message translates to:
  /// **'Glissez la liste vers la droite pour le mois d’avant, vers la gauche pour le mois suivant. Ou touchez le titre du mois.'**
  String get swipeTipText;

  /// The first choice of the Type filter.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get filterAllType;

  /// The first choice of the Catégorie filter.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get filterAllCategories;

  /// The Type filter: expenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get filterExpenses;

  /// The Type filter: income.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get filterIncomes;

  /// The Type filter: transfers.
  ///
  /// In fr, this message translates to:
  /// **'Transferts'**
  String get filterTransfers;

  /// Opens all the categories, those without operations this month too.
  ///
  /// In fr, this message translates to:
  /// **'Afficher les {count} autres'**
  String filterMore(int count);

  /// In the totals card: exits but no entry this month.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée'**
  String get listNoEntries;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get listSearch;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Libellé, catégorie, compte, montant'**
  String get searchHint;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Fermer la recherche'**
  String get searchClose;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Effacer la recherche'**
  String get searchClear;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Recherches récentes'**
  String get searchRecent;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get searchRecentClear;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Chercher par'**
  String get searchBy;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'La recherche porte sur tous les mois : libellé, catégorie, compte, note et montant.'**
  String get searchHelp;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 résultat} other{{count} résultats}}'**
  String searchResults(int count);

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 autre résultat} other{{count} autres résultats}}'**
  String searchOthers(int count);

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Dans les mois précédents'**
  String get searchEarlierMonths;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Dans les autres mois'**
  String get searchOtherMonths;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Mois précédents · {count}'**
  String searchEarlierFold(int count);

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Autres mois · {count}'**
  String searchOtherFold(int count);

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Replier'**
  String get searchFold;

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Rien en {month} pour « {query} ».'**
  String searchNothingInMonth(String month, String query);

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour « {query} »'**
  String searchNoResultTitle(String query);

  /// Operations search
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez l’orthographe ou cherchez un montant.'**
  String get searchNoResultHelp;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur kibuo'**
  String get firstWelcome;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Vos comptes, vos dettes et vos projets, au même endroit. Vos données restent sur votre téléphone.'**
  String get firstWelcomeText;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre langue'**
  String get firstLanguage;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get firstContinue;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Étape {step} sur {count}'**
  String firstStep(int step, int count);

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Votre devise principale'**
  String get firstCurrencyTitle;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Elle sert au suivi et aux rapports. Chaque compte gardera sa propre devise.'**
  String get firstCurrencyText;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une devise'**
  String get firstCurrencySearch;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Nom ou code'**
  String get firstCurrencySearchHint;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Votre premier compte'**
  String get firstAccountTitle;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Commencez par celui que vous utilisez le plus. Vous pourrez en ajouter d’autres ensuite.'**
  String get firstAccountText;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Protégez vos données'**
  String get firstProtectTitle;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Vos données restent sur ce téléphone. Sans sauvegarde, elles sont perdues si vous le perdez.'**
  String get firstProtectText;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Verrouiller l’application'**
  String get firstLockTitle;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'PIN ou empreinte. Un code de récupération vous sera remis.'**
  String get firstLockHelp;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Vous pourrez changer ces choix à tout moment dans les réglages.'**
  String get firstLater;

  /// First launch
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get firstStart;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get draftLabel;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get draftIgnore;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get draftValidate;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Prévu'**
  String get plannedTag;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Validé : {name}, compté dans le mois'**
  String draftValidated(String name);

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Ignoré : {name}. Validez-le depuis son détail.'**
  String draftIgnoredToast(String name);

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'À valider · {count}'**
  String draftsToValidate(String count);

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Récurrence · {account}'**
  String draftFromRecurrence(String account);

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'{status, select, ignored{Ignoré} other{Brouillon}} · récurrence {unit, select, day{quotidienne} week{hebdomadaire} year{annuelle} other{mensuelle}}'**
  String draftStatus(String status, String unit);

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Prévu aujourd’hui, {date}'**
  String draftDueToday(String date);

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Prévu hier, {date}'**
  String draftDueYesterday(String date);

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Prévu le {date}'**
  String draftDueOn(String date);

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Cette opération attend votre accord. Vérifiez le montant, il varie parfois, puis validez pour l’ajouter au compte.'**
  String get draftNotice;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Vous l’avez ignorée pour cette fois : elle ne compte pas dans le compte. Si elle a bien eu lieu, validez-la ici.'**
  String get ignoredNotice;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Valider l’opération'**
  String get draftValidateAction;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Changer le montant'**
  String get draftChangeAmount;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer cette fois'**
  String get draftIgnoreOnce;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Il manque le taux du {currency} : donnez-le avec « Changer le montant ».'**
  String draftNoRate(String currency);

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Affichage de la liste'**
  String get listDisplay;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Quand une récurrence arrive à sa date'**
  String get displayWhenDue;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Valider automatiquement'**
  String get displayAuto;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Créée et comptée à sa date.'**
  String get displayAutoHelp;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Toujours demander'**
  String get displayAsk;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Arrive en brouillon, à valider.'**
  String get displayAskHelp;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Brouillons à valider'**
  String get displayDrafts;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'À leur date'**
  String get displayAtDate;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Au jour prévu, dans la liste.'**
  String get displayAtDateHelp;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Groupés en haut'**
  String get displayOnTop;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'En retard et du jour, en haut.'**
  String get displayOnTopHelp;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Opérations prévues ce mois-ci'**
  String get displayPlanned;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'En pointillés, marquées « Prévu ».'**
  String get displayPlannedHelp;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Masquées'**
  String get displayHidden;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Visibles une fois la date arrivée.'**
  String get displayHiddenHelp;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Aussi dans Réglages. Une récurrence peut toujours demander sa validation.'**
  String get displayFoot;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get displayDone;

  /// Drafts in the list and their card.
  ///
  /// In fr, this message translates to:
  /// **'Récurrences et brouillons'**
  String get settingsRecurrences;

  /// Recurrences and drafts settings.
  ///
  /// In fr, this message translates to:
  /// **'L’opération est créée et comptée, sauf pour les récurrences qui demandent une validation.'**
  String get displayAutoLong;

  /// Recurrences and drafts settings.
  ///
  /// In fr, this message translates to:
  /// **'Chaque opération arrive en brouillon et attend votre accord.'**
  String get displayAskLong;

  /// Recurrences and drafts settings.
  ///
  /// In fr, this message translates to:
  /// **'Chaque brouillon reste au jour prévu.'**
  String get displayAtDateLong;

  /// Recurrences and drafts settings.
  ///
  /// In fr, this message translates to:
  /// **'Ceux en retard et du jour sont réunis en haut de la liste.'**
  String get displayOnTopLong;

  /// Recurrences and drafts settings.
  ///
  /// In fr, this message translates to:
  /// **'Elles restent au jour prévu, en pointillés, marquées « Prévu ».'**
  String get displayPlannedLong;

  /// Recurrences and drafts settings.
  ///
  /// In fr, this message translates to:
  /// **'Elles n’apparaissent qu’une fois leur date arrivée.'**
  String get displayHiddenLong;

  /// Recurrences and drafts settings.
  ///
  /// In fr, this message translates to:
  /// **'Ces choix se retrouvent dans l’affichage de la liste des opérations. Chaque récurrence peut demander sa propre validation, dans sa fiche.'**
  String get settingsRecurrencesFoot;

  /// Recurrences and drafts settings.
  ///
  /// In fr, this message translates to:
  /// **'Automatique'**
  String get displayAutoShort;

  /// Drafts grouped on top of the list.
  ///
  /// In fr, this message translates to:
  /// **'En retard et du jour'**
  String get draftsLateAndToday;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'À traiter'**
  String get todoTitle;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir · {count}'**
  String todoSeeAll(String count);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 chose} other{{count} choses}}, les plus urgentes d’abord'**
  String todoListHelp(int count);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Urgent'**
  String get todoUrgent;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get todoWeek;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get todoReminders;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Budget dépassé'**
  String get todoBudgetOverSub;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Budget · {amount} restants'**
  String todoBudgetNearSub(String amount);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get todoSee;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 brouillon} other{{count} brouillons}}'**
  String todoDrafts(int count);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get todoValidate;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Code de récupération'**
  String get todoRecovery;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Non vérifié'**
  String get todoRecoverySub;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier'**
  String get todoRecoveryAction;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Taux du {currency}'**
  String todoRate(String currency);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{Il y a 1 jour} other{Il y a {days} jours}}'**
  String todoRateSub(int days);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get todoRateAction;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get todoLater;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Reporté à demain : {name}'**
  String todoPutOff(String name);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get toastUndo;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get upcomingTitle;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get upcomingSeeAll;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Valider ce brouillon ?} other{{count} brouillons à valider}}'**
  String draftsSheetTitle(int count);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un brouillon pour le modifier ou le valider seul.'**
  String get draftsSheetHelp;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Rien à valider} =1{Valider le brouillon} other{Valider les {count}}}'**
  String draftsSheetValidate(int count);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get draftsSheetValidateOne;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get draftsSheetLater;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Taux manquant : à valider seul'**
  String get draftsSheetNoRate;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'Passerait sous le plancher : à valider seul'**
  String get draftsSheetFloor;

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'{kind} · {day} · {account}'**
  String draftsSheetLine(String kind, String day, String account);

  /// Home: À traiter, À venir, drafts sheet.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 brouillon validé} other{{count} brouillons validés}}'**
  String draftsValidated(int count);

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'Types de compte'**
  String get typesTitle;

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'Fournis par kibuo'**
  String get typesProvided;

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'Les vôtres'**
  String get typesYours;

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'Les types fournis ne se modifient pas.'**
  String get typesProvidedHelp;

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le type'**
  String get typeEditTitle;

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce type'**
  String get typeDelete;

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 compte est de ce type : changez-le d’abord.} other{{count} comptes sont de ce type : changez-les d’abord.}}'**
  String typeInUse(int count);

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le type {name} ?'**
  String typeDeleteTitle(String name);

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'Il disparaît de la liste des types ; aucun compte ne l’utilise.'**
  String get typeDeleteText;

  /// Account types management.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get typeDeleteAction;

  /// Account form: opens Types de compte.
  ///
  /// In fr, this message translates to:
  /// **'Gérer'**
  String get typesManage;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappels et alertes'**
  String get remindersTitle;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Saisie'**
  String get remindersEntryGroup;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Noter mes opérations'**
  String get remindersEntry;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour à {time}'**
  String remindersEntryHelp(String time);

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Un rappel le soir, si rien n’est noté'**
  String get remindersEntryOffHelp;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get remindersTime;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Notifications bloquées'**
  String get remindersBlocked;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages du téléphone'**
  String get remindersOpenSettings;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Heure du rappel'**
  String get remindersTimeTitle;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get remindersTimeSave;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Noter mes opérations'**
  String get reminderEntryTitle;

  /// Reminders.
  ///
  /// In fr, this message translates to:
  /// **'Rien n’est noté aujourd’hui. Une dépense, un revenu ?'**
  String get reminderEntryBody;

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'{amount} dans {days, plural, =1{1 jour} other{{days} jours}}, {account}'**
  String reminderDueSoon(String amount, int days, String account);

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Dans {days, plural, =1{1 jour} other{{days} jours}} : il manque {missing} sur {account}'**
  String reminderDueShort(int days, String missing, String account);

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'{amount} aujourd’hui, {account}'**
  String reminderDueToday(String amount, String account);

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui : il manque {missing} sur {account}'**
  String reminderDueTodayShort(String missing, String account);

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Échéances'**
  String get remindersDueGroup;

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappeler avant une échéance'**
  String get remindersDue;

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Le jour même de chaque échéance} =1{1 jour avant chaque échéance} other{{days} jours avant chaque échéance}}'**
  String remindersDueHelp(int days);

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rappel avant les échéances'**
  String get remindersDueOffHelp;

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Délai'**
  String get remindersDelay;

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Le jour même} =1{1 jour avant} other{{days} jours avant}}'**
  String daysBefore(int days);

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Chaque récurrence peut avoir son propre rappel, réglé dans sa fiche.'**
  String get remindersRuleNote;

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get reminderRule;

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Par défaut ({when})'**
  String reminderRuleDefault(String when);

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get reminderRuleNone;

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Aucun (rappels éteints)'**
  String get reminderRuleOff;

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'{name} · le {date}'**
  String todoShortfall(String name, String date);

  /// Due-date reminders.
  ///
  /// In fr, this message translates to:
  /// **'Il manque {missing} sur {account}'**
  String todoShortfallSub(String missing, String account);

  /// Entry dated later.
  ///
  /// In fr, this message translates to:
  /// **'Prévue le {date} : elle arrivera ce jour-là.'**
  String entryPlannedToast(String date);

  /// A planned operation's card.
  ///
  /// In fr, this message translates to:
  /// **'{kind, select, income{Revenu prévu} transfer{Transfert prévu} other{Dépense prévue}}'**
  String plannedStatus(String kind);

  /// A planned operation's card.
  ///
  /// In fr, this message translates to:
  /// **'Prévue le {date}'**
  String plannedOn(String date);

  /// A planned operation's card.
  ///
  /// In fr, this message translates to:
  /// **'Elle ne compte pas encore. Le jour venu, elle arrivera comme les autres : comptée, ou en brouillon à valider.'**
  String get plannedNotice;

  /// A planned operation's card.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l’opération prévue'**
  String get plannedCancel;

  /// A planned operation's card.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l’opération prévue ?'**
  String get plannedCancelTitle;

  /// A planned operation's card.
  ///
  /// In fr, this message translates to:
  /// **'Elle disparaît des opérations prévues ; rien n’a encore été compté.'**
  String get plannedCancelText;

  /// A planned operation's card.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l’opération'**
  String get plannedCancelAction;

  /// A planned operation's card.
  ///
  /// In fr, this message translates to:
  /// **'Opération prévue annulée : {name}'**
  String plannedCancelled(String name);

  /// Budget alerts.
  ///
  /// In fr, this message translates to:
  /// **'{name} à {percent} % du budget · {left} restants'**
  String budgetAlertNear(String name, String percent, String left);

  /// Budget alerts.
  ///
  /// In fr, this message translates to:
  /// **'{name} à 100 % du budget'**
  String budgetAlertFull(String name);

  /// Budget alerts.
  ///
  /// In fr, this message translates to:
  /// **'{name} dépassé de {over}'**
  String budgetAlertOver(String name, String over);

  /// Budget alerts.
  ///
  /// In fr, this message translates to:
  /// **'Voir'**
  String get budgetAlertSee;

  /// Budget alerts.
  ///
  /// In fr, this message translates to:
  /// **'Budgets'**
  String get remindersBudgetGroup;

  /// Budget alerts.
  ///
  /// In fr, this message translates to:
  /// **'À 80 % du budget'**
  String get remindersAt80;

  /// Budget alerts.
  ///
  /// In fr, this message translates to:
  /// **'À 100 % du budget'**
  String get remindersAt100;

  /// Budget alerts.
  ///
  /// In fr, this message translates to:
  /// **'Une alerte par catégorie'**
  String get remindersBudgetHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Dettes et créances'**
  String get debtsTitle;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Je dois'**
  String get debtsOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'On me doit'**
  String get debtsOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{count} en retard'**
  String debtsLateCount(int count);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get debtsLateGroup;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Sans échéance'**
  String get debtsNoDue;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Environ {amount}'**
  String debtsAbout(String amount);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{En retard d’un jour} other{En retard de {days} jours}}'**
  String debtWordLate(int days);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd’hui'**
  String get debtWordToday;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Demain'**
  String get debtWordTomorrow;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Après-demain'**
  String get debtWordAfterTomorrow;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Dans {days} jours'**
  String debtWordIn(int days);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Soldée aujourd’hui} =1{Soldée hier} other{Soldée il y a {days} jours}}'**
  String debtWordSettled(int days);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =0{Reçue aujourd’hui} =1{Reçue hier} other{Reçue il y a {days} jours}}'**
  String debtWordReceived(int days);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : {date}'**
  String debtDueLine(String date);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Échéance : aujourd’hui, {date}'**
  String debtDueTodayLine(String date);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Échéance dépassée : {date}'**
  String debtDueLateLine(String date);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Aucune date fixée'**
  String get debtNoDueLine;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Rien remboursé pour l’instant.'**
  String get debtNothingRepaid;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Rien reçu pour l’instant.'**
  String get debtNothingReceived;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{paid} déjà remboursés sur {total}.'**
  String debtRepaidLine(String paid, String total);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{paid} déjà reçus sur {total}.'**
  String debtReceivedLine(String paid, String total);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Environ {amount} au taux du jour.'**
  String debtAboutLine(String amount);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 dette soldée} other{{count} dettes soldées}}'**
  String debtSettledOwe(int count);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 créance encaissée} other{{count} créances encaissées}}'**
  String debtSettledOwed(int count);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Aucune dette'**
  String get debtsEmptyOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Notez ce que vous devez, avec ou sans échéance.'**
  String get debtsEmptyOweHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Personne ne vous doit rien'**
  String get debtsEmptyOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Notez l’argent prêté, pour savoir qui doit rembourser.'**
  String get debtsEmptyOwedHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Ranger par'**
  String get debtsGroupBy;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get debtsByDue;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'La plus proche d’abord, celles en retard en haut.'**
  String get debtsByDueHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Personne'**
  String get debtsByPerson;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Un groupe par nom, dans l’ordre alphabétique.'**
  String get debtsByPersonHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Dettes et créances soldées'**
  String get debtsPaidTitle;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Dans leur mois'**
  String get debtsPaidInline;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Avec les autres, à leur date. Sans date : dans « Sans échéance ».'**
  String get debtsPaidInlineHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Regroupées en bas'**
  String get debtsPaidBottom;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Un bloc « soldées » à part, qui se déplie.'**
  String get debtsPaidBottomHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Masquées'**
  String get debtsPaidHidden;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Absentes de la liste.'**
  String get debtsPaidHiddenHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'À qui je dois'**
  String get debtPersonOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Qui me doit'**
  String get debtPersonOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Un nom'**
  String get debtPersonHint;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un nom'**
  String get debtPersonMissing;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Reste dû'**
  String get debtLeft;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get debtDue;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Retirer l’échéance'**
  String get debtDueClear;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Argent reçu sur un compte'**
  String get debtLinkOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Argent sorti d’un compte'**
  String get debtLinkOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{account}, le solde sera mis à jour'**
  String debtLinkHelp(String account);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Une dette ancienne : seul le reste dû est noté'**
  String get debtLinkOffHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Dette enregistrée'**
  String get debtSavedOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Créance enregistrée'**
  String get debtSavedOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Devise de la dette'**
  String get debtCurrency;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un montant'**
  String get debtAmountMissing;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dette'**
  String get debtNewOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle créance'**
  String get debtNewOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Sans compte'**
  String get debtNoAccount;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir une ligne'**
  String get debtsOpenTitle;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Détails au-dessus'**
  String get debtsDetailsAbove;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'La ligne descend, les détails viennent du haut.'**
  String get debtsDetailsAboveHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Détails en dessous'**
  String get debtsDetailsBelow;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'La ligne reste en place, les détails se déplient dessous.'**
  String get debtsDetailsBelowHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{step} sur 2'**
  String debtsCoachStep(int step);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Chaque ligne, une personne'**
  String get debtsCoach1Title;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'En rouge, l’échéance est dépassée. Le carré autour du jour se remplit à mesure des remboursements.'**
  String get debtsCoach1Text;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Touchez pour le détail'**
  String get debtsCoach2Title;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'La date complète et ce qui est déjà remboursé s’affichent au toucher. Où ils apparaissent se choisit dans Affichage.'**
  String get debtsCoach2Text;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get debtsCoachSkip;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get debtsCoachNext;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Essayer'**
  String get debtsCoachTry;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Je dois encore'**
  String get debtLeftOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'On me doit encore'**
  String get debtLeftOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{paid} remboursés sur {total}'**
  String debtRepaidOf(String paid, String total);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{paid} reçus sur {total}'**
  String debtReceivedOf(String paid, String total);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Remboursements'**
  String get debtRepayments;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 fois} other{{count} fois}}'**
  String debtRepaymentsCount(int count);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Aucun remboursement pour l’instant.'**
  String get debtNoRepayment;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser'**
  String get debtRepay;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser'**
  String get debtCollect;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get debtDetails;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get debtEditAction;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser {name}'**
  String debtRepayTitle(String name);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser {name}'**
  String debtCollectTitle(String name);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'emprunt du {date}'**
  String debtBorrowedOn(String date);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'prêt du {date}'**
  String debtLentOn(String date);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Depuis'**
  String get debtFrom;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Vers'**
  String get debtTo;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get debtLater;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement enregistré'**
  String get debtRepaySaved;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Encaissement enregistré'**
  String get debtCollectSaved;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Dette soldée'**
  String get debtSettledOweToast;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Créance soldée'**
  String get debtSettledOwedToast;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dette'**
  String get debtEditTitleOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la créance'**
  String get debtEditTitleOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Au moins {amount}, déjà remboursés.'**
  String debtAmountMin(String amount);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la dette'**
  String get debtDeleteOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la créance'**
  String get debtDeleteOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Rien n’a bougé sur vos comptes : seule la ligne disparaît.} =1{Son opération sera aussi supprimée, et le solde de son compte reviendra comme avant.} other{Ses {count} opérations seront aussi supprimées, et les soldes de leurs comptes reviendront comme avant.}}'**
  String debtDeleteText(int count);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'{name} supprimé'**
  String debtDeleted(String name);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Montant, devise et catégorie se modifient depuis la fiche de la dette.'**
  String get debtOpLocked;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Voir la dette'**
  String get debtSeeDebt;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Au plus {amount}, ce qui reste.'**
  String debtLeftCap(String amount);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Dette'**
  String get debtTagOwe;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Créance'**
  String get debtTagOwed;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Dans les Entrées et Sorties'**
  String get debtsInTotals;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'L’argent emprunté compte comme une entrée, un remboursement comme une sortie.'**
  String get debtsInTotalsHelp;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'À part'**
  String get debtsApart;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Dans la liste, mais hors des totaux du mois.'**
  String get debtsApartHelp;

  /// Account choice and debt operation titles.
  ///
  /// In fr, this message translates to:
  /// **'Solde : {amount}'**
  String accountBalanceLine(String amount);

  /// Account choice and debt operation titles.
  ///
  /// In fr, this message translates to:
  /// **'Emprunté à {name}'**
  String debtTitleBorrow(String name);

  /// Account choice and debt operation titles.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé à {name}'**
  String debtTitleRepayTo(String name);

  /// Account choice and debt operation titles.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé à {name}'**
  String debtTitleRepayToShort(String name);

  /// Account choice and debt operation titles.
  ///
  /// In fr, this message translates to:
  /// **'Prêté à {name}'**
  String debtTitleLend(String name);

  /// Account choice and debt operation titles.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé par {name}'**
  String debtTitleRepayFrom(String name);

  /// Account choice and debt operation titles.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé par {name}'**
  String debtTitleRepayFromShort(String name);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Reste {left} sur {total}'**
  String debtLeftOf(String left, String total);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Solder sans paiement'**
  String get debtForgive;

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Le reste ({amount}) sera abandonné. Rien ne bouge sur vos comptes, et ce reste ne pourra plus être repris.'**
  String debtForgiveText(String amount);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Soldée sans paiement le {date} : {amount} abandonnés'**
  String debtForgivenOn(String date, String amount);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Soldée sans paiement le {date}, reste abandonné : {amount}'**
  String debtForgivenNote(String date, String amount);

  /// Debts and receivables.
  ///
  /// In fr, this message translates to:
  /// **'Aucun remboursement : soldée sans paiement.'**
  String get debtNoRepaymentForgiven;

  /// Debts on the home screen.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 dette} other{{count} dettes}}'**
  String debtsCountOwe(int count);

  /// Debts on the home screen.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 créance} other{{count} créances}}'**
  String debtsCountOwed(int count);

  /// Debts on the home screen.
  ///
  /// In fr, this message translates to:
  /// **'Rien'**
  String get debtsNothing;

  /// Claiming money owed.
  ///
  /// In fr, this message translates to:
  /// **'Réclamer à {name}'**
  String debtClaimTitle(String name);

  /// Claiming money owed.
  ///
  /// In fr, this message translates to:
  /// **'{name} vous doit {amount}'**
  String debtClaimOwes(String name, String amount);

  /// Claiming money owed.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get debtClaimMessageLabel;

  /// Claiming money owed.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}, petit rappel pour les {amount} que tu me dois. Merci !'**
  String debtClaimMessage(String name, String amount);

  /// Claiming money owed.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour {name}, petit rappel pour les {amount} que tu devais me rendre le {date}. Merci !'**
  String debtClaimMessageDue(String name, String amount, String date);

  /// Claiming money owed.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get debtClaimSend;

  /// Claiming money owed.
  ///
  /// In fr, this message translates to:
  /// **'Réclamer'**
  String get debtClaimAction;

  /// Debts in À venir.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser {name}'**
  String debtComingOwe(String name);

  /// Debts in À venir.
  ///
  /// In fr, this message translates to:
  /// **'{name} me rembourse'**
  String debtComingOwed(String name);

  /// Debt reminders.
  ///
  /// In fr, this message translates to:
  /// **'Rembourser {name} : {amount}, échéance {day}'**
  String reminderDebtOwe(String name, String amount, String day);

  /// Debt reminders.
  ///
  /// In fr, this message translates to:
  /// **'{name} doit vous rembourser {amount} {day}'**
  String reminderDebtOwed(String name, String amount, String day);

  /// Debt reminders.
  ///
  /// In fr, this message translates to:
  /// **'C’est aujourd’hui.'**
  String get reminderDebtToday;

  /// Debt reminders.
  ///
  /// In fr, this message translates to:
  /// **'{days, plural, =1{C’est demain.} other{Dans {days} jours.}}'**
  String reminderDebtSoon(int days);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Projets'**
  String get projectsTitle;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Aucun projet'**
  String get projectsEmpty;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Mettez de l’argent de côté pour un but : un voyage, un achat, une réserve.'**
  String get projectsEmptyHelp;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Où vous devriez en être aujourd’hui pour tenir la date'**
  String get projectsMarkLegend;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Terminés'**
  String get projectsEnded;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau projet'**
  String get projectsNew;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Mis de côté · 1 projet} other{Mis de côté · {count} projets}}'**
  String projectsSaved(int count);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'sur {amount}'**
  String projectsOf(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'du total'**
  String get projectsOfTotal;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Reste à mettre : {amount}'**
  String projectsLeft(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Sans date'**
  String get projectsNoDate;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Avant le {date}'**
  String projectsBefore(String date);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'par semaine'**
  String get projectsPerWeek;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'par quinzaine'**
  String get projectsPerFortnight;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'par mois'**
  String get projectsPerMonth;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé, terminé'**
  String get projectsEndedSpent;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Rendu disponible, terminé'**
  String get projectsEndedReleased;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Objectif atteint'**
  String get projectsReached;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} de retard'**
  String projectsBehind(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} d’avance'**
  String projectsAhead(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'À votre rythme'**
  String get projectsOwnPace;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'En retard'**
  String get projectsLate;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Changer l’icône'**
  String get projectIconTitle;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Diviser le plan par'**
  String get projectPeriod;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get projectWeek;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Quinzaine'**
  String get projectFortnight;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get projectMonth;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Chaque lundi'**
  String get projectRemindWeek;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Le 1er et le 15'**
  String get projectRemindFortnight;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Le 1er du mois'**
  String get projectRemindMonth;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau projet'**
  String get projectNewTitle;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get projectName;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Voyage, moto, loyer d’avance…'**
  String get projectNameHint;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Donnez-lui un nom.'**
  String get projectNameMissing;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get projectGoal;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Indiquez un objectif'**
  String get projectGoalMissing;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} libres'**
  String projectFree(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'facultative'**
  String get projectOptional;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Retirer la date'**
  String get projectNoDate;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Il faudra {amount} par {period} d’ici le {date}.'**
  String projectEffort(String amount, String period, String date);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Me rappeler de mettre de côté'**
  String get projectRemind;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Créer le projet'**
  String get projectCreate;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Total {amount}'**
  String homeTotal(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'dont projets {amount}'**
  String homeOfProjects(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Créer un projet'**
  String get homeNewProject;

  /// Home strip.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get homeTotalLabel;

  /// Home strip.
  ///
  /// In fr, this message translates to:
  /// **'dont projets'**
  String get homeOfProjectsLabel;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Dans les temps'**
  String get projectsOnTrack;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Il faudra '**
  String get projectEffortLead;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} par {period}'**
  String projectEffortAmount(String amount, String period);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **' d’ici le {date}.'**
  String projectEffortUntil(String date);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get projectEdit;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 jour} other{{count} jours}}'**
  String projectDaysLeft(int count);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 semaine} other{{count} semaines}}'**
  String projectWeeksLeft(int count);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 mois} other{{count} mois}}'**
  String projectMonthsLeft(int count);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'En avance'**
  String get projectAheadTag;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **' sur le rythme'**
  String get projectOnPace;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Sur {account}'**
  String projectOn(String account);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Mettre de côté'**
  String get projectPutAside;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Il faut {amount} par semaine pour tenir la date'**
  String projectNeedWeek(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Il faut {amount} par quinzaine pour tenir la date'**
  String projectNeedFortnight(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Il faut {amount} par mois pour tenir la date'**
  String projectNeedMonth(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Il reste {amount} à mettre de côté'**
  String projectLeftToSave(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Le plan'**
  String get projectPlan;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} restants'**
  String projectPlanLeft(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'jusqu’au {date}'**
  String projectUntil(String date);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Cette sem.'**
  String get projectThisWeek;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Sem. {n}'**
  String projectWeekN(int n);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Cette quinz.'**
  String get projectThisFortnight;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Quinz. {n}'**
  String projectFortnightN(int n);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get projectThisMonth;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Versements'**
  String get projectPayments;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre de l’argent'**
  String get projectTakeBack;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Repris · {account}'**
  String projectTakenBack(String account);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{from} → {to}'**
  String projectFromTo(String from, String to);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Et maintenant ?'**
  String get projectWhatNow;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Terminé le {date}'**
  String projectEndedOn(String date);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get projectEndedTag;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Dépensé'**
  String get projectSpentWord;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Rendu disponible'**
  String get projectReleasedWord;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Objectif atteint le jour même} =1{Atteint 1 jour avant la date} other{Atteint {count} jours avant la date}}'**
  String projectReachedEarly(int count);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le projet'**
  String get projectDelete;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer {name} ?'**
  String projectDeleteTitle(String name);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Le projet sera effacé.} =1{Le projet et son versement seront effacés.} other{Le projet et ses {count} versements seront effacés.}}'**
  String projectDeleteText(int count);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **' Les {amount} mis de côté redeviennent libres sur {account}.'**
  String projectDeleteFree(String amount, String account);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get projectDeleteAction;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Mettre de côté pour {name}'**
  String projectPutAsideFor(String name);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} de côté'**
  String projectSavedAmount(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'ce qui manque'**
  String get projectQuickMissing;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'cette semaine'**
  String get projectQuickWeek;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'cette quinzaine'**
  String get projectQuickFortnight;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'ce mois'**
  String get projectQuickMonth;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'la moitié'**
  String get projectQuickHalf;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get projectQuickAll;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Pris sur'**
  String get projectTakenFrom;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Un transfert de {from} vers {to} sera enregistré.'**
  String projectTransferNote(String from, String to);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Seulement {amount} libres sur {account}.'**
  String projectOnlyFree(String amount, String account);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Il restera {amount} disponibles sur {account}.'**
  String projectWillLeave(String amount, String account);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Sur'**
  String get projectSheetOn;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Aucune opération : les {amount} redeviennent libres sur {account}.'**
  String projectTakeBackNote(String amount, String account);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get projectTakeBackAction;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Au plus {amount}, ce qui est de côté'**
  String projectSavedCap(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Au plus {amount}, ce qui est libre'**
  String projectFreeCap(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} mis de côté pour {name}.'**
  String projectReachedText(String amount, String name);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} mis de côté pour {name}, {count, plural, =1{1 jour} other{{count} jours}} avant la date.'**
  String projectReachedEarlyText(String amount, String name, int count);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Je l’ai dépensé'**
  String get projectSpent;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la dépense, le projet se termine'**
  String get projectSpentHelp;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Le garder de côté'**
  String get projectKeep;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Pour plus tard, ou augmenter l’objectif'**
  String get projectKeepHelp;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Le rendre disponible'**
  String get projectRelease;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'L’argent redevient libre sur {account}'**
  String projectReleaseHelp(String account);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le projet'**
  String get projectEditTitle;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get projectSave;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'Le compte ne change plus après un premier versement.'**
  String get projectAccountLocked;

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} mis de côté'**
  String projectPutAsideDone(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{amount} repris'**
  String projectTakenBackDone(String amount);

  /// Projects.
  ///
  /// In fr, this message translates to:
  /// **'{name} est terminé, l’argent est libre'**
  String projectReleasedDone(String name);
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
