import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';
import '../core/archive/archive_path.dart';
import '../core/archive/archive_writer.dart';
import '../core/fs/file_system_service.dart';
import '../core/open/open_service.dart';
import '../core/keyboard/keyboard_shortcuts.dart';
import '../core/platform/platform_paths.dart';
import '../core/models/file_entry.dart';
import '../core/models/file_operation.dart';
import '../core/settings/settings_store.dart';
import '../features/navigation/navigation_store.dart';
import '../features/navigation/sidebar.dart';
import '../features/navigation/status_bar.dart';
import '../features/operations/operation_store.dart';
import '../features/panes/pane_view.dart';
import '../features/panes/pane_divider.dart';
import '../features/panes/shell_store.dart';
import '../features/settings/preferences_view.dart';
import '../i18n/strings.g.dart';
import '../ui/chrome/title_bar.dart';
import '../ui/dialogs/dialog.dart';
import '../ui/dialogs/compress_dialog.dart';
import '../ui/dialogs/open_with_dialog.dart';
import '../ui/dialogs/properties_dialog.dart';
import '../ui/overlays/command_palette.dart';
import '../ui/overlays/context_menu.dart';
import '../ui/overlays/notification_overlay.dart';
import '../ui/overlays/quick_look.dart';
import '../ui/overlays/notification_store.dart';
import '../ui/overlays/toast.dart';
import '../ui/theme/app_theme.dart';
import '../ui/theme/app_text_styles.dart';

class WaydirPage extends StatefulWidget {
  const WaydirPage({super.key});

  @override
  State<WaydirPage> createState() => _WaydirPageState();
}

class _WaydirPageState extends State<WaydirPage> {
  final _notificationStore = NotificationStore();
  late final _operationStore = OperationStore(
    notificationStore: _notificationStore,
  );
  late final _shell = ShellStore(
    operationStore: _operationStore,
    notificationStore: _notificationStore,
  );
  final _focusNode = FocusNode();
  final _effectDisposers = <void Function()>[];

  /// The file the "Open With…" chooser was opened on.
  FileEntry? _openWithEntry;
  final _renameErrorDisposers = <String, void Function()>{};

  NavigationStore get _active => _shell.activeStore.value!;

  @override
  void initState() {
    super.initState();
    _effectDisposers.add(
      effect(() {
        if (!_shell.ready.value) return;
        final completedId = _operationStore.taskCompleted.value;
        if (completedId != null) {
          _operationStore.taskCompleted.value = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final tasks = _operationStore.tasks.value;
            FileTask? task;
            for (final t in tasks) {
              if (t.id == completedId) {
                task = t;
                break;
              }
            }
            if (task == null) return;
            for (final store in _shell.allStores) {
              if (task.destination == store.currentPath.value ||
                  ((task.type == TaskType.delete ||
                          task.type == TaskType.trash) &&
                      task.sources.any(
                        (s) => p.dirname(s) == store.currentPath.value,
                      ))) {
                store.refresh();
              }
            }
            if (task.errors.isNotEmpty &&
                (task.status == TaskStatus.completed ||
                    task.status == TaskStatus.failed)) {
              final label = TaskLabel.title(task);
              showToast(
                context: context,
                message: t.toast.taskErrors(
                  label: label,
                  count: task.errors.length,
                ),
                duration: const Duration(seconds: 3),
              );
            }
          });
        }
      }),
    );
    _effectDisposers.add(
      effect(() {
        if (!_shell.ready.value) return;
        final active = _active.searchActive.value;
        if (!active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (_isEditableFocused()) return;
            _focusNode.requestFocus();
          });
        }
      }),
    );
    _effectDisposers.add(
      effect(() {
        if (!_shell.ready.value) return;
        _shell.panes.value;
        _installRenameErrorEffects();
      }),
    );
  }

  void _installRenameErrorEffects() {
    final currentIds = <String>{};
    for (final pane in _shell.panes.value) {
      for (final tab in pane.tabs.tabs.value) {
        currentIds.add(tab.id);
        if (!_renameErrorDisposers.containsKey(tab.id)) {
          final store = tab.store;
          _renameErrorDisposers[tab.id] = effect(() {
            final error = store.renameError.value;
            if (error != null) {
              store.renameError.value = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  showToast(
                    context: context,
                    message: error,
                    duration: const Duration(seconds: 3),
                  );
                }
              });
            }
          });
        }
      }
    }
    final existingIds = _renameErrorDisposers.keys.toSet();
    for (final id in existingIds.difference(currentIds)) {
      _renameErrorDisposers.remove(id)?.call();
    }
  }

  @override
  void dispose() {
    for (final d in _effectDisposers) {
      d();
    }
    _effectDisposers.clear();
    for (final d in _renameErrorDisposers.values) {
      d();
    }
    _renameErrorDisposers.clear();
    _focusNode.dispose();
    _notificationStore.dispose();
    _shell.dispose();
    _operationStore.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete({bool forcePermanent = false}) async {
    final entries = _active.selectedEntries;
    if (entries.isEmpty) return;
    if (_active.isTrashView) {
      _active.deletePermanentlySelectedFromTrash();
      return;
    }
    final useTrash =
        !forcePermanent &&
        SettingsStore.instance.deleteKeyBehavior.value == 'trash';
    if (!SettingsStore.instance.confirmDelete.value) {
      _active.deleteSelected(toTrash: useTrash);
      return;
    }
    final count = entries.length;
    final single = count == 1;
    final String message;
    if (useTrash) {
      message = single
          ? t.dialog.confirmTrashSingle(name: entries.first.name)
          : t.dialog.confirmTrashMultiple(count: count);
    } else {
      message = single
          ? t.dialog.confirmDeleteSingle(name: entries.first.name)
          : t.dialog.confirmDeleteMultiple(count: count);
    }
    final actionLabel = useTrash ? t.dialog.moveToTrash : t.dialog.delete;
    final result = await showCustomDialog<String>(
      context: context,
      title: useTrash
          ? t.dialog.confirmTrashTitle
          : t.dialog.confirmDeleteTitle,
      icon: useTrash
          ? PhosphorIconsRegular.trashSimple
          : PhosphorIconsRegular.trash,
      iconColor: AppColors.danger,
      body: Text(message, style: context.txt.body.copyWith(height: 1.4)),
      actions: [
        DialogAction(label: t.dialog.cancel, color: AppColors.fgMuted),
        DialogAction(label: actionLabel, color: AppColors.danger),
      ],
    );
    if (result == actionLabel) {
      _active.deleteSelected(toTrash: useTrash);
    }
  }

  void _handleBackgroundContextMenu(Offset position) {
    final store = _active;
    if (store.isTrashView) {
      showContextMenu(
        context: context,
        position: position,
        items: [
          ContextMenuItem(
            icon: PhosphorIconsRegular.arrowClockwise,
            label: t.toolbar.refresh,
            action: 'refresh',
          ),
          ContextMenuItem(
            icon: PhosphorIconsRegular.selectionAll,
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
        icon: PhosphorIconsRegular.clipboard,
        label: t.menu.paste,
        action: 'paste',
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: PhosphorIconsRegular.terminal,
        label: t.menu.openInTerminal,
        action: 'open_in_terminal',
      ),
      ContextMenuItem(
        icon: PhosphorIconsRegular.folderPlus,
        label: t.toolbar.newFolder,
        action: 'new_folder',
      ),
      ContextMenuItem(
        icon: PhosphorIconsRegular.arrowClockwise,
        label: t.toolbar.refresh,
        action: 'refresh',
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: PhosphorIconsRegular.selectionAll,
        label: t.menu.selectAll,
        action: 'select_all',
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
    final isRecursive = store.searchActive.value && store.searchRecursive.value;

    final openWithItems = isSingleFile
        ? await _buildOpenWithItem(entries.first)
        : const <ContextMenuItem>[];
    if (!mounted) return;

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
        : p.basename(store.currentPath.value);
    final compressItem = canCompress
        ? ContextMenuItem(
            icon: PhosphorIconsRegular.fileZip,
            label: t.menu.compress,
            action: 'compress',
            children: [
              ContextMenuItem(
                icon: PhosphorIconsRegular.fileZip,
                label: t.menu.compressTo(name: '$compressBase.zip'),
                action: 'compress_zip',
              ),
              ContextMenuItem(
                icon: PhosphorIconsRegular.fileZip,
                label: t.menu.compressTo(name: '$compressBase.tar.gz'),
                action: 'compress_targz',
              ),
              ContextMenuItem.divider,
              ContextMenuItem(
                icon: PhosphorIconsRegular.slidersHorizontal,
                label: t.menu.compressOptions,
                action: 'compress_options',
              ),
            ],
          )
        : null;

    final extractItem = canExtract
        ? ContextMenuItem(
            icon: PhosphorIconsRegular.archive,
            label: t.menu.extract,
            action: 'extract',
            children: [
              ContextMenuItem(
                icon: PhosphorIconsRegular.arrowLineDown,
                label: t.menu.extractHere,
                action: 'extract_here',
              ),
              ContextMenuItem(
                icon: PhosphorIconsRegular.folderPlus,
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
            icon: PhosphorIconsRegular.arrowCounterClockwise,
            label: count == 1
                ? t.menu.restore
                : t.menu.restoreItems(count: count),
            action: 'restore',
          ),
        ContextMenuItem(
          icon: PhosphorIconsRegular.trash,
          label: count == 1
              ? t.menu.deletePermanently
              : t.menu.deletePermanentlyItems(count: count),
          action: 'delete_permanent_bin',
          danger: true,
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
      if (!isSingleFile)
        ContextMenuItem(
          icon: PhosphorIconsRegular.folderOpen,
          label: count == 1 ? t.menu.open : t.menu.openItems(count: count),
          action: 'open',
        ),
      ...openWithItems,
      ?extractItem,
      ?compressItem,
      if (isRecursive && count == 1)
        ContextMenuItem(
          icon: PhosphorIconsRegular.arrowSquareOut,
          label: t.menu.openLocation,
          action: 'open_location',
        ),
      if (isSingleFolder) ...[
        ContextMenuItem(
          icon: PhosphorIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
        ContextMenuItem(
          icon: PhosphorIconsRegular.terminal,
          label: t.menu.openInTerminal,
          action: 'open_in_terminal',
        ),
      ],
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: PhosphorIconsRegular.copy,
        label: t.menu.copy,
        action: 'copy',
      ),
      ContextMenuItem(
        icon: PhosphorIconsRegular.scissors,
        label: t.menu.cut,
        action: 'cut',
      ),
      ContextMenuItem(
        icon: PhosphorIconsRegular.clipboard,
        label: t.menu.paste,
        action: 'paste',
      ),
      if (count == 1) ContextMenuItem.divider,
      if (count == 1)
        ContextMenuItem(
          icon: PhosphorIconsRegular.copy,
          label: t.menu.copyPath,
          action: 'copy_path',
        ),
      ContextMenuItem.divider,
      if (count == 1)
        ContextMenuItem(
          icon: PhosphorIconsRegular.pencilSimple,
          label: t.menu.rename,
          action: 'rename',
          shortcut: 'F2',
        ),
      ContextMenuItem(
        icon: PhosphorIconsRegular.trashSimple,
        label: count == 1
            ? t.menu.moveToTrash
            : t.menu.moveToTrashItems(count: count),
        action: 'trash',
      ),
      ContextMenuItem(
        icon: PhosphorIconsRegular.trash,
        label: count == 1
            ? t.menu.deletePermanently
            : t.menu.deletePermanentlyItems(count: count),
        action: 'delete_permanent',
        danger: true,
      ),
      if (count == 1) ContextMenuItem.divider,
      if (count == 1)
        ContextMenuItem(
          icon: PhosphorIconsRegular.info,
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

  Future<List<ContextMenuItem>> _buildOpenWithItem(FileEntry entry) async {
    _openWithEntry = entry;

    final open = ContextMenuItem(
      icon: PhosphorIconsRegular.folderOpen,
      label: t.menu.open,
      action: 'open',
    );

    if (PlatformPaths.isWindows) {
      return [
        open,
        ContextMenuItem(
          icon: PhosphorIconsRegular.dotsThreeOutline,
          label: t.menu.openWithChoose,
          action: 'open_with_system',
        ),
      ];
    }

    final chooser = ContextMenuItem(
      icon: PhosphorIconsRegular.dotsThreeOutline,
      label: t.menu.openWithChoose,
      action: 'open_with_choose',
    );

    if (PlatformPaths.isMacOS) return [open, chooser];

    OpenWithOptions options;
    try {
      options = await OpenService.optionsFor(entry.realPath);
    } catch (_) {
      return [open, chooser];
    }
    final preferred = options.defaultApp;
    if (preferred == null) return [open, chooser];
    return [
      ContextMenuItem(
        icon: PhosphorIconsRegular.appWindow,
        label: t.menu.openWithApp(app: preferred.name),
        action: 'open',
        iconPath: preferred.iconPath,
      ),
      chooser,
    ];
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
      case 'rename':
        store.startRename();
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
        final entries = store.selectedEntries;
        if (entries.length == 1) {
          showPropertiesDialog(
            context: context,
            entry: entries.first,
          ).then((_) => _restoreFocus());
        }
    }
  }

  List<String> _compressSources() {
    return _active.selectedEntries
        .where((e) => !FileSystemService.isInsideArchive(e.path))
        .map((e) => e.path)
        .toList();
  }

  String _compressBaseName() {
    final store = _active;
    final entries = store.selectedEntries;
    if (entries.length == 1) {
      final e = entries.first;
      return e.type == FileItemType.folder
          ? e.name
          : p.basenameWithoutExtension(e.name);
    }
    return p.basename(store.currentPath.value);
  }

  void _quickCompress(ArchiveFormat format) {
    final store = _active;
    final sources = _compressSources();
    if (sources.isEmpty) return;
    final dest = FileSystemService.uniquePath(
      p.join(
        store.currentPath.value,
        '${_compressBaseName()}.${format.extension}',
      ),
    );
    store.operationStore.enqueueCompress(
      sources,
      dest,
      format: format.name,
      level: CompressionLevel.normal.name,
    );
  }

  Future<void> _compressWithOptions() async {
    final store = _active;
    final sources = _compressSources();
    if (sources.isEmpty) return;
    final dir = store.currentPath.value;
    final req = await showCompressDialog(
      context: context,
      defaultBaseName: _compressBaseName(),
      destinationDir: dir,
    );
    if (req == null) return;
    final dest = FileSystemService.uniquePath(p.join(dir, req.fileName));
    store.operationStore.enqueueCompress(
      sources,
      dest,
      format: req.format.name,
      level: req.level.name,
    );
  }

  void _extractSelected({required bool toOwnFolder}) {
    final store = _active;
    final base = store.currentPath.value;
    final archives = store.selectedEntries
        .where(
          (e) =>
              e.type == FileItemType.file &&
              ArchivePath.isArchiveName(e.name) &&
              !FileSystemService.isInsideArchive(e.path),
        )
        .toList();
    if (archives.isEmpty) return;

    if (toOwnFolder) {
      for (final entry in archives) {
        final dest = FileSystemService.uniquePath(
          p.join(base, FileSystemService.archiveBaseName(entry.name)),
        );
        store.operationStore.enqueueExtract([entry.path], dest);
      }
    } else {
      store.operationStore.enqueueExtract(
        archives.map((e) => e.path).toList(),
        base,
      );
    }
  }

  bool _isEditableFocused() {
    final primaryFocus = WidgetsBinding.instance.focusManager.primaryFocus;
    if (primaryFocus == null || primaryFocus == _focusNode) return false;
    final ctx = primaryFocus.context;
    if (ctx == null) return true;
    if (ctx.widget is EditableText) return true;
    bool found = false;
    ctx.visitAncestorElements((el) {
      if (el.widget is EditableText) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  bool _isModalRouteOnTop() {
    final navigator = Navigator.maybeOf(context);
    return navigator != null && navigator.canPop();
  }

  void _openPreferences() {
    showPreferencesDialog(context).then((_) => _restoreFocus());
  }

  void _openQuickLook() {
    if (_isModalRouteOnTop()) return;
    showQuickLook(
      context: context,
      store: _active,
    ).then((_) => _restoreFocus());
  }

  void _openCommandPalette() {
    showCommandPalette(
      context: context,
      actions: [
        CommandPaletteAction(
          icon: PhosphorIconsRegular.gearSix,
          title: t.commandPalette.openPreferences,
          subtitle: t.commandPalette.preferencesSubtitle,
          searchText: 'settings options preferences',
          run: _openPreferences,
        ),
        CommandPaletteAction(
          icon: PhosphorIconsRegular.columns,
          title: t.menu.dualPaneMode,
          subtitle: _shell.isDual.value
              ? t.commandPalette.enabled
              : t.commandPalette.disabled,
          searchText: 'view split panes dual',
          run: _shell.toggleDual,
        ),
        CommandPaletteAction(
          icon: PhosphorIconsRegular.eye,
          title: t.menu.showHidden,
          subtitle: SettingsStore.instance.showHiddenDefault.value
              ? t.commandPalette.enabled
              : t.commandPalette.disabled,
          searchText: 'view hidden dotfiles files',
          run: _toggleShowHiddenGlobal,
        ),
      ],
    ).then((_) => _restoreFocus());
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final ctrl = AppShortcuts.isControl;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;

    if (!_isModalRouteOnTop() &&
        ctrl &&
        !shift &&
        AppShortcuts.isKey('command_palette', key)) {
      _openCommandPalette();
      return KeyEventResult.handled;
    }

    if (!_isModalRouteOnTop() &&
        ctrl &&
        !shift &&
        AppShortcuts.isKey('preferences', key)) {
      _openPreferences();
      return KeyEventResult.handled;
    }

    if (_isEditableFocused() || _isModalRouteOnTop()) {
      return KeyEventResult.ignored;
    }

    if (AppShortcuts.isKey('toggle_dual', key)) {
      _shell.toggleDual();
      return KeyEventResult.handled;
    }

    if (ctrl && !shift && AppShortcuts.isKey('toggle_sidebar', key)) {
      final s = SettingsStore.instance.sidebarCollapsed;
      s.value = !s.value;
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('switch_pane', key) &&
        !ctrl &&
        !shift &&
        _shell.isDual.value) {
      final idx = _shell.activePaneIndex.value;
      _shell.setActivePane(1 - idx);
      return KeyEventResult.handled;
    }

    if (ctrl && !shift && AppShortcuts.isKey('new_tab', key)) {
      _shell.activePane.value!.tabs.addTab(_active.currentPath.value);
      return KeyEventResult.handled;
    }

    if (ctrl && !shift && AppShortcuts.isKey('close_tab', key)) {
      final tabsStore = _shell.activePane.value!.tabs;
      final tab = tabsStore.activeTab.value;
      if (tabsStore.tabs.value.length > 1) {
        tabsStore.closeTab(tab.id);
      }
      return KeyEventResult.handled;
    }

    if (ctrl && !shift && AppShortcuts.isKey('next_tab', key)) {
      final tabsStore = _shell.activePane.value!.tabs;
      final idx = tabsStore.activeIndex.value;
      final next = (idx + 1) % tabsStore.tabs.value.length;
      tabsStore.selectTab(next);
      return KeyEventResult.handled;
    }

    if (ctrl && shift && AppShortcuts.isKey('prev_tab', key)) {
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

    if (!ctrl && !shift && !alt && AppShortcuts.isKey('quick_look', key)) {
      _openQuickLook();
      return KeyEventResult.handled;
    }

    if (ctrl && shift && AppShortcuts.isKey('recursive_search', key)) {
      store.openSearch(recursive: true);
      return KeyEventResult.handled;
    }

    if (ctrl && !shift && AppShortcuts.isKey('search', key)) {
      store.openSearch();
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('close_search', key) && store.searchActive.value) {
      store.closeSearch();
      return KeyEventResult.handled;
    }

    if (ctrl && AppShortcuts.isKey('copy', key)) {
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

    if (ctrl && AppShortcuts.isKey('cut', key)) {
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

    if (ctrl && AppShortcuts.isKey('paste', key)) {
      store.paste();
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('open_item', key)) {
      store.openSelected();
      return KeyEventResult.handled;
    }

    if (ctrl && AppShortcuts.isKey('select_all', key)) {
      store.selectAll();
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('deselect_all', key) && !store.searchActive.value) {
      store.deselectAll();
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('toggle_select', key)) {
      store.toggleSelectAndAdvance();
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('go_up', key) && !alt) {
      store.goUp();
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('dual_copy', key)) {
      if (_shell.isDual.value) {
        final activeIdx = _shell.activePaneIndex.value;
        final otherPane = _shell.panes.value[1 - activeIdx];
        final otherPath =
            otherPane.tabs.activeTab.value.store.currentPath.value;
        final sources = _dualPaneSources(store);
        if (sources.isNotEmpty) {
          _operationStore.enqueueCopy(sources, otherPath);
        }
      } else {
        store.refresh();
      }
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('new_folder', key)) {
      store.startCreate();
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('dual_move', key) && _shell.isDual.value) {
      final activeIdx = _shell.activePaneIndex.value;
      final otherPane = _shell.panes.value[1 - activeIdx];
      final otherPath = otherPane.tabs.activeTab.value.store.currentPath.value;
      final sources = _dualPaneSources(store);
      if (sources.isNotEmpty) {
        _operationStore.enqueueMove(sources, otherPath);
      }
      return KeyEventResult.handled;
    }

    if (alt && AppShortcuts.isKey('go_back', key)) {
      store.goBack();
      return KeyEventResult.handled;
    }

    if (alt && AppShortcuts.isKey('go_forward', key)) {
      store.goForward();
      return KeyEventResult.handled;
    }

    if (ctrl && !shift && AppShortcuts.isKey('refresh', key)) {
      store.refresh();
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('delete', key)) {
      _confirmAndDelete(forcePermanent: shift);
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('cursor_down', key)) {
      store.moveCursor(1);
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('cursor_up', key)) {
      store.moveCursor(-1);
      return KeyEventResult.handled;
    }

    if (AppShortcuts.isKey('rename', key)) {
      store.startRename();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _openInNewTab(String path) {
    _shell.activePane.value!.tabs.addTab(path);
  }

  List<String> _dualPaneSources(NavigationStore store) {
    final selected = store.selectedPaths.value;
    if (selected.isNotEmpty) return selected.toList();
    final idx = store.cursorIndex.value;
    final files = store.visibleFiles.value;
    if (idx >= 0 && idx < files.length) return [files[idx].path];
    return const [];
  }

  void _restoreFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isEditableFocused()) return;
      _focusNode.requestFocus();
    });
  }

  VoidCallback _activatePane(int index) {
    return () {
      _shell.setActivePane(index);
      _restoreFocus();
    };
  }

  void _setShowHiddenGlobal(bool value) {
    SettingsStore.instance.showHiddenDefault.value = value;
    if (!_shell.ready.value) return;
    for (final store in _shell.allStores) {
      store.showHidden.value = value;
    }
  }

  void _toggleShowHiddenGlobal() {
    if (!_shell.ready.value) return;
    _setShowHiddenGlobal(!SettingsStore.instance.showHiddenDefault.value);
  }

  Widget _buildViewMenu() {
    return Watch((_) {
      if (!_shell.ready.value) return const SizedBox.shrink();
      return TitleMenuButton(
        label: 'View',
        items: [
          ContextMenuItem(
            icon: PhosphorIconsRegular.columns,
            label: t.menu.dualPaneMode,
            action: 'toggle_dual',
            isToggle: true,
            toggleSignal: _shell.isDual,
          ),
          ContextMenuItem.divider,
          ContextMenuItem(
            icon: PhosphorIconsRegular.eye,
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
      );
    });
  }

  List<PlatformMenu> _platformViewMenus() {
    return [
      PlatformMenu(
        label: 'View',
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Stack(
          children: [
            TitleBar(
              menuTrailing: _buildViewMenu(),
              platformMenus: _platformViewMenus(),
              child: Watch((context) {
                if (!_shell.ready.value) {
                  return const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.fgMuted,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _SidebarHost(
                            active: _active,
                            operationStore: _operationStore,
                            onOpenInNewTab: _openInNewTab,
                          ),
                          Container(width: 1, color: AppColors.bgDivider),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Watch((_) {
                                  final dual = _shell.isDual.value;
                                  final panes = _shell.panes.value;
                                  final activeIdx =
                                      _shell.activePaneIndex.value;

                                  if (!dual) {
                                    return PaneView(
                                      pane: panes[0],
                                      isActive: true,
                                      onActivate: _restoreFocus,
                                      onBackgroundContextMenu:
                                          _handleBackgroundContextMenu,
                                      onContextMenu: _handleContextMenu,
                                      onMenuAction: _handleMenuAction,
                                      onOpenInNewTab: _openInNewTab,
                                    );
                                  }

                                  final ratio = _shell.splitRatio.value;
                                  final leftFlex = (ratio * 1000).round();
                                  final rightFlex = ((1 - ratio) * 1000)
                                      .round();

                                  return Row(
                                    children: [
                                      Flexible(
                                        flex: leftFlex,
                                        child: PaneView(
                                          pane: panes[0],
                                          isActive: activeIdx == 0,
                                          onActivate: _activatePane(0),
                                          onBackgroundContextMenu:
                                              _handleBackgroundContextMenu,
                                          onContextMenu: _handleContextMenu,
                                          onMenuAction: _handleMenuAction,
                                          onOpenInNewTab: _openInNewTab,
                                        ),
                                      ),
                                      PaneDivider(
                                        shell: _shell,
                                        totalWidth: constraints.maxWidth,
                                      ),
                                      Flexible(
                                        flex: rightFlex,
                                        child: PaneView(
                                          pane: panes[1],
                                          isActive: activeIdx == 1,
                                          onActivate: _activatePane(1),
                                          onBackgroundContextMenu:
                                              _handleBackgroundContextMenu,
                                          onContextMenu: _handleContextMenu,
                                          onMenuAction: _handleMenuAction,
                                          onOpenInNewTab: _openInNewTab,
                                        ),
                                      ),
                                    ],
                                  );
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Watch(
                      (context) => StatusBar(
                        store: _active,
                        operationStore: _operationStore,
                        notificationStore: _notificationStore,
                      ),
                    ),
                  ],
                );
              }),
            ),
            NotificationOverlay(store: _notificationStore),
          ],
        ),
      ),
    );
  }
}

class _SidebarHost extends StatefulWidget {
  final NavigationStore active;
  final OperationStore operationStore;
  final void Function(String path) onOpenInNewTab;

  const _SidebarHost({
    required this.active,
    required this.operationStore,
    required this.onOpenInNewTab,
  });

  @override
  State<_SidebarHost> createState() => _SidebarHostState();
}

class _SidebarHostState extends State<_SidebarHost> {
  static const _railWidth = 52.0;
  static const _expandedWidth = 200.0;
  static const _animDuration = Duration(milliseconds: 140);

  void _toggleUserCollapsed() {
    final s = SettingsStore.instance.sidebarCollapsed;
    s.value = !s.value;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final collapsed = SettingsStore.instance.sidebarCollapsed.value;

      return AnimatedContainer(
        duration: _animDuration,
        curve: Curves.easeOut,
        width: collapsed ? _railWidth : _expandedWidth,
        child: ClipRect(
          child: Sidebar(
            store: widget.active,
            operationStore: widget.operationStore,
            onOpenInNewTab: widget.onOpenInNewTab,
            collapsed: collapsed,
            onToggleCollapsed: _toggleUserCollapsed,
          ),
        ),
      );
    });
  }
}
