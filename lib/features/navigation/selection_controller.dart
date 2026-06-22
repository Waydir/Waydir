import 'package:flutter/services.dart';
import 'package:signals/signals.dart';

import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../core/models/file_entry.dart';
import '../../core/settings/settings_store.dart';

class SelectionController {
  final Signal<Set<String>> selectedPaths;
  final Signal<int> cursorIndex;
  final Signal<int> anchorIndex;
  final Signal<int> gridColumns;
  final List<FileEntry> Function() visibleFiles;

  int _pageRows = 10;

  SelectionController({
    required this.selectedPaths,
    required this.cursorIndex,
    required this.anchorIndex,
    required this.gridColumns,
    required this.visibleFiles,
  });

  List<FileEntry> get _vf => visibleFiles();

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

  void invertSelection() {
    final selected = selectedPaths.value;
    selectedPaths.value = Set<String>.from(
      _vf.where((f) => !selected.contains(f.path)).map((f) => f.path),
    );
  }

  void toggleSelectAndAdvance() {
    batch(() {
      if (cursorIndex.value >= 0 && cursorIndex.value < _vf.length) {
        final path = _vf[cursorIndex.value].path;
        final paths = Set<String>.from(selectedPaths.value);
        if (paths.contains(path) && paths.length > 1) {
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

  void onContextMenu(FileSelectionEvent event) {
    if (!selectedPaths.value.contains(event.entry.path)) {
      batch(() {
        selectedPaths.value = {event.entry.path};
        cursorIndex.value = event.index;
        anchorIndex.value = event.index;
      });
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

  void moveCursorToStart() {
    if (_vf.isEmpty) return;
    if (cursorIndex.value < 0) {
      _initCursor(0);

      return;
    }
    _applyCursorMove(0);
  }

  void moveCursorToEnd() {
    if (_vf.isEmpty) return;
    final last = _vf.length - 1;
    if (cursorIndex.value < 0) {
      _initCursor(last);

      return;
    }
    _applyCursorMove(last);
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
        final cur = cursorIndex.value;
        final extending = (next - anchor).abs() > (cur - anchor).abs();
        if (cur >= 0 &&
            cur < _vf.length &&
            !selectedPaths.value.contains(_vf[cur].path) &&
            extending) {
          final lo = cur < anchor ? cur : anchor;
          final hi = cur < anchor ? anchor : cur;
          final paths = Set<String>.from(selectedPaths.value);
          for (int i = lo; i <= hi; i++) {
            paths.add(_vf[i].path);
          }
          selectedPaths.value = paths;

          return;
        }
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
