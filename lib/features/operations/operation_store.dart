import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/app_notification.dart';
import '../../core/models/file_operation.dart';
import '../../core/fs/file_system_service.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';
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

  /// Optional gate shown before a copy/move is enqueued. Returns whether the
  /// transfer should proceed. Set by the UI layer so it can show a dialog.
  Future<bool> Function(TaskType type, List<String> sources)? confirmTransfer;

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
    assert(
      !destination.startsWith('smb://'),
      'Unresolved smb:// URI reached operation store as destination — '
      'callers must translate to a physical mount path before enqueueing.',
    );
    if (destination.startsWith('smb://')) return;
    final List<String> resolved;
    try {
      resolved = await FileSystemService.materializeArchiveSources(sources);
    } catch (_) {
      return;
    }
    final sep = PlatformPaths.separator;
    final rejected = <String>[];
    final filtered = <String>[];
    for (final s in resolved) {
      final name = PlatformPaths.fileName(s);
      final dst = '$destination$sep$name';
      if (_samePath(s, dst)) continue;
      if (_wouldNestTransfer(s, destination)) {
        rejected.add(s);
        continue;
      }
      filtered.add(s);
    }
    if (rejected.isNotEmpty) {
      _showRejectedTransferNotification(type, rejected);
    }
    if (filtered.isEmpty) return;

    final confirm = confirmTransfer;
    if (confirm != null && !await confirm(type, filtered)) return;

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
    final safe = _rejectSmbUris(sources);
    if (safe.isEmpty) return;

    final task = FileTask(
      id: '${_idCounter++}',
      type: TaskType.delete,
      sources: safe,
      startTime: DateTime.now(),
    );
    _enqueue(task);
  }

  void enqueueTrash(List<String> sources) {
    if (sources.isEmpty) return;
    final safe = _rejectSmbUris(sources);
    if (safe.isEmpty) return;

    final task = FileTask(
      id: '${_idCounter++}',
      type: TaskType.trash,
      sources: safe,
      startTime: DateTime.now(),
    );
    _enqueue(task);
  }

  List<String> _rejectSmbUris(List<String> sources) {
    final out = <String>[];
    for (final s in sources) {
      if (s.startsWith('smb://')) {
        assert(false, 'Unresolved smb:// URI reached operation store: $s');
        continue;
      }
      out.add(s);
    }
    return out;
  }

  void enqueueTrashRestore(List<TrashEntry> entries) {
    _enqueueTrashEntryTask(TaskType.trashRestore, entries);
  }

  void enqueueTrashDelete(List<TrashEntry> entries) {
    _enqueueTrashEntryTask(TaskType.trashDelete, entries);
  }

  void _enqueueTrashEntryTask(TaskType type, List<TrashEntry> entries) {
    if (entries.isEmpty) return;

    final task = FileTask(
      id: '${_idCounter++}',
      type: type,
      sources: [for (final entry in entries) entry.displayName],
      destination: kTrashPath,
      options: {'entries': _encodeTrashEntries(entries)},
      startTime: DateTime.now(),
    );
    _enqueue(task);
  }

  String _encodeTrashEntries(List<TrashEntry> entries) {
    return jsonEncode([
      for (final e in entries)
        {
          'virtualPath': e.virtualPath,
          'displayName': e.displayName,
          'realDataPath': e.realDataPath,
          'originalPath': e.originalPath,
          'deletedAt': e.deletedAt.millisecondsSinceEpoch,
          'size': e.size,
          'isDirectory': e.isDirectory,
          'infoPath': e.infoPath,
          'nativeId': e.nativeId,
        },
    ]);
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
      if (_currentTaskId == id && _isArchiveTask(task.type)) {
        _hardCancelCurrent(task);
      }
    } else if (task.status == TaskStatus.queued) {
      _queue.removeWhere((t) => t.id == id);
      task.status = TaskStatus.cancelled;
      task.endTime = DateTime.now();
      _updateTask(task);
      _scheduleCleanup(task);
    }
    _dismissTaskConflictNotification(id);
  }

  bool _isArchiveTask(TaskType type) =>
      type == TaskType.compress ||
      type == TaskType.extract ||
      type == TaskType.archiveEdit;

  void _hardCancelCurrent(FileTask task) {
    final worker = _currentWorker;
    if (worker == null) return;
    worker.dispose();
    _currentWorker = null;
    if (task.type == TaskType.compress) {
      final dest = task.destination;
      if (dest != null && dest.isNotEmpty) {
        try {
          final f = File(dest);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
    }
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
      case TaskType.trashRestore:
      case TaskType.trashDelete:
        entryPoint = FileSystemService.trashEntryWorker;
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

      if (task.status == TaskStatus.cancelling) {
        handle.sendPort.send(CancelCommand());
      }

      final completer = Completer<void>();

      final speedClock = Stopwatch()..start();
      var lastSampleMs = 0;
      var lastSampleBytes = 0;
      var emaBytesPerSec = 0.0;

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

          final nowMs = speedClock.elapsedMilliseconds;
          final dtMs = nowMs - lastSampleMs;
          if (dtMs >= 300) {
            final dBytes = task.processedBytes - lastSampleBytes;
            if (dBytes > 0) {
              final inst = dBytes * 1000 / dtMs;
              emaBytesPerSec = emaBytesPerSec == 0
                  ? inst
                  : emaBytesPerSec * 0.6 + inst * 0.4;
              task.bytesPerSecond = emaBytesPerSec;
            }
            lastSampleMs = nowMs;
            lastSampleBytes = task.processedBytes;
          }
          final tb = task.totalBytes;
          if (tb != null && tb > 0) {
            task.progress = (task.processedBytes / tb).clamp(0.0, 1.0);
          } else if (task.totalFiles > 0) {
            task.progress = task.processedFiles / task.totalFiles;
          }
          _updateTask(task);
        } else if (msg is ErrorMessage) {
          task.errors = [
            ...task.errors,
            TaskError(path: msg.path, message: msg.message),
          ];
          log.warn(
            'operation',
            '${task.type.name} task ${task.id} error'
                '${msg.path.isNotEmpty ? ' at ${msg.path}' : ''}: ${msg.message}',
          );
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
          task.bytesPerSecond = 0;
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
        if (task.status == TaskStatus.cancelling) {
          task.status = TaskStatus.cancelled;
        } else {
          log.error('operation', 'task ${task.id} worker exited unexpectedly');
          task.status = TaskStatus.failed;
          task.errors = [
            ...task.errors,
            TaskError(path: '', message: t.errors.workerExitedUnexpectedly),
          ];
        }
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
    List<NotificationAction> actions = const [];

    switch (task.status) {
      case TaskStatus.completed when task.errors.isNotEmpty:
        message = t.tasks.status.completedWithErrors(count: task.errors.length);
        color = AppColors.danger;
        icon = WaydirIconsRegular.warning;
        type = NotificationType.persistent;
      case TaskStatus.completed:
        message = t.tasks.status.completed;
        color = AppColors.success;
        icon = WaydirIconsRegular.check;
      case TaskStatus.failed:
        message = t.tasks.status.failed;
        color = AppColors.danger;
        icon = WaydirIconsRegular.x;
        type = NotificationType.persistent;
      case TaskStatus.cancelled:
        message = t.tasks.status.cancelled;
        color = AppColors.fgMuted;
        icon = WaydirIconsRegular.prohibit;
      default:
        return;
    }

    if (task.type == TaskType.trash && task.errors.isNotEmpty) {
      final paths = task.errors
          .map((e) => e.path)
          .where((path) => path.isNotEmpty)
          .toSet()
          .toList();
      if (paths.isNotEmpty) {
        actions = [
          NotificationAction(
            label: t.menu.deletePermanently,
            onTap: () => enqueueDelete(paths),
            color: AppColors.danger,
          ),
        ];
        type = NotificationType.persistent;
      }
    }

    ns.add(
      AppNotification(
        id: 'task_done_${task.id}',
        title: title,
        message: message,
        type: type,
        autoDismissDuration: const Duration(seconds: 4),
        actions: actions,
        icon: icon,
        accentColor: color,
      ),
    );
  }

  void _showRejectedTransferNotification(TaskType type, List<String> sources) {
    final ns = notificationStore;
    if (ns == null) return;
    ns.add(
      AppNotification(
        id: 'task_rejected_${DateTime.now().microsecondsSinceEpoch}',
        title: type == TaskType.copy
            ? t.tasks.copyingMultiple(count: sources.length)
            : t.tasks.movingMultiple(count: sources.length),
        message: t.errors.transferIntoSelf,
        type: NotificationType.persistent,
        icon: WaydirIconsRegular.warning,
        accentColor: AppColors.danger,
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
        icon: WaydirIconsRegular.warning,
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
        return WaydirIconsRegular.copy;
      case TaskType.move:
        return WaydirIconsRegular.arrowRight;
      case TaskType.delete:
        return WaydirIconsRegular.trash;
      case TaskType.trash:
        return WaydirIconsRegular.trashSimple;
      case TaskType.trashRestore:
        return WaydirIconsRegular.arrowCounterClockwise;
      case TaskType.trashDelete:
        return WaydirIconsRegular.trash;
      case TaskType.extract:
        return WaydirIconsRegular.archive;
      case TaskType.compress:
        return WaydirIconsRegular.fileZip;
      case TaskType.archiveEdit:
        return WaydirIconsRegular.archive;
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

  static bool _wouldNestTransfer(String source, String destination) {
    final type = FileSystemEntity.typeSync(source, followLinks: false);
    if (type != FileSystemEntityType.directory) return false;
    final srcCanonical = _canonicalPath(source);
    final destCanonical = _canonicalPath(destination);
    return testDirIsParent(srcCanonical, destCanonical);
  }

  static bool testDirIsParent(String srcCanonical, String destCanonical) {
    final sep = PlatformPaths.separator;
    final src = _comparePath(srcCanonical);
    final dest = _comparePath(destCanonical);
    if (src == dest) return true;
    final prefix = src.endsWith(sep) ? src : '$src$sep';
    return dest.startsWith(prefix);
  }

  static bool _samePath(String a, String b) =>
      _comparePath(a) == _comparePath(b);

  static String _canonicalPath(String path) {
    try {
      return File(path).resolveSymbolicLinksSync();
    } catch (_) {
      return p.normalize(p.absolute(path));
    }
  }

  static String _comparePath(String path) {
    final normalized = p.normalize(path);
    return PlatformPaths.isWindows ? normalized.toLowerCase() : normalized;
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
