// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

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
}
