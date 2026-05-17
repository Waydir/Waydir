import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import '../archive/archive_path.dart';
import '../archive/archive_reader.dart';
import '../archive/archive_writer.dart';
import '../models/file_entry.dart';
import '../models/file_operation.dart';
import '../open/open_service.dart';
import '../platform/platform_paths.dart';
import '../settings/settings_store.dart';
import '../terminal/terminal.dart';
import '../../i18n/strings.g.dart';
import 'fs_worker_pool.dart';
import 'safe_file_replace.dart';
import 'waydir_core_loader.dart';
import 'trash_service.dart';

sealed class RenameResult {
  const RenameResult();
}

class RenameSuccess extends RenameResult {
  final String newPath;
  const RenameSuccess(this.newPath);
}

class RenameInvalidName extends RenameResult {
  const RenameInvalidName();
}

class RenameAlreadyExists extends RenameResult {
  const RenameAlreadyExists();
}

class RenameNoChange extends RenameResult {
  const RenameNoChange();
}

class RenameError extends RenameResult {
  final String message;
  const RenameError(this.message);
}

class FileSystemService {
  static RenameResult rename(String oldPath, String newName) {
    if (!PlatformPaths.isValidFileName(newName)) {
      return const RenameInvalidName();
    }

    final newPath = p.join(p.dirname(oldPath), newName);

    if (oldPath == newPath) return const RenameNoChange();

    if (FileSystemEntity.typeSync(newPath) != FileSystemEntityType.notFound) {
      return const RenameAlreadyExists();
    }

    try {
      final type = FileSystemEntity.typeSync(oldPath, followLinks: false);
      if (type == FileSystemEntityType.link) {
        Link(oldPath).renameSync(newPath);
      } else if (type == FileSystemEntityType.directory) {
        Directory(oldPath).renameSync(newPath);
      } else {
        File(oldPath).renameSync(newPath);
      }
      return RenameSuccess(newPath);
    } on FileSystemException catch (e) {
      return RenameError(_friendlyError(e));
    }
  }

  static Future<List<FileEntry>> listDirectory(String path) {
    final loc = ArchivePath.resolve(path);
    if (loc != null) {
      return FsWorkerPool.instance.listArchive(loc.archivePath, loc.innerPath);
    }
    return FsWorkerPool.instance.listDirectory(path);
  }

  static Future<bool> directoryExists(String path) =>
      FsWorkerPool.instance.directoryExists(path);

  static Future<bool> isNavigable(String path) async {
    if (ArchivePath.resolve(path) != null) return true;
    return FsWorkerPool.instance.directoryExists(path);
  }

  static bool isInsideArchive(String path) {
    final loc = ArchivePath.resolve(path);
    return loc != null && !loc.isRoot;
  }

  static Future<List<String>> materializeArchiveSources(
    List<String> sources,
  ) async {
    if (!sources.any(isInsideArchive)) return sources;
    final staging = Directory(
      p.join(
        Directory.systemTemp.path,
        'waydir-archive-stage',
        DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    )..createSync(recursive: true);
    final out = <String>[];
    for (final s in sources) {
      final loc = ArchivePath.resolve(s);
      if (loc == null || loc.isRoot) {
        out.add(s);
        continue;
      }
      out.add(
        await FsWorkerPool.instance.extractArchiveTree(
          loc.archivePath,
          loc.innerPath,
          staging.path,
        ),
      );
    }
    return out;
  }

  static String archiveBaseName(String archivePath) {
    var name = p.basename(archivePath);
    final lower = name.toLowerCase();
    for (final ext in const [
      '.tar.gz',
      '.tar.bz2',
      '.tar.xz',
      '.tar.zst',
      '.tar.lz',
      '.tar.lzma',
      '.tar.z',
    ]) {
      if (lower.endsWith(ext)) {
        return name.substring(0, name.length - ext.length);
      }
    }
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    return name;
  }

  static String uniquePath(String desired) {
    bool taken(String p) =>
        FileSystemEntity.typeSync(p) != FileSystemEntityType.notFound;
    if (!taken(desired)) return desired;
    for (var i = 1; i < 10000; i++) {
      final candidate = '$desired ($i)';
      if (!taken(candidate)) return candidate;
    }
    return '$desired ${DateTime.now().microsecondsSinceEpoch}';
  }

  static Future<void> openArchiveEntry(ArchiveLocation loc) async {
    final tempRoot = Directory(
      p.join(Directory.systemTemp.path, 'waydir-archive'),
    );
    final dest = p.join(
      tempRoot.path,
      p.basename(loc.archivePath),
      loc.innerPath,
    );
    await FsWorkerPool.instance.extractArchiveEntry(
      loc.archivePath,
      loc.innerPath,
      dest,
    );
    await OpenService.openDefault(dest);
  }

  static Future<bool> isDirectory(String path) =>
      FsWorkerPool.instance.isDirectory(path);

  static Future<void> createDirectory(String path) =>
      FsWorkerPool.instance.createDirectory(path);

  static Future<void> openInTerminal(String directory) =>
      TerminalService.openInDirectory(
        directory,
        preferredId: SettingsStore.instance.terminal.value,
        customCommand: SettingsStore.instance.terminalCustomCommand.value,
      );

  static Future<void> openWithDefaultApp(String path) =>
      OpenService.openDefault(path);

  static void copyWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    final allPaths = <String>[];
    final sourceRoots = <String>{};
    final visitedDirs = <String>{};
    int totalBytes = 0;
    int totalFiles = 0;
    final conflicts = <ConflictInfo>[];
    Map<String, ConflictResolution> resolutions = {};
    final runtimeResolutions = <String, ConflictResolution>{};
    final pendingConflicts = <String, ConflictInfo>{};
    final promptedSet = <String>{};
    ConflictResolution? runtimeApplyAll;
    Completer<void>? decisionWaker;
    final errors = <TaskError>[];
    String? destination;
    int processedBytes = 0;
    int processedFiles = 0;
    final reportClock = Stopwatch()..start();
    var lastReportMs = 0;

    void emitPrompt(ConflictInfo info) {
      if (promptedSet.add(info.sourcePath)) {
        mainSendPort.send(ConflictPromptMessage(conflict: info));
      }
    }

    void wakeDecisions() {
      final w = decisionWaker;
      decisionWaker = null;
      w?.complete();
    }

    void maybeReport(String currentFile) {
      if (reportClock.elapsedMilliseconds - lastReportMs > 50 ||
          processedFiles % 100 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: processedBytes,
            currentFile: currentFile,
          ),
        );
        lastReportMs = reportClock.elapsedMilliseconds;
      }
    }

    void scanEntity(String src, String dest) {
      final name = src.split(Platform.pathSeparator).last;
      final targetPath = '$dest${Platform.pathSeparator}$name';

      final type = FileSystemEntity.typeSync(src);
      if (type == FileSystemEntityType.notFound) {
        errors.add(TaskError(path: src, message: t.errors.notFound));
        mainSendPort.send(ErrorMessage(path: src, message: t.errors.notFound));
        return;
      }
      if (type == FileSystemEntityType.directory) {
        allPaths.add(src);
        totalFiles++;
        _scanDirForCopy(
          Directory(src),
          targetPath,
          visitedDirs,
          (path, bytes, conflict) {
            allPaths.add(path);
            totalFiles++;
            totalBytes += bytes;
            if (conflict != null) conflicts.add(conflict);
          },
          (errorPath, errorMsg) {
            errors.add(TaskError(path: errorPath, message: errorMsg));
            mainSendPort.send(ErrorMessage(path: errorPath, message: errorMsg));
          },
        );
      } else {
        try {
          final sourceStat = FileStat.statSync(src);
          final size = sourceStat.size;
          allPaths.add(src);
          totalFiles++;
          totalBytes += size;
          final targetStat = FileStat.statSync(targetPath);
          if (targetStat.type != FileSystemEntityType.notFound) {
            conflicts.add(
              ConflictInfo(
                sourcePath: src,
                targetPath: targetPath,
                name: name,
                sourceSize: size,
                targetSize: targetStat.size,
                sourceModified: sourceStat.modified,
                targetModified: targetStat.modified,
              ),
            );
          }
        } catch (e) {
          errors.add(TaskError(path: src, message: _friendlyError(e)));
          mainSendPort.send(
            ErrorMessage(path: src, message: _friendlyError(e)),
          );
        }
      }
    }

    String mapDestination(String srcPath, String dest) {
      final sep = Platform.pathSeparator;
      final srcRoot = _findSourceRoot(srcPath, sourceRoots);
      if (srcRoot != null) {
        final srcName = srcRoot.split(sep).last;
        final relative = srcPath.substring(srcRoot.length);
        return '$dest$sep$srcName$relative';
      }
      final name = srcPath.split(sep).last;
      return '$dest$sep$name';
    }

    Future<bool> processCopyItem(String srcPath) async {
      var resolution =
          runtimeApplyAll ??
          runtimeResolutions[srcPath] ??
          resolutions[srcPath];
      if (resolution == ConflictResolution.skip) {
        return true;
      }

      var dstPath = mapDestination(srcPath, destination!);
      if (resolution == ConflictResolution.rename) {
        dstPath = _uniqueName(dstPath);
      }

      try {
        final type = FileSystemEntity.typeSync(srcPath);
        if (type == FileSystemEntityType.notFound) {
          errors.add(TaskError(path: srcPath, message: t.errors.notFound));
          return true;
        } else if (type == FileSystemEntityType.file) {
          final targetExists =
              FileSystemEntity.typeSync(dstPath) !=
              FileSystemEntityType.notFound;
          if (resolution != ConflictResolution.overwrite && targetExists) {
            final size = File(srcPath).lengthSync();
            final targetStat = FileStat.statSync(dstPath);
            final sourceStat = FileStat.statSync(srcPath);
            final info = ConflictInfo(
              sourcePath: srcPath,
              targetPath: dstPath,
              name: srcPath.split(Platform.pathSeparator).last,
              sourceSize: size,
              targetSize: targetStat.size,
              sourceModified: sourceStat.modified,
              targetModified: targetStat.modified,
            );
            pendingConflicts[srcPath] = info;
            emitPrompt(info);
            return false;
          }

          final dstDir = dstPath.substring(
            0,
            dstPath.lastIndexOf(Platform.pathSeparator),
          );
          if (!Directory(dstDir).existsSync()) {
            Directory(dstDir).createSync(recursive: true);
          }

          final size = File(srcPath).lengthSync();
          _copyFileSync(File(srcPath), dstPath);
          processedBytes += size;
        } else if (type == FileSystemEntityType.directory) {
          if (!Directory(dstPath).existsSync()) {
            Directory(dstPath).createSync(recursive: true);
          }
        }
      } catch (e) {
        errors.add(TaskError(path: srcPath, message: _friendlyError(e)));
      }
      return true;
    }

    Future<void> executeCopy() async {
      for (final c in conflicts) {
        pendingConflicts[c.sourcePath] = c;
        if (!resolutions.containsKey(c.sourcePath)) {
          emitPrompt(c);
        }
      }
      while (!cancelled &&
          pendingConflicts.keys.any(
            (s) =>
                runtimeApplyAll == null &&
                runtimeResolutions[s] == null &&
                resolutions[s] == null,
          )) {
        decisionWaker = Completer<void>();
        await decisionWaker!.future;
      }

      for (final srcPath in allPaths) {
        if (cancelled) break;

        if (pendingConflicts.containsKey(srcPath) &&
            runtimeApplyAll == null &&
            runtimeResolutions[srcPath] == null &&
            resolutions[srcPath] == null) {
          continue;
        }

        final handled = await processCopyItem(srcPath);
        if (handled) {
          pendingConflicts.remove(srcPath);
          processedFiles++;
          maybeReport(srcPath.split(Platform.pathSeparator).last);
          if (processedFiles % 64 == 0) {
            await Future.delayed(Duration.zero);
          }
        }
      }

      while (pendingConflicts.isNotEmpty && !cancelled) {
        final resolvable = pendingConflicts.keys
            .where(
              (s) =>
                  runtimeApplyAll != null ||
                  runtimeResolutions[s] != null ||
                  resolutions[s] != null,
            )
            .toList();
        if (resolvable.isEmpty) {
          decisionWaker = Completer<void>();
          await decisionWaker!.future;
          continue;
        }
        for (final srcPath in resolvable) {
          if (cancelled) break;
          final handled = await processCopyItem(srcPath);
          if (handled) {
            pendingConflicts.remove(srcPath);
            processedFiles++;
            maybeReport(srcPath.split(Platform.pathSeparator).last);
            if (processedFiles % 4 == 0) {
              await Future.delayed(Duration.zero);
            }
          }
        }
      }

      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          destination = msg.destination;
          for (final src in msg.sources) {
            sourceRoots.add(src);
            scanEntity(src, destination!);
          }
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: totalBytes,
              allPaths: allPaths,
              conflicts: conflicts,
            ),
          );
        } else if (msg is ExecuteCommand) {
          resolutions = msg.resolutions;
          executeCopy().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is ConflictDecisionCommand) {
          if (msg.applyToAll) runtimeApplyAll = msg.resolution;
          runtimeResolutions[msg.sourcePath] = msg.resolution;
          wakeDecisions();
        } else if (msg is CancelCommand) {
          cancelled = true;
          wakeDecisions();
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void moveWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    final allPaths = <String>[];
    final sourceRoots = <String>{};
    final sourceRootOrder = <String>[];
    final sourceRootCounts = <String, int>{};
    final visitedDirs = <String>{};
    int totalFiles = 0;
    final conflicts = <ConflictInfo>[];
    Map<String, ConflictResolution> resolutions = {};
    final runtimeResolutions = <String, ConflictResolution>{};
    final pendingConflicts = <String, ConflictInfo>{};
    final promptedSet = <String>{};
    ConflictResolution? runtimeApplyAll;
    Completer<void>? decisionWaker;
    final errors = <TaskError>[];
    String? destination;
    int processedFiles = 0;
    final reportClock = Stopwatch()..start();
    var lastReportMs = 0;

    void emitPrompt(ConflictInfo info) {
      if (promptedSet.add(info.sourcePath)) {
        mainSendPort.send(ConflictPromptMessage(conflict: info));
      }
    }

    void wakeDecisions() {
      final w = decisionWaker;
      decisionWaker = null;
      w?.complete();
    }

    void maybeReport(String currentFile) {
      if (reportClock.elapsedMilliseconds - lastReportMs > 50 ||
          processedFiles % 100 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: 0,
            currentFile: currentFile,
          ),
        );
        lastReportMs = reportClock.elapsedMilliseconds;
      }
    }

    void scanEntity(String src, String dest) {
      final name = src.split(Platform.pathSeparator).last;
      final targetPath = '$dest${Platform.pathSeparator}$name';

      final type = FileSystemEntity.typeSync(src);
      if (type == FileSystemEntityType.notFound) {
        errors.add(TaskError(path: src, message: t.errors.notFound));
        mainSendPort.send(ErrorMessage(path: src, message: t.errors.notFound));
        return;
      }
      if (type == FileSystemEntityType.directory) {
        allPaths.add(src);
        totalFiles++;
        _scanDirForMove(
          Directory(src),
          targetPath,
          visitedDirs,
          (path, _) {
            allPaths.add(path);
            totalFiles++;
          },
          (errorPath, errorMsg) {
            errors.add(TaskError(path: errorPath, message: errorMsg));
            mainSendPort.send(ErrorMessage(path: errorPath, message: errorMsg));
          },
        );
        final dirTargetStat = FileStat.statSync(targetPath);
        if (dirTargetStat.type != FileSystemEntityType.notFound) {
          try {
            final targetStat = dirTargetStat;
            final sourceStat = FileStat.statSync(src);
            conflicts.add(
              ConflictInfo(
                sourcePath: src,
                targetPath: targetPath,
                name: name,
                sourceSize: sourceStat.size,
                targetSize: targetStat.size,
                sourceModified: sourceStat.modified,
                targetModified: targetStat.modified,
              ),
            );
          } catch (e) {
            errors.add(TaskError(path: src, message: _friendlyError(e)));
            mainSendPort.send(
              ErrorMessage(path: src, message: _friendlyError(e)),
            );
          }
        }
      } else {
        try {
          allPaths.add(src);
          totalFiles++;
          final targetStat = FileStat.statSync(targetPath);
          if (targetStat.type != FileSystemEntityType.notFound) {
            final sourceStat = FileStat.statSync(src);
            conflicts.add(
              ConflictInfo(
                sourcePath: src,
                targetPath: targetPath,
                name: name,
                sourceSize: sourceStat.size,
                targetSize: targetStat.size,
                sourceModified: sourceStat.modified,
                targetModified: targetStat.modified,
              ),
            );
          }
        } catch (e) {
          errors.add(TaskError(path: src, message: _friendlyError(e)));
          mainSendPort.send(
            ErrorMessage(path: src, message: _friendlyError(e)),
          );
        }
      }
    }

    String mapDestination(String srcPath, String dest) {
      final sep = Platform.pathSeparator;
      final srcRoot = _findSourceRoot(srcPath, sourceRoots);
      if (srcRoot != null) {
        final srcName = srcRoot.split(sep).last;
        final relative = srcPath.substring(srcRoot.length);
        return '$dest$sep$srcName$relative';
      }
      final name = srcPath.split(sep).last;
      return '$dest$sep$name';
    }

    ConflictInfo buildConflictInfo(String src, String dst) {
      final targetStat = FileStat.statSync(dst);
      final sourceStat = FileStat.statSync(src);
      return ConflictInfo(
        sourcePath: src,
        targetPath: dst,
        name: src.split(Platform.pathSeparator).last,
        sourceSize: sourceStat.size,
        targetSize: targetStat.size,
        sourceModified: sourceStat.modified,
        targetModified: targetStat.modified,
      );
    }

    Future<bool> processMoveRoot(String srcPath) async {
      var resolution =
          runtimeApplyAll ??
          runtimeResolutions[srcPath] ??
          resolutions[srcPath];
      if (resolution == ConflictResolution.skip) {
        return true;
      }

      var dstPath = mapDestination(srcPath, destination!);
      if (resolution == ConflictResolution.rename) {
        dstPath = _uniqueName(dstPath);
      }

      try {
        final targetType = FileSystemEntity.typeSync(
          dstPath,
          followLinks: false,
        );
        if (resolution != ConflictResolution.overwrite &&
            targetType != FileSystemEntityType.notFound) {
          final info = buildConflictInfo(srcPath, dstPath);
          pendingConflicts[srcPath] = info;
          emitPrompt(info);
          return false;
        }
        if (resolution == ConflictResolution.overwrite &&
            targetType != FileSystemEntityType.notFound) {
          final tempDstPath = SafeFileReplace.temporarySiblingPath(dstPath);
          await _moveEntity(srcPath, tempDstPath, () => cancelled, null);
          if (cancelled) return true;
          if (targetType == FileSystemEntityType.file ||
              targetType == FileSystemEntityType.link) {
            SafeFileReplace.replaceWithFile(tempDstPath, dstPath);
          } else {
            _deleteExistingEntity(dstPath);
            await _moveEntity(tempDstPath, dstPath, () => false, null);
          }
          return true;
        }
        final dstDir = dstPath.substring(
          0,
          dstPath.lastIndexOf(Platform.pathSeparator),
        );
        if (!Directory(dstDir).existsSync()) {
          Directory(dstDir).createSync(recursive: true);
        }
        await _moveEntity(srcPath, dstPath, () => cancelled, null);
      } catch (e) {
        errors.add(TaskError(path: srcPath, message: _friendlyError(e)));
      }
      return true;
    }

    Future<void> executeMove() async {
      for (final c in conflicts) {
        pendingConflicts[c.sourcePath] = c;
        if (!resolutions.containsKey(c.sourcePath)) {
          emitPrompt(c);
        }
      }
      while (!cancelled &&
          pendingConflicts.keys.any(
            (s) =>
                runtimeApplyAll == null &&
                runtimeResolutions[s] == null &&
                resolutions[s] == null,
          )) {
        decisionWaker = Completer<void>();
        await decisionWaker!.future;
      }

      for (final srcPath in sourceRootOrder) {
        if (cancelled) break;

        if (pendingConflicts.containsKey(srcPath) &&
            runtimeApplyAll == null &&
            runtimeResolutions[srcPath] == null &&
            resolutions[srcPath] == null) {
          continue;
        }

        final handled = await processMoveRoot(srcPath);
        if (handled) {
          pendingConflicts.remove(srcPath);
          processedFiles += sourceRootCounts[srcPath] ?? 1;
          if (processedFiles > totalFiles) processedFiles = totalFiles;
          maybeReport(srcPath.split(Platform.pathSeparator).last);
          await Future.delayed(Duration.zero);
        }
      }

      while (pendingConflicts.isNotEmpty && !cancelled) {
        final resolvable = pendingConflicts.keys
            .where(
              (s) =>
                  runtimeApplyAll != null ||
                  runtimeResolutions[s] != null ||
                  resolutions[s] != null,
            )
            .toList();
        if (resolvable.isEmpty) {
          decisionWaker = Completer<void>();
          await decisionWaker!.future;
          continue;
        }
        for (final srcPath in resolvable) {
          if (cancelled) break;
          final handled = await processMoveRoot(srcPath);
          if (handled) {
            pendingConflicts.remove(srcPath);
            processedFiles += sourceRootCounts[srcPath] ?? 1;
            if (processedFiles > totalFiles) processedFiles = totalFiles;
            maybeReport(srcPath.split(Platform.pathSeparator).last);
            await Future.delayed(Duration.zero);
          }
        }
      }

      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          destination = msg.destination;
          for (final src in msg.sources) {
            sourceRoots.add(src);
            sourceRootOrder.add(src);
            final before = totalFiles;
            scanEntity(src, destination!);
            sourceRootCounts[src] = totalFiles - before;
          }
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: null,
              allPaths: allPaths,
              conflicts: conflicts,
            ),
          );
        } else if (msg is ExecuteCommand) {
          resolutions = msg.resolutions;
          executeMove().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is ConflictDecisionCommand) {
          if (msg.applyToAll) runtimeApplyAll = msg.resolution;
          runtimeResolutions[msg.sourcePath] = msg.resolution;
          wakeDecisions();
        } else if (msg is CancelCommand) {
          cancelled = true;
          wakeDecisions();
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void deleteWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    List<String> allPaths = [];
    int totalFiles = 0;
    List<TaskError> errors = [];
    int processedFiles = 0;
    final reportClock = Stopwatch()..start();
    var lastReportMs = 0;

    void maybeReport(String currentFile) {
      if (reportClock.elapsedMilliseconds - lastReportMs > 50 ||
          processedFiles % 100 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: 0,
            currentFile: currentFile,
          ),
        );
        lastReportMs = reportClock.elapsedMilliseconds;
      }
    }

    void scanForDelete(List<String> sources) {
      final visited = <String>{};
      void walk(String dirPath) {
        final resolved = _resolveCanonical(dirPath);
        if (!visited.add(resolved)) return;
        try {
          for (final entity in Directory(
            dirPath,
          ).listSync(followLinks: false)) {
            final entType = FileSystemEntity.typeSync(
              entity.path,
              followLinks: false,
            );
            if (entType == FileSystemEntityType.directory) {
              walk(entity.path);
            }
            allPaths.add(entity.path);
            totalFiles++;
          }
        } catch (e) {
          errors.add(TaskError(path: dirPath, message: _friendlyError(e)));
          mainSendPort.send(
            ErrorMessage(path: dirPath, message: _friendlyError(e)),
          );
        }
      }

      for (final src in sources) {
        final type = FileSystemEntity.typeSync(src, followLinks: false);
        if (type == FileSystemEntityType.notFound) {
          errors.add(TaskError(path: src, message: t.errors.notFound));
          mainSendPort.send(
            ErrorMessage(path: src, message: t.errors.notFound),
          );
        } else if (type == FileSystemEntityType.directory) {
          final native = WaydirCoreLoader.enumerate(src, postorder: false);
          if (native != null) {
            for (final e in FileEntryCodec.decode(native)) {
              allPaths.add(e.path);
              totalFiles++;
            }
          } else {
            walk(src);
          }
          allPaths.add(src);
          totalFiles++;
        } else {
          allPaths.add(src);
          totalFiles++;
        }
      }
    }

    Future<void> executeDelete() async {
      final sorted = List<String>.from(allPaths);
      sorted.sort((a, b) => b.length.compareTo(a.length));

      for (final path in sorted) {
        if (cancelled) break;

        try {
          final type = FileSystemEntity.typeSync(path, followLinks: false);
          if (type == FileSystemEntityType.link) {
            Link(path).deleteSync();
          } else if (type == FileSystemEntityType.directory) {
            Directory(path).deleteSync(recursive: false);
          } else if (type == FileSystemEntityType.file) {
            File(path).deleteSync();
          }
        } catch (e) {
          errors.add(TaskError(path: path, message: _friendlyError(e)));
        }

        processedFiles++;
        maybeReport(path.split(Platform.pathSeparator).last);
        if (processedFiles % 4 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          scanForDelete(msg.sources);
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: null,
              allPaths: allPaths,
              conflicts: [],
            ),
          );
        } else if (msg is ExecuteCommand) {
          executeDelete().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is CancelCommand) {
          cancelled = true;
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void trashWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    List<String> sources = const [];
    final errors = <TaskError>[];
    int processedFiles = 0;
    final reportClock = Stopwatch()..start();
    var lastReportMs = 0;

    void maybeReport(String currentFile) {
      if (reportClock.elapsedMilliseconds - lastReportMs > 50 ||
          processedFiles % 50 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: 0,
            currentFile: currentFile,
          ),
        );
        lastReportMs = reportClock.elapsedMilliseconds;
      }
    }

    Future<void> executeTrash() async {
      final service = TrashService.instance;
      for (final src in sources) {
        if (cancelled) break;
        try {
          await service.trash(src);
        } catch (e) {
          errors.add(TaskError(path: src, message: _friendlyError(e)));
          mainSendPort.send(
            ErrorMessage(path: src, message: _friendlyError(e)),
          );
        }
        processedFiles++;
        maybeReport(src.split(Platform.pathSeparator).last);
      }
      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          sources = msg.sources;
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: sources.length,
              totalBytes: null,
              allPaths: sources,
              conflicts: const [],
            ),
          );
        } else if (msg is ExecuteCommand) {
          executeTrash().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is CancelCommand) {
          cancelled = true;
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void extractWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    List<String> sources = const [];
    String? destination;
    int totalFiles = 0;
    final errors = <TaskError>[];
    int processedFiles = 0;
    final reportClock = Stopwatch()..start();
    var lastReportMs = 0;
    final conflicts = <ConflictInfo>[];
    final conflictKeys = <String>{};
    Map<String, ConflictResolution> resolutions = {};
    final runtimeResolutions = <String, ConflictResolution>{};
    final promptedSet = <String>{};
    ConflictResolution? runtimeApplyAll;
    Completer<void>? decisionWaker;

    String keyOf(String src, String epath) => '$src $epath';

    void wakeDecisions() {
      final w = decisionWaker;
      decisionWaker = null;
      w?.complete();
    }

    void maybeReport(String currentFile) {
      if (reportClock.elapsedMilliseconds - lastReportMs > 50 ||
          processedFiles % 50 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: 0,
            currentFile: currentFile,
          ),
        );
        lastReportMs = reportClock.elapsedMilliseconds;
      }
    }

    bool unresolved(String key) =>
        runtimeApplyAll == null &&
        runtimeResolutions[key] == null &&
        resolutions[key] == null;

    Future<void> executeExtract() async {
      for (final c in conflicts) {
        if (promptedSet.add(c.sourcePath) && unresolved(c.sourcePath)) {
          mainSendPort.send(ConflictPromptMessage(conflict: c));
        }
      }
      while (!cancelled && conflictKeys.any(unresolved)) {
        decisionWaker = Completer<void>();
        await decisionWaker!.future;
      }
      if (cancelled) {
        mainSendPort.send(TaskDoneMessage(cancelled: true, errors: errors));
        workerReceivePort.close();
        return;
      }

      final dest = destination!;
      for (final src in sources) {
        if (cancelled) break;
        try {
          ArchiveReader.extractAllResolved(
            src,
            (epath, isDir) {
              final target = '$dest/$epath';
              if (isDir) return target;
              final key = keyOf(src, epath);
              if (!conflictKeys.contains(key)) return target;
              final res =
                  runtimeApplyAll ??
                  runtimeResolutions[key] ??
                  resolutions[key] ??
                  ConflictResolution.overwrite;
              return switch (res) {
                ConflictResolution.skip => null,
                ConflictResolution.rename => _uniqueName(target),
                ConflictResolution.overwrite => target,
              };
            },
            isCancelled: () => cancelled,
            onEntry: (name) {
              processedFiles++;
              maybeReport(name.split('/').last);
            },
          );
        } catch (e) {
          errors.add(TaskError(path: src, message: _friendlyError(e)));
          mainSendPort.send(
            ErrorMessage(path: src, message: _friendlyError(e)),
          );
        }
        await Future.delayed(Duration.zero);
      }
      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          sources = msg.sources;
          destination = msg.destination;
          final dest = destination!;
          for (final src in sources) {
            try {
              final entries = ArchiveReader.listEntries(src);
              totalFiles += entries.length;
              for (final e in entries) {
                if (e.isDir) continue;
                final target = '$dest/${e.path}';
                final stat = FileStat.statSync(target);
                if (stat.type == FileSystemEntityType.notFound) continue;
                final key = keyOf(src, e.path);
                conflictKeys.add(key);
                conflicts.add(
                  ConflictInfo(
                    sourcePath: key,
                    targetPath: target,
                    name: e.path.split('/').last,
                    sourceSize: e.size,
                    targetSize: stat.size,
                    sourceModified: e.mtimeSeconds > 0
                        ? DateTime.fromMillisecondsSinceEpoch(
                            e.mtimeSeconds * 1000,
                          )
                        : stat.modified,
                    targetModified: stat.modified,
                  ),
                );
              }
            } catch (_) {}
          }
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: null,
              allPaths: sources,
              conflicts: conflicts,
            ),
          );
        } else if (msg is ExecuteCommand) {
          resolutions = {...resolutions, ...msg.resolutions};
          executeExtract().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is ConflictDecisionCommand) {
          if (msg.applyToAll) runtimeApplyAll = msg.resolution;
          runtimeResolutions[msg.sourcePath] = msg.resolution;
          wakeDecisions();
        } else if (msg is CancelCommand) {
          cancelled = true;
          wakeDecisions();
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void compressWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    List<String> sources = const [];
    String? destination;
    var format = ArchiveFormat.zip;
    var level = CompressionLevel.normal;
    int totalFiles = 0;
    final errors = <TaskError>[];
    int processedFiles = 0;
    final reportClock = Stopwatch()..start();
    var lastReportMs = 0;

    void maybeReport(String currentFile) {
      if (reportClock.elapsedMilliseconds - lastReportMs > 50 ||
          processedFiles % 50 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: 0,
            currentFile: currentFile,
          ),
        );
        lastReportMs = reportClock.elapsedMilliseconds;
      }
    }

    Future<void> executeCompress() async {
      try {
        ArchiveWriter.create(
          sources,
          destination!,
          format,
          level,
          isCancelled: () => cancelled,
          onEntry: (name) {
            processedFiles++;
            maybeReport(name.split('/').last);
          },
        );
      } catch (e) {
        errors.add(TaskError(path: destination ?? '', message: e.toString()));
        mainSendPort.send(
          ErrorMessage(path: destination ?? '', message: e.toString()),
        );
      }
      if (cancelled || errors.isNotEmpty) {
        try {
          final f = File(destination!);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          sources = msg.sources;
          destination = msg.destination;
          format = ArchiveFormat.values.byName(msg.options['format'] ?? 'zip');
          level = CompressionLevel.values.byName(
            msg.options['level'] ?? 'normal',
          );
          totalFiles = ArchiveWriter.planCount(sources);
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: null,
              allPaths: sources,
              conflicts: const [],
            ),
          );
        } else if (msg is ExecuteCommand) {
          executeCompress().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is CancelCommand) {
          cancelled = true;
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void archiveEditWorker(List<dynamic> args) {
    final mainSendPort = args[0] as SendPort;
    final workerReceivePort = ReceivePort();
    mainSendPort.send(workerReceivePort.sendPort);

    bool cancelled = false;
    List<String> addSources = const [];
    String archivePath = '';
    String addInner = '';
    List<String> deleteInner = const [];
    String? renameFrom;
    String? renameTo;
    int totalFiles = 0;
    final errors = <TaskError>[];
    int processedFiles = 0;
    final reportClock = Stopwatch()..start();
    var lastReportMs = 0;

    void maybeReport(String currentFile) {
      if (reportClock.elapsedMilliseconds - lastReportMs > 50 ||
          processedFiles % 50 == 0) {
        mainSendPort.send(
          ProgressMessage(
            processedFiles: processedFiles,
            processedBytes: 0,
            currentFile: currentFile,
          ),
        );
        lastReportMs = reportClock.elapsedMilliseconds;
      }
    }

    Future<void> executeEdit() async {
      try {
        ArchiveWriter.mutate(
          archivePath,
          addSources: addSources,
          addInner: addInner,
          deleteInner: deleteInner,
          renameFromInner: renameFrom,
          renameToName: renameTo,
          isCancelled: () => cancelled,
          onEntry: (name) {
            processedFiles++;
            maybeReport(name.split('/').last);
          },
        );
      } catch (e) {
        errors.add(TaskError(path: archivePath, message: e.toString()));
        mainSendPort.send(
          ErrorMessage(path: archivePath, message: e.toString()),
        );
      }
      mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
      workerReceivePort.close();
    }

    workerReceivePort.listen((msg) {
      try {
        if (msg is StartCommand) {
          addSources = msg.sources;
          archivePath = msg.options['archive'] ?? '';
          addInner = msg.options['addInner'] ?? '';
          final del = msg.options['deleteInner'] ?? '';
          deleteInner = del.isEmpty ? const [] : del.split('\n');
          renameFrom = msg.options['renameFrom'];
          renameTo = msg.options['renameTo'];
          totalFiles = ArchiveWriter.editPlanCount(archivePath, addSources);
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: null,
              allPaths: addSources,
              conflicts: const [],
            ),
          );
        } else if (msg is ExecuteCommand) {
          executeEdit().catchError((e, st) {
            mainSendPort.send(
              TaskDoneMessage(
                cancelled: cancelled,
                errors: [
                  ...errors,
                  TaskError(path: '', message: e.toString()),
                ],
              ),
            );
            workerReceivePort.close();
          });
        } else if (msg is CancelCommand) {
          cancelled = true;
        }
      } catch (e) {
        mainSendPort.send(
          TaskDoneMessage(
            cancelled: cancelled,
            errors: [
              ...errors,
              TaskError(path: '', message: e.toString()),
            ],
          ),
        );
        workerReceivePort.close();
      }
    });
  }

  static void _copyFileSync(File src, String dstPath) {
    SafeFileReplace.copyFile(src, dstPath);
  }

  static void _scanDirForCopy(
    Directory dir,
    String dest,
    Set<String> visited,
    void Function(String path, int bytes, ConflictInfo? conflict) onFile,
    void Function(String path, String message) onError,
  ) {
    final canonical = _resolveCanonical(dir.path);
    if (!visited.add(canonical)) return;
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final targetPath = '$dest${Platform.pathSeparator}$name';
        if (entity is Link) {
          continue;
        } else if (entity is Directory) {
          _scanDirForCopy(entity, targetPath, visited, onFile, onError);
        } else if (entity is File) {
          try {
            final sourceStat = FileStat.statSync(entity.path);
            final size = sourceStat.size;
            ConflictInfo? conflict;
            final targetStat = FileStat.statSync(targetPath);
            if (targetStat.type != FileSystemEntityType.notFound) {
              conflict = ConflictInfo(
                sourcePath: entity.path,
                targetPath: targetPath,
                name: name,
                sourceSize: size,
                targetSize: targetStat.size,
                sourceModified: sourceStat.modified,
                targetModified: targetStat.modified,
              );
            }
            onFile(entity.path, size, conflict);
          } catch (e) {
            onError(entity.path, _friendlyError(e));
          }
        }
      }
    } catch (e) {
      onError(dir.path, _friendlyError(e));
    }
  }

  static void _scanDirForMove(
    Directory dir,
    String dest,
    Set<String> visited,
    void Function(String path, ConflictInfo? conflict) onEntry,
    void Function(String path, String message) onError,
  ) {
    final canonical = _resolveCanonical(dir.path);
    if (!visited.add(canonical)) return;
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final targetPath = '$dest${Platform.pathSeparator}$name';
        if (entity is Link) {
          onEntry(entity.path, null);
          continue;
        } else if (entity is Directory) {
          _scanDirForMove(entity, targetPath, visited, onEntry, onError);
        } else {
          try {
            ConflictInfo? conflict;
            final targetStat = FileStat.statSync(targetPath);
            if (targetStat.type != FileSystemEntityType.notFound) {
              final sourceStat = FileStat.statSync(entity.path);
              conflict = ConflictInfo(
                sourcePath: entity.path,
                targetPath: targetPath,
                name: name,
                sourceSize: sourceStat.size,
                targetSize: targetStat.size,
                sourceModified: sourceStat.modified,
                targetModified: targetStat.modified,
              );
            }
            onEntry(entity.path, conflict);
          } catch (e) {
            onError(entity.path, _friendlyError(e));
          }
        }
      }
    } catch (e) {
      onError(dir.path, _friendlyError(e));
    }
  }

  static String? _findSourceRoot(String path, Set<String> sourceRoots) {
    final sep = Platform.pathSeparator;
    String? best;
    for (final candidate in sourceRoots) {
      if (path == candidate) {
        return candidate;
      }
      if (path.startsWith(candidate) &&
          path.length > candidate.length &&
          path[candidate.length] == sep) {
        if (best == null || candidate.length > best.length) {
          best = candidate;
        }
      }
    }
    return best;
  }

  static Future<void> _moveEntity(
    String src,
    String dst,
    bool Function() isCancelled,
    void Function(String currentName)? onProgress,
  ) async {
    final type = FileSystemEntity.typeSync(src, followLinks: false);
    if (type == FileSystemEntityType.link) {
      final target = Link(src).targetSync();
      Link(dst).createSync(target);
      Link(src).deleteSync();
      return;
    }
    if (type == FileSystemEntityType.directory) {
      try {
        Directory(src).renameSync(dst);
      } on FileSystemException {
        await _copyDirectory(
          Directory(src),
          Directory(dst),
          isCancelled,
          onProgress,
        );
        if (isCancelled()) return;
        Directory(src).deleteSync(recursive: true);
      }
    } else {
      try {
        File(src).renameSync(dst);
      } on FileSystemException {
        _copyFileSync(File(src), dst);
        if (isCancelled()) {
          return;
        }
        File(src).deleteSync();
      }
    }
  }

  static void _deleteExistingEntity(String path) {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      Link(path).deleteSync();
    } else if (type == FileSystemEntityType.directory) {
      Directory(path).deleteSync(recursive: true);
    } else if (type == FileSystemEntityType.file) {
      File(path).deleteSync();
    }
  }

  static Future<void> _copyDirectory(
    Directory src,
    Directory dst,
    bool Function() isCancelled,
    void Function(String currentName)? onProgress,
  ) async {
    if (!dst.existsSync()) dst.createSync(recursive: true);
    int counter = 0;
    for (final entity in src.listSync(followLinks: false)) {
      if (isCancelled()) return;
      final name = entity.path.split(Platform.pathSeparator).last;
      final newPath = '${dst.path}${Platform.pathSeparator}$name';
      if (entity is Link) {
        try {
          Link(newPath).createSync(entity.targetSync());
        } catch (_) {}
      } else if (entity is Directory) {
        await _copyDirectory(
          entity,
          Directory(newPath),
          isCancelled,
          onProgress,
        );
      } else if (entity is File) {
        _copyFileSync(entity, newPath);
        onProgress?.call(name);
      }
      if ((++counter & 0x3F) == 0) {
        await Future.delayed(Duration.zero);
      }
    }
  }

  static String _resolveCanonical(String path) {
    try {
      return File(path).resolveSymbolicLinksSync();
    } catch (_) {
      return path;
    }
  }

  static String _uniqueName(String path) {
    if (!File(path).existsSync() && !Directory(path).existsSync()) return path;
    final dir = path.substring(0, path.lastIndexOf(Platform.pathSeparator));
    final name = path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);
    final dotIndex = name.lastIndexOf('.');
    for (int counter = 1; counter <= 10000; counter++) {
      final newName = dotIndex > 0
          ? '${name.substring(0, dotIndex)} ($counter)${name.substring(dotIndex)}'
          : '$name ($counter)';
      final newPath = '$dir${Platform.pathSeparator}$newName';
      if (!File(newPath).existsSync() && !Directory(newPath).existsSync()) {
        return newPath;
      }
    }
    return '$dir${Platform.pathSeparator}$name.${DateTime.now().microsecondsSinceEpoch}';
  }

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (e is FileSystemException) {
      if (msg.contains('Permission denied') ||
          msg.contains('errno = 13') ||
          msg.contains('Access is denied') ||
          msg.contains('ERROR_ACCESS_DENIED')) {
        return t.errors.permissionDenied;
      }
      if (msg.contains('No space left') ||
          msg.contains('errno = 28') ||
          msg.contains('ERROR_DISK_FULL') ||
          msg.contains('There is not enough space')) {
        return t.errors.noSpace;
      }
      if (msg.contains('Read-only file system') ||
          msg.contains('errno = 30') ||
          msg.contains('ERROR_WRITE_PROTECT')) {
        return t.errors.readOnly;
      }
      if (msg.contains('No such file') ||
          msg.contains('errno = 2') ||
          msg.contains('ERROR_FILE_NOT_FOUND') ||
          msg.contains('ERROR_PATH_NOT_FOUND') ||
          msg.contains('The system cannot find')) {
        return t.errors.notFound;
      }
      if (msg.contains('Directory not empty') ||
          msg.contains('errno = 39') ||
          msg.contains('ERROR_DIR_NOT_EMPTY')) {
        return t.errors.notEmpty;
      }
      if (msg.contains('cross-device') ||
          msg.contains('errno = 18') ||
          msg.contains('ERROR_NOT_SAME_DEVICE')) {
        return t.errors.crossDevice;
      }
      if (e.message.isNotEmpty) return e.message;
    }
    if (msg.length > 120) return '${msg.substring(0, 117)}...';
    return msg;
  }
}
