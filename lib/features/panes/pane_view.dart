import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
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

  const PaneView({
    super.key,
    required this.pane,
    required this.isActive,
    required this.onActivate,
    this.onBackgroundContextMenu,
    this.onContextMenu,
    this.onMenuAction,
    this.onOpenInNewTab,
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
              Watch(
                (_) => PaneLocationBar(store: pane.tabs.activeTab.value.store),
              ),
              Watch(
                (_) => pane.tabs.activeTab.value.store.searchActive.value
                    ? AppSearchBar(store: pane.tabs.activeTab.value.store)
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Watch((_) {
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
                          onRectSelect: (paths, {additive = false}) =>
                              tab.store.onRectSelect(paths, additive: additive),
                        ),
                    ],
                  );
                }),
              ),
              Watch((_) {
                final gitStore = pane.tabs.activeTab.value.store.gitStatus;
                final status = gitStore.status.value;
                if (status == null) return const SizedBox.shrink();
                return GitStatusBar(status: status, store: gitStore);
              }),
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
    return Watch((context) {
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
      return Watch((context) {
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
      });
    });
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
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
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
