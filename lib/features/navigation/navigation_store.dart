import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:signals/signals.dart';
import '../../core/archive/archive_path.dart';
import '../../core/archive/archive_reader.dart';
import '../../core/models/file_entry.dart';
import '../../core/clipboard/file_clipboard.dart';
import '../../core/fs/file_sort.dart';
import '../../core/fs/file_system_service.dart';
import '../../core/fs/fs_worker_pool.dart';
import '../../core/fs/directory_watcher_service.dart';
import '../../core/fs/recursive_search.dart';
import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';
import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../git/git_status_store.dart';
import '../operations/operation_store.dart';

enum ClipboardMode { copy, cut }

const String kPendingCreatePath = '__pending_create__';

class NavigationStore {
  final currentPath = signal('');
  final files = signal<List<FileEntry>>([]);
  final showHidden = signal(false);
  final selectedPaths = signal<Set<String>>({});
  final cursorIndex = signal(-1);
  final anchorIndex = signal(-1);
  final history = signal<List<String>>([]);
  final historyIndex = signal(0);
  final isLoading = signal(false);
  final clipboardPaths = signal<Set<String>>({});
  final clipboardMode = signal<ClipboardMode?>(null);
  final OperationStore operationStore;
  final gitStatus = GitStatusStore();
  final loadError = signal<String?>(null);
  final renamingPath = signal<String?>(null);
  final renameError = signal<String?>(null);
  final pendingCreate = signal<FileEntry?>(null);
  final _trashEntries = <String, TrashEntry>{};
  int _loadToken = 0;

  /// Effective sort for the current folder (per-folder, falls back to the
  /// global defaults in [SettingsStore]).
  final sortKey = signal<SortKey>(SortKey.name);
  final sortAscending = signal<bool>(true);
  final foldersFirst = signal<bool>(true);
  int _sortLoadToken = 0;
  void Function()? _sortDefaultsDisposer;
  void Function()? _gitStatusDisposer;

  bool get isTrashView => isTrashPath(currentPath.value);
  bool get isTrashRoot => currentPath.value == kTrashPath;
  final DirectoryWatcherService _watcher = DirectoryWatcherService();

  final searchActive = signal(false);
  final searchQuery = signal('');
  final searchRecursive = signal(false);
  final searchResults = signal<List<FileEntry>>([]);
  final isSearching = signal(false);
  final searchScannedDirs = signal(0);
  final searchTruncated = signal(false);
  final searchCurrentDir = signal<String?>(null);
  final searchFocusRequest = signal(0);
  final renameAttempt = signal(0);

  SearchHandle? _searchHandle;
  Timer? _searchDebounce;
  Timer? _searchUiFlush;
  void Function()? _showHiddenDisposer;
  List<FileEntry>? _pendingSearchResults;
  static const _kSearchLimit = 5000;
  static const _kSearchUiFlushMs = 250;

  late final canGoBack = computed(() => historyIndex.value > 0);
  late final canGoForward = computed(
    () => historyIndex.value < history.value.length - 1,
  );
  late final visibleFiles = computed(() {
    final pending = pendingCreate.value;
    if (searchActive.value && searchRecursive.value) {
      return pending != null
          ? [pending, ...searchResults.value]
          : searchResults.value;
    }
    var list = showHidden.value
        ? files.value
        : files.value.where((f) => !f.isHidden).toList();
    final q = searchQuery.value.trim().toLowerCase();
    if (searchActive.value && q.isNotEmpty) {
      list = list.where((f) => f.name.toLowerCase().contains(q)).toList();
    }
    list = sortEntries(
      list,
      key: sortKey.value,
      ascending: sortAscending.value,
      foldersFirst: foldersFirst.value,
    );
    return pending != null ? [pending, ...list] : list;
  });
  late final folderCount = computed(
    () => visibleFiles.value.where((f) => f.type == FileItemType.folder).length,
  );
  late final fileCount = computed(
    () => visibleFiles.value.where((f) => f.type == FileItemType.file).length,
  );
  late final totalItems = computed(() => visibleFiles.value.length);
  late final cursorEntry = computed<FileEntry?>(() {
    final files = visibleFiles.value;
    final idx = cursorIndex.value;
    if (idx >= 0 && idx < files.length) return files[idx];
    final sel = selectedPaths.value;
    if (sel.length == 1) {
      for (final f in files) {
        if (f.path == sel.first) return f;
      }
    }
    return null;
  });
  late final selectedCount = computed(() => selectedPaths.value.length);
  late final canPaste = computed(
    () => clipboardPaths.value.isNotEmpty && clipboardMode.value != null,
  );

  NavigationStore({required this.operationStore, String? initialPath}) {
    final startPath = initialPath ?? PlatformPaths.homePath;
    currentPath.value = startPath;
    history.value = [startPath];
    showHidden.value = SettingsStore.instance.showHiddenDefault.value;
    _loadSortFor(startPath);
    loadDirectory(startPath);
    _setupShowHiddenEffect();
    _setupSortDefaultsEffect();
    _setupGitStatusEffect();
  }

  void _setupGitStatusEffect() {
    _gitStatusDisposer = effect(() {
      gitStatus.watchPath(currentPath.value);
    });
  }

  void _setupSortDefaultsEffect() {
    var first = true;
    _sortDefaultsDisposer = effect(() {
      final s = SettingsStore.instance;
      // Track the global sort defaults.
      s.sortKey.value;
      s.sortAscending.value;
      s.foldersFirst.value;
      if (first) {
        first = false;
        return;
      }
      // Defaults changed in Preferences: reapply for the current folder
      // (only matters when it has no stored per-folder override).
      _loadSortFor(currentPath.value);
    });
  }

  void _applySort(SortKey key, bool ascending, bool foldersFirstValue) {
    batch(() {
      sortKey.value = key;
      sortAscending.value = ascending;
      foldersFirst.value = foldersFirstValue;
    });
  }

  Future<void> _loadSortFor(String path) async {
    final token = ++_sortLoadToken;
    final s = SettingsStore.instance;
    _applySort(
      sortKeyFromString(s.sortKey.value),
      s.sortAscending.value,
      s.foldersFirst.value,
    );
    try {
      final pref = await s.db.getFolderPref(path);
      if (token != _sortLoadToken) return;
      if (pref != null) {
        _applySort(
          sortKeyFromString(pref.sortKey),
          pref.sortAscending,
          pref.foldersFirst,
        );
      }
    } catch (_) {}
  }

  void _persistSort() {
    final path = currentPath.value;
    if (path.isEmpty) return;
    SettingsStore.instance.db
        .setFolderPref(
          path,
          sortKey: sortKeyToString(sortKey.value),
          sortAscending: sortAscending.value,
          foldersFirst: foldersFirst.value,
        )
        .catchError((_) {});
  }

  /// Toggles direction when [key] is already active, otherwise switches to
  /// [key] ascending. Persists the choice for the current folder.
  void cycleSortColumn(SortKey key) {
    batch(() {
      if (sortKey.value == key) {
        sortAscending.value = !sortAscending.value;
      } else {
        sortKey.value = key;
        sortAscending.value = true;
      }
    });
    _persistSort();
  }

  void _setupShowHiddenEffect() {
    _showHiddenDisposer = effect(() {
      showHidden.value;
      if (searchActive.value && searchRecursive.value) {
        _restartRecursiveSearch();
      }
    });
  }

  void openSearch({bool recursive = false}) {
    batch(() {
      searchActive.value = true;
      if (recursive) searchRecursive.value = true;
      searchFocusRequest.value = searchFocusRequest.value + 1;
    });
  }

  void closeSearch() {
    _searchDebounce?.cancel();
    _searchUiFlush?.cancel();
    _searchUiFlush = null;
    _pendingSearchResults = null;
    _searchHandle?.cancel();
    _searchHandle = null;
    batch(() {
      searchActive.value = false;
      searchRecursive.value = false;
      searchQuery.value = '';
      searchResults.value = [];
      isSearching.value = false;
      searchScannedDirs.value = 0;
      searchTruncated.value = false;
      searchCurrentDir.value = null;
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
  }

  void setSearchQuery(String q) {
    batch(() {
      searchQuery.value = q;
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    _scheduleSearchRestart();
  }

  void toggleRecursive() {
    searchRecursive.value = !searchRecursive.value;
    _scheduleSearchRestart();
  }

  void _scheduleSearchRestart() {
    _searchDebounce?.cancel();
    if (searchRecursive.value) {
      _searchDebounce = Timer(
        const Duration(milliseconds: 250),
        _restartRecursiveSearch,
      );
      return;
    }
    _restartRecursiveSearch();
  }

  void _restartRecursiveSearch() {
    _searchHandle?.cancel();
    _searchHandle = null;
    _searchUiFlush?.cancel();
    _searchUiFlush = null;
    _pendingSearchResults = null;
    batch(() {
      searchResults.value = [];
      searchScannedDirs.value = 0;
      searchTruncated.value = false;
      searchCurrentDir.value = null;
      isSearching.value = false;
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    if (!searchActive.value || !searchRecursive.value) return;
    final q = searchQuery.value.trim();
    if (q.isEmpty) return;
    isSearching.value = true;
    final acc = <FileEntry>[];
    _searchHandle = RecursiveSearch.start(
      root: currentPath.value,
      query: q,
      includeHidden: showHidden.value,
      onBatch: (b) {
        acc.addAll(b);
        if (acc.length >= _kSearchLimit) {
          _searchUiFlush?.cancel();
          _searchUiFlush = null;
          _pendingSearchResults = null;
          batch(() {
            searchTruncated.value = true;
            searchResults.value = List.of(acc.take(_kSearchLimit));
            isSearching.value = false;
          });
          _searchHandle?.cancel();
          return;
        }
        _pendingSearchResults = acc;
        _scheduleSearchUiFlush();
      },
      onProgress: (n, currentDir) {
        batch(() {
          searchScannedDirs.value = n;
          if (currentDir != null) {
            searchCurrentDir.value = currentDir;
          }
        });
      },
      onDone: () {
        _searchUiFlush?.cancel();
        _searchUiFlush = null;
        if (_pendingSearchResults != null) {
          searchResults.value = List.of(_pendingSearchResults!);
          _pendingSearchResults = null;
        }
        batch(() {
          isSearching.value = false;
          searchCurrentDir.value = null;
        });
      },
      onError: (_) {
        _searchUiFlush?.cancel();
        _searchUiFlush = null;
        _pendingSearchResults = null;
        batch(() {
          isSearching.value = false;
          searchCurrentDir.value = null;
        });
      },
    );
  }

  void _scheduleSearchUiFlush() {
    if (_searchUiFlush?.isActive ?? false) return;
    _searchUiFlush = Timer(const Duration(milliseconds: _kSearchUiFlushMs), () {
      _searchUiFlush = null;
      final pending = _pendingSearchResults;
      if (pending == null) return;
      _pendingSearchResults = null;
      searchResults.value = List.of(pending);
    });
  }

  void navigateTo(String path, {bool addToHistory = true}) {
    final normalized = isTrashPath(path) ? path : PlatformPaths.normalize(path);
    closeSearch();
    if (addToHistory) {
      history.value = history.value.sublist(0, historyIndex.value + 1)
        ..add(normalized);
      historyIndex.value = history.value.length - 1;
    }
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
      currentPath.value = normalized;
    });
    _loadSortFor(normalized);
    loadDirectory(normalized);
  }

  void goBack() {
    if (!canGoBack.value) return;
    historyIndex.value--;
    navigateTo(history.value[historyIndex.value], addToHistory: false);
  }

  void goForward() {
    if (!canGoForward.value) return;
    historyIndex.value++;
    navigateTo(history.value[historyIndex.value], addToHistory: false);
  }

  void goUp() async {
    if (isTrashView) {
      if (isTrashRoot) return;
      navigateTo(trashParentOf(currentPath.value));
      return;
    }
    final parent = PlatformPaths.parentOf(currentPath.value);
    if (parent != currentPath.value &&
        await FileSystemService.isNavigable(parent)) {
      navigateTo(parent);
    }
  }

  Future<void> refresh() => loadDirectory(currentPath.value);

  Future<void> loadDirectory(String path) async {
    final token = ++_loadToken;
    isLoading.value = true;
    try {
      final entries = isTrashPath(path)
          ? await _loadTrash(path)
          : await FileSystemService.listDirectory(path);
      if (token != _loadToken) return;
      batch(() {
        files.value = entries;
        loadError.value = null;
        isLoading.value = false;
      });
      if (isTrashPath(path)) {
        _watcher.stop();
      } else {
        _watcher.watch(
          path,
          (changed, fullReload) => _onWatcherEvent(path, changed, fullReload),
        );
        // Covers manual refresh of the same dir (currentPath unchanged, so
        // the git effect wouldn't re-run on its own).
        gitStatus.watchPath(path);
      }
    } catch (e) {
      if (token != _loadToken) return;
      batch(() {
        files.value = [];
        loadError.value = switch (e) {
          ArchiveUnavailableException() => t.errors.archiveUnavailable,
          ArchiveReadException() => t.errors.archiveError,
          FileSystemException(:final message) =>
            message.isNotEmpty ? message : e.toString(),
          _ => e.toString(),
        };
        isLoading.value = false;
      });
      _watcher.stop();
    }
  }

  Future<List<FileEntry>> _loadTrash(String path) async {
    if (path == kTrashPath) {
      final entries = await TrashRepository.instance.listRoot();
      _trashEntries.clear();
      final out = <FileEntry>[];
      for (final e in entries) {
        _trashEntries[e.virtualPath] = e;
        out.add(
          FileEntry(
            name: e.displayName,
            path: e.virtualPath,
            realPath: e.realDataPath,
            type: e.isDirectory ? FileItemType.folder : FileItemType.file,
            size: e.size,
            modified: e.deletedAt,
          ),
        );
      }
      return out;
    }
    final children = await TrashRepository.instance.listSub(path);
    return [
      for (final c in children)
        FileEntry(
          name: c.displayName,
          path: c.virtualPath,
          realPath: c.realPath,
          type: c.isDirectory ? FileItemType.folder : FileItemType.file,
          size: c.size,
          modified: c.modified,
        ),
    ];
  }

  bool get canRestoreFromTrash => TrashRepository.instance.canRestore;

  Future<void> restoreSelectedFromTrash() =>
      _applyToSelectedTrashEntries(TrashRepository.instance.restore);

  Future<void> deletePermanentlySelectedFromTrash() =>
      _applyToSelectedTrashEntries(TrashRepository.instance.deletePermanently);

  Future<void> _applyToSelectedTrashEntries(
    Future<void> Function(TrashEntry) op,
  ) async {
    if (!isTrashView) return;
    for (final p in selectedPaths.value.toList()) {
      final e = _trashEntries[p];
      if (e == null) continue;
      try {
        await op(e);
      } catch (_) {}
    }
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    refresh();
  }

  void _onWatcherEvent(
    String path,
    Set<String> changed,
    bool fullReload,
  ) async {
    if (path != currentPath.value) return;
    // Working-tree changed under the watched dir — refresh git too
    // (debounced inside the store).
    gitStatus.watchPath(path);
    if (fullReload) {
      _onExternalChange(path);
      return;
    }
    try {
      final patched = List<FileEntry>.of(files.value);
      final byPath = {
        for (var i = 0; i < patched.length; i++) patched[i].path: i,
      };
      var mutated = false;
      for (final childPath in changed) {
        if (childPath == path) continue;
        final entry = await FsWorkerPool.instance.stat(childPath);
        if (path != currentPath.value) return;
        final existingIdx = byPath[childPath];
        if (entry == null) {
          if (existingIdx != null) {
            patched[existingIdx] = _kTombstone;
            mutated = true;
          }
        } else if (existingIdx != null) {
          patched[existingIdx] = entry;
          mutated = true;
        } else {
          patched.add(entry);
          mutated = true;
        }
      }
      if (!mutated) return;
      patched.removeWhere(identical0);
      _applyExternalChanges(sortCurrent(patched));
    } catch (_) {
      _onExternalChange(path);
    }
  }

  static final FileEntry _kTombstone = FileEntry.raw(
    name: '',
    path: 'waydir-tombstone-sentinel',
    type: FileItemType.file,
    size: 0,
    modifiedMs: 0,
  );

  static bool identical0(FileEntry e) => identical(e, _kTombstone);

  List<FileEntry> sortCurrent(List<FileEntry> entries) => sortEntries(
    entries,
    key: sortKey.value,
    ascending: sortAscending.value,
    foldersFirst: foldersFirst.value,
  );

  void _onExternalChange(String path) async {
    if (path != currentPath.value) return;
    try {
      final entries = await FileSystemService.listDirectory(path);
      if (path != currentPath.value) return;
      _applyExternalChanges(entries);
    } catch (_) {}
  }

  void _applyExternalChanges(List<FileEntry> newEntries) {
    final newPaths = newEntries.map((e) => e.path).toSet();
    final filteredSelected = selectedPaths.value
        .where(newPaths.contains)
        .toSet();

    final visible = showHidden.value
        ? newEntries
        : newEntries.where((f) => !f.isHidden).toList();

    int newCursor = -1;
    if (cursorIndex.value >= 0 && cursorIndex.value < _vf.length) {
      final cursorPath = _vf[cursorIndex.value].path;
      newCursor = visible.indexWhere((e) => e.path == cursorPath);
    }
    int newAnchor = -1;
    if (anchorIndex.value >= 0 && anchorIndex.value < _vf.length) {
      final anchorPath = _vf[anchorIndex.value].path;
      newAnchor = visible.indexWhere((e) => e.path == anchorPath);
    }

    batch(() {
      files.value = newEntries;
      selectedPaths.value = filteredSelected;
      cursorIndex.value = newCursor;
      anchorIndex.value = newAnchor;
    });
  }

  void startRename() {
    if (isTrashView) return;
    final entries = selectedEntries;
    if (entries.length != 1) return;
    renamingPath.value = entries.first.path;
  }

  void startCreate({FileItemType type = FileItemType.folder}) {
    if (isTrashView) return;
    batch(() {
      pendingCreate.value = FileEntry(
        name: '',
        path: kPendingCreatePath,
        type: type,
        size: 0,
        modified: DateTime.now(),
      );
      renamingPath.value = kPendingCreatePath;
      renameError.value = null;
    });
  }

  void cancelRename() {
    batch(() {
      renamingPath.value = null;
      renameError.value = null;
      pendingCreate.value = null;
    });
  }

  void commitRename(String newName) async {
    final oldPath = renamingPath.value;
    if (oldPath == null) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      cancelRename();
      return;
    }

    if (oldPath == kPendingCreatePath) {
      _commitCreate(trimmed);
      return;
    }

    final renameLoc = ArchivePath.resolve(oldPath);
    if (renameLoc != null && !renameLoc.isRoot) {
      operationStore.enqueueArchiveEdit(
        archivePath: renameLoc.archivePath,
        displayDir: currentPath.value,
        renameFromInner: renameLoc.innerPath,
        renameToName: trimmed,
      );
      batch(() {
        renamingPath.value = null;
        renameError.value = null;
      });
      return;
    }

    final result = FileSystemService.rename(oldPath, trimmed);

    switch (result) {
      case RenameSuccess(:final newPath):
        batch(() {
          renamingPath.value = null;
          renameError.value = null;
          selectedPaths.value = {newPath};
        });
        if (searchActive.value && searchRecursive.value) {
          final updated = searchResults.value.map((e) {
            if (e.path != oldPath) return e;
            return FileEntry(
              name: PlatformPaths.fileName(newPath),
              path: newPath,
              type: e.type,
              size: e.size,
              modified: e.modified,
            );
          }).toList();
          searchResults.value = updated;
          final idx = updated.indexWhere((f) => f.path == newPath);
          if (idx >= 0) {
            batch(() {
              cursorIndex.value = idx;
              anchorIndex.value = idx;
            });
          }
        } else {
          await refresh();
          final idx = _vf.indexWhere((f) => f.path == newPath);
          if (idx >= 0) {
            batch(() {
              cursorIndex.value = idx;
              anchorIndex.value = idx;
            });
          }
        }
      case RenameAlreadyExists():
        renameError.value = t.toast.renameAlreadyExists(name: trimmed);
        renameAttempt.value = renameAttempt.value + 1;
      case RenameError(:final message):
        renameError.value = t.toast.renameError(message: message);
        renameAttempt.value = renameAttempt.value + 1;
      case RenameInvalidName():
        renameError.value = t.toast.renameInvalidName;
        renameAttempt.value = renameAttempt.value + 1;
      case RenameNoChange():
        batch(() {
          renamingPath.value = null;
          renameError.value = null;
        });
    }
  }

  Future<void> _commitCreate(String name) async {
    final pending = pendingCreate.value;
    if (pending == null) return;
    if (!PlatformPaths.isValidFileName(name)) {
      renameError.value = t.toast.renameInvalidName;
      renameAttempt.value = renameAttempt.value + 1;
      return;
    }
    final dir = currentPath.value;
    final newPath = PlatformPaths.join(dir, name);
    if (FileSystemEntity.typeSync(newPath) != FileSystemEntityType.notFound) {
      renameError.value = t.toast.renameAlreadyExists(name: name);
      renameAttempt.value = renameAttempt.value + 1;
      return;
    }
    try {
      await FileSystemService.createDirectory(newPath);
    } catch (e) {
      renameError.value = t.toast.renameError(message: e.toString());
      renameAttempt.value = renameAttempt.value + 1;
      return;
    }
    batch(() {
      pendingCreate.value = null;
      renamingPath.value = null;
      renameError.value = null;
    });
    await refresh();
    final idx = _vf.indexWhere((f) => f.path == newPath);
    if (idx >= 0) {
      batch(() {
        selectedPaths.value = {newPath};
        cursorIndex.value = idx;
        anchorIndex.value = idx;
      });
    }
  }

  void dispose() {
    _showHiddenDisposer?.call();
    _showHiddenDisposer = null;
    _sortDefaultsDisposer?.call();
    _sortDefaultsDisposer = null;
    _gitStatusDisposer?.call();
    _gitStatusDisposer = null;
    gitStatus.dispose();
    _searchDebounce?.cancel();
    _searchUiFlush?.cancel();
    _searchHandle?.cancel();
    _watcher.dispose();
  }

  List<FileEntry> get _vf => visibleFiles.value;

  void onSelect(FileSelectionEvent event) {
    final ctrl = AppShortcuts.isControl;
    final shift = AppShortcuts.isShift;

    batch(() {
      if (ctrl && !shift) {
        final paths = Set<String>.from(selectedPaths.value);
        if (paths.contains(event.entry.path)) {
          paths.remove(event.entry.path);
          if (paths.isNotEmpty) {
            final lastSelected = _vf.lastWhere(
              (f) => paths.contains(f.path),
              orElse: () => event.entry,
            );
            anchorIndex.value = _vf.indexOf(lastSelected);
          } else {
            anchorIndex.value = -1;
          }
        } else {
          paths.add(event.entry.path);
          anchorIndex.value = event.index;
        }
        selectedPaths.value = paths;
        cursorIndex.value = event.index;
      } else if (shift && !ctrl) {
        int start;
        if (anchorIndex.value >= 0 &&
            anchorIndex.value < _vf.length &&
            selectedPaths.value.contains(_vf[anchorIndex.value].path)) {
          start = anchorIndex.value;
        } else if (cursorIndex.value >= 0 &&
            cursorIndex.value < _vf.length &&
            selectedPaths.value.contains(_vf[cursorIndex.value].path)) {
          start = cursorIndex.value;
          anchorIndex.value = start;
        } else {
          start = event.index;
          anchorIndex.value = event.index;
        }
        final end = event.index;
        final lo = start < end ? start : end;
        final hi = start < end ? end : start;
        final paths = <String>{};
        for (int i = lo; i <= hi; i++) {
          paths.add(_vf[i].path);
        }
        selectedPaths.value = paths;
        cursorIndex.value = event.index;
      } else {
        selectedPaths.value = {event.entry.path};
        cursorIndex.value = event.index;
        anchorIndex.value = event.index;
      }
    });
  }

  void revealInFolder(String path) {
    final parent = PlatformPaths.parentOf(path);
    if (parent.isEmpty) return;
    closeSearch();
    navigateTo(parent);
    selectedPaths.value = {path};
  }

  void onOpen(FileEntry entry) => _openEntry(entry);

  void _openEntry(FileEntry entry) {
    if (entry.type == FileItemType.folder) {
      navigateTo(entry.path);
      return;
    }
    final loc = ArchivePath.resolve(entry.path);
    if (loc != null) {
      if (loc.isRoot) {
        navigateTo(entry.path);
      } else {
        FileSystemService.openArchiveEntry(loc);
      }
      return;
    }
    FileSystemService.openWithDefaultApp(entry.realPath);
  }

  void openSelected() {
    FileEntry? entry;
    if (cursorIndex.value >= 0 && cursorIndex.value < _vf.length) {
      entry = _vf[cursorIndex.value];
    } else if (selectedPaths.value.length == 1) {
      for (final file in _vf) {
        if (file.path == selectedPaths.value.first) {
          entry = file;
          break;
        }
      }
    }
    if (entry == null) return;
    _openEntry(entry);
  }

  void selectAll() {
    selectedPaths.value = Set<String>.from(_vf.map((f) => f.path));
  }

  /// Selects every visible entry whose name matches the given shell-style
  /// glob (`*`, `?`, character classes), case-insensitively. Returns the
  /// number of entries matched.
  int selectByPattern(String pattern) {
    final globs = pattern
        .split(',')
        .map((g) => g.trim())
        .where((g) => g.isNotEmpty)
        .toList();
    if (globs.isEmpty) return 0;
    final alternatives = globs.map((glob) {
      final buf = StringBuffer();
      for (final ch in glob.split('')) {
        switch (ch) {
          case '*':
            buf.write('.*');
          case '?':
            buf.write('.');
          case '[':
          case ']':
            buf.write(ch);
          default:
            buf.write(RegExp.escape(ch));
        }
      }
      return buf.toString();
    });
    final RegExp re;
    try {
      re = RegExp(
        '^(?:${alternatives.join('|')})\$',
        caseSensitive: false,
      );
    } catch (_) {
      return 0;
    }
    final matched = _vf.where((f) => re.hasMatch(f.name)).toList();
    selectedPaths.value = Set<String>.from(matched.map((f) => f.path));
    return matched.length;
  }

  void deselectAll() {
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
  }

  void toggleSelectAndAdvance() {
    batch(() {
      if (cursorIndex.value >= 0 && cursorIndex.value < _vf.length) {
        final path = _vf[cursorIndex.value].path;
        final paths = Set<String>.from(selectedPaths.value);
        if (paths.contains(path)) {
          paths.remove(path);
        } else {
          paths.add(path);
        }
        selectedPaths.value = paths;
      }
      if (cursorIndex.value < _vf.length - 1) {
        cursorIndex.value++;
      }
    });
  }

  void onBackgroundTap() => deselectAll();

  void onRectSelect(Set<String> paths, {bool additive = false}) {
    batch(() {
      if (additive) {
        selectedPaths.value = {...selectedPaths.value, ...paths};
      } else {
        selectedPaths.value = paths;
      }
      if (paths.isNotEmpty) {
        final idx = _vf.indexWhere((f) => paths.contains(f.path));
        if (idx >= 0) cursorIndex.value = idx;
      } else if (!additive) {
        cursorIndex.value = -1;
        anchorIndex.value = -1;
      }
    });
  }

  List<FileEntry> get selectedEntries {
    final paths = selectedPaths.value;
    return _vf.where((f) => paths.contains(f.path)).toList();
  }

  void deleteSelected({bool? toTrash}) {
    if (isTrashView) return;
    final entries = selectedEntries;
    if (entries.isEmpty) return;
    final paths = entries.map((e) => e.path).toList();
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    final archiveLoc = ArchivePath.resolve(currentPath.value);
    if (archiveLoc != null) {
      final inner = <String>[];
      for (final e in entries) {
        final loc = ArchivePath.resolve(e.path);
        if (loc != null && !loc.isRoot) inner.add(loc.innerPath);
      }
      operationStore.enqueueArchiveEdit(
        archivePath: archiveLoc.archivePath,
        displayDir: currentPath.value,
        deleteInner: inner,
      );
      return;
    }
    final useTrash =
        toTrash ?? SettingsStore.instance.deleteKeyBehavior.value == 'trash';
    if (useTrash) {
      operationStore.enqueueTrash(paths);
    } else {
      operationStore.enqueueDelete(paths);
    }
  }

  void copySelectedPaths() {
    final paths = selectedPaths.value;
    if (paths.isEmpty) return;
    final text = paths.length == 1 ? paths.first : paths.join('\n');
    Clipboard.setData(ClipboardData(text: text));
  }

  void onContextMenu(FileSelectionEvent event) {
    if (!selectedPaths.value.contains(event.entry.path)) {
      batch(() {
        selectedPaths.value = {event.entry.path};
        cursorIndex.value = event.index;
        anchorIndex.value = event.index;
      });
    }
  }

  void copySelected() async {
    if (isTrashView) return;
    if (selectedPaths.value.isEmpty) return;
    final paths = selectedPaths.value.toList();
    batch(() {
      clipboardPaths.value = Set<String>.from(paths);
      clipboardMode.value = ClipboardMode.copy;
    });
    await FileClipboard.writeFiles(paths, isCut: false);
  }

  void cutSelected() async {
    if (isTrashView) return;
    if (selectedPaths.value.isEmpty) return;
    final paths = selectedPaths.value.toList();
    batch(() {
      clipboardPaths.value = Set<String>.from(paths);
      clipboardMode.value = ClipboardMode.cut;
    });
    await FileClipboard.writeFiles(paths, isCut: true);
  }

  void dropFiles(
    List<String> sourcePaths,
    String destination, {
    bool move = false,
  }) {
    if (isTrashPath(destination)) return;
    final sep = PlatformPaths.separator;
    final filtered = sourcePaths.where((s) {
      final parent = PlatformPaths.parentOf(s);
      if (parent == destination) return false;
      if (destination == s) return false;
      if (destination.startsWith('$s$sep')) return false;
      return true;
    }).toList();
    if (filtered.isEmpty) return;
    final archiveLoc = ArchivePath.resolve(destination);
    if (archiveLoc != null) {
      operationStore.enqueueArchiveEdit(
        archivePath: archiveLoc.archivePath,
        displayDir: destination,
        addSources: filtered,
        addInner: archiveLoc.innerPath,
      );
      return;
    }
    if (move) {
      operationStore.enqueueMove(filtered, destination);
    } else {
      operationStore.enqueueCopy(filtered, destination);
    }
  }

  void paste() async {
    if (isTrashView) return;
    final internalPaths = Set<String>.from(clipboardPaths.value);
    final internalCut = clipboardMode.value == ClipboardMode.cut;

    final paths = await FileClipboard.readFilePaths();
    if (paths.isEmpty) return;

    final samePaths =
        internalPaths.length == paths.length &&
        internalPaths.containsAll(paths.toSet());

    bool isCut = samePaths && internalCut;
    if (!isCut) isCut = await FileClipboard.isCutOperation();

    final sep = PlatformPaths.separator;
    final filteredPaths = paths.where((s) {
      final parent = PlatformPaths.parentOf(s);
      if (parent == currentPath.value) return false;
      if (currentPath.value == s) return false;
      if (currentPath.value.startsWith('$s$sep')) {
        return false;
      }
      return true;
    }).toList();

    if (filteredPaths.isEmpty) {
      if (isCut && samePaths) {
        batch(() {
          clipboardPaths.value = {};
          clipboardMode.value = ClipboardMode.copy;
        });
      }
      return;
    }

    final archiveLoc = ArchivePath.resolve(currentPath.value);
    if (archiveLoc != null) {
      operationStore.enqueueArchiveEdit(
        archivePath: archiveLoc.archivePath,
        displayDir: currentPath.value,
        addSources: filteredPaths,
        addInner: archiveLoc.innerPath,
      );
      if (isCut && samePaths) {
        batch(() {
          clipboardPaths.value = {};
          clipboardMode.value = null;
        });
      }
      return;
    }

    if (isCut) {
      operationStore.enqueueMove(filteredPaths, currentPath.value);
      if (samePaths) {
        batch(() {
          clipboardPaths.value = {};
          clipboardMode.value = null;
        });
      }
    } else {
      operationStore.enqueueCopy(filteredPaths, currentPath.value);
    }
  }

  void moveCursor(int delta) {
    batch(() {
      if (_vf.isEmpty) return;

      final shift = HardwareKeyboard.instance.isShiftPressed;

      if (cursorIndex.value < 0) {
        cursorIndex.value = delta > 0 ? 0 : _vf.length - 1;
        anchorIndex.value = cursorIndex.value;
        selectedPaths.value = {_vf[cursorIndex.value].path};
        return;
      }

      final next = cursorIndex.value + delta;
      if (next < 0 || next >= _vf.length) return;

      if (shift) {
        final anchor = anchorIndex.value >= 0 && anchorIndex.value < _vf.length
            ? anchorIndex.value
            : cursorIndex.value;
        final lo = next < anchor ? next : anchor;
        final hi = next < anchor ? anchor : next;
        final paths = <String>{};
        for (int i = lo; i <= hi; i++) {
          paths.add(_vf[i].path);
        }
        selectedPaths.value = paths;
      } else {
        selectedPaths.value = {_vf[next].path};
        anchorIndex.value = next;
      }
      cursorIndex.value = next;
    });
  }
}
