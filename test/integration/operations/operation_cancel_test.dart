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
    tmpDir = Directory.systemTemp.createTempSync('waydir_ops_cancel_');
    store = OperationStore();
  });

  tearDown(() {
    store.dispose();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test(
    'copy cancel during transfer leaves no temporary sibling files',
    () async {
      final src = Directory(p.join(tmpDir.path, 'src'))..createSync();
      final file = File(p.join(src.path, 'large.bin'));
      final sink = file.openSync(mode: FileMode.write);
      try {
        sink.truncateSync(128 * 1024 * 1024);
      } finally {
        sink.closeSync();
      }
      final dest = Directory(p.join(tmpDir.path, 'dest'))..createSync();

      store.enqueueCopy([src.path], dest.path);
      final running = await waitForTask(
        store,
        (task) => task.status == TaskStatus.running,
        timeout: const Duration(seconds: 20),
      );
      store.cancelTask(running.id);

      final terminal = await waitForTask(
        store,
        (task) => task.id == running.id && isTerminalTask(task),
        timeout: const Duration(seconds: 20),
      );

      expect(terminal.status, TaskStatus.cancelled);
      final leftovers = Directory(p.join(dest.path, 'src')).existsSync()
          ? Directory(p.join(dest.path, 'src'))
                .listSync(followLinks: false)
                .where(
                  (entity) => p.basename(entity.path).contains('.waydir_tmp_'),
                )
                .toList()
          : const <FileSystemEntity>[];
      expect(leftovers, isEmpty);
    },
  );

  test('copy cancel while waiting for conflicts ends cancelled', () async {
    final src = Directory(p.join(tmpDir.path, 'src'))..createSync();
    File(p.join(src.path, 'same.txt')).writeAsStringSync('source');
    final dest = Directory(p.join(tmpDir.path, 'dest'))..createSync();
    final targetDir = Directory(p.join(dest.path, 'src'))..createSync();
    File(p.join(targetDir.path, 'same.txt')).writeAsStringSync('target');

    store.enqueueCopy([src.path], dest.path);
    final waiting = await waitForTask(
      store,
      (task) => task.status == TaskStatus.waitingConflicts,
    );
    store.cancelTask(waiting.id);

    final terminal = await waitForTask(
      store,
      (task) => task.id == waiting.id && isTerminalTask(task),
    );

    expect(terminal.status, TaskStatus.cancelled);
    expect(
      File(p.join(targetDir.path, 'same.txt')).readAsStringSync(),
      'target',
    );
  });
}
