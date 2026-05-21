@Tags(<String>['integration'])
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/core/fs/file_system_service.dart';

void main() {
  group('FileSystemService', () {
    late Directory tmpDir;

    setUp(() {
      tmpDir = Directory(
        '${Directory.systemTemp.path}/fm_test_${DateTime.now().millisecondsSinceEpoch}',
      );
      tmpDir.createSync(recursive: true);
    });

    tearDown(() {
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    group('listDirectory', () {
      test('returns empty list for empty directory', () async {
        final entries = await FileSystemService.listDirectory(tmpDir.path);
        expect(entries, isEmpty);
      });

      test('lists files and folders', () async {
        File('${tmpDir.path}/file.txt').writeAsStringSync('hello');
        Directory('${tmpDir.path}/subdir').createSync();

        final entries = await FileSystemService.listDirectory(tmpDir.path);

        expect(entries.length, 2);
        expect(
          entries.any(
            (e) => e.name == 'file.txt' && e.type == FileItemType.file,
          ),
          isTrue,
        );
        expect(
          entries.any(
            (e) => e.name == 'subdir' && e.type == FileItemType.folder,
          ),
          isTrue,
        );
      });

      test('folders come first in sort order', () async {
        File('${tmpDir.path}/a_file.txt').writeAsStringSync('a');
        Directory('${tmpDir.path}/z_folder').createSync();

        final entries = await FileSystemService.listDirectory(tmpDir.path);

        expect(entries.first.name, 'z_folder');
        expect(entries.first.type, FileItemType.folder);
        expect(entries.last.name, 'a_file.txt');
        expect(entries.last.type, FileItemType.file);
      });

      test('sorts alphabetically within same type', () async {
        File('${tmpDir.path}/c.txt').writeAsStringSync('c');
        File('${tmpDir.path}/a.txt').writeAsStringSync('a');
        File('${tmpDir.path}/b.txt').writeAsStringSync('b');

        final entries = await FileSystemService.listDirectory(tmpDir.path);

        expect(entries[0].name, 'a.txt');
        expect(entries[1].name, 'b.txt');
        expect(entries[2].name, 'c.txt');
      });

      test('throws for non-existent directory', () async {
        expect(
          FileSystemService.listDirectory('/tmp/this_does_not_exist_xyz'),
          throwsA(isA<FileSystemException>()),
        );
      });

      test('populates size and modified for files', () async {
        File('${tmpDir.path}/sized.txt').writeAsStringSync('hello world');

        final entries = await FileSystemService.listDirectory(tmpDir.path);
        final file = entries.firstWhere((e) => e.name == 'sized.txt');

        expect(file.size, greaterThan(0));
        expect(file.modified, isNotNull);
      });

      test('FileEntry extension is correct for listed files', () async {
        File('${tmpDir.path}/script.dart').writeAsStringSync('void main() {}');

        final entries = await FileSystemService.listDirectory(tmpDir.path);
        final file = entries.firstWhere((e) => e.name == 'script.dart');

        expect(file.extension, 'dart');
      });
    });

    group('directoryExists', () {
      test('returns true for existing directory', () async {
        expect(await FileSystemService.directoryExists(tmpDir.path), isTrue);
      });

      test('returns false for non-existent directory', () async {
        expect(
          await FileSystemService.directoryExists('/tmp/nope_xyz_123'),
          isFalse,
        );
      });

      test('returns false for a file path', () async {
        final file = File('${tmpDir.path}/a.txt')..writeAsStringSync('x');
        expect(await FileSystemService.directoryExists(file.path), isFalse);
      });
    });

    group('createDirectory', () {
      test('creates a new directory', () async {
        final path = '${tmpDir.path}/new_dir';
        await FileSystemService.createDirectory(path);
        expect(Directory(path).existsSync(), isTrue);
      });

      test('creates nested directories with recursive', () async {
        final path = '${tmpDir.path}/a/b/c';
        await FileSystemService.createDirectory(path);
        expect(Directory(path).existsSync(), isTrue);
      });
    });
  });
}
