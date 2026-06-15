import 'dart:async';
import 'dart:convert';
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
import '../../core/fs/sftp_fs.dart';
import '../../core/fs/smb_share_discovery.dart';
import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';
import '../locations/location_resolver.dart';
import '../locations/location_uri.dart';
import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../git/git_status_store.dart';
import '../operations/operation_store.dart';
import 'filter_query.dart';

enum ClipboardMode { copy, cut }

const String kPendingCreatePath = '__pending_create__';

class NavigationStore {
  final currentPath = signal('');
  final files = signal<List<FileEntry>>([]);
  final showHidden = signal(false);
  final selectedPaths = signal<Set<String>>({});
  final cursorIndex = signal(-1);
  final anchorIndex = signal(-1);
  int _pageRows = 10;
  final history = signal<List<String>>([]);
  final historyIndex = signal(0);
  final isLoading = signal(false);
  final clipboardPaths = signal<Set<String>>({});
  final clipboardMode = signal<ClipboardMode?>(null);
  final OperationStore operationStore;
  final gitStatus = GitStatusStore();
  Future<SmbCredentials?> Function(String logical)? requestSmbCredentials;
  Future<SftpCredentials?> Function(String logical)? requestSftpCredentials;
  final loadError = signal<String?>(null);
  final trashAccessDenied = signal<bool>(false);
  final accessDenied = signal<bool>(false);
  final renamingPath = signal<String?>(null);
  final renameError = signal<String?>(null);
  final pendingCreate = signal<FileEntry?>(null);
  final fileListFocusRequest = signal(0);
  final _trashEntries = <String, TrashEntry>{};
  int _loadToken = 0;
  String? _pendingInitialSelect;

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

  /// Translate a logical smb:// path to its physical gvfs mountpoint when
  /// possible; pass non-smb paths through unchanged.
  String _physical(String p) => LocationResolver.logicalToPhysical(p) ?? p;
  List<String> _physicalList(Iterable<String> ps) => ps.map(_physical).toList();

  Future<String?> resolveForOperation(String logical) =>
      _resolvePhysicalDestination(logical);

  Future<ArchiveLocation?> _archiveLocationFor(String path) async {
    if (PlatformPaths.isSmbUri(path)) {
      final physical = await _resolvePhysicalDestination(path);
      if (physical == null) return null;

      return ArchivePath.resolve(physical);
    }

    return ArchivePath.resolve(path);
  }

  /// Returns the physical path for [logical], mounting the share first when
  /// [logical] is smb://. Sets [loadError] and returns null if the share
  /// can't be reached — callers MUST refuse the op in that case (otherwise
  /// the unresolved URI is interpreted by `Directory(...)` as a relative
  /// path and pollutes the process CWD).
  Future<String?> _resolvePhysicalDestination(String logical) async {
    if (PlatformPaths.isSftpUri(logical)) {
      final result = await _resolveSftp(logical);
      switch (result) {
        case ResolveSuccess():
          return result.physicalPath;
        case ResolveError(:final message):
          loadError.value = message;

          return null;
        case ResolveUnsupported():
          loadError.value = t.errors.sftpNotSupported;

          return null;
        case ResolveAuthenticationRequired():
          loadError.value = t.errors.authenticationRequired;

          return null;
      }
    }
    if (!PlatformPaths.isSmbUri(logical)) return logical;
    final existing = LocationResolver.logicalToPhysical(logical);
    if (existing != null) return existing;
    final result = await _resolveSmb(logical);
    switch (result) {
      case ResolveSuccess():
        return result.physicalPath;
      case ResolveError(:final message):
        loadError.value = message;

        return null;
      case ResolveUnsupported():
        loadError.value = t.errors.smbNotSupportedOnPlatform;

        return null;
      case ResolveAuthenticationRequired():
        loadError.value = t.errors.authenticationRequired;

        return null;
    }
  }

  Future<ResolveResult> _resolveSmb(String logical) async {
    final result = await LocationResolver.resolve(logical);
    if (result is! ResolveAuthenticationRequired) return result;
    final credentials = await requestSmbCredentials?.call(logical);
    if (credentials == null ||
        credentials.username.trim().isEmpty ||
        credentials.password.isEmpty) {
      return result;
    }

    return LocationResolver.resolveWithCredentials(logical, credentials);
  }

  Future<ResolveResult> _resolveSftp(String logical) async {
    final result = await LocationResolver.resolve(logical);
    if (result is! ResolveAuthenticationRequired) return result;
    final credentials = await requestSftpCredentials?.call(logical);
    if (credentials == null || credentials.username.trim().isEmpty) {
      return result;
    }

    return LocationResolver.resolveSftpWithCredentials(logical, credentials);
  }

  Future<List<FileEntry>> _listSmbHostShares(
    String logical,
    LocationUri uri,
  ) async {
    final host = uri.host ?? '';
    if (host.isEmpty) {
      throw FileSystemException(t.errors.missingSmbHost, logical);
    }
    SmbShareListResult result = await SmbShareDiscovery.list(
      host: host,
      port: uri.port,
      credentials: uri.username != null && uri.username!.isNotEmpty
          ? SmbCredentials(username: uri.username!, password: '')
          : null,
    );
    if (result is SmbShareListAuthRequired) {
      final creds = await requestSmbCredentials?.call(logical);
      if (creds != null &&
          creds.username.trim().isNotEmpty &&
          creds.password.isNotEmpty) {
        result = await SmbShareDiscovery.list(
          host: host,
          port: uri.port,
          credentials: creds,
        );
      }
    }
    switch (result) {
      case SmbShareListOk(:final shares):
        final now = DateTime.now();

        return [
          for (final s in shares)
            FileEntry(
              name: s.name,
              path: '$logical/${s.name}',
              type: FileItemType.folder,
              size: 0,
              modified: now,
            ),
        ];
      case SmbShareListAuthRequired():
        throw FileSystemException(t.errors.authenticationRequired, logical);
      case SmbShareListError(:final message):
        throw FileSystemException(message, logical);
      case SmbShareListUnsupported():
        throw FileSystemException(t.errors.smbNotSupportedOnPlatform, logical);
    }
  }

  Future<List<FileEntry>> _listWindowsUncShares(
    String path,
    String host,
  ) async {
    final result = await SmbShareDiscovery.list(host: host);
    switch (result) {
      case SmbShareListOk(:final shares):
        final now = DateTime.now();

        return [
          for (final s in shares)
            FileEntry(
              name: s.name,
              path: PlatformPaths.join(path, s.name),
              type: FileItemType.folder,
              size: 0,
              modified: now,
            ),
        ];
      case SmbShareListAuthRequired():
        throw FileSystemException(t.errors.authenticationRequired, path);
      case SmbShareListError(:final message):
        throw FileSystemException(message, path);
      case SmbShareListUnsupported():
        throw FileSystemException(t.errors.smbNotSupportedOnPlatform, path);
    }
  }

  final DirectoryWatcherService _watcher = DirectoryWatcherService();

  final _folderStateCache = <String, _FolderState>{};

  final searchActive = signal(false);
  final searchQuery = signal('');
  final searchRecursive = signal(false);
  final searchContent = signal(false);
  final searchResults = signal<List<FileEntry>>([]);
  final isSearching = signal(false);
  final searchScannedDirs = signal(0);
  final searchCurrentDir = signal<String?>(null);
  final searchFocusRequest = signal(0);
  final pathBarFocusRequest = signal(0);
  final searchPatternError = signal<String?>(null);
  final renameAttempt = signal(0);
  final gridColumns = signal(1);

  SearchHandle? _searchHandle;
  Timer? _searchDebounce;
  Timer? _searchUiFlush;
  void Function()? _showHiddenDisposer;
  List<FileEntry>? _pendingSearchResults;
  int _searchToken = 0;
  static const _kSearchUiFlushMs = 180;

  late final canGoBack = computed(() => historyIndex.value > 0);
  late final canGoForward = computed(
    () => historyIndex.value < history.value.length - 1,
  );
  late final visibleFiles = computed(() {
    final pending = pendingCreate.value;
    if (searchActive.value && (searchRecursive.value || searchContent.value)) {
      var results = searchResults.value;
      if (SettingsStore.instance.searchMode.value == filterSearchMode) {
        final parsed = parseFilterQuery(searchQuery.value);
        final filter = parsed.query;
        results = filter == null
            ? const []
            : results.where((f) => filter.matches(f)).toList();
      }
      final sorted = sortEntries(
        results,
        key: sortKey.value,
        ascending: sortAscending.value,
        foldersFirst: foldersFirst.value,
        naturalSort: SettingsStore.instance.naturalSort.value,
        sortFolders: SettingsStore.instance.sortFolders.value,
      );

      return pending != null ? [pending, ...sorted] : sorted;
    }
    var list = showHidden.value
        ? files.value
        : files.value.where((f) => !f.isHidden).toList();
    final q = searchQuery.value.trim();
    if (searchActive.value && q.isNotEmpty) {
      if (SettingsStore.instance.searchMode.value == filterSearchMode) {
        final parsed = parseFilterQuery(q);
        final filter = parsed.query;
        if (filter != null) {
          list = list.where((f) => filter.matches(f)).toList();
        } else {
          list = const [];
        }
      } else {
        final matcher = _localMatcher(q, _currentSearchMode());
        if (matcher != null) {
          list = list.where((f) => matcher(f.name)).toList();
        } else {
          list = const [];
        }
      }
    }
    list = sortEntries(
      list,
      key: sortKey.value,
      ascending: sortAscending.value,
      foldersFirst: foldersFirst.value,
      naturalSort: SettingsStore.instance.naturalSort.value,
      sortFolders: SettingsStore.instance.sortFolders.value,
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

  NavigationStore({
    required this.operationStore,
    String? initialPath,
    String? initialSelect,
  }) {
    final startPath = initialPath ?? PlatformPaths.homePath;
    currentPath.value = startPath;
    history.value = [startPath];
    showHidden.value = SettingsStore.instance.showHiddenDefault.value;
    _pendingInitialSelect = initialSelect;
    _loadSortFor(startPath);
    loadDirectory(startPath);
    _setupShowHiddenEffect();
    _setupSortDefaultsEffect();
    _setupGitStatusEffect();
  }

  void _setupGitStatusEffect() {
    _gitStatusDisposer = effect(() {
      final path = currentPath.value;
      if (!PlatformPaths.isNetworkPath(path)) gitStatus.watchPath(path);
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
    if (!s.rememberFolderSort.value) return;
    if (!s.isLoaded) return;
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
    } catch (e, st) {
      log.warn('navigation', 'failed to load folder sort', error: e, stack: st);
    }
  }

  void _persistSort() {
    final path = currentPath.value;
    if (path.isEmpty) return;
    final s = SettingsStore.instance;
    if (!s.rememberFolderSort.value) return;
    if (!s.isLoaded) return;
    s.db
        .setFolderPref(
          path,
          sortKey: sortKeyToString(sortKey.value),
          sortAscending: sortAscending.value,
          foldersFirst: foldersFirst.value,
        )
        .catchError(
          (e, st) => log.warn(
            'navigation',
            'failed to persist folder sort',
            error: e,
            stack: st,
          ),
        );
  }

  void setSortKey(SortKey key) {
    if (sortKey.value == key) return;
    sortKey.value = key;
    _persistSort();
  }

  void setSortAscending(bool ascending) {
    if (sortAscending.value == ascending) return;
    sortAscending.value = ascending;
    _persistSort();
  }

  void setFoldersFirst(bool value) {
    if (foldersFirst.value == value) return;
    foldersFirst.value = value;
    _persistSort();
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
      if (searchActive.value &&
          (searchRecursive.value || searchContent.value)) {
        _scheduleSearchRestart();
      }
    });
  }

  void focusPathBar() {
    pathBarFocusRequest.value = pathBarFocusRequest.value + 1;
  }

  void openSearch({bool recursive = false}) {
    batch(() {
      searchActive.value = true;
      if (recursive) searchRecursive.value = true;
      searchFocusRequest.value = searchFocusRequest.value + 1;
    });
  }

  void closeSearch() {
    _searchToken++;
    _searchDebounce?.cancel();
    _searchUiFlush?.cancel();
    _searchUiFlush = null;
    _pendingSearchResults = null;
    _searchHandle?.cancel();
    _searchHandle = null;
    batch(() {
      searchActive.value = false;
      searchRecursive.value = false;
      searchContent.value = false;
      searchQuery.value = '';
      searchResults.value = [];
      isSearching.value = false;
      searchScannedDirs.value = 0;
      searchCurrentDir.value = null;
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
  }

  void setSearchQuery(String q) {
    batch(() {
      searchQuery.value = q;
      searchPatternError.value = validateSearchPattern(
        q.trim(),
        _currentSearchMode(),
      );
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    _scheduleSearchRestart();
  }

  void toggleRecursive() {
    searchRecursive.value = !searchRecursive.value;
    _scheduleSearchRestart();
  }

  void toggleContent() {
    if (PlatformPaths.isSftpUri(currentPath.value)) return;
    if (SettingsStore.instance.searchMode.value == filterSearchMode) return;
    final enabling = !searchContent.value;
    batch(() {
      searchContent.value = enabling;
      if (enabling && SettingsStore.instance.searchMode.value == 'glob') {
        SettingsStore.instance.searchMode.value = 'substring';
        searchPatternError.value = validateSearchPattern(
          searchQuery.value.trim(),
          _currentSearchMode(),
        );
      }
    });
    _scheduleSearchRestart();
  }

  void cycleSearchMode() {
    const order = ['substring', 'glob', 'regex', filterSearchMode];
    final s = SettingsStore.instance;
    final idx = order.indexOf(s.searchMode.value);
    setSearchMode(order[((idx < 0 ? 0 : idx) + 1) % order.length]);
  }

  void setSearchMode(String mode) {
    final s = SettingsStore.instance;
    if (mode == 'glob' && searchContent.value) return;
    if (s.searchMode.value == mode) return;
    batch(() {
      s.searchMode.value = mode;
      if (mode == filterSearchMode) searchContent.value = false;
      searchPatternError.value = validateSearchPattern(
        searchQuery.value.trim(),
        _currentSearchMode(),
      );
    });
    _scheduleSearchRestart();
  }

  SearchMode _currentSearchMode() {
    switch (SettingsStore.instance.searchMode.value) {
      case 'glob':
        return SearchMode.glob;
      case 'regex':
        return SearchMode.regex;
      default:
        return SearchMode.substring;
    }
  }

  static bool Function(String)? _localMatcher(String query, SearchMode mode) {
    switch (mode) {
      case SearchMode.substring:
        final q = query.toLowerCase();

        return (name) => name.toLowerCase().contains(q);
      case SearchMode.regex:
        try {
          final r = RegExp(query);

          return r.hasMatch;
        } catch (e) {
          return null;
        }
      case SearchMode.glob:
        final r = _globToRegExp(query);

        return r?.hasMatch;
    }
  }

  static String? validateSearchPattern(String query, SearchMode mode) {
    if (query.isEmpty) return null;
    if (SettingsStore.instance.searchMode.value == filterSearchMode) {
      return parseFilterQuery(query).error;
    }
    switch (mode) {
      case SearchMode.substring:
        return null;
      case SearchMode.regex:
        try {
          RegExp(query);

          return null;
        } catch (e) {
          return t.search.invalidRegex;
        }
      case SearchMode.glob:
        return _globToRegExp(query) == null ? t.search.invalidGlob : null;
    }
  }

  static RegExp? _globToRegExp(String glob) {
    final sb = StringBuffer('^');
    var i = 0;
    while (i < glob.length) {
      final c = glob[i];
      if (c == '*') {
        if (i + 1 < glob.length && glob[i + 1] == '*') {
          sb.write('.*');
          i += 2;
        } else {
          sb.write('[^/]*');
          i++;
        }
      } else if (c == '?') {
        sb.write('[^/]');
        i++;
      } else if (c == '[') {
        final end = glob.indexOf(']', i + 1);
        if (end < 0) return null;
        sb.write(glob.substring(i, end + 1));
        i = end + 1;
      } else if ('.+()|^\$\\/'.contains(c)) {
        sb.write('\\');
        sb.write(c);
        i++;
      } else {
        sb.write(c);
        i++;
      }
    }
    sb.write('\$');
    try {
      return RegExp(sb.toString(), caseSensitive: false);
    } catch (e) {
      return null;
    }
  }

  void _scheduleSearchRestart() {
    _searchDebounce?.cancel();
    if (searchRecursive.value || searchContent.value) {
      _searchDebounce = Timer(const Duration(milliseconds: 250), () {
        _restartRecursiveSearch();
      });

      return;
    }
    _restartRecursiveSearch();
  }

  Future<void> _restartRecursiveSearch() async {
    final token = ++_searchToken;
    _searchHandle?.cancel();
    _searchHandle = null;
    _searchUiFlush?.cancel();
    _searchUiFlush = null;
    _pendingSearchResults = null;
    batch(() {
      searchResults.value = [];
      searchScannedDirs.value = 0;
      searchCurrentDir.value = null;
      isSearching.value = false;
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    if (!searchActive.value ||
        (!searchRecursive.value && !searchContent.value)) {
      return;
    }
    final q = searchQuery.value.trim();
    if (q.isEmpty) return;
    isSearching.value = true;
    final acc = <FileEntry>[];
    final mode = _currentSearchMode();
    final err = validateSearchPattern(q, mode);
    searchPatternError.value = err;
    if (err != null) {
      isSearching.value = false;

      return;
    }
    final root = await _resolvePhysicalDestination(currentPath.value);
    if (token != _searchToken) return;
    if (root == null) {
      isSearching.value = false;

      return;
    }
    final filter = SettingsStore.instance.searchMode.value == filterSearchMode
        ? parseFilterQuery(q).query
        : null;
    final recursiveQuery = filter?.recursiveNameQuery ?? q;
    if (recursiveQuery.isEmpty && filter == null) {
      isSearching.value = false;

      return;
    }
    if (PlatformPaths.isSftpUri(root)) {
      if (searchContent.value) {
        isSearching.value = false;

        return;
      }
      final matcher = filter != null && recursiveQuery.isEmpty
          ? (_) => true
          : _localMatcher(recursiveQuery, mode);
      if (matcher == null) {
        isSearching.value = false;

        return;
      }
      _runSftpRecursiveSearch(
        token: token,
        root: root,
        includeHidden: showHidden.value,
        matcher: matcher,
        filter: filter,
      );

      return;
    }
    _searchHandle = RecursiveSearch.start(
      root: root,
      query: recursiveQuery,
      includeHidden: showHidden.value,
      mode: mode,
      content: searchContent.value,
      maxDepth: searchRecursive.value ? 0 : 1,
      onBatch: (b) {
        if (token != _searchToken) return;
        final entries = b.map(_logicalEntryFromPhysical);
        acc.addAll(filter == null ? entries : entries.where(filter.matches));
        _pendingSearchResults = acc;
        _scheduleSearchUiFlush();
      },
      onProgress: (n, currentDir) {
        if (token != _searchToken) return;
        batch(() {
          searchScannedDirs.value = n;
          if (currentDir != null) {
            searchCurrentDir.value =
                LocationResolver.physicalToLogical(currentDir) ?? currentDir;
          }
        });
      },
      onDone: () {
        if (token != _searchToken) return;
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
        if (token != _searchToken) return;
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

  Future<void> _runSftpRecursiveSearch({
    required int token,
    required String root,
    required bool includeHidden,
    required bool Function(String name) matcher,
    required FilterQuery? filter,
  }) async {
    final acc = <FileEntry>[];
    var scanned = 0;

    Future<void> walk(String dir) async {
      if (token != _searchToken) return;
      batch(() {
        searchScannedDirs.value = scanned;
        searchCurrentDir.value = dir;
      });
      final entries = await FileSystemService.listDirectory(dir);
      scanned++;
      for (final entry in entries) {
        if (token != _searchToken) return;
        if (!includeHidden && entry.isHidden) continue;
        if (matcher(entry.name) && (filter == null || filter.matches(entry))) {
          acc.add(entry);
          _pendingSearchResults = acc;
          _scheduleSearchUiFlush();
        }
        if (entry.type == FileItemType.folder) {
          await walk(entry.path);
        }
      }
    }

    try {
      await walk(root);
      if (token != _searchToken) return;
      _searchUiFlush?.cancel();
      _searchUiFlush = null;
      _pendingSearchResults = null;
      batch(() {
        searchResults.value = List.of(acc);
        searchScannedDirs.value = scanned;
        searchCurrentDir.value = null;
        isSearching.value = false;
      });
    } catch (e, st) {
      if (token != _searchToken) return;
      log.warn('navigation', 'recursive search failed', error: e, stack: st);
      _searchUiFlush?.cancel();
      _searchUiFlush = null;
      _pendingSearchResults = null;
      batch(() {
        searchCurrentDir.value = null;
        isSearching.value = false;
      });
    }
  }

  FileEntry _logicalEntryFromPhysical(FileEntry entry) {
    final logical = LocationResolver.physicalToLogical(entry.path);
    if (logical == null) return entry;

    return FileEntry.raw(
      name: entry.name,
      path: logical,
      realPath: entry.realPath,
      type: entry.type,
      size: entry.size,
      modifiedMs: entry.modifiedMs,
    );
  }

  void _scheduleSearchUiFlush() {
    if (_searchUiFlush?.isActive ?? false) return;
    final pending = _pendingSearchResults;
    if (pending != null) {
      _pendingSearchResults = null;
      searchResults.value = List.of(pending);
    }
    _searchUiFlush = Timer(const Duration(milliseconds: _kSearchUiFlushMs), () {
      _searchUiFlush = null;
      final p = _pendingSearchResults;
      if (p == null) return;
      _pendingSearchResults = null;
      searchResults.value = List.of(p);
    });
  }

  Future<void> _ensureSftpConnectedAndNavigate(
    String logical, {
    bool addToHistory = true,
    String? enteredPath,
  }) async {
    batch(() {
      isLoading.value = true;
      loadError.value = null;
    });
    final result = await _resolveSftp(logical);
    switch (result) {
      case ResolveSuccess():
        _doNavigate(
          result.physicalPath,
          addToHistory: addToHistory,
          enteredPath: enteredPath,
        );
      case ResolveError(:final message):
        batch(() {
          isLoading.value = false;
          loadError.value = message;
        });
      case ResolveUnsupported():
        batch(() {
          isLoading.value = false;
          loadError.value = t.errors.sftpNotSupported;
        });
      case ResolveAuthenticationRequired():
        batch(() {
          isLoading.value = false;
          loadError.value = t.errors.authenticationRequired;
        });
    }
  }

  Future<void> _ensureSmbMountedAndNavigate(
    String logical, {
    bool addToHistory = true,
    String? enteredPath,
  }) async {
    final uri = LocationUri.parse(logical);
    if (uri.share == null || uri.share!.isEmpty) {
      _doNavigate(
        logical,
        addToHistory: addToHistory,
        enteredPath: enteredPath,
      );

      return;
    }
    batch(() {
      isLoading.value = true;
      loadError.value = null;
    });
    final result = await _resolveSmb(logical);
    switch (result) {
      case ResolveSuccess():
        _doNavigate(
          logical,
          addToHistory: addToHistory,
          enteredPath: enteredPath,
        );
      case ResolveError(:final message):
        batch(() {
          isLoading.value = false;
          loadError.value = message;
        });
      case ResolveUnsupported():
        batch(() {
          isLoading.value = false;
          loadError.value = t.errors.smbNotSupportedOnPlatform;
        });
      case ResolveAuthenticationRequired():
        batch(() {
          isLoading.value = false;
          loadError.value = t.errors.authenticationRequired;
        });
    }
  }

  /// Synchronous resolution for inputs that don't need IO (local, UNC,
  /// trash, smb→UNC on Windows). Returns null for inputs that need async
  /// resolution (smb on Linux) or are unsupported (other schemes).
  String? _resolveForNavigationSync(String input) {
    final uri = LocationUri.parse(input);
    switch (uri.scheme) {
      case LocationScheme.smb:
        if (PlatformPaths.isWindows) {
          if (uri.port != null) {
            loadError.value = t.errors.smbPortsNotSupportedOnWindows;

            return null;
          }
          final unc = uri.toWindowsUnc();
          if (unc == null) {
            loadError.value = t.errors.invalidSmbUri;

            return null;
          }

          return unc;
        }

        return null;
      case LocationScheme.sftp:
        // Asynchronously resolved via _ensureSftpConnectedAndNavigate.
        return null;
      case LocationScheme.other:
        loadError.value = t.errors.smbNotSupportedOnPlatform;

        return null;
      case LocationScheme.windowsUnc:
      case LocationScheme.local:
      case LocationScheme.trash:
        return input;
    }
  }

  void navigateTo(
    String path, {
    bool addToHistory = true,
    String? enteredPath,
  }) {
    final uri = LocationUri.parse(path);
    if (uri.scheme == LocationScheme.sftp) {
      _ensureSftpConnectedAndNavigate(
        path,
        addToHistory: addToHistory,
        enteredPath: enteredPath,
      );

      return;
    }
    if (uri.scheme == LocationScheme.smb && !PlatformPaths.isWindows) {
      _ensureSmbMountedAndNavigate(
        path,
        addToHistory: addToHistory,
        enteredPath: enteredPath,
      );

      return;
    }
    final resolved = _resolveForNavigationSync(path);
    if (resolved == null) return;
    _doNavigate(resolved, addToHistory: addToHistory, enteredPath: enteredPath);
  }

  void _doNavigate(
    String resolved, {
    bool addToHistory = true,
    String? enteredPath,
  }) {
    final normalized = isTrashPath(resolved)
        ? resolved
        : PlatformPaths.normalize(resolved);
    final previous = currentPath.value;
    if (previous.isNotEmpty && previous != normalized) {
      _saveFolderState(previous);
    }
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
    _recordEnteredPath(enteredPath);
  }

  void _recordEnteredPath(String? path) {
    if (path == null || path.trim().isEmpty) return;
    final s = SettingsStore.instance;
    if (!s.isLoaded) return;
    s.db
        .recordRecentEnteredPath(path)
        .catchError(
          (e, st) => log.warn(
            'navigation',
            'failed to record entered path',
            error: e,
            stack: st,
          ),
        );
  }

  void _saveFolderState(String path) {
    if (path.isEmpty) return;
    final s = SettingsStore.instance;
    if (!s.rememberFolderState.value) return;
    final idx = cursorIndex.value;
    final list = _vf;
    final cursorPath = (idx >= 0 && idx < list.length) ? list[idx].path : null;
    final selected = Set<String>.from(selectedPaths.value);
    _folderStateCache[path] = _FolderState(
      selectedPaths: selected,
      cursorPath: cursorPath,
    );
    if (!s.isLoaded) return;
    final encoded = selected.isEmpty ? null : jsonEncode(selected.toList());
    s.db
        .setFolderUiState(path, cursorPath: cursorPath, selectedPaths: encoded)
        .catchError(
          (e, st) => log.warn(
            'navigation',
            'failed to save folder state',
            error: e,
            stack: st,
          ),
        );
  }

  void _applyPendingSelect() {
    final target = _pendingInitialSelect;
    if (target == null) return;
    _pendingInitialSelect = null;
    final list = _vf;
    final idx = list.indexWhere((f) => f.path == target);
    batch(() {
      selectedPaths.value = {target};
      if (idx >= 0) {
        cursorIndex.value = idx;
        anchorIndex.value = idx;
      }
    });
  }

  Future<void> _restoreFolderStateIfMatches(String path) async {
    if (_pendingInitialSelect != null) return;
    final s = SettingsStore.instance;
    if (!s.rememberFolderState.value) return;
    _FolderState? state = _folderStateCache[path];
    if (state == null && s.isLoaded) {
      try {
        final pref = await s.db.getFolderPref(path);
        if (pref == null) return;
        if (currentPath.value != path) return;
        Set<String> selected = const {};
        final raw = pref.selectedPaths;
        if (raw != null && raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              selected = decoded.whereType<String>().toSet();
            }
          } catch (e, st) {
            log.warn(
              'navigation',
              'failed to decode stored folder selection',
              error: e,
              stack: st,
            );
          }
        }
        if (pref.cursorPath == null && selected.isEmpty) return;
        state = _FolderState(
          selectedPaths: selected,
          cursorPath: pref.cursorPath,
        );
        _folderStateCache[path] = state;
      } catch (e, st) {
        log.warn(
          'navigation',
          'failed to restore folder state',
          error: e,
          stack: st,
        );

        return;
      }
    }
    final resolved = state;
    if (resolved == null) return;
    final list = _vf;
    if (list.isEmpty) return;
    final visiblePaths = {for (final f in list) f.path};
    final restored = resolved.selectedPaths.intersection(visiblePaths);
    int cursor = -1;
    final cursorPath = resolved.cursorPath;
    if (cursorPath != null) {
      cursor = list.indexWhere((f) => f.path == cursorPath);
    }
    if (cursor < 0 && restored.isNotEmpty) {
      cursor = list.indexWhere((f) => f.path == restored.first);
    }
    batch(() {
      if (restored.isNotEmpty) selectedPaths.value = restored;
      if (cursor >= 0) {
        cursorIndex.value = cursor;
        anchorIndex.value = cursor;
      }
    });
  }

  Future<bool> navigateToEnteredPath(String path) async {
    final trimmed = PlatformPaths.expandTilde(
      PlatformPaths.expandEnvVars(path.trim()),
    );
    if (trimmed.isEmpty) return false;
    final uri = LocationUri.parse(trimmed);
    if (uri.scheme == LocationScheme.sftp) {
      navigateTo(trimmed, enteredPath: trimmed);

      return true;
    }
    if (uri.scheme == LocationScheme.smb && !PlatformPaths.isWindows) {
      navigateTo(trimmed, enteredPath: trimmed);

      return true;
    }
    final resolved = _resolveForNavigationSync(trimmed);
    if (resolved == null) return true;
    final normalized = isTrashPath(resolved)
        ? resolved
        : PlatformPaths.normalize(resolved);
    if (isTrashPath(normalized)) {
      navigateTo(normalized, enteredPath: trimmed);

      return true;
    }
    if (PlatformPaths.windowsUncServerRoot(normalized) != null) {
      navigateTo(normalized, enteredPath: trimmed);

      return true;
    }

    final type = FileSystemEntity.typeSync(normalized);
    if (type == FileSystemEntityType.directory) {
      navigateTo(normalized, enteredPath: trimmed);

      return true;
    }
    if (type == FileSystemEntityType.file ||
        type == FileSystemEntityType.link) {
      final parent = PlatformPaths.parentOf(normalized);
      if (parent.isEmpty || !await FileSystemService.isNavigable(parent)) {
        return false;
      }
      revealInFolder(normalized, enteredPath: trimmed);

      return true;
    }

    return false;
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
    final cur = currentPath.value;
    if (PlatformPaths.isSmbUri(cur)) {
      final parent = PlatformPaths.parentOf(cur);
      if (parent != cur) navigateTo(parent);

      return;
    }
    final parent = PlatformPaths.parentOf(cur);
    if (parent == cur) return;
    if (PlatformPaths.windowsUncServerRoot(parent) != null ||
        await FileSystemService.isNavigable(parent)) {
      navigateTo(parent);
    }
  }

  Future<void> refresh() => loadDirectory(currentPath.value);

  Future<void> loadDirectory(String path) async {
    final token = ++_loadToken;
    batch(() {
      isLoading.value = true;
      trashAccessDenied.value = false;
      accessDenied.value = false;
    });
    try {
      final List<FileEntry> entries;
      if (isTrashPath(path)) {
        entries = await _loadTrash(path);
      } else if (PlatformPaths.isSmbUri(path)) {
        final uri = LocationUri.parse(path);
        if (uri.share == null || uri.share!.isEmpty) {
          entries = await _listSmbHostShares(path, uri);
          if (token != _loadToken) return;
          batch(() {
            files.value = entries;
            loadError.value = null;
            trashAccessDenied.value = false;
            isLoading.value = false;
          });
          _restoreFolderStateIfMatches(path);
          _watcher.stop();

          return;
        }
        var physical = LocationResolver.logicalToPhysical(path);
        if (physical == null) {
          final r = await _resolveSmb(path);
          if (r is ResolveSuccess) {
            physical = r.physicalPath;
          } else if (r is ResolveError) {
            throw FileSystemException(r.message, path);
          } else if (r is ResolveAuthenticationRequired) {
            throw FileSystemException(t.errors.authenticationRequired, path);
          }
          if (physical == null) {
            throw FileSystemException(t.errors.smbShareNotMounted, path);
          }
        }
        final raw = await FileSystemService.listDirectory(physical);
        entries = [
          for (final e in raw)
            FileEntry.raw(
              name: e.name,
              path: '$path/${e.name}',
              realPath: e.path,
              type: e.type,
              size: e.size,
              modifiedMs: e.modifiedMs,
            ),
        ];
      } else if (PlatformPaths.windowsUncServerRoot(path) case final host?) {
        entries = await _listWindowsUncShares(path, host);
        if (token != _loadToken) return;
        batch(() {
          files.value = entries;
          loadError.value = null;
          trashAccessDenied.value = false;
          isLoading.value = false;
        });
        _restoreFolderStateIfMatches(path);
        _watcher.stop();

        return;
      } else {
        entries = await FileSystemService.listDirectory(path);
      }
      if (token != _loadToken) return;
      batch(() {
        files.value = entries;
        loadError.value = null;
        trashAccessDenied.value = false;
        isLoading.value = false;
      });
      _restoreFolderStateIfMatches(path);
      _applyPendingSelect();
      if (isTrashPath(path) || PlatformPaths.isNetworkPath(path)) {
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
      if (e is TrashAccessDeniedException) {
        batch(() {
          files.value = [];
          loadError.value = null;
          trashAccessDenied.value = true;
          accessDenied.value = false;
          isLoading.value = false;
        });
        _watcher.stop();

        return;
      }
      if (e is FileSystemException && _isPermissionDenied(path)) {
        batch(() {
          files.value = [];
          loadError.value = null;
          trashAccessDenied.value = false;
          accessDenied.value = true;
          isLoading.value = false;
        });
        _watcher.stop();

        return;
      }
      batch(() {
        files.value = [];
        loadError.value = switch (e) {
          ArchiveReadException() => t.errors.archiveError,
          FileSystemException(:final message) =>
            message.isNotEmpty ? message : e.toString(),
          _ => e.toString(),
        };
        trashAccessDenied.value = false;
        accessDenied.value = false;
        isLoading.value = false;
      });
      _watcher.stop();
    }
  }

  bool _isPermissionDenied(String path) {
    try {
      Directory(path).listSync(followLinks: false);

      return false;
    } on FileSystemException catch (e) {
      final code = e.osError?.errorCode;
      if (code == 1 || code == 13 || code == 5) return true;
      final msg = e.message.toLowerCase();

      return msg.contains('operation not permitted') ||
          msg.contains('permission denied') ||
          msg.contains('access is denied');
    } catch (e, st) {
      log.warn('navigation', 'permission probe failed', error: e, stack: st);

      return false;
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

  Future<void> restoreSelectedFromTrash() async {
    final entries = _selectedTrashEntries();
    if (entries.isEmpty) return;
    operationStore.enqueueTrashRestore(entries);
    _clearTrashSelection();
  }

  Future<void> deletePermanentlySelectedFromTrash() async {
    final entries = _selectedTrashEntries();
    if (entries.isEmpty) return;
    operationStore.enqueueTrashDelete(entries);
    _clearTrashSelection();
  }

  List<TrashEntry> _selectedTrashEntries() {
    if (!isTrashView) return const [];
    final entries = <TrashEntry>[];
    for (final p in selectedPaths.value.toList()) {
      final e = _trashEntries[p];
      if (e != null) entries.add(e);
    }

    return entries;
  }

  void _clearTrashSelection() {
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
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
      _applyExternalChanges(sortCurrent(_dedupeByName(patched)));
    } catch (e, st) {
      log.warn('navigation', 'incremental refresh failed', error: e, stack: st);
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
    naturalSort: SettingsStore.instance.naturalSort.value,
    sortFolders: SettingsStore.instance.sortFolders.value,
  );

  static List<FileEntry> _dedupeByName(List<FileEntry> entries) {
    final seen = <String>{};
    final out = <FileEntry>[];
    for (final e in entries) {
      final name = PlatformPaths.fileName(e.path);
      final key = PlatformPaths.isWindows ? name.toLowerCase() : name;
      if (seen.add(key)) out.add(e);
    }

    return out;
  }

  void _onExternalChange(String path) async {
    if (path != currentPath.value) return;
    try {
      final entries = await FileSystemService.listDirectory(path);
      if (path != currentPath.value) return;
      _applyExternalChanges(entries);
    } catch (e, st) {
      log.warn('navigation', 'external refresh failed', error: e, stack: st);
    }
  }

  void _applyExternalChanges(List<FileEntry> newEntries) {
    final newPaths = newEntries.map((e) => e.path).toSet();
    final filteredSelected = selectedPaths.value
        .where(newPaths.contains)
        .toSet();

    final visible = showHidden.value
        ? newEntries
        : newEntries.where((f) => !f.isHidden).toList();

    final oldCursor = cursorIndex.value;
    int newCursor = -1;
    if (oldCursor >= 0 && oldCursor < _vf.length) {
      final cursorPath = _vf[oldCursor].path;
      newCursor = visible.indexWhere((e) => e.path == cursorPath);
    }
    if (newCursor < 0 && oldCursor >= 0 && visible.isNotEmpty) {
      newCursor = oldCursor.clamp(0, visible.length - 1);
    }
    int newAnchor = -1;
    if (anchorIndex.value >= 0 && anchorIndex.value < _vf.length) {
      final anchorPath = _vf[anchorIndex.value].path;
      newAnchor = visible.indexWhere((e) => e.path == anchorPath);
    }
    if (newAnchor < 0) newAnchor = newCursor;

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
    fileListFocusRequest.value++;
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

    final renameLoc = await _archiveLocationFor(oldPath);
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

    final isSmbRename = PlatformPaths.isSmbUri(oldPath);
    if (PlatformPaths.isSftpUri(oldPath)) {
      await _commitSftpRename(oldPath, trimmed);

      return;
    }
    final physicalOld = _physical(oldPath);
    final result = FileSystemService.rename(physicalOld, trimmed);

    switch (result) {
      case RenameSuccess(:final newPath):
        final logicalNew = isSmbRename
            ? '${PlatformPaths.parentOf(oldPath)}/$trimmed'
            : newPath;
        batch(() {
          renamingPath.value = null;
          renameError.value = null;
          selectedPaths.value = {logicalNew};
        });
        if (searchActive.value && searchRecursive.value) {
          final updated = searchResults.value.map((e) {
            if (e.path != oldPath) return e;

            return FileEntry(
              name: PlatformPaths.fileName(logicalNew),
              path: logicalNew,
              type: e.type,
              size: e.size,
              modified: e.modified,
            );
          }).toList();
          searchResults.value = updated;
          final idx = updated.indexWhere((f) => f.path == logicalNew);
          if (idx >= 0) {
            batch(() {
              cursorIndex.value = idx;
              anchorIndex.value = idx;
            });
          }
        } else {
          await refresh();
          final idx = _vf.indexWhere((f) => f.path == logicalNew);
          if (idx >= 0) {
            batch(() {
              cursorIndex.value = idx;
              anchorIndex.value = idx;
            });
          }
        }
        fileListFocusRequest.value++;
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

  Future<void> _commitSftpRename(String oldPath, String newName) async {
    if (!PlatformPaths.isValidFileName(newName)) {
      renameError.value = t.toast.renameInvalidName;
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    if (PlatformPaths.fileName(oldPath) == newName) {
      batch(() {
        renamingPath.value = null;
        renameError.value = null;
      });

      return;
    }
    final parent = PlatformPaths.parentOf(oldPath);
    final newPath = '$parent/$newName';
    final fs = const SftpFs();
    if (await fs.exists(newPath)) {
      renameError.value = t.toast.renameAlreadyExists(name: newName);
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    try {
      await fs.rename(oldPath, newPath);
    } catch (e) {
      renameError.value = t.toast.renameError(message: e.toString());
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    batch(() {
      renamingPath.value = null;
      renameError.value = null;
      selectedPaths.value = {newPath};
    });
    await refresh();
    final idx = _vf.indexWhere((f) => f.path == newPath);
    if (idx >= 0) {
      batch(() {
        cursorIndex.value = idx;
        anchorIndex.value = idx;
      });
    }
  }

  Future<MultiRenameOutcome> multiRename(
    List<({String path, String newName})> renames, {
    MultiRenameProgressCallback? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (renames.isEmpty) return const MultiRenameOutcome.empty();
    if (isTrashView) {
      return MultiRenameOutcome(
        succeeded: 0,
        invalid: 0,
        collision: 0,
        other: renames.length,
        blocked: true,
      );
    }
    var processed = 0;
    final total = renames.length;
    var cancelled = false;

    bool shouldStop() {
      cancelled = cancelled || (isCancelled?.call() ?? false);

      return cancelled;
    }

    void report(String currentName) {
      if (total <= 0) return;
      processed++;
      if (processed > total) processed = total;
      onProgress?.call(processed, total, currentName);
    }

    final localOrSmb = <({String path, String newName})>[];
    final sftp = <({String path, String newName})>[];
    final archive = <({ArchiveLocation loc, String oldPath, String newName})>[];

    for (final r in renames) {
      if (shouldStop()) break;
      final loc = await _archiveLocationFor(r.path);
      if (loc != null && !loc.isRoot) {
        archive.add((loc: loc, oldPath: r.path, newName: r.newName));
      } else if (PlatformPaths.isSftpUri(r.path)) {
        sftp.add(r);
      } else {
        localOrSmb.add(r);
      }
    }

    final acc = _MutableOutcome();
    _multiRenameLocal(localOrSmb, acc, report, shouldStop);
    if (!shouldStop()) {
      await _multiRenameSftp(sftp, acc, report, shouldStop);
    }
    if (!shouldStop()) {
      _multiRenameArchive(archive, acc, report, shouldStop);
    }

    batch(() {
      renamingPath.value = null;
      renameError.value = null;
    });
    await refresh();
    if (acc.succeeded > 0) {
      final visiblePaths = _vf.map((f) => f.path).toSet();
      final remaining = selectedPaths.value.intersection(visiblePaths);
      batch(() {
        selectedPaths.value = remaining;
        if (remaining.isEmpty) {
          cursorIndex.value = -1;
          anchorIndex.value = -1;
        }
      });
    }

    return acc.freeze();
  }

  void _multiRenameLocal(
    List<({String path, String newName})> renames,
    _MutableOutcome acc,
    void Function(String currentName) report,
    bool Function() shouldStop,
  ) {
    if (renames.isEmpty) return;

    final ops = <_LocalRenameOp>[];
    for (final r in renames) {
      if (shouldStop()) return;
      final physicalOld = _physical(r.path);
      final dir = PlatformPaths.parentOf(physicalOld);
      final physicalNew = '$dir${PlatformPaths.separator}${r.newName}';
      if (!PlatformPaths.isValidFileName(r.newName)) {
        acc.invalid++;
        report(r.newName);
        continue;
      }
      if (physicalOld == physicalNew) {
        report(r.newName);
        continue;
      }
      ops.add(
        _LocalRenameOp(
          physicalOld: physicalOld,
          physicalNew: physicalNew,
          newName: r.newName,
        ),
      );
    }

    if (ops.isEmpty) return;

    final sources = ops.map((o) => _norm(o.physicalOld)).toSet();
    final filtered = <_LocalRenameOp>[];
    for (final op in ops) {
      if (shouldStop()) return;
      final exists =
          FileSystemEntity.typeSync(op.physicalNew) !=
          FileSystemEntityType.notFound;
      if (exists && !sources.contains(_norm(op.physicalNew))) {
        acc.collision++;
        report(op.newName);
        continue;
      }
      filtered.add(op);
    }

    final needsTwoPhase = filtered.any(
      (o) => sources.contains(_norm(o.physicalNew)),
    );

    if (needsTwoPhase) {
      _applyTwoPhase(filtered, acc, report, shouldStop);
    } else {
      for (final op in filtered) {
        if (shouldStop()) return;
        _applyDirect(op, acc);
        report(op.newName);
      }
    }
  }

  void _applyDirect(_LocalRenameOp op, _MutableOutcome acc) {
    final r = FileSystemService.rename(op.physicalOld, op.newName);
    switch (r) {
      case RenameSuccess():
        acc.succeeded++;
      case RenameAlreadyExists():
        acc.collision++;
      case RenameInvalidName():
        acc.invalid++;
      case RenameError():
        acc.other++;
      case RenameNoChange():
        break;
    }
  }

  void _applyTwoPhase(
    List<_LocalRenameOp> ops,
    _MutableOutcome acc,
    void Function(String currentName) report,
    bool Function() shouldStop,
  ) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final staged = <({String tempPath, String finalName})>[];
    for (var i = 0; i < ops.length; i++) {
      if (shouldStop()) return;
      final op = ops[i];
      final tempName = '.waydir-rename-$stamp-$i.tmp';
      final dir = PlatformPaths.parentOf(op.physicalOld);
      final tempPath = '$dir${PlatformPaths.separator}$tempName';
      final r = FileSystemService.rename(op.physicalOld, tempName);
      if (r is RenameSuccess) {
        staged.add((tempPath: tempPath, finalName: op.newName));
      } else {
        switch (r) {
          case RenameAlreadyExists():
            acc.collision++;
          case RenameInvalidName():
            acc.invalid++;
          case RenameError():
            acc.other++;
          default:
            acc.other++;
        }
        report(op.newName);
      }
    }
    for (final s in staged) {
      if (shouldStop()) return;
      final r = FileSystemService.rename(s.tempPath, s.finalName);
      if (r is RenameSuccess) {
        acc.succeeded++;
      } else {
        acc.other++;
      }
      report(s.finalName);
    }
  }

  Future<void> _multiRenameSftp(
    List<({String path, String newName})> renames,
    _MutableOutcome acc,
    void Function(String currentName) report,
    bool Function() shouldStop,
  ) async {
    if (renames.isEmpty) return;
    final fs = const SftpFs();

    final ops = <_SftpRenameOp>[];
    for (final r in renames) {
      if (shouldStop()) return;
      if (!PlatformPaths.isValidFileName(r.newName)) {
        acc.invalid++;
        report(r.newName);
        continue;
      }
      final parent = PlatformPaths.parentOf(r.path);
      final newPath = '$parent/${r.newName}';
      if (r.path == newPath) {
        report(r.newName);
        continue;
      }
      ops.add(_SftpRenameOp(oldPath: r.path, newPath: newPath));
    }

    final sources = ops.map((o) => o.oldPath).toSet();
    final filtered = <_SftpRenameOp>[];
    for (final op in ops) {
      if (shouldStop()) return;
      if (sources.contains(op.newPath)) {
        filtered.add(op);
        continue;
      }
      if (await fs.exists(op.newPath)) {
        acc.collision++;
        report(PlatformPaths.fileName(op.newPath));
        continue;
      }
      filtered.add(op);
    }

    final needsTwoPhase = filtered.any((o) => sources.contains(o.newPath));
    if (!needsTwoPhase) {
      for (final op in filtered) {
        if (shouldStop()) return;
        try {
          await fs.rename(op.oldPath, op.newPath);
          acc.succeeded++;
        } catch (e, st) {
          log.warn('navigation', 'rename failed', error: e, stack: st);
          acc.other++;
        }
        report(PlatformPaths.fileName(op.newPath));
      }

      return;
    }

    final stamp = DateTime.now().millisecondsSinceEpoch;
    final staged = <({String tempPath, String finalPath})>[];
    for (var i = 0; i < filtered.length; i++) {
      if (shouldStop()) return;
      final op = filtered[i];
      final tempPath =
          '${PlatformPaths.parentOf(op.oldPath)}/.waydir-rename-$stamp-$i.tmp';
      try {
        await fs.rename(op.oldPath, tempPath);
        staged.add((tempPath: tempPath, finalPath: op.newPath));
      } catch (e, st) {
        log.warn('navigation', 'rename staging failed', error: e, stack: st);
        acc.other++;
        report(PlatformPaths.fileName(op.newPath));
      }
    }
    for (final s in staged) {
      if (shouldStop()) return;
      try {
        await fs.rename(s.tempPath, s.finalPath);
        acc.succeeded++;
      } catch (e, st) {
        log.warn(
          'navigation',
          'rename finalization failed',
          error: e,
          stack: st,
        );
        acc.other++;
      }
      report(PlatformPaths.fileName(s.finalPath));
    }
  }

  void _multiRenameArchive(
    List<({ArchiveLocation loc, String oldPath, String newName})> renames,
    _MutableOutcome acc,
    void Function(String currentName) report,
    bool Function() shouldStop,
  ) {
    for (final r in renames) {
      if (shouldStop()) return;
      if (!PlatformPaths.isValidFileName(r.newName)) {
        acc.invalid++;
        report(r.newName);
        continue;
      }
      operationStore.enqueueArchiveEdit(
        archivePath: r.loc.archivePath,
        displayDir: currentPath.value,
        renameFromInner: r.loc.innerPath,
        renameToName: r.newName,
      );
      acc.succeeded++;
      report(r.newName);
    }
  }

  String _norm(String path) =>
      PlatformPaths.isWindows ? path.toLowerCase() : path;

  Future<void> _commitCreate(String name) async {
    final pending = pendingCreate.value;
    if (pending == null) return;
    if (!PlatformPaths.isValidFileName(name)) {
      renameError.value = t.toast.renameInvalidName;
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    final dir = currentPath.value;
    final physicalDir = _physical(dir);
    final physicalNewPath = PlatformPaths.join(physicalDir, name);
    final logicalNewPath = PlatformPaths.isSmbUri(dir)
        ? '$dir/$name'
        : physicalNewPath;
    final exists = PlatformPaths.isSftpUri(physicalNewPath)
        ? await FsWorkerPool.instance.stat(physicalNewPath) != null
        : FileSystemEntity.typeSync(physicalNewPath) !=
              FileSystemEntityType.notFound;
    if (exists) {
      renameError.value = t.toast.renameAlreadyExists(name: name);
      renameAttempt.value = renameAttempt.value + 1;

      return;
    }
    try {
      await FileSystemService.createDirectory(physicalNewPath);
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
    final idx = _vf.indexWhere((f) => f.path == logicalNewPath);
    if (idx >= 0) {
      batch(() {
        selectedPaths.value = {logicalNewPath};
        cursorIndex.value = idx;
        anchorIndex.value = idx;
      });
    }
    fileListFocusRequest.value++;
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

  void revealInFolder(String path, {String? enteredPath}) {
    final parent = PlatformPaths.parentOf(path);
    if (parent.isEmpty) return;
    closeSearch();
    navigateTo(parent, enteredPath: enteredPath);
    selectedPaths.value = {path};
  }

  void onOpen(FileEntry entry) => unawaited(_openEntry(entry));

  Future<void> _openEntry(FileEntry entry) async {
    if (entry.type == FileItemType.folder) {
      if (PlatformPaths.isWindows &&
          currentPath.value == kTrashPath &&
          isTrashPath(entry.path)) {
        return;
      }
      navigateTo(entry.path);

      return;
    }
    final loc = await _archiveLocationFor(entry.path);
    if (loc != null) {
      if (loc.isRoot) {
        navigateTo(entry.path);
      } else {
        await FileSystemService.openArchiveEntry(loc);
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
    unawaited(_openEntry(entry));
  }

  void selectAll() {
    selectedPaths.value = Set<String>.from(_vf.map((f) => f.path));
  }

  List<String> selectedNamesForFile() {
    final selected = selectedPaths.value;
    if (selected.isEmpty) return const [];

    return [
      for (final entry in _vf)
        if (selected.contains(entry.path)) entry.name,
    ];
  }

  int selectNamesFromFile(Iterable<String> names) {
    final wanted = names
        .map(
          (name) =>
              name.endsWith('\r') ? name.substring(0, name.length - 1) : name,
        )
        .map((name) => name.startsWith('\uFEFF') ? name.substring(1) : name)
        .where((name) => name.isNotEmpty)
        .toSet();
    if (wanted.isEmpty) {
      deselectAll();

      return 0;
    }
    final matched = <String>{};
    var cursor = -1;
    for (var i = 0; i < _vf.length; i++) {
      final entry = _vf[i];
      if (!wanted.contains(entry.name)) continue;
      matched.add(entry.path);
      cursor = cursor < 0 ? i : cursor;
    }
    batch(() {
      selectedPaths.value = matched;
      cursorIndex.value = cursor;
      anchorIndex.value = cursor;
    });

    return matched.length;
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
      re = RegExp('^(?:${alternatives.join('|')})\$', caseSensitive: false);
    } catch (e) {
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

  void deleteSelected({bool? toTrash}) async {
    if (isTrashView) return;
    final entries = selectedEntries;
    if (entries.isEmpty) return;
    final paths = entries.map((e) => e.realPath).toList();
    batch(() {
      selectedPaths.value = {};
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    final archiveLoc = await _archiveLocationFor(currentPath.value);
    if (archiveLoc != null) {
      final inner = <String>[];
      for (final e in entries) {
        final loc = await _archiveLocationFor(e.path);
        if (loc != null && !loc.isRoot) inner.add(loc.innerPath);
      }
      operationStore.enqueueArchiveEdit(
        archivePath: archiveLoc.archivePath,
        displayDir: currentPath.value,
        deleteInner: inner,
      );

      return;
    }
    final hasNetworkPath = entries.any(
      (entry) => PlatformPaths.isNetworkPath(entry.realPath),
    );
    final useTrash = !hasNetworkPath && (toTrash ?? false);
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
    final entries = selectedEntries;
    if (entries.isEmpty) return;
    final logical = entries.map((e) => e.path).toList();
    final physical = entries.map((e) => e.realPath).toList();
    batch(() {
      clipboardPaths.value = Set<String>.from(logical);
      clipboardMode.value = ClipboardMode.copy;
    });
    if (!physical.any(PlatformPaths.isSftpUri)) {
      await FileClipboard.writeFiles(physical, isCut: false);
    }
  }

  void cutSelected() async {
    if (isTrashView) return;
    final entries = selectedEntries;
    if (entries.isEmpty) return;
    final logical = entries.map((e) => e.path).toList();
    final physical = entries.map((e) => e.realPath).toList();
    batch(() {
      clipboardPaths.value = Set<String>.from(logical);
      clipboardMode.value = ClipboardMode.cut;
    });
    if (!physical.any(PlatformPaths.isSftpUri)) {
      await FileClipboard.writeFiles(physical, isCut: true);
    }
  }

  Future<void> dropFiles(
    List<String> sourcePaths,
    String destination, {
    bool move = false,
  }) async {
    if (isTrashPath(destination)) return;
    final sep = PlatformPaths.isSftpUri(destination)
        ? '/'
        : PlatformPaths.separator;
    final filtered = sourcePaths.where((s) {
      final parent = PlatformPaths.parentOf(s);
      if (parent == destination) return false;
      if (destination == s) return false;
      if (destination.startsWith('$s$sep')) return false;

      return true;
    }).toList();
    if (filtered.isEmpty) return;
    final archiveLoc = await _archiveLocationFor(destination);
    if (archiveLoc != null) {
      operationStore.enqueueArchiveEdit(
        archivePath: archiveLoc.archivePath,
        displayDir: destination,
        addSources: _physicalList(filtered),
        addInner: archiveLoc.innerPath,
      );

      return;
    }
    final physicalDest = await _resolvePhysicalDestination(destination);
    if (physicalDest == null) return;
    final physicalSources = _physicalList(filtered);
    if (move) {
      operationStore.enqueueMove(physicalSources, physicalDest);
    } else {
      operationStore.enqueueCopy(physicalSources, physicalDest);
    }
  }

  Future<bool> hasPasteableFiles() async {
    if (canPaste.value) return true;
    if (isTrashView) return false;
    final paths = await FileClipboard.readFilePaths();

    return paths.isNotEmpty;
  }

  void paste() async {
    if (isTrashView) return;
    final internalPaths = Set<String>.from(clipboardPaths.value);
    final internalCut = clipboardMode.value == ClipboardMode.cut;

    var paths = await FileClipboard.readFilePaths();
    if (paths.isEmpty && internalPaths.isNotEmpty) {
      paths = internalPaths.toList();
    }
    if (paths.isEmpty) return;

    final samePaths =
        internalPaths.length == paths.length &&
        internalPaths.containsAll(paths.toSet());

    bool isCut = samePaths && internalCut;
    if (!isCut) isCut = await FileClipboard.isCutOperation();

    final sep = PlatformPaths.isSftpUri(currentPath.value)
        ? '/'
        : PlatformPaths.separator;
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

    final archiveLoc = await _archiveLocationFor(currentPath.value);
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

    final physicalDest = await _resolvePhysicalDestination(currentPath.value);
    if (physicalDest == null) return;
    if (isCut) {
      operationStore.enqueueMove(filteredPaths, physicalDest);
      if (samePaths) {
        batch(() {
          clipboardPaths.value = {};
          clipboardMode.value = null;
        });
      }
    } else {
      operationStore.enqueueCopy(filteredPaths, physicalDest);
    }
  }

  void jumpToIndex(int index) {
    batch(() {
      if (_vf.isEmpty) return;
      if (index < 0 || index >= _vf.length) return;
      cursorIndex.value = index;
      anchorIndex.value = index;
      selectedPaths.value = {_vf[index].path};
    });
  }

  void setPageRows(int rows) {
    if (rows > 0) _pageRows = rows;
  }

  void setGridColumns(int columns) {
    if (columns > 0) gridColumns.value = columns;
  }

  void moveCursorHorizontally(int delta) {
    final settings = SettingsStore.instance;
    if (settings.fileViewMode.value != 'grid') {
      moveCursor(delta);

      return;
    }
    if (_vf.isEmpty || delta == 0) return;
    if (cursorIndex.value < 0) {
      _initCursor(delta > 0 ? 0 : _vf.length - 1);

      return;
    }
    final columns = gridColumns.value.clamp(1, 1000);
    final col = cursorIndex.value % columns;
    if (delta < 0 && col == 0) return;
    if (delta > 0 && col == columns - 1) return;
    final next = cursorIndex.value + delta;
    if (next < 0 || next >= _vf.length) return;
    _applyCursorMove(next);
  }

  void moveCursor(int delta) {
    final settings = SettingsStore.instance;
    final step = settings.fileViewMode.value == 'grid' && delta.abs() == 1
        ? delta * gridColumns.value.clamp(1, 1000)
        : delta;
    if (_vf.isEmpty) return;
    if (cursorIndex.value < 0) {
      _initCursor(step > 0 ? 0 : _vf.length - 1);

      return;
    }
    final next = cursorIndex.value + step;
    if (next < 0 || next >= _vf.length) return;
    _applyCursorMove(next);
  }

  void moveCursorByPage(int dir) {
    if (_vf.isEmpty) return;
    if (cursorIndex.value < 0) {
      _initCursor(dir > 0 ? 0 : _vf.length - 1);

      return;
    }
    final step = (_pageRows * 0.8).floor().clamp(1, _pageRows);
    final next = (cursorIndex.value + dir * step).clamp(0, _vf.length - 1);
    if (next == cursorIndex.value) return;
    _applyCursorMove(next);
  }

  void _initCursor(int index) {
    batch(() {
      cursorIndex.value = index;
      anchorIndex.value = index;
      selectedPaths.value = {_vf[index].path};
    });
  }

  void _applyCursorMove(int next) {
    final shift = HardwareKeyboard.instance.isShiftPressed;
    batch(() {
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

class _FolderState {
  final Set<String> selectedPaths;
  final String? cursorPath;

  _FolderState({required this.selectedPaths, required this.cursorPath});
}

class MultiRenameOutcome {
  final int succeeded;
  final int invalid;
  final int collision;
  final int other;
  final bool blocked;

  const MultiRenameOutcome({
    required this.succeeded,
    required this.invalid,
    required this.collision,
    required this.other,
    this.blocked = false,
  });

  const MultiRenameOutcome.empty()
    : succeeded = 0,
      invalid = 0,
      collision = 0,
      other = 0,
      blocked = false;

  int get failed => invalid + collision + other;
  int get total => succeeded + failed;
}

typedef MultiRenameProgressCallback =
    void Function(int processed, int total, String currentName);

class _MutableOutcome {
  int succeeded = 0;
  int invalid = 0;
  int collision = 0;
  int other = 0;

  MultiRenameOutcome freeze() => MultiRenameOutcome(
    succeeded: succeeded,
    invalid: invalid,
    collision: collision,
    other: other,
  );
}

class _LocalRenameOp {
  final String physicalOld;
  final String physicalNew;
  final String newName;

  const _LocalRenameOp({
    required this.physicalOld,
    required this.physicalNew,
    required this.newName,
  });
}

class _SftpRenameOp {
  final String oldPath;
  final String newPath;

  const _SftpRenameOp({required this.oldPath, required this.newPath});
}
