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
  final states = store.tasks.value
      .map(
        (task) =>
            '${task.id}:${task.type.name}:${task.status.name}:conflicts=${task.conflicts.length}:errors=${task.errors.length}',
      )
      .join(', ');
  fail('Timed out waiting for task state. Tasks: $states');
}

bool isTerminalTask(FileTask task) =>
    task.status == TaskStatus.completed ||
    task.status == TaskStatus.failed ||
    task.status == TaskStatus.cancelled;
