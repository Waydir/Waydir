@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/fs/fs_worker_pool.dart';
import 'package:waydir/features/navigation/navigation_store.dart';
import 'package:waydir/features/operations/operation_store.dart';

void main() {
  group('NavigationStore.resolveSymlink', () {
    late Directory tmpDir;
    late OperationStore operationStore;
    late NavigationStore store;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('waydir_resolve_symlink_');
      operationStore = OperationStore();
      store = NavigationStore(
        operationStore: operationStore,
        initialPath: tmpDir.path,
      );
    });

    tearDown(() {
      store.dispose();
      operationStore.dispose();
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test(
      'replaces a file symlink with a real copy, leaving the target untouched',
      () async {
        final target = File(p.join(tmpDir.path, 'target.txt'))
          ..writeAsStringSync('hello world');
        final linkPath = p.join(tmpDir.path, 'link.txt');
        Link(linkPath).createSync(target.path);

        final entry = await FsWorkerPool.instance.stat(linkPath);
        expect(entry, isNotNull);
        expect(entry!.isSymlink, isTrue);

        final result = await store.resolveSymlink(entry);

        expect(result, isA<SymlinkOpSuccess>());
        expect(
          FileSystemEntity.typeSync(linkPath, followLinks: false),
          FileSystemEntityType.file,
        );
        expect(File(linkPath).readAsStringSync(), 'hello world');
        expect(target.existsSync(), isTrue);
        expect(target.readAsStringSync(), 'hello world');
      },
    );

    test(
      'replaces a directory symlink with a real copy, leaving the target untouched',
      () async {
        final targetDir = Directory(p.join(tmpDir.path, 'targetDir'))
          ..createSync();
        File(
          p.join(targetDir.path, 'nested.txt'),
        ).writeAsStringSync('nested content');
        final linkPath = p.join(tmpDir.path, 'linkDir');
        Link(linkPath).createSync(targetDir.path);

        final entry = await FsWorkerPool.instance.stat(linkPath);
        final result = await store.resolveSymlink(entry!);

        expect(result, isA<SymlinkOpSuccess>());
        expect(
          FileSystemEntity.typeSync(linkPath, followLinks: false),
          FileSystemEntityType.directory,
        );
        expect(
          File(p.join(linkPath, 'nested.txt')).readAsStringSync(),
          'nested content',
        );
        expect(targetDir.existsSync(), isTrue);
        expect(
          File(p.join(targetDir.path, 'nested.txt')).readAsStringSync(),
          'nested content',
        );
      },
    );

    test('fails for a broken symlink without touching the link', () async {
      final linkPath = p.join(tmpDir.path, 'broken');
      Link(linkPath).createSync(p.join(tmpDir.path, 'does_not_exist'));

      final entry = await FsWorkerPool.instance.stat(linkPath);
      final result = await store.resolveSymlink(entry!);

      expect(result, isA<SymlinkOpFailure>());
      expect(
        FileSystemEntity.typeSync(linkPath, followLinks: false),
        FileSystemEntityType.link,
      );
    });
  });
}
