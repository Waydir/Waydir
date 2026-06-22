part of '../waydir_shell.dart';

mixin _WaydirCommandPaletteMixin
    on
        State<WaydirShell>,
        _WaydirStateBase,
        _WaydirActionsMixin,
        _WaydirTerminalMixin,
        _WaydirMenuMixin {
  bool _hasTarget(NavigationStore s) {
    if (s.selectedCount.value > 0) return true;
    final idx = s.cursorIndex.value;
    return idx >= 0 && idx < s.visibleFiles.value.length;
  }

  AppCommand _cmd(
    String id,
    VoidCallback run, {
    bool enabled = true,
    String? label,
    String? category,
    ShortcutGroup? group,
    IconData? icon,
  }) {
    final def = AppShortcuts.tryGetById(id);
    final effectiveGroup = group ?? def?.group;
    final meta = effectiveGroup != null
        ? shortcutGroupMeta[effectiveGroup]
        : null;
    return AppCommand(
      id: id,
      label: label ?? (def != null ? shortcutLabel(def) : id),
      description: category ?? meta?.title(),
      icon: icon ?? meta?.icon ?? WaydirIconsRegular.gearSix,
      enabled: enabled,
      disabledReason: enabled ? null : t.commandPalette.unavailable,
      run: run,
    );
  }

  List<AppCommand> _buildCommands({List<String> recentPaths = const []}) {
    final store = _active;
    final dual = _shell.isDual.value;
    final hasTarget = _hasTarget(store);
    final tabCount = _shell.activePane.value!.tabs.tabs.value.length;
    final selected = store.selectedCount.value;

    return [
      _cmd('go_back', store.goBack, enabled: store.canGoBack.value),
      _cmd('go_forward', store.goForward, enabled: store.canGoForward.value),
      _cmd('go_up', store.goUp),
      _cmd('refresh', store.refresh),
      _cmd('focus_path', _active.focusPathBar),
      _cmd('open_item', store.openSelected, enabled: hasTarget),
      _cmd('quick_look', _openQuickLook, enabled: hasTarget),
      _cmd('search', store.openSearch),
      _cmd('recursive_search', () => store.openSearch(recursive: true)),
      _cmd('new_folder', store.startCreate),
      _cmd('rename', () => _renameOrMultiRename(store), enabled: hasTarget),
      _cmd('copy', () => _copySelectedWithToast(store), enabled: hasTarget),
      _cmd('cut', () => _cutSelectedWithToast(store), enabled: hasTarget),
      _cmd('paste', store.paste, enabled: store.canPaste.value),
      _cmd(
        'delete',
        () => _confirmAndDelete(forceTrash: true),
        enabled: hasTarget,
      ),
      _cmd(
        'delete_permanent',
        () => _confirmAndDelete(forcePermanent: true),
        enabled: hasTarget,
      ),
      _cmd(
        'compute_folder_size',
        store.computeSelectedFolderSizes,
        enabled: hasTarget,
      ),
      _cmd(
        'properties',
        () => _openPropertiesFromMenu(store),
        enabled: hasTarget,
        label: t.menu.properties,
        group: ShortcutGroup.fileOps,
        icon: WaydirIconsRegular.info,
      ),
      _cmd(
        'compress',
        () => unawaited(_compressWithOptions()),
        enabled: hasTarget,
        label: t.menu.compressOptions,
        group: ShortcutGroup.fileOps,
        icon: WaydirIconsRegular.archive,
      ),
      _cmd(
        'extract_here',
        () => _extractSelected(toOwnFolder: false),
        enabled: hasTarget,
        label: t.menu.extractHere,
        group: ShortcutGroup.fileOps,
        icon: WaydirIconsRegular.archive,
      ),
      _cmd('select_all', store.selectAll),
      _cmd('deselect_all', store.deselectAll, enabled: selected > 0),
      _cmd('invert_selection', store.invertSelection),
      _cmd('select_pattern', _openSelectPattern),
      _cmd(
        'save_selection',
        () => unawaited(_saveSelectionToFile()),
        enabled: selected > 0,
      ),
      _cmd('load_selection', () => unawaited(_loadSelectionFromFile())),
      _cmd('new_tab', _newTabHere),
      _cmd('close_tab', _closeActiveTab, enabled: tabCount > 1),
      _cmd('next_tab', _selectNextTab, enabled: tabCount > 1),
      _cmd('prev_tab', _selectPrevTab, enabled: tabCount > 1),
      _cmd('toggle_dual', _shell.toggleDual),
      _cmd('compare', _shell.compare.toggle, enabled: dual),
      _cmd(
        'dual_copy',
        () => unawaited(_dualPaneTransfer(store, move: false)),
        enabled: dual,
      ),
      _cmd(
        'dual_move',
        () => unawaited(_dualPaneTransfer(store, move: true)),
        enabled: dual,
      ),
      _cmd('toggle_sidebar', _toggleSidebarCollapsed),
      _cmd('toggle_hidden', _toggleShowHiddenGlobal),
      _cmd('toggle_view', _toggleViewMode),
      _cmd('file_list_zoom_in', SettingsStore.instance.increaseFileListScale),
      _cmd('file_list_zoom_out', SettingsStore.instance.decreaseFileListScale),
      _cmd('file_list_zoom_reset', SettingsStore.instance.resetFileListScale),
      _cmd('toggle_terminal', _toggleTerminal),
      _cmd('preferences', _openPreferences),
      _cmd('help', _openHelp),
      ..._goToCommands(recentPaths),
      ..._pluginCommands(),
      ..._fileCommands(store),
    ];
  }

  List<AppCommand> _goToCommands(List<String> recentPaths) {
    final commands = <AppCommand>[];
    final seen = <String>{};

    for (final b in BookmarkStore.instance.bookmarks.value) {
      if (!seen.add(b.path)) continue;
      commands.add(
        AppCommand(
          id: 'goto:${b.path}',
          label: b.label,
          description: t.commandPalette.categoryBookmark,
          icon: WaydirIconsRegular.bookmarkSimple,
          run: () => _active.navigateTo(b.path),
        ),
      );
    }

    for (final drive in driveStore.drives.value) {
      final mount = drive.mountPoint;
      if (mount == null || !seen.add(mount)) continue;
      commands.add(
        AppCommand(
          id: 'goto:$mount',
          label: drive.label,
          description: t.commandPalette.categoryDrive,
          icon: WaydirIconsRegular.hardDrive,
          run: () => _active.navigateTo(mount),
        ),
      );
    }

    for (final path in recentPaths) {
      if (!seen.add(path)) continue;
      commands.add(
        AppCommand(
          id: 'goto:$path',
          label: p.basename(path).isEmpty ? path : p.basename(path),
          description: '${t.commandPalette.categoryRecent} · $path',
          icon: WaydirIconsRegular.clock,
          run: () => _active.navigateTo(path),
        ),
      );
    }

    return commands;
  }

  List<AppCommand> _pluginCommands() {
    final seen = <String>{};
    final contributions = [
      ...PluginStore.instance.menubarContributions(),
      ...PluginStore.instance.toolbarContributions(),
      ...PluginStore.instance.shortcutContributions(),
    ];

    return [
      for (final c in contributions)
        if (c.event == null && seen.add(c.fullActionId))
          AppCommand(
            id: c.fullActionId,
            label: c.title,
            description: t.commandPalette.categoryPlugin,
            icon: WaydirIconsRegular.gearSix,
            run: () => unawaited(_runPluginAction(c.fullActionId)),
          ),
    ];
  }

  List<AppCommand> _fileCommands(NavigationStore store) {
    return [
      for (final entry in store.visibleFiles.value)
        AppCommand(
          id: 'file:${entry.path}',
          label: entry.name,
          description: entry.type == FileItemType.folder
              ? t.commandPalette.categoryFolder
              : t.commandPalette.categoryFile,
          icon: entry.type == FileItemType.folder
              ? WaydirIconsRegular.folder
              : WaydirIconsRegular.file,
          queryOnly: true,
          run: () => store.onOpen(entry),
        ),
    ];
  }

  void _openCommandPalette() {
    unawaited(_showCommandPalette());
  }

  Future<void> _showCommandPalette() async {
    final recentPaths = await SettingsStore.instance.db.getRecentEnteredPaths();
    if (!mounted) return;
    showCommandPalette(
      context: context,
      commands: _buildCommands(recentPaths: recentPaths),
      onRun: (command) => CommandUsageStore.instance.record(command.id),
      recentIds: CommandUsageStore.instance.rankedIds(),
    );
  }
}
