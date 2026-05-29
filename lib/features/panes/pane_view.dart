import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import 'package:waydir_term/xterm.dart';
import '../../core/keyboard/keyboard_shortcuts.dart';
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
    this.onHeightChanged,
    this.onReturnFocusToFiles,
  });

  @override
  State<_TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends State<_TerminalPanel> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focused = widget.active.focusNode.hasFocus;
    widget.active.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _TerminalPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
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
        _TerminalResizeHandle(
          slot: widget.slot,
          height: widget.height,
          onHeightChanged: widget.onHeightChanged,
        ),
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
        ),
        SizedBox(
          height: widget.height,
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
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  return _TerminalTabChip(
                    tab: tab,
                    active: tab.id == active.id,
                    foreign: isSingleMode && tab.originPane == 1,
                    onSelect: () => onSelectTab?.call(slot, tab.id),
                    onClose: () => onCloseTab?.call(tab.id),
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

class _TerminalTabChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final fg = active ? AppColors.fg : AppColors.fgMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.only(left: 8, right: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.bgHover : Colors.transparent,
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
              onTap: onClose,
              size: 18,
              iconSize: 11,
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalIconButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(icon, size: iconSize, color: AppColors.fgMuted),
        ),
      ),
    );
  }
}

class _TerminalResizeHandle extends StatefulWidget {
  final int slot;
  final double height;
  final void Function(int slot, double height)? onHeightChanged;

  const _TerminalResizeHandle({
    required this.slot,
    required this.height,
    this.onHeightChanged,
  });

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
        onVerticalDragUpdate: (details) {
          final next = (widget.height - details.delta.dy).clamp(80.0, 900.0);
          widget.onHeightChanged?.call(widget.slot, next);
        },
        child: Container(
          height: 5,
          color: _hovered ? AppColors.accent : AppColors.bgDivider,
        ),
      ),
    );
  }
}

class _TrashPermissionPrompt extends StatelessWidget {
  const _TrashPermissionPrompt();

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
              t.trash.accessDeniedTitle,
              textAlign: TextAlign.center,
              style: context.txt.dialogTitle.copyWith(color: AppColors.fgMuted),
            ),
            const SizedBox(height: 8),
            Text(
              t.trash.accessDeniedBody,
              textAlign: TextAlign.center,
              style: context.txt.body.copyWith(
                color: AppColors.fgMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            _PromptButton(
              label: t.trash.openSystemSettings,
              onTap: () {
                unawaited(
                  Process.run('open', [
                    'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles',
                  ]),
                );
              },
            ),
          ],
        ),
      ),
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
