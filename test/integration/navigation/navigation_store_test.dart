@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/features/navigation/navigation_store.dart';
import 'package:waydir/features/operations/operation_store.dart';

void main() {
  group('NavigationStore entered paths', () {
    late Directory tmpDir;
    late OperationStore operationStore;
    late NavigationStore store;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('waydir_nav_');
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

    test('does not navigate to a missing path', () async {
      final missing = p.join(tmpDir.path, 'missing');

      final ok = await store.navigateToEnteredPath(missing);

      expect(ok, isFalse);
      expect(store.currentPath.value, tmpDir.path);
      expect(store.selectedPaths.value, isEmpty);
    });

    test('navigates to a file parent and selects the file', () async {
      final child = Directory(p.join(tmpDir.path, 'child'))..createSync();
      final file = File(p.join(child.path, 'note.txt'))
        ..writeAsStringSync('content');

      final ok = await store.navigateToEnteredPath(file.path);

      expect(ok, isTrue);
      expect(store.currentPath.value, child.path);
      expect(store.selectedPaths.value, {file.path});
    });

    test('multi rename reports progress for each renamed file', () async {
      final first = File(p.join(tmpDir.path, 'one.txt'))
        ..writeAsStringSync('1');
      final second = File(p.join(tmpDir.path, 'two.txt'))
        ..writeAsStringSync('2');
      final progress = <({int processed, int total, String current})>[];

      final outcome = await store.multiRename(
        [
          (path: first.path, newName: 'renamed-one.txt'),
          (path: second.path, newName: 'renamed-two.txt'),
        ],
        onProgress: (processed, total, currentName) {
          progress.add((
            processed: processed,
            total: total,
            current: currentName,
          ));
        },
      );

      expect(outcome.succeeded, 2);
      expect(outcome.failed, 0);
      expect(progress.map((p) => p.processed), [1, 2]);
      expect(progress.every((p) => p.total == 2), isTrue);
      expect(File(p.join(tmpDir.path, 'renamed-one.txt')).existsSync(), isTrue);
      expect(File(p.join(tmpDir.path, 'renamed-two.txt')).existsSync(), isTrue);
    });
  });
}
