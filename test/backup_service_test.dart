import 'dart:io';

import 'package:abarrotes/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('backup y restauracion incluye archivos e imagenes', () async {
    final root = Directory(p.join(Directory.current.path, 'build', 'test_tmp', 'backup_service'));
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
    await root.create(recursive: true);

    final sourceDocs = Directory(p.join(root.path, 'docs'));
    await sourceDocs.create(recursive: true);

    await File(p.join(sourceDocs.path, 'configuracionBox.hive')).writeAsBytes([1, 2, 3]);
    await File(p.join(sourceDocs.path, 'productosBox.hive')).writeAsBytes([9, 8, 7]);
    await File(p.join(sourceDocs.path, 'productosBox.hive.lock')).writeAsString('lock');

    final productosDir = Directory(p.join(sourceDocs.path, 'productos'));
    await productosDir.create(recursive: true);
    await File(p.join(productosDir.path, 'prod_1.jpg')).writeAsBytes([4, 5, 6, 7]);
    await File(p.join(sourceDocs.path, 'logo_1.png')).writeAsBytes([10, 11]);

    final outDir = Directory(p.join(root.path, 'out'));
    await outDir.create(recursive: true);

    final service = BackupService();
    final backupFile = await service.createBackup(
      sourceDocumentsDir: sourceDocs,
      destinationDir: outDir,
      now: DateTime.utc(2026, 1, 1, 0, 0, 0),
    );
    expect(await backupFile.exists(), isTrue);

    final targetDocs = Directory(p.join(root.path, 'restored'));
    await targetDocs.create(recursive: true);
    await File(p.join(targetDocs.path, 'stale.txt')).writeAsString('stale');

    await service.restoreBackup(
      zipFile: backupFile,
      targetDocumentsDir: targetDocs,
    );

    expect(await File(p.join(targetDocs.path, 'stale.txt')).exists(), isFalse);
    expect(await File(p.join(targetDocs.path, 'configuracionBox.hive')).readAsBytes(), equals([1, 2, 3]));
    expect(await File(p.join(targetDocs.path, 'productosBox.hive')).readAsBytes(), equals([9, 8, 7]));
    expect(await File(p.join(targetDocs.path, 'productos', 'prod_1.jpg')).readAsBytes(), equals([4, 5, 6, 7]));
    expect(await File(p.join(targetDocs.path, 'logo_1.png')).readAsBytes(), equals([10, 11]));
    expect(await File(p.join(targetDocs.path, 'productosBox.hive.lock')).exists(), isFalse);
  });
}

