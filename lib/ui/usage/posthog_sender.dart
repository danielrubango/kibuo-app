import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kibuo/app_version.dart';
import 'package:kibuo/data/key_vault.dart';
import 'package:kibuo/domain/usage/usage_event.dart';
import 'package:kibuo/domain/usage/usage_message.dart';
import 'package:kibuo/ui/usage/usage_measure.dart';
import 'package:uuid/uuid.dart';

/// The PostHog project kibuo sends to (ADR 0013, region EU): its key is
/// public, made to sit in the app.
const postHogKey = 'phc_xvJgDQP6CjzENvVk2a6gaqr3rUwGxP4nyTEFT4oaHCyx';

/// PostHog Cloud in Europe, where the batches go.
final postHogBatch = Uri.parse('https://eu.i.posthog.com/batch/');

/// Sends a body to PostHog; true once it is taken.
typedef UsagePost = Future<bool> Function(Uri url, String body);

/// The messages, sent by kibuo itself (ADR 0013): no PostHog module on the
/// phone, so only what the ADR lists leaves. They wait in a file on the
/// phone and leave by batches, every 30 seconds, at 20 waiting, and when
/// kibuo goes to the background; without network they wait.
class PostHogSender implements UsageSink {
  PostHogSender({
    required this.vault,
    required this.folder,
    UsagePost? post,
    Future<UsagePhone> Function()? phone,
    DateTime Function()? now,
    this.every = const Duration(seconds: 30),
  }) : _post = post ?? _postOverHttp,
       _readPhone = phone ?? _phoneFromAndroid,
       _now = now ?? DateTime.now;

  /// The random number, kept in the phone's vault, never in the data.
  static const idKey = 'usage_id';

  /// At most this many wait; the oldest go first beyond it.
  static const kept = 500;
  static const _sendAt = 20;
  static const _perBatch = 50;

  final KeyVault vault;
  final Future<Directory> folder;
  final Duration every;
  final UsagePost _post;
  final Future<UsagePhone> Function() _readPhone;
  final DateTime Function() _now;

  bool _on = false;
  String? _id;
  UsagePhone _phone = const UsagePhone();
  Map<String, Object> _context = const {};
  final _waiting = <QueuedUsage>[];
  Timer? _timer;
  Future<void>? _sending;

  /// The messages still to send, for the tests.
  List<QueuedUsage> get waiting => List.unmodifiable(_waiting);

  @override
  Future<void> start({required bool on}) async {
    if (!on) return;
    _id = await vault.read(idKey);
    if (_id == null) await _newId();
    await _readQueue();
    await _begin();
  }

  @override
  Future<void> turnOn() async {
    await _newId();
    await _begin();
  }

  @override
  Future<void> turnOff() async {
    _on = false;
    _timer?.cancel();
    _timer = null;
    _id = null;
    _waiting.clear();
    await vault.delete(idKey);
    await _saveQueue();
  }

  @override
  Future<void> describe(Map<String, Object> context) async =>
      _context = context;

  @override
  Future<void> send(String name, Map<String, Object> properties) =>
      _queue(QueuedUsage(name, properties, _now()));

  @override
  Future<void> sendError(RedactedError error, StackTrace? stack) => _queue(
    QueuedUsage(
      r'$exception',
      exceptionProperties(error.type, stack?.toString()),
      _now(),
    ),
  );

  /// Sends what waits, by batches; what PostHog did not take stays.
  @override
  Future<void> flush() => _sending ??= _sendAll().whenComplete(() {
    _sending = null;
  });

  Future<void> _begin() async {
    try {
      _phone = await _readPhone();
    } on Object {
      _phone = const UsagePhone();
    }
    _on = true;
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => flush());
  }

  Future<void> _newId() async {
    _id = const Uuid().v4();
    await vault.write(idKey, _id!);
  }

  Future<void> _queue(QueuedUsage message) async {
    if (!_on) return;
    _waiting.add(message);
    if (_waiting.length > kept) {
      _waiting.removeRange(0, _waiting.length - kept);
    }
    await _saveQueue();
    if (_waiting.length >= _sendAt) await flush();
  }

  Future<void> _sendAll() async {
    while (_on && _waiting.isNotEmpty) {
      final id = _id;
      if (id == null) return;
      final part = _waiting.take(_perBatch).toList();
      final body = jsonEncode(
        usageBatch(
          key: postHogKey,
          messages: [
            for (final m in part)
              usageMessage(
                m,
                distinctId: id,
                context: _context,
                phone: _phone,
                appVersion: appVersion,
              ),
          ],
        ),
      );
      bool taken;
      try {
        taken = await _post(postHogBatch, body);
      } on Object {
        taken = false;
      }
      // Off meanwhile: the queue is already gone.
      if (!taken || !_on) return;
      _waiting.removeRange(0, part.length);
      await _saveQueue();
    }
  }

  Future<File> get _file async =>
      File('${(await folder).path}/usage_queue.json');

  Future<void> _readQueue() async {
    try {
      final file = await _file;
      if (!file.existsSync()) return;
      final list = jsonDecode(await file.readAsString()) as List<Object?>;
      _waiting
        ..clear()
        ..addAll([
          for (final m in list)
            QueuedUsage.fromJson(Map<String, Object?>.from(m! as Map)),
        ]);
    } on Object {
      _waiting.clear();
    }
  }

  Future<void> _saveQueue() async {
    try {
      final file = await _file;
      if (_waiting.isEmpty) {
        if (file.existsSync()) await file.delete();
        return;
      }
      await file.writeAsString(
        jsonEncode([for (final m in _waiting) m.toJson()]),
      );
    } on Object {
      // The queue stays in memory.
    }
  }
}

Future<bool> _postOverHttp(Uri url, String body) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final request = await client.postUrl(url);
    request.headers.contentType = ContentType.json;
    request.add(utf8.encode(body));
    final response = await request.close().timeout(const Duration(seconds: 20));
    await response.drain<void>();
    return response.statusCode == 200;
  } finally {
    client.close(force: true);
  }
}

const _device = MethodChannel('kibuo/device');

Future<UsagePhone> _phoneFromAndroid() async {
  final info = await _device.invokeMapMethod<String, String>('phone');
  return UsagePhone(
    maker: info?['maker'],
    model: info?['model'],
    android: info?['android'],
  );
}
