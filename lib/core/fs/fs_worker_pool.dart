import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import '../archive/archive_reader.dart';
import '../archive/archive_service.dart';
import '../models/file_entry.dart';
import 'waydir_core_loader.dart';

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

class _FsWorker {
  final int slot;
  final Isolate isolate;
  final SendPort commandPort;
  final ReceivePort replyPort;
  final ReceivePort errorPort;
  final ReceivePort exitPort;
  StreamSubscription? replySub;
  StreamSubscription? errorSub;
  StreamSubscription? exitSub;
  final pending = <int, Completer<dynamic>>{};

  _FsWorker({
    required this.slot,
    required this.isolate,
    required this.commandPort,
    required this.replyPort,
    required this.errorPort,
    required this.exitPort,
  });

  void shutdown(Object error) {
    replySub?.cancel();
    errorSub?.cancel();
    exitSub?.cancel();
    replyPort.close();
    errorPort.close();
    exitPort.close();
    isolate.kill(priority: Isolate.immediate);
    for (final c in pending.values) {
      if (!c.isCompleted) c.completeError(error);
    }
    pending.clear();
  }
}

class FsWorkerPool {
  static final FsWorkerPool instance = FsWorkerPool._();
  FsWorkerPool._();

  static final int _poolSize = () {
    final n = Platform.numberOfProcessors ~/ 2;
    return n < 2 ? 2 : (n > 8 ? 8 : n);
  }();

  final List<_FsWorker?> _workers = List.filled(_poolSize, null);
  final List<Future<_FsWorker>?> _spawning = List.filled(_poolSize, null);
  int _nextId = 0;
  int _rr = 0;

  Future<void> ensureStarted() async {
    await Future.wait([for (var i = 0; i < _poolSize; i++) _ensureWorker(i)]);
  }

  Future<_FsWorker> _ensureWorker(int slot) {
    final live = _workers[slot];
    if (live != null) return Future.value(live);
    final inFlight = _spawning[slot];
    if (inFlight != null) return inFlight;
    final fut = _spawnWorker(slot);
    _spawning[slot] = fut;
    return fut
        .then((w) {
          _workers[slot] = w;
          _spawning[slot] = null;
          return w;
        })
        .catchError((e) {
          _spawning[slot] = null;
          throw e;
        });
  }

  Future<_FsWorker> _spawnWorker(int slot) async {
    final ready = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final workerReady = Completer<SendPort>();

    late StreamSubscription readySub;
    readySub = ready.listen((msg) {
      if (msg is SendPort && !workerReady.isCompleted) {
        workerReady.complete(msg);
        readySub.cancel();
        ready.close();
      }
    });

    Isolate isolate;
    try {
      isolate = await Isolate.spawn<SendPort>(
        _entryPoint,
        ready.sendPort,
        errorsAreFatal: false,
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
      );
    } catch (_) {
      await readySub.cancel();
      ready.close();
      errorPort.close();
      exitPort.close();
      rethrow;
    }

    final commandPort = await workerReady.future;
    final replyPort = ReceivePort();
    commandPort.send(replyPort.sendPort);

    final worker = _FsWorker(
      slot: slot,
      isolate: isolate,
      commandPort: commandPort,
      replyPort: replyPort,
      errorPort: errorPort,
      exitPort: exitPort,
    );

    worker.replySub = replyPort.listen((msg) {
      if (msg is _Response) {
        final completer = worker.pending.remove(msg.id);
        if (completer == null) return;
        if (msg.error != null) {
          completer.completeError(msg.error!);
        } else {
          completer.complete(msg.result);
        }
      }
    });
    worker.errorSub = errorPort.listen(
      (err) => _handleWorkerFailure(slot, StateError('FS worker failed: $err')),
    );
    worker.exitSub = exitPort.listen(
      (_) => _handleWorkerFailure(slot, StateError('FS worker exited')),
    );
    return worker;
  }

  Future<T> _run<T>(_Op op, List<dynamic> args) async {
    final slot = _rr;
    _rr = (_rr + 1) % _poolSize;
    final worker = await _ensureWorker(slot);
    final id = _nextId++;
    final completer = Completer<dynamic>();
    worker.pending[id] = completer;
    worker.commandPort.send(_Request(id, op, args));
    final result = await completer.future;
    return result as T;
  }

  Future<List<FileEntry>> listDirectory(String path) async {
    final r = await _run<dynamic>(_Op.list, [path]);
    if (r is Uint8List) return FileEntryCodec.decode(r);
    return r as List<FileEntry>;
  }

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
    for (var i = 0; i < _poolSize; i++) {
      _workers[i]?.shutdown(StateError('Pool disposed'));
      _workers[i] = null;
      _spawning[i] = null;
    }
  }

  void _handleWorkerFailure(int slot, Object error) {
    final worker = _workers[slot];
    if (worker == null) return;
    _workers[slot] = null;
    _spawning[slot] = null;
    worker.shutdown(error);
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
        final path = args[0] as String;
        // Directory listing is native-only (Rust). No Dart fallback.
        final native = WaydirCoreLoader.listDir(path);
        if (native == null) {
          throw FileSystemException('Directory not readable', path);
        }
        if (FileEntryCodec.countOf(native) >= FileEntryCodec.threshold) {
          return native;
        }
        return FileEntryCodec.decode(native);
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
}
