import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_operation.dart';

void main() {
  group('FileTask', () {
    test('creates with correct defaults', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/home/user/file.txt'],
        destination: '/home/user/backup',
        startTime: DateTime.now(),
      );

      expect(task.status, TaskStatus.queued);
      expect(task.progress, 0.0);
      expect(task.totalFiles, 0);
      expect(task.processedFiles, 0);
      expect(task.totalBytes, isNull);
      expect(task.processedBytes, 0);
      expect(task.currentFile, '');
      expect(task.conflicts, []);
      expect(task.resolutions, {});
      expect(task.errors, []);
      expect(task.endTime, isNull);
    });

    test('creates with custom values', () {
      final now = DateTime.now();
      final task = FileTask(
        id: '1',
        type: TaskType.delete,
        sources: ['/tmp/a', '/tmp/b'],
        status: TaskStatus.running,
        progress: 0.5,
        totalFiles: 10,
        processedFiles: 5,
        totalBytes: 1024,
        processedBytes: 512,
        currentFile: 'file5.txt',
        startTime: now,
      );

      expect(task.type, TaskType.delete);
      expect(task.sources, ['/tmp/a', '/tmp/b']);
      expect(task.status, TaskStatus.running);
      expect(task.progress, 0.5);
      expect(task.totalFiles, 10);
      expect(task.processedFiles, 5);
      expect(task.totalBytes, 1024);
      expect(task.processedBytes, 512);
      expect(task.currentFile, 'file5.txt');
      expect(task.destination, isNull);
    });
  });

  group('TaskLabel', () {
    test('title for single copy', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/home/user/report.pdf'],
        destination: '/backup',
        startTime: DateTime.now(),
      );
      expect(TaskLabel.title(task), 'Copying report.pdf');
    });

    test('title for multiple copy', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a', '/b', '/c'],
        destination: '/backup',
        startTime: DateTime.now(),
      );
      expect(TaskLabel.title(task), 'Copying 3 items');
    });

    test('title for single move', () {
      final task = FileTask(
        id: '0',
        type: TaskType.move,
        sources: ['/home/user/project'],
        destination: '/docs',
        startTime: DateTime.now(),
      );
      expect(TaskLabel.title(task), 'Moving project');
    });

    test('title for multiple delete', () {
      final task = FileTask(
        id: '0',
        type: TaskType.delete,
        sources: ['/a', '/b'],
        startTime: DateTime.now(),
      );
      expect(TaskLabel.title(task), 'Deleting 2 items');
    });

    test('subtitle for queued', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        status: TaskStatus.queued,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.subtitle(task), 'Waiting...');
    });

    test('subtitle for preparing', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        status: TaskStatus.preparing,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.subtitle(task), 'Scanning files...');
    });

    test('subtitle for waitingConflicts', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        status: TaskStatus.waitingConflicts,
        conflicts: [
          ConflictInfo(
            sourcePath: '/a/f.txt',
            targetPath: '/b/f.txt',
            name: 'f.txt',
            sourceSize: 100,
            targetSize: 200,
            sourceModified: DateTime.now(),
            targetModified: DateTime.now(),
          ),
        ],
        startTime: DateTime.now(),
      );
      expect(TaskLabel.subtitle(task), '1 conflicts');
    });

    test('subtitle for running', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        status: TaskStatus.running,
        currentFile: 'photo.jpg',
        processedFiles: 5,
        totalFiles: 10,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.subtitle(task), 'photo.jpg (5/10)');
    });

    test('subtitle for completed with errors', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        status: TaskStatus.completed,
        errors: [TaskError(path: '/a/f.txt', message: 'permission denied')],
        startTime: DateTime.now(),
      );
      expect(TaskLabel.subtitle(task), 'Completed with 1 errors');
    });

    test('subtitle for completed without errors', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        status: TaskStatus.completed,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.subtitle(task), 'Completed');
    });

    test('subtitle for failed', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        status: TaskStatus.failed,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.subtitle(task), 'Failed');
    });

    test('subtitle for cancelled', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        status: TaskStatus.cancelled,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.subtitle(task), 'Cancelled');
    });

    test('progressText with bytes', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        totalBytes: 1024 * 1024 * 2,
        processedBytes: 1024 * 512,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.progressText(task), '512.0 KB / 2.0 MB');
    });

    test('progressText without bytes', () {
      final task = FileTask(
        id: '0',
        type: TaskType.delete,
        sources: ['/a'],
        totalFiles: 100,
        processedFiles: 42,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.progressText(task), '(42/100)');
    });
  });

  group('TaskLabel._formatBytes', () {
    test('formats bytes correctly', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        totalBytes: 500,
        processedBytes: 500,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.progressText(task), '500 B / 500 B');
    });

    test('formats KB correctly', () {
      final task = FileTask(
        id: '0',
        type: TaskType.copy,
        sources: ['/a'],
        totalBytes: 2048,
        processedBytes: 1024,
        startTime: DateTime.now(),
      );
      expect(TaskLabel.progressText(task), '1.0 KB / 2.0 KB');
    });
  });

  group('Message classes', () {
    test('StartCommand holds values', () {
      final cmd = StartCommand(
        type: TaskType.copy,
        sources: ['/a'],
        destination: '/b',
      );
      expect(cmd.type, TaskType.copy);
      expect(cmd.sources, ['/a']);
      expect(cmd.destination, '/b');
    });

    test('ExecuteCommand holds resolutions', () {
      final cmd = ExecuteCommand(
        resolutions: {'/a': ConflictResolution.overwrite},
      );
      expect(cmd.resolutions, {'/a': ConflictResolution.overwrite});
    });

    test('CancelCommand can be created', () {
      expect(CancelCommand(), isA<CancelCommand>());
    });

    test('TaskDoneMessage holds values', () {
      final msg = TaskDoneMessage(
        cancelled: true,
        errors: [TaskError(path: '/a', message: 'oops')],
      );
      expect(msg.cancelled, true);
      expect(msg.errors.length, 1);
    });

    test('ProgressMessage holds values', () {
      final msg = ProgressMessage(
        processedFiles: 5,
        processedBytes: 1024,
        currentFile: 'test.txt',
      );
      expect(msg.processedFiles, 5);
      expect(msg.processedBytes, 1024);
      expect(msg.currentFile, 'test.txt');
    });

    test('PreScanResultMessage holds values', () {
      final msg = PreScanResultMessage(
        totalFiles: 10,
        totalBytes: 2048,
        allPaths: ['/a', '/b'],
        conflicts: [],
      );
      expect(msg.totalFiles, 10);
      expect(msg.totalBytes, 2048);
      expect(msg.allPaths.length, 2);
    });

    test('ErrorMessage holds values', () {
      final msg = ErrorMessage(path: '/a', message: 'error');
      expect(msg.path, '/a');
      expect(msg.message, 'error');
    });
  });
}
