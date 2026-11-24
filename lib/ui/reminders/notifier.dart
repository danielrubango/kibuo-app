import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:kibuo/ui/backup/auto_backup_task.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// A notification to show at [at] (PRODUCT: Rappels); [payload] says where
/// touching it leads.
class Notice {
  const Notice({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;
  final String payload;
}

/// The phone's notifications, as kibuo uses them: asking leave, knowing
/// it, and replacing everything scheduled. Fake in tests.
abstract class Notifier {
  /// Ready, with what to do when a notification is touched while kibuo
  /// runs. Returns the payload of one that opened kibuo, if any.
  Future<String?> start(void Function(String payload) onOpen);

  Future<bool> allowed();

  /// Android's own question (Android 13+); true once allowed.
  Future<bool> ask();

  /// Android's settings for kibuo's notifications.
  Future<void> openSettings();

  /// Everything scheduled before is replaced by [notices].
  Future<void> replace(List<Notice> notices);
}

/// The real one, on Android's notifications.
class LocalNotifier implements Notifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _device = MethodChannel('kibuo/device');
  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Rappels',
      channelDescription: 'Rappels de saisie et échéances',
      icon: 'ic_launcher_monochrome',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  @override
  Future<String?> start(void Function(String payload) onOpen) async {
    try {
      return await _start(onOpen);
      // Without the plugin (tests, other platforms): no notifications.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return null;
    }
  }

  Future<String?> _start(void Function(String payload) onOpen) async {
    if (!_ready) {
      tz_data.initializeTimeZones();
      try {
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
      } on Exception {
        // An unknown zone: universal time, a few hours off at worst.
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_launcher_monochrome'),
        ),
        onDidReceiveNotificationResponse: (r) {
          if (r.payload case final p?) onOpen(p);
        },
      );
      _ready = true;
    }
    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp == true
        ? launch?.notificationResponse?.payload
        : null;
  }

  @override
  Future<bool> allowed() async =>
      _ready && (await _android?.areNotificationsEnabled() ?? false);

  @override
  Future<bool> ask() async =>
      _ready && (await _android?.requestNotificationsPermission() ?? false);

  @override
  Future<void> openSettings() async {
    try {
      await _device.invokeMethod<bool>('notificationSettings');
    } on MissingPluginException {
      // Not on Android.
    }
  }

  @override
  Future<void> replace(List<Notice> notices) async {
    if (!_ready) return;
    // Everything but a failed automatic backup's notice, which stays until
    // it is touched or a backup works.
    await _plugin.cancelAllPendingNotifications();
    for (final shown
        in await _android?.getActiveNotifications() ??
            const <ActiveNotification>[]) {
      if (shown.id case final id? when id != autoBackupNoticeId) {
        await _plugin.cancel(id: id, tag: shown.tag);
      }
    }
    for (final n in notices) {
      await _plugin.zonedSchedule(
        id: n.id,
        scheduledDate: tz.TZDateTime.from(n.at, tz.local),
        notificationDetails: _details,
        // Inexact: no special permission, a few minutes late at worst.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: n.title,
        body: n.body,
        payload: n.payload,
      );
    }
  }
}
