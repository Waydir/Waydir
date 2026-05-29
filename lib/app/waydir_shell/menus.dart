part of '../waydir_shell.dart';

mixin _WaydirMenuMixin
    on State<WaydirShell>, _WaydirStateBase, _WaydirActionsMixin {
  void _handleBackgroundContextMenu(Offset position) {
    final store = _active;
    if (store.isTrashView) {
      showContextMenu(
        context: context,
        position: position,
        items: [
          ContextMenuItem(
            icon: WaydirIconsRegular.arrowClockwise,
            label: t.toolbar.refresh,
            action: 'refresh',
          ),
          ContextMenuItem(
            icon: WaydirIconsRegular.selectionAll,
            label: t.menu.selectAll,
            action: 'select_all',
          ),
        ],
        onSelect: _handleBackgroundMenuAction,
      );
      return;
    }
    final canPaste = store.canPaste.value;
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: WaydirIconsRegular.clipboard,
        label: t.menu.paste,
        action: 'paste',
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.terminal,
        label: t.menu.openInTerminal,
        action: 'open_in_terminal',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.folderPlus,
        label: t.toolbar.newFolder,
        action: 'new_folder',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.arrowClockwise,
        label: t.toolbar.refresh,
        action: 'refresh',
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.selectionAll,
        label: t.menu.selectAll,
        action: 'select_all',
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.info,
        label: t.menu.properties,
        action: 'properties',
      ),
    ];
    if (!canPaste) items.removeAt(0);

    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: _handleBackgroundMenuAction,
    );
  }

  void _handleBackgroundMenuAction(String action) {
    final store = _active;
    switch (action) {
      case 'paste':
        store.paste();
      case 'new_folder':
        store.startCreate();
      case 'refresh':
        store.refresh();
      case 'select_all':
        store.selectAll();
      case 'open_in_terminal':
        FileSystemService.openInTerminal(store.currentPath.value);
      case 'properties':
        _openFolderProperties(store.currentPath.value);
    }
  }

  Future<void> _handleContextMenu(
    FileSelectionEvent event,
    Offset position,
  ) async {
    final store = _active;
    store.onContextMenu(event);

    final entries = store.selectedEntries;
    final count = entries.length;
    final isSingleFolder =
        count == 1 && entries.first.type == FileItemType.folder;
    final isSingleFile = count == 1 && entries.first.type == FileItemType.file;
    final canVerifyChecksum =
        isSingleFile &&
        !PlatformPaths.isRemoteUri(entries.first.realPath) &&
        !FileSystemService.isInsideArchive(entries.first.realPath);
    final isRecursive = store.searchActive.value && store.searchRecursive.value;

    final openWithItems = isSingleFile
        ? _openWithItemsFor(entries.first)
        : const <ContextMenuItem>[];

    final archiveEntries = entries
        .where(
          (e) =>
              e.type == FileItemType.file &&
              ArchivePath.isArchiveName(e.name) &&
              !FileSystemService.isInsideArchive(e.path),
        )
        .toList();
    final canExtract =
        archiveEntries.isNotEmpty && archiveEntries.length == count;
    final canCompress =
        entries.isNotEmpty &&
        entries.every((e) => !FileSystemService.isInsideArchive(e.path));
    final compressBase = count == 1
        ? (entries.first.type == FileItemType.folder
              ? entries.first.name
              : p.basenameWithoutExtension(entries.first.name))
        : _sanitizeArchiveBase(
            p.basename(store.currentPath.value),
            store.currentPath.value,
          );
    final compressItem = canCompress
        ? ContextMenuItem(
            icon: WaydirIconsRegular.fileZip,
            label: t.menu.compress,
            action: 'compress',
            children: [
              ContextMenuItem(
                icon: WaydirIconsRegular.fileZip,
                label: t.menu.compressTo(name: '$compressBase.zip'),
                action: 'compress_zip',
              ),
              ContextMenuItem(
                icon: WaydirIconsRegular.fileZip,
                label: t.menu.compressTo(name: '$compressBase.tar.gz'),
                action: 'compress_targz',
              ),
              ContextMenuItem.divider,
              ContextMenuItem(
                icon: WaydirIconsRegular.slidersHorizontal,
                label: t.menu.compressOptions,
                action: 'compress_options',
              ),
            ],
          )
        : null;

    final extractItem = canExtract
        ? ContextMenuItem(
            icon: WaydirIconsRegular.archive,
            label: t.menu.extract,
            action: 'extract',
            children: [
              ContextMenuItem(
                icon: WaydirIconsRegular.arrowLineDown,
                label: t.menu.extractHere,
                action: 'extract_here',
              ),
              ContextMenuItem(
                icon: WaydirIconsRegular.folderPlus,
                label: count == 1
                    ? t.menu.extractToFolder(
                        name: FileSystemService.archiveBaseName(
                          archiveEntries.first.name,
                        ),
                      )
                    : t.menu.extractEach,
                action: 'extract_to_folder',
              ),
            ],
          )
        : null;

    if (store.isTrashView) {
      final binItems = <ContextMenuItem>[
        if (store.canRestoreFromTrash)
          ContextMenuItem(
            icon: WaydirIconsRegular.arrowCounterClockwise,
            label: count == 1
                ? t.menu.restore
                : t.menu.restoreItems(count: count),
            action: 'restore',
          ),
        ContextMenuItem(
          icon: WaydirIconsRegular.trash,
          label: count == 1
              ? t.menu.deletePermanently
              : t.menu.deletePermanentlyItems(count: count),
          action: 'delete_permanent_bin',
          danger: true,
        ),
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: WaydirIconsRegular.info,
          label: t.menu.properties,
          action: 'properties',
        ),
      ];
      showContextMenu(
        context: context,
        position: position,
        items: binItems,
        onSelect: _handleMenuAction,
      );
      return;
    }

    final items = <ContextMenuItem>[
      if (count == 1 && !isSingleFile)
        ContextMenuItem(
          icon: WaydirIconsRegular.folderOpen,
          label: t.menu.open,
          action: 'open',
        ),
      ...openWithItems,
      ?extractItem,
      ?compressItem,
      if (isRecursive && count == 1)
        ContextMenuItem(
          icon: WaydirIconsRegular.arrowSquareOut,
          label: t.menu.openLocation,
          action: 'open_location',
        ),
      if (isSingleFolder) ...[
        ContextMenuItem(
          icon: WaydirIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
        ContextMenuItem(
          icon: WaydirIconsRegular.terminal,
          label: t.menu.openInTerminal,
          action: 'open_in_terminal',
        ),
      ],
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.copy,
        label: t.menu.copy,
        action: 'copy',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.scissors,
        label: t.menu.cut,
        action: 'cut',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.clipboard,
        label: t.menu.paste,
        action: 'paste',
      ),
      if (count == 1) ContextMenuItem.divider,
      if (count == 1)
        ContextMenuItem(
          icon: WaydirIconsRegular.copy,
          label: t.menu.copyPath,
          action: 'copy_path',
        ),
      if (canVerifyChecksum)
        ContextMenuItem(
          icon: WaydirIconsRegular.checkSquare,
          label: t.menu.verifyChecksum,
          action: 'verify_checksum',
        ),
      ContextMenuItem.divider,
      if (count == 1)
        ContextMenuItem(
          icon: WaydirIconsRegular.pencilSimple,
          label: t.menu.rename,
          action: 'rename',
          shortcut: 'F2',
        ),
      if (count >= 2)
        ContextMenuItem(
          icon: WaydirIconsRegular.pencilSimple,
          label: t.menu.multiRename,
          action: 'multi_rename',
        ),
      ContextMenuItem(
        icon: WaydirIconsRegular.trashSimple,
        label: count == 1
            ? t.menu.moveToTrash
            : t.menu.moveToTrashItems(count: count),
        action: 'trash',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.trash,
        label: count == 1
            ? t.menu.deletePermanently
            : t.menu.deletePermanentlyItems(count: count),
        action: 'delete_permanent',
        danger: true,
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.info,
        label: t.menu.properties,
        action: 'properties',
      ),
    ];

    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: _handleMenuAction,
    );
  }

  ContextMenuItem get _openItem => ContextMenuItem(
    icon: WaydirIconsRegular.folderOpen,
    label: t.menu.open,
    action: 'open',
  );

  ContextMenuItem get _chooserItem => ContextMenuItem(
    icon: WaydirIconsRegular.dotsThreeOutline,
    label: t.menu.openWithChoose,
    action: 'open_with_choose',
  );

  /// Returns the "Open / Open with" items synchronously so the context menu
  /// can be shown immediately. On Linux the preferred-app lookup spawns
  /// `xdg-mime` subprocesses, so it is resolved off the menu path and cached
  /// per extension; the first menu for a given type shows the generic items,
  /// subsequent ones show the resolved default app.
  List<ContextMenuItem> _openWithItemsFor(FileEntry entry) {
    _openWithEntry = entry;

    if (PlatformPaths.isWindows) {
      return [
        _openItem,
        ContextMenuItem(
          icon: WaydirIconsRegular.dotsThreeOutline,
          label: t.menu.openWithChoose,
          action: 'open_with_system',
        ),
      ];
    }

    if (PlatformPaths.isMacOS) return [_openItem, _chooserItem];

    final key = entry.extension.toLowerCase();
    final cached = _openWithCache[key];
    if (cached != null) return cached;
    _warmOpenWith(entry.realPath, key);
    return [_openItem, _chooserItem];
  }

  Future<void> _warmOpenWith(String path, String key) async {
    if (!_openWithWarming.add(key)) return;
    try {
      final options = await OpenService.optionsFor(path);
      final preferred = options.defaultApp;
      _openWithCache[key] = preferred == null
          ? [_openItem, _chooserItem]
          : [
              ContextMenuItem(
                icon: WaydirIconsRegular.appWindow,
                label: t.menu.openWithApp(app: preferred.name),
                action: 'open',
                iconPath: preferred.iconPath,
              ),
              _chooserItem,
            ];
    } catch (_) {
      // Leave uncached so a later right-click can retry.
    } finally {
      _openWithWarming.remove(key);
    }
  }

  void _handleMenuAction(String action) {
    final store = _active;
    switch (action) {
      case 'open':
        store.openSelected();
      case 'open_with_choose':
        final entry = _openWithEntry;
        if (entry != null) {
          showOpenWithDialog(
            context: context,
            entry: entry,
          ).then((_) => _restoreFocus());
        }
      case 'open_with_system':
        final entry = _openWithEntry;
        if (entry != null) {
          OpenService.systemOpenWithDialog(entry.realPath);
        }
      case 'copy':
        store.copySelected();
        final count = store.selectedPaths.value.length;
        if (count > 0) {
          showToast(
            context: context,
            message: t.toast.copiedItems(count: count),
          );
        }
      case 'cut':
        store.cutSelected();
        final count = store.selectedPaths.value.length;
        if (count > 0) {
          showToast(
            context: context,
            message: t.toast.cutItems(count: count),
          );
        }
      case 'compress_zip':
        _quickCompress(ArchiveFormat.zip);
      case 'compress_targz':
        _quickCompress(ArchiveFormat.tarGz);
      case 'compress_options':
        _compressWithOptions();
      case 'extract_here':
        _extractSelected(toOwnFolder: false);
      case 'extract_to_folder':
        _extractSelected(toOwnFolder: true);
      case 'paste':
        store.paste();
      case 'copy_path':
        store.copySelectedPaths();
      case 'verify_checksum':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.file) {
          showChecksumDialog(
            context: context,
            entry: entries.first,
          ).then((_) => _restoreFocus());
        }
      case 'rename':
        store.startRename();
      case 'multi_rename':
        _multiRename(store);
      case 'trash':
        _confirmAndDelete();
      case 'delete_permanent':
        _confirmAndDelete(forcePermanent: true);
      case 'restore':
        store.restoreSelectedFromTrash();
      case 'delete_permanent_bin':
        store.deletePermanentlySelectedFromTrash();
      case 'open_in_terminal':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.folder) {
          FileSystemService.openInTerminal(entries.first.path);
        }
      case 'open_location':
        final entries = store.selectedEntries;
        if (entries.length == 1) {
          store.revealInFolder(entries.first.path);
        }
      case 'open_in_new_tab':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.folder) {
          _shell.activePane.value!.tabs.addTab(entries.first.path);
        }
      case 'properties':
        _openPropertiesFromMenu(store);
    }
  }

  Widget _buildViewMenu() {
    return SignalBuilder(
      builder: (_) {
        if (!_shell.ready.value) return const SizedBox.shrink();
        final store = _active;
        final selectedCount = store.selectedCount.value;
        final hasVisibleFiles = store.visibleFiles.value.isNotEmpty;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TitleMenuButton(
              label: t.menu.view,
              items: [
                ContextMenuItem(
                  icon: WaydirIconsRegular.columns,
                  label: t.menu.dualPaneMode,
                  action: 'toggle_dual',
                  isToggle: true,
                  toggleSignal: _shell.isDual,
                ),
                ContextMenuItem.divider,
                ContextMenuItem(
                  icon: WaydirIconsRegular.eye,
                  label: t.menu.showHidden,
                  action: 'toggle_hidden',
                  isToggle: true,
                  toggleSignal: SettingsStore.instance.showHiddenDefault,
                ),
              ],
              onSelect: (action) {
                switch (action) {
                  case 'toggle_dual':
                    _shell.toggleDual();
                  case 'toggle_hidden':
                    _toggleShowHiddenGlobal();
                }
              },
            ),
            TitleMenuButton(
              label: t.keybindings.categories.selection,
              items: [
                ContextMenuItem(
                  icon: WaydirIconsRegular.selectionAll,
                  label: t.menu.selectAll,
                  action: 'select_all',
                  shortcut: AppShortcuts.getById('select_all').displayKeys,
                  enabled: hasVisibleFiles,
                ),
                ContextMenuItem(
                  icon: WaydirIconsRegular.selectionAll,
                  label: t.menu.selectByPattern,
                  action: 'select_pattern',
                  shortcut: AppShortcuts.getById('select_pattern').displayKeys,
                  enabled: hasVisibleFiles,
                ),
                ContextMenuItem(
                  icon: WaydirIconsRegular.selectionAll,
                  label: t.menu.deselectAll,
                  action: 'deselect_all',
                  shortcut: AppShortcuts.getById('deselect_all').displayKeys,
                  enabled: selectedCount > 0,
                ),
                ContextMenuItem.divider,
                ContextMenuItem(
                  icon: WaydirIconsRegular.floppyDisk,
                  label: t.menu.saveSelection,
                  action: 'save_selection',
                  shortcut: AppShortcuts.getById('save_selection').displayKeys,
                  enabled: selectedCount > 0,
                ),
                ContextMenuItem(
                  icon: WaydirIconsRegular.fileTxt,
                  label: t.menu.loadSelection,
                  action: 'load_selection',
                  shortcut: AppShortcuts.getById('load_selection').displayKeys,
                  enabled: hasVisibleFiles,
                ),
              ],
              onSelect: _handleSelectionMenuAction,
            ),
          ],
        );
      },
    );
  }

  void _handleSelectionMenuAction(String action) {
    final store = _active;
    switch (action) {
      case 'select_all':
        store.selectAll();
      case 'select_pattern':
        _openSelectPattern();
      case 'deselect_all':
        store.deselectAll();
      case 'save_selection':
        _saveSelectionToFile();
      case 'load_selection':
        _loadSelectionFromFile();
    }
  }

  List<PlatformMenu> _platformViewMenus() {
    final store = _shell.ready.value ? _active : null;
    final selectedCount = store?.selectedCount.value ?? 0;
    final hasVisibleFiles = store?.visibleFiles.value.isNotEmpty ?? false;
    return [
      PlatformMenu(
        label: t.menu.view,
        menus: [
          PlatformMenuItem(
            label: t.menu.dualPaneMode,
            onSelected: () {
              if (_shell.ready.value) _shell.toggleDual();
            },
          ),
          PlatformMenuItem(
            label: t.menu.showHidden,
            onSelected: _toggleShowHiddenGlobal,
          ),
        ],
      ),
      PlatformMenu(
        label: t.keybindings.categories.selection,
        menus: [
          PlatformMenuItem(
            label: t.menu.selectAll,
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyA,
              meta: true,
            ),
            onSelected: hasVisibleFiles ? () => _active.selectAll() : null,
          ),
          PlatformMenuItem(
            label: t.menu.selectByPattern,
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyS,
              meta: true,
            ),
            onSelected: hasVisibleFiles ? _openSelectPattern : null,
          ),
          PlatformMenuItem(
            label: t.menu.deselectAll,
            shortcut: const SingleActivator(LogicalKeyboardKey.escape),
            onSelected: selectedCount > 0 ? () => _active.deselectAll() : null,
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: t.menu.saveSelection,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyS,
                  meta: true,
                  shift: true,
                ),
                onSelected: selectedCount > 0 ? _saveSelectionToFile : null,
              ),
              PlatformMenuItem(
                label: t.menu.loadSelection,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyL,
                  meta: true,
                  shift: true,
                ),
                onSelected: hasVisibleFiles ? _loadSelectionFromFile : null,
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
