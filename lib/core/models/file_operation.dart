import 'package:path/path.dart' as p;
import '../../i18n/strings.g.dart';
import '../../utils/format.dart';

enum TaskType {
  copy,
  move,
  delete,
  trash,
  trashRestore,
  trashDelete,
  extract,
  compress,
  archiveEdit,
}

enum TaskStatus {
  queued,
  preparing,
  waitingConflicts,
  running,
  paused,
  cancelling,
  completed,
  failed,
  cancelled,
}

enum ConflictResolution { overwrite, skip, rename }

class TaskError {
  final String path;
  final String message;

  const TaskError({required this.path, required this.message});
}

class ConflictInfo {
  final String sourcePath;
  final String targetPath;
  final String name;
  final int sourceSize;
  final int targetSize;
  final DateTime sourceModified;
  final DateTime targetModified;

  const ConflictInfo({
    required this.sourcePath,
    required this.targetPath,
    required this.name,
    required this.sourceSize,
    required this.targetSize,
    required this.sourceModified,
    required this.targetModified,
  });
}

class FileTask {
  final String id;
  final TaskType type;
  final List<String> sources;
  final String? destination;
  final Map<String, String> options;

  TaskStatus status;
  double progress;

  int totalFiles;
  int processedFiles;
  int? totalBytes;
  int processedBytes;
  String currentFile;
  double bytesPerSecond;

  List<ConflictInfo> conflicts;
  Map<String, ConflictResolution> resolutions;
  List<TaskError> errors;
  ConflictInfo? pendingConflict;
  ConflictResolution? applyToAllResolution;

  DateTime startTime;
  DateTime? endTime;

  FileTask({
    required this.id,
    required this.type,
    required this.sources,
    this.destination,
    this.options = const {},
    this.status = TaskStatus.queued,
    this.progress = 0.0,
    this.totalFiles = 0,
    this.processedFiles = 0,
    this.totalBytes,
    this.processedBytes = 0,
    this.currentFile = '',
    this.bytesPerSecond = 0,
    this.conflicts = const [],
    this.resolutions = const {},
    this.errors = const [],
    this.pendingConflict,
    this.applyToAllResolution,
    required this.startTime,
    this.endTime,
  });
}

class TaskLabel {
  static String title(FileTask task) {
    final count = task.sources.length;
    return switch (task.type) {
      TaskType.copy when count == 1 => t.tasks.copyingSingle(
        name: p.basename(task.sources.first),
      ),
      TaskType.copy => t.tasks.copyingMultiple(count: count),
      TaskType.move when count == 1 => t.tasks.movingSingle(
        name: p.basename(task.sources.first),
      ),
      TaskType.move => t.tasks.movingMultiple(count: count),
      TaskType.delete when count == 1 => t.tasks.deletingSingle(
        name: p.basename(task.sources.first),
      ),
      TaskType.delete => t.tasks.deletingMultiple(count: count),
      TaskType.trash when count == 1 => t.tasks.trashingSingle(
        name: p.basename(task.sources.first),
      ),
      TaskType.trash => t.tasks.trashingMultiple(count: count),
      TaskType.trashRestore when count == 1 => t.tasks.restoringTrashSingle(
        name: p.basename(task.sources.first),
      ),
      TaskType.trashRestore => t.tasks.restoringTrashMultiple(count: count),
      TaskType.trashDelete when count == 1 => t.tasks.deletingTrashSingle(
        name: p.basename(task.sources.first),
      ),
      TaskType.trashDelete => t.tasks.deletingTrashMultiple(count: count),
      TaskType.extract when count == 1 => t.tasks.extractingSingle(
        name: p.basename(task.sources.first),
      ),
      TaskType.extract => t.tasks.extractingMultiple(count: count),
      TaskType.compress => t.tasks.compressingTo(
        name: p.basename(task.destination ?? ''),
      ),
      TaskType.archiveEdit => t.tasks.updatingArchive,
    };
  }

  static String subtitle(FileTask task) {
    return switch (task.status) {
      TaskStatus.queued => t.tasks.status.waiting,
      TaskStatus.preparing => t.tasks.status.scanning,
      TaskStatus.waitingConflicts => t.tasks.status.conflicts(
        count: task.conflicts.length,
      ),
      TaskStatus.running => t.tasks.status.running(
        current: task.currentFile,
        processed: task.processedFiles,
        total: task.totalFiles,
      ),
      TaskStatus.paused => t.tasks.status.conflicts(count: 1),
      TaskStatus.cancelling => t.tasks.status.cancelling,
      TaskStatus.completed when task.errors.isNotEmpty =>
        t.tasks.status.completedWithErrors(count: task.errors.length),
      TaskStatus.completed => t.tasks.status.completed,
      TaskStatus.failed => t.tasks.status.failed,
      TaskStatus.cancelled => t.tasks.status.cancelled,
    };
  }

  static String progressText(FileTask task) {
    final tb = task.totalBytes;
    if (tb != null) {
      return '${formatBytes(task.processedBytes)} / ${formatBytes(tb)}';
    }
    return t.tasks.status
        .running(
          current: '',
          processed: task.processedFiles,
          total: task.totalFiles,
        )
        .replaceFirst(' ()', '')
        .trim();
  }
}

sealed class WorkerMessage {}

class PreScanResultMessage extends WorkerMessage {
  final int totalFiles;
  final int? totalBytes;
  final List<String> allPaths;
  final List<ConflictInfo> conflicts;

  PreScanResultMessage({
    required this.totalFiles,
    this.totalBytes,
    required this.allPaths,
    required this.conflicts,
  });
}

class ConflictPromptMessage extends WorkerMessage {
  final ConflictInfo conflict;

  ConflictPromptMessage({required this.conflict});
}

class ProgressMessage extends WorkerMessage {
  final int processedFiles;
  final int processedBytes;
  final String currentFile;

  ProgressMessage({
    required this.processedFiles,
    required this.processedBytes,
    required this.currentFile,
  });
}

class ErrorMessage extends WorkerMessage {
  final String path;
  final String message;

  ErrorMessage({required this.path, required this.message});
}

class TaskDoneMessage extends WorkerMessage {
  final bool cancelled;
  final List<TaskError> errors;

  TaskDoneMessage({required this.cancelled, required this.errors});
}

sealed class CommandMessage {}

class StartCommand extends CommandMessage {
  final TaskType type;
  final List<String> sources;
  final String? destination;
  final Map<String, String> options;

  StartCommand({
    required this.type,
    required this.sources,
    this.destination,
    this.options = const {},
  });
}

class ExecuteCommand extends CommandMessage {
  final Map<String, ConflictResolution> resolutions;

  ExecuteCommand({required this.resolutions});
}

class ConflictDecisionCommand extends CommandMessage {
  final String sourcePath;
  final ConflictResolution resolution;
  final bool applyToAll;

  ConflictDecisionCommand({
    required this.sourcePath,
    required this.resolution,
    this.applyToAll = false,
  });
}

class CancelCommand extends CommandMessage {}
