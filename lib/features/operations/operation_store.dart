import 'dart:async';
import 'dart:isolate';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/app_notification.dart';
import '../../core/models/file_operation.dart';
import '../../core/fs/file_system_service.dart';
import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';
import '../../ui/overlays/notification_store.dart';
import '../../ui/theme/app_theme.dart';

class _WorkerHandle {
  final Isolate isolate;
  final SendPort sendPort;
  final ReceivePort receivePort;
  final ReceivePort errorPort;
  final ReceivePort exitPort;
  final StreamSubscription subscription;
  bool _disposed = false;

  _WorkerHandle(
    this.isolate,
    this.sendPort,
    this.receivePort,
    this.errorPort,
    this.exitPort,
    this.subscription,
  );

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    subscription.cancel();
    receivePort.close();
    errorPort.close();
    exitPort.close();
    isolate.kill(priority: Isolate.immediate);
  }
}

class OperationStore {
  final NotificationStore? notificationStore;

  OperationStore({this.notificationStore});

  final tasks = signal<List<FileTask>>([]);

  final taskCompleted = Signal<String?>(null, debugLabel: 'taskCompleted');

  late final activeTask = computed(
    () => tasks.value.firstWhereOrNull((t) => t.status == TaskStatus.running),
  );

  late final activeCount = computed(
    () => tasks.value
        .where(
          (t) =>
              t.status == TaskStatus.running ||
              t.status == TaskStatus.queued ||
              t.status == TaskStatus.preparing ||
              t.status == TaskStatus.waitingConflicts ||
              t.status == TaskStatus.cancelling,
        )
        .length,
  );

  final _queue = <FileTask>[];
  bool _processing = false;
  _WorkerHandle? _currentWorker;
  String? _currentTaskId;
  int _idCounter = 0;

  final _cleanupTimers = <String, Timer>{};
  final _conflictQueues = <String, List<ConflictInfo>>{};
  final _conflictNotifIds = <String, String>{};

  void enqueueCopy(List<String> sources, String destination) =>
      _enqueueTransfer(TaskType.copy, sources, destination);

  void enqueueMove(List<String> sources, String destination) =>
      _enqueueTransfer(TaskType.move, sources, destination);

  Future<void> _enqueueTransfer(
    TaskType type,
    List<String> sources,
    String destination,
  ) async {
    final List<String> resolved;
    try {
      resolved = await FileSystemService.materializeArchiveSources(sources);
    } catch (_) {
      return;
    }
    final sep = PlatformPaths.separator;
    final filtered = resolved.where((s) {
      final name = PlatformPaths.fileName(s);
      final dst = '$destination$sep$name';
      return s != dst;
    }).toList();
    if (filtered.isEmpty) return;

    final task = FileTask(
      id: '${_idCounter++}',
      type: type,
      sources: filtered,
      destination: destination,
      startTime: DateTime.now(),
    );
    _enqueue(task);
  }

  void enqueueDelete(List<String> sources) {
    if (sources.isEmpty) return;

    final task = FileTask(
      id: '${_idCounter++}',
      type: TaskType.delete,
      sources: sources,
      startTime: DateTime.now(),
    );
    _enqueue(task);
  }

  void enqueueTrash(List<String> sources) {
    if (sources.isEmpty) return;

    final task = FileTask(
      id: '${_idCounter++}',
      type: TaskType.trash,
      sources: sources,
      startTime: DateTime.now(),
    );
    _enqueue(task);
  }

  void enqueueExtract(List<String> sources, String destination) {
    if (sources.isEmpty) return;

    final task = FileTask(
      id: '${_idCounter++}',
      type: TaskType.extract,
      sources: sources,
      destination: destination,
      startTime: DateTime.now(),
    );
    _enqueue(task);
  }

  void enqueueCompress(
    List<String> sources,
    String destination, {
    required String format,
    required String level,
  }) {
    if (sources.isEmpty) return;

    final task = FileTask(
      id: '${_idCounter++}',
      type: TaskType.compress,
      sources: sources,
      destination: destination,
      options: {'format': format, 'level': level},
      startTime: DateTime.now(),
    );
    _enqueue(task);
  }

  void enqueueArchiveEdit({
    required String archivePath,
    required String displayDir,
    List<String> addSources = const [],
    String addInner = '',
    List<String> deleteInner = const [],
    String? renameFromInner,
    String? renameToName,
  }) {
    if (addSources.isEmpty && deleteInner.isEmpty && renameFromInner == null) {
      return;
    }
    final task = FileTask(
      id: '${_idCounter++}',
      type: TaskType.archiveEdit,
      sources: addSources,
      destination: displayDir,
      options: {
        'archive': archivePath,
        'addInner': addInner,
        'deleteInner': deleteInner.join('\n'),
        'renameFrom': ?renameFromInner,
        'renameTo': ?renameToName,
      },
      startTime: DateTime.now(),
    );
    _enqueue(task);
  }

  void cancelTask(String id) {
    final task = tasks.value.firstWhereOrNull((t) => t.id == id);
    if (task == null) return;

    if (task.status == TaskStatus.running ||
        task.status == TaskStatus.preparing) {
      task.status = TaskStatus.cancelling;
      _updateTask(task);
      _currentWorker?.sendPort.send(CancelCommand());
    } else if (task.status == TaskStatus.queued) {
      _queue.removeWhere((t) => t.id == id);
      task.status = TaskStatus.cancelled;
      task.endTime = DateTime.now();
      _updateTask(task);
      _scheduleCleanup(task);
    }
    _dismissTaskConflictNotification(id);
  }

  void resolveCurrentConflict(
    String taskId,
    ConflictResolution resolution, {
    bool applyToAll = false,
  }) {
    final task = tasks.value.firstWhereOrNull((t) => t.id == taskId);
    if (task == null) return;
    if (_currentTaskId != taskId) return;
    if (_currentWorker == null) return;

    final queue = _conflictQueues[taskId];
    if (queue == null || queue.isEmpty) return;
    final head = queue.removeAt(0);

    if (applyToAll) {
      task.applyToAllResolution = resolution;
      task.conflicts = const [];
      queue.clear();
    } else {
      task.resolutions = Map<String, ConflictResolution>.from(task.resolutions)
        ..[head.sourcePath] = resolution;
      task.conflicts = task.conflicts
          .where((c) => c.sourcePath != head.sourcePath)
          .toList();
    }
    if (queue.isEmpty && task.status == TaskStatus.waitingConflicts) {
      task.status = TaskStatus.running;
    }
    _updateTask(task);

    _currentWorker!.sendPort.send(
      ConflictDecisionCommand(
        sourcePath: head.sourcePath,
        resolution: resolution,
        applyToAll: applyToAll,
      ),
    );

    _renderConflictNotification(task);
  }

  void clearCompleted() {
    final toRemove = tasks.value
        .where(
          (t) =>
              t.status == TaskStatus.completed ||
              t.status == TaskStatus.failed ||
              t.status == TaskStatus.cancelled,
        )
        .toList();
    for (final t in toRemove) {
      _cleanupTimers[t.id]?.cancel();
      _cleanupTimers.remove(t.id);
    }
    tasks.value = tasks.value
        .where(
          (t) =>
              t.status != TaskStatus.completed &&
              t.status != TaskStatus.failed &&
              t.status != TaskStatus.cancelled,
        )
        .toList();
  }

  void _enqueue(FileTask task) {
    _queue.add(task);
    _addTask(task);
    _showStartNotification(task);
    _processQueue();
  }

  void _addTask(FileTask task) {
    tasks.value = [...tasks.value, task];
  }

  void _updateTask(FileTask task) {
    tasks.value = [...tasks.value];
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    if (_queue.isEmpty) return;

    _processing = true;
    final task = _queue.removeAt(0);

    await _executeTask(task);

    _currentWorker = null;
    _currentTaskId = null;
    _processing = false;

    _processQueue();
  }

  Future<void> _executeTask(FileTask task) async {
    task.status = TaskStatus.preparing;
    _updateTask(task);
    _currentTaskId = task.id;

    void Function(List<dynamic>) entryPoint;
    switch (task.type) {
      case TaskType.copy:
        entryPoint = FileSystemService.copyWorker;
      case TaskType.move:
        entryPoint = FileSystemService.moveWorker;
      case TaskType.delete:
        entryPoint = FileSystemService.deleteWorker;
      case TaskType.trash:
        entryPoint = FileSystemService.trashWorker;
      case TaskType.extract:
        entryPoint = FileSystemService.extractWorker;
      case TaskType.compress:
        entryPoint = FileSystemService.compressWorker;
      case TaskType.archiveEdit:
        entryPoint = FileSystemService.archiveEditWorker;
    }

    try {
      final handle = await _spawnWorker(entryPoint);
      _currentWorker = handle;

      handle.sendPort.send(
        StartCommand(
          type: task.type,
          sources: task.sources,
          destination: task.destination,
          options: task.options,
        ),
      );

      final completer = Completer<void>();

      void handleMessage(dynamic msg) {
        if (completer.isCompleted) return;
        if (msg is! WorkerMessage) return;

        if (msg is PreScanResultMessage) {
          task.totalFiles = msg.totalFiles;
          task.totalBytes = msg.totalBytes;
          task.conflicts = msg.conflicts;

          task.status = msg.conflicts.isEmpty
              ? TaskStatus.running
              : TaskStatus.waitingConflicts;
          _updateTask(task);

          handle.sendPort.send(ExecuteCommand(resolutions: {}));
        } else if (msg is ConflictPromptMessage) {
          _enqueueConflict(task, msg.conflict);
        } else if (msg is ProgressMessage) {
          task.processedFiles = msg.processedFiles;
          task.processedBytes = msg.processedBytes;
          task.currentFile = msg.currentFile;
          if (task.totalFiles > 0) {
            task.progress = task.processedFiles / task.totalFiles;
          }
          _updateTask(task);
        } else if (msg is ErrorMessage) {
          task.errors = [
            ...task.errors,
            TaskError(path: msg.path, message: msg.message),
          ];
          _updateTask(task);
        } else if (msg is TaskDoneMessage) {
          final allErrors = [...task.errors, ...msg.errors];
          if (msg.cancelled) {
            task.status = TaskStatus.cancelled;
          } else if (allErrors.isNotEmpty && task.processedFiles == 0) {
            task.status = TaskStatus.failed;
          } else {
            task.status = TaskStatus.completed;
          }
          task.errors = allErrors;
          task.endTime = DateTime.now();
          task.progress = task.status == TaskStatus.completed
              ? 1.0
              : task.progress;
          _updateTask(task);

          _dismissTaskConflictNotification(task.id);
          _showFinishNotification(task);
          taskCompleted.value = task.id;

          _scheduleCleanup(task);
          handle.dispose();
          completer.complete();
        }
      }

      handle.subscription.onData(handleMessage);

      handle.errorPort.listen((err) {
        if (completer.isCompleted) return;
        log.error('operation', 'task ${task.id} isolate error', error: err);
        task.status = TaskStatus.failed;
        task.errors = [
          ...task.errors,
          TaskError(path: '', message: err.toString()),
        ];
        task.endTime = DateTime.now();
        _updateTask(task);
        _dismissTaskConflictNotification(task.id);
        _showFinishNotification(task);
        taskCompleted.value = task.id;
        _scheduleCleanup(task);
        handle.dispose();
        completer.complete();
      });

      handle.exitPort.listen((_) {
        if (completer.isCompleted) return;
        log.error('operation', 'task ${task.id} worker exited unexpectedly');
        task.status = TaskStatus.failed;
        task.errors = [
          ...task.errors,
          const TaskError(path: '', message: 'Worker exited unexpectedly'),
        ];
        task.endTime = DateTime.now();
        _updateTask(task);
        _dismissTaskConflictNotification(task.id);
        _showFinishNotification(task);
        taskCompleted.value = task.id;
        _scheduleCleanup(task);
        handle.dispose();
        completer.complete();
      });

      await completer.future;
    } catch (e, s) {
      log.error('operation', 'task ${task.id} failed', error: e, stack: s);
      task.status = TaskStatus.failed;
      task.errors = [TaskError(path: '', message: e.toString())];
      task.endTime = DateTime.now();
      _updateTask(task);
      _dismissTaskConflictNotification(task.id);
      _showFinishNotification(task);
      _scheduleCleanup(task);
    }
  }

  void _showStartNotification(FileTask task) {
    notificationStore?.add(
      AppNotification(
        id: 'task_start_${task.id}',
        title: TaskLabel.title(task),
        message: t.tasks.status.scanning,
        type: NotificationType.autoDismiss,
        autoDismissDuration: const Duration(seconds: 2),
        icon: _iconForType(task.type),
        accentColor: AppColors.accent,
      ),
    );
  }

  void _showFinishNotification(FileTask task) {
    final ns = notificationStore;
    if (ns == null) return;

    final title = TaskLabel.title(task);
    String message;
    Color color;
    IconData icon;
    NotificationType type = NotificationType.autoDismiss;

    switch (task.status) {
      case TaskStatus.completed when task.errors.isNotEmpty:
        message = t.tasks.status.completedWithErrors(count: task.errors.length);
        color = AppColors.danger;
        icon = PhosphorIconsRegular.warning;
        type = NotificationType.persistent;
      case TaskStatus.completed:
        message = t.tasks.status.completed;
        color = AppColors.success;
        icon = PhosphorIconsRegular.check;
      case TaskStatus.failed:
        message = t.tasks.status.failed;
        color = AppColors.danger;
        icon = PhosphorIconsRegular.x;
        type = NotificationType.persistent;
      case TaskStatus.cancelled:
        message = t.tasks.status.cancelled;
        color = AppColors.fgMuted;
        icon = PhosphorIconsRegular.prohibit;
      default:
        return;
    }

    ns.add(
      AppNotification(
        id: 'task_done_${task.id}',
        title: title,
        message: message,
        type: type,
        autoDismissDuration: const Duration(seconds: 4),
        icon: icon,
        accentColor: color,
      ),
    );
  }

  void _enqueueConflict(FileTask task, ConflictInfo conflict) {
    final queue = _conflictQueues.putIfAbsent(task.id, () => []);
    if (queue.any((c) => c.sourcePath == conflict.sourcePath)) return;
    queue.add(conflict);
    if (!task.conflicts.any((c) => c.sourcePath == conflict.sourcePath)) {
      task.conflicts = [...task.conflicts, conflict];
    }
    task.status = TaskStatus.waitingConflicts;
    _updateTask(task);
    _renderConflictNotification(task);
  }

  void _renderConflictNotification(FileTask task) {
    final ns = notificationStore;
    if (ns == null) return;

    final queue = _conflictQueues[task.id] ?? const <ConflictInfo>[];
    if (queue.isEmpty) {
      _dismissTaskConflictNotification(task.id);
      return;
    }

    final head = queue.first;
    final remaining = queue.length - 1;
    final notifId = 'task_conflicts_${task.id}';

    final title = remaining > 0
        ? '${t.operations.conflictsDetected} (${queue.length})'
        : t.operations.conflictsDetected;
    final message = remaining > 0
        ? '${p.basename(head.sourcePath)}\n+$remaining more'
        : p.basename(head.sourcePath);

    ns.add(
      AppNotification(
        id: notifId,
        title: title,
        message: message,
        type: NotificationType.persistent,
        icon: PhosphorIconsRegular.warning,
        accentColor: AppColors.warning,
        dismissible: false,
        applyToAllLabel: remaining > 0
            ? t.operations.applyToAll(count: remaining)
            : null,
        actions: [
          NotificationAction(
            label: t.operations.replace,
            onTap: () {},
            onTapWithApplyToAll: (applyToAll) => resolveCurrentConflict(
              task.id,
              ConflictResolution.overwrite,
              applyToAll: applyToAll,
            ),
            color: AppColors.accent,
            dismissOnTap: false,
          ),
          NotificationAction(
            label: t.operations.keepBoth,
            onTap: () {},
            onTapWithApplyToAll: (applyToAll) => resolveCurrentConflict(
              task.id,
              ConflictResolution.rename,
              applyToAll: applyToAll,
            ),
            color: AppColors.success,
            dismissOnTap: false,
          ),
          NotificationAction(
            label: t.operations.skip,
            onTap: () {},
            onTapWithApplyToAll: (applyToAll) => resolveCurrentConflict(
              task.id,
              ConflictResolution.skip,
              applyToAll: applyToAll,
            ),
            color: AppColors.fgMuted,
            dismissOnTap: false,
          ),
        ],
      ),
    );
    _conflictNotifIds[task.id] = notifId;
  }

  void _dismissTaskConflictNotification(String taskId) {
    _conflictQueues.remove(taskId);
    final notifId = _conflictNotifIds.remove(taskId);
    if (notifId != null) {
      notificationStore?.dismiss(notifId, force: true);
      notificationStore?.removeFromHistory(notifId, force: true);
    }
  }

  IconData _iconForType(TaskType type) {
    switch (type) {
      case TaskType.copy:
        return PhosphorIconsRegular.copy;
      case TaskType.move:
        return PhosphorIconsRegular.arrowRight;
      case TaskType.delete:
        return PhosphorIconsRegular.trash;
      case TaskType.trash:
        return PhosphorIconsRegular.trashSimple;
      case TaskType.extract:
        return PhosphorIconsRegular.archive;
      case TaskType.compress:
        return PhosphorIconsRegular.fileZip;
      case TaskType.archiveEdit:
        return PhosphorIconsRegular.archive;
    }
  }

  Future<_WorkerHandle> _spawnWorker(
    void Function(List<dynamic>) entryPoint,
  ) async {
    final mainToWorker = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final isolate = await Isolate.spawn<List<dynamic>>(
      entryPoint,
      [mainToWorker.sendPort],
      errorsAreFatal: true,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort,
    );

    final completer = Completer<SendPort>();

    late StreamSubscription sub;
    sub = mainToWorker.listen((msg) {
      if (msg is SendPort && !completer.isCompleted) {
        completer.complete(msg);
      }
    });

    final workerPort = await completer.future;
    return _WorkerHandle(
      isolate,
      workerPort,
      mainToWorker,
      errorPort,
      exitPort,
      sub,
    );
  }

  void _scheduleCleanup(FileTask task) {
    _cleanupTimers[task.id]?.cancel();
    _cleanupTimers[task.id] = Timer(const Duration(seconds: 30), () {
      tasks.value = tasks.value.where((t) => t.id != task.id).toList();
      _cleanupTimers.remove(task.id);
    });
  }

  void dispose() {
    for (final timer in _cleanupTimers.values) {
      timer.cancel();
    }
    _cleanupTimers.clear();
    _currentWorker?.dispose();
  }
}
