import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kibuo/data/backup_service.dart';
import 'package:kibuo/l10n/app_localizations.dart';

/// The phone's folders for backups: chosen in Android's own picker, then
/// written with the lasting right it gives (docs/backlog/ios.md).
abstract interface class BackupFolders {
  /// Null when the user leaves the picker without a folder.
  Future<BackupFolder?> pick();

  /// Whether kibuo can still write in [folder].
  Future<bool> reachable(BackupFolder folder);

  /// Copies [file] into [folder] as [name]; false when it could not.
  Future<bool> write(BackupFolder folder, String name, File file);
}

class DeviceBackupFolders implements BackupFolders {
  const DeviceBackupFolders();

  static const _channel = MethodChannel('kibuo/folder');

  @override
  Future<BackupFolder?> pick() async {
    final picked = await _channel.invokeMapMethod<String, String>('pick');
    if (picked == null) return null;
    return BackupFolder(uri: picked['uri']!, name: picked['name']!);
  }

  @override
  Future<bool> reachable(BackupFolder folder) async =>
      await _channel.invokeMethod<bool>('reachable', folder.uri) ?? false;

  @override
  Future<bool> write(BackupFolder folder, String name, File file) async =>
      await _channel.invokeMethod<bool>('write', {
        'uri': folder.uri,
        'name': name,
        'path': file.path,
      }) ??
      false;
}

/// « Download/Kibuo » as the user knows it: « Téléchargements/Kibuo ».
String folderLabel(AppLocalizations l, BackupFolder folder) {
  final parts = folder.name.split('/');
  parts[0] = switch (parts[0]) {
    'Download' => l.backupFolderDownload,
    'Documents' => l.backupFolderDocuments,
    final other => other,
  };
  return parts.join('/');
}
