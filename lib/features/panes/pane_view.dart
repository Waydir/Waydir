import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import 'package:waydir_term/xterm.dart';
import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../core/platform/full_disk_access.dart';
import '../../core/settings/settings_store.dart';
import '../../features/files/file_view.dart'
    show
        FileList,
        OpenInNewTabCallback,
        BackgroundContextMenuCallback,
        FileContextMenuCallback,
        FileMenuActionCallback;
import '../../features/files/rubber_band_layer.dart'
    show RubberBandSelectCallback;
import '../git/git_status_bar.dart';
import '../navigation/navigation_store.dart';
import '../navigation/search_bar_widget.dart';
import '../navigation/toolbar.dart';
import '../plugins/plugin_bar.dart';
import '../plugins/plugin_store.dart';
import '../tabs/tab_strip.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_close_button.dart';
import '../../i18n/strings.g.dart';
import 'pane_store.dart';
import 'terminal_tab.dart';

class PaneView extends StatelessWidget {
  final PaneStore pane;
  final bool isActive;
  final VoidCallback onActivate;
  final BackgroundContextMenuCallback? onBackgroundContextMenu;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final OpenInNewTabCallback? onOpenInNewTab;
  final void Function(NavigationStore store)? onMultiRename;
  final void Function(String fullActionId)? onPluginToolbarAction;
  final PluginBarEffectsHandler? onPluginBarEffects;
  final int terminalSlot;
  final List<TerminalTab> terminalTabs;
  final TerminalTab? activeTerminal;
  final bool terminalVisible;
  final double terminalHeight;
  final bool isSingleMode;
  final void Function(int slot)? onToggleTerminal;
  final void Function(int slot, int id)? onTerminalActivate;
  final void Function(int slot, int id)? onSelectTerminalTab;
  final void Function(int id)? onCloseTerminalTab;
  final void Function(int slot)? onNewTerminalTab;
  final void Function(int slot, int dir)? onCycleTerminalTab;
  final void Function(int slot, int from, int to)? onReorderTerminalTab;
  final void Function(int slot, double height)? onTerminalHeightChanged;
  final VoidCallback? onReturnFocusToFiles;

  const PaneView({
    super.key,
    required this.pane,
    required this.isActive,
    required this.onActivate,
    this.onBackgroundContextMenu,
    this.onContextMenu,
    this.onMenuAction,
    this.onOpenInNewTab,
    this.onMultiRename,
    this.onPluginToolbarAction,
    this.onPluginBarEffects,
    required this.terminalSlot,
    required this.terminalTabs,
    required this.activeTerminal,
    required this.terminalVisible,
    required this.terminalHeight,
    required this.isSingleMode,
    this.onToggleTerminal,
    this.onTerminalActivate,
    this.onSelectTerminalTab,
    this.onCloseTerminalTab,
    this.onNewTerminalTab,
    this.onCycleTerminalTab,
    this.onReorderTerminalTab,
    this.onTerminalHeightChanged,
    this.onReturnFocusToFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onActivate(),
      child: Stack(
        children: [
          Column(
            children: [
              TabStrip(tabsStore: pane.tabs, isActive: isActive),
              SignalBuilder(
                builder: (_) {
                  final tabStore = pane.tabs.activeTab.value.store;
                  return PaneLocationBar(
                    store: tabStore,
                    onMultiRename: onMultiRename == null
                        ? null
                        : () => onMultiRename!(tabStore),
                    onPluginAction: onPluginToolbarAction,
                  );
                },
              ),
              SignalBuilder(
                builder: (_) =>
                    pane.tabs.activeTab.value.store.searchActive.value
                    ? AppSearchBar(store: pane.tabs.activeTab.value.store)
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: SignalBuilder(
                  builder: (_) {
                    final idx = pane.tabs.activeIndex.value;
                    final tabs = pane.tabs.tabs.value;
                    return IndexedStack(
                      index: idx,
                      children: [
                        for (final tab in tabs)
                          _TabContent(
                            store: tab.store,
                            onBackgroundContextMenu: onBackgroundContextMenu,
                            onContextMenu: onContextMenu,
                            onMenuAction: onMenuAction,
                            onOpenInNewTab: onOpenInNewTab,
                            onRectSelect: (paths, {additive = false}) => tab
                                .store
                                .onRectSelect(paths, additive: additive),
                          ),
                      ],
                    );
                  },
                ),
              ),
              SignalBuilder(
                builder: (_) {
                  final bars = PluginStore.instance.paneBarContributions();
                  final handler = onPluginBarEffects;
                  if (bars.isEmpty || handler == null) {
                    return const SizedBox.shrink();
                  }
                  final store = pane.tabs.activeTab.value.store;
                  final paths = store.selectedPaths.value.toList()..sort();
                  final ctx = {
                    'scope': 'pane',
                    'pane': terminalSlot,
                    'is_active': isActive,
                    'dir': store.currentPath.value,
                    'paths': paths,
                  };
                  return PluginBarHost(
                    hostId: 'pane:$terminalSlot',
                    bars: bars,
                    contextData: ctx,
                    contextKey:
                        '${store.currentPath.value}|${paths.join('\u0001')}|$isActive',
                    onEffects: handler,
                  );
                },
              ),
              SignalBuilder(
                builder: (_) {
                  final gitStore = pane.tabs.activeTab.value.store.gitStatus;
                  final status = gitStore.status.value;
                  if (status == null) return const SizedBox.shrink();
                  return GitStatusBar(status: status, store: gitStore);
                },
              ),
              if (terminalVisible && activeTerminal != null)
                _TerminalPanel(
                  slot: terminalSlot,
                  tabs: terminalTabs,
                  active: activeTerminal!,
                  height: terminalHeight,
                  isSingleMode: isSingleMode,
                  onToggleTerminal: onToggleTerminal,
                  onActivate: onTerminalActivate,
                  onSelectTab: onSelectTerminalTab,
                  onCloseTab: onCloseTerminalTab,
                  onNewTab: onNewTerminalTab,
                  onCycleTab: onCycleTerminalTab,
                  onReorderTab: onReorderTerminalTab,
                  onHeightChanged: onTerminalHeightChanged,
                  onReturnFocusToFiles: onReturnFocusToFiles,
                ),
            ],
          ),
          if (!isActive)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  final NavigationStore store;
  final BackgroundContextMenuCallback? onBackgroundContextMenu;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final OpenInNewTabCallback? onOpenInNewTab;
  final RubberBandSelectCallback? onRectSelect;

  const _TabContent({
    required this.store,
    this.onBackgroundContextMenu,
    this.onContextMenu,
    this.onMenuAction,
    this.onOpenInNewTab,
    this.onRectSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        if (store.isLoading.value) {
          return Center(
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
        return SignalBuilder(
          builder: (context) {
            if (store.trashAccessDenied.value) {
              return const _TrashPermissionPrompt();
            }
            if (store.accessDenied.value) {
              return const _AccessDeniedPrompt();
            }
            final loadError = store.loadError.value;
            if (loadError != null) {
              return _LoadErrorNotice(message: loadError, onRetry: store.refresh);
            }
            final files = store.visibleFiles.value;
            final selected = store.selectedPaths.value;
            final cursorIndex = store.cursorIndex.value;
            final cutPaths = store.clipboardMode.value == ClipboardMode.cut
                ? store.clipboardPaths.value
                : <String>{};
            final currentPath = store.currentPath.value;
            return FileList(
              files: files,
              currentPath: currentPath,
              recursiveResults:
                  store.searchActive.value && store.searchRecursive.value,
              onSelect: store.onSelect,
              onOpen: store.onOpen,
              onBackgroundTap: store.onBackgroundTap,
              onBackgroundContextMenu: onBackgroundContextMenu,
              onContextMenu: onContextMenu,
              onMenuAction: onMenuAction,
              onDropFiles: store.dropFiles,
              selectedPaths: selected,
              cursorIndex: cursorIndex,
              cutPaths: cutPaths,
              renamingPath: store.renamingPath.value,
              renameAttempt: store.renameAttempt.value,
              onRenameSubmit: store.commitRename,
              onRenameCancel: store.cancelRename,
              onCloseSearch: store.closeSearch,
              onOpenInNewTab: onOpenInNewTab,
              onRectSelect: onRectSelect,
              sortColumn: store.sortKey.value,
              sortAscending: store.sortAscending.value,
              onSortColumn: store.cycleSortColumn,
              onPageRows: store.setPageRows,
            );
          },
        );
      },
    );
  }
}

class _TerminalPanel extends StatefulWidget {
  final int slot;
  final List<TerminalTab> tabs;
  final TerminalTab active;
  final double height;
  final bool isSingleMode;
  final void Function(int slot)? onToggleTerminal;
  final void Function(int slot, int id)? onActivate;
  final void Function(int slot, int id)? onSelectTab;
  final void Function(int id)? onCloseTab;
  final void Function(int slot)? onNewTab;
  final void Function(int slot, int dir)? onCycleTab;
  final void Function(int slot, int from, int to)? onReorderTab;
  final void Function(int slot, double height)? onHeightChanged;
  final VoidCallback? onReturnFocusToFiles;

  const _TerminalPanel({
    required this.slot,
    required this.tabs,
    required this.active,
    required this.height,
    required this.isSingleMode,
    this.onToggleTerminal,
    this.onActivate,
    this.onSelectTab,
    this.onCloseTab,
    this.onNewTab,
    this.onCycleTab,
    this.onReorderTab,
    this.onHeightChanged,
    this.onReturnFocusToFiles,
  });

  @override
  State<_TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<_TerminalPanel> {
  bool _focused = false;
  double? _dragHeight;

  double get _effectiveHeight => _dragHeight ?? widget.height;

  void _onResizeDrag(double dy) {
    final base = _dragHeight ?? widget.height;
    setState(() => _dragHeight = (base - dy).clamp(80.0, 900.0));
  }

  void _onResizeEnd() {
    final h = _dragHeight;
    if (h != null) widget.onHeightChanged?.call(widget.slot, h);
  }

  @override
  void initState() {
    super.initState();
    _focused = widget.active.focusNode.hasFocus;
    widget.active.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _TerminalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_dragHeight != null && widget.height == _dragHeight) {
      _dragHeight = null;
    }
    if (oldWidget.active.id == widget.active.id) return;
    oldWidget.active.focusNode.removeListener(_onFocusChange);
    _focused = widget.active.focusNode.hasFocus;
    widget.active.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.active.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    final focused = widget.active.focusNode.hasFocus;
    if (focused != _focused) setState(() => _focused = focused);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.physicalKey == AppShortcuts.terminalTogglePhysicalKey &&
        AppShortcuts.isControl &&
        !HardwareKeyboard.instance.isAltPressed) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        widget.onToggleTerminal?.call(widget.slot);
      } else {
        widget.onReturnFocusToFiles?.call();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed &&
        HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        event.physicalKey == PhysicalKeyboardKey.keyT) {
      widget.onNewTab?.call(widget.slot);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed &&
        HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        event.physicalKey == PhysicalKeyboardKey.keyW) {
      widget.onCloseTab?.call(widget.active.id);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        event.physicalKey == PhysicalKeyboardKey.pageDown) {
      widget.onCycleTab?.call(widget.slot, 1);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isShiftPressed &&
        !HardwareKeyboard.instance.isAltPressed &&
        event.physicalKey == PhysicalKeyboardKey.pageUp) {
      widget.onCycleTab?.call(widget.slot, -1);
      return KeyEventResult.handled;
    }
    if (event is KeyDownEvent &&
        HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isAltPressed) {
      final settings = SettingsStore.instance;
      final key = event.physicalKey;
      if (key == PhysicalKeyboardKey.equal) {
        settings.increaseTerminalFontSize();
        return KeyEventResult.handled;
      }
      if (key == PhysicalKeyboardKey.minus) {
        settings.decreaseTerminalFontSize();
        return KeyEventResult.handled;
      }
      if (key == PhysicalKeyboardKey.digit0) {
        settings.resetTerminalFontSize();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TerminalResizeHandle(onDrag: _onResizeDrag, onDragEnd: _onResizeEnd),
        _TerminalHeader(
          focused: _focused,
          slot: widget.slot,
          tabs: widget.tabs,
          active: widget.active,
          isSingleMode: widget.isSingleMode,
          onSelectTab: widget.onSelectTab,
          onCloseTab: widget.onCloseTab,
          onNewTab: widget.onNewTab,
          onClose: widget.onToggleTerminal,
          onReorderTab: widget.onReorderTab,
        ),
        SizedBox(
          height: _effectiveHeight,
          child: Listener(
            onPointerDown: (_) =>
                widget.onActivate?.call(widget.slot, widget.active.id),
            child: SignalBuilder(
              builder: (context) {
                final settings = SettingsStore.instance;
                final useSystem = settings.terminalUseSystemFont.value;
                final family = settings.terminalFontFamily.value.trim();
                return TerminalView(
                  widget.active.session.terminal,
                  focusNode: widget.active.focusNode,
                  theme: _appTerminalTheme(),
                  textStyle: TerminalStyle(
                    fontSize: settings.terminalFontSize.value.toDouble(),
                    height: settings.terminalLineHeight.value,
                    fontFamily: (useSystem || family.isEmpty)
                        ? 'monospace'
                        : family,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  onKeyEvent: _onKeyEvent,
                  hardwareKeyboardOnly: Platform.isWindows,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

TerminalTheme _appTerminalTheme() {
  final c = AppColors.terminal;
  return TerminalTheme(
    cursor: AppColors.accent,
    selection: AppColors.accent.withValues(alpha: 0.30),
    foreground: AppColors.fg,
    background: AppColors.bg,
    black: c.black,
    red: c.red,
    green: c.green,
    yellow: c.yellow,
    blue: c.blue,
    magenta: c.magenta,
    cyan: c.cyan,
    white: c.white,
    brightBlack: c.brightBlack,
    brightRed: c.brightRed,
    brightGreen: c.brightGreen,
    brightYellow: c.brightYellow,
    brightBlue: c.brightBlue,
    brightMagenta: c.brightMagenta,
    brightCyan: c.brightCyan,
    brightWhite: c.brightWhite,
    searchHitBackground: AppColors.warning,
    searchHitBackgroundCurrent: AppColors.accent,
    searchHitForeground: AppColors.bg,
  );
}

class _TerminalHeader extends StatelessWidget {
  final bool focused;
  final int slot;
  final List<TerminalTab> tabs;
  final TerminalTab active;
  final bool isSingleMode;
  final void Function(int slot, int id)? onSelectTab;
  final void Function(int id)? onCloseTab;
  final void Function(int slot)? onNewTab;
  final void Function(int slot)? onClose;
  final void Function(int slot, int from, int to)? onReorderTab;

  const _TerminalHeader({
    required this.focused,
    required this.slot,
    required this.tabs,
    required this.active,
    required this.isSingleMode,
    this.onSelectTab,
    this.onCloseTab,
    this.onNewTab,
    this.onClose,
    this.onReorderTab,
  });

  @override
  Widget build(BuildContext context) {
    final fg = focused ? AppColors.fg : AppColors.fgMuted;
    return Opacity(
      opacity: focused ? 1.0 : 0.55,
      child: Container(
        height: 28,
        padding: const EdgeInsets.only(left: 10, right: 4),
        decoration: BoxDecoration(
          color: AppColors.bgStatus,
          border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
        ),
        child: Row(
          children: [
            Icon(WaydirIconsRegular.terminal, size: 13, color: fg),
            const SizedBox(width: 7),
            Expanded(
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                padding: EdgeInsets.zero,
                itemCount: tabs.length,
                onReorderItem: (from, to) => onReorderTab?.call(slot, from, to),
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  return ReorderableDragStartListener(
                    key: ValueKey('terminal-tab:${tab.id}'),
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _TerminalTabChip(
                        tab: tab,
                        active: tab.id == active.id,
                        foreign: isSingleMode && tab.originPane == 1,
                        onSelect: () => onSelectTab?.call(slot, tab.id),
                        onClose: () => onCloseTab?.call(tab.id),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 4),
            if (onClose != null)
              _TerminalIconButton(
                icon: WaydirIconsRegular.plus,
                onTap: () => onNewTab?.call(slot),
              ),
            if (onClose != null) const SizedBox(width: 2),
            if (onClose != null)
              AppCloseButton(onTap: () => onClose!(slot), size: 22),
          ],
        ),
      ),
    );
  }
}

class _TerminalTabChip extends StatefulWidget {
  final TerminalTab tab;
  final bool active;
  final bool foreign;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  const _TerminalTabChip({
    required this.tab,
    required this.active,
    required this.foreign,
    required this.onSelect,
    required this.onClose,
  });

  @override
  State<_TerminalTabChip> createState() => _TerminalTabChipState();
}

class _TerminalTabChipState extends State<_TerminalTabChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tab = widget.tab;
    final active = widget.active;
    final foreign = widget.foreign;
    final fg = active ? AppColors.fg : AppColors.fgMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onSelect,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.only(left: 8, right: 4),
          decoration: BoxDecoration(
            color: active || _hovered ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: active ? AppColors.bgDivider : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (foreign) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  tab.label,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.row.copyWith(color: fg),
                ),
              ),
              const SizedBox(width: 4),
              _TerminalIconButton(
                icon: WaydirIconsRegular.x,
                onTap: widget.onClose,
                size: 18,
                iconSize: 11,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerminalIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  const _TerminalIconButton({
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.iconSize = 13,
  });

  @override
  State<_TerminalIconButton> createState() => _TerminalIconButtonState();
}

class _TerminalIconButtonState extends State<_TerminalIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _hovered ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

class _TerminalResizeHandle extends StatefulWidget {
  final ValueChanged<double> onDrag;
  final VoidCallback onDragEnd;

  const _TerminalResizeHandle({required this.onDrag, required this.onDragEnd});

  @override
  State<_TerminalResizeHandle> createState() => _TerminalResizeHandleState();
}

class _TerminalResizeHandleState extends State<_TerminalResizeHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeRow,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) => widget.onDrag(details.delta.dy),
        onVerticalDragEnd: (_) => widget.onDragEnd(),
        child: Container(
          height: 5,
          color: _hovered ? AppColors.accent : AppColors.bgDivider,
        ),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  final String title;
  final String body;
  final List<Widget> actions;

  const _PermissionNotice({
    required this.title,
    required this.body,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              WaydirIconsRegular.warningCircle,
              size: 48,
              color: AppColors.fgSubtle,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.txt.dialogTitle.copyWith(color: AppColors.fgMuted),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: context.txt.body.copyWith(
                color: AppColors.fgMuted,
                height: 1.35,
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: actions,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrashPermissionPrompt extends StatelessWidget {
  const _TrashPermissionPrompt();

  @override
  Widget build(BuildContext context) {
    return _PermissionNotice(
      title: t.trash.accessDeniedTitle,
      body: t.trash.accessDeniedBody,
      actions: [
        _PromptButton(
          label: t.trash.openSystemSettings,
          onTap: openFullDiskAccessSettings,
        ),
      ],
    );
  }
}

class _AccessDeniedPrompt extends StatelessWidget {
  const _AccessDeniedPrompt();

  @override
  Widget build(BuildContext context) {
    return _PermissionNotice(
      title: t.folderAccess.deniedTitle,
      body: t.folderAccess.deniedBody,
      actions: [
        if (Platform.isMacOS)
          _PromptButton(
            label: t.folderAccess.openSystemSettings,
            onTap: openFullDiskAccessSettings,
          ),
      ],
    );
  }
}

/// Generic fallback when a folder fails to load for a non-permission reason.
class _LoadErrorNotice extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadErrorNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _PermissionNotice(
      title: t.folderAccess.errorTitle,
      body: message,
      actions: [_PromptButton(label: t.folderAccess.retry, onTap: onRetry)],
    );
  }
}

class _PromptButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PromptButton({required this.label, required this.onTap});

  @override
  State<_PromptButton> createState() => _PromptButtonState();
}

class _PromptButtonState extends State<_PromptButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = _hovered ? AppColors.accentHover : AppColors.accent;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.zero),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(WaydirIconsRegular.gearSix, size: 15, color: AppColors.bg),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: context.txt.bodyEmphasis.copyWith(color: AppColors.bg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
