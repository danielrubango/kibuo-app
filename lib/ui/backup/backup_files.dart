import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A backup file to restore, copied into kibuo's own cache.
class PickedBackup {
  const PickedBackup({required this.file, required this.name});

  final File file;

  /// As the phone names it: « kibuo-2026-11-03-2104.kibuo ».
  final String name;
}

/// Backups to restore: chosen in Android's file picker, or a .kibuo file
/// touched elsewhere, which opens kibuo (docs/backlog/ios.md).
abstract interface class BackupFiles {
  /// Null when the user leaves the picker.
  Future<PickedBackup?> pick();

  /// The file kibuo was opened with, once; null if none.
  Future<PickedBackup?> takeOpened();

  /// Rings when kibuo, already open, is handed a file.
  Listenable get opened;
}

class DeviceBackupFiles implements BackupFiles {
  DeviceBackupFiles._() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'opened') _opened.value++;
    });
  }

  /// One for the whole app: Android hands files to a single listener.
  static final instance = DeviceBackupFiles._();

  static const _channel = MethodChannel('kibuo/backup-file');
  final _opened = ValueNotifier(0);

  @override
  Listenable get opened => _opened;

  PickedBackup? _of(Map<String, String>? map) => map == null
      ? null
      : PickedBackup(file: File(map['path']!), name: map['name']!);

  @override
  Future<PickedBackup?> pick() async =>
      _of(await _channel.invokeMapMethod<String, String>('pick'));

  @override
  Future<PickedBackup?> takeOpened() async {
    try {
      return _of(await _channel.invokeMapMethod<String, String>('takeOpened'));
    } on MissingPluginException {
      // Tests and phones without the channel: nothing was opened.
      return null;
    }
  }
}
