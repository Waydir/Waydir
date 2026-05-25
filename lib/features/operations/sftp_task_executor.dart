import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/fs/sftp_fs.dart';
import '../../core/fs/sftp_session_manager.dart';
import '../../core/fs/waydir_core_loader.dart';
import '../../core/models/file_entry.dart';
import '../../core/models/file_operation.dart';
import '../../core/platform/platform_paths.dart';

const _chunkBytes = 256 * 1024;
const sftpSessionsOptionKey = '_sftpSessions';

class SftpTaskExecutor {
  SftpTaskExecutor._();

  static bool involvesSftp({
    required List<String> sources,
    String? destination,
  }) {
    if (destination != null && PlatformPaths.isSftpUri(destination)) {
      return true;
    }
    return sources.any(PlatformPaths.isSftpUri);
  }

  /// Snapshot aktywnych sesji SFTP serializowany do `task.options`. Worker
  /// odtwarza je w swoim isolate przez `SftpSessionManager.seedRecords`.
  static String encodeSessions() {
    return jsonEncode([
      for (final r in SftpSessionManager.exportRecords()) r.toJson(),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Workers
// ---------------------------------------------------------------------------

void sftpCopyWorker(List<dynamic> args) {
  _runTransferWorker(args, move: false);
}

void sftpMoveWorker(List<dynamic> args) {
  _runTransferWorker(args, move: true);
}

void sftpDeleteWorker(List<dynamic> args) {
  final mainSendPort = args[0] as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  var cancelled = false;
  List<String> sources = const [];
  final errors = <TaskError>[];
  var processedFiles = 0;
  var totalFiles = 0;
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

  Future<void> executeDelete() async {
    final fs = const SftpFs();
    for (final src in sources) {
      if (cancelled) break;
      try {
        await _removeAny(src, fs);
        processedFiles++;
        maybeReport(PlatformPaths.fileName(src));
      } catch (e) {
        errors.add(TaskError(path: src, message: _friendly(e)));
        mainSendPort.send(ErrorMessage(path: src, message: _friendly(e)));
      }
      await Future<void>.delayed(Duration.zero);
    }
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        _seedSessionsFromOptions(msg.options);
        sources = msg.sources;
        totalFiles = sources.length;
        mainSendPort.send(
          PreScanResultMessage(
            totalFiles: totalFiles,
            totalBytes: null,
            allPaths: sources,
            conflicts: const [],
          ),
        );
      } else if (msg is ExecuteCommand) {
        executeDelete().catchError((e, _) {
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

// ---------------------------------------------------------------------------
// Copy / move shared implementation
// ---------------------------------------------------------------------------

void _runTransferWorker(List<dynamic> args, {required bool move}) {
  final mainSendPort = args[0] as SendPort;
  final workerReceivePort = ReceivePort();
  mainSendPort.send(workerReceivePort.sendPort);

  var cancelled = false;
  List<String> sources = const [];
  String? destination;
  final errors = <TaskError>[];
  final conflicts = <ConflictInfo>[];
  final allPaths = <String>[];
  final sourceSizes = <String, int>{};
  final sourceFileCounts = <String, int>{};
  var totalFiles = 0;
  var totalBytes = 0;
  var processedFiles = 0;
  var processedBytes = 0;

  Map<String, ConflictResolution> resolutions = {};
  final runtimeResolutions = <String, ConflictResolution>{};
  ConflictResolution? runtimeApplyAll;
  Completer<void>? decisionWaker;
  final reservedTargetNames = <String>{};

  final reportClock = Stopwatch()..start();
  var lastReportMs = 0;

  void wakeDecisions() {
    final w = decisionWaker;
    decisionWaker = null;
    w?.complete();
  }

  void maybeReport(String currentFile, {bool force = false}) {
    if (force || reportClock.elapsedMilliseconds - lastReportMs > 50) {
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

  ConflictResolution? resolutionFor(String sourcePath) {
    return runtimeApplyAll ??
        runtimeResolutions[sourcePath] ??
        resolutions[sourcePath];
  }

  Future<void> prescanRoot(String src, SftpFs fs) async {
    try {
      final name = PlatformPaths.fileName(src);
      final destIsSftp = PlatformPaths.isSftpUri(destination!);
      final dstTop = _joinDest(destination!, name, destIsSftp);

      final srcStat = await _statAny(src, fs);
      if (srcStat == null) {
        errors.add(TaskError(path: src, message: 'Source not found'));
        mainSendPort.send(ErrorMessage(path: src, message: 'Source not found'));
        return;
      }

      var size = 0;
      var fileCount = 1;
      if (srcStat.type == FileItemType.folder) {
        final scan = await _scanRecursive(src, fs);
        size = scan.bytes;
        fileCount = scan.files;
      } else {
        size = srcStat.size;
      }
      sourceSizes[src] = size;
      sourceFileCounts[src] = fileCount;
      totalFiles += fileCount;
      totalBytes += size;
      allPaths.add(src);

      final dstStat = await _statAny(dstTop, fs);
      if (dstStat != null) {
        conflicts.add(
          ConflictInfo(
            sourcePath: src,
            targetPath: dstTop,
            name: name,
            sourceSize: size,
            targetSize: dstStat.size,
            sourceModified: DateTime.fromMillisecondsSinceEpoch(
              srcStat.modifiedMs == 0
                  ? DateTime.now().millisecondsSinceEpoch
                  : srcStat.modifiedMs,
            ),
            targetModified: DateTime.fromMillisecondsSinceEpoch(
              dstStat.modifiedMs == 0
                  ? DateTime.now().millisecondsSinceEpoch
                  : dstStat.modifiedMs,
            ),
          ),
        );
      }
    } catch (e) {
      errors.add(TaskError(path: src, message: _friendly(e)));
      mainSendPort.send(ErrorMessage(path: src, message: _friendly(e)));
    }
  }

  Future<String> resolveTargetPath(
    String src,
    String desiredDst,
    bool dstIsSftp,
    SftpFs fs,
    ConflictResolution? resolution,
  ) async {
    if (resolution != ConflictResolution.rename) {
      reservedTargetNames.add(desiredDst);
      return desiredDst;
    }
    final unique = await _uniquePath(
      desiredDst,
      dstIsSftp,
      fs,
      reserved: reservedTargetNames,
    );
    reservedTargetNames.add(unique);
    return unique;
  }

  Future<bool> processRoot(String src, SftpFs fs) async {
    final resolution = resolutionFor(src);
    if (resolution == ConflictResolution.skip) {
      processedFiles += sourceFileCounts[src] ?? 1;
      maybeReport(PlatformPaths.fileName(src));
      return true;
    }

    final name = PlatformPaths.fileName(src);
    final destIsSftp = PlatformPaths.isSftpUri(destination!);
    final desiredDst = _joinDest(destination!, name, destIsSftp);

    final dst = await resolveTargetPath(
      src,
      desiredDst,
      destIsSftp,
      fs,
      resolution,
    );

    void onBytes(String path, int delta) {
      processedBytes += delta;
      if (processedBytes > totalBytes) totalBytes = processedBytes;
      maybeReport(PlatformPaths.fileName(path));
    }

    void onEntry(String path) {
      processedFiles++;
      maybeReport(PlatformPaths.fileName(path));
    }

    if (move) {
      final srcIsSftp = PlatformPaths.isSftpUri(src);
      if (srcIsSftp && destIsSftp && _sameSftpSession(src, dst)) {
        await _ensureParentDir(dst, destIsSftp, fs);
        if (resolution == ConflictResolution.overwrite) {
          await _removeAnySafe(dst, fs);
        }
        await fs.rename(src, dst);
        processedFiles += sourceFileCounts[src] ?? 1;
        maybeReport(name);
        return true;
      }
    }

    try {
      await _copyEntity(
        src,
        dst,
        fs,
        isCancelled: () => cancelled,
        overwriteAllowed: resolution == ConflictResolution.overwrite,
        onBytes: onBytes,
        onEntry: onEntry,
      );
      if (move && !cancelled) {
        await _removeAny(src, fs);
      }
    } catch (e) {
      if (e is _SftpCancelled) rethrow;
      errors.add(TaskError(path: src, message: _friendly(e)));
      mainSendPort.send(ErrorMessage(path: src, message: _friendly(e)));
    }
    return true;
  }

  Future<void> executeTransfer() async {
    final fs = const SftpFs();

    final unresolved = conflicts
        .where(
          (c) =>
              runtimeApplyAll == null &&
              runtimeResolutions[c.sourcePath] == null &&
              resolutions[c.sourcePath] == null,
        )
        .toList();
    for (final c in unresolved) {
      mainSendPort.send(ConflictPromptMessage(conflict: c));
    }
    while (!cancelled &&
        conflicts.any(
          (c) =>
              runtimeApplyAll == null &&
              runtimeResolutions[c.sourcePath] == null &&
              resolutions[c.sourcePath] == null,
        )) {
      decisionWaker = Completer<void>();
      await decisionWaker!.future;
    }

    for (final src in sources) {
      if (cancelled) break;
      try {
        await processRoot(src, fs);
      } on _SftpCancelled {
        break;
      }
      await Future<void>.delayed(Duration.zero);
    }

    maybeReport('', force: true);
    mainSendPort.send(TaskDoneMessage(cancelled: cancelled, errors: errors));
    workerReceivePort.close();
  }

  workerReceivePort.listen((msg) {
    try {
      if (msg is StartCommand) {
        _seedSessionsFromOptions(msg.options);
        sources = msg.sources;
        destination = msg.destination;
        Future(() async {
          try {
            final fs = const SftpFs();
            for (final src in sources) {
              if (cancelled) break;
              await prescanRoot(src, fs);
            }
          } catch (e) {
            errors.add(TaskError(path: '', message: _friendly(e)));
          }
          mainSendPort.send(
            PreScanResultMessage(
              totalFiles: totalFiles,
              totalBytes: totalBytes > 0 ? totalBytes : null,
              allPaths: allPaths,
              conflicts: conflicts,
            ),
          );
        });
      } else if (msg is ExecuteCommand) {
        resolutions = msg.resolutions;
        executeTransfer().catchError((e, _) {
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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _seedSessionsFromOptions(Map<String, String> options) {
  final raw = options[sftpSessionsOptionKey];
  if (raw == null || raw.isEmpty) return;
  try {
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    SftpSessionManager.seedRecords(list.map(SftpSessionRecord.fromJson));
  } catch (_) {}
}

String _joinDest(String destination, String name, bool destIsSftp) {
  if (destIsSftp) {
    final trimmed = destination.endsWith('/')
        ? destination.substring(0, destination.length - 1)
        : destination;
    return '$trimmed/$name';
  }
  return '$destination${PlatformPaths.separator}$name';
}

bool _sameSftpSession(String a, String b) {
  final ra = SftpSessionManager.recordFor(a);
  final rb = SftpSessionManager.recordFor(b);
  return ra != null && rb != null && ra.sessionId == rb.sessionId;
}

class _AnyStat {
  final FileItemType type;
  final int size;
  final int modifiedMs;
  const _AnyStat(this.type, this.size, this.modifiedMs);
}

Future<_AnyStat?> _statAny(String path, SftpFs fs) async {
  if (PlatformPaths.isSftpUri(path)) {
    final s = await fs.stat(path);
    if (s == null) return null;
    return _AnyStat(s.type, s.size, s.modifiedMs);
  }
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) return null;
  if (type == FileSystemEntityType.directory) {
    final stat = FileStat.statSync(path);
    return _AnyStat(
      FileItemType.folder,
      0,
      stat.modified.millisecondsSinceEpoch,
    );
  }
  final stat = FileStat.statSync(path);
  return _AnyStat(
    FileItemType.file,
    stat.size,
    stat.modified.millisecondsSinceEpoch,
  );
}

Future<({int files, int bytes})> _scanRecursive(String path, SftpFs fs) async {
  if (PlatformPaths.isSftpUri(path)) {
    final stat = await fs.stat(path);
    if (stat == null) return (files: 0, bytes: 0);
    if (stat.type != FileItemType.folder) {
      return (files: 1, bytes: stat.size);
    }
    var files = 1;
    var bytes = 0;
    final entries = await fs.listDirectory(path);
    for (final entry in entries) {
      final r = await _scanRecursive(entry.path, fs);
      files += r.files;
      bytes += r.bytes;
    }
    return (files: files, bytes: bytes);
  }
  final type = FileSystemEntity.typeSync(path, followLinks: false);
  if (type == FileSystemEntityType.notFound) return (files: 0, bytes: 0);
  if (type != FileSystemEntityType.directory) {
    return (files: 1, bytes: File(path).lengthSync());
  }
  var files = 1;
  var bytes = 0;
  await for (final entity in Directory(path).list(followLinks: false)) {
    final r = await _scanRecursive(entity.path, fs);
    files += r.files;
    bytes += r.bytes;
  }
  return (files: files, bytes: bytes);
}

Future<String> _uniquePath(
  String desired,
  bool isSftp,
  SftpFs fs, {
  Set<String>? reserved,
}) async {
  Future<bool> taken(String p) async {
    if (reserved?.contains(p) ?? false) return true;
    final stat = await _statAny(p, fs);
    return stat != null;
  }

  if (!await taken(desired)) return desired;
  final sep = isSftp ? '/' : PlatformPaths.separator;
  final idx = desired.lastIndexOf(sep);
  final dir = idx > 0 ? desired.substring(0, idx) : '';
  final name = idx >= 0 ? desired.substring(idx + 1) : desired;
  final dot = name.lastIndexOf('.');
  for (var i = 1; i < 10000; i++) {
    final newName = dot > 0
        ? '${name.substring(0, dot)} ($i)${name.substring(dot)}'
        : '$name ($i)';
    final candidate = dir.isEmpty ? newName : '$dir$sep$newName';
    if (!await taken(candidate)) return candidate;
  }
  return '$desired.${DateTime.now().microsecondsSinceEpoch}';
}

Future<void> _ensureParentDir(String path, bool isSftp, SftpFs fs) async {
  final sep = isSftp ? '/' : PlatformPaths.separator;
  final idx = path.lastIndexOf(sep);
  if (idx <= 0) return;
  final parent = path.substring(0, idx);
  if (parent.isEmpty) return;
  if (isSftp) {
    try {
      await fs.mkdir(parent, recursive: true);
    } catch (_) {}
  } else {
    try {
      await Directory(parent).create(recursive: true);
    } catch (_) {}
  }
}

Future<void> _ensureDirExists(String path, bool isSftp, SftpFs fs) async {
  if (isSftp) {
    try {
      await fs.mkdir(path, recursive: true);
    } catch (_) {}
  } else {
    await Directory(path).create(recursive: true);
  }
}

Future<void> _removeAny(String src, SftpFs fs) async {
  if (PlatformPaths.isSftpUri(src)) {
    final stat = await fs.stat(src);
    if (stat == null) return;
    await fs.remove(src, recursive: stat.type == FileItemType.folder);
    return;
  }
  final type = FileSystemEntity.typeSync(src, followLinks: false);
  if (type == FileSystemEntityType.notFound) return;
  if (type == FileSystemEntityType.directory) {
    await Directory(src).delete(recursive: true);
  } else if (type == FileSystemEntityType.link) {
    await Link(src).delete();
  } else {
    await File(src).delete();
  }
}

Future<void> _removeAnySafe(String src, SftpFs fs) async {
  try {
    await _removeAny(src, fs);
  } catch (_) {}
}

void _checkCancelled(bool Function() isCancelled) {
  if (isCancelled()) throw const _SftpCancelled();
}

String _partPath(String dst, bool isSftp) {
  final rand = math.Random().nextInt(0x7fffffff);
  return '$dst.waydir-${DateTime.now().microsecondsSinceEpoch}-$rand.part';
}

// ---------------------------------------------------------------------------
// Copy primitives (atomic write)
// ---------------------------------------------------------------------------

Future<void> _copyEntity(
  String src,
  String dst,
  SftpFs fs, {
  required bool Function() isCancelled,
  required bool overwriteAllowed,
  required void Function(String path, int bytes) onBytes,
  required void Function(String path) onEntry,
}) async {
  _checkCancelled(isCancelled);
  final srcIsSftp = PlatformPaths.isSftpUri(src);
  final dstIsSftp = PlatformPaths.isSftpUri(dst);

  final srcStat = await _statAny(src, fs);
  if (srcStat == null) {
    throw FileSystemException('Source not found', src);
  }

  if (srcStat.type == FileItemType.folder) {
    await _ensureDirExists(dst, dstIsSftp, fs);
    final entries = srcIsSftp
        ? await fs.listDirectory(src)
        : await Directory(src)
              .list(followLinks: false)
              .map(
                (e) => FileEntry.raw(
                  name: PlatformPaths.fileName(e.path),
                  path: e.path,
                  type: e is Directory
                      ? FileItemType.folder
                      : FileItemType.file,
                  size: 0,
                  modifiedMs: 0,
                ),
              )
              .toList();
    for (final e in entries) {
      _checkCancelled(isCancelled);
      final childDst = _joinDest(dst, e.name, dstIsSftp);
      await _copyEntity(
        e.path,
        childDst,
        fs,
        isCancelled: isCancelled,
        overwriteAllowed: overwriteAllowed,
        onBytes: onBytes,
        onEntry: onEntry,
      );
    }
    onEntry(src);
    return;
  }

  await _ensureParentDir(dst, dstIsSftp, fs);
  final partial = _partPath(dst, dstIsSftp);
  try {
    if (srcIsSftp && dstIsSftp) {
      await _copySftpToSftp(
        src,
        partial,
        size: srcStat.size,
        onBytes: (b) => onBytes(src, b),
        isCancelled: isCancelled,
      );
    } else if (srcIsSftp) {
      await _downloadSftpToLocal(
        src,
        partial,
        size: srcStat.size,
        onBytes: (b) => onBytes(src, b),
        isCancelled: isCancelled,
      );
    } else if (dstIsSftp) {
      await _uploadLocalToSftp(
        src,
        partial,
        onBytes: (b) => onBytes(src, b),
        isCancelled: isCancelled,
      );
    } else {
      await _copyLocalToLocal(
        src,
        partial,
        onBytes: (b) => onBytes(src, b),
        isCancelled: isCancelled,
      );
    }
    _checkCancelled(isCancelled);
    await _atomicSwap(partial, dst, dstIsSftp, fs, overwriteAllowed);
  } catch (e) {
    await _removeAnySafe(partial, fs);
    rethrow;
  }
  onEntry(src);
}

Future<void> _atomicSwap(
  String partial,
  String dst,
  bool dstIsSftp,
  SftpFs fs,
  bool overwriteAllowed,
) async {
  final existing = await _statAny(dst, fs);
  if (existing != null) {
    if (!overwriteAllowed) {
      await _removeAnySafe(partial, fs);
      throw FileSystemException('Target exists', dst);
    }
    await _removeAny(dst, fs);
  }
  if (dstIsSftp) {
    final rec = SftpSessionManager.recordFor(dst);
    if (rec == null) {
      throw FileSystemException('No active SFTP session', dst);
    }
    final ok = WaydirCoreLoader.sftpRename(
      rec.sessionId,
      SftpSessionManager.remotePath(partial),
      SftpSessionManager.remotePath(dst),
    );
    if (!ok) throw FileSystemException('SFTP rename failed', dst);
  } else {
    await File(partial).rename(dst);
  }
}

Future<void> _copyLocalToLocal(
  String src,
  String dst, {
  required void Function(int bytes) onBytes,
  required bool Function() isCancelled,
}) async {
  final input = File(src).openRead();
  final sink = File(dst).openWrite();
  try {
    await for (final chunk in input) {
      _checkCancelled(isCancelled);
      sink.add(chunk);
      onBytes(chunk.length);
      await Future<void>.delayed(Duration.zero);
    }
  } finally {
    await sink.close();
  }
}

Future<void> _uploadLocalToSftp(
  String src,
  String dst, {
  required void Function(int bytes) onBytes,
  required bool Function() isCancelled,
}) async {
  final rec = SftpSessionManager.recordFor(dst);
  if (rec == null) {
    throw FileSystemException('No active SFTP session', dst);
  }
  final remote = SftpSessionManager.remotePath(dst);

  if (WaydirCoreLoader.supportsSftpStreaming()) {
    final writerId = WaydirCoreLoader.sftpOpenWriter(rec.sessionId, remote);
    if (writerId == null) {
      throw FileSystemException('SFTP open writer failed', dst);
    }
    try {
      await for (final raw in File(src).openRead()) {
        _checkCancelled(isCancelled);
        final data = raw is Uint8List ? raw : Uint8List.fromList(raw);
        var offset = 0;
        while (offset < data.length) {
          _checkCancelled(isCancelled);
          final end = math.min(data.length, offset + _chunkBytes);
          final part = Uint8List.sublistView(data, offset, end);
          if (!WaydirCoreLoader.sftpWriterWrite(writerId, part)) {
            throw FileSystemException('SFTP write failed', dst);
          }
          offset = end;
          onBytes(part.length);
          await Future<void>.delayed(Duration.zero);
        }
      }
    } catch (_) {
      WaydirCoreLoader.sftpWriterClose(writerId);
      rethrow;
    }
    final closed = WaydirCoreLoader.sftpWriterClose(writerId);
    if (!closed) throw FileSystemException('SFTP close failed', dst);
    return;
  }

  // Fallback (stary ABI < 10): per-chunk open/close.
  if (!WaydirCoreLoader.supportsSftpWriteChunk()) {
    final data = await File(src).readAsBytes();
    _checkCancelled(isCancelled);
    final ok = WaydirCoreLoader.sftpWrite(rec.sessionId, remote, data);
    if (!ok) throw FileSystemException('SFTP write failed', dst);
    onBytes(data.length);
    return;
  }
  var append = false;
  await for (final raw in File(src).openRead()) {
    _checkCancelled(isCancelled);
    final data = raw is Uint8List ? raw : Uint8List.fromList(raw);
    var offset = 0;
    while (offset < data.length) {
      _checkCancelled(isCancelled);
      final end = math.min(data.length, offset + _chunkBytes);
      final part = Uint8List.sublistView(data, offset, end);
      final ok = WaydirCoreLoader.sftpWriteChunk(
        rec.sessionId,
        remote,
        part,
        append: append,
      );
      if (!ok) throw FileSystemException('SFTP write failed', dst);
      append = true;
      offset = end;
      onBytes(part.length);
      await Future<void>.delayed(Duration.zero);
    }
  }
  if (!append) {
    final ok = WaydirCoreLoader.sftpWriteChunk(
      rec.sessionId,
      remote,
      Uint8List(0),
      append: false,
    );
    if (!ok) throw FileSystemException('SFTP write failed', dst);
  }
}

Future<void> _downloadSftpToLocal(
  String src,
  String dst, {
  required int size,
  required void Function(int bytes) onBytes,
  required bool Function() isCancelled,
}) async {
  final rec = SftpSessionManager.recordFor(src);
  if (rec == null) {
    throw FileSystemException('No active SFTP session', src);
  }
  final remote = SftpSessionManager.remotePath(src);

  if (WaydirCoreLoader.supportsSftpStreaming()) {
    final opened = WaydirCoreLoader.sftpOpenReader(rec.sessionId, remote);
    if (opened == null) {
      throw FileSystemException('SFTP open reader failed', src);
    }
    final sink = File(dst).openWrite();
    try {
      while (true) {
        _checkCancelled(isCancelled);
        final chunk = WaydirCoreLoader.sftpReaderRead(
          opened.readerId,
          _chunkBytes,
        );
        if (chunk == null) {
          throw FileSystemException('SFTP read failed', src);
        }
        if (chunk.isEmpty) break;
        sink.add(chunk);
        onBytes(chunk.length);
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      WaydirCoreLoader.sftpReaderClose(opened.readerId);
      await sink.close();
    }
    return;
  }

  // Fallback (stary ABI < 10): chunkowane read_range z otwieraniem za każdym razem.
  final sink = File(dst).openWrite();
  var offset = 0;
  try {
    while (offset < size) {
      _checkCancelled(isCancelled);
      final length = math.min(size - offset, _chunkBytes);
      final chunk = WaydirCoreLoader.sftpRead(
        rec.sessionId,
        remote,
        start: offset,
        length: length,
      );
      if (chunk == null) {
        throw FileSystemException('SFTP read failed', src);
      }
      if (chunk.isEmpty) break;
      sink.add(chunk);
      offset += chunk.length;
      onBytes(chunk.length);
      await Future<void>.delayed(Duration.zero);
    }
  } finally {
    await sink.close();
  }
}

Future<void> _copySftpToSftp(
  String src,
  String dst, {
  required int size,
  required void Function(int bytes) onBytes,
  required bool Function() isCancelled,
}) async {
  final srcRec = SftpSessionManager.recordFor(src);
  final dstRec = SftpSessionManager.recordFor(dst);
  if (srcRec == null) {
    throw FileSystemException('No active SFTP session', src);
  }
  if (dstRec == null) {
    throw FileSystemException('No active SFTP session', dst);
  }
  final srcRemote = SftpSessionManager.remotePath(src);
  final dstRemote = SftpSessionManager.remotePath(dst);

  if (WaydirCoreLoader.supportsSftpStreaming()) {
    final opened = WaydirCoreLoader.sftpOpenReader(srcRec.sessionId, srcRemote);
    if (opened == null) {
      throw FileSystemException('SFTP open reader failed', src);
    }
    final writerId = WaydirCoreLoader.sftpOpenWriter(
      dstRec.sessionId,
      dstRemote,
    );
    if (writerId == null) {
      WaydirCoreLoader.sftpReaderClose(opened.readerId);
      throw FileSystemException('SFTP open writer failed', dst);
    }
    try {
      while (true) {
        _checkCancelled(isCancelled);
        final chunk = WaydirCoreLoader.sftpReaderRead(
          opened.readerId,
          _chunkBytes,
        );
        if (chunk == null) {
          throw FileSystemException('SFTP read failed', src);
        }
        if (chunk.isEmpty) break;
        if (!WaydirCoreLoader.sftpWriterWrite(writerId, chunk)) {
          throw FileSystemException('SFTP write failed', dst);
        }
        onBytes(chunk.length);
        await Future<void>.delayed(Duration.zero);
      }
    } catch (_) {
      WaydirCoreLoader.sftpReaderClose(opened.readerId);
      WaydirCoreLoader.sftpWriterClose(writerId);
      rethrow;
    }
    WaydirCoreLoader.sftpReaderClose(opened.readerId);
    if (!WaydirCoreLoader.sftpWriterClose(writerId)) {
      throw FileSystemException('SFTP close failed', dst);
    }
    return;
  }

  if (!WaydirCoreLoader.supportsSftpWriteChunk()) {
    final data = WaydirCoreLoader.sftpRead(srcRec.sessionId, srcRemote);
    if (data == null) {
      throw FileSystemException('SFTP read failed', src);
    }
    _checkCancelled(isCancelled);
    final ok = WaydirCoreLoader.sftpWrite(dstRec.sessionId, dstRemote, data);
    if (!ok) throw FileSystemException('SFTP write failed', dst);
    onBytes(data.length);
    return;
  }

  var offset = 0;
  var append = false;
  while (offset < size) {
    _checkCancelled(isCancelled);
    final length = math.min(size - offset, _chunkBytes);
    final chunk = WaydirCoreLoader.sftpRead(
      srcRec.sessionId,
      srcRemote,
      start: offset,
      length: length,
    );
    if (chunk == null) {
      throw FileSystemException('SFTP read failed', src);
    }
    if (chunk.isEmpty) break;
    final ok = WaydirCoreLoader.sftpWriteChunk(
      dstRec.sessionId,
      dstRemote,
      chunk,
      append: append,
    );
    if (!ok) throw FileSystemException('SFTP write failed', dst);
    append = true;
    offset += chunk.length;
    onBytes(chunk.length);
    await Future<void>.delayed(Duration.zero);
  }
  if (!append) {
    final ok = WaydirCoreLoader.sftpWriteChunk(
      dstRec.sessionId,
      dstRemote,
      Uint8List(0),
      append: false,
    );
    if (!ok) throw FileSystemException('SFTP write failed', dst);
  }
}

class _SftpCancelled implements Exception {
  const _SftpCancelled();
}

String _friendly(Object e) {
  final msg = e.toString();
  if (msg.length > 200) return '${msg.substring(0, 197)}...';
  return msg;
}
