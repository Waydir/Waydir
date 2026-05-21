@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/archive/archive_reader.dart';

void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('waydir_tar_symlink_');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test('extractAll does not create archive symlinks', () {
    final archive = Archive()
      ..addFile(ArchiveFile.symlink('passwd-link', '/etc/passwd'))
      ..addFile(ArchiveFile.bytes('regular.txt', 'ok'.codeUnits));
    final tarPath = p.join(tmpDir.path, 'payload.tar');
    File(tarPath).writeAsBytesSync(TarEncoder().encode(archive));

    final dest = p.join(tmpDir.path, 'dest');
    ArchiveReader.extractAll(tarPath, dest);

    final linkPath = p.join(dest, 'passwd-link');
    expect(FileSystemEntity.isLinkSync(linkPath), isFalse);
    if (FileSystemEntity.typeSync(linkPath) != FileSystemEntityType.notFound) {
      expect(FileSystemEntity.typeSync(linkPath), FileSystemEntityType.file);
    }
    expect(File(p.join(dest, 'regular.txt')).readAsStringSync(), 'ok');
  });
}
