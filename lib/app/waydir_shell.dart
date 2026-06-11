import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../core/archive/archive_path.dart';
import '../core/archive/archive_writer.dart';
import '../core/fs/file_system_service.dart';
import '../core/logging/app_logger.dart';
import '../features/locations/location_resolver.dart';
import '../core/open/open_service.dart';
import '../core/keyboard/keyboard_shortcuts.dart';
import '../core/platform/full_disk_access.dart';
import '../core/platform/platform_paths.dart';
import '../core/models/app_notification.dart';
import '../core/models/file_entry.dart';
import '../core/models/file_operation.dart';
import '../core/settings/settings_store.dart';
import '../core/update/update_store.dart';
import '../features/checksum/checksum_dialog.dart';
import '../features/help/help_dialog.dart';
import '../features/update/update_dialog.dart';
import '../features/navigation/navigation_store.dart';
import '../features/navigation/sidebar.dart';
import '../features/navigation/status_bar.dart';
import '../features/onboarding/full_disk_access_dialog.dart';
import '../features/operations/operation_store.dart';
import '../features/panes/pane_view.dart';
import '../features/panes/pane_divider.dart';
import '../features/panes/shell_store.dart';
import '../features/panes/terminal_tab.dart';
import '../features/plugins/plugin_bar.dart';
import '../features/plugins/plugin_form_dialog.dart';
import '../features/plugins/plugin_icons.dart';
import '../features/plugins/plugin_models.dart';
import '../features/plugins/plugin_settings_store.dart';
import '../features/plugins/plugin_store.dart';
import '../features/settings/preferences_view.dart';
import '../i18n/strings.g.dart';
import '../ui/chrome/title_bar.dart';
import '../ui/dialogs/compress_dialog.dart';
import '../ui/dialogs/dialog.dart';
import '../ui/dialogs/multi_rename_dialog.dart';
import '../ui/dialogs/open_with_dialog.dart';
import '../ui/overlays/context_menu.dart';
import '../ui/overlays/notification_overlay.dart';
import '../features/navigation/select_pattern_dialog.dart';
import '../features/quick_look/quick_look.dart';
import '../ui/overlays/notification_store.dart';
import '../ui/overlays/toast.dart';
import '../ui/theme/app_theme.dart';
import '../ui/theme/app_text_styles.dart';
import '../ui/window/window.dart';

part 'waydir_shell/base.dart';
part 'waydir_shell/actions.dart';
part 'waydir_shell/terminal.dart';
part 'waydir_shell/menus.dart';
part 'waydir_shell/keyboard.dart';

class WaydirShell extends StatefulWidget {
  const WaydirShell({super.key});

  @override
  State<WaydirShell> createState() => _WaydirShellState();
}

class _WaydirShellState extends State<WaydirShell>
    with
        _WaydirStateBase,
        _WaydirActionsMixin,
        _WaydirTerminalMixin,
        _WaydirMenuMixin,
        _WaydirKeyboardMixin {
  @override
  void initState() {
    super.initState();
    _operationStore.confirmTransfer = _confirmTransfer;
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
            final destLogical = LocationResolver.physicalToLogical(
              task.destination ?? '',
            );
            for (final store in _shell.allStores) {
              final cp = store.currentPath.value;
              final destMatches = task.destination == cp || destLogical == cp;
              final isTrashTask =
                  task.type == TaskType.trashRestore ||
                  task.type == TaskType.trashDelete;
              final isRemoval =
                  task.type == TaskType.delete || task.type == TaskType.trash;
              final removalMatches =
                  isRemoval &&
                  task.sources.any((s) {
                    final d = p.dirname(s);
                    return d == cp ||
                        LocationResolver.physicalToLogical(d) == cp;
                  });
              if (destMatches ||
                  (isTrashTask && store.isTrashView) ||
                  removalMatches) {
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
        if (!isWindowChromeSupported) return;
        final pane = _shell.activePane.value;
        if (pane == null) {
          appWindow.title = t.app.title;
          return;
        }
        final title = pane.tabs.activeTab.value.title.value;
        appWindow.title = '$title - ${t.app.title}';
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
    _installUpdateNotification();
    _maybePromptFullDiskAccess();
  }

  void _maybePromptFullDiskAccess() {
    if (!Platform.isMacOS) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (await hasFullDiskAccess()) return;
      if (!mounted) return;
      await showFullDiskAccessDialog(context);
    });
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
    for (final d in _renameFocusDisposers.values) {
      d();
    }
    _renameFocusDisposers.clear();
    _focusNode.dispose();
    _notificationStore.dispose();
    _shell.dispose();
    _operationStore.dispose();
    super.dispose();
  }

  Widget _buildPane(
    int slot, {
    required bool isActive,
    required VoidCallback onActivate,
    required bool isSingleMode,
  }) {
    return PaneView(
      pane: _shell.panes.value[slot],
      isActive: isActive,
      onActivate: onActivate,
      onBackgroundContextMenu: _handleBackgroundContextMenu,
      onContextMenu: _handleContextMenu,
      onMenuAction: _handleMenuAction,
      onOpenInNewTab: _openInNewTab,
      onMultiRename: _multiRename,
      onPluginToolbarAction: (id) => _runPluginAction(id, background: true),
      onPluginBarEffects: (effects, target) =>
          _applyPluginEffects(effects, target, background: true),
      terminalSlot: slot,
      terminalTabs: _shell.terminalsForSlot(slot),
      activeTerminal: _shell.activeTerminalForSlot(slot),
      terminalVisible: _shell.terminalVisible.value[slot],
      terminalHeight: _shell.terminalHeight.value[slot],
      isSingleMode: isSingleMode,
      onToggleTerminal: _toggleTerminalSlot,
      onTerminalActivate: _activateTerminal,
      onSelectTerminalTab: _selectTerminalTab,
      onCloseTerminalTab: _closeTerminalTab,
      onNewTerminalTab: _newTerminalTab,
      onCycleTerminalTab: _cycleTerminalTab,
      onReorderTerminalTab: _shell.reorderTerminalTab,
      onTerminalHeightChanged: _setTerminalHeight,
      onReturnFocusToFiles: _focusFiles,
    );
  }

  Widget _buildPaneArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SignalBuilder(
          builder: (_) {
            final dual = _shell.isDual.value;
            final activeIdx = _shell.activePaneIndex.value;

            if (!dual) {
              return _buildPane(
                0,
                isActive: true,
                onActivate: _restoreFocus,
                isSingleMode: true,
              );
            }

            final ratio = _shell.splitRatio.value;
            final leftFlex = (ratio * 1000).round();
            final rightFlex = ((1 - ratio) * 1000).round();

            return Row(
              children: [
                Flexible(
                  flex: leftFlex,
                  child: _buildPane(
                    0,
                    isActive: activeIdx == 0,
                    onActivate: _activatePane(0),
                    isSingleMode: false,
                  ),
                ),
                PaneDivider(shell: _shell, totalWidth: constraints.maxWidth),
                Flexible(
                  flex: rightFlex,
                  child: _buildPane(
                    1,
                    isActive: activeIdx == 1,
                    onActivate: _activatePane(1),
                    isSingleMode: false,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _pluginBarContext(
    NavigationStore store, {
    required String scope,
    int? pane,
    bool isActive = true,
  }) {
    final paths = store.selectedPaths.value.toList()..sort();
    return {
      'scope': scope,
      'pane': pane,
      'is_active': isActive,
      'dir': store.currentPath.value,
      'paths': paths,
    };
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
            SignalBuilder(
              builder: (_) {
                if (_shell.ready.value) {
                  _active.selectedCount.value;
                  _active.visibleFiles.value.length;
                }
                return TitleBar(
                  menuTrailing: _buildViewMenu(),
                  platformMenus: _platformViewMenus(),
                  child: SignalBuilder(
                    builder: (context) {
                      if (!_shell.ready.value) {
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
                                Expanded(child: _buildPaneArea()),
                              ],
                            ),
                          ),
                          SignalBuilder(
                            builder: (context) {
                              final bars = PluginStore.instance
                                  .globalBarContributions();
                              if (bars.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final ctx = _pluginBarContext(
                                _active,
                                scope: 'global',
                              );
                              return PluginBarHost(
                                hostId: 'global',
                                bars: bars,
                                contextData: ctx,
                                contextKey: jsonEncode(ctx),
                                onEffects: (effects, target) =>
                                    _applyPluginEffects(
                                      effects,
                                      target,
                                      background: true,
                                    ),
                              );
                            },
                          ),
                          SignalBuilder(
                            builder: (context) => StatusBar(
                              store: _active,
                              operationStore: _operationStore,
                              notificationStore: _notificationStore,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
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
  static const _minExpanded = 160.0;
  static const _maxExpanded = 400.0;
  // Drag the expanded sidebar narrower than this and it snaps to the icon rail.
  static const _collapseThreshold = 120.0;
  static const _animDuration = Duration(milliseconds: 140);

  double? _dragWidth;
  bool _dragging = false;

  void _toggleUserCollapsed() {
    final s = SettingsStore.instance.sidebarCollapsed;
    s.value = !s.value;
  }

  void _onDragStart(DragStartDetails _) {
    final settings = SettingsStore.instance;
    // Seed the live width from whatever is currently on screen so the handle
    // tracks the pointer continuously in both directions.
    _dragWidth = settings.sidebarCollapsed.value
        ? _railWidth
        : settings.sidebarWidth.value.clamp(_minExpanded, _maxExpanded);
    setState(() => _dragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final settings = SettingsStore.instance;
    final next = ((_dragWidth ?? _railWidth) + details.delta.dx).clamp(
      _railWidth,
      _maxExpanded,
    );

    // Collapsed state is derived purely from the live width crossing the
    // threshold, so collapse and expand are symmetric and repeatable.
    final shouldCollapse = next < _collapseThreshold;
    if (settings.sidebarCollapsed.value != shouldCollapse) {
      settings.sidebarCollapsed.value = shouldCollapse;
    }
    if (!shouldCollapse) {
      settings.sidebarWidth.value = next.clamp(_minExpanded, _maxExpanded);
    }
    setState(() => _dragWidth = next);
  }

  void _onDragEnd() {
    setState(() {
      _dragging = false;
      _dragWidth = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final settings = SettingsStore.instance;
        final collapsed = settings.sidebarCollapsed.value;
        final width =
            _dragWidth ??
            (collapsed
                ? _railWidth
                : settings.sidebarWidth.value.clamp(
                    _minExpanded,
                    _maxExpanded,
                  ));

        return AnimatedContainer(
          duration: _dragging ? Duration.zero : _animDuration,
          curve: Curves.easeOut,
          width: width,
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRect(
                  child: Sidebar(
                    store: widget.active,
                    operationStore: widget.operationStore,
                    onOpenInNewTab: widget.onOpenInNewTab,
                    collapsed: collapsed,
                    onToggleCollapsed: _toggleUserCollapsed,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: _SidebarResizeHandle(
                  onDragStart: _onDragStart,
                  onDragUpdate: _onDragUpdate,
                  onDragEnd: _onDragEnd,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarResizeHandle extends StatefulWidget {
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final VoidCallback onDragEnd;

  const _SidebarResizeHandle({
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: widget.onDragStart,
        onHorizontalDragUpdate: widget.onDragUpdate,
        onHorizontalDragEnd: (_) => widget.onDragEnd(),
        onHorizontalDragCancel: widget.onDragEnd,
        child: SizedBox(
          width: 8,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: _hovered ? 2 : 1,
              color: _hovered ? AppColors.accent : AppColors.bgDivider,
            ),
          ),
        ),
      ),
    );
  }
}
