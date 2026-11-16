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
  String get homePlaceholder =>
      'Le disponible, le mois en cours et ce qui arrive viendront ici.';

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
  String get lockCreatedBody => 'Kibuo demandera ce code à chaque ouverture.';

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
  String get fingerprintOfferTitle => 'Ouvrir Kibuo avec votre empreinte ?';

  @override
  String get fingerprintOfferBody =>
      'Plus rapide que le code, qui reste possible à tout moment.';

  @override
  String get fingerprintEnable => 'Activer l’empreinte';

  @override
  String get later => 'Plus tard';

  @override
  String get fingerprintReason => 'Ouvrir Kibuo';

  @override
  String get forgotErase => 'Effacer et repartir de zéro';

  @override
  String get forgotEraseBody =>
      'Toutes les données de Kibuo sur ce téléphone seront effacées. Vous pourrez ensuite restaurer une sauvegarde, si vous en avez une.';

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
      'Sans code, Kibuo s’ouvre directement. Vos données restent chiffrées.';

  @override
  String get privacyHideRecents =>
      'Masquer Kibuo dans les applications récentes';

  @override
  String get privacyScreenshots => 'Autoriser les captures d’écran';

  @override
  String get privacyHelp =>
      'Masqué, l’aperçu des applications récentes montre le logo de Kibuo au lieu de vos soldes.';

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
      'Il rend l’accès à Kibuo si vous oubliez votre code et que l’empreinte ne marche pas, et il rouvre vos données sur un nouveau téléphone. Notez-le sur papier et gardez-le en lieu sûr.';

  @override
  String get recoveryShowWarning =>
      'Kibuo ne le garde pas : il ne pourra plus vous le montrer.';

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
  String get recoveryOpen => 'Ouvrir Kibuo';

  @override
  String get recoveryUse => 'Utiliser le code de récupération';

  @override
  String get recoveryNotKept =>
      'Kibuo ne le garde pas : vous seul le connaissez.';

  @override
  String get recoveryNew => 'Obtenir un nouveau code';

  @override
  String get recoveryNewHelp =>
      'L’ancien code de récupération cessera de fonctionner.';

  @override
  String get recoveryCreate => 'Créer un code de récupération';

  @override
  String get recoveryCreateHelp =>
      'Sans code de récupération, un code oublié ou un nouveau téléphone obligent à repartir de zéro, et Android ne copie pas les données de Kibuo.';

  @override
  String get recoveryAndroidCopy => 'Laisser Android copier Kibuo';

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
    return 'Dans Kibuo aujourd’hui : $balance. Tapez ce que contient vraiment le compte.';
  }

  @override
  String adjustTitle(String account) {
    return 'Corriger le solde de $account ?';
  }

  @override
  String get adjustInKibuo => 'Dans Kibuo';

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
}
