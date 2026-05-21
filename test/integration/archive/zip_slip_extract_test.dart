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
    tmpDir = Directory.systemTemp.createTempSync('waydir_zip_slip_');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test('extractAll skips entries that would escape destination', () {
    final archive = Archive()
      ..addFile(ArchiveFile.bytes('../../escape.txt', 'owned'.codeUnits))
      ..addFile(ArchiveFile.bytes('safe/file.txt', 'ok'.codeUnits));
    final zipPath = p.join(tmpDir.path, 'payload.zip');
    File(zipPath).writeAsBytesSync(ZipEncoder().encode(archive));

    final dest = p.join(tmpDir.path, 'dest');
    ArchiveReader.extractAll(zipPath, dest);

    expect(File(p.join(tmpDir.path, 'escape.txt')).existsSync(), isFalse);
    expect(File(p.join(dest, 'safe', 'file.txt')).readAsStringSync(), 'ok');
  });
}
