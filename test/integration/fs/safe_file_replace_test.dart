@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/fs/safe_file_replace.dart';

void main() {
  group('SafeFileReplace', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('waydir_safe_replace_');
    });

    tearDown(() {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('copyFile replaces existing file contents', () async {
      final source = File(p.join(tmpDir.path, 'source.txt'))
        ..writeAsStringSync('new content');
      final destination = File(p.join(tmpDir.path, 'destination.txt'))
        ..writeAsStringSync('old content');

      await SafeFileReplace.copyFile(source, destination.path);

      expect(destination.readAsStringSync(), 'new content');
      expect(source.readAsStringSync(), 'new content');
    });

    test('copyFile preserves last modified timestamp', () async {
      final source = File(p.join(tmpDir.path, 'source.txt'))
        ..writeAsStringSync('new content');
      final modified = DateTime(2020, 1, 2, 3, 4, 5);
      source.setLastModifiedSync(modified);
      final destination = File(p.join(tmpDir.path, 'destination.txt'))
        ..writeAsStringSync('old content');

      await SafeFileReplace.copyFile(source, destination.path);

      expect(destination.lastModifiedSync(), modified);
    });

    test('copyFile removes temporary file when replace fails', () async {
      final source = File(p.join(tmpDir.path, 'source.txt'))
        ..writeAsStringSync('new content');
      final destination = Directory(p.join(tmpDir.path, 'destination'))
        ..createSync();

      await expectLater(
        SafeFileReplace.copyFile(source, destination.path),
        throwsA(isA<FileSystemException>()),
      );

      final leftovers = tmpDir
          .listSync()
          .where((e) => p.basename(e.path).contains('.waydir_tmp_'))
          .toList();
      expect(leftovers, isEmpty);
      expect(destination.existsSync(), isTrue);
    });
  });
}
