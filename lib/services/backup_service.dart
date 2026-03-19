import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

class BackupService {
  static const int formatVersion = 1;
  static const String _manifestName = 'manifest.json';
  static const String _documentsPrefix = 'documents';
  static const String _backupPrefix = 'backup_abarrotes_';

  Future<File> createBackup({
    required Directory sourceDocumentsDir,
    required Directory destinationDir,
    DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).toIso8601String().replaceAll(':', '-');
    final backupName = '$_backupPrefix$timestamp.zip';
    final backupPath = p.join(destinationDir.path, backupName);

    final archive = Archive();

    final manifest = <String, Object?>{
      'formatVersion': formatVersion,
      'createdAt': (now ?? DateTime.now()).toUtc().toIso8601String(),
      'root': _documentsPrefix,
    };
    archive.addFile(ArchiveFile.string(_manifestName, jsonEncode(manifest)));

    await for (final entity in sourceDocumentsDir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      if (_shouldSkipSourceFile(entity)) continue;

      final relative = p.relative(entity.path, from: sourceDocumentsDir.path);
      final segments = p.split(relative);
      final zipPath = p.posix.joinAll([_documentsPrefix, ...segments]);

      final bytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
    }

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw StateError('No se pudo crear el ZIP.');
    }

    final outFile = File(backupPath);
    await outFile.writeAsBytes(zipBytes, flush: true);
    return outFile;
  }

  Future<void> restoreBackup({
    required File zipFile,
    required Directory targetDocumentsDir,
  }) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final hasManifest = archive.any((f) => f.name == _manifestName);
    if (!hasManifest) {
      throw const FormatException('Backup inválido o antiguo (sin manifest).');
    }

    await _clearDirectory(targetDocumentsDir);

    for (final entry in archive) {
      final name = entry.name;
      if (name == _manifestName) continue;
      if (!name.startsWith('$_documentsPrefix/')) continue;
      if (!entry.isFile) continue;

      final relativePosix = p.posix.normalize(p.posix.relative(name, from: _documentsPrefix));
      if (relativePosix.startsWith('..') || p.posix.isAbsolute(relativePosix)) {
        continue;
      }

      final segments = p.posix.split(relativePosix);
      if (segments.isEmpty) continue;
      if (segments.last.toLowerCase().endsWith('.lock')) continue;

      final destinationPath = p.joinAll([targetDocumentsDir.path, ...segments]);
      final destinationFile = File(destinationPath);
      await destinationFile.parent.create(recursive: true);

      final data = entry.content as List<int>;
      await destinationFile.writeAsBytes(data, flush: true);
    }

    await _deleteHiveLocks(targetDocumentsDir);
  }

  bool _shouldSkipSourceFile(File file) {
    final base = p.basename(file.path).toLowerCase();
    if (base.endsWith('.lock')) return true;
    if (base.startsWith(_backupPrefix) && base.endsWith('.zip')) return true;
    return false;
  }

  Future<void> _clearDirectory(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      return;
    }

    final entities = await dir.list(recursive: true, followLinks: false).toList();
    entities.sort((a, b) => b.path.length.compareTo(a.path.length));

    for (final entity in entities) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        // Ignorar: mejor esfuerzo.
      }
    }
  }

  Future<void> _deleteHiveLocks(Directory dir) async {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.lock')) {
        try {
          await entity.delete();
        } catch (_) {
          // Ignorar: mejor esfuerzo.
        }
      }
    }
  }
}
