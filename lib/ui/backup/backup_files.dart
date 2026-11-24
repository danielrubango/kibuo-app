import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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

/// Hands [onOpened] the .kibuo file kibuo was opened with, at once or
/// later, while [child] shows (PRODUCT: Restauration, au départ).
class WhenBackupOpened extends StatefulWidget {
  const WhenBackupOpened({
    super.key,
    required this.onOpened,
    required this.child,
    this.files,
  });

  final void Function(PickedBackup picked) onOpened;
  final Widget child;

  /// The phone's own when null.
  final BackupFiles? files;

  @override
  State<WhenBackupOpened> createState() => _WhenBackupOpenedState();
}

class _WhenBackupOpenedState extends State<WhenBackupOpened> {
  late final BackupFiles _files = widget.files ?? DeviceBackupFiles.instance;

  @override
  void initState() {
    super.initState();
    _files.opened.addListener(_take);
    WidgetsBinding.instance.addPostFrameCallback((_) => _take());
  }

  @override
  void dispose() {
    _files.opened.removeListener(_take);
    super.dispose();
  }

  Future<void> _take() async {
    final picked = await _files.takeOpened();
    if (picked != null && mounted) widget.onOpened(picked);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
