import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/usage/usage_message.dart';

/// kibuo's own messages to PostHog (ADR 0013): exactly the listed fields.
void main() {
  final at = DateTime.utc(2026, 11, 25, 13, 40);
  const phone = UsagePhone(maker: 'Xiaomi', model: 'M2007J20CG', android: '15');

  test('a message carries the event, the random number and the list only', () {
    final message = usageMessage(
      QueuedUsage('tab_viewed', const {'tab': 'more'}, at),
      distinctId: 'k-7f3a',
      context: const {'language': 'fr', 'country': 'CD', 'currency': 'CDF'},
      phone: phone,
      appVersion: '0.1.0',
    );
    expect(message, {
      'event': 'tab_viewed',
      'distinct_id': 'k-7f3a',
      'timestamp': '2026-11-25T13:40:00.000Z',
      'properties': {
        'tab': 'more',
        'language': 'fr',
        'country': 'CD',
        'currency': 'CDF',
        r'$app_version': '0.1.0',
        r'$os': 'Android',
        r'$os_version': '15',
        r'$device_manufacturer': 'Xiaomi',
        r'$device_model': 'M2007J20CG',
        r'$lib': 'kibuo',
        r'$process_person_profile': false,
        r'$geoip_disable': true,
      },
    });
  });

  test('nothing else rides along: no carrier, time zone or user agent', () {
    final properties =
        usageMessage(
              QueuedUsage('app_opened', const {}, at),
              distinctId: 'k',
              context: const {},
              phone: phone,
              appVersion: '0.1.0',
            )['properties']!
            as Map<String, Object?>;
    for (final key in properties.keys) {
      expect(
        key,
        isNot(
          anyOf(contains('carrier'), contains('timezone'), contains('agent')),
        ),
      );
    }
  });

  test('a batch for PostHog carries the project key', () {
    final batch = usageBatch(
      key: 'phc_x',
      messages: const [
        {'event': 'a'},
      ],
    );
    expect(batch, {
      'api_key': 'phc_x',
      'batch': [
        {'event': 'a'},
      ],
    });
  });

  test('a queued message keeps through a restart', () {
    final queued = QueuedUsage('backup_made', const {
      'automatic': true,
      'outcome': 'done',
    }, at);
    final back = QueuedUsage.fromJson(queued.toJson());
    expect(back.event, 'backup_made');
    expect(back.properties, {'automatic': true, 'outcome': 'done'});
    expect(back.at, at);
  });

  group('an error', () {
    const stack = '''
#0      BudgetScreen._load (package:kibuo/ui/budgets/budgets_screen.dart:88:7)
#1      _rootRunUnary (dart:async/zone.dart:1538:47)
<asynchronous suspension>
#2      main (package:kibuo/main.dart:30:3)''';

    test('its type and where, never its message', () {
      final properties = exceptionProperties('FormatException', stack);
      final list = properties[r'$exception_list']! as List<Object?>;
      final exception = list.single! as Map<String, Object?>;
      expect(exception['type'], 'FormatException');
      expect(exception['value'], 'FormatException');
      expect(exception['mechanism'], {
        'handled': false,
        'synthetic': false,
        'type': 'generic',
      });
      expect(properties[r'$exception_level'], 'error');
    });

    test('its frames, oldest first, kibuo’s own marked', () {
      final exception =
          (exceptionProperties('FormatException', stack)[r'$exception_list']!
                      as List<Object?>)
                  .single!
              as Map<String, Object?>;
      final trace = exception['stacktrace']! as Map<String, Object?>;
      expect(trace['type'], 'raw');
      final frames = trace['frames']! as List<Object?>;
      expect(frames, [
        {
          'platform': 'dart',
          'abs_path': 'package:kibuo/main.dart',
          'filename': 'main.dart',
          'function': 'main',
          'lineno': 30,
          'colno': 3,
          'in_app': true,
        },
        {
          'platform': 'dart',
          'abs_path': 'dart:async/zone.dart',
          'filename': 'zone.dart',
          'function': '_rootRunUnary',
          'lineno': 1538,
          'colno': 47,
          'in_app': false,
        },
        {
          'platform': 'dart',
          'abs_path': 'package:kibuo/ui/budgets/budgets_screen.dart',
          'filename': 'budgets_screen.dart',
          'function': 'BudgetScreen._load',
          'lineno': 88,
          'colno': 7,
          'in_app': true,
        },
      ]);
    });

    test('without a stack, still its type', () {
      final exception =
          (exceptionProperties('StateError', null)[r'$exception_list']!
                      as List<Object?>)
                  .single!
              as Map<String, Object?>;
      expect(exception['type'], 'StateError');
      expect(exception.containsKey('stacktrace'), isFalse);
    });
  });
}
