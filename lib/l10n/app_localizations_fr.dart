// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String transferTitle(String account) {
    return 'Vers $account';
  }

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabOperations => 'Opérations';

  @override
  String get tabOverview => 'Aperçu';

  @override
  String get tabMore => 'Plus';

  @override
  String get homeTitle => 'Aujourd’hui';

  @override
  String get longAmounts => 'Montants longs';

  @override
  String get longAmountsAuto => 'Automatique';

  @override
  String get longAmountsAutoHelp => 'Raccourcit seulement ce qui ne tient pas';

  @override
  String get longAmountsAlways => 'Toujours';

  @override
  String get longAmountsAlwaysHelp => 'Dès 10 000 : 1,2 M au lieu de 1 245 000';

  @override
  String get longAmountsNever => 'Jamais';

  @override
  String get longAmountsNeverHelp =>
      'Toujours en entier, plus petit s’il le faut';

  @override
  String get longAmountsNote =>
      'La saisie, le détail d’une opération et les confirmations montrent toujours le montant entier.';

  @override
  String listPeriod(String first, String last) {
    return 'du $first au $last';
  }

  @override
  String get monthStart => 'Début du mois';

  @override
  String get monthStartHelp =>
      'Le jour où votre mois commence, par exemple le jour de la paie.';

  @override
  String monthStartValue(int day) {
    String _temp0 = intl.Intl.pluralLogic(
      day,
      locale: localeName,
      other: 'Le $day',
      one: 'Le 1er',
    );
    return '$_temp0';
  }

  @override
  String monthStartPreview(String month, String first, String last) {
    return '$month ira du $first au $last.';
  }

  @override
  String get monthStartSave => 'Enregistrer';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsEmptyTitle => 'Aucun budget pour l’instant';

  @override
  String get budgetsEmptyHelp =>
      'Fixez un montant par catégorie pour suivre vos dépenses.';

  @override
  String get budgetsAdd => 'Ajouter un budget';

  @override
  String budgetsDays(String first, String last) {
    return 'du $first au $last';
  }

  @override
  String budgetsOutOf(String spent, String amount) {
    return '$spent sur $amount';
  }

  @override
  String get budgetsTooMuch => 'de trop';

  @override
  String budgetsLeftOf(String amount) {
    return 'restants sur $amount';
  }

  @override
  String budgetsOverOf(String amount) {
    return 'de trop sur $amount';
  }

  @override
  String budgetsSpentOf(String spent, String amount) {
    return '$spent dépensés sur $amount';
  }

  @override
  String get budgetsGroupOver => 'Dépassés';

  @override
  String get budgetsGroupNear => 'Presque atteints';

  @override
  String get budgetsGroupOk => 'Dans les clous';

  @override
  String get budgetsDisplay => 'Affichage des budgets';

  @override
  String get budgetsLayout => 'Disposition';

  @override
  String get budgetsTiles => 'Tuiles';

  @override
  String get budgetsTilesHelp => 'Deux colonnes, ce qui reste en grand';

  @override
  String get budgetsList => 'Liste';

  @override
  String get budgetsListHelp => 'Une ligne par budget, groupée par état';

  @override
  String get budgetsOrder => 'Ordre';

  @override
  String get budgetsWatch => 'À surveiller';

  @override
  String get budgetsWatchHelp => 'Les plus consommés d’abord';

  @override
  String get budgetsMine => 'Mon ordre';

  @override
  String get budgetsMineHelp => 'Celui que vous choisissez, en glissant';

  @override
  String get budgetsDone => 'Terminé';

  @override
  String get budgetNew => 'Nouveau budget';

  @override
  String get budgetEdit => 'Modifier le budget';

  @override
  String get budgetAmount => 'Montant par mois';

  @override
  String budgetAverage(String amount, String category) {
    return 'Vous dépensez en moyenne $amount par mois en $category';
  }

  @override
  String get budgetCategory => 'Catégorie';

  @override
  String get budgetChoose => 'Choisir';

  @override
  String get budgetPeriod => 'Période';

  @override
  String get budgetEveryMonth => 'Chaque mois';

  @override
  String get budgetNoCarry => 'Le reste ne se reporte pas sur le mois suivant.';

  @override
  String get budgetCreate => 'Créer le budget';

  @override
  String get budgetSave => 'Enregistrer';

  @override
  String get budgetDelete => 'Supprimer le budget';

  @override
  String budgetDeleteTitle(String category) {
    return 'Supprimer le budget $category ?';
  }

  @override
  String get budgetDeleteText => 'Les opérations ne changent pas.';

  @override
  String get budgetDeleteConfirm => 'Supprimer';

  @override
  String get budgetAlready => 'Déjà un budget';

  @override
  String protectDeleteBudget(String name) {
    return 'Pour supprimer le budget $name';
  }

  @override
  String budgetDetailBudget(String amount) {
    return 'budget $amount';
  }

  @override
  String get budgetOver => 'Dépassé';

  @override
  String get budgetNear => 'Presque atteint';

  @override
  String get budgetChart => 'Au fil du mois';

  @override
  String get budgetChartTotal => 'Total';

  @override
  String get budgetChartPace => 'Rythme';

  @override
  String budgetChartBudget(String amount) {
    return 'Budget $amount';
  }

  @override
  String get budgetLegendSpent => 'Dépensé';

  @override
  String get budgetLegendOver => 'Hors budget';

  @override
  String get budgetLegendPace => 'Rythme régulier';

  @override
  String get budgetLegendFast => 'Trop vite';

  @override
  String get budgetLegendSlow => 'Marge';

  @override
  String budgetAhead(String amount) {
    return '+$amount d’avance';
  }

  @override
  String budgetMargin(String amount) {
    return '$amount de marge';
  }

  @override
  String get budgetOps => 'Opérations du mois';

  @override
  String budgetNoOps(String category) {
    return 'Aucune dépense dans $category ce mois-ci.';
  }

  @override
  String get budgetSeeInList => 'Voir dans Opérations';

  @override
  String get budgetEditAction => 'Modifier';

  @override
  String confirmCategoryBudget(String amount) {
    return 'Son budget de $amount par mois est supprimé aussi.';
  }

  @override
  String get securityRecoveryUnverified => 'Non vérifié';

  @override
  String get rhythmDaily => 'Chaque jour';

  @override
  String rhythmEveryDays(String n) {
    return 'Tous les $n jours';
  }

  @override
  String rhythmWeekly(String days) {
    return 'Chaque $days';
  }

  @override
  String rhythmEveryOtherWeek(String days) {
    return '$days, une semaine sur deux';
  }

  @override
  String rhythmEveryWeeks(String days, String n) {
    return '$days, toutes les $n semaines';
  }

  @override
  String rhythmMonthly(String day) {
    return 'Le $day de chaque mois';
  }

  @override
  String rhythmEveryMonths(String day, String n) {
    return 'Le $day, tous les $n mois';
  }

  @override
  String rhythmYearly(String date) {
    return 'Chaque $date';
  }

  @override
  String rhythmEveryYears(String date, String n) {
    return 'Le $date, tous les $n ans';
  }

  @override
  String get rhythmEndNever => 'sans fin';

  @override
  String rhythmEndCount(String n) {
    return '$n fois en tout';
  }

  @override
  String rhythmEndDate(String date) {
    return 'jusqu’au $date';
  }

  @override
  String get rhythmAnd => 'et';

  @override
  String rhythmThe(String day) {
    return 'le $day';
  }

  @override
  String get recurrenceNew => 'Nouvelle récurrence';

  @override
  String get recurrenceEdit => 'Modifier la récurrence';

  @override
  String get repeatTitle => 'Répéter';

  @override
  String get repeatDay => 'Jour';

  @override
  String get repeatWeek => 'Semaine';

  @override
  String get repeatMonth => 'Mois';

  @override
  String get repeatYear => 'Année';

  @override
  String repeatEveryDay(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tous les $n jours',
      one: 'Tous les jours',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryWeek(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Toutes les $n semaines',
      one: 'Toutes les semaines',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryMonth(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tous les $n mois',
      one: 'Tous les mois',
    );
    return '$_temp0';
  }

  @override
  String repeatEveryYear(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Tous les $n ans',
      one: 'Tous les ans',
    );
    return '$_temp0';
  }

  @override
  String get repeatFirst => 'Première fois';

  @override
  String get repeatEnd => 'Fin';

  @override
  String get repeatEndNever => 'Jamais';

  @override
  String get repeatEndCount => 'Après X fois';

  @override
  String get repeatEndDate => 'À une date';

  @override
  String get repeatCount => 'Nombre de fois';

  @override
  String get repeatLastDate => 'Dernière date possible';

  @override
  String get repeatEndNeverHelp =>
      'La récurrence continue jusqu’à ce que vous l’arrêtiez.';

  @override
  String get repeatEndCountHelp =>
      'Utile pour un crédit ou des mensualités : elle s’arrête toute seule.';

  @override
  String get repeatEndDateHelp =>
      'Aucune opération ne sera créée après cette date.';

  @override
  String repeatNext(String dates) {
    return 'Prochaines dates : $dates';
  }

  @override
  String get repeatEach => 'À chaque échéance';

  @override
  String get repeatModeSave => 'Enregistrer';

  @override
  String get repeatModeDraft => 'Préparer un brouillon';

  @override
  String get repeatModeSaveHelp =>
      'L’opération est ajoutée automatiquement à sa date.';

  @override
  String get repeatModeDraftHelp =>
      'Un brouillon attend votre validation, utile si le montant varie.';

  @override
  String get repeatNever => 'Jamais';

  @override
  String get repeatStop => 'Ne plus répéter';

  @override
  String get repeatLess => 'Moins';

  @override
  String get repeatMore => 'Plus';

  @override
  String get repeatSave => 'Enregistrer';

  @override
  String get entryAmount => 'Montant';

  @override
  String get recurrencesTitle => 'Récurrences';

  @override
  String get recurrencesExpenses => 'Dépenses';

  @override
  String get recurrencesIncome => 'Revenus';

  @override
  String get recurrencesTransfers => 'Transferts';

  @override
  String get recurrencesEmptyTitle => 'Aucune récurrence pour l’instant';

  @override
  String get recurrencesEmptyHelp =>
      'Loyer, salaire, abonnements : notez-les une fois, kibuo s’en souvient.';

  @override
  String get recurrenceToValidate => 'À valider';

  @override
  String recurrenceNextOn(String date) {
    return 'le $date';
  }

  @override
  String get recurrenceTitle => 'Récurrence';

  @override
  String get recurrenceEditAction => 'Modifier';

  @override
  String get recurrenceNextTimes => 'Prochaines fois';

  @override
  String get recurrencePast => 'Dernières fois';

  @override
  String get recurrenceIgnored => 'Ignoré';

  @override
  String get recurrenceDraft => 'Brouillon';

  @override
  String get recurrenceStop => 'Arrêter la récurrence';

  @override
  String recurrenceStopTitle(String name) {
    return 'Arrêter la récurrence $name ?';
  }

  @override
  String get recurrenceStopText =>
      'Ce qui a déjà été créé reste ; les brouillons en attente sont supprimés.';

  @override
  String get recurrenceStopAction => 'Arrêter';

  @override
  String recurrenceToAccount(String name) {
    return 'vers $name';
  }

  @override
  String get recurrenceAskDraft => 'Préparer un brouillon';

  @override
  String get recurrenceSaveDirect => 'Enregistrer';

  @override
  String get recurrenceNone => 'Plus de prochaine fois';

  @override
  String get homeAvailable => 'Disponible';

  @override
  String get homeAvailableHelp => 'à dépenser librement';

  @override
  String get homeOpenAccounts => 'Voir mes comptes';

  @override
  String get homeThisMonth => 'ce mois-ci';

  @override
  String get homeLeft => 'restants';

  @override
  String homeOutOfIn(String out, String income) {
    return '$out sur $income';
  }

  @override
  String get operationsPlaceholder => 'Les opérations du mois viendront ici.';

  @override
  String get overviewPlaceholder =>
      'Les graphiques et les points suivis viendront ici.';

  @override
  String get morePlaceholder => 'Mes espaces et les réglages viendront ici.';

  @override
  String get plusButton => 'Ajouter une opération';

  @override
  String get plusButtonHint => 'Maintenir pour les choix rapides';

  @override
  String get addSheetTitle => 'Ajouter';

  @override
  String get close => 'Fermer';

  @override
  String get cancel => 'Annuler';

  @override
  String get fanHint => 'Glissez vers un choix, ou touchez-le';

  @override
  String get addExpense => 'Dépense';

  @override
  String get addExpenseHint => 'Le plus fréquent';

  @override
  String get addExpenseTitle => 'Nouvelle dépense';

  @override
  String get addIncome => 'Revenu';

  @override
  String get addIncomeHint => 'Salaire, vente';

  @override
  String get addIncomeTitle => 'Nouveau revenu';

  @override
  String get addTransfer => 'Transfert';

  @override
  String get addTransferHint => 'Entre comptes';

  @override
  String get addTransferTitle => 'Nouveau transfert';

  @override
  String get addDebt => 'Dette';

  @override
  String get addDebtHint => 'ou créance';

  @override
  String get addDebtFan => 'Dette ou\ncréance';

  @override
  String get addDebtTitle => 'Nouvelle dette ou créance';

  @override
  String get addProject => 'Projet';

  @override
  String get addProjectHint => 'Mettre de côté';

  @override
  String get addProjectFan => 'Mettre\nde côté';

  @override
  String get addProjectTitle => 'Mettre de côté';

  @override
  String get entryComingLater => 'Cette saisie arrive à une prochaine étape.';

  @override
  String get unreadableTitle => 'Vos données ne peuvent pas être ouvertes';

  @override
  String get unreadableBody =>
      'Elles viennent peut-être d’un autre téléphone, ou la clé qui les protège n’est plus sur celui-ci. Le fichier est gardé de côté, il n’est pas effacé.';

  @override
  String get unreadableStartOver => 'Repartir de zéro';

  @override
  String get lockCreateTitle => 'Créer votre code';

  @override
  String get lockChoose => 'Choisissez votre code';

  @override
  String get lockChooseHint => 'De 4 à 6 chiffres.';

  @override
  String get lockConfirm => 'Retapez votre code';

  @override
  String get lockConfirmHint => 'Pour vérifier que vous l’avez bien en tête.';

  @override
  String get lockMismatch =>
      'Les deux codes ne correspondent pas. Recommencez.';

  @override
  String get lockValidate => 'Valider';

  @override
  String get lockCreatedTitle => 'Code créé';

  @override
  String get lockCreatedBody => 'kibuo demandera ce code à chaque ouverture.';

  @override
  String get continueAction => 'Continuer';

  @override
  String get lockEnterTitle => 'Entrez votre code';

  @override
  String get lockCurrentTitle => 'Entrez votre code actuel';

  @override
  String get lockTooMany => 'Trop d’essais';

  @override
  String get lockUseFingerprint => 'Utiliser l’empreinte';

  @override
  String get lockForgot => 'Code oublié ?';

  @override
  String get keypadDelete => 'Effacer';

  @override
  String get fingerprintOfferTitle => 'Ouvrir kibuo avec votre empreinte ?';

  @override
  String get fingerprintOfferBody =>
      'Plus rapide que le code, qui reste possible à tout moment.';

  @override
  String get fingerprintEnable => 'Activer l’empreinte';

  @override
  String get later => 'Plus tard';

  @override
  String get fingerprintReason => 'Ouvrir kibuo';

  @override
  String get forgotErase => 'Effacer et repartir de zéro';

  @override
  String get forgotEraseBody =>
      'Toutes les données de kibuo sur ce téléphone seront effacées. Vous pourrez ensuite restaurer une sauvegarde, si vous en avez une.';

  @override
  String get forgotHold => 'Maintenir pour effacer';

  @override
  String get securityTitle => 'Sécurité';

  @override
  String get securityLock => 'Verrouillage';

  @override
  String get securityPrivacy => 'Confidentialité';

  @override
  String get securityNoCode => 'Aucun code';

  @override
  String get securityCode => 'Code';

  @override
  String get securityCodeFingerprint => 'Code · empreinte';

  @override
  String get securityRecentsHidden => 'Récentes masquées';

  @override
  String get securityRecentsShown => 'Récentes visibles';

  @override
  String get securityFooter =>
      'Vos données sont chiffrées et restent sur ce téléphone.';

  @override
  String get lockSettingsCreate => 'Créer un code';

  @override
  String get lockSettingsChange => 'Modifier le code';

  @override
  String get lockFingerprint => 'Empreinte';

  @override
  String get lockShuffle => 'Clavier mélangé';

  @override
  String get lockShuffleHelp =>
      'Le clavier mélangé change la place des chiffres à chaque fois : un regard par-dessus l’épaule ne suffit pas à deviner le code.';

  @override
  String get lockAfter => 'Verrouiller après une absence de';

  @override
  String get delayImmediately => 'Aussitôt';

  @override
  String get delayOneMinute => '1 minute';

  @override
  String get delayFiveMinutes => '5 minutes';

  @override
  String get lockRemove => 'Retirer le code';

  @override
  String get lockRemoveHelp =>
      'Sans code, kibuo s’ouvre directement. Vos données restent chiffrées.';

  @override
  String get privacyHideRecents =>
      'Masquer kibuo dans les applications récentes';

  @override
  String get privacyScreenshots => 'Autoriser les captures d’écran';

  @override
  String get privacyHelp =>
      'Masqué, l’aperçu des applications récentes montre le logo de kibuo au lieu de vos soldes.';

  @override
  String lockWrong(int count) {
    return 'Code incorrect. Essai $count sur 5.';
  }

  @override
  String lockRetryIn(String time) {
    return 'Réessayez dans $time.';
  }

  @override
  String lockDigits(int count) {
    return '$count chiffres';
  }

  @override
  String get lockAfterRow => 'Verrouiller après';

  @override
  String get delayThirtySeconds => '30 secondes';

  @override
  String get delayFifteenMinutes => '15 minutes';

  @override
  String get recoveryTitle => 'Code de récupération';

  @override
  String get recoveryShowTitle => 'Notez votre code de récupération';

  @override
  String get recoveryShowBody =>
      'Il rend l’accès à kibuo si vous oubliez votre code et que l’empreinte ne marche pas, et il rouvre vos données sur un nouveau téléphone. Notez-le sur papier et gardez-le en lieu sûr.';

  @override
  String get recoveryShowWarning =>
      'kibuo ne le garde pas : il ne pourra plus vous le montrer.';

  @override
  String get recoveryCopy => 'Copier le code';

  @override
  String get recoveryCopied => 'Code copié';

  @override
  String get recoveryNoted => 'J’ai noté mon code';

  @override
  String get recoveryProofBody =>
      'Pour vérifier que vous avez bien noté votre code.';

  @override
  String get recoveryProofWrong =>
      'Ce n’est pas ce groupe. Regardez votre note.';

  @override
  String get recoverySeeAgain => 'Revoir le code';

  @override
  String get recoveryEnterTitle => 'Saisissez votre code de récupération';

  @override
  String get recoveryEnterBody =>
      'Le code de 16 caractères remis à sa création, en 4 groupes.';

  @override
  String get recoveryEnterHint =>
      'Les tirets et les minuscules ne comptent pas.';

  @override
  String get recoveryWrong =>
      'Code incorrect. Vérifiez chaque groupe et réessayez.';

  @override
  String get recoveryOpen => 'Ouvrir kibuo';

  @override
  String get recoveryUse => 'Utiliser le code de récupération';

  @override
  String get recoveryNotKept =>
      'kibuo ne le garde pas : vous seul le connaissez.';

  @override
  String get recoveryNew => 'Obtenir un nouveau code';

  @override
  String get recoveryNewHelp =>
      'L’ancien code de récupération cessera de fonctionner.';

  @override
  String get recoveryCreate => 'Créer un code de récupération';

  @override
  String get recoveryCreateHelp =>
      'Sans code de récupération, un code oublié ou un nouveau téléphone obligent à repartir de zéro, et Android ne copie pas les données de kibuo.';

  @override
  String get recoveryAndroidCopy => 'Laisser Android copier kibuo';

  @override
  String get recoveryAndroidCopyHelp =>
      'Sauvegarde Google et transfert vers un nouveau téléphone. Les données copiées restent chiffrées et ne s’ouvrent qu’avec ce code.';

  @override
  String get unreadableRecover => 'Saisir le code de récupération';

  @override
  String recoveryProofTitle(int group) {
    return 'Retapez le groupe $group';
  }

  @override
  String recoveryNotedOn(String date) {
    return 'Code noté le $date';
  }

  @override
  String securityRecoveryOn(String date) {
    return 'Noté le $date';
  }

  @override
  String get currenciesTitle => 'Devises';

  @override
  String get currenciesMain => 'Devise principale';

  @override
  String get currenciesChange => 'Changer';

  @override
  String get currenciesRates => 'Taux de conversion';

  @override
  String get currenciesWorkedOut => 'Calculé d’après vos autres taux';

  @override
  String get currenciesNoRate => 'Pas encore de taux';

  @override
  String get currenciesEdit => 'Modifier';

  @override
  String get currenciesRatesHelp =>
      'Modifier un taux ne change pas les opérations déjà enregistrées.';

  @override
  String get currenciesAdd => 'Ajouter une devise';

  @override
  String get currencyPickerTitle => 'Choisir une devise';

  @override
  String get mainCurrencyPickerTitle => 'Votre devise principale';

  @override
  String get mainCurrencyHelp =>
      'Elle sert au suivi et aux rapports. Chaque compte gardera sa propre devise.';

  @override
  String get currencySearch => 'Rechercher une devise';

  @override
  String get currencyYours => 'Vos devises';

  @override
  String get currencyCommon => 'Les plus courantes';

  @override
  String get currencyOthers => 'Toutes les autres';

  @override
  String get rateKeepsOld =>
      'Les opérations déjà enregistrées gardent leur taux.';

  @override
  String get rateSave => 'Enregistrer le taux';

  @override
  String get currenciesCents => 'Centimes';

  @override
  String get currencyDecimalsHelp =>
      'Désactivés, les montants s’affichent et se saisissent sans centimes.';

  @override
  String currenciesUpdatedOn(String date) {
    return 'Mis à jour le $date';
  }

  @override
  String rateSheetTitle(String ofName) {
    return 'Taux $ofName';
  }

  @override
  String rateBefore(String rate, String date) {
    return 'Avant : $rate · $date';
  }

  @override
  String get currencySearchHint => 'Nom ou code';

  @override
  String get rateUnchanged => 'Inchangé';

  @override
  String get accountsTitle => 'Comptes';

  @override
  String get accountsAll => 'Tous';

  @override
  String get accountsTotal => 'Total de mes comptes';

  @override
  String accountsTotalOf(String type) {
    return 'Total $type';
  }

  @override
  String get accountsAdd => 'Ajouter un compte';

  @override
  String accountsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comptes',
      one: '1 compte',
    );
    return '$_temp0';
  }

  @override
  String get accountTypeCash => 'Espèces';

  @override
  String get accountTypeBank => 'Banque';

  @override
  String get accountTypeMobile => 'Mobile money';

  @override
  String get accountTypeSavings => 'Épargne';

  @override
  String get accountNewTitle => 'Nouveau compte';

  @override
  String get accountEditTitle => 'Modifier le compte';

  @override
  String get accountTypeLabel => 'Type';

  @override
  String get accountTypeCreate => 'Créer un autre type';

  @override
  String get accountName => 'Nom du compte';

  @override
  String get accountNameHint => 'M-Pesa, Rawbank, poche…';

  @override
  String get accountOpening => 'Solde de départ';

  @override
  String accountCurrencyNote(String name, String code) {
    return '$name. Touchez $code pour changer de devise.';
  }

  @override
  String get accountOpeningDate => 'Date du solde';

  @override
  String get accountOpeningDateHelp =>
      'Ce que contient le compte ce jour-là. Les opérations d’avant n’y changent rien.';

  @override
  String accountToday(String date) {
    return 'Aujourd’hui, $date';
  }

  @override
  String get accountCreate => 'Créer le compte';

  @override
  String get accountSave => 'Enregistrer';

  @override
  String get accountArchive => 'Archiver le compte';

  @override
  String get accountArchiveHelp =>
      'Un compte archivé quitte les listes et les totaux ; ses opérations restent.';

  @override
  String get keypadDone => 'Terminé';

  @override
  String get typeNewTitle => 'Nouveau type';

  @override
  String get typeName => 'Nom';

  @override
  String get typeNameHint => 'Tontine, carte prépayée…';

  @override
  String get typeIcon => 'Icône';

  @override
  String get typeSave => 'Enregistrer';

  @override
  String get accountsDisplay => 'Affichage des comptes';

  @override
  String get accountsDisplayAmounts => 'Montants';

  @override
  String get accountsDisplayEach => 'Devise de chaque compte';

  @override
  String get accountsDisplayEachHelp => 'Chaque compte reste dans sa devise';

  @override
  String accountsDisplayAll(String name, String code) {
    return 'Tout en $name ($code)';
  }

  @override
  String get accountsDisplayAllHelp => 'Converti au dernier taux';

  @override
  String get accountsDisplayNote =>
      'Visible seulement quand vos comptes ont plusieurs devises.';

  @override
  String get accountsNoRate => 'Pas de taux';

  @override
  String accountsNoRateNote(String codes) {
    return 'Sans taux, $codes ne compte pas dans le total.';
  }

  @override
  String get accountsAddRate => 'Ajouter un taux';

  @override
  String get accountNameMissing => 'Donnez un nom au compte.';

  @override
  String get currencyKeptMain => 'Votre devise principale';

  @override
  String currencyKeptAccount(String name) {
    return 'Utilisée par le compte $name';
  }

  @override
  String get currencyOther => 'Autre devise…';

  @override
  String get currencyRemoveShort => 'Retirer';

  @override
  String get currencyKept => 'Gardée';

  @override
  String get currencyKeep => 'Garder';

  @override
  String categoryName(String key) {
    String _temp0 = intl.Intl.selectLogic(key, {
      'food': 'Repas',
      'restaurant': 'Restaurant',
      'market': 'Marché',
      'transport': 'Transport',
      'taxi': 'Taxi',
      'motoTaxi': 'Moto-taxi',
      'bus': 'Bus',
      'fuel': 'Carburant',
      'toll': 'Péage',
      'groceries': 'Courses',
      'housing': 'Logement',
      'rent': 'Loyer',
      'electricity': 'Électricité',
      'water': 'Eau',
      'communication': 'Communication',
      'airtime': 'Crédit',
      'internet': 'Internet',
      'health': 'Santé',
      'pharmacy': 'Pharmacie',
      'school': 'École',
      'family': 'Famille',
      'outings': 'Sorties',
      'contributions': 'Cotisations',
      'otherExpense': 'Autres',
      'salary': 'Salaire',
      'business': 'Activité',
      'sale': 'Vente',
      'service': 'Prestation',
      'giftReceived': 'Cadeau reçu',
      'refund': 'Remboursement',
      'otherIncome': 'Autres',
      'adjustExpense': 'Régularisation',
      'adjustIncome': 'Régularisation',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get categoriesTitle => 'Catégories';

  @override
  String get categoriesExpenses => 'Dépenses';

  @override
  String get categoriesIncome => 'Revenus';

  @override
  String categoriesSubCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sous-catégories',
      one: '1 sous-catégorie',
    );
    return '$_temp0';
  }

  @override
  String get categoriesAddSub => 'Ajouter une sous-catégorie';

  @override
  String get categoriesAdd => 'Ajouter une catégorie';

  @override
  String get categoryNewTitle => 'Nouvelle catégorie';

  @override
  String get categoryNewSubTitle => 'Nouvelle sous-catégorie';

  @override
  String get categoryEditTitle => 'Modifier la catégorie';

  @override
  String get categoryEditSubTitle => 'Modifier la sous-catégorie';

  @override
  String get categoryIn => 'Dans';

  @override
  String get categoryNameLabel => 'Nom';

  @override
  String get categoryIcon => 'Icône';

  @override
  String get categoryCreate => 'Créer la catégorie';

  @override
  String get categoryCreateSub => 'Créer la sous-catégorie';

  @override
  String get categorySave => 'Enregistrer';

  @override
  String get categoryRemove => 'Retirer la catégorie';

  @override
  String get categoryRemoveSub => 'Retirer la sous-catégorie';

  @override
  String get categoryRemoveHelp =>
      'Elle disparaît des choix ; ses opérations la gardent.';

  @override
  String categoryRemoveSubsToo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ses $count sous-catégories sont retirées avec elle.',
      one: 'Sa sous-catégorie est retirée avec elle.',
    );
    return '$_temp0';
  }

  @override
  String get categoryNameHint => 'Église, Moto-taxi…';

  @override
  String get currencyKeptTransaction => 'Utilisée par une opération';

  @override
  String get entryNewExpense => 'Nouvelle dépense';

  @override
  String get entryNewIncome => 'Nouveau revenu';

  @override
  String get entryEditExpense => 'Modifier la dépense';

  @override
  String get entryEditIncome => 'Modifier le revenu';

  @override
  String get entryExpense => 'Dépense';

  @override
  String get entryIncome => 'Revenu';

  @override
  String get entryTakenFrom => 'Retiré du compte';

  @override
  String get entryAddedTo => 'Ajouté au compte';

  @override
  String get entryAccount => 'Compte';

  @override
  String get entryCategory => 'Catégorie';

  @override
  String get entryDate => 'Date';

  @override
  String get entryFees => 'Frais';

  @override
  String get entryNone => 'Aucun';

  @override
  String get entryChoose => 'Choisir';

  @override
  String get entryNote => 'Note';

  @override
  String get entryNoteHint => 'Ajouter une note';

  @override
  String get entryToday => 'Aujourd’hui';

  @override
  String get entryYesterday => 'Hier';

  @override
  String get entrySave => 'Enregistrer';

  @override
  String get entrySaveChanges => 'Enregistrer les modifications';

  @override
  String get entryPaidCurrency => 'Devise payée';

  @override
  String get entryReceivedCurrency => 'Devise reçue';

  @override
  String entryCurrencyHelp(String account, String currency) {
    return 'Le compte $account est en $currency.';
  }

  @override
  String get entryAccountCurrency => 'La devise du compte, pas de conversion';

  @override
  String get entryConverted => 'Converti au taux choisi';

  @override
  String get entryRateTitle => 'Taux de conversion';

  @override
  String get entryPaid => 'Payé';

  @override
  String get entryReceived => 'Reçu';

  @override
  String get entryRateToday => 'Taux du jour';

  @override
  String get entryRateTodayHelp => 'Votre taux en cours, dans Devises';

  @override
  String get entryRateTodayMissing => 'Pas encore de taux dans Devises';

  @override
  String get entryRateOther => 'Autre taux';

  @override
  String get entryRateOtherHelp => 'Tapez le taux du changeur';

  @override
  String entryRateFor(String symbol) {
    return 'Taux pour 1 $symbol';
  }

  @override
  String get entryRateTodayTag => 'Du jour';

  @override
  String get entryRateTypedTag => 'Personnalisé';

  @override
  String get entrySo => 'Soit';

  @override
  String get entryFeesTitle => 'Frais supplémentaires';

  @override
  String get entrySavedExpense => 'Dépense enregistrée';

  @override
  String get entrySavedIncome => 'Revenu enregistré';

  @override
  String get entryUndoEdit => 'Annuler et modifier';

  @override
  String get entryClosesSoon => 'Se ferme seule dans un instant';

  @override
  String entryRateFrozen(String symbol) {
    return 'Taux figé pour 1 $symbol';
  }

  @override
  String get entryDuplicate => 'Dupliquer';

  @override
  String entryPaidChip(String amount, String rate) {
    return '$amount payés · $rate';
  }

  @override
  String entryReceivedChip(String amount, String rate) {
    return '$amount reçus · $rate';
  }

  @override
  String get entryReadNote => 'Lire toute la note';

  @override
  String get entryNoAccount => 'Ajoutez d’abord un compte.';

  @override
  String get categorySearch => 'Chercher une catégorie';

  @override
  String get operationsTitle => 'Opérations';

  @override
  String get operationsEmpty =>
      'Aucune opération pour l’instant. Le + en ajoute une.';

  @override
  String get entryFirstAccountTitle => 'D’abord, un compte';

  @override
  String get entryFirstAccountExpense =>
      'Chaque dépense sort d’un compte, et chaque revenu y arrive : votre poche, votre mobile money, votre banque. Créez le premier, puis notez votre dépense.';

  @override
  String get entryFirstAccountIncome =>
      'Chaque dépense sort d’un compte, et chaque revenu y arrive : votre poche, votre mobile money, votre banque. Créez le premier, puis notez votre revenu.';

  @override
  String get entryFirstAccountAction => 'Créer mon premier compte';

  @override
  String get entryFirstCategoryTitle => 'D’abord, une catégorie';

  @override
  String get entryFirstCategoryExpense =>
      'Chaque dépense se range dans une catégorie : repas, transport, loyer… Créez-en une, puis notez votre dépense.';

  @override
  String get entryFirstCategoryIncome =>
      'Chaque revenu se range dans une catégorie : salaire, ventes… Créez-en une, puis notez votre revenu.';

  @override
  String get entryFirstCategoryAction => 'Créer une catégorie';

  @override
  String get entryLater => 'Plus tard';

  @override
  String get entryDeleteOperation => 'Supprimer l’opération';

  @override
  String get entryDeleteExpenseTitle => 'Supprimer cette dépense ?';

  @override
  String get entryDeleteIncomeTitle => 'Supprimer ce revenu ?';

  @override
  String entryDeleteExpenseHelp(String account, String amount) {
    return 'Elle disparaît de la liste et le solde de $account reprend $amount.';
  }

  @override
  String entryDeleteIncomeHelp(String account, String amount) {
    return 'Il disparaît de la liste et le solde de $account perd $amount.';
  }

  @override
  String get entryDeleteConfirm => 'Supprimer';

  @override
  String get attachTitle => 'Pièces jointes';

  @override
  String get attachAdd => 'Ajouter';

  @override
  String get attachEmpty => 'Ajouter une pièce jointe';

  @override
  String get attachEmptyHelp => 'Photo d’un reçu ou document, 5 au plus';

  @override
  String get attachPhoto => 'Prendre une photo';

  @override
  String get attachGallery => 'Choisir dans la galerie';

  @override
  String get attachFile => 'Choisir un fichier';

  @override
  String get attachKindPhoto => 'Photo';

  @override
  String get attachKindPdf => 'PDF';

  @override
  String get attachKindFile => 'Fichier';

  @override
  String get attachTooBig =>
      'Ce fichier dépasse 10 Mo : choisissez-en un plus léger.';

  @override
  String attachChosen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choisies',
      one: '1 choisie',
    );
    return '$_temp0';
  }

  @override
  String get attachRemove => 'Retirer';

  @override
  String get attachView => 'Voir';

  @override
  String get attachOpenWith => 'Ouvrir avec…';

  @override
  String attachPage(int pages) {
    return 'Page 1 sur $pages';
  }

  @override
  String get attachNoApp => 'Aucune appli du téléphone n\'ouvre ce fichier.';

  @override
  String attachPhotoName(int n) {
    return 'Photo $n';
  }

  @override
  String get entryTransfer => 'Transfert';

  @override
  String get entryNewTransfer => 'Nouveau transfert';

  @override
  String get entryEditTransfer => 'Modifier le transfert';

  @override
  String get transferFrom => 'De';

  @override
  String get transferTo => 'Vers';

  @override
  String get transferToQuestion => 'Vers quel compte ?';

  @override
  String get transferSent => 'Envoyé';

  @override
  String transferArrives(String account) {
    return 'Arrive sur $account';
  }

  @override
  String transferTakenFrom(String account) {
    return 'Retiré de $account';
  }

  @override
  String get transferSaved => 'Transfert enregistré';

  @override
  String transferSavedSub(String from, String to, String when) {
    return '$from vers $to · $when';
  }

  @override
  String get transferAnother => 'Nouveau transfert';

  @override
  String get transferKind => 'Transfert';

  @override
  String get transferDepuis => 'Depuis';

  @override
  String transferArrivedChip(String amount, String rate) {
    return '$amount arrivés · $rate';
  }

  @override
  String get transferFirstAccountText =>
      'Un transfert déplace de l’argent entre deux de vos comptes : votre poche, votre mobile money, votre banque. Créez le premier, puis un deuxième.';

  @override
  String get transferSecondTitle => 'D’abord, un deuxième compte';

  @override
  String get transferSecondText =>
      'Un transfert déplace de l’argent entre deux de vos comptes. Créez-en un deuxième, puis notez votre transfert.';

  @override
  String get transferSecondAction => 'Créer un compte';

  @override
  String get entryDeleteTransferTitle => 'Supprimer ce transfert ?';

  @override
  String entryDeleteTransferHelp(
    String from,
    String withdrawn,
    String to,
    String arrived,
  ) {
    return 'Il disparaît de la liste : $from reprend $withdrawn et $to perd $arrived.';
  }

  @override
  String get overdraftLabel => 'Découvert';

  @override
  String get overdraftAllow => 'Autoriser le découvert';

  @override
  String get overdraftAllowHelp => 'Le solde peut descendre sous zéro';

  @override
  String get overdraftUpTo => 'Jusqu’à';

  @override
  String get overdraftNoLimitHelp => 'Vide ou 0 : sans limite.';

  @override
  String get overdraftNoLimit => 'Sans limite';

  @override
  String overdraftBelowZero(String account, String balance) {
    return '$account est à $balance : aucune sortie ne passera tant qu’il ne sera pas remonté. Les entrées restent possibles.';
  }

  @override
  String overdraftCaptionUpTo(String amount) {
    return 'Découvert jusqu’à $amount';
  }

  @override
  String get overdraftCaptionNoLimit => 'Découvert sans limite';

  @override
  String overdraftAvailable(String amount, String account) {
    return '$amount disponibles sur $account';
  }

  @override
  String get overdraftAuthorize => 'Autoriser';

  @override
  String overdraftWouldGo(String account, String amount) {
    return '$account passerait à $amount';
  }

  @override
  String get accountCurrentBalance => 'Solde actuel';

  @override
  String accountCurrentHelp(String balance) {
    return 'Dans kibuo aujourd’hui : $balance. Tapez ce que contient vraiment le compte.';
  }

  @override
  String adjustTitle(String account) {
    return 'Corriger le solde de $account ?';
  }

  @override
  String get adjustInKibuo => 'Dans kibuo';

  @override
  String get adjustReal => 'Solde réel';

  @override
  String get adjustHelp =>
      'La différence est ajoutée comme une opération, que vous pourrez modifier ensuite.';

  @override
  String adjustNote(String before, String after) {
    return 'Solde corrigé : $before → $after';
  }

  @override
  String get adjustAdd => 'Ajouter la régularisation';

  @override
  String get lockProtect => 'Code pour les actions importantes';

  @override
  String get lockProtectHelp => 'Supprimer, archiver, corriger un solde';

  @override
  String get protectTitle => 'Confirmez avec votre code';

  @override
  String protectArchive(String name) {
    return 'Pour archiver $name';
  }

  @override
  String get protectDeleteOperation => 'Pour supprimer l’opération';

  @override
  String protectDeleteCategory(String name) {
    return 'Pour supprimer $name';
  }

  @override
  String protectRemoveCurrencies(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count devises',
      one: 'une devise',
    );
    return 'Pour retirer $_temp0';
  }

  @override
  String protectAdjust(String name) {
    return 'Pour corriger le solde de $name';
  }

  @override
  String protectOverdraft(String name) {
    return 'Pour changer le découvert de $name';
  }

  @override
  String confirmArchiveTitle(String name) {
    return 'Archiver $name ?';
  }

  @override
  String confirmArchiveHelp(String name) {
    return '$name quitte les listes et les totaux. Ses opérations restent.';
  }

  @override
  String get confirmArchiveAction => 'Archiver le compte';

  @override
  String confirmCategoryTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String confirmCategoryHelp(String name, int subs) {
    String _temp0 = intl.Intl.pluralLogic(
      subs,
      locale: localeName,
      other:
          '$name et ses $subs sous-catégories disparaissent des choix. Les opérations déjà notées les gardent.',
      one:
          '$name et sa sous-catégorie disparaissent des choix. Les opérations déjà notées les gardent.',
      zero: '$name disparaît des choix. Les opérations déjà notées la gardent.',
    );
    return '$_temp0';
  }

  @override
  String get confirmCategoryAction => 'Supprimer la catégorie';

  @override
  String confirmCurrenciesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Retirer $count devises ?',
      one: 'Retirer une devise ?',
    );
    return '$_temp0';
  }

  @override
  String confirmCurrenciesHelp(String names, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'seront',
      one: 'sera',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'proposés',
      one: 'proposé',
    );
    return '$names ne $_temp0 plus $_temp1.';
  }

  @override
  String get confirmCurrenciesAction => 'Retirer';

  @override
  String get accountMinusHint => 'Maintenez « , » pour un solde négatif.';

  @override
  String get addRedo => 'Refaire';

  @override
  String get plusHoldTip =>
      'Astuce : maintenez + puis glissez vers un choix, sans lever le doigt.';

  @override
  String get plusHoldTipDone => 'Compris';

  @override
  String get listEntries => 'Entrées';

  @override
  String get listExits => 'Sorties';

  @override
  String listSpent(int percent) {
    return '$percent % dépensés';
  }

  @override
  String get listRest => 'Reste';

  @override
  String get listThisMonth => 'Ce mois-ci';

  @override
  String get filterType => 'Type';

  @override
  String get filterAccount => 'Compte';

  @override
  String get filterCategory => 'Catégorie';

  @override
  String get filterAll => 'Tous';

  @override
  String filterTypes(int count) {
    return '$count types';
  }

  @override
  String filterAccounts(int count) {
    return '$count comptes';
  }

  @override
  String filterCategories(int count) {
    return '$count catégories';
  }

  @override
  String get emptyMonthTitle => 'Aucune opération';

  @override
  String emptyMonthHelp(String month) {
    return 'Les dépenses, revenus et transferts de $month apparaîtront ici.';
  }

  @override
  String get emptyFilterTitle => 'Rien avec ces filtres';

  @override
  String get emptyFilterHelp =>
      'Essayez d’autres choix, ou effacez les filtres.';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get backToThisMonth => 'Revenir au mois en cours';

  @override
  String get swipeTipTitle => 'Changez de mois d’un geste';

  @override
  String get swipeTipText =>
      'Glissez la liste vers la droite pour le mois d’avant, vers la gauche pour le mois suivant. Ou touchez le titre du mois.';

  @override
  String get filterAllType => 'Tout';

  @override
  String get filterAllCategories => 'Toutes';

  @override
  String get filterExpenses => 'Dépenses';

  @override
  String get filterIncomes => 'Revenus';

  @override
  String get filterTransfers => 'Transferts';

  @override
  String filterMore(int count) {
    return 'Afficher les $count autres';
  }

  @override
  String get listNoEntries => 'Aucune entrée';

  @override
  String get listSearch => 'Rechercher';

  @override
  String get searchHint => 'Libellé, catégorie, compte, montant';

  @override
  String get searchClose => 'Fermer la recherche';

  @override
  String get searchClear => 'Effacer la recherche';

  @override
  String get searchRecent => 'Recherches récentes';

  @override
  String get searchRecentClear => 'Effacer';

  @override
  String get searchBy => 'Chercher par';

  @override
  String get searchHelp =>
      'La recherche porte sur tous les mois : libellé, catégorie, compte, note et montant.';

  @override
  String searchResults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
    );
    return '$_temp0';
  }

  @override
  String searchOthers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count autres résultats',
      one: '1 autre résultat',
    );
    return '$_temp0';
  }

  @override
  String get searchEarlierMonths => 'Dans les mois précédents';

  @override
  String get searchOtherMonths => 'Dans les autres mois';

  @override
  String searchEarlierFold(int count) {
    return 'Mois précédents · $count';
  }

  @override
  String searchOtherFold(int count) {
    return 'Autres mois · $count';
  }

  @override
  String get searchFold => 'Replier';

  @override
  String searchNothingInMonth(String month, String query) {
    return 'Rien en $month pour « $query ».';
  }

  @override
  String searchNoResultTitle(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get searchNoResultHelp =>
      'Vérifiez l’orthographe ou cherchez un montant.';

  @override
  String get firstWelcome => 'Bienvenue sur kibuo';

  @override
  String get firstWelcomeText =>
      'Vos comptes, vos dettes et vos projets, au même endroit. Vos données restent sur votre téléphone.';

  @override
  String get firstLanguage => 'Choisissez votre langue';

  @override
  String get firstContinue => 'Continuer';

  @override
  String firstStep(int step, int count) {
    return 'Étape $step sur $count';
  }

  @override
  String get firstCurrencyTitle => 'Votre devise principale';

  @override
  String get firstCurrencyText =>
      'Elle sert au suivi et aux rapports. Chaque compte gardera sa propre devise.';

  @override
  String get firstCurrencySearch => 'Rechercher une devise';

  @override
  String get firstCurrencySearchHint => 'Nom ou code';

  @override
  String get firstAccountTitle => 'Votre premier compte';

  @override
  String get firstAccountText =>
      'Commencez par celui que vous utilisez le plus. Vous pourrez en ajouter d’autres ensuite.';

  @override
  String get firstProtectTitle => 'Protégez vos données';

  @override
  String get firstProtectText =>
      'Vos données restent sur ce téléphone. Sans sauvegarde, elles sont perdues si vous le perdez.';

  @override
  String get firstLockTitle => 'Verrouiller l’application';

  @override
  String get firstLockHelp =>
      'PIN ou empreinte. Un code de récupération vous sera remis.';

  @override
  String get firstLater =>
      'Vous pourrez changer ces choix à tout moment dans les réglages.';

  @override
  String get firstStart => 'Commencer';

  @override
  String get draftLabel => 'Brouillon';

  @override
  String get draftIgnore => 'Ignorer';

  @override
  String get draftValidate => 'Valider';

  @override
  String get plannedTag => 'Prévu';

  @override
  String draftValidated(String name) {
    return 'Validé : $name, compté dans le mois';
  }

  @override
  String draftIgnoredToast(String name) {
    return 'Ignoré : $name. Validez-le depuis son détail.';
  }

  @override
  String draftsToValidate(String count) {
    return 'À valider · $count';
  }

  @override
  String draftFromRecurrence(String account) {
    return 'Récurrence · $account';
  }

  @override
  String draftStatus(String status, String unit) {
    String _temp0 = intl.Intl.selectLogic(status, {
      'ignored': 'Ignoré',
      'other': 'Brouillon',
    });
    String _temp1 = intl.Intl.selectLogic(unit, {
      'day': 'quotidienne',
      'week': 'hebdomadaire',
      'year': 'annuelle',
      'other': 'mensuelle',
    });
    return '$_temp0 · récurrence $_temp1';
  }

  @override
  String draftDueToday(String date) {
    return 'Prévu aujourd’hui, $date';
  }

  @override
  String draftDueYesterday(String date) {
    return 'Prévu hier, $date';
  }

  @override
  String draftDueOn(String date) {
    return 'Prévu le $date';
  }

  @override
  String get draftNotice =>
      'Cette opération attend votre accord. Vérifiez le montant, il varie parfois, puis validez pour l’ajouter au compte.';

  @override
  String get ignoredNotice =>
      'Vous l’avez ignorée pour cette fois : elle ne compte pas dans le compte. Si elle a bien eu lieu, validez-la ici.';

  @override
  String get draftValidateAction => 'Valider l’opération';

  @override
  String get draftChangeAmount => 'Changer le montant';

  @override
  String get draftIgnoreOnce => 'Ignorer cette fois';

  @override
  String draftNoRate(String currency) {
    return 'Il manque le taux du $currency : donnez-le avec « Changer le montant ».';
  }

  @override
  String get listDisplay => 'Affichage de la liste';

  @override
  String get displayWhenDue => 'Quand une récurrence arrive à sa date';

  @override
  String get displayAuto => 'Valider automatiquement';

  @override
  String get displayAutoHelp => 'Créée et comptée à sa date.';

  @override
  String get displayAsk => 'Toujours demander';

  @override
  String get displayAskHelp => 'Arrive en brouillon, à valider.';

  @override
  String get displayDrafts => 'Brouillons à valider';

  @override
  String get displayAtDate => 'À leur date';

  @override
  String get displayAtDateHelp => 'Au jour prévu, dans la liste.';

  @override
  String get displayOnTop => 'Groupés en haut';

  @override
  String get displayOnTopHelp => 'En retard et du jour, en haut.';

  @override
  String get displayPlanned => 'Opérations prévues ce mois-ci';

  @override
  String get displayPlannedHelp => 'En pointillés, marquées « Prévu ».';

  @override
  String get displayHidden => 'Masquées';

  @override
  String get displayHiddenHelp => 'Visibles une fois la date arrivée.';

  @override
  String get displayFoot =>
      'Aussi dans Réglages. Une récurrence peut toujours demander sa validation.';

  @override
  String get displayDone => 'Terminé';

  @override
  String get settingsRecurrences => 'Récurrences et brouillons';

  @override
  String get displayAutoLong =>
      'L’opération est créée et comptée, sauf pour les récurrences qui demandent une validation.';

  @override
  String get displayAskLong =>
      'Chaque opération arrive en brouillon et attend votre accord.';

  @override
  String get displayAtDateLong => 'Chaque brouillon reste au jour prévu.';

  @override
  String get displayOnTopLong =>
      'Ceux en retard et du jour sont réunis en haut de la liste.';

  @override
  String get displayPlannedLong =>
      'Elles restent au jour prévu, en pointillés, marquées « Prévu ».';

  @override
  String get displayHiddenLong =>
      'Elles n’apparaissent qu’une fois leur date arrivée.';

  @override
  String get settingsRecurrencesFoot =>
      'Ces choix se retrouvent dans l’affichage de la liste des opérations. Chaque récurrence peut demander sa propre validation, dans sa fiche.';

  @override
  String get displayAutoShort => 'Automatique';

  @override
  String get draftsLateAndToday => 'En retard et du jour';

  @override
  String get todoTitle => 'À traiter';

  @override
  String todoSeeAll(String count) {
    return 'Tout voir · $count';
  }

  @override
  String todoListHelp(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count choses',
      one: '1 chose',
    );
    return '$_temp0, les plus urgentes d’abord';
  }

  @override
  String get todoUrgent => 'Urgent';

  @override
  String get todoWeek => 'Cette semaine';

  @override
  String get todoReminders => 'Rappels';

  @override
  String get todoBudgetOverSub => 'Budget dépassé';

  @override
  String todoBudgetNearSub(String amount) {
    return 'Budget · $amount restants';
  }

  @override
  String get todoSee => 'Voir';

  @override
  String todoDrafts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brouillons',
      one: '1 brouillon',
    );
    return '$_temp0';
  }

  @override
  String get todoValidate => 'Valider';

  @override
  String get todoRecovery => 'Code de récupération';

  @override
  String get todoRecoverySub => 'Non vérifié';

  @override
  String get todoRecoveryAction => 'Vérifier';

  @override
  String todoRate(String currency) {
    return 'Taux du $currency';
  }

  @override
  String todoRateSub(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Il y a $days jours',
      one: 'Il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get todoRateAction => 'Modifier';

  @override
  String get todoLater => 'Plus tard';

  @override
  String todoPutOff(String name) {
    return 'Reporté à demain : $name';
  }

  @override
  String get toastUndo => 'Annuler';

  @override
  String get upcomingTitle => 'À venir';

  @override
  String get upcomingSeeAll => 'Tout voir';

  @override
  String draftsSheetTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brouillons à valider',
      one: 'Valider ce brouillon ?',
    );
    return '$_temp0';
  }

  @override
  String get draftsSheetHelp =>
      'Touchez un brouillon pour le modifier ou le valider seul.';

  @override
  String draftsSheetValidate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Valider les $count',
      one: 'Valider le brouillon',
      zero: 'Rien à valider',
    );
    return '$_temp0';
  }

  @override
  String get draftsSheetValidateOne => 'Valider';

  @override
  String get draftsSheetLater => 'Plus tard';

  @override
  String get draftsSheetNoRate => 'Taux manquant : à valider seul';

  @override
  String get draftsSheetFloor => 'Passerait sous le plancher : à valider seul';

  @override
  String draftsSheetLine(String kind, String day, String account) {
    return '$kind · $day · $account';
  }

  @override
  String draftsValidated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brouillons validés',
      one: '1 brouillon validé',
    );
    return '$_temp0';
  }

  @override
  String get typesTitle => 'Types de compte';

  @override
  String get typesProvided => 'Fournis par kibuo';

  @override
  String get typesYours => 'Les vôtres';

  @override
  String get typesProvidedHelp => 'Les types fournis ne se modifient pas.';

  @override
  String get typeEditTitle => 'Modifier le type';

  @override
  String get typeDelete => 'Supprimer ce type';

  @override
  String typeInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comptes sont de ce type : changez-les d’abord.',
      one: '1 compte est de ce type : changez-le d’abord.',
    );
    return '$_temp0';
  }

  @override
  String typeDeleteTitle(String name) {
    return 'Supprimer le type $name ?';
  }

  @override
  String get typeDeleteText =>
      'Il disparaît de la liste des types ; aucun compte ne l’utilise.';

  @override
  String get typeDeleteAction => 'Supprimer';
}
