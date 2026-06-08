part of '../waydir_shell.dart';

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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
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
      final digitKeys = [
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
      final digitIdx = digitKeys.indexOf(key);
      if (digitIdx >= 0) {
        _shell.activePane.value!.tabs.selectTab(digitIdx);
        return KeyEventResult.handled;
      }
    }

    final store = _active;

    if (isRepeat) {
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

    if (AppShortcuts.matches('rename', key)) {
      store.startRename();
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
    final now = DateTime.now();
    final lastAt = _typeAheadLastAt;
    final sameLetter =
        _typeAheadLetter == ch &&
        lastAt != null &&
        now.difference(lastAt) < _typeAheadResetAfter;

    int startFrom;
    if (sameLetter) {
      startFrom = (_typeAheadIndex + 1) % files.length;
    } else {
      startFrom = 0;
    }

    int found = -1;
    for (int i = 0; i < files.length; i++) {
      final idx = (startFrom + i) % files.length;
      final name = files[idx].name.toLowerCase();
      if (name.startsWith(ch)) {
        found = idx;
        break;
      }
    }
    if (found < 0) {
      _typeAheadLetter = null;
      _typeAheadIndex = -1;
      _typeAheadLastAt = null;
      return;
    }
    _typeAheadLetter = ch;
    _typeAheadIndex = found;
    _typeAheadLastAt = now;
    store.jumpToIndex(found);
  }
}
