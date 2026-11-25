import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/usage/usage_event.dart';

/// What may leave the phone (ADR 0013): names and short codes, never an
/// amount or a text the user typed.
void main() {
  test('every event of the catalogue is allowed to leave', () {
    for (final event in UsageEvent.catalogue) {
      expect(
        usageEventAllowed(event.name, event.properties),
        isTrue,
        reason: event.name,
      );
    }
  });

  test('the events say what was done, not what was written', () {
    expect(UsageEvent.operationSaved(UsageOperation.expense).properties, {
      'kind': 'expense',
      'edited': false,
    });
    expect(UsageEvent.tab(UsageTab.overview).properties, {'tab': 'overview'});
    expect(UsageEvent.backup(automatic: true, done: false).properties, {
      'automatic': true,
      'outcome': 'failed',
    });
  });

  test('an amount never leaves', () {
    expect(usageEventAllowed('operation_saved', {'amount': 125000}), isFalse);
    expect(usageEventAllowed('operation_saved', {'kind': 125000}), isFalse);
  });

  test('a typed text never leaves', () {
    expect(
      usageEventAllowed('operation_saved', {'kind': 'Loyer de novembre'}),
      isFalse,
    );
    expect(usageEventAllowed('operation_saved', {'label': 'taxi'}), isFalse);
    expect(usageEventAllowed('Loyer payé', const {}), isFalse);
  });

  test('the context says the phone, not the person', () {
    expect(usageContext(language: 'fr', country: 'CD', currency: 'CDF'), {
      'language': 'fr',
      'country': 'CD',
      'currency': 'CDF',
    });
    // Unknown or odd values are left out rather than sent.
    expect(usageContext(language: 'fr', country: null, currency: 'franc'), {
      'language': 'fr',
    });
  });

  test('an error leaves as its type alone', () {
    final error = RedactedError.of(
      const FormatException('Montant 125 000 FC refusé'),
    );
    expect(error.toString(), 'FormatException');
    expect(error.toString(), isNot(contains('125')));
  });
}
