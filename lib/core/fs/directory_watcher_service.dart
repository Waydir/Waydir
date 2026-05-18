import 'dart:async';
import 'dart:io';

import '../logging/app_logger.dart';

/// Coalesced directory-change notifier.
///
/// Dart's [Directory.watch] already wraps the native backend (inotify on
/// Linux, FSEvents on macOS, ReadDirectoryChangesW on Windows). On top of
/// that this service batches a burst of events into a single callback and,
/// crucially, reports *which* child paths changed so the caller can apply an
/// incremental patch instead of re-scanning the whole directory.
///
/// [fullReload] is set when a precise patch is unsafe: move/rename events
/// (the old↔new pairing is ambiguous), watcher errors, or a storm large
/// enough that per-path stats would cost as much as a full relist.
typedef DirectoryChangeCallback =
    void Function(Set<String> changedPaths, bool fullReload);

class DirectoryWatcherService {
  static const _debounce = Duration(milliseconds: 100);
  static const _stormThreshold = 64;

  StreamSubscription<FileSystemEvent>? _subscription;
  Timer? _debounceTimer;
  String? _watchedPath;
  DirectoryChangeCallback? _onChange;

  final Set<String> _pending = {};
  bool _fullReload = false;

  void watch(String path, DirectoryChangeCallback onChange) {
    if (_watchedPath == path && _subscription != null) {
      _onChange = onChange;
      return;
    }
    stop();
    _watchedPath = path;
    _onChange = onChange;
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return;
      _subscription = dir
          .watch(recursive: false)
          .listen(
            (event) {
              if (_watchedPath != path) return;
              _accumulate(event);
              _scheduleNotify();
            },
            onError: (e) {
              if (_watchedPath != path) return;
              log.warn('fs.watcher', 'watch error, full reload', error: e);
              _fullReload = true;
              _scheduleNotify();
            },
            cancelOnError: true,
          );
    } catch (e, s) {
      log.warn('fs.watcher', 'failed to start watch', error: e, stack: s);
    }
  }

  void _accumulate(FileSystemEvent event) {
    if (event is FileSystemMoveEvent) {
      _fullReload = true;
      return;
    }
    _pending.add(event.path);
    if (event.path != _watchedPath) {
      // Some backends report the directory itself; ignore for patching.
    }
    if (_pending.length > _stormThreshold) _fullReload = true;
  }

  void _scheduleNotify() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      final cb = _onChange;
      if (cb == null) return;
      final changed = Set<String>.from(_pending);
      final full = _fullReload || changed.isEmpty;
      _pending.clear();
      _fullReload = false;
      cb(changed, full);
    });
  }

  void stop() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _watchedPath = null;
    _onChange = null;
    _pending.clear();
    _fullReload = false;
  }

  void dispose() => stop();
}
