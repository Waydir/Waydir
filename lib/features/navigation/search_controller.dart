import 'dart:async';

import 'package:signals/signals.dart';

import '../../core/fs/file_system_service.dart';
import '../../core/fs/recursive_search.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../locations/location_resolver.dart';
import 'filter_query.dart';

class SearchController {
  final String Function() currentPath;
  final List<FileEntry> Function() files;
  final bool Function() showHidden;
  final bool Function() isTagView;
  final Future<String?> Function(String logical) resolvePhysicalDestination;
  final List<FileEntry> Function(List<FileEntry> list, FilterQuery filter)
  filterByTags;
  final Signal<int> cursorIndex;
  final Signal<int> anchorIndex;

  final searchActive = signal(false);
  final searchQuery = signal('');
  final searchRecursive = signal(false);
  final searchContent = signal(false);
  final searchResults = signal<List<FileEntry>>([]);
  final isSearching = signal(false);
  final searchScannedDirs = signal(0);
  final searchCurrentDir = signal<String?>(null);
  final searchFocusRequest = signal(0);
  final searchPatternError = signal<String?>(null);

  SearchHandle? _searchHandle;
  Timer? _searchDebounce;
  Timer? _searchUiFlush;
  List<FileEntry>? _pendingSearchResults;
  int _searchToken = 0;
  static const _kSearchUiFlushMs = 180;

  SearchController({
    required this.currentPath,
    required this.files,
    required this.showHidden,
    required this.isTagView,
    required this.resolvePhysicalDestination,
    required this.filterByTags,
    required this.cursorIndex,
    required this.anchorIndex,
  });

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

  void setSearchQuery(String query) {
    batch(() {
      searchQuery.value = query;
      searchPatternError.value = validateSearchPattern(
        query.trim(),
        currentSearchMode(),
      );
      cursorIndex.value = -1;
      anchorIndex.value = -1;
    });
    scheduleRestart();
  }

  void toggleRecursive() {
    searchRecursive.value = !searchRecursive.value;
    scheduleRestart();
  }

  void toggleContent() {
    if (PlatformPaths.isSftpUri(currentPath())) return;
    if (SettingsStore.instance.searchMode.value == filterSearchMode) return;
    final enabling = !searchContent.value;
    batch(() {
      searchContent.value = enabling;
      if (enabling && SettingsStore.instance.searchMode.value == 'glob') {
        SettingsStore.instance.searchMode.value = 'substring';
        searchPatternError.value = validateSearchPattern(
          searchQuery.value.trim(),
          currentSearchMode(),
        );
      }
    });
    scheduleRestart();
  }

  void cycleSearchMode() {
    const order = ['substring', 'glob', 'regex', filterSearchMode];
    final settings = SettingsStore.instance;
    final index = order.indexOf(settings.searchMode.value);
    setSearchMode(order[((index < 0 ? 0 : index) + 1) % order.length]);
  }

  void setSearchMode(String mode) {
    final settings = SettingsStore.instance;
    if (mode == 'glob' && searchContent.value) return;
    if (settings.searchMode.value == mode) return;
    batch(() {
      settings.searchMode.value = mode;
      if (mode == filterSearchMode) searchContent.value = false;
      searchPatternError.value = validateSearchPattern(
        searchQuery.value.trim(),
        currentSearchMode(),
      );
    });
    scheduleRestart();
  }

  SearchMode currentSearchMode() {
    switch (SettingsStore.instance.searchMode.value) {
      case 'glob':
        return SearchMode.glob;
      case 'regex':
        return SearchMode.regex;
      default:
        return SearchMode.substring;
    }
  }

  static bool Function(String)? localMatcher(String query, SearchMode mode) {
    switch (mode) {
      case SearchMode.substring:
        final lowerQuery = query.toLowerCase();

        return (name) => name.toLowerCase().contains(lowerQuery);
      case SearchMode.regex:
        try {
          final regex = RegExp(query);

          return regex.hasMatch;
        } catch (e) {
          return null;
        }
      case SearchMode.glob:
        final regex = _globToRegExp(query);

        return regex?.hasMatch;
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
    final buffer = StringBuffer('^');
    var index = 0;
    while (index < glob.length) {
      final char = glob[index];
      if (char == '*') {
        if (index + 1 < glob.length && glob[index + 1] == '*') {
          buffer.write('.*');
          index += 2;
        } else {
          buffer.write('[^/]*');
          index++;
        }
      } else if (char == '?') {
        buffer.write('[^/]');
        index++;
      } else if (char == '[') {
        final end = glob.indexOf(']', index + 1);
        if (end < 0) return null;
        buffer.write(glob.substring(index, end + 1));
        index = end + 1;
      } else if ('.+()|^\$\\/'.contains(char)) {
        buffer.write('\\');
        buffer.write(char);
        index++;
      } else {
        buffer.write(char);
        index++;
      }
    }
    buffer.write('\$');
    try {
      return RegExp(buffer.toString(), caseSensitive: false);
    } catch (e) {
      return null;
    }
  }

  void scheduleRestart() {
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
    final query = searchQuery.value.trim();
    if (query.isEmpty) return;
    isSearching.value = true;
    final acc = <FileEntry>[];
    final mode = currentSearchMode();
    final error = validateSearchPattern(query, mode);
    searchPatternError.value = error;
    if (error != null) {
      isSearching.value = false;

      return;
    }
    if (isTagView()) {
      _searchTagView(query, mode);

      return;
    }
    final root = await resolvePhysicalDestination(currentPath());
    if (token != _searchToken) return;
    if (root == null) {
      isSearching.value = false;

      return;
    }
    final filter = SettingsStore.instance.searchMode.value == filterSearchMode
        ? parseFilterQuery(query).query
        : null;
    final recursiveQuery = filter?.recursiveNameQuery ?? query;
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
          : localMatcher(recursiveQuery, mode);
      if (matcher == null) {
        isSearching.value = false;

        return;
      }
      _runSftpRecursiveSearch(
        token: token,
        root: root,
        includeHidden: showHidden(),
        matcher: matcher,
        filter: filter,
      );

      return;
    }
    _searchHandle = RecursiveSearch.start(
      root: root,
      query: recursiveQuery,
      includeHidden: showHidden(),
      mode: mode,
      content: searchContent.value,
      maxDepth: searchRecursive.value ? 0 : 1,
      onBatch: (batchEntries) {
        if (token != _searchToken) return;
        final entries = batchEntries.map(_logicalEntryFromPhysical);
        acc.addAll(filter == null ? entries : entries.where(filter.matches));
        _pendingSearchResults = acc;
        _scheduleSearchUiFlush();
      },
      onProgress: (count, currentDir) {
        if (token != _searchToken) return;
        batch(() {
          searchScannedDirs.value = count;
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

  void _searchTagView(String query, SearchMode mode) {
    final filter = SettingsStore.instance.searchMode.value == filterSearchMode
        ? parseFilterQuery(query).query
        : null;
    final nameQuery = filter?.recursiveNameQuery ?? query;
    final matcher = filter != null && nameQuery.isEmpty
        ? (String _) => true
        : localMatcher(nameQuery, mode);
    var results = matcher == null
        ? const <FileEntry>[]
        : files().where((file) => matcher(file.name)).toList();
    if (filter != null) {
      results = filterByTags(results.where(filter.matches).toList(), filter);
    }
    batch(() {
      searchResults.value = results;
      isSearching.value = false;
    });
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
      final pending = _pendingSearchResults;
      if (pending == null) return;
      _pendingSearchResults = null;
      searchResults.value = List.of(pending);
    });
  }

  void dispose() {
    _searchDebounce?.cancel();
    _searchUiFlush?.cancel();
    _searchHandle?.cancel();
  }
}
