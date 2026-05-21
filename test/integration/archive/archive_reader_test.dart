@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/archive/archive_reader.dart';

void main() {
  group('ArchiveReader', () {
    late Directory tmp;
    late String zipPath;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('waydir_arcreader');
      final src = Directory(p.join(tmp.path, 'src', 'sub'))
        ..createSync(recursive: true);
      File(p.join(tmp.path, 'src', 'a.txt')).writeAsStringSync('hello');
      File(p.join(src.path, 'b.txt')).writeAsStringSync('world');
      zipPath = p.join(tmp.path, 'sample.zip');
      final r = Process.runSync('zip', [
        '-qr',
        zipPath,
        '.',
      ], workingDirectory: p.join(tmp.path, 'src'));
      expect(r.exitCode, 0, reason: r.stderr.toString());
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    test('lists entries', () {
      final entries = ArchiveReader.listEntries(zipPath);
      final paths = entries.map((e) => e.path).toSet();
      expect(paths.contains('a.txt'), isTrue);
      expect(paths.contains('sub/b.txt'), isTrue);
    });

    test('extracts a single entry', () {
      final dest = p.join(tmp.path, 'out', 'b.txt');
      ArchiveReader.extractEntry(zipPath, 'sub/b.txt', dest);
      expect(File(dest).readAsStringSync(), 'world');
    });

    test('extractTree stages a single file under its basename', () {
      final stage = p.join(tmp.path, 'stage1');
      final staged = ArchiveReader.extractTree(zipPath, 'a.txt', stage);
      expect(staged, p.join(stage, 'a.txt'));
      expect(File(staged).readAsStringSync(), 'hello');
    });

    test('extractAll recreates the full archive tree', () {
      final out = p.join(tmp.path, 'all');
      ArchiveReader.extractAll(zipPath, out);
      expect(File(p.join(out, 'a.txt')).readAsStringSync(), 'hello');
      expect(File(p.join(out, 'sub', 'b.txt')).readAsStringSync(), 'world');
    });

    test('extractTree stages a whole directory subtree', () {
      final stage = p.join(tmp.path, 'stage2');
      final staged = ArchiveReader.extractTree(zipPath, 'sub', stage);
      expect(staged, p.join(stage, 'sub'));
      expect(File(p.join(staged, 'b.txt')).readAsStringSync(), 'world');
    });
  });
}
