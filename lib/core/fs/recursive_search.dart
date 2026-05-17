import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import '../models/file_entry.dart';
import 'waydir_core_loader.dart';

class _BatchMsg {
  final List<FileEntry> entries;
  const _BatchMsg(this.entries);
}

class _ProgressMsg {
  final int dirs;
  final String? currentDir;
  const _ProgressMsg(this.dirs, this.currentDir);
}

class _DoneMsg {
  const _DoneMsg();
}

class _StartMsg {
  final String root;
  final String query;
  final bool includeHidden;
  const _StartMsg(this.root, this.query, this.includeHidden);
}

class _CancelMsg {
  const _CancelMsg();
}

const _excludedDirs = {
  '.git',
  'node_modules',
  '.cache',
  '.venv',
  '__pycache__',
  'target',
  'build',
  '.gradle',
  '.idea',
};

class SearchHandle {
  SendPort? _commandPort;
  bool _done = false;

  SearchHandle._();

  void _setCommandPort(SendPort port) => _commandPort = port;

  void cancel() {
    if (_done) return;
    _done = true;
    _commandPort?.send(const _CancelMsg());
  }

  bool get isDone => _done;
}

typedef SearchProgressCallback =
    void Function(int scannedDirs, String? currentDir);

class RecursiveSearch {
  static SearchHandle start({
    required String root,
    required String query,
    required bool includeHidden,
    required void Function(List<FileEntry> batch) onBatch,
    required SearchProgressCallback onProgress,
    required void Function() onDone,
    required void Function(Object error) onError,
  }) {
    final handle = SearchHandle._();
    final receivePort = ReceivePort();
    Isolate? isolate;
    bool startSent = false;

    final sub = receivePort.listen((msg) {
      if (!startSent && msg is SendPort) {
        startSent = true;
        handle._setCommandPort(msg);
        msg.send(_StartMsg(root, query, includeHidden));
        return;
      }
      if (handle._done && msg is! _DoneMsg) return;
      if (msg is _BatchMsg) {
        onBatch(msg.entries);
      } else if (msg is _ProgressMsg) {
        onProgress(msg.dirs, msg.currentDir);
      } else if (msg is _DoneMsg) {
        if (!handle._done) {
          handle._done = true;
          onDone();
        }
        receivePort.close();
        isolate?.kill(priority: Isolate.immediate);
      }
    });

    Isolate.spawn(
          _searchEntryPoint,
          receivePort.sendPort,
          errorsAreFatal: false,
        )
        .then((iso) {
          isolate = iso;
          if (handle._done) {
            iso.kill(priority: Isolate.immediate);
          }
        })
        .catchError((e) {
          sub.cancel();
          receivePort.close();
          onError(e);
        });

    return handle;
  }

  static void _searchEntryPoint(SendPort mainPort) {
    final commandPort = ReceivePort();
    mainPort.send(commandPort.sendPort);

    bool cancelled = false;
    bool started = false;

    commandPort.listen((msg) {
      if (msg is _StartMsg && !started) {
        started = true;
        _runSearchAsync(
          mainPort,
          msg.root,
          msg.query,
          msg.includeHidden,
          () => cancelled,
        ).whenComplete(() {
          commandPort.close();
        });
      } else if (msg is _CancelMsg) {
        cancelled = true;
      }
    });
  }

  static Future<void> _runSearchAsync(
    SendPort mainPort,
    String root,
    String query,
    bool includeHidden,
    bool Function() isCancelled,
  ) async {
    final queryLower = query.toLowerCase();
    final buffer = <FileEntry>[];
    int scannedDirs = 0;
    final clock = Stopwatch()..start();
    var lastFlushMs = 0;
    var lastProgressMs = -1000;
    const batchSize = 200;
    const flushIntervalMs = 200;
    const progressIntervalMs = 150;

    void flush() {
      if (buffer.isEmpty) return;
      mainPort.send(_BatchMsg(List.of(buffer)));
      buffer.clear();
      lastFlushMs = clock.elapsedMilliseconds;
    }

    void maybeFlush() {
      if (buffer.length >= batchSize ||
          clock.elapsedMilliseconds - lastFlushMs >= flushIntervalMs) {
        flush();
      }
    }

    void sendProgress(String? dir, {bool force = false}) {
      final nowMs = clock.elapsedMilliseconds;
      if (!force && nowMs - lastProgressMs < progressIntervalMs) {
        return;
      }
      lastProgressMs = nowMs;
      mainPort.send(_ProgressMsg(scannedDirs, dir));
    }

    // Fast path: the native (Rust) parallel walker. Returns all matches in
    // one buffer; we chunk it back into the same batch protocol the UI
    // already consumes. Falls back to the Dart walker on any failure.
    if (!isCancelled()) {
      final blob = WaydirCoreLoader.search(root, query, includeHidden);
      if (blob != null) {
        final all = FileEntryCodec.decode(blob);
        for (var i = 0; i < all.length; i += batchSize) {
          if (isCancelled()) break;
          final end = (i + batchSize < all.length) ? i + batchSize : all.length;
          mainPort.send(_BatchMsg(all.sublist(i, end)));
          await Future.delayed(Duration.zero);
        }
        sendProgress(null, force: true);
        mainPort.send(const _DoneMsg());
        return;
      }
    }

    FileEntry makeEntry(FileSystemEntity entity, String name, bool isDir) {
      return FileEntry.raw(
        name: name,
        path: entity.path,
        type: isDir ? FileItemType.folder : FileItemType.file,
        size: 0,
        modifiedMs: 0,
      );
    }

    final queue = Queue<String>()..add(root);

    while (queue.isNotEmpty) {
      if (isCancelled()) break;

      final dirPath = queue.removeFirst();
      sendProgress(dirPath);

      List<FileSystemEntity> entities;
      try {
        entities = Directory(dirPath).listSync(followLinks: false);
      } catch (_) {
        scannedDirs++;
        continue;
      }

      for (final entity in entities) {
        if (isCancelled()) break;

        final name = entity.path.split(Platform.pathSeparator).last;
        final isHidden = name.startsWith('.');
        final isDir = entity is Directory;

        if (!includeHidden && isHidden) continue;

        if (isDir) {
          if (_excludedDirs.contains(name)) {
            if (name.toLowerCase().contains(queryLower)) {
              buffer.add(makeEntry(entity, name, true));
              maybeFlush();
            }
            continue;
          }
          queue.add(entity.path);
        }

        if (name.toLowerCase().contains(queryLower)) {
          buffer.add(makeEntry(entity, name, isDir));
          maybeFlush();
        }
      }

      scannedDirs++;
      sendProgress(null);
      maybeFlush();

      await Future.delayed(Duration.zero);
    }

    flush();
    sendProgress(null, force: true);
    mainPort.send(const _DoneMsg());
  }
}
