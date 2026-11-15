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
}
