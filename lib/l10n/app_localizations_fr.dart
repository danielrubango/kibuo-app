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
      'La clé qui protège vos données n’est plus sur ce téléphone, ou ne correspond plus. Le fichier est gardé de côté sur le téléphone, il n’est pas effacé.';

  @override
  String get unreadableStartOver => 'Repartir de zéro';
}
