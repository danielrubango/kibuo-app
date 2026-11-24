import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:kibuo/data/database.dart';
import 'package:kibuo/data/pin_store.dart' show pbkdf2;
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// A kibuo backup file (ADR 0012): a short readable envelope (date, whether
/// it is encrypted), then the content cut in frames, each one signed, or
/// encrypted with the password. The content holds a manifest, the database
/// in clear (it opens on any phone) and the attachments as kibuo keeps them,
/// already encrypted with their key from the database (ADR 0011).

/// Not a kibuo backup.
class BackupNotKibuo implements Exception {}

/// The password is missing or wrong.
class BackupWrongPassword implements Exception {}

/// The file was changed or cut after it was written.
class BackupDamaged implements Exception {}

/// What shows before any password: the file's date, and whether it needs one.
class BackupEnvelope {
  const BackupEnvelope({required this.createdAt, required this.encrypted});

  final DateTime createdAt;
  final bool encrypted;
}

/// What the backup says about itself, once opened.
class BackupManifest {
  const BackupManifest({
    required this.createdAt,
    required this.schemaVersion,
    required this.accounts,
    required this.operations,
    required this.projects,
    this.language,
  });

  factory BackupManifest._fromJson(Map<String, dynamic> json) => BackupManifest(
    createdAt: DateTime.parse(json['createdAt'] as String),
    schemaVersion: json['schemaVersion'] as int,
    accounts: json['accounts'] as int,
    operations: json['operations'] as int,
    projects: json['projects'] as int,
    language: json['language'] as String?,
  );

  final DateTime createdAt;
  final int schemaVersion;
  final int accounts;
  final int operations;
  final int projects;

  /// kibuo's language when it was saved: Android 13 and more keep it
  /// outside the data, so it travels here (PRODUCT: Restauration).
  final String? language;

  Map<String, Object> _toJson() => {
    'language': ?language,
    'createdAt': createdAt.toIso8601String(),
    'schemaVersion': schemaVersion,
    'accounts': accounts,
    'operations': operations,
    'projects': projects,
  };
}

/// An opened backup, laid out in a folder.
class BackupContents {
  const BackupContents({
    required this.manifest,
    required this.database,
    required this.attachments,
  });

  final BackupManifest manifest;

  /// The database in clear, at its own schema version.
  final File database;
  final Directory attachments;
}

const _magic = 'KIBUO-BACKUP\n';
const _format = 1;
const _chunk = 1 << 20;
const _manifestName = 'manifest.json';
const _databaseName = 'kibuo.db';
const _attachmentsName = 'attachments';

/// Writes a backup of [db], with the attachments of [appFolder], to [out].
/// With [password], everything but the date is encrypted. Nothing in clear
/// stays behind: the work copy is deleted, even after a failure.
Future<void> writeBackup(
  KibuoDatabase db, {
  required Directory appFolder,
  required File out,
  required DateTime createdAt,
  String? password,
  String? language,
  int rounds = 300000,
}) async {
  final work = await Directory.systemTemp.createTemp('kibuo-backup-');
  try {
    final plain = p.join(work.path, _databaseName);
    await _copyInClear(db, plain);
    final manifest = _manifestOf(plain, createdAt, language);
    await Isolate.run(
      () => _seal(
        manifest: manifest,
        database: plain,
        attachments: p.join(appFolder.path, _attachmentsName),
        work: work.path,
        out: out.path,
        password: password,
        rounds: rounds,
      ),
    );
  } on Object {
    if (out.existsSync()) out.deleteSync();
    rethrow;
  } finally {
    work.deleteSync(recursive: true);
  }
}

/// Reads the envelope only: no password needed.
Future<BackupEnvelope> peekBackup(File file) async {
  final raf = await file.open();
  try {
    final (envelope, _) = _readEnvelope(raf);
    return BackupEnvelope(
      createdAt: DateTime.parse(envelope['createdAt'] as String),
      encrypted: envelope['encrypted'] as bool,
    );
  } finally {
    await raf.close();
  }
}

/// Opens [file] into the empty folder [into].
Future<BackupContents> openBackup(
  File file, {
  String? password,
  required Directory into,
}) async {
  final json = await Isolate.run(
    () => _unseal(file.path, password: password, into: into.path),
  );
  final manifest = BackupManifest._fromJson(json);
  final attachments = Directory(p.join(into.path, _attachmentsName));
  if (!attachments.existsSync()) attachments.createSync();
  return BackupContents(
    manifest: manifest,
    database: File(p.join(into.path, _databaseName)),
    attachments: attachments,
  );
}

/// A copy of the database at [path], decrypted: SQLite3 Multiple Ciphers
/// copies it with the phone's key, then the attached copy is rekeyed to
/// nothing. The phone's own file is never touched.
Future<void> _copyInClear(KibuoDatabase db, String path) async {
  String quoted(String s) => "'${s.replaceAll("'", "''")}'";
  await db.customStatement('VACUUM INTO ${quoted(path)}');
  // Without KEY, the attached file takes the main database's key.
  await db.customStatement('ATTACH DATABASE ${quoted(path)} AS backup_copy');
  try {
    await db.customStatement("PRAGMA backup_copy.rekey = ''");
  } finally {
    await db.customStatement('DETACH DATABASE backup_copy');
  }
}

BackupManifest _manifestOf(String path, DateTime createdAt, String? language) {
  final copy = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
  try {
    int count(String table) =>
        copy
                .select('SELECT count(*) AS n FROM $table WHERE deleted = 0')
                .single['n']
            as int;
    return BackupManifest(
      createdAt: createdAt,
      schemaVersion:
          copy.select('PRAGMA user_version').single['user_version'] as int,
      accounts: count('accounts'),
      operations: count('transactions'),
      projects: count('projects'),
      language: language,
    );
  } finally {
    copy.close();
  }
}

// The writing and reading below run in an isolate: plain files, no database.

Future<void> _seal({
  required BackupManifest manifest,
  required String database,
  required String attachments,
  required String work,
  required String out,
  required String? password,
  required int rounds,
}) async {
  // The content, as one file: manifest, database, attachments.
  final bundle = File(p.join(work, 'bundle'));
  final sink = bundle.openSync(mode: FileMode.write);
  try {
    void entry(String name, List<int> bytes) {
      final nameBytes = utf8.encode(name);
      sink
        ..writeFromSync(_u16(nameBytes.length))
        ..writeFromSync(nameBytes)
        ..writeFromSync(_u64(bytes.length))
        ..writeFromSync(bytes);
    }

    entry(_manifestName, utf8.encode(jsonEncode(manifest._toJson())));
    entry(_databaseName, File(database).readAsBytesSync());
    final folder = Directory(attachments);
    if (folder.existsSync()) {
      final files = folder.listSync().whereType<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final f in files) {
        entry('$_attachmentsName/${p.basename(f.path)}', f.readAsBytesSync());
      }
    }
  } finally {
    sink.closeSync();
  }

  final random = Random.secure();
  final envelope = <String, Object>{
    'format': _format,
    'createdAt': manifest.createdAt.toIso8601String(),
    'encrypted': password != null,
    'chunk': _chunk,
  };
  SecretKey? key;
  if (password != null) {
    final salt = List.generate(16, (_) => random.nextInt(256));
    final derived = pbkdf2(utf8.encode(password), salt, rounds, 32);
    key = SecretKey(derived);
    envelope['kdf'] = {
      'name': 'pbkdf2-sha256',
      'rounds': rounds,
      'salt': base64.encode(salt),
      'check': base64.encode(_check(derived)),
    };
  }
  final envelopeBytes = utf8.encode(jsonEncode(envelope));
  final envelopeHash = hash.sha256.convert(envelopeBytes).bytes;

  final output = File(out).openSync(mode: FileMode.write);
  final input = bundle.openSync();
  try {
    output
      ..writeFromSync(utf8.encode(_magic))
      ..writeFromSync(_u32(envelopeBytes.length))
      ..writeFromSync(envelopeBytes);
    final length = input.lengthSync();
    final frames = max(1, (length / _chunk).ceil());
    for (var i = 0; i < frames; i++) {
      final data = input.readSync(_chunk);
      final aad = _aad(envelopeHash, i, last: i == frames - 1);
      final List<int> body;
      if (key == null) {
        body = [
          ...data,
          ...hash.sha256.convert([...aad, ...data]).bytes,
        ];
      } else {
        final nonce = List.generate(12, (_) => random.nextInt(256));
        final box = await _aes.encrypt(
          data,
          secretKey: key,
          nonce: nonce,
          aad: aad,
        );
        body = box.concatenation();
      }
      output
        ..writeFromSync(_u32(body.length))
        ..writeFromSync(body);
    }
  } finally {
    input.closeSync();
    output.closeSync();
  }
}

Future<Map<String, dynamic>> _unseal(
  String path, {
  required String? password,
  required String into,
}) async {
  final raf = File(path).openSync();
  final bundlePath = p.join(into, '.bundle');
  final bundle = File(bundlePath).openSync(mode: FileMode.write);
  try {
    final (envelope, envelopeBytes) = _readEnvelope(raf);
    final envelopeHash = hash.sha256.convert(envelopeBytes).bytes;
    SecretKey? key;
    if (envelope['encrypted'] == true) {
      if (password == null) throw BackupWrongPassword();
      final kdf = envelope['kdf'] as Map<String, dynamic>;
      final derived = pbkdf2(
        utf8.encode(password),
        base64.decode(kdf['salt'] as String),
        kdf['rounds'] as int,
        32,
      );
      if (!_same(_check(derived), base64.decode(kdf['check'] as String))) {
        throw BackupWrongPassword();
      }
      key = SecretKey(derived);
    }

    final length = raf.lengthSync();
    var index = 0;
    var ended = false;
    while (raf.positionSync() < length) {
      if (ended) throw BackupDamaged();
      final size = _readU32(raf);
      final body = raf.readSync(size);
      if (body.length != size) throw BackupDamaged();
      final last = raf.positionSync() == length;
      final aad = _aad(envelopeHash, index, last: last);
      final List<int> data;
      if (key == null) {
        if (body.length < 32) throw BackupDamaged();
        data = body.sublist(0, body.length - 32);
        final sum = hash.sha256.convert([...aad, ...data]).bytes;
        if (!_same(sum, body.sublist(body.length - 32))) throw BackupDamaged();
      } else {
        try {
          data = await _aes.decrypt(
            SecretBox.fromConcatenation(body, nonceLength: 12, macLength: 16),
            secretKey: key,
            aad: aad,
          );
        } on SecretBoxAuthenticationError {
          throw BackupDamaged();
        } on ArgumentError {
          throw BackupDamaged();
        }
      }
      bundle.writeFromSync(data);
      ended = last;
      index++;
    }
    if (!ended) throw BackupDamaged();
    bundle.closeSync();
    return _unpack(bundlePath, into);
  } on RangeError {
    throw BackupDamaged();
  } finally {
    raf.closeSync();
    try {
      bundle.closeSync();
    } on FileSystemException {
      // Already closed.
    }
    final leftover = File(bundlePath);
    if (leftover.existsSync()) leftover.deleteSync();
  }
}

Map<String, dynamic> _unpack(String bundlePath, String into) {
  final raf = File(bundlePath).openSync();
  Map<String, dynamic>? manifest;
  try {
    final length = raf.lengthSync();
    while (raf.positionSync() < length) {
      final nameLength = _readU16(raf);
      final name = utf8.decode(raf.readSync(nameLength));
      final size = _readU64(raf);
      final data = raf.readSync(size);
      if (data.length != size) throw BackupDamaged();
      if (name == _manifestName) {
        manifest = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      } else if (name == _databaseName ||
          (name.startsWith('$_attachmentsName/') &&
              p.basename(name) == name.substring(_attachmentsName.length + 1) &&
              !name.contains('..'))) {
        final target = File(p.join(into, name));
        target.parent.createSync(recursive: true);
        target.writeAsBytesSync(data);
      }
    }
  } on FormatException {
    throw BackupDamaged();
  } finally {
    raf.closeSync();
  }
  if (manifest == null || !File(p.join(into, _databaseName)).existsSync()) {
    throw BackupDamaged();
  }
  return manifest;
}

(Map<String, dynamic>, List<int>) _readEnvelope(RandomAccessFile raf) {
  final magic = utf8.encode(_magic);
  final head = raf.readSync(magic.length);
  if (!_same(head, magic)) throw BackupNotKibuo();
  try {
    final size = _readU32(raf);
    if (size > 64 * 1024) throw BackupNotKibuo();
    final bytes = raf.readSync(size);
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (json['format'] != _format) throw BackupNotKibuo();
    return (json, bytes);
  } on FormatException {
    throw BackupNotKibuo();
  } on RangeError {
    throw BackupNotKibuo();
  }
}

final _aes = DartAesGcm.with256bits();

/// Tells a wrong password from a damaged file, without revealing the key.
List<int> _check(List<int> key) => hash.Hmac(
  hash.sha256,
  key,
).convert(utf8.encode('kibuo-check')).bytes.sublist(0, 16);

/// Ties each frame to the envelope, to its place and to the end of the file.
List<int> _aad(List<int> envelopeHash, int index, {required bool last}) => [
  ...envelopeHash,
  ..._u64(index),
  if (last) 1 else 0,
];

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

Uint8List _u16(int v) => Uint8List(2)..buffer.asByteData().setUint16(0, v);
Uint8List _u32(int v) => Uint8List(4)..buffer.asByteData().setUint32(0, v);
Uint8List _u64(int v) => Uint8List(8)..buffer.asByteData().setUint64(0, v);

int _readFixed(RandomAccessFile raf, int n) {
  final bytes = raf.readSync(n);
  if (bytes.length != n) throw RangeError('cut');
  final data = ByteData.sublistView(bytes);
  return switch (n) {
    2 => data.getUint16(0),
    4 => data.getUint32(0),
    _ => data.getUint64(0),
  };
}

int _readU16(RandomAccessFile raf) => _readFixed(raf, 2);
int _readU32(RandomAccessFile raf) => _readFixed(raf, 4);
int _readU64(RandomAccessFile raf) => _readFixed(raf, 8);
