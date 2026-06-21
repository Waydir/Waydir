import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/distro_icons.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../../core/database/app_database.dart';
import '../../core/logging/app_logger.dart';
import 'bookmark_store.dart';
import 'navigation_store.dart';
import 'sidebar_store.dart';
import '../drives/drive_store.dart';
import '../drives/drive_model.dart';
import '../containers/container_store.dart';
import '../containers/wsl_distribution.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/dialogs/password_dialog.dart';
import '../../ui/dialogs/rename_dialog.dart';
import '../../ui/dialogs/sftp_credentials_dialog.dart';
import '../../ui/overlays/context_menu.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';
import '../quick_look/quick_look.dart';
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
import '../tags/tag_edit_dialog.dart';
import '../tags/tag_path.dart';
import '../tags/tag_store.dart';

const double _sectionGap = 12;
const double _gutter = 8;
const double _expandedRightGutter = 4;
const double _rowPadH = 10;
const double _rowHeight = 30;
const double _rowHeightWithSpace = 40;
const double _railRowHeight = 34;
const double _iconSize = 16;
const double _iconGap = 10;

class _SidebarItem {
  final String label;
  final IconData icon;
  final String path;
  final String? key;
  final Color? iconColor;
  final Widget? leading;
  const _SidebarItem(
    this.label,
    this.icon,
    this.path, {
    this.key,
    this.iconColor,
    this.leading,
  });
}

/// One row's full rendering inputs, shared by normal and edit-mode rendering.
class _SidebarEntry {
  final String key;
  final _SidebarItem item;
  final bool isSelected;
  final bool isMounted;
  final DriveSpace? space;
  final String? tooltip;
  final ValueChanged<String> onTap;
  final VoidCallback? onMiddleTap;
  final void Function(List<String> paths, {bool move})? onDropFiles;
  final bool isTagTarget;
  final VoidCallback? onUnmount;
  final void Function(Offset position)? onContextMenu;

  const _SidebarEntry({
    required this.key,
    required this.item,
    required this.isSelected,
    this.isMounted = true,
    this.space,
    this.tooltip,
    required this.onTap,
    this.onMiddleTap,
    this.onDropFiles,
    this.isTagTarget = false,
    this.onUnmount,
    this.onContextMenu,
  });
}

class _SidebarSection {
  final String id;
  final String title;
  final List<_SidebarEntry> entries;

  const _SidebarSection({
    required this.id,
    required this.title,
    required this.entries,
  });
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
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _credentialsRequester = _requestSmbCredentials;
    _sftpCredentialsRequester = _requestSftpCredentials;
    final h = PlatformPaths.homePath;
    _favorites = [
      _SidebarItem(t.sidebar.home, WaydirIconsRegular.house, h, key: 'home'),
      _SidebarItem(
        t.sidebar.desktop,
        WaydirIconsRegular.desktop,
        PlatformPaths.desktopPath,
        key: 'desktop',
      ),
      _SidebarItem(
        t.sidebar.documents,
        WaydirIconsRegular.notebook,
        PlatformPaths.documentsPath,
        key: 'documents',
      ),
      _SidebarItem(
        t.sidebar.downloads,
        WaydirIconsRegular.downloadSimple,
        PlatformPaths.downloadsPath,
        key: 'downloads',
      ),
      _SidebarItem(
        t.sidebar.pictures,
        WaydirIconsRegular.image,
        PlatformPaths.picturesPath,
        key: 'pictures',
      ),
      _SidebarItem(
        t.sidebar.music,
        WaydirIconsRegular.musicNote,
        PlatformPaths.musicPath,
        key: 'music',
      ),
      _SidebarItem(
        t.sidebar.videos,
        WaydirIconsRegular.videoCamera,
        PlatformPaths.videosPath,
        key: 'videos',
      ),
      if (PlatformPaths.canOpenTrash)
        _SidebarItem(
          t.sidebar.trash,
          WaydirIconsRegular.trashSimple,
          kTrashPath,
          key: 'trash',
        ),
    ];
    final trashDir = PlatformPaths.trashPath;
    if (trashDir != null) {
      try {
        Directory(trashDir).createSync(recursive: true);
      } catch (e, st) {
        log.warn(
          'navigation',
          'failed to create trash directory',
          error: e,
          stack: st,
        );
      }
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
    _scrollController.dispose();
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
          case 'copy_path':
            _copyPath(bookmark.path);
          case 'rename':
            _renameBookmark(bookmark);
          case 'remove':
            _bookmarkStore.remove(bookmark);
        }
      },
    );
  }

  void _copyPath(String path) {
    unawaited(Clipboard.setData(ClipboardData(text: path)));
  }

  void _showProperties(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return;
    final name = PlatformPaths.fileName(path);
    final entry = FileEntry(
      name: name.isEmpty ? path : name,
      path: path,
      type: FileItemType.folder,
      size: 0,
      modified: dir.statSync().modified,
    );
    unawaited(
      showQuickLook(
        context: context,
        store: widget.store,
        explicitEntry: entry,
      ),
    );
  }

  void _showFolderMenu(String path, Offset position, {required bool isTrash}) {
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: WaydirIconsRegular.folderOpen,
        label: t.menu.open,
        action: 'open',
      ),
      if (!isTrash && widget.onOpenInNewTab != null)
        ContextMenuItem(
          icon: WaydirIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
      if (!isTrash) ...[
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: WaydirIconsRegular.copy,
          label: t.menu.copyPath,
          action: 'copy_path',
        ),
        ContextMenuItem(
          icon: WaydirIconsRegular.bookmarkSimple,
          label: t.menu.addBookmark,
          action: 'add_bookmark',
        ),
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: WaydirIconsRegular.info,
          label: t.menu.properties,
          action: 'properties',
        ),
      ],
    ];
    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: (action) {
        switch (action) {
          case 'open':
            widget.store.navigateTo(path);
          case 'open_in_new_tab':
            widget.onOpenInNewTab?.call(path);
          case 'copy_path':
            _copyPath(path);
          case 'add_bookmark':
            unawaited(_bookmarkStore.addPath(path));
          case 'properties':
            _showProperties(path);
        }
      },
    );
  }

  void _showDriveMenu(Drive drive, String path, Offset position) {
    final isMounted = drive.isMounted;
    final canUnmount = isMounted && drive.id != '/' && drive.isRemovable;
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: WaydirIconsRegular.folderOpen,
        label: t.menu.open,
        action: 'open',
      ),
      if (isMounted && widget.onOpenInNewTab != null)
        ContextMenuItem(
          icon: WaydirIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
      if (isMounted) ...[
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: WaydirIconsRegular.copy,
          label: t.menu.copyPath,
          action: 'copy_path',
        ),
        ContextMenuItem(
          icon: WaydirIconsRegular.bookmarkSimple,
          label: t.menu.addBookmark,
          action: 'add_bookmark',
        ),
      ],
      if (canUnmount)
        ContextMenuItem(
          icon: WaydirIconsRegular.eject,
          label: t.menu.eject,
          action: 'eject',
        ),
      if (isMounted) ...[
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: WaydirIconsRegular.info,
          label: t.menu.properties,
          action: 'properties',
        ),
      ],
    ];
    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: (action) {
        switch (action) {
          case 'open':
            unawaited(_onDriveTap(drive, path));
          case 'open_in_new_tab':
            widget.onOpenInNewTab?.call(path);
          case 'copy_path':
            _copyPath(path);
          case 'add_bookmark':
            unawaited(_bookmarkStore.addPath(path));
          case 'eject':
            unawaited(_unmountDrive(drive));
          case 'properties':
            _showProperties(path);
        }
      },
    );
  }

  void _showNetworkMenu(
    String path,
    Offset position, {
    required bool canDisconnect,
  }) {
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: WaydirIconsRegular.folderOpen,
        label: t.menu.open,
        action: 'open',
      ),
      if (widget.onOpenInNewTab != null)
        ContextMenuItem(
          icon: WaydirIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.copy,
        label: t.menu.copyPath,
        action: 'copy_path',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.bookmarkSimple,
        label: t.menu.addBookmark,
        action: 'add_bookmark',
      ),
      if (canDisconnect) ...[
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: WaydirIconsRegular.eject,
          label: t.menu.disconnect,
          action: 'disconnect',
          danger: true,
        ),
      ],
    ];
    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: (action) {
        switch (action) {
          case 'open':
            widget.store.navigateTo(path);
          case 'open_in_new_tab':
            widget.onOpenInNewTab?.call(path);
          case 'copy_path':
            _copyPath(path);
          case 'add_bookmark':
            unawaited(_bookmarkStore.addLocation(path));
          case 'disconnect':
            unawaited(_unmountLocation(path));
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
          SignalBuilder(
            builder: (context) => _SidebarHeader(
              collapsed: widget.collapsed,
              editing: !widget.collapsed && SidebarStore.instance.editing.value,
              onToggle: widget.onToggleCollapsed,
              onToggleEdit: widget.collapsed
                  ? null
                  : SidebarStore.instance.toggleEditing,
            ),
          ),
          Expanded(
            child: _SidebarDropTarget(
              onDropBookmark: _bookmarkStore.addPath,
              child: SignalBuilder(builder: _buildBody),
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

  Widget _buildBody(BuildContext context) {
    final store = SidebarStore.instance;
    final editing = !widget.collapsed && store.editing.value;
    final collapsed = widget.collapsed;

    final currentPath = widget.store.currentPath.value;
    final currentDrives = driveStore.drives.value;
    final distributions = containerStore.distributions.value;
    final bookmarks = _bookmarkStore.bookmarks.value;
    final tags = TagStore.instance.tags.value;

    // Read layout signals so the body re-renders on reorder/visibility edits.
    final sectionOrder = store.sectionOrder.value;
    store.hiddenSections.value;
    store.collapsedSections.value;
    store.itemOrder.value;
    store.hiddenItems.value;

    final networkDrives = currentDrives.where((d) => d.isNetwork).toList();
    final devices = currentDrives.where((d) => !d.isNetwork).toList();
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
    final networkLocations = LocationResolver.mountedLocations();

    final byId = <String, _SidebarSection>{
      sidebarSectionFavorites: _SidebarSection(
        id: sidebarSectionFavorites,
        title: t.sidebar.places,
        entries: _favoriteEntries(currentPath),
      ),
      sidebarSectionDevices: _SidebarSection(
        id: sidebarSectionDevices,
        title: t.sidebar.devices,
        entries: _deviceEntries(devices, currentPath),
      ),
      sidebarSectionContainers: _SidebarSection(
        id: sidebarSectionContainers,
        title: t.sidebar.containers,
        entries: _containerEntries(distributions, currentPath),
      ),
      sidebarSectionNetwork: _SidebarSection(
        id: sidebarSectionNetwork,
        title: t.sidebar.network,
        entries: _networkEntries(networkDrives, networkLocations, currentPath),
      ),
      sidebarSectionTags: _SidebarSection(
        id: sidebarSectionTags,
        title: t.sidebar.tags,
        entries: _tagEntries(tags, currentPath),
      ),
      sidebarSectionBookmarks: _SidebarSection(
        id: sidebarSectionBookmarks,
        title: t.sidebar.bookmarks,
        entries: _bookmarkEntries(bookmarks, currentPath),
      ),
    };
    final ordered = [
      for (final id in sectionOrder)
        if (byId.containsKey(id)) byId[id]!,
    ];

    return Padding(
      padding: const EdgeInsets.only(
        left: _gutter,
        right: _expandedRightGutter,
      ),
      child: Scrollbar(
        controller: _scrollController,
        child: editing
            ? _buildEditList(ordered)
            : _buildNormalList(ordered, collapsed),
      ),
    );
  }

  bool _sectionAlwaysShown(String id) =>
      id != sidebarSectionNetwork && id != sidebarSectionContainers;

  Widget _buildNormalList(List<_SidebarSection> sections, bool collapsed) {
    final store = SidebarStore.instance;
    final children = <Widget>[];
    var first = true;
    for (final section in sections) {
      if (store.isSectionHidden(section.id)) continue;
      final visible = section.entries
          .where((e) => !store.isItemHidden(section.id, e.key))
          .toList();
      if (!_sectionAlwaysShown(section.id) && visible.isEmpty) continue;

      final sectionCollapsed =
          !collapsed && store.isSectionCollapsed(section.id);
      if (collapsed) {
        if (first) {
          children.add(const SizedBox(height: 6));
        } else {
          children.add(const _SectionRailDivider());
        }
      } else {
        if (!first) children.add(const SizedBox(height: _sectionGap));
        children.add(
          _SectionHeader(
            title: section.title,
            collapsed: sectionCollapsed,
            onToggle: () =>
                store.setSectionCollapsed(section.id, !sectionCollapsed),
          ),
        );
      }
      first = false;

      if (sectionCollapsed) continue;

      for (final entry in visible) {
        children.add(_rowFor(entry, collapsed));
      }
      if (section.id == sidebarSectionBookmarks &&
          visible.isEmpty &&
          !collapsed) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(_rowPadH, 2, _rowPadH, 8),
            child: Text(
              t.sidebar.dropBookmark,
              overflow: TextOverflow.ellipsis,
              style: context.txt.caption.copyWith(color: AppColors.fgMuted),
            ),
          ),
        );
      }
      if (section.id == sidebarSectionTags && visible.isEmpty && !collapsed) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(_rowPadH, 2, _rowPadH, 8),
            child: Text(
              t.sidebar.noTags,
              overflow: TextOverflow.ellipsis,
              style: context.txt.caption.copyWith(color: AppColors.fgMuted),
            ),
          ),
        );
      }
    }

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: collapsed ? 6 : _sectionGap),
      children: children,
    );
  }

  Widget _rowFor(_SidebarEntry entry, bool collapsed) {
    return _ItemRow(
      item: entry.item,
      isSelected: entry.isSelected,
      isMounted: entry.isMounted,
      space: entry.space,
      collapsed: collapsed,
      tooltip: entry.tooltip,
      onTap: entry.onTap,
      onMiddleTap: entry.onMiddleTap,
      onDropFiles: entry.onDropFiles ?? (paths, {bool move = false}) {},
      isTagTarget: entry.isTagTarget,
      onUnmount: entry.onUnmount,
      onContextMenu: entry.onContextMenu,
    );
  }

  Widget _buildEditList(List<_SidebarSection> sections) {
    // Show every section while editing — including an empty Network — so its
    // position in the order can be set before any network locations exist.
    return ReorderableListView.builder(
      scrollController: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 6),
      buildDefaultDragHandles: false,
      itemCount: sections.length,
      onReorderItem: (oldIndex, newIndex) =>
          SidebarStore.instance.reorderSections(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final section = sections[index];

        return _EditSection(
          key: ValueKey('section:${section.id}'),
          section: section,
          sectionIndex: index,
          onReorderItem: (oldI, newI) => _reorderItems(section, oldI, newI),
        );
      },
    );
  }

  void _reorderItems(_SidebarSection section, int oldIndex, int newIndex) {
    if (section.id == sidebarSectionBookmarks) {
      _bookmarkStore.reorder(oldIndex, newIndex);

      return;
    }
    if (section.id == sidebarSectionTags) {
      final ids = section.entries
          .map((e) => e.key)
          .where((k) => k.startsWith('tag:'))
          .map((k) => int.parse(k.substring(4)))
          .toList();
      if (oldIndex < 0 || oldIndex >= ids.length) return;
      var to = newIndex;
      if (to < 0) to = 0;
      if (to > ids.length - 1) to = ids.length - 1;
      if (to == oldIndex) return;
      final moved = ids.removeAt(oldIndex);
      ids.insert(to, moved);
      TagStore.instance.reorder(ids);

      return;
    }
    SidebarStore.instance.reorderItems(
      section.id,
      oldIndex,
      newIndex,
      section.entries.map((e) => e.key).toList(),
    );
  }

  List<_SidebarEntry> _favoriteEntries(String currentPath) {
    final entries = _favorites.map((item) {
      final isRecycleBin = isTrashPath(item.path);

      return _SidebarEntry(
        key: item.key!,
        item: item,
        isSelected: isRecycleBin
            ? isTrashPath(currentPath)
            : currentPath == item.path,
        isMounted: !isRecycleBin,
        onTap: widget.store.navigateTo,
        onMiddleTap: widget.onOpenInNewTab != null && !isRecycleBin
            ? () => widget.onOpenInNewTab!(item.path)
            : null,
        onDropFiles: (paths, {bool move = false}) {
          if (isRecycleBin) {
            widget.operationStore.enqueueTrash(paths);

            return;
          }
          widget.store.dropFiles(paths, item.path, move: move);
        },
        onContextMenu: (position) =>
            _showFolderMenu(item.path, position, isTrash: isRecycleBin),
      );
    }).toList();

    return SidebarStore.instance.orderItems(
      sidebarSectionFavorites,
      entries,
      (e) => e.key,
    );
  }

  List<_SidebarEntry> _deviceEntries(List<Drive> devices, String currentPath) {
    final entries = devices.map((drive) {
      final path = drive.mountPoint ?? drive.id;
      final isMounted = drive.isMounted;
      final label = drive.id == '/' ? t.sidebar.root : drive.label;
      final canUnmount = isMounted && drive.id != '/' && drive.isRemovable;

      return _SidebarEntry(
        key: drive.id,
        item: _SidebarItem(
          label,
          drive.isRemovable
              ? WaydirIconsRegular.usb
              : WaydirIconsRegular.hardDrive,
          path,
        ),
        isSelected: currentPath == path,
        isMounted: isMounted,
        space: isMounted ? drive.space : null,
        onTap: (p) => _onDriveTap(drive, p),
        onMiddleTap: widget.onOpenInNewTab != null && isMounted
            ? () => widget.onOpenInNewTab!(path)
            : null,
        onDropFiles: (paths, {bool move = false}) {
          if (isMounted) widget.store.dropFiles(paths, path, move: move);
        },
        onUnmount: canUnmount ? () => _unmountDrive(drive) : null,
        onContextMenu: (position) => _showDriveMenu(drive, path, position),
      );
    }).toList();

    return SidebarStore.instance.orderItems(
      sidebarSectionDevices,
      entries,
      (e) => e.key,
    );
  }

  List<_SidebarEntry> _containerEntries(
    List<WslDistribution> distributions,
    String currentPath,
  ) {
    final entries = distributions.map((dist) {
      final path = dist.uncPath;

      return _SidebarEntry(
        key: 'wsl:${dist.name}',
        item: _SidebarItem(
          dist.name,
          distroIconFor(dist.name),
          path,
          iconColor: distroColorFor(dist.name),
        ),
        isSelected: currentPath == path || currentPath.startsWith(path),
        isMounted: dist.isRunning,
        tooltip: dist.isRunning
            ? '${dist.name}\n${t.sidebar.containerRunning}'
            : dist.name,
        onTap: widget.store.navigateTo,
        onMiddleTap: widget.onOpenInNewTab != null
            ? () => widget.onOpenInNewTab!(path)
            : null,
        onDropFiles: (paths, {bool move = false}) =>
            widget.store.dropFiles(paths, path, move: move),
      );
    }).toList();

    return SidebarStore.instance.orderItems(
      sidebarSectionContainers,
      entries,
      (e) => e.key,
    );
  }

  List<_SidebarEntry> _networkEntries(
    List<Drive> drives,
    List<String> locations,
    String currentPath,
  ) {
    final entries = <_SidebarEntry>[];
    for (final drive in drives) {
      final path = drive.mountPoint ?? drive.id;
      entries.add(
        _SidebarEntry(
          key: 'drive:${drive.id}',
          item: _SidebarItem(
            drive.label,
            WaydirIconsRegular.treeStructure,
            path,
          ),
          isSelected: currentPath == path || currentPath.startsWith(path),
          tooltip: drive.remoteTarget == null
              ? drive.label
              : '${drive.label}\n${drive.remoteTarget}',
          onTap: widget.store.navigateTo,
          onMiddleTap: widget.onOpenInNewTab != null
              ? () => widget.onOpenInNewTab!(path)
              : null,
          onDropFiles: (paths, {bool move = false}) =>
              widget.store.dropFiles(paths, path, move: move),
          onContextMenu: (position) =>
              _showNetworkMenu(path, position, canDisconnect: false),
        ),
      );
    }
    for (final path in locations) {
      final uri = LocationUri.parse(path);
      entries.add(
        _SidebarEntry(
          key: 'loc:$path',
          item: _SidebarItem(
            uri.displayLabel,
            WaydirIconsRegular.treeStructure,
            path,
          ),
          isSelected: currentPath == path || currentPath.startsWith('$path/'),
          tooltip: uri.displayLabel == path
              ? uri.displayLabel
              : '${uri.displayLabel}\n$path',
          onTap: widget.store.navigateTo,
          onMiddleTap: widget.onOpenInNewTab != null
              ? () => widget.onOpenInNewTab!(path)
              : null,
          onDropFiles: (paths, {bool move = false}) =>
              widget.store.dropFiles(paths, path, move: move),
          onUnmount: () => _unmountLocation(path),
          onContextMenu: (position) =>
              _showNetworkMenu(path, position, canDisconnect: true),
        ),
      );
    }

    return SidebarStore.instance.orderItems(
      sidebarSectionNetwork,
      entries,
      (e) => e.key,
    );
  }

  List<_SidebarEntry> _bookmarkEntries(
    List<Bookmark> bookmarks,
    String currentPath,
  ) {
    return bookmarks.map((bookmark) {
      final uri = LocationUri.parse(bookmark.path);
      final icon = uri.isNetwork
          ? WaydirIconsRegular.treeStructure
          : WaydirIconsRegular.bookmarkSimple;
      final isMounted = uri.isLocal
          ? Directory(bookmark.path).existsSync()
          : true;

      return _SidebarEntry(
        key: 'bookmark:${bookmark.id}',
        item: _SidebarItem(bookmark.label, icon, bookmark.path),
        isSelected: currentPath == bookmark.path,
        isMounted: isMounted,
        onTap: widget.store.navigateTo,
        onMiddleTap: widget.onOpenInNewTab != null
            ? () => widget.onOpenInNewTab!(bookmark.path)
            : null,
        onDropFiles: (paths, {bool move = false}) =>
            widget.store.dropFiles(paths, bookmark.path, move: move),
        onContextMenu: (position) => _showBookmarkMenu(bookmark, position),
      );
    }).toList();
  }

  List<_SidebarEntry> _tagEntries(List<TagDef> tags, String currentPath) {
    return tags.map((tag) {
      final path = tagPathFor(tag.id);

      return _SidebarEntry(
        key: 'tag:${tag.id}',
        item: _SidebarItem(
          tag.name,
          WaydirIconsRegular.bookmarkSimple,
          path,
          leading: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: tag.color, shape: BoxShape.circle),
          ),
        ),
        isSelected: currentPath == path,
        onTap: widget.store.navigateTo,
        onMiddleTap: widget.onOpenInNewTab != null
            ? () => widget.onOpenInNewTab!(path)
            : null,
        onDropFiles: (paths, {bool move = false}) =>
            widget.store.addTag(paths, tag.id),
        isTagTarget: true,
        onContextMenu: (position) => _showTagMenu(tag, position),
      );
    }).toList();
  }

  void _showTagMenu(TagDef tag, Offset position) {
    final path = tagPathFor(tag.id);
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
          label: t.tags.editTag,
          action: 'edit',
        ),
        ContextMenuItem(
          icon: WaydirIconsRegular.trash,
          label: t.tags.deleteTag,
          action: 'delete',
          danger: true,
        ),
      ],
      onSelect: (action) async {
        switch (action) {
          case 'open':
            widget.store.navigateTo(path);
          case 'open_in_new_tab':
            widget.onOpenInNewTab?.call(path);
          case 'edit':
            await showTagEditDialog(context, existing: tag);
          case 'delete':
            await TagStore.instance.deleteTag(tag.id);
            if (widget.store.currentPath.value == path) {
              widget.store.navigateTo(PlatformPaths.homePath);
            }
        }
      },
    );
  }

  Future<void> _onDriveTap(Drive drive, String path) async {
    if (drive.isMounted) {
      widget.store.navigateTo(path);

      return;
    }
    try {
      await driveStore.mount(drive);
      _navigateToMounted(drive.id);
    } catch (e) {
      final error = e.toString().toLowerCase();
      if (!error.contains('not authorized') &&
          !error.contains('polkit') &&
          !error.contains('authenticate')) {
        return;
      }
      if (!mounted) return;
      final pwd = await showPasswordDialog(
        context,
        title: t.sidebar.drives.mountTitle(name: drive.label),
      );
      if (pwd == null) return;
      try {
        await driveStore.mountWithPassword(drive, pwd);
        _navigateToMounted(drive.id);
      } catch (e, st) {
        log.warn(
          'drives',
          'drive mount with password failed',
          error: e,
          stack: st,
        );
      }
    }
  }

  void _navigateToMounted(String driveId) {
    Future.microtask(() {
      final mounted = driveStore.drives.value
          .where((d) => d.id == driveId)
          .firstOrNull;
      if (mounted?.isMounted == true) {
        widget.store.navigateTo(mounted!.mountPoint!);
      }
    });
  }

  Future<void> _unmountDrive(Drive drive) async {
    final currentPath = widget.store.currentPath.value;
    final mountPoint = drive.mountPoint;
    try {
      await driveStore.unmount(drive);
      if (mountPoint != null && currentPath.startsWith(mountPoint)) {
        widget.store.navigateTo(PlatformPaths.homePath);
      }
    } catch (e, st) {
      log.warn('drives', 'drive unmount action failed', error: e, stack: st);
    }
  }

  Future<void> _unmountLocation(String path) async {
    final currentPath = widget.store.currentPath.value;
    await LocationResolver.unmount(path);
    if (mounted) setState(() {});
    if (currentPath == path || currentPath.startsWith('$path/')) {
      widget.store.navigateTo(PlatformPaths.homePath);
    }
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
        padding: const EdgeInsets.fromLTRB(_gutter, 6, _expandedRightGutter, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ConnectToServerButton(collapsed: false, onTap: onConnect),
            const SizedBox(height: 2),
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
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: _rowPadH),
              decoration: BoxDecoration(
                color: _hovered ? AppColors.bgHover : Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Icon(
                    WaydirIconsRegular.treeStructure,
                    size: _iconSize,
                    color: color,
                  ),
                  const SizedBox(width: _iconGap),
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

class _EditSection extends StatelessWidget {
  final _SidebarSection section;
  final int sectionIndex;
  final void Function(int oldIndex, int newIndex) onReorderItem;

  const _EditSection({
    super.key,
    required this.section,
    required this.sectionIndex,
    required this.onReorderItem,
  });

  @override
  Widget build(BuildContext context) {
    final store = SidebarStore.instance;
    final sectionHidden = store.isSectionHidden(section.id);
    final allowItemHide = section.id != sidebarSectionBookmarks;
    final entries = section.entries;

    return Padding(
      padding: const EdgeInsets.only(bottom: _sectionGap),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: sectionIndex,
                  child: const _DragHandle(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    section.title.toUpperCase(),
                    style: context.txt.sectionLabel.copyWith(
                      color: sectionHidden ? AppColors.fgSubtle : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _VisibilityToggle(
                  hidden: sectionHidden,
                  onTap: () =>
                      store.setSectionHidden(section.id, !sectionHidden),
                ),
              ],
            ),
          ),
          if (entries.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: entries.length,
              onReorderItem: onReorderItem,
              itemBuilder: (context, index) {
                final entry = entries[index];

                return _EditRow(
                  key: ValueKey('item:${section.id}:${entry.key}'),
                  entry: entry,
                  index: index,
                  scope: section.id,
                  allowHide: allowItemHide,
                  dimmed: sectionHidden,
                  orderedKeys: entries.map((e) => e.key).toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final _SidebarEntry entry;
  final int index;
  final String scope;
  final bool allowHide;
  final bool dimmed;
  final List<String> orderedKeys;

  const _EditRow({
    super.key,
    required this.entry,
    required this.index,
    required this.scope,
    required this.allowHide,
    required this.dimmed,
    required this.orderedKeys,
  });

  @override
  Widget build(BuildContext context) {
    final store = SidebarStore.instance;
    final itemHidden = allowHide && store.isItemHidden(scope, entry.key);
    final faded = dimmed || itemHidden;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Opacity(
        opacity: faded ? 0.45 : 1,
        child: Container(
          height: _rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.bgHover.withValues(alpha: 0.4),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const _DragHandle(),
              ),
              const SizedBox(width: 8),
              Icon(entry.item.icon, size: 15, color: AppColors.fgMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.item.label,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.body,
                ),
              ),
              if (allowHide)
                _VisibilityToggle(
                  hidden: itemHidden,
                  onTap: () => store.setItemHidden(
                    scope,
                    entry.key,
                    !itemHidden,
                    orderedKeys,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Icon(WaydirIconsRegular.list, size: 14, color: AppColors.fgSubtle),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool hidden;
  final VoidCallback onTap;

  const _VisibilityToggle({required this.hidden, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hidden ? t.sidebar.show : t.sidebar.hide,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              hidden ? WaydirIconsRegular.prohibit : WaydirIconsRegular.eye,
              size: 14,
              color: hidden ? AppColors.fgSubtle : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool collapsed;
  final bool editing;
  final VoidCallback? onToggle;
  final VoidCallback? onToggleEdit;

  const _SidebarHeader({
    required this.collapsed,
    required this.editing,
    required this.onToggle,
    required this.onToggleEdit,
  });

  @override
  Widget build(BuildContext context) {
    final toggle = _HeaderButton(
      icon: collapsed
          ? WaydirIconsRegular.sidebarSimple
          : WaydirIconsRegular.caretLeft,
      tooltip: collapsed ? t.sidebar.expand : t.sidebar.collapse,
      onTap: onToggle,
    );

    return Container(
      height: 32,
      padding: EdgeInsets.only(
        left: collapsed ? 0 : 6,
        right: collapsed ? 0 : 10,
      ),
      child: collapsed
          ? Center(child: toggle)
          : Row(
              children: [
                if (onToggleEdit != null)
                  _HeaderButton(
                    icon: editing
                        ? WaydirIconsRegular.check
                        : WaydirIconsRegular.slidersHorizontal,
                    tooltip: editing
                        ? t.sidebar.editDone
                        : t.sidebar.editLayout,
                    active: editing,
                    onTap: onToggleEdit,
                  ),
                const Spacer(),
                toggle,
              ],
            ),
    );
  }
}

class _HeaderButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback? onTap;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    this.active = false,
    required this.onTap,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.active
        ? AppColors.fgAccent
        : (_hovered ? AppColors.fg : AppColors.fgMuted);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.active
                  ? AppColors.bgSelectedMuted
                  : (_hovered ? AppColors.bgHover : Colors.transparent),
              borderRadius: BorderRadius.zero,
            ),
            child: SizedBox(
              width: 26,
              height: 26,
              child: Center(child: Icon(widget.icon, size: 14, color: color)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: _rowPadH,
                  vertical: 7,
                ),
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
                          size: _iconSize,
                          color: AppColors.fgAccent,
                        ),
                        const SizedBox(width: _iconGap),
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
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: _rowPadH),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              children: [
                Icon(
                  WaydirIconsRegular.clockClockwise,
                  size: _iconSize,
                  color: color,
                ),
                const SizedBox(width: _iconGap),
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
      TaskType.plugin => WaydirIconsRegular.gearSix,
    };
  }
}

class _SectionHeader extends StatefulWidget {
  final String title;
  final bool collapsed;
  final VoidCallback onToggle;

  const _SectionHeader({
    required this.title,
    required this.collapsed,
    required this.onToggle,
  });

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? AppColors.fg : AppColors.fgMuted;

    return Tooltip(
      message: widget.collapsed
          ? t.sidebar.expandSection
          : t.sidebar.collapseSection,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(2, 14, _rowPadH, 6),
            child: Row(
              children: [
                Icon(
                  widget.collapsed
                      ? WaydirIconsRegular.caretRight
                      : WaydirIconsRegular.caretDown,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.title.toUpperCase(),
                    style: context.txt.sectionLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
  final bool isTagTarget;
  final VoidCallback? onUnmount;
  final void Function(Offset position)? onContextMenu;
  final String? tooltip;

  const _ItemRow({
    required this.item,
    required this.isSelected,
    this.isMounted = true,
    this.space,
    this.collapsed = false,
    required this.onTap,
    this.onMiddleTap,
    required this.onDropFiles,
    this.isTagTarget = false,
    this.onUnmount,
    this.onContextMenu,
    this.tooltip,
  });

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _hovered = false;
  bool _dragOver = false;

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: [Formats.fileUri, formatLocalFile],
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) {
        if (!_dragOver) setState(() => _dragOver = true);
        if (widget.isTagTarget) return DropOperation.link;

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
              final row = widget.collapsed ? _railRow() : _expandedRow(context);
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

  Color get _bg {
    if (_dragOver) return AppColors.accent.withValues(alpha: 0.12);
    if (widget.isSelected) return AppColors.bgSelectedMuted;
    if (_hovered) return AppColors.bgHover;

    return Colors.transparent;
  }

  Color get _iconColor {
    final brand = widget.item.iconColor;
    if (brand != null) {
      return widget.isMounted ? brand : brand.withValues(alpha: 0.55);
    }
    if (widget.isSelected) return AppColors.fgAccent;

    return widget.isMounted
        ? AppColors.fg.withValues(alpha: 0.85)
        : AppColors.fgMuted;
  }

  Border? get _dragBorder => _dragOver
      ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
      : null;

  Widget _railRow() {
    return Container(
      height: _railRowHeight,
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(color: _bg, border: _dragBorder),
      child: Stack(
        children: [
          if (widget.isSelected)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _SelectionAccent(),
            ),
          Center(
            child:
                widget.item.leading ??
                Icon(widget.item.icon, size: _iconSize, color: _iconColor),
          ),
        ],
      ),
    );
  }

  Widget _expandedRow(BuildContext context) {
    final content = Row(
      children: [
        widget.item.leading ??
            Icon(widget.item.icon, size: _iconSize, color: _iconColor),
        const SizedBox(width: _iconGap),
        Expanded(
          child: Text(
            widget.item.label,
            overflow: TextOverflow.ellipsis,
            style: context.txt.body.copyWith(
              color: widget.isSelected
                  ? AppColors.fg
                  : (widget.isMounted
                        ? AppColors.fg.withValues(alpha: 0.85)
                        : AppColors.fgMuted),
              fontWeight: widget.isSelected
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
        ),
        if (widget.onUnmount != null)
          _RowIconButton(
            icon: WaydirIconsRegular.eject,
            tooltip: t.menu.eject,
            onTap: widget.onUnmount!,
          ),
      ],
    );

    final body = widget.space == null
        ? content
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              content,
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.only(left: _iconSize + _iconGap),
                child: _DriveSpaceBar(space: widget.space!),
              ),
            ],
          );

    return Container(
      height: widget.space == null ? _rowHeight : _rowHeightWithSpace,
      decoration: BoxDecoration(color: _bg, border: _dragBorder),
      child: Stack(
        children: [
          if (widget.isSelected)
            const Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _SelectionAccent(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _rowPadH),
            child: Center(child: body),
          ),
        ],
      ),
    );
  }

  String? _tooltipMessage() {
    final space = widget.space;
    if (space == null) {
      if (widget.collapsed) return widget.item.label;

      return widget.tooltip;
    }

    final usedPercent = (space.usedFraction * 100).toStringAsFixed(1);

    return [
      widget.item.label,
      '${t.sidebar.driveSpace.used}: ${formatBytes(space.usedBytes)} ($usedPercent%)',
      '${t.sidebar.driveSpace.free}: ${formatBytes(space.freeBytes)}',
      '${t.sidebar.driveSpace.total}: ${formatBytes(space.totalBytes)}',
    ].join('\n');
  }
}

class _SelectionAccent extends StatelessWidget {
  const _SelectionAccent();

  @override
  Widget build(BuildContext context) {
    return Container(width: 2, color: AppColors.accent);
  }
}

class _RowIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RowIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_RowIconButton> createState() => _RowIconButtonState();
}

class _RowIconButtonState extends State<_RowIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHoverStrong : Colors.transparent,
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
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
