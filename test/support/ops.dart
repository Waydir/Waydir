import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_operation.dart';
import 'package:waydir/features/operations/operation_store.dart';

Future<FileTask> waitForTask(
  OperationStore store,
  bool Function(FileTask task) predicate, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    for (final task in store.tasks.value) {
      if (predicate(task)) return task;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for task state');
}
