part of '../waydir_shell.dart';

const _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

mixin _WaydirKeyboardMixin
    on
        State<WaydirShell>,
        _WaydirStateBase,
        _WaydirActionsMixin,
        _WaydirTerminalMixin,
        _WaydirMenuMixin {
  bool _acceptCursorRepeat() {
    final now = DateTime.now();
    final last = _lastCursorRepeatAt;
    if (last != null && now.difference(last) < _cursorRepeatInterval) {
      return false;
    }
    _lastCursorRepeatAt = now;

    return true;
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final isRepeat = event is KeyRepeatEvent;
    if (event is! KeyDownEvent && !isRepeat) return KeyEventResult.ignored;
    if (!_shell.ready.value || _shell.activeStore.value == null) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final ctrl = AppShortcuts.isControl;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;

    if (!_isModalRouteOnTop() && AppShortcuts.matches('preferences', key)) {
      _openPreferences();

      return KeyEventResult.handled;
    }

    if (!_isModalRouteOnTop() && key == LogicalKeyboardKey.f1) {
      _openHelp();

      return KeyEventResult.handled;
    }

    if (!_isModalRouteOnTop() &&
        ctrl &&
        !alt &&
        event.physicalKey == AppShortcuts.terminalTogglePhysicalKey) {
      if (shift) {
        _toggleTerminal();
      } else {
        _focusTerminal();
      }

      return KeyEventResult.handled;
    }

    if (_isEditableFocused() || _isModalRouteOnTop() || _isTerminalFocused()) {
      return KeyEventResult.ignored;
    }

    for (final c in PluginStore.instance.shortcutContributions()) {
      if (AppShortcuts.matches(c.fullActionId, key)) {
        _runPluginAction(c.fullActionId);

        return KeyEventResult.handled;
      }
    }

    if (AppShortcuts.matches('toggle_dual', key)) {
      _shell.toggleDual();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('toggle_sidebar', key)) {
      final s = SettingsStore.instance.sidebarCollapsed;
      s.value = !s.value;

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('toggle_hidden', key)) {
      _toggleShowHiddenGlobal();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('toggle_view', key)) {
      final mode = SettingsStore.instance.fileViewMode;
      mode.value = mode.value == 'grid' ? 'list' : 'grid';

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('focus_path', key)) {
      _active.focusPathBar();

      return KeyEventResult.handled;
    }

    final settings = SettingsStore.instance;
    if (AppShortcuts.matches('file_list_zoom_in', key)) {
      settings.increaseFileListScale();

      return KeyEventResult.handled;
    }
    if (AppShortcuts.matches('file_list_zoom_out', key)) {
      settings.decreaseFileListScale();

      return KeyEventResult.handled;
    }
    if (AppShortcuts.matches('file_list_zoom_reset', key)) {
      settings.resetFileListScale();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('switch_pane', key) && _shell.isDual.value) {
      final idx = _shell.activePaneIndex.value;
      _shell.setActivePane(1 - idx);

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('new_tab', key)) {
      _shell.activePane.value!.tabs.addTab(_active.currentPath.value);

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('close_tab', key)) {
      final tabsStore = _shell.activePane.value!.tabs;
      final tab = tabsStore.activeTab.value;
      if (tabsStore.tabs.value.length > 1) {
        tabsStore.closeTab(tab.id);
      }

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('next_tab', key)) {
      final tabsStore = _shell.activePane.value!.tabs;
      final idx = tabsStore.activeIndex.value;
      final next = (idx + 1) % tabsStore.tabs.value.length;
      tabsStore.selectTab(next);

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('prev_tab', key)) {
      final tabsStore = _shell.activePane.value!.tabs;
      final idx = tabsStore.activeIndex.value;
      final prev =
          (idx - 1 + tabsStore.tabs.value.length) % tabsStore.tabs.value.length;
      tabsStore.selectTab(prev);

      return KeyEventResult.handled;
    }

    if (ctrl) {
      final digitIdx = _digitKeys.indexOf(key);
      if (digitIdx >= 0) {
        if (shift) {
          final bookmarks = BookmarkStore.instance.bookmarks.value;
          if (digitIdx < bookmarks.length) {
            _active.navigateTo(bookmarks[digitIdx].path);
          }

          return KeyEventResult.handled;
        }
        _shell.activePane.value!.tabs.selectTab(digitIdx);

        return KeyEventResult.handled;
      }
    }

    final store = _active;
    final gridMode = SettingsStore.instance.fileViewMode.value == 'grid';

    if (isRepeat) {
      if (gridMode && !ctrl && !alt && key == LogicalKeyboardKey.arrowRight) {
        if (!_acceptCursorRepeat()) return KeyEventResult.handled;
        store.moveCursorHorizontally(1);

        return KeyEventResult.handled;
      }

      if (gridMode && !ctrl && !alt && key == LogicalKeyboardKey.arrowLeft) {
        if (!_acceptCursorRepeat()) return KeyEventResult.handled;
        store.moveCursorHorizontally(-1);

        return KeyEventResult.handled;
      }

      if (AppShortcuts.matchesIgnoreShift('cursor_down', key)) {
        if (!_acceptCursorRepeat()) return KeyEventResult.handled;
        store.moveCursor(1);

        return KeyEventResult.handled;
      }

      if (AppShortcuts.matchesIgnoreShift('cursor_up', key)) {
        if (!_acceptCursorRepeat()) return KeyEventResult.handled;
        store.moveCursor(-1);

        return KeyEventResult.handled;
      }

      if (AppShortcuts.matchesIgnoreShift('page_down', key)) {
        if (!_acceptCursorRepeat()) return KeyEventResult.handled;
        store.moveCursorByPage(1);

        return KeyEventResult.handled;
      }

      if (AppShortcuts.matchesIgnoreShift('page_up', key)) {
        if (!_acceptCursorRepeat()) return KeyEventResult.handled;
        store.moveCursorByPage(-1);

        return KeyEventResult.handled;
      }

      if (AppShortcuts.matchesIgnoreShift('home', key)) {
        if (!_acceptCursorRepeat()) return KeyEventResult.handled;
        store.moveCursorToStart();

        return KeyEventResult.handled;
      }

      if (AppShortcuts.matchesIgnoreShift('end', key)) {
        if (!_acceptCursorRepeat()) return KeyEventResult.handled;
        store.moveCursorToEnd();

        return KeyEventResult.handled;
      }

      return KeyEventResult.ignored;
    }

    if (AppShortcuts.matches('quick_look', key)) {
      _openQuickLook();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('help', key)) {
      _openHelp();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('recursive_search', key)) {
      store.openSearch(recursive: true);

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('search', key)) {
      store.openSearch();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('close_search', key) && store.searchActive.value) {
      store.closeSearch();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('select_pattern', key)) {
      _openSelectPattern();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('save_selection', key)) {
      _saveSelectionToFile();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('load_selection', key)) {
      _loadSelectionFromFile();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('copy', key)) {
      store.copySelected();
      final count = store.selectedPaths.value.length;
      if (count > 0) {
        showToast(
          context: context,
          message: t.toast.copiedItems(count: count),
        );
      }

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('cut', key)) {
      store.cutSelected();
      final count = store.selectedPaths.value.length;
      if (count > 0) {
        showToast(
          context: context,
          message: t.toast.cutItems(count: count),
        );
      }

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('paste', key)) {
      store.paste();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('insert_relative_paths', key)) {
      unawaited(_insertPathsIntoTerminal(absolute: false));

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('insert_absolute_paths', key)) {
      unawaited(_insertPathsIntoTerminal(absolute: true));

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('open_item', key)) {
      store.openSelected();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('select_all', key)) {
      store.selectAll();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('deselect_all', key) &&
        !store.searchActive.value) {
      store.deselectAll();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('invert_selection', key)) {
      store.invertSelection();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('toggle_select', key)) {
      store.toggleSelectAndAdvance();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('go_up', key)) {
      store.goUp();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('dual_copy', key)) {
      if (_shell.isDual.value) {
        unawaited(_dualPaneTransfer(store, move: false));
      } else {
        store.refresh();
      }

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('new_folder', key)) {
      store.startCreate();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('dual_move', key) && _shell.isDual.value) {
      unawaited(_dualPaneTransfer(store, move: true));

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('go_back', key)) {
      store.goBack();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('go_forward', key)) {
      store.goForward();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('refresh', key)) {
      store.refresh();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matchesIgnoreShift('delete', key)) {
      _confirmAndDelete(forcePermanent: shift);

      return KeyEventResult.handled;
    }

    if (gridMode && !ctrl && !alt && key == LogicalKeyboardKey.arrowRight) {
      _lastCursorRepeatAt = null;
      store.moveCursorHorizontally(1);

      return KeyEventResult.handled;
    }

    if (gridMode && !ctrl && !alt && key == LogicalKeyboardKey.arrowLeft) {
      _lastCursorRepeatAt = null;
      store.moveCursorHorizontally(-1);

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matchesIgnoreShift('cursor_down', key)) {
      _lastCursorRepeatAt = null;
      store.moveCursor(1);

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matchesIgnoreShift('cursor_up', key)) {
      _lastCursorRepeatAt = null;
      store.moveCursor(-1);

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matchesIgnoreShift('page_down', key)) {
      _lastCursorRepeatAt = null;
      store.moveCursorByPage(1);

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matchesIgnoreShift('page_up', key)) {
      _lastCursorRepeatAt = null;
      store.moveCursorByPage(-1);

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matchesIgnoreShift('home', key)) {
      _lastCursorRepeatAt = null;
      store.moveCursorToStart();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matchesIgnoreShift('end', key)) {
      _lastCursorRepeatAt = null;
      store.moveCursorToEnd();

      return KeyEventResult.handled;
    }

    if (AppShortcuts.matches('rename', key)) {
      if (store.selectedCount.value >= 2) {
        _multiRename(store);
      } else {
        store.startRename();
      }

      return KeyEventResult.handled;
    }

    if (!ctrl && !alt) {
      final ch = _typeAheadChar(event, key);
      if (ch != null) {
        _handleTypeAhead(store, ch);

        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  String? _typeAheadChar(KeyEvent event, LogicalKeyboardKey key) {
    final ch = event.character;
    if (ch == null || ch.isEmpty) return null;
    final code = ch.codeUnitAt(0);
    if (code < 0x20 || code == 0x7f) return null;
    if (key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.tab ||
        key == LogicalKeyboardKey.enter) {
      return null;
    }

    return ch.toLowerCase();
  }

  void _handleTypeAhead(NavigationStore store, String ch) {
    final files = store.visibleFiles.value;
    if (files.isEmpty) return;
    final bufferEnabled = SettingsStore.instance.typeAheadBuffer.value;
    final now = DateTime.now();
    final lastAt = _typeAheadLastAt;
    final withinWindow =
        lastAt != null && now.difference(lastAt) < _typeAheadResetAfter;
    final previous = withinWindow ? _typeAheadBuffer : '';

    int findFrom(String prefix, int start) {
      for (int i = 0; i < files.length; i++) {
        final idx = (start + i) % files.length;
        if (files[idx].name.toLowerCase().startsWith(prefix)) return idx;
      }

      return -1;
    }

    void commit(String buffer, int index) {
      _typeAheadBuffer = buffer;
      _typeAheadIndex = index;
      _typeAheadLastAt = now;
      store.jumpToIndex(index);
    }

    if (bufferEnabled && previous.isNotEmpty) {
      final extended = previous + ch;
      final hit = findFrom(extended, 0);
      if (hit >= 0) {
        commit(extended, hit);

        return;
      }
    }

    if (previous == ch) {
      final hit = findFrom(ch, (_typeAheadIndex + 1) % files.length);
      if (hit >= 0) {
        commit(ch, hit);

        return;
      }
    }

    final fresh = findFrom(ch, 0);
    if (fresh >= 0) {
      commit(ch, fresh);

      return;
    }

    _typeAheadBuffer = '';
    _typeAheadIndex = -1;
    _typeAheadLastAt = null;
  }
}
