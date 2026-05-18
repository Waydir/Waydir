import 'dart:async';
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

class _ErrorMsg {
  final String message;
  const _ErrorMsg(this.message);
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
      } else if (msg is _ErrorMsg) {
        if (!handle._done) {
          handle._done = true;
          onError(StateError(msg.message));
        }
        receivePort.close();
        isolate?.kill(priority: Isolate.immediate);
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

  // Recursive search runs exclusively in the native (Rust) parallel walker.
  // There is no Dart fallback by design; a missing native library is a
  // hard error surfaced to the caller.
  static Future<void> _runSearchAsync(
    SendPort mainPort,
    String root,
    String query,
    bool includeHidden,
    bool Function() isCancelled,
  ) async {
    const pollInterval = Duration(milliseconds: 120);
    if (isCancelled()) {
      mainPort.send(const _DoneMsg());
      return;
    }

    final int? session;
    try {
      session = WaydirCoreLoader.searchStart(root, query, includeHidden);
    } catch (e) {
      mainPort.send(_ErrorMsg(e.toString()));
      return;
    }

    if (session == null) {
      mainPort.send(_ProgressMsg(0, null));
      mainPort.send(const _DoneMsg());
      return;
    }

    var lastScanned = -1;
    try {
      while (true) {
        if (isCancelled()) {
          WaydirCoreLoader.searchCancel(session);
        }
        final r = WaydirCoreLoader.searchPoll(session);
        if (r.batch != null) {
          final entries = FileEntryCodec.decode(r.batch!);
          if (entries.isNotEmpty) mainPort.send(_BatchMsg(entries));
        }
        if (r.scanned != lastScanned) {
          lastScanned = r.scanned;
          mainPort.send(_ProgressMsg(r.scanned, null));
        }
        if (r.done || isCancelled()) {
          final f = WaydirCoreLoader.searchPoll(session);
          if (f.batch != null) {
            final entries = FileEntryCodec.decode(f.batch!);
            if (entries.isNotEmpty) mainPort.send(_BatchMsg(entries));
          }
          break;
        }
        await Future.delayed(pollInterval);
      }
    } finally {
      WaydirCoreLoader.searchFree(session);
    }
    mainPort.send(_ProgressMsg(lastScanned < 0 ? 0 : lastScanned, null));
    mainPort.send(const _DoneMsg());
  }
}
