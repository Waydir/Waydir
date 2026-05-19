import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/models/file_operation.dart';
import 'package:waydir/features/operations/operation_store.dart';

import '../../support/ops.dart';

void main() {
  group('OperationStore copy regressions', () {
    late Directory tmpDir;
    late OperationStore store;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('waydir_ops_reg_');
      store = OperationStore();
    });

    tearDown(() {
      store.dispose();
      if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
    });

    test('copy preserves an empty nested directory', () async {
      final src = Directory(p.join(tmpDir.path, 'src'))..createSync();
      Directory(
        p.join(src.path, 'empty', 'deep_empty'),
      ).createSync(recursive: true);
      File(p.join(src.path, 'file.txt')).writeAsStringSync('x');

      final dest = Directory(p.join(tmpDir.path, 'dest'))..createSync();
      store.enqueueCopy([src.path], dest.path);

      await waitForTask(store, (t) => t.status == TaskStatus.completed);

      expect(
        Directory(p.join(dest.path, 'src', 'empty', 'deep_empty')).existsSync(),
        isTrue,
        reason: 'empty nested directories must not be dropped',
      );
      expect(
        File(p.join(dest.path, 'src', 'file.txt')).readAsStringSync(),
        'x',
      );
    });

    test('copy recreates a symlink contained in a directory', () async {
      final src = Directory(p.join(tmpDir.path, 'src'))..createSync();
      final target = File(p.join(src.path, 'real.txt'))
        ..writeAsStringSync('payload');
      Link(p.join(src.path, 'alias.txt')).createSync(target.path);

      final dest = Directory(p.join(tmpDir.path, 'dest'))..createSync();
      store.enqueueCopy([src.path], dest.path);

      final done = await waitForTask(
        store,
        (t) => t.status == TaskStatus.completed,
      );

      expect(done.errors, isEmpty);
      final copiedLink = p.join(dest.path, 'src', 'alias.txt');
      expect(
        FileSystemEntity.isLinkSync(copiedLink),
        isTrue,
        reason: 'symlinks inside copied trees must be recreated, not skipped',
      );
      expect(File(copiedLink).readAsStringSync(), 'payload');
    });

    test(
      'cancelling during preparing ends cancelled, never completed',
      () async {
        final src = Directory(p.join(tmpDir.path, 'big'))..createSync();
        for (var i = 0; i < 4000; i++) {
          File(p.join(src.path, 'f$i.txt')).writeAsStringSync('$i');
        }
        final dest = Directory(p.join(tmpDir.path, 'dest'))..createSync();

        store.enqueueCopy([src.path], dest.path);

        final preparing = await waitForTask(
          store,
          (t) => t.status == TaskStatus.preparing,
        );
        store.cancelTask(preparing.id);

        final terminal = await waitForTask(
          store,
          (t) =>
              t.id == preparing.id &&
              (t.status == TaskStatus.cancelled ||
                  t.status == TaskStatus.completed ||
                  t.status == TaskStatus.failed),
        );
        expect(
          terminal.status,
          TaskStatus.cancelled,
          reason: 'cancel in preparing must not silently run to completion',
        );
      },
    );
  });
}
