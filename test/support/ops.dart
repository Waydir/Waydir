import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_operation.dart';
import 'package:waydir/features/operations/operation_store.dart';

Future<FileTask> waitForTask(
  OperationStore store,
  bool Function(FileTask task) predicate, {
  Duration timeout = const Duration(seconds: 10),
  Duration pollInterval = const Duration(milliseconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    for (final task in store.tasks.value) {
      if (predicate(task)) return task;
    }
    await Future<void>.delayed(pollInterval);
  }
  fail('Timed out waiting for task state');
}

bool isTerminalTask(FileTask task) =>
    task.status == TaskStatus.completed ||
    task.status == TaskStatus.failed ||
    task.status == TaskStatus.cancelled;
