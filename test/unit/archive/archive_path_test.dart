import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/archive/archive_path.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('waydir_arcpath');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test('isArchiveName matches simple and compound extensions', () {
    expect(ArchivePath.isArchiveName('foo.zip'), isTrue);
    expect(ArchivePath.isArchiveName('foo.tar.gz'), isTrue);
    expect(ArchivePath.isArchiveName('Foo.TGZ'), isTrue);
    expect(ArchivePath.isArchiveName('notes.txt'), isFalse);
  });

  test('resolve returns null for a plain directory path', () {
    final dir = Directory(p.join(tmp.path, 'plain'))..createSync();
    expect(ArchivePath.resolve(dir.path), isNull);
  });

  test('resolve splits an archive file and inner path', () {
    final zip = File(p.join(tmp.path, 'a.zip'))..writeAsStringSync('x');
    final root = ArchivePath.resolve(zip.path);
    expect(root, isNotNull);
    expect(root!.archivePath, zip.path);
    expect(root.isRoot, isTrue);

    final inner = ArchivePath.resolve(p.join(zip.path, 'dir', 'f.txt'));
    expect(inner!.archivePath, zip.path);
    expect(inner.innerPath, p.join('dir', 'f.txt'));
    expect(inner.isRoot, isFalse);
  });

  test('resolve ignores archive-named directories', () {
    final fakeDir = Directory(p.join(tmp.path, 'weird.zip'))..createSync();
    expect(ArchivePath.resolve(fakeDir.path), isNull);
  });
}
