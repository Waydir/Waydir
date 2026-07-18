@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/models/file_operation.dart';
import 'package:waydir/features/operations/operation_store.dart';

import '../../support/ops.dart';

void main() {
  late Directory tmpDir;
  late OperationStore store;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('waydir_ops_delete_');
    store = OperationStore();
  });

  tearDown(() {
    store.dispose();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test('permanent delete removes nested trees', () async {
    final root = Directory(p.join(tmpDir.path, 'root'))..createSync();
    for (var i = 0; i < 8; i++) {
      final leaf = Directory(p.join(root.path, 'd$i', 'nested'))
        ..createSync(recursive: true);
      for (var j = 0; j < 8; j++) {
        File(p.join(leaf.path, 'f$j.txt')).writeAsStringSync('$i:$j');
      }
    }

    store.enqueueDelete([root.path]);
    final task = await waitForTask(store, isTerminalTask);

    expect(task.status, TaskStatus.completed);
    expect(task.errors, isEmpty);
    expect(root.existsSync(), isFalse);
  });

  test('permanent delete deduplicates overlapping sources', () async {
    final root = Directory(p.join(tmpDir.path, 'root'))..createSync();
    final child = Directory(p.join(root.path, 'child'))..createSync();
    File(p.join(child.path, 'file.txt')).writeAsStringSync('data');

    store.enqueueDelete([root.path, child.path]);
    final task = await waitForTask(store, isTerminalTask);

    expect(task.status, TaskStatus.completed);
    expect(task.errors, isEmpty);
    expect(root.existsSync(), isFalse);
  });
}
