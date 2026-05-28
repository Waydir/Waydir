import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import 'package:waydir_term/xterm.dart';
import '../../core/terminal/pty_session.dart';
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

class PaneView extends StatelessWidget {
  final PaneStore pane;
  final bool isActive;
  final VoidCallback onActivate;
  final BackgroundContextMenuCallback? onBackgroundContextMenu;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final OpenInNewTabCallback? onOpenInNewTab;
  final void Function(NavigationStore store)? onMultiRename;
  final VoidCallback? onToggleTerminal;
  final void Function(PaneStore pane)? onTerminalActivate;
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
    this.onToggleTerminal,
    this.onTerminalActivate,
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
              SignalBuilder(
                builder: (_) {
                  if (!pane.terminalVisible.value) {
                    return const SizedBox.shrink();
                  }
                  final session = pane.activeTerminal;
                  if (session == null) return const SizedBox.shrink();
                  return _TerminalPanel(
                    pane: pane,
                    session: session,
                    onToggleTerminal: onToggleTerminal,
                    onActivate: onTerminalActivate,
                    onReturnFocusToFiles: onReturnFocusToFiles,
                  );
                },
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
  final PaneStore pane;
  final PtySession session;
  final VoidCallback? onToggleTerminal;
  final void Function(PaneStore pane)? onActivate;
  final VoidCallback? onReturnFocusToFiles;

  const _TerminalPanel({
    required this.pane,
    required this.session,
    this.onToggleTerminal,
    this.onActivate,
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
    _focused = widget.pane.terminalFocusNode.hasFocus;
    widget.pane.terminalFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.pane.terminalFocusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    final focused = widget.pane.terminalFocusNode.hasFocus;
    if (focused != _focused) setState(() => _focused = focused);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.physicalKey == PhysicalKeyboardKey.backquote &&
        HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isAltPressed) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        widget.onToggleTerminal?.call();
      } else {
        widget.onReturnFocusToFiles?.call();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final pane = widget.pane;
    return SignalBuilder(
      builder: (_) {
        final height = pane.terminalHeight.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TerminalResizeHandle(pane: pane),
            _TerminalHeader(focused: _focused, onClose: widget.onToggleTerminal),
            SizedBox(
              height: height,
              child: Listener(
                onPointerDown: (_) => widget.onActivate?.call(pane),
                child: TerminalView(
                  widget.session.terminal,
                  focusNode: pane.terminalFocusNode,
                  theme: _appTerminalTheme(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  onKeyEvent: _onKeyEvent,
                ),
              ),
            ),
          ],
        );
      },
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
  final VoidCallback? onClose;

  const _TerminalHeader({required this.focused, this.onClose});

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
            Text(t.terminal.title, style: context.txt.body.copyWith(color: fg)),
            const Spacer(),
            if (onClose != null) AppCloseButton(onTap: onClose!, size: 22),
          ],
        ),
      ),
    );
  }
}

class _TerminalResizeHandle extends StatefulWidget {
  final PaneStore pane;

  const _TerminalResizeHandle({required this.pane});

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
          final next = (widget.pane.terminalHeight.value - details.delta.dy)
              .clamp(80.0, 900.0);
          widget.pane.terminalHeight.value = next;
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
