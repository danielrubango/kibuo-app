/// kibuo's own messages to PostHog (ADR 0013): no PostHog module on the
/// phone, so nothing rides along that the ADR does not list.
library;

/// The phone, as the messages say it: its maker, its model and Android's
/// version.
class UsagePhone {
  const UsagePhone({this.maker, this.model, this.android});

  final String? maker;
  final String? model;
  final String? android;
}

/// A message waiting to leave: what was done and when. The random number
/// and the phone are added when it leaves.
class QueuedUsage {
  const QueuedUsage(this.event, this.properties, this.at);

  factory QueuedUsage.fromJson(Map<String, Object?> json) => QueuedUsage(
    json['event']! as String,
    Map<String, Object>.from(json['properties']! as Map),
    DateTime.parse(json['at']! as String),
  );

  final String event;
  final Map<String, Object> properties;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'event': event,
    'properties': properties,
    'at': at.toUtc().toIso8601String(),
  };
}

/// One message as PostHog takes it: no person profile, no place from the
/// IP address.
Map<String, Object?> usageMessage(
  QueuedUsage queued, {
  required String distinctId,
  required Map<String, Object> context,
  required UsagePhone phone,
  required String appVersion,
}) => {
  'event': queued.event,
  'distinct_id': distinctId,
  'timestamp': queued.at.toUtc().toIso8601String(),
  'properties': {
    ...queued.properties,
    ...context,
    r'$app_version': appVersion,
    r'$os': 'Android',
    if (phone.android != null) r'$os_version': phone.android,
    if (phone.maker != null) r'$device_manufacturer': phone.maker,
    if (phone.model != null) r'$device_model': phone.model,
    r'$lib': 'kibuo',
    r'$process_person_profile': false,
    r'$geoip_disable': true,
  },
};

/// What PostHog's `/batch/` takes.
Map<String, Object?> usageBatch({
  required String key,
  required List<Map<String, Object?>> messages,
}) => {'api_key': key, 'batch': messages};

/// A crash as PostHog's error tracking reads it: its type, never its
/// message, and where it happened, oldest frame first.
Map<String, Object> exceptionProperties(String type, String? stack) {
  final frames = stack == null ? const <Map<String, Object>>[] : _frames(stack);
  return {
    r'$exception_level': 'error',
    r'$exception_list': [
      {
        'type': type,
        'value': type,
        'mechanism': {'handled': false, 'synthetic': false, 'type': 'generic'},
        if (frames.isNotEmpty)
          'stacktrace': {'type': 'raw', 'frames': frames.reversed.toList()},
      },
    ],
  };
}

final _frame = RegExp(r'^#\d+\s+(.+?) \((.+?)(?::(\d+))?(?::(\d+))?\)$');

List<Map<String, Object>> _frames(String stack) => [
  for (final line in stack.split('\n'))
    if (_frame.firstMatch(line.trim()) case final match?) _toFrame(match),
];

Map<String, Object> _toFrame(RegExpMatch match) {
  final path = match.group(2)!;
  final line = int.tryParse(match.group(3) ?? '');
  final column = int.tryParse(match.group(4) ?? '');
  return {
    'platform': 'dart',
    'abs_path': path,
    'filename': path.split('/').last,
    'function': match.group(1)!,
    'lineno': ?line,
    'colno': ?column,
    'in_app': path.startsWith('package:kibuo/'),
  };
}
