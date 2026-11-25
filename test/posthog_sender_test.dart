import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kibuo/domain/usage/usage_event.dart';
import 'package:kibuo/domain/usage/usage_message.dart';
import 'package:kibuo/ui/usage/posthog_sender.dart';

import 'support/memory_vault.dart';

/// kibuo's own sender to PostHog (ADR 0013).
void main() {
  late Directory folder;
  late MemoryVault vault;
  late List<Map<String, Object?>> bodies;
  late bool network;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('usage');
    vault = MemoryVault();
    bodies = [];
    network = true;
  });
  tearDown(() => folder.deleteSync(recursive: true));

  PostHogSender sender() => PostHogSender(
    vault: vault,
    folder: Future.value(folder),
    post: (url, body) async {
      expect(url.toString(), 'https://eu.i.posthog.com/batch/');
      if (!network) return false;
      bodies.add(jsonDecode(body) as Map<String, Object?>);
      return true;
    },
    phone: () async =>
        const UsagePhone(maker: 'Xiaomi', model: 'M2007J20CG', android: '15'),
    now: () => DateTime.utc(2026, 11, 25, 14),
    every: const Duration(hours: 1),
  );

  File queueFile() => File('${folder.path}/usage_queue.json');

  List<Object?> sent() => [
    for (final b in bodies) ...(b['batch']! as List<Object?>),
  ];

  test('started without a yes: nothing waits, nothing leaves', () async {
    final s = sender();
    await s.start(on: false);
    await s.send('tab_viewed', const {'tab': 'more'});
    await s.flush();
    expect(s.waiting, isEmpty);
    expect(bodies, isEmpty);
    expect(vault.values, isEmpty);
  });

  test(
    'after a yes: a random number, and the messages leave by batch',
    () async {
      final s = sender();
      await s.turnOn();
      final id = vault.values[PostHogSender.idKey];
      expect(id, isNotNull);
      await s.describe(const {'language': 'fr', 'country': 'CD'});
      await s.send('tab_viewed', const {'tab': 'more'});
      expect(queueFile().existsSync(), isTrue, reason: 'waits on the phone');

      await s.flush();
      expect(bodies.single['api_key'], postHogKey);
      final message = sent().single! as Map<String, Object?>;
      expect(message['event'], 'tab_viewed');
      expect(message['distinct_id'], id);
      final properties = message['properties']! as Map<String, Object?>;
      expect(properties['tab'], 'more');
      expect(properties['language'], 'fr');
      expect(properties[r'$device_model'], 'M2007J20CG');
      expect(properties[r'$process_person_profile'], false);
      expect(properties.containsKey(r'$network_carrier'), isFalse);
      expect(s.waiting, isEmpty);
      expect(queueFile().existsSync(), isFalse);
    },
  );

  test('without network the messages wait, then leave', () async {
    final s = sender();
    await s.turnOn();
    network = false;
    await s.send('app_opened', const {});
    await s.flush();
    expect(s.waiting, hasLength(1));
    network = true;
    await s.flush();
    expect(s.waiting, isEmpty);
    expect(sent(), hasLength(1));
  });

  test('they wait through a restart, under the same number', () async {
    final first = sender();
    await first.turnOn();
    final id = vault.values[PostHogSender.idKey];
    network = false;
    await first.send('app_opened', const {});
    await first.flush();

    network = true;
    final again = sender();
    await again.start(on: true);
    expect(again.waiting, hasLength(1));
    await again.flush();
    expect((sent().single! as Map)['distinct_id'], id);
  });

  test('twenty waiting leave at once', () async {
    final s = sender();
    await s.turnOn();
    for (var i = 0; i < 20; i++) {
      await s.send('tab_viewed', const {'tab': 'home'});
    }
    expect(sent(), hasLength(20));
  });

  test('turned off: the number and what waited are forgotten', () async {
    final s = sender();
    await s.turnOn();
    final before = vault.values[PostHogSender.idKey];
    network = false;
    await s.send('app_opened', const {});
    await s.turnOff();
    expect(vault.values.containsKey(PostHogSender.idKey), isFalse);
    expect(s.waiting, isEmpty);
    expect(queueFile().existsSync(), isFalse);

    await s.send('app_opened', const {});
    expect(s.waiting, isEmpty);

    await s.turnOn();
    expect(vault.values[PostHogSender.idKey], isNot(before));
  });

  test('an error leaves as its type and its frames', () async {
    final s = sender();
    await s.turnOn();
    await s.sendError(
      RedactedError.of(const FormatException('Loyer 300 000 FC')),
      StackTrace.fromString('#0      main (package:kibuo/main.dart:30:3)'),
    );
    await s.flush();
    final message = sent().single! as Map<String, Object?>;
    expect(message['event'], r'$exception');
    final text = jsonEncode(message);
    expect(text, contains('FormatException'));
    expect(text, contains('main.dart'));
    expect(text, isNot(contains('300')));
  });

  test('at most 500 wait; the oldest go first', () async {
    final s = sender();
    await s.turnOn();
    network = false;
    for (var i = 0; i < PostHogSender.kept + 5; i++) {
      await s.send('tab_viewed', const {'tab': 'home'});
    }
    expect(s.waiting, hasLength(PostHogSender.kept));
  });
}
