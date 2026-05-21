@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/fs/file_system_service.dart';

void main() {
  test('archiveBaseName strips simple and compound extensions', () {
    expect(FileSystemService.archiveBaseName('photos.zip'), 'photos');
    expect(FileSystemService.archiveBaseName('photos.tar.gz'), 'photos');
    expect(FileSystemService.archiveBaseName('a.b.tar.xz'), 'a.b');
    expect(FileSystemService.archiveBaseName('noext'), 'noext');
  });

  test('uniquePath appends a counter when the target exists', () {
    final tmp = Directory.systemTemp.createTempSync('waydir_uniq');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final base = p.join(tmp.path, 'out');
    expect(FileSystemService.uniquePath(base), base);
    Directory(base).createSync();
    expect(FileSystemService.uniquePath(base), '$base (1)');
  });
}
