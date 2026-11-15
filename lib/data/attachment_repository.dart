import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/domain/sync/hybrid_clock.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// What an attachment is, for its preview.
enum AttachmentKind {
  photo,
  pdf,
  file;

  static AttachmentKind fromStored(String s) =>
      values.firstWhere((k) => k.name == s, orElse: () => file);
}

class AttachmentInfo {
  const AttachmentInfo({
    required this.id,
    required this.name,
    required this.kind,
    required this.size,
  });

  final String id;
  final String name;
  final AttachmentKind kind;

  /// Bytes before encryption.
  final int size;
}

/// An operation holds 5 attachments at most (PRODUCT).
class TooManyAttachments implements Exception {}

/// A chosen file is 10 MB at most (ADR 0011).
class AttachmentTooBig implements Exception {}

/// Attachments of operations, encrypted in [folder] with a key kept in the
/// database (ADR 0011).
class AttachmentRepository {
  AttachmentRepository(this._db, Directory folder)
    : _files = FolderFiles(() async => folder);

  /// Kibuo's private folder, found only when a file is first needed.
  AttachmentRepository.lazy(this._db, Future<Directory> Function() folder)
    : _files = FolderFiles(folder);

  /// With another place for the files (in memory, for screen tests).
  AttachmentRepository.withFiles(this._db, this._files);

  final KibuoDatabase _db;
  final AttachmentFiles _files;
  HybridClock? _clock;
  SecretKey? _key;

  static const maxCount = 5;
  static const maxBytes = 10 * 1024 * 1024;
  static const _keyName = 'attachments_key';
  static final _cipher = AesGcm.with256bits();

  Future<int> _nextVersion() async {
    _clock ??= HybridClock(last: await _db.lastVersion());
    return _clock!.next();
  }

  Future<SecretKey> _secretKey() async {
    if (_key != null) return _key!;
    final row = await (_db.select(
      _db.preferences,
    )..where((pr) => pr.name.equals(_keyName))).getSingleOrNull();
    if (row != null) return _key = SecretKey(base64Decode(row.value));
    final random = Random.secure();
    final bytes = List.generate(32, (_) => random.nextInt(256));
    await _db
        .into(_db.preferences)
        .insert(
          PreferencesCompanion.insert(
            id: const Uuid().v7(),
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            name: _keyName,
            value: base64Encode(bytes),
          ),
        );
    return _key = SecretKey(bytes);
  }

  /// Adds a file to [transactionId] (or to a draft id, see [attach]).
  Future<String> add({
    required String transactionId,
    required Uint8List bytes,
    required String name,
    required AttachmentKind kind,
  }) async {
    if (bytes.length > maxBytes) throw AttachmentTooBig();
    final count = (await list(transactionId)).length;
    if (count >= maxCount) throw TooManyAttachments();
    final id = const Uuid().v7();
    final file = '$id.enc';
    await _write(file, bytes);
    await _db
        .into(_db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            id: id,
            version: await _nextVersion(),
            deviceId: _db.deviceId,
            transactionId: transactionId,
            name: name,
            kind: kind.name,
            size: bytes.length,
            file: file,
            position: count + 1,
          ),
        );
    return id;
  }

  Future<void> _write(String file, Uint8List bytes) async {
    final box = await _cipher.encrypt(bytes, secretKey: await _secretKey());
    await _files.write(file, Uint8List.fromList(box.concatenation()));
  }

  /// The attachments of [transactionId], in the order they were added.
  Future<List<AttachmentInfo>> list(String transactionId) async {
    final rows =
        await (_db.select(_db.attachments)
              ..where(
                (a) => a.transactionId.equals(transactionId) & a.deleted.not(),
              )
              ..orderBy([(a) => OrderingTerm.asc(a.position)]))
            .get();
    return [
      for (final r in rows)
        AttachmentInfo(
          id: r.id,
          name: r.name,
          kind: AttachmentKind.fromStored(r.kind),
          size: r.size,
        ),
    ];
  }

  /// The file of [id], decrypted.
  Future<Uint8List> read(String id) async {
    final row = await (_db.select(
      _db.attachments,
    )..where((a) => a.id.equals(id))).getSingle();
    final data = await _files.read(row.file);
    final box = SecretBox.fromConcatenation(
      data,
      nonceLength: _cipher.nonceLength,
      macLength: _cipher.macAlgorithm.macLength,
    );
    return Uint8List.fromList(
      await _cipher.decrypt(box, secretKey: await _secretKey()),
    );
  }

  /// Gives draft attachments [ids] to the operation just saved.
  Future<void> attach(List<String> ids, String transactionId) async {
    if (ids.isEmpty) return;
    await _update(
      _db.attachments.id.isIn(ids),
      AttachmentsCompanion(transactionId: Value(transactionId)),
    );
  }

  /// Takes [id] away; its file stays until a later clean-up, so [restore]
  /// can bring it back.
  Future<void> remove(String id) => _update(
    _db.attachments.id.equals(id),
    const AttachmentsCompanion(deleted: Value(true)),
  );

  Future<void> restore(String id) => _update(
    _db.attachments.id.equals(id),
    const AttachmentsCompanion(deleted: Value(false)),
  );

  Future<void> _update(
    Expression<bool> which,
    AttachmentsCompanion changes,
  ) async {
    await (_db.update(_db.attachments)..where((_) => which)).write(
      changes.copyWith(
        version: Value(await _nextVersion()),
        deviceId: Value(_db.deviceId),
      ),
    );
  }
}

/// Where encrypted attachment files are kept.
abstract class AttachmentFiles {
  Future<void> write(String name, Uint8List bytes);
  Future<Uint8List> read(String name);
}

/// The `attachments/` folder in Kibuo's private folder (ADR 0011).
class FolderFiles implements AttachmentFiles {
  FolderFiles(this._findRoot);

  final Future<Directory> Function() _findRoot;
  Future<Directory>? _root;

  Future<Directory> get _folder async =>
      Directory(p.join((await (_root ??= _findRoot())).path, 'attachments'));

  @override
  Future<void> write(String name, Uint8List bytes) async {
    final folder = await _folder;
    await folder.create(recursive: true);
    await File(p.join(folder.path, name)).writeAsBytes(bytes);
  }

  @override
  Future<Uint8List> read(String name) async =>
      File(p.join((await _folder).path, name)).readAsBytes();
}

/// Files kept in memory, for screen tests.
class MemoryFiles implements AttachmentFiles {
  final files = <String, Uint8List>{};

  @override
  Future<void> write(String name, Uint8List bytes) async => files[name] = bytes;

  @override
  Future<Uint8List> read(String name) async => files[name]!;
}
