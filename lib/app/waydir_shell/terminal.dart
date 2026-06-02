part of '../waydir_shell.dart';

mixin _WaydirTerminalMixin on State<WaydirShell>, _WaydirStateBase {
  void _focusTerminal() {
    final slot = _terminalSlotForActivePane();
    _terminalInteractionAt = DateTime.now();
    var active = _shell.activeTerminalForSlot(slot);
    if (active == null) {
      active = _openTerminalTab(slot);
      if (active == null) return;
    }
    final visible = _shell.terminalVisible.value[slot];
    if (visible) {
      _shell.setActiveTerminal(slot, active.id);
      active.focusNode.requestFocus();
      return;
    }
    _shell.setTerminalVisible(slot, true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _shell.setActiveTerminal(slot, active!.id);
      active.focusNode.requestFocus();
    });
  }

  void _openInTerminal(String directory) {
    if (SettingsStore.instance.terminal.value == 'builtin') {
      _openBuiltinTerminalAt(directory);
    } else {
      FileSystemService.openInTerminal(directory);
    }
  }

  void _openBuiltinTerminalAt(String directory) {
    final slot = _terminalSlotForActivePane();
    _terminalInteractionAt = DateTime.now();
    if (_shell.isDual.value) _shell.setActivePane(slot);
    final tab = _shell.openTerminal(slot, directory);
    if (tab == null) {
      showToast(context: context, message: t.toast.terminalUnavailable);
      return;
    }
    if (!_shell.terminalVisible.value[slot]) {
      _shell.setTerminalVisible(slot, true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _shell.setActiveTerminal(slot, tab.id);
      tab.focusNode.requestFocus();
    });
  }

  void _toggleTerminal() {
    final slot = _terminalSlotForActivePane();
    _toggleTerminalSlot(slot);
  }

  void _toggleTerminalSlot(int slot) {
    if (_shell.terminalVisible.value[slot]) {
      _shell.setTerminalVisible(slot, false);
      _restoreFocus();
      return;
    }
    if (_shell.isDual.value) _shell.setActivePane(slot);
    _focusTerminal();
  }

  int _terminalSlotForActivePane() {
    return _shell.isDual.value ? _shell.activePaneIndex.value : 0;
  }

  TerminalTab? _openTerminalTab(int slot) {
    final pane = _shell.panes.value[slot];
    final cwd = pane.tabs.activeTab.value.store.currentPath.value;
    final tab = _shell.openTerminal(slot, cwd);
    if (tab == null) {
      showToast(context: context, message: t.toast.terminalUnavailable);
    }
    return tab;
  }

  void _newTerminalTab(int slot) {
    _terminalInteractionAt = DateTime.now();
    final tab = _openTerminalTab(slot);
    if (tab == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      tab.focusNode.requestFocus();
    });
  }

  void _closeTerminalTab(int id) {
    final wasFocused = _isTerminalFocused();
    _shell.closeTerminalTab(id);
    if (wasFocused && !_isTerminalFocused()) _focusFiles();
  }

  void _selectTerminalTab(int slot, int id) {
    _terminalInteractionAt = DateTime.now();
    _shell.setActiveTerminal(slot, id);
    final tab = _shell.activeTerminalForSlot(slot);
    tab?.focusNode.requestFocus();
  }

  void _cycleTerminalTab(int slot, int dir) {
    _terminalInteractionAt = DateTime.now();
    _shell.cycleTerminal(slot, dir);
    final tab = _shell.activeTerminalForSlot(slot);
    tab?.focusNode.requestFocus();
  }

  void _setTerminalHeight(int slot, double height) {
    _shell.setTerminalHeight(slot, height);
  }

  void _activateTerminal(int slot, int id) {
    if (_shell.isDual.value) _shell.setActivePane(slot);
    _terminalInteractionAt = DateTime.now();
    _shell.setActiveTerminal(slot, id);
    final tab = _shell.activeTerminalForSlot(slot);
    tab?.focusNode.requestFocus();
  }
}
