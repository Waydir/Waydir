import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:signals/signals.dart';

import '../../core/fs/file_system_service.dart';
import '../../core/fs/waydir_core_loader.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../ui/theme/app_theme.dart';
import '../files/row_decorations.dart';
import '../navigation/navigation_store.dart';
import '../operations/operation_store.dart';
import '../panes/pane_store.dart';
import 'compare_diff.dart';

class CompareController {
  final Signal<List<PaneStore>> panes;
  final Signal<bool> isDual;
  final OperationStore operationStore;

  final active = signal(false);
  final running = signal(false);
  final recursive = signal(true);
  final leftResults = signal<Map<String, CompareEntryResult>>({});
  final rightResults = signal<Map<String, CompareEntryResult>>({});
  final counts = signal(const CompareCounts());

  int _runId = 0;
  void Function()? _taskDisposer;
  void Function()? _scopeDisposer;
  String? _leftRoot;
  String? _rightRoot;
  NavigationStore? _leftDecorated;
  NavigationStore? _rightDecorated;

  CompareController({
    required this.panes,
    required this.isDual,
    required this.operationStore,
  }) {
    _taskDisposer = effect(() {
      final completed = operationStore.taskCompleted.value;
      if (completed == null || !active.value) return;
      scheduleMicrotask(start);
    });
    _scopeDisposer = effect(() {
      if (!active.value) return;
      final pair = _activeStores();
      final leftRoot = _leftRoot;
      final rightRoot = _rightRoot;
      if (pair == null || leftRoot == null || rightRoot == null) {
        scheduleMicrotask(stop);

        return;
      }
      final leftPath = pair.$1.currentPath.value;
      final rightPath = pair.$2.currentPath.value;
      if (!_withinScope(leftRoot, leftPath) ||
          !_withinScope(rightRoot, rightPath)) {
        scheduleMicrotask(stop);
      }
    });
  }

  bool _withinScope(String root, String path) {
    if (path == root) return true;
    if (!recursive.value) return false;

    return p.isWithin(root, path);
  }

  bool get canStart {
    final pair = _activeStores();
    if (pair == null) return false;

    return _isLocalFolder(pair.$1.currentPath.value) &&
        _isLocalFolder(pair.$2.currentPath.value);
  }

  Future<void> toggle() async {
    if (active.value) {
      stop();
    } else {
      await start();
    }
  }

  Future<void> start() async {
    if (!canStart) return;
    final pair = _activeStores();
    if (pair == null) return;
    final run = ++_runId;
    final leftStore = pair.$1;
    final rightStore = pair.$2;
    final leftRoot = leftStore.currentPath.value;
    final rightRoot = rightStore.currentPath.value;
    _leftRoot = leftRoot;
    _rightRoot = rightRoot;
    running.value = true;
    active.value = true;
    final recursive = this.recursive.value;
    try {
      final listed = await Future.wait([
        _entriesFor(leftRoot, run, recursive),
        _entriesFor(rightRoot, run, recursive),
      ]);
      if (run != _runId) return;
      final diff = buildCompareDiff(
        leftRoot: leftRoot,
        rightRoot: rightRoot,
        leftEntries: listed[0],
        rightEntries: listed[1],
      );
      leftResults.value = diff.left;
      rightResults.value = diff.right;
      counts.value = diff.counts;
      _clearDecorations();
      _leftDecorated = leftStore;
      _rightDecorated = rightStore;
      leftStore.decorations.setLayer('compare', _decorationsFor(diff.left));
      rightStore.decorations.setLayer('compare', _decorationsFor(diff.right));
    } finally {
      if (run == _runId) running.value = false;
    }
  }

  Future<void> syncLeftToRight() => _sync(leftToRight: true);

  Future<void> syncRightToLeft() => _sync(leftToRight: false);

  Future<void> setRecursive(bool value) async {
    if (recursive.value == value) return;
    recursive.value = value;
    if (active.value) await start();
  }

  void stop() {
    _runId++;
    running.value = false;
    active.value = false;
    leftResults.value = const {};
    rightResults.value = const {};
    counts.value = const CompareCounts();
    _leftRoot = null;
    _rightRoot = null;
    _clearDecorations();
  }

  void _clearDecorations() {
    _leftDecorated?.decorations.clearLayer('compare');
    _rightDecorated?.decorations.clearLayer('compare');
    _leftDecorated = null;
    _rightDecorated = null;
  }

  void dispose() {
    _taskDisposer?.call();
    _taskDisposer = null;
    _scopeDisposer?.call();
    _scopeDisposer = null;
    stop();
    active.dispose();
    running.dispose();
    recursive.dispose();
    leftResults.dispose();
    rightResults.dispose();
    counts.dispose();
  }

  (NavigationStore, NavigationStore)? _activeStores() {
    if (!isDual.value) return null;
    final list = panes.value;
    if (list.length < 2) return null;

    return (
      list[0].tabs.activeTab.value.store,
      list[1].tabs.activeTab.value.store,
    );
  }

  bool _isLocalFolder(String path) {
    if (path.isEmpty) return false;
    if (PlatformPaths.isRemoteUri(path) || PlatformPaths.isNetworkPath(path)) {
      return false;
    }
    try {
      return Directory(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<List<FileEntry>> _entriesFor(
    String root,
    int run,
    bool recursive,
  ) async {
    if (!recursive) return FileSystemService.listDirectory(root);

    final native = await Isolate.run(() {
      try {
        final blob = WaydirCoreLoader.enumerate(root, postorder: false);
        if (blob == null) return null;

        return FileEntryCodec.decode(blob);
      } catch (_) {
        return null;
      }
    });
    if (native != null) return native;

    final out = <FileEntry>[];
    final pending = <String>[root];
    final visited = <String>{root};
    while (pending.isNotEmpty) {
      if (run != _runId) return const [];
      final dir = pending.removeLast();
      final entries = await FileSystemService.listDirectory(dir);
      for (final entry in entries) {
        out.add(entry);
        if (entry.type == FileItemType.folder && visited.add(entry.path)) {
          pending.add(entry.path);
        }
      }
    }

    return out;
  }

  Map<String, RowDecoration> _decorationsFor(
    Map<String, CompareEntryResult> results,
  ) {
    final out = <String, RowDecoration>{};
    for (final entry in results.values) {
      final decoration = _decorationFor(entry.status);
      if (decoration == null) continue;
      out[entry.path] = decoration;
    }

    return out;
  }

  Future<void> _sync({required bool leftToRight}) async {
    if (!active.value) return;
    final pair = _activeStores();
    if (pair == null) return;
    final sourceStore = leftToRight ? pair.$1 : pair.$2;
    final destinationStore = leftToRight ? pair.$2 : pair.$1;
    final sourceResults = leftToRight ? leftResults.value : rightResults.value;
    final destinationRoot = destinationStore.currentPath.value;
    final selected = sourceStore.selectedPaths.value;
    final selectedRel = <String>{};
    for (final path in selected) {
      final result = sourceResults[path];
      if (result != null) selectedRel.add(result.relativePath);
    }
    final candidates = sourceResults.values.where((result) {
      if (!_shouldSync(result)) return false;
      if (selectedRel.isEmpty) return true;

      return selectedRel.any(
        (rel) =>
            result.relativePath == rel ||
            result.relativePath.startsWith('$rel/'),
      );
    }).toList()..sort((a, b) => a.relativePath.compareTo(b.relativePath));
    final filtered = <CompareEntryResult>[];
    for (final candidate in candidates) {
      final nested = filtered.any(
        (existing) =>
            existing.type == FileItemType.folder &&
            candidate.relativePath.startsWith('${existing.relativePath}/'),
      );
      if (!nested) filtered.add(candidate);
    }
    final grouped = <String, List<String>>{};
    for (final entry in filtered) {
      final destination = destinationDirectoryFor(
        destinationRoot,
        entry.relativePath,
      );
      await FileSystemService.createDirectory(destination);
      (grouped[destination] ??= <String>[]).add(entry.path);
    }
    for (final group in grouped.entries) {
      operationStore.enqueueCopy(group.value, group.key);
    }
  }

  bool _shouldSync(CompareEntryResult result) {
    return switch (result.status) {
      CompareStatus.unique => true,
      CompareStatus.newer => result.type == FileItemType.file,
      CompareStatus.differ => result.type == FileItemType.file,
      CompareStatus.older || CompareStatus.identical => false,
    };
  }

  RowDecoration? _decorationFor(CompareStatus status) {
    return switch (status) {
      CompareStatus.unique => RowDecoration(
        tint: AppColors.compareUnique,
        badge: '+',
      ),
      CompareStatus.newer => RowDecoration(
        tint: AppColors.compareNewer,
        badge: '↑',
      ),
      CompareStatus.older => RowDecoration(
        tint: AppColors.compareOlder,
        badge: '↓',
      ),
      CompareStatus.differ => RowDecoration(
        tint: AppColors.compareDiffer,
        badge: '≠',
      ),
      CompareStatus.identical => null,
    };
  }

  String destinationDirectoryFor(String destinationRoot, String relativePath) {
    final dir = p.posix.dirname(relativePath);
    if (dir == '.') return destinationRoot;

    return p.joinAll([destinationRoot, ...dir.split('/')]);
  }
}
