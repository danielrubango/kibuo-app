import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/l10n/app_localizations_fr.dart';
import 'package:kibuo/ui/transactions/operation_row.dart';

void main() {
  final l = AppLocalizationsFr();

  test('a debt operation says what it did, before the name', () {
    expect(debtTitle(l, 'debtIn', 'Jean'), 'Emprunté à Jean');
    expect(debtTitle(l, 'debtOut', 'Jean'), 'Remboursé à Jean');
    expect(debtTitle(l, 'receivableOut', 'Jean'), 'Prêté à Jean');
    expect(debtTitle(l, 'receivableIn', 'Jean'), 'Remboursé par Jean');
  });

  test('short enough not to need shortening', () {
    expect(debtTitle(l, 'debtOut', 'Jean', short: true), 'Remboursé à Jean');
    expect(
      debtTitle(l, 'receivableIn', 'Jean', short: true),
      'Remboursé par Jean',
    );
  });
}
