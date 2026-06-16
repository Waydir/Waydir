part of '../waydir_shell.dart';

mixin _WaydirTerminalMixin on State<WaydirShell>, _WaydirStateBase {
  TerminalLaunchSpec? _autoWslSpec(String cwd) {
    final wsl = parseWslPath(cwd);

    return wsl != null ? TerminalLaunch.forWsl(wsl.distro, cwd) : null;
  }

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
    final tab = _shell.openTerminal(
      slot,
      directory,
      spec: _autoWslSpec(directory),
    );
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
    final tab = _shell.openTerminal(slot, cwd, spec: _autoWslSpec(cwd));
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

  void _newTerminalTabMenu(int slot, Offset position) {
    final cwd =
        _shell.panes.value[slot].tabs.activeTab.value.store.currentPath.value;
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: WaydirIconsRegular.magicWand,
        label: t.preferences.terminal.shellSystem,
        action: 'shell:',
      ),
      for (final shell in ShellDetector.detect())
        ContextMenuItem(
          icon: WaydirIconsRegular.terminal,
          label: shell.label,
          action: 'shell:${shell.path}',
        ),
    ];
    final distributions = containerStore.distributions.value;
    if (distributions.isNotEmpty) {
      items.add(ContextMenuItem.divider);
      for (final dist in distributions) {
        items.add(
          ContextMenuItem(
            icon: distroIconFor(dist.name),
            label: dist.name,
            action: 'wsl:${dist.name}',
          ),
        );
      }
    }
    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: (action) {
        TerminalLaunchSpec spec;
        if (action.startsWith('wsl:')) {
          spec = TerminalLaunch.forWsl(action.substring(4), cwd);
        } else if (action.startsWith('shell:')) {
          spec = TerminalLaunch.forShell(action.substring(6), cwd);
        } else {
          return;
        }
        _openTerminalWithSpec(slot, cwd, spec);
      },
    );
  }

  void _openTerminalWithSpec(int slot, String cwd, TerminalLaunchSpec spec) {
    _terminalInteractionAt = DateTime.now();
    if (_shell.isDual.value) _shell.setActivePane(slot);
    final tab = _shell.openTerminal(slot, cwd, spec: spec);
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

  Future<void> _insertPathsIntoTerminal({required bool absolute}) async {
    final slot = _terminalSlotForActivePane();
    final tab = _shell.activeTerminalForSlot(slot);
    if (!_shell.terminalVisible.value[slot] || tab == null) {
      showToast(context: context, message: t.toast.terminalNotVisible);

      return;
    }

    final store = _active;
    final selected = store.selectedEntries;
    final entries = selected.length > 1
        ? selected
        : [if (store.cursorEntry.value != null) store.cursorEntry.value!];
    if (entries.isEmpty) return;

    final values = entries
        .map(
          (entry) =>
              absolute ? entry.path : _relativeTerminalPath(entry, tab.cwd),
        )
        .map(_shellQuote)
        .toList();

    String separator = ' ';
    if (values.length > 1) {
      final result = await _confirmMultiPathInsert(
        count: values.length,
        values: values,
      );
      if (result == null) return;
      separator = result;
    }

    tab.session.writeInput(values.join(separator));
    _shell.setActiveTerminal(slot, tab.id);
    tab.focusNode.requestFocus();
  }

  String _relativeTerminalPath(FileEntry entry, String cwd) {
    final sep = PlatformPaths.isNetworkPath(cwd)
        ? '/'
        : PlatformPaths.separator;
    final prefix = cwd.endsWith(sep) ? cwd : '$cwd$sep';
    if (entry.path.startsWith(prefix)) {
      return entry.path.substring(prefix.length);
    }

    if (!PlatformPaths.isNetworkPath(cwd) &&
        !PlatformPaths.isNetworkPath(entry.path)) {
      return p.relative(entry.path, from: cwd);
    }

    return entry.path;
  }

  String _shellQuote(String value) {
    if (value.isEmpty) return "''";
    if (!RegExp(r'''[\s'"`$\\|&;()<>*?!\[\]{}]''').hasMatch(value)) {
      return value;
    }

    return "'${value.replaceAll("'", r"'\''")}'";
  }

  String _pathPreview(List<String> values, String separator) {
    const limit = 10;
    final shown = values.take(limit).join(separator);
    if (values.length <= limit) return shown;

    return '$shown\n... and ${values.length - limit} more';
  }

  Future<String?> _confirmMultiPathInsert({
    required int count,
    required List<String> values,
  }) async {
    var separator = ' ';
    final result = await showCustomDialog<String>(
      context: context,
      title: t.terminalInsert.title(count: count),
      icon: WaydirIconsRegular.terminal,
      iconColor: AppColors.accent,
      width: 460,
      body: _TerminalInsertBody(
        values: values,
        previewBuilder: (values, value) =>
            _pathPreview(values, _decodeSeparator(value)),
        onSeparatorChanged: (value) => separator = _decodeSeparator(value),
      ),
      actions: [
        DialogAction(label: t.dialog.cancel, color: AppColors.fgMuted),
        DialogAction(label: t.terminalInsert.insert, color: AppColors.accent),
      ],
    );
    if (result != t.terminalInsert.insert) {
      return null;
    }

    return separator;
  }

  String _decodeSeparator(String value) {
    return value
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t')
        .replaceAll(r'\r', '\r');
  }
}

class _TerminalInsertBody extends StatefulWidget {
  final List<String> values;
  final String Function(List<String> values, String separator) previewBuilder;
  final ValueChanged<String> onSeparatorChanged;

  const _TerminalInsertBody({
    required this.values,
    required this.previewBuilder,
    required this.onSeparatorChanged,
  });

  @override
  State<_TerminalInsertBody> createState() => _TerminalInsertBodyState();
}

class _TerminalInsertBodyState extends State<_TerminalInsertBody> {
  late final TextEditingController _separator;

  @override
  void initState() {
    super.initState();
    _separator = TextEditingController(text: ' ');
    widget.onSeparatorChanged(_separator.text);
  }

  @override
  void dispose() {
    _separator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.terminalInsert.separator, style: context.txt.fieldLabel),
        const SizedBox(height: 6),
        AppTextField(
          controller: _separator,
          autofocus: true,
          hintText: t.terminalInsert.customHint,
          onChanged: (value) {
            widget.onSeparatorChanged(value);
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        Text(t.terminalInsert.preview, style: context.txt.fieldLabel),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 130),
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: SingleChildScrollView(
            child: Text(
              widget.previewBuilder(widget.values, _separator.text),
              style: context.txt.code.copyWith(color: AppColors.fg),
            ),
          ),
        ),
      ],
    );
  }
}
