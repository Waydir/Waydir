import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import '../archive/archive_reader.dart';
import '../archive/archive_service.dart';
import '../models/file_entry.dart';
import '../platform/platform_paths.dart';

enum _Op {
  list,
  exists,
  isDir,
  mkdir,
  delete,
  stat,
  archiveList,
  archiveExtract,
  archiveExtractTree,
}

class _Request {
  final int id;
  final _Op op;
  final List<dynamic> args;
  const _Request(this.id, this.op, this.args);
}

class _Response {
  final int id;
  final dynamic result;
  final Object? error;
  const _Response(this.id, this.result, this.error);
}

class FsWorkerPool {
  static final FsWorkerPool instance = FsWorkerPool._();
  FsWorkerPool._();

  SendPort? _commandPort;
  ReceivePort? _replyPort;
  ReceivePort? _errorPort;
  ReceivePort? _exitPort;
  Isolate? _isolate;
  StreamSubscription? _replySubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _exitSubscription;
  final _pending = <int, Completer<dynamic>>{};
  int _nextId = 0;
  Future<void>? _initFuture;

  Future<void> ensureStarted() async {
    final existing = _initFuture;
    if (existing != null) return existing;
    final future = _start();
    _initFuture = future;
    try {
      await future;
    } catch (_) {
      if (identical(_initFuture, future)) {
        _initFuture = null;
      }
      rethrow;
    }
  }

  Future<void> _start() async {
    final ready = ReceivePort();
    _errorPort = ReceivePort();
    _exitPort = ReceivePort();
    final workerReady = Completer<SendPort>();

    late StreamSubscription readySub;
    readySub = ready.listen((msg) {
      if (msg is SendPort && !workerReady.isCompleted) {
        workerReady.complete(msg);
        readySub.cancel();
        ready.close();
      }
    });

    _errorSubscription = _errorPort!.listen((err) {
      if (!workerReady.isCompleted) {
        workerReady.completeError(StateError('FS worker failed: $err'));
      }
      _handleWorkerFailure(StateError('FS worker failed: $err'));
    });
    _exitSubscription = _exitPort!.listen((_) {
      if (!workerReady.isCompleted) {
        workerReady.completeError(StateError('FS worker exited before ready'));
      }
      _handleWorkerFailure(StateError('FS worker exited unexpectedly'));
    });

    try {
      _isolate = await Isolate.spawn<SendPort>(
        _entryPoint,
        ready.sendPort,
        errorsAreFatal: false,
        onError: _errorPort!.sendPort,
        onExit: _exitPort!.sendPort,
      );

      _commandPort = await workerReady.future;
    } catch (_) {
      await readySub.cancel();
      ready.close();
      _errorSubscription?.cancel();
      _exitSubscription?.cancel();
      _errorPort?.close();
      _exitPort?.close();
      _errorSubscription = null;
      _exitSubscription = null;
      _errorPort = null;
      _exitPort = null;
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      rethrow;
    }

    _replyPort = ReceivePort();
    _commandPort!.send(_replyPort!.sendPort);
    _replySubscription = _replyPort!.listen((msg) {
      if (msg is _Response) {
        final completer = _pending.remove(msg.id);
        if (completer == null) return;
        if (msg.error != null) {
          completer.completeError(msg.error!);
        } else {
          completer.complete(msg.result);
        }
      }
    });
  }

  Future<T> _run<T>(_Op op, List<dynamic> args) async {
    await ensureStarted();
    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pending[id] = completer;
    _commandPort!.send(_Request(id, op, args));
    final result = await completer.future;
    return result as T;
  }

  Future<List<FileEntry>> listDirectory(String path) =>
      _run<List<FileEntry>>(_Op.list, [path]);

  Future<bool> directoryExists(String path) => _run<bool>(_Op.exists, [path]);

  Future<bool> isDirectory(String path) => _run<bool>(_Op.isDir, [path]);

  Future<void> createDirectory(String path) => _run<void>(_Op.mkdir, [path]);

  Future<void> delete(String path, {bool recursive = false}) =>
      _run<void>(_Op.delete, [path, recursive]);

  Future<FileEntry?> stat(String path) => _run<FileEntry?>(_Op.stat, [path]);

  Future<List<FileEntry>> listArchive(String archivePath, String innerPath) =>
      _run<List<FileEntry>>(_Op.archiveList, [archivePath, innerPath]);

  Future<void> extractArchiveEntry(
    String archivePath,
    String innerPath,
    String destPath,
  ) => _run<void>(_Op.archiveExtract, [archivePath, innerPath, destPath]);

  Future<String> extractArchiveTree(
    String archivePath,
    String innerPath,
    String stagingDir,
  ) => _run<String>(_Op.archiveExtractTree, [
    archivePath,
    innerPath,
    stagingDir,
  ]);

  void dispose() {
    _replySubscription?.cancel();
    _errorSubscription?.cancel();
    _exitSubscription?.cancel();
    _replyPort?.close();
    _errorPort?.close();
    _exitPort?.close();
    _isolate?.kill(priority: Isolate.immediate);
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('Pool disposed'));
    }
    _pending.clear();
    _commandPort = null;
    _replyPort = null;
    _errorPort = null;
    _exitPort = null;
    _isolate = null;
    _replySubscription = null;
    _errorSubscription = null;
    _exitSubscription = null;
    _initFuture = null;
  }

  void _handleWorkerFailure(Object error) {
    _replySubscription?.cancel();
    _errorSubscription?.cancel();
    _exitSubscription?.cancel();
    _replySubscription = null;
    _errorSubscription = null;
    _exitSubscription = null;
    _replyPort?.close();
    _errorPort?.close();
    _exitPort?.close();
    _replyPort = null;
    _errorPort = null;
    _exitPort = null;
    _commandPort = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _initFuture = null;
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(error);
    }
    _pending.clear();
  }

  static void _entryPoint(SendPort initial) {
    final commandPort = ReceivePort();
    initial.send(commandPort.sendPort);

    SendPort? replyPort;
    commandPort.listen((msg) {
      if (msg is SendPort) {
        replyPort = msg;
        return;
      }
      if (msg is _Request && replyPort != null) {
        try {
          final result = _execute(msg.op, msg.args);
          replyPort!.send(_Response(msg.id, result, null));
        } catch (e) {
          replyPort!.send(_Response(msg.id, null, e));
        }
      }
    });
  }

  static dynamic _execute(_Op op, List<dynamic> args) {
    switch (op) {
      case _Op.list:
        return _listDirectory(args[0] as String);
      case _Op.exists:
        return Directory(args[0] as String).existsSync();
      case _Op.isDir:
        return FileSystemEntity.isDirectorySync(args[0] as String);
      case _Op.mkdir:
        Directory(args[0] as String).createSync(recursive: true);
        return null;
      case _Op.delete:
        final path = args[0] as String;
        final recursive = args[1] as bool;
        final type = FileSystemEntity.typeSync(path, followLinks: false);
        if (type == FileSystemEntityType.link) {
          Link(path).deleteSync();
        } else if (type == FileSystemEntityType.directory) {
          Directory(path).deleteSync(recursive: recursive);
        } else if (type == FileSystemEntityType.file) {
          File(path).deleteSync();
        }
        return null;
      case _Op.stat:
        final path = args[0] as String;
        final type = FileSystemEntity.typeSync(path, followLinks: false);
        if (type == FileSystemEntityType.notFound) return null;
        final entity = type == FileSystemEntityType.directory
            ? Directory(path) as FileSystemEntity
            : (type == FileSystemEntityType.link ? Link(path) : File(path));
        return FileEntry.fromFileSystemEntity(entity);
      case _Op.archiveList:
        final archivePath = args[0] as String;
        final innerPath = args[1] as String;
        final modified = FileStat.statSync(archivePath).modified;
        final all = ArchiveReader.listEntries(archivePath);
        final entries = ArchiveService.levelEntries(
          archivePath,
          innerPath,
          all,
          modified,
        );
        entries.sort((a, b) {
          if (a.type != b.type) {
            return a.type == FileItemType.folder ? -1 : 1;
          }
          return a.nameLower.compareTo(b.nameLower);
        });
        return entries;
      case _Op.archiveExtract:
        ArchiveReader.extractEntry(
          args[0] as String,
          args[1] as String,
          args[2] as String,
        );
        return null;
      case _Op.archiveExtractTree:
        return ArchiveReader.extractTree(
          args[0] as String,
          args[1] as String,
          args[2] as String,
        );
    }
  }

  static List<FileEntry> _listDirectory(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      throw FileSystemException('Directory not found', path);
    }

    final entries = <FileEntry>[];
    try {
      for (final e in dir.listSync(followLinks: false)) {
        try {
          final stat = FileStat.statSync(e.path);
          final isDir =
              e is Directory ||
              (e is Link && stat.type == FileSystemEntityType.directory);
          entries.add(
            FileEntry(
              name: PlatformPaths.fileName(e.path),
              path: e.path,
              type: isDir ? FileItemType.folder : FileItemType.file,
              size: stat.size,
              modified: stat.modified,
            ),
          );
        } catch (_) {}
      }
    } catch (e) {
      if (e is FileSystemException) rethrow;
      throw FileSystemException(e.toString(), path);
    }

    entries.sort((a, b) {
      if (a.type != b.type) return a.type == FileItemType.folder ? -1 : 1;
      return a.nameLower.compareTo(b.nameLower);
    });

    return entries;
  }
}
