/// A currency's name after « of », in the app's language: « du franc
/// congolais », « de l’euro », « de la livre sterling » in French, the name
/// as it is in English. Currency names come from CLDR, so this can't sit in
/// the ARB files one by one.
String currencyNameAfterOf(String language, String name) =>
    language == 'fr' ? _frenchOf(name) : name;

String _frenchOf(String name) {
  final lower = name.substring(0, 1).toLowerCase() + name.substring(1);
  const feminine = {
    'livre', 'roupie', 'couronne', 'lire', 'hryvnia', 'gourde', 'peseta', //
    'nouvelle', 'roupiah',
  };
  if (RegExp('^[aeiouyhéèêâîôû]').hasMatch(lower)) return 'de l’$lower';
  if (feminine.contains(lower.split(' ').first)) return 'de la $lower';
  return 'du $lower';
}
