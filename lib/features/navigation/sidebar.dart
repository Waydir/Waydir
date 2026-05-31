import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../../core/database/app_database.dart';
import 'bookmark_store.dart';
import 'navigation_store.dart';
import '../drives/drive_store.dart';
import '../drives/drive_model.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/dialogs/password_dialog.dart';
import '../../ui/dialogs/rename_dialog.dart';
import '../../ui/dialogs/sftp_credentials_dialog.dart';
import '../../ui/overlays/context_menu.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';
import '../../i18n/strings.g.dart';
import '../../utils/drag_drop.dart';
import '../../utils/format.dart';
import '../locations/connect_to_server_dialog.dart';
import '../locations/location_resolver.dart';
import '../locations/location_uri.dart';
import '../operations/drag_hint.dart';
import '../operations/operation_store.dart';
import '../operations/operations_panel.dart';
import '../../core/models/file_operation.dart';

class _SidebarItem {
  final String label;
  final IconData icon;
  final String path;
  const _SidebarItem(this.label, this.icon, this.path);
}

class Sidebar extends StatefulWidget {
  final NavigationStore store;
  final OperationStore operationStore;
  final void Function(String path)? onOpenInNewTab;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  const Sidebar({
    super.key,
    required this.store,
    required this.operationStore,
    this.onOpenInNewTab,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  late final List<_SidebarItem> _favorites;
  late final Future<SmbCredentials?> Function(String logical)
  _credentialsRequester;
  late final Future<SftpCredentials?> Function(String logical)
  _sftpCredentialsRequester;
  final _bookmarkStore = BookmarkStore.instance;

  @override
  void initState() {
    super.initState();
    _credentialsRequester = _requestSmbCredentials;
    _sftpCredentialsRequester = _requestSftpCredentials;
    final h = PlatformPaths.homePath;
    _favorites = [
      _SidebarItem(t.sidebar.home, WaydirIconsRegular.house, h),
      _SidebarItem(
        t.sidebar.desktop,
        WaydirIconsRegular.desktop,
        PlatformPaths.desktopPath,
      ),
      _SidebarItem(
        t.sidebar.documents,
        WaydirIconsRegular.notebook,
        PlatformPaths.documentsPath,
      ),
      _SidebarItem(
        t.sidebar.downloads,
        WaydirIconsRegular.downloadSimple,
        PlatformPaths.downloadsPath,
      ),
      _SidebarItem(
        t.sidebar.pictures,
        WaydirIconsRegular.image,
        PlatformPaths.picturesPath,
      ),
      _SidebarItem(
        t.sidebar.music,
        WaydirIconsRegular.musicNote,
        PlatformPaths.musicPath,
      ),
      _SidebarItem(
        t.sidebar.videos,
        WaydirIconsRegular.videoCamera,
        PlatformPaths.videosPath,
      ),
      if (PlatformPaths.canOpenTrash)
        _SidebarItem(
          t.sidebar.trash,
          WaydirIconsRegular.trashSimple,
          kTrashPath,
        ),
    ];
    final trashDir = PlatformPaths.trashPath;
    if (trashDir != null) {
      try {
        Directory(trashDir).createSync(recursive: true);
      } catch (_) {}
    }
    _bookmarkStore.load();
    widget.store.requestSmbCredentials = _credentialsRequester;
    widget.store.requestSftpCredentials = _sftpCredentialsRequester;
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      if (oldWidget.store.requestSmbCredentials == _credentialsRequester) {
        oldWidget.store.requestSmbCredentials = null;
      }
      widget.store.requestSmbCredentials = _credentialsRequester;
      if (oldWidget.store.requestSftpCredentials == _sftpCredentialsRequester) {
        oldWidget.store.requestSftpCredentials = null;
      }
      widget.store.requestSftpCredentials = _sftpCredentialsRequester;
    }
  }

  @override
  void dispose() {
    if (widget.store.requestSmbCredentials == _credentialsRequester) {
      widget.store.requestSmbCredentials = null;
    }
    if (widget.store.requestSftpCredentials == _sftpCredentialsRequester) {
      widget.store.requestSftpCredentials = null;
    }
    super.dispose();
  }

  Future<SmbCredentials?> _requestSmbCredentials(String logical) async {
    final uri = LocationUri.parse(logical);
    final result = await showSmbCredentialsDialog(
      context,
      title: uri.displayLabel,
      username: uri.username,
    );
    if (result == null) return null;
    return SmbCredentials(username: result.username, password: result.password);
  }

  Future<SftpCredentials?> _requestSftpCredentials(String logical) async {
    final uri = LocationUri.parse(logical);
    return showSftpCredentialsDialog(
      context,
      title: uri.displayLabel,
      username: uri.username,
    );
  }

  Future<void> _renameBookmark(Bookmark bookmark) async {
    final label = await showRenameDialog(
      context,
      title: t.menu.rename,
      icon: WaydirIconsRegular.pencilSimple,
      initialValue: bookmark.label,
    );
    if (label != null && label != bookmark.label) {
      await _bookmarkStore.rename(bookmark, label);
    }
  }

  void _showBookmarkMenu(Bookmark bookmark, Offset position) {
    showContextMenu(
      context: context,
      position: position,
      items: [
        ContextMenuItem(
          icon: WaydirIconsRegular.folderOpen,
          label: t.menu.open,
          action: 'open',
        ),
        ContextMenuItem(
          icon: WaydirIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: WaydirIconsRegular.pencilSimple,
          label: t.menu.rename,
          action: 'rename',
        ),
        ContextMenuItem(
          icon: WaydirIconsRegular.trash,
          label: t.menu.removeBookmark,
          action: 'remove',
          danger: true,
        ),
      ],
      onSelect: (action) {
        switch (action) {
          case 'open':
            widget.store.navigateTo(bookmark.path);
          case 'open_in_new_tab':
            widget.onOpenInNewTab?.call(bookmark.path);
          case 'rename':
            _renameBookmark(bookmark);
          case 'remove':
            _bookmarkStore.remove(bookmark);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSidebar,
      child: Column(
        children: [
          _SidebarHeader(
            collapsed: widget.collapsed,
            onToggle: widget.onToggleCollapsed,
          ),
          Expanded(
            child: _SidebarDropTarget(
              onDropBookmark: _bookmarkStore.addPath,
              child: SignalBuilder(
                builder: (context) {
                  final currentPath = widget.store.currentPath.value;
                  final currentDrives = driveStore.drives.value;

                  final networkDrives = currentDrives
                      .where((d) => d.isNetwork)
                      .toList();
                  final devices = currentDrives
                      .where((d) => !d.isNetwork)
                      .toList();
                  final isUnix = PlatformPaths.isLinux || PlatformPaths.isMacOS;
                  if (isUnix && !devices.any((d) => d.mountPoint == '/')) {
                    devices.insert(
                      0,
                      Drive(
                        id: '/',
                        label: t.sidebar.root,
                        isRemovable: false,
                        mountPoint: '/',
                      ),
                    );
                  }

                  final collapsed = widget.collapsed;
                  final networkLocations = LocationResolver.mountedLocations();
                  return ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (!collapsed)
                        _SectionHeader(title: t.sidebar.favorites),
                      if (collapsed) const SizedBox(height: 6),
                      ..._favorites.map((item) {
                        final isRecycleBin = isTrashPath(item.path);
                        return _ItemRow(
                          item: item,
                          isSelected: isRecycleBin
                              ? isTrashPath(currentPath)
                              : currentPath == item.path,
                          isMounted: !isRecycleBin,
                          collapsed: collapsed,
                          onTap: widget.store.navigateTo,
                          onMiddleTap:
                              widget.onOpenInNewTab != null && !isRecycleBin
                              ? () => widget.onOpenInNewTab!(item.path)
                              : null,
                          onDropFiles: (paths, {bool move = false}) {
                            if (isRecycleBin) {
                              widget.operationStore.enqueueTrash(paths);
                              return;
                            }
                            widget.store.dropFiles(
                              paths,
                              item.path,
                              move: move,
                            );
                          },
                        );
                      }),
                      SizedBox(height: collapsed ? 12 : 8),
                      if (!collapsed)
                        _SectionHeader(title: t.sidebar.devices)
                      else
                        const _SectionRailDivider(),
                      ...devices.map((drive) {
                        final path = drive.mountPoint ?? drive.id;
                        final isSelected = currentPath == path;
                        final isMounted = drive.isMounted;
                        final label = drive.id == '/'
                            ? t.sidebar.root
                            : drive.label;
                        final canUnmount =
                            isMounted && drive.id != '/' && drive.isRemovable;

                        return _ItemRow(
                          item: _SidebarItem(
                            label,
                            drive.isRemovable
                                ? WaydirIconsRegular.usb
                                : WaydirIconsRegular.hardDrive,
                            path,
                          ),
                          isSelected: isSelected,
                          isMounted: isMounted,
                          space: isMounted ? drive.space : null,
                          collapsed: collapsed,
                          onTap: (p) async {
                            if (isMounted) {
                              widget.store.navigateTo(p);
                            } else {
                              try {
                                await driveStore.mount(drive);
                                Future.microtask(() {
                                  final mountedDrive = driveStore.drives.value
                                      .where((d) => d.id == drive.id)
                                      .firstOrNull;
                                  if (mountedDrive?.isMounted == true) {
                                    widget.store.navigateTo(
                                      mountedDrive!.mountPoint!,
                                    );
                                  }
                                });
                              } catch (e) {
                                final error = e.toString().toLowerCase();
                                if (error.contains('not authorized') ||
                                    error.contains('polkit') ||
                                    error.contains('authenticate')) {
                                  if (context.mounted) {
                                    final pwd = await showPasswordDialog(
                                      context,
                                      title: t.sidebar.drives.mountTitle(
                                        name: drive.label,
                                      ),
                                    );
                                    if (pwd != null) {
                                      try {
                                        await driveStore.mountWithPassword(
                                          drive,
                                          pwd,
                                        );
                                        Future.microtask(() {
                                          final mountedDrive = driveStore
                                              .drives
                                              .value
                                              .where((d) => d.id == drive.id)
                                              .firstOrNull;
                                          if (mountedDrive?.isMounted == true) {
                                            widget.store.navigateTo(
                                              mountedDrive!.mountPoint!,
                                            );
                                          }
                                        });
                                      } catch (_) {}
                                    }
                                  }
                                }
                              }
                            }
                          },
                          onMiddleTap:
                              widget.onOpenInNewTab != null && isMounted
                              ? () => widget.onOpenInNewTab!(path)
                              : null,
                          onDropFiles: (paths, {bool move = false}) {
                            if (isMounted) {
                              widget.store.dropFiles(paths, path, move: move);
                            }
                          },
                          onUnmount: canUnmount
                              ? () async {
                                  final currentPath =
                                      widget.store.currentPath.value;
                                  final mountPoint = drive.mountPoint;
                                  try {
                                    await driveStore.unmount(drive);
                                    if (mountPoint != null &&
                                        currentPath.startsWith(mountPoint)) {
                                      widget.store.navigateTo(
                                        PlatformPaths.homePath,
                                      );
                                    }
                                  } catch (_) {}
                                }
                              : null,
                        );
                      }),
                      SizedBox(height: collapsed ? 12 : 8),
                      if (networkLocations.isNotEmpty ||
                          networkDrives.isNotEmpty) ...[
                        _NetworkSection(
                          locations: networkLocations,
                          drives: networkDrives,
                          currentPath: currentPath,
                          collapsed: collapsed,
                          onNavigate: widget.store.navigateTo,
                          onOpenInNewTab: widget.onOpenInNewTab,
                          onDropFiles:
                              (paths, destination, {bool move = false}) =>
                                  widget.store.dropFiles(
                                    paths,
                                    destination,
                                    move: move,
                                  ),
                          onUnmountDrive: (drive) async {
                            final cur = widget.store.currentPath.value;
                            final mountPoint = drive.mountPoint ?? drive.id;
                            try {
                              await driveStore.unmount(drive);
                            } catch (_) {}
                            if (cur == mountPoint ||
                                cur.startsWith(mountPoint)) {
                              widget.store.navigateTo(PlatformPaths.homePath);
                            }
                          },
                          onUnmount: (path) async {
                            final currentPath = widget.store.currentPath.value;
                            await LocationResolver.unmount(path);
                            if (mounted) setState(() {});
                            if (currentPath == path ||
                                currentPath.startsWith('$path/')) {
                              widget.store.navigateTo(PlatformPaths.homePath);
                            }
                          },
                        ),
                        SizedBox(height: collapsed ? 12 : 8),
                      ],
                      SignalBuilder(
                        builder: (context) => _BookmarksSection(
                          bookmarks: _bookmarkStore.bookmarks.value,
                          currentPath: widget.store.currentPath.value,
                          collapsed: collapsed,
                          onNavigate: widget.store.navigateTo,
                          onOpenInNewTab: widget.onOpenInNewTab,
                          onDropFiles:
                              (paths, destination, {bool move = false}) =>
                                  widget.store.dropFiles(
                                    paths,
                                    destination,
                                    move: move,
                                  ),
                          onContextMenu: _showBookmarkMenu,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          _SidebarFooter(
            operationStore: widget.operationStore,
            collapsed: widget.collapsed,
            onConnect: () async {
              final uri = await openConnectToServer(context);
              if (uri != null) widget.store.navigateTo(uri);
            },
          ),
        ],
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final OperationStore operationStore;
  final bool collapsed;
  final VoidCallback onConnect;

  const _SidebarFooter({
    required this.operationStore,
    required this.collapsed,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border(top: BorderSide(color: AppColors.bgDivider));

    if (collapsed) {
      return DecoratedBox(
        decoration: BoxDecoration(border: border),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ConnectToServerButton(collapsed: true, onTap: onConnect),
              const SizedBox(height: 2),
              _SidebarOperationsButton(
                operationStore: operationStore,
                collapsed: true,
              ),
            ],
          ),
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(border: border),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ConnectToServerButton(collapsed: false, onTap: onConnect),
            const SizedBox(height: 4),
            _SidebarOperationsButton(operationStore: operationStore),
          ],
        ),
      ),
    );
  }
}

class _ConnectToServerButton extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onTap;

  const _ConnectToServerButton({required this.collapsed, required this.onTap});

  @override
  State<_ConnectToServerButton> createState() => _ConnectToServerButtonState();
}

class _ConnectToServerButtonState extends State<_ConnectToServerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? AppColors.fg : AppColors.fgMuted;

    if (!widget.collapsed) {
      return Tooltip(
        message: t.sidebar.connectToServer,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: _hovered ? AppColors.bgHover : Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Icon(
                    WaydirIconsRegular.treeStructure,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      t.sidebar.connectToServer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.txt.rowEmphasis.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: t.sidebar.connectToServer,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            alignment: Alignment.center,
            child: Icon(
              WaydirIconsRegular.treeStructure,
              size: 15,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarDropTarget extends StatefulWidget {
  final Widget child;
  final Future<void> Function(String path) onDropBookmark;

  const _SidebarDropTarget({required this.child, required this.onDropBookmark});

  @override
  State<_SidebarDropTarget> createState() => _SidebarDropTargetState();
}

class _SidebarDropTargetState extends State<_SidebarDropTarget> {
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: [Formats.fileUri, formatLocalFile],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) {
        if (!_dragOver) setState(() => _dragOver = true);
        return DropOperation.copy;
      },
      onDropLeave: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onDropEnded: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onPerformDrop: (event) async {
        final paths = await pathsFromSession(event.session);
        for (final path in paths) {
          if (Directory(path).existsSync()) {
            await widget.onDropBookmark(path);
          }
        }
        if (_dragOver) setState(() => _dragOver = false);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _dragOver
              ? AppColors.accent.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: widget.child,
      ),
    );
  }
}

class _BookmarksSection extends StatelessWidget {
  final List<Bookmark> bookmarks;
  final String currentPath;
  final bool collapsed;
  final ValueChanged<String> onNavigate;
  final void Function(String path)? onOpenInNewTab;
  final void Function(List<String> paths, String destination, {bool move})
  onDropFiles;
  final void Function(Bookmark bookmark, Offset position) onContextMenu;

  const _BookmarksSection({
    required this.bookmarks,
    required this.currentPath,
    required this.collapsed,
    required this.onNavigate,
    required this.onOpenInNewTab,
    required this.onDropFiles,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!collapsed)
          _SectionHeader(title: t.sidebar.bookmarks)
        else
          const _SectionRailDivider(),
        if (bookmarks.isEmpty)
          collapsed
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                  child: Text(
                    t.sidebar.dropBookmark,
                    overflow: TextOverflow.ellipsis,
                    style: context.txt.caption.copyWith(
                      color: AppColors.fgMuted,
                    ),
                  ),
                )
        else
          ...bookmarks.map((bookmark) {
            final uri = LocationUri.parse(bookmark.path);
            final icon = uri.isNetwork
                ? WaydirIconsRegular.treeStructure
                : WaydirIconsRegular.bookmarkSimple;
            final mounted = uri.isLocal
                ? Directory(bookmark.path).existsSync()
                : true;
            return _ItemRow(
              item: _SidebarItem(bookmark.label, icon, bookmark.path),
              isSelected: currentPath == bookmark.path,
              isMounted: mounted,
              collapsed: collapsed,
              onTap: onNavigate,
              onMiddleTap: onOpenInNewTab != null
                  ? () => onOpenInNewTab!(bookmark.path)
                  : null,
              onDropFiles: (paths, {bool move = false}) =>
                  onDropFiles(paths, bookmark.path, move: move),
              onContextMenu: (position) => onContextMenu(bookmark, position),
            );
          }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _NetworkSection extends StatelessWidget {
  final List<String> locations;
  final List<Drive> drives;
  final String currentPath;
  final bool collapsed;
  final ValueChanged<String> onNavigate;
  final void Function(String path)? onOpenInNewTab;
  final void Function(List<String> paths, String destination, {bool move})
  onDropFiles;
  final Future<void> Function(String path) onUnmount;
  final Future<void> Function(Drive drive) onUnmountDrive;

  const _NetworkSection({
    required this.locations,
    this.drives = const [],
    required this.currentPath,
    required this.collapsed,
    required this.onNavigate,
    required this.onOpenInNewTab,
    required this.onDropFiles,
    required this.onUnmount,
    required this.onUnmountDrive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!collapsed)
          _SectionHeader(title: t.sidebar.network)
        else
          const _SectionRailDivider(),
        ...drives.map((drive) {
          final path = drive.mountPoint ?? drive.id;
          return _ItemRow(
            item: _SidebarItem(
              drive.label,
              WaydirIconsRegular.treeStructure,
              path,
            ),
            isSelected: currentPath == path || currentPath.startsWith(path),
            isMounted: true,
            collapsed: collapsed,
            onTap: onNavigate,
            onMiddleTap: onOpenInNewTab != null
                ? () => onOpenInNewTab!(path)
                : null,
            onDropFiles: (paths, {bool move = false}) =>
                onDropFiles(paths, path, move: move),
            onUnmount: () => unawaited(onUnmountDrive(drive)),
          );
        }),
        ...locations.map((path) {
          final uri = LocationUri.parse(path);
          return _ItemRow(
            item: _SidebarItem(
              uri.displayLabel,
              WaydirIconsRegular.treeStructure,
              path,
            ),
            isSelected: currentPath == path || currentPath.startsWith('$path/'),
            isMounted: true,
            collapsed: collapsed,
            onTap: onNavigate,
            onMiddleTap: onOpenInNewTab != null
                ? () => onOpenInNewTab!(path)
                : null,
            onDropFiles: (paths, {bool move = false}) =>
                onDropFiles(paths, path, move: move),
            onUnmount: () => unawaited(onUnmount(path)),
          );
        }),
      ],
    );
  }
}

class _SidebarHeader extends StatefulWidget {
  final bool collapsed;
  final VoidCallback? onToggle;

  const _SidebarHeader({required this.collapsed, required this.onToggle});

  @override
  State<_SidebarHeader> createState() => _SidebarHeaderState();
}

class _SidebarHeaderState extends State<_SidebarHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final collapsed = widget.collapsed;
    final icon = Icon(
      collapsed
          ? WaydirIconsRegular.sidebarSimple
          : WaydirIconsRegular.caretLeft,
      size: 14,
      color: _hovered ? AppColors.fg : AppColors.fgMuted,
    );

    return Container(
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 6),
      alignment: collapsed ? Alignment.center : Alignment.centerRight,
      child: Tooltip(
        message: collapsed ? t.sidebar.expand : t.sidebar.collapse,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onToggle,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _hovered ? AppColors.bgHover : Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              child: SizedBox(
                width: 26,
                height: 26,
                child: Center(child: icon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionRailDivider extends StatelessWidget {
  const _SectionRailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(height: 1, color: AppColors.bgDivider),
    );
  }
}

class _SidebarOperationsButton extends StatefulWidget {
  final OperationStore operationStore;
  final bool collapsed;

  const _SidebarOperationsButton({
    required this.operationStore,
    this.collapsed = false,
  });

  @override
  State<_SidebarOperationsButton> createState() =>
      _SidebarOperationsButtonState();
}

class _SidebarOperationsButtonState extends State<_SidebarOperationsButton> {
  bool _hovered = false;

  void _openPanel() {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset(box.size.width + 6, 0));
    showOperationsPanel(
      context: context,
      position: offset,
      operationStore: widget.operationStore,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final tasks = widget.operationStore.tasks.value;
        final active = tasks.where(_isActiveTask).firstOrNull;
        if (active == null) return _buildIdle(context);

        final activeCount = widget.operationStore.activeCount.value;
        final progress = active.progress.clamp(0.0, 1.0).toDouble();
        final progressText = '${(progress * 100).round()}%';

        if (widget.collapsed) {
          return Tooltip(
            message: '${t.toolbar.operations} · $progressText',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: GestureDetector(
                onTap: _openPanel,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(
                      alpha: _hovered ? 0.22 : 0.14,
                    ),
                    borderRadius: BorderRadius.zero,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.42),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 23,
                        height: 23,
                        child: CircularProgressIndicator(
                          value: active.totalFiles > 0 ? progress : null,
                          strokeWidth: 2,
                          backgroundColor: AppColors.bgInput,
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                      Icon(
                        _operationIcon(active),
                        size: 12,
                        color: AppColors.fgAccent,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Tooltip(
          message: t.toolbar.operations,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: _openPanel,
              behavior: HitTestBehavior.opaque,
              child: Container(
                constraints: const BoxConstraints(minHeight: 38),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(
                    alpha: _hovered ? 0.18 : 0.11,
                  ),
                  borderRadius: BorderRadius.zero,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.42),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _operationIcon(active),
                          size: 14,
                          color: AppColors.fgAccent,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            TaskLabel.title(active),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.txt.rowEmphasis.copyWith(
                              color: AppColors.fg,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeCount > 1
                              ? '$progressText · $activeCount'
                              : progressText,
                          style: context.txt.caption.copyWith(
                            color: AppColors.fgAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: LinearProgressIndicator(
                        value: active.totalFiles > 0 ? progress : null,
                        minHeight: 3,
                        backgroundColor: AppColors.bgInput,
                        valueColor: AlwaysStoppedAnimation(AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIdle(BuildContext context) {
    final color = _hovered ? AppColors.fg : AppColors.fgMuted;

    if (widget.collapsed) {
      return Tooltip(
        message: t.toolbar.operations,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _openPanel,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _hovered ? AppColors.bgHover : Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              child: Center(
                child: Icon(
                  WaydirIconsRegular.clockClockwise,
                  size: 14,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: t.toolbar.operations,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _openPanel,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              children: [
                Icon(WaydirIconsRegular.clockClockwise, size: 14, color: color),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    t.toolbar.operations,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.txt.rowEmphasis.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _isActiveTask(FileTask task) {
    return task.status == TaskStatus.queued ||
        task.status == TaskStatus.preparing ||
        task.status == TaskStatus.waitingConflicts ||
        task.status == TaskStatus.running ||
        task.status == TaskStatus.cancelling;
  }

  static IconData _operationIcon(FileTask? task) {
    if (task == null) return WaydirIconsRegular.clockClockwise;
    if (task.status == TaskStatus.waitingConflicts) {
      return WaydirIconsRegular.warning;
    }
    return switch (task.type) {
      TaskType.copy => WaydirIconsRegular.copy,
      TaskType.move => WaydirIconsRegular.arrowRight,
      TaskType.delete => WaydirIconsRegular.trash,
      TaskType.trash => WaydirIconsRegular.trashSimple,
      TaskType.trashRestore => WaydirIconsRegular.arrowCounterClockwise,
      TaskType.trashDelete => WaydirIconsRegular.trash,
      TaskType.extract => WaydirIconsRegular.archive,
      TaskType.compress => WaydirIconsRegular.fileZip,
      TaskType.archiveEdit => WaydirIconsRegular.archive,
    };
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
      child: Text(title.toUpperCase(), style: context.txt.sectionLabel),
    );
  }
}

class _ItemRow extends StatefulWidget {
  final _SidebarItem item;
  final bool isSelected;
  final bool isMounted;
  final DriveSpace? space;
  final bool collapsed;
  final ValueChanged<String> onTap;
  final VoidCallback? onMiddleTap;
  final void Function(List<String> paths, {bool move}) onDropFiles;
  final VoidCallback? onUnmount;
  final void Function(Offset position)? onContextMenu;

  const _ItemRow({
    required this.item,
    required this.isSelected,
    this.isMounted = true,
    this.space,
    this.collapsed = false,
    required this.onTap,
    this.onMiddleTap,
    required this.onDropFiles,
    this.onUnmount,
    this.onContextMenu,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _hovered = false;
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (_dragOver) {
      bg = AppColors.accent.withValues(alpha: 0.12);
    } else if (widget.isSelected) {
      bg = AppColors.bgSelectedMuted;
    } else if (_hovered) {
      bg = AppColors.bgHover;
    } else {
      bg = Colors.transparent;
    }

    return DropRegion(
      formats: [Formats.fileUri, formatLocalFile],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) {
        if (!_dragOver) setState(() => _dragOver = true);
        return DragHintController.instance.mode.value == DragMode.move
            ? DropOperation.move
            : DropOperation.copy;
      },
      onDropLeave: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onDropEnded: (_) {
        if (_dragOver) setState(() => _dragOver = false);
      },
      onPerformDrop: (event) async {
        final paths = await pathsFromSession(event.session);
        final move = DragHintController.instance.mode.value == DragMode.move;
        if (paths.isNotEmpty) widget.onDropFiles(paths, move: move);
        if (_dragOver) setState(() => _dragOver = false);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => widget.onTap(widget.item.path),
          onTertiaryTapUp: (_) {
            if (widget.isMounted) {
              widget.onMiddleTap?.call();
            }
          },
          onSecondaryTapUp: widget.onContextMenu != null
              ? (details) => widget.onContextMenu!(details.globalPosition)
              : null,
          child: Builder(
            builder: (context) {
              final row = widget.collapsed
                  ? Container(
                      height: 32,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.zero,
                        border: _dragOver
                            ? Border.all(
                                color: AppColors.accent.withValues(alpha: 0.4),
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        widget.item.icon,
                        size: 16,
                        color: widget.isSelected
                            ? AppColors.fgAccent
                            : (widget.isMounted
                                  ? AppColors.fg.withValues(alpha: 0.85)
                                  : AppColors.fgMuted),
                      ),
                    )
                  : Container(
                      height: widget.space == null ? 28 : 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.zero,
                        border: _dragOver
                            ? Border.all(
                                color: AppColors.accent.withValues(alpha: 0.4),
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.item.icon,
                                size: 16,
                                color: widget.isSelected
                                    ? AppColors.fgAccent
                                    : AppColors.fgMuted,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.item.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.txt.body.copyWith(
                                    color: widget.isSelected
                                        ? AppColors.fg
                                        : (widget.isMounted
                                              ? AppColors.fg.withValues(
                                                  alpha: 0.85,
                                                )
                                              : AppColors.fgMuted),
                                    fontWeight: widget.isSelected
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (widget.onUnmount != null)
                                IconButton(
                                  icon: Icon(
                                    WaydirIconsRegular.eject,
                                    size: 14,
                                    color: AppColors.fgMuted,
                                  ),
                                  onPressed: widget.onUnmount,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 22,
                                  ),
                                  splashRadius: 12,
                                ),
                            ],
                          ),
                          if (widget.space != null) ...[
                            const SizedBox(height: 4),
                            _DriveSpaceBar(space: widget.space!),
                          ],
                        ],
                      ),
                    );
              final tooltipMessage = _tooltipMessage();
              if (tooltipMessage == null) return row;
              return Tooltip(
                message: tooltipMessage,
                waitDuration: const Duration(milliseconds: 400),
                child: row,
              );
            },
          ),
        ),
      ),
    );
  }

  String? _tooltipMessage() {
    final space = widget.space;
    if (space == null) return widget.collapsed ? widget.item.label : null;

    final usedPercent = (space.usedFraction * 100).toStringAsFixed(1);
    return [
      widget.item.label,
      '${t.sidebar.driveSpace.used}: ${formatBytes(space.usedBytes)} ($usedPercent%)',
      '${t.sidebar.driveSpace.free}: ${formatBytes(space.freeBytes)}',
      '${t.sidebar.driveSpace.total}: ${formatBytes(space.totalBytes)}',
    ].join('\n');
  }
}

class _DriveSpaceBar extends StatelessWidget {
  final DriveSpace space;

  const _DriveSpaceBar({required this.space});

  @override
  Widget build(BuildContext context) {
    final used = space.usedFraction;
    final color = used >= 0.9
        ? AppColors.danger
        : used >= 0.75
        ? AppColors.warning
        : AppColors.success;
    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: SizedBox(
        height: 2,
        child: LinearProgressIndicator(
          value: used,
          minHeight: 2,
          backgroundColor: AppColors.bgDivider,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
