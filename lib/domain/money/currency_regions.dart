/// Which currencies to suggest near the top of the choice list, by the
/// phone's country (validated 15 November 2026): the dollar, the franc
/// congolais, the euro and the franc CFA for everyone, then a few more that
/// people of the region often meet.
library;

/// Offered to everyone, in this order, after the phone's own currency; one
/// franc CFA follows them.
const everyoneCurrencies = ['USD', 'CDF', 'EUR'];

/// Countries of the Central African franc CFA.
const xafCountries = {'CM', 'CF', 'TD', 'CG', 'GQ', 'GA'};

/// Countries of the West African franc CFA.
const xofCountries = {'BJ', 'BF', 'CI', 'GW', 'ML', 'NE', 'SN', 'TG'};

// Each region's currencies, most important first.
const _greatLakes = ['ZAR', 'UGX', 'KES', 'RWF', 'TZS', 'AED', 'CNY'];
const _southern = ['ZAR', 'BWP', 'MZN', 'ZMW', 'NAD', 'MWK', 'AOA'];
const _westAfrica = ['NGN', 'GHS', 'GNF', 'MAD', 'GBP'];
const _hornOfAfrica = ['KES', 'ETB', 'UGX', 'DJF', 'SOS', 'AED'];
const _north = ['MAD', 'DZD', 'TND', 'EGP', 'AED', 'SAR'];
const _gulf = ['SAR', 'QAR', 'OMR', 'KWD', 'INR', 'PKR'];
const _eastAsia = ['CNY', 'KRW', 'HKD', 'SGD'];
const _europe = ['GBP', 'CHF', 'CAD', 'MAD'];
const _northAmerica = ['CAD', 'MXN', 'GBP'];

/// West African countries outside the franc CFA, whose neighbours use the
/// West African one.
const westAfricaOutsideCfa = {'NG', 'GH', 'GN', 'SL', 'LR', 'GM', 'MR'};

/// The region's currencies, by country (ISO 3166). They fill the first
/// group up to 6; the others go with all the rest.
final regionCurrencies = <String, List<String>>{
  for (final c in ['CD', 'CG', 'RW', 'BI', 'UG', 'KE', 'TZ', 'SS'])
    c: _greatLakes,
  for (final c in ['ZA', 'NA', 'BW', 'ZW', 'MZ', 'MW', 'LS', 'SZ', 'ZM', 'AO'])
    c: _southern,
  for (final c in [...westAfricaOutsideCfa, ...xofCountries]) c: _westAfrica,
  for (final c in ['CM', 'CF', 'TD', 'GQ', 'GA']) c: _greatLakes,
  for (final c in ['ET', 'DJ', 'SO', 'ER']) c: _hornOfAfrica,
  for (final c in ['MA', 'DZ', 'TN', 'EG', 'LY']) c: _north,
  for (final c in ['AE', 'SA', 'QA', 'OM', 'KW', 'BH']) c: _gulf,
  for (final c in ['JP', 'CN', 'KR', 'HK', 'TW', 'SG']) c: _eastAsia,
  for (final c in ['FR', 'BE', 'CH', 'LU', 'DE', 'NL', 'IT', 'ES', 'PT', 'GB'])
    c: _europe,
  for (final c in ['US', 'CA', 'MX']) c: _northAmerica,
};
