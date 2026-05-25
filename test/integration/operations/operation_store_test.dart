@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/models/file_operation.dart';
import 'package:waydir/features/operations/operation_store.dart';

import '../../support/ops.dart';

void main() {
  group('OperationStore conflicts', () {
    late Directory tmpDir;
    late OperationStore store;

    setUp(() {
      tmpDir = Directory.systemTemp.createTempSync('waydir_ops_');
      store = OperationStore();
    });

    tearDown(() {
      store.dispose();
      if (tmpDir.existsSync()) {
        tmpDir.deleteSync(recursive: true);
      }
    });

    test('copy waits for conflict resolution', () async {
      final sourceRoot = Directory(p.join(tmpDir.path, 'source'));
      final sourceFolder = Directory(p.join(sourceRoot.path, 'folder'))
        ..createSync(recursive: true);
      final sourceExtra = Directory(p.join(sourceFolder.path, 'extra'))
        ..createSync();
      File(p.join(sourceFolder.path, 'file.txt')).writeAsStringSync('new');
      File(p.join(sourceExtra.path, 'extra.txt')).writeAsStringSync('extra');

      final destination = Directory(p.join(tmpDir.path, 'destination'))
        ..createSync();
      final existingFolder = Directory(p.join(destination.path, 'folder'))
        ..createSync();
      File(p.join(existingFolder.path, 'file.txt')).writeAsStringSync('old');

      store.enqueueCopy([sourceFolder.path], destination.path);

      final waiting = await waitForTask(
        store,
        (task) => task.status == TaskStatus.waitingConflicts,
      );
      expect(waiting.conflicts, isNotEmpty);
      expect(
        Directory(p.join(existingFolder.path, 'extra')).existsSync(),
        isFalse,
      );

      store.resolveCurrentConflict(waiting.id, ConflictResolution.rename);

      final done = await waitForTask(
        store,
        (task) => task.status == TaskStatus.completed,
      );

      expect(done.errors, isEmpty);
      expect(
        File(p.join(existingFolder.path, 'file.txt')).readAsStringSync(),
        'old',
      );
      expect(
        File(p.join(existingFolder.path, 'file (1).txt')).readAsStringSync(),
        'new',
      );
      expect(
        File(
          p.join(existingFolder.path, 'extra', 'extra.txt'),
        ).readAsStringSync(),
        'extra',
      );
    });

    test('move keeps both when target folder exists', () async {
      final sourceRoot = Directory(p.join(tmpDir.path, 'source'));
      final sourceFolder = Directory(p.join(sourceRoot.path, 'folder'))
        ..createSync(recursive: true);
      File(p.join(sourceFolder.path, 'file.txt')).writeAsStringSync('new');

      final destination = Directory(p.join(tmpDir.path, 'destination'))
        ..createSync();
      final existingFolder = Directory(p.join(destination.path, 'folder'))
        ..createSync();
      File(p.join(existingFolder.path, 'file.txt')).writeAsStringSync('old');

      store.enqueueMove([sourceFolder.path], destination.path);

      final waiting = await waitForTask(
        store,
        (task) => task.status == TaskStatus.waitingConflicts,
      );
      expect(waiting.conflicts.single.sourcePath, sourceFolder.path);

      store.resolveCurrentConflict(waiting.id, ConflictResolution.rename);

      final done = await waitForTask(
        store,
        (task) => task.status == TaskStatus.completed,
      );

      final renamedFolder = Directory(p.join(destination.path, 'folder (1)'));
      expect(done.errors, isEmpty);
      expect(sourceFolder.existsSync(), isFalse);
      expect(
        File(p.join(existingFolder.path, 'file.txt')).readAsStringSync(),
        'old',
      );
      expect(
        File(p.join(renamedFolder.path, 'file.txt')).readAsStringSync(),
        'new',
      );
    });

    test('extract task unpacks an archive into the destination', () async {
      final src = Directory(p.join(tmpDir.path, 'payload', 'sub'))
        ..createSync(recursive: true);
      File(p.join(tmpDir.path, 'payload', 'a.txt')).writeAsStringSync('hi');
      File(p.join(src.path, 'b.txt')).writeAsStringSync('deep');
      final zip = p.join(tmpDir.path, 'bundle.zip');
      final z = Process.runSync('zip', [
        '-qr',
        zip,
        '.',
      ], workingDirectory: p.join(tmpDir.path, 'payload'));
      expect(z.exitCode, 0, reason: z.stderr.toString());

      final dest = Directory(p.join(tmpDir.path, 'out'))..createSync();
      store.enqueueExtract([zip], dest.path);

      final done = await waitForTask(
        store,
        (task) =>
            task.type == TaskType.extract &&
            task.status == TaskStatus.completed,
      );
      expect(done.errors, isEmpty);
      expect(File(p.join(dest.path, 'a.txt')).readAsStringSync(), 'hi');
      expect(
        File(p.join(dest.path, 'sub', 'b.txt')).readAsStringSync(),
        'deep',
      );
    });

    test('extract prompts on conflict and keeps both on rename', () async {
      File(p.join(tmpDir.path, 'a.txt')).writeAsStringSync('fresh');
      final zip = p.join(tmpDir.path, 'one.zip');
      final z = Process.runSync('zip', [
        '-qr',
        zip,
        'a.txt',
      ], workingDirectory: tmpDir.path);
      expect(z.exitCode, 0, reason: z.stderr.toString());

      final dest = Directory(p.join(tmpDir.path, 'out'))..createSync();
      File(p.join(dest.path, 'a.txt')).writeAsStringSync('old');
      store.enqueueExtract([zip], dest.path);

      final waiting = await waitForTask(
        store,
        (task) =>
            task.type == TaskType.extract &&
            task.status == TaskStatus.waitingConflicts,
      );
      expect(waiting.conflicts, isNotEmpty);
      store.resolveCurrentConflict(waiting.id, ConflictResolution.rename);

      final done = await waitForTask(
        store,
        (task) =>
            task.type == TaskType.extract &&
            task.status == TaskStatus.completed,
      );
      expect(done.errors, isEmpty);
      expect(File(p.join(dest.path, 'a.txt')).readAsStringSync(), 'old');
      expect(File(p.join(dest.path, 'a (1).txt')).readAsStringSync(), 'fresh');
    });

    test('compress task reports byte progress', () async {
      final src = p.join(tmpDir.path, 'payload.bin');
      File(src).writeAsBytesSync(List<int>.filled(128 * 1024, 7));
      final dest = p.join(tmpDir.path, 'payload.zip');

      store.enqueueCompress([src], dest, format: 'zip', level: 'normal');

      final done = await waitForTask(
        store,
        (task) =>
            task.type == TaskType.compress &&
            task.status == TaskStatus.completed,
      );

      expect(done.errors, isEmpty);
      expect(done.totalBytes, 128 * 1024 * 2);
      expect(done.processedBytes, done.totalBytes);
      expect(File(dest).existsSync(), isTrue);
    });
  });
}
