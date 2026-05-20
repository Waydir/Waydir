import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;
import 'package:waydir/ui/icons/waydir_icons.dart'
    show WaydirIconsFill, WaydirIconsRegular;
import 'package:signals/signals_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../../i18n/strings.g.dart';
import '../../core/fs/file_sort.dart';
import '../../core/models/file_entry.dart';
import '../../core/settings/settings_store.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../utils/drag_drop.dart';
import 'package:path/path.dart' as p;
import '../../utils/format.dart';
import '../operations/drag_hint.dart';
import 'file_icons.dart';
import 'rubber_band_layer.dart';

typedef FileSelectCallback = void Function(FileSelectionEvent event);
typedef FileOpenCallback = void Function(FileEntry entry);
typedef BackgroundTapCallback = void Function();
typedef BackgroundContextMenuCallback = void Function(Offset position);
typedef FileContextMenuCallback =
    void Function(FileSelectionEvent event, Offset position);
typedef FileMenuActionCallback = void Function(String action);
typedef FileDropCallback =
    void Function(List<String> paths, String destination, {bool move});
typedef RenameSubmitCallback = void Function(String newName);
typedef RenameCancelCallback = void Function();
typedef OpenInNewTabCallback = void Function(String path);

const _kDoubleTapMs = 300;
const _kRowHeightComfortable = 26.0;
const _kRowHeightCompact = 20.0;
const _kRowGapComfortable = 6.0;
const _kRowGapCompact = 2.0;

class FileList extends StatefulWidget {
  final List<FileEntry> files;
  final String currentPath;
  final FileSelectCallback onSelect;
  final FileOpenCallback onOpen;
  final BackgroundTapCallback? onBackgroundTap;
  final BackgroundContextMenuCallback? onBackgroundContextMenu;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final FileDropCallback? onDropFiles;
  final Set<String> selectedPaths;
  final int cursorIndex;
  final Set<String> cutPaths;
  final String? renamingPath;
  final int renameAttempt;
  final RenameSubmitCallback? onRenameSubmit;
  final RenameCancelCallback? onRenameCancel;
  final bool recursiveResults;
  final VoidCallback? onCloseSearch;
  final OpenInNewTabCallback? onOpenInNewTab;
  final RubberBandSelectCallback? onRectSelect;
  final SortKey sortColumn;
  final bool sortAscending;
  final void Function(SortKey key)? onSortColumn;

  const FileList({
    super.key,
    required this.files,
    required this.currentPath,
    required this.onSelect,
    required this.onOpen,
    this.sortColumn = SortKey.name,
    this.sortAscending = true,
    this.onSortColumn,
    this.onBackgroundTap,
    this.onBackgroundContextMenu,
    this.onContextMenu,
    this.onMenuAction,
    this.onDropFiles,
    this.selectedPaths = const {},
    this.cursorIndex = -1,
    this.cutPaths = const {},
    this.renamingPath,
    this.renameAttempt = 0,
    this.onRenameSubmit,
    this.onRenameCancel,
    this.recursiveResults = false,
    this.onCloseSearch,
    this.onOpenInNewTab,
    this.onRectSelect,
  });

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  final _scrollController = ScrollController();
  bool _isDragOver = false;
  String? _hoveredFolderPath;
  double _rowH = _kRowHeightComfortable;
  double _rowG = _kRowGapComfortable;
  double _itemExt = _kRowHeightComfortable + _kRowGapComfortable;
  String _dateFmt = 'locale';
  bool _recentDatesRelative = true;
  String? _lastRevealedKey;

  double _measureWidth(String text, TextStyle style) {
    if (text.isEmpty) return 0;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return tp.width;
  }

  ({double size, double date}) _computeColumnWidths(BuildContext context) {
    final muted = context.txt.muted;

    String longestSize = '';
    for (final e in widget.files) {
      if (e.type == FileItemType.folder) continue;
      final s = formatBytes(e.size);
      if (s.length > longestSize.length) longestSize = s;
    }
    if (longestSize.isEmpty) longestSize = '--';

    String longestDate = '';
    for (final e in widget.files) {
      final d = _formatDateBy(
        e.modified,
        _dateFmt,
        recentDatesRelative: _recentDatesRelative,
      );
      if (d.length > longestDate.length) longestDate = d;
    }

    final sizeW = _measureWidth(longestSize, muted);
    final dateW = _measureWidth(longestDate, muted);

    return (size: sizeW.ceilToDouble() + 8, date: dateW.ceilToDouble() + 8);
  }

  String? _relativeParent(String entryPath, String currentPath) {
    final rel = p.relative(p.dirname(entryPath), from: currentPath);
    if (rel == '.') return null;
    return rel;
  }

  int _rowAt(Offset localPosition) {
    if (localPosition.dy < 0) return -1;
    final adjustedY = localPosition.dy + _scrollController.offset;
    final index = (adjustedY / _itemExt).floor();
    if (index < 0 || index >= widget.files.length) return -1;

    final relativeY = adjustedY % _itemExt;
    if (relativeY >= _rowH) return -1;

    return index;
  }

  void _updateHover(Offset localPosition) {
    final index = _rowAt(localPosition);
    String? folder;
    if (index >= 0) {
      final entry = widget.files[index];
      if (entry.type == FileItemType.folder) folder = entry.path;
    }
    if (folder != _hoveredFolderPath || !_isDragOver) {
      setState(() {
        _isDragOver = true;
        _hoveredFolderPath = folder;
      });
    }
  }

  void _clearDrag() {
    if (_isDragOver || _hoveredFolderPath != null) {
      setState(() {
        _isDragOver = false;
        _hoveredFolderPath = null;
      });
    }
  }

  void _revealSelectedRow() {
    final index = widget.cursorIndex;
    if (index < 0 || index >= widget.files.length) return;
    final key = '$index:${widget.files[index].path}';
    if (key == _lastRevealedKey) return;
    _lastRevealedKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final viewport = _scrollController.position.viewportDimension;
      final top = index * _itemExt;
      final bottom = top + _rowH;
      final current = _scrollController.offset;
      final target = top < current
          ? top
          : bottom > current + viewport
          ? bottom - viewport
          : current;
      if (target == current) return;
      _scrollController.animateTo(
        target.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final density = SettingsStore.instance.rowDensity.watch(context);
    _dateFmt = SettingsStore.instance.dateFormat.watch(context);
    _recentDatesRelative = SettingsStore.instance.recentDatesRelative.watch(
      context,
    );
    _rowH = density == 'compact' ? _kRowHeightCompact : _kRowHeightComfortable;
    _rowG = density == 'compact' ? _kRowGapCompact : _kRowGapComfortable;
    _itemExt = _rowH + _rowG;
    _revealSelectedRow();

    if (widget.files.isEmpty) {
      return GestureDetector(
        onTap: widget.onBackgroundTap,
        onSecondaryTapUp: widget.onBackgroundContextMenu != null
            ? (d) => widget.onBackgroundContextMenu!(d.globalPosition)
            : null,
        behavior: HitTestBehavior.opaque,
        child: _EmptyState(
          isSearching: widget.recursiveResults,
          onCloseSearch: widget.onCloseSearch,
        ),
      );
    }

    final columnWidths = widget.recursiveResults
        ? (size: 0.0, date: 0.0)
        : _computeColumnWidths(context);

    return Column(
      children: [
        _ListHeader(
          recursive: widget.recursiveResults,
          sizeWidth: columnWidths.size,
          dateWidth: columnWidths.date,
          sortColumn: widget.sortColumn,
          sortAscending: widget.sortAscending,
          onSortColumn: widget.onSortColumn,
        ),
        Divider(height: 1, thickness: 1, color: AppColors.bgDivider),
        Expanded(
          child: RubberBandLayer(
            scrollController: _scrollController,
            itemCount: widget.files.length,
            itemExtent: _itemExt,
            rowHeight: _rowH,
            pathAt: (i) => widget.files[i].path,
            rowAt: _rowAt,
            onSelectionChanged: widget.onRectSelect,
            onBackgroundTap: widget.onBackgroundTap,
            child: DropRegion(
              formats: [Formats.fileUri, formatLocalFile],
              hitTestBehavior: HitTestBehavior.opaque,
              onDropOver: (event) {
                _updateHover(event.position.local);
                return DragHintController.instance.mode.value == DragMode.move
                    ? DropOperation.move
                    : DropOperation.copy;
              },
              onDropLeave: (_) => _clearDrag(),
              onDropEnded: (_) {
                _clearDrag();
              },
              onPerformDrop: (event) async {
                final pos = event.position.local;
                final index = _rowAt(pos);
                String? target;
                if (index >= 0 &&
                    widget.files[index].type == FileItemType.folder) {
                  target = widget.files[index].path;
                }
                final paths = await pathsFromSession(event.session);
                final move =
                    DragHintController.instance.mode.value == DragMode.move;
                if (paths.isNotEmpty) {
                  widget.onDropFiles?.call(
                    paths,
                    target ?? widget.currentPath,
                    move: move,
                  );
                }
                _clearDrag();
              },
              child: Stack(
                children: [
                  GestureDetector(
                    onSecondaryTapUp: (d) {
                      final index = _rowAt(d.localPosition);
                      if (index < 0) {
                        widget.onBackgroundTap?.call();
                        widget.onBackgroundContextMenu?.call(d.globalPosition);
                      }
                    },
                    behavior: HitTestBehavior.translucent,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: widget.files.length,
                      itemExtent: _itemExt,
                      // We supply our own RepaintBoundary per row; the keep
                      // alive / semantics / repaint wrappers ListView adds by
                      // default are pure overhead at 10k+ rows.
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                      addSemanticIndexes: false,
                      itemBuilder: (context, i) => RepaintBoundary(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: _rowG),
                          child: _ListRow(
                            rowHeight: _rowH,
                            dateFmt: _dateFmt,
                            recentDatesRelative: _recentDatesRelative,
                            entry: widget.files[i],
                            index: i,
                            selected: widget.selectedPaths.contains(
                              widget.files[i].path,
                            ),
                            selectedPaths: widget.selectedPaths,
                            isCut: widget.cutPaths.contains(
                              widget.files[i].path,
                            ),
                            isDraggingSelected: widget.selectedPaths.isNotEmpty,
                            isFolderDragOver:
                                _hoveredFolderPath == widget.files[i].path,
                            isRenaming:
                                widget.renamingPath == widget.files[i].path,
                            renameAttempt: widget.renameAttempt,
                            onRenameSubmit: widget.onRenameSubmit,
                            onRenameCancel: widget.onRenameCancel,
                            onSelect: widget.onSelect,
                            onOpen: widget.onOpen,
                            onContextMenu: widget.onContextMenu,
                            onMenuAction: widget.onMenuAction,
                            recursive: widget.recursiveResults,
                            sizeWidth: columnWidths.size,
                            dateWidth: columnWidths.date,
                            location: widget.recursiveResults
                                ? _relativeParent(
                                    widget.files[i].path,
                                    widget.currentPath,
                                  )
                                : null,
                            onOpenInNewTab: widget.onOpenInNewTab,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isDragOver)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  final bool recursive;
  final double sizeWidth;
  final double dateWidth;
  final SortKey sortColumn;
  final bool sortAscending;
  final void Function(SortKey key)? onSortColumn;
  const _ListHeader({
    this.recursive = false,
    this.sizeWidth = 0,
    this.dateWidth = 0,
    this.sortColumn = SortKey.name,
    this.sortAscending = true,
    this.onSortColumn,
  });

  Widget _sortable(
    BuildContext context,
    String label,
    SortKey key,
    TextStyle style,
  ) {
    final active = sortColumn == key;
    final ascending = sortAscending;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSortColumn == null ? null : () => onSortColumn!(key),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: active ? style.copyWith(color: AppColors.fg) : style,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 3),
              Icon(
                ascending
                    ? WaydirIconsRegular.caretUp
                    : WaydirIconsRegular.caretDown,
                size: 10,
                color: AppColors.fgAccent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = context.txt.fieldLabel;
    return Container(
      height: 24,
      padding: const EdgeInsets.only(left: 12, right: 16),
      decoration: BoxDecoration(color: AppColors.bg),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Expanded(
            flex: 3,
            child: _sortable(
              context,
              t.fileView.columns.name,
              SortKey.name,
              headerStyle,
            ),
          ),
          if (recursive) ...[
            Expanded(
              flex: 4,
              child: Text(t.fileView.columns.location, style: headerStyle),
            ),
          ] else ...[
            SizedBox(
              width: sizeWidth,
              child: _sortable(
                context,
                t.fileView.columns.size,
                SortKey.size,
                headerStyle,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: dateWidth,
              child: _sortable(
                context,
                t.fileView.columns.dateModified,
                SortKey.date,
                headerStyle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ListRow extends StatefulWidget {
  final FileEntry entry;
  final int index;
  final bool selected;
  final Set<String> selectedPaths;
  final bool isCut;
  final bool isDraggingSelected;
  final bool isFolderDragOver;
  final bool isRenaming;
  final int renameAttempt;
  final RenameSubmitCallback? onRenameSubmit;
  final RenameCancelCallback? onRenameCancel;
  final FileSelectCallback onSelect;
  final FileOpenCallback onOpen;
  final FileContextMenuCallback? onContextMenu;
  final FileMenuActionCallback? onMenuAction;
  final bool recursive;
  final double sizeWidth;
  final double dateWidth;
  final double rowHeight;
  final String dateFmt;
  final bool recentDatesRelative;
  final String? location;
  final OpenInNewTabCallback? onOpenInNewTab;

  const _ListRow({
    required this.entry,
    required this.index,
    required this.selected,
    required this.selectedPaths,
    this.isCut = false,
    this.isDraggingSelected = false,
    this.isFolderDragOver = false,
    this.isRenaming = false,
    this.renameAttempt = 0,
    this.onRenameSubmit,
    this.onRenameCancel,
    required this.onSelect,
    required this.onOpen,
    this.onContextMenu,
    this.onMenuAction,
    this.recursive = false,
    this.sizeWidth = 0,
    this.dateWidth = 0,
    this.rowHeight = _kRowHeightComfortable,
    this.dateFmt = 'locale',
    this.recentDatesRelative = true,
    this.location,
    this.onOpenInNewTab,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _hovered = false;
  bool _dragging = false;
  DateTime? _lastTap;
  TextEditingController? _renameController;
  FocusNode? _renameFocusNode;
  bool _renameCommitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.isRenaming) _initRenameFields();
  }

  @override
  void didUpdateWidget(covariant _ListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRenaming && !oldWidget.isRenaming) {
      _initRenameFields();
    } else if (!widget.isRenaming && oldWidget.isRenaming) {
      _disposeRenameFields();
    } else if (widget.isRenaming &&
        widget.renameAttempt != oldWidget.renameAttempt) {
      _renameCommitted = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _renameFocusNode == null || _renameController == null) {
          return;
        }
        _renameFocusNode!.requestFocus();
        _renameController!.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _renameController!.text.length,
        );
      });
    }
  }

  void _initRenameFields() {
    _renameCommitted = false;
    final name = widget.entry.name;
    String initialText;
    int selectionEnd;
    if (widget.entry.type == FileItemType.file) {
      final dotIndex = name.lastIndexOf('.');
      if (dotIndex > 0) {
        initialText = name;
        selectionEnd = dotIndex;
      } else {
        initialText = name;
        selectionEnd = name.length;
      }
    } else {
      initialText = name;
      selectionEnd = name.length;
    }
    _renameController = TextEditingController(text: initialText);
    _renameController!.selection = TextSelection(
      baseOffset: 0,
      extentOffset: selectionEnd,
    );
    _renameFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _renameFocusNode != null) {
        _renameFocusNode!.requestFocus();
      }
    });
  }

  void _disposeRenameFields() {
    _renameController?.dispose();
    _renameController = null;
    _renameFocusNode?.dispose();
    _renameFocusNode = null;
  }

  @override
  void dispose() {
    _disposeRenameFields();
    super.dispose();
  }

  void _commitRename() {
    if (_renameCommitted) return;
    _renameCommitted = true;
    final newName = _renameController?.text ?? '';
    widget.onRenameSubmit?.call(newName);
  }

  void _cancelRename() {
    if (_renameCommitted) return;
    _renameCommitted = true;
    widget.onRenameCancel?.call();
  }

  Color get _bg {
    if (widget.isFolderDragOver) {
      return AppColors.accent.withValues(alpha: 0.12);
    }
    if (_dragging) return AppColors.accent.withValues(alpha: 0.08);
    if (widget.selected) return AppColors.bgSelectedMuted;
    if (_hovered) return AppColors.bgHover;
    return Colors.transparent;
  }

  BoxBorder? get _border {
    if (widget.isFolderDragOver) {
      return Border.all(color: AppColors.accent.withValues(alpha: 0.4));
    }
    if (widget.selected) {
      return Border(left: BorderSide(color: AppColors.accent, width: 2));
    }
    return null;
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!).inMilliseconds < _kDoubleTapMs) {
      _lastTap = null;
      widget.onOpen(widget.entry);
      return;
    }
    _lastTap = now;
    widget.onSelect(
      FileSelectionEvent(entry: widget.entry, index: widget.index),
    );
  }

  void _handleSecondaryTap(TapUpDetails details) {
    widget.onContextMenu?.call(
      FileSelectionEvent(entry: widget.entry, index: widget.index),
      details.globalPosition,
    );
  }

  Widget _buildDragImage(BuildContext context, Widget child) {
    final dragCount = widget.selected ? widget.selectedPaths.length : 1;

    final e = widget.entry;
    final isFolder = e.type == FileItemType.folder;

    final visualRow = Container(
      width: 260,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSidebar,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.bgDivider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isFolder ? WaydirIconsFill.folder : fileIcon(e.extension),
            size: 20,
            color: isFolder
                ? AppColors.folderColor
                : fileIconColor(e.extension),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              dragCount > 1 ? t.fileView.movingItems(count: dragCount) : e.name,
              overflow: TextOverflow.ellipsis,
              style: context.txt.dialogTitle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );

    return visualRow;
  }

  Future<DragItem?> _provideDragItem(DragItemRequest request) async {
    List<String> pathsToDrag;

    if (!widget.selected) {
      widget.onSelect(
        FileSelectionEvent(entry: widget.entry, index: widget.index),
      );
      pathsToDrag = [widget.entry.path];
    } else {
      pathsToDrag = widget.selectedPaths.toList();
    }

    final item = DragItem(localData: {'paths': pathsToDrag});
    item.add(formatLocalFile(pathsToDrag.join('\n')));

    for (final path in pathsToDrag) {
      item.add(Formats.fileUri(Uri.file(path)));
    }

    final initialMode = HardwareKeyboard.instance.isAltPressed
        ? DragMode.move
        : DragMode.copy;

    void updateDragging() {
      final isDragging = request.session.dragging.value;
      if (mounted) {
        setState(() => _dragging = isDragging);
      }
      if (isDragging) {
        DragHintController.instance.mode.value = initialMode;
      }
    }

    request.session.dragging.addListener(updateDragging);
    updateDragging();

    return item;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final isFolder = e.type == FileItemType.folder;
    final opacity = widget.isCut ? 0.4 : (_dragging ? 0.4 : 1.0);

    if (widget.isRenaming) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          height: widget.rowHeight,
          padding: const EdgeInsets.only(left: 12, right: 16),
          decoration: BoxDecoration(color: _bg, border: _border),
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                Icon(
                  isFolder ? WaydirIconsFill.folder : fileIcon(e.extension),
                  size: 16,
                  color: isFolder
                      ? AppColors.folderColor
                      : fileIconColor(e.extension),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.escape):
                          _cancelRename,
                    },
                    child: TextField(
                      controller: _renameController,
                      focusNode: _renameFocusNode,
                      autofocus: true,
                      style: context.txt.bodyEmphasis,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(3),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(3),
                          borderSide: BorderSide(
                            color: AppColors.bgDivider,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(3),
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 1,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _commitRename(),
                      onTapOutside: (_) => _commitRename(),
                    ),
                  ),
                ),
                if (widget.recursive) ...[
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        widget.location ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: context.txt.muted,
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: widget.sizeWidth,
                    child: Text(
                      isFolder ? '--' : formatBytes(e.size),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: context.txt.muted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: widget.dateWidth,
                    child: Text(
                      _formatDateBy(
                        e.modified,
                        widget.dateFmt,
                        recentDatesRelative: widget.recentDatesRelative,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: context.txt.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final row = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        onSecondaryTapUp: _handleSecondaryTap,
        onTertiaryTapUp: (_) {
          if (widget.entry.type == FileItemType.folder) {
            widget.onOpenInNewTab?.call(widget.entry.path);
          }
        },
        child: Container(
          height: widget.rowHeight,
          padding: const EdgeInsets.only(left: 12, right: 16),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: widget.isFolderDragOver
                ? BorderRadius.circular(4)
                : null,
            border: _border,
          ),
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                Icon(
                  isFolder ? WaydirIconsFill.folder : fileIcon(e.extension),
                  size: 16,
                  color: isFolder
                      ? AppColors.folderColor
                      : fileIconColor(e.extension),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: Text(
                    e.name,
                    overflow: TextOverflow.ellipsis,
                    style: context.txt.body.copyWith(
                      color: widget.selected
                          ? AppColors.fg
                          : AppColors.fg.withValues(alpha: 0.9),
                      fontWeight: widget.selected
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (widget.recursive) ...[
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        widget.location ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: context.txt.muted,
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: widget.sizeWidth,
                    child: Text(
                      isFolder ? '--' : formatBytes(e.size),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: context.txt.muted,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: widget.dateWidth,
                    child: Text(
                      _formatDateBy(
                        e.modified,
                        widget.dateFmt,
                        recentDatesRelative: widget.recentDatesRelative,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: context.txt.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return DragItemWidget(
      dragItemProvider: _provideDragItem,
      allowedOperations: () => [DropOperation.copy, DropOperation.move],
      canAddItemToExistingSession: true,
      dragBuilder: _buildDragImage,
      child: DraggableWidget(child: row),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback? onCloseSearch;

  const _EmptyState({this.isSearching = false, this.onCloseSearch});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: null,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              WaydirIconsRegular.folderOpen,
              size: 48,
              color: AppColors.fgSubtle,
            ),
            const SizedBox(height: 12),
            if (isSearching) ...[
              Text(
                t.search.noMatches,
                style: context.txt.dialogTitle.copyWith(
                  color: AppColors.fgMuted,
                ),
              ),
              const SizedBox(height: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onCloseSearch,
                  child: Text(
                    t.search.clear,
                    style: context.txt.body.copyWith(
                      color: AppColors.accent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ] else
              Text(
                t.fileView.empty,
                style: context.txt.dialogTitle.copyWith(
                  color: AppColors.fgMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatDateBy(
  DateTime d,
  String mode, {
  required bool recentDatesRelative,
}) {
  switch (mode) {
    case 'locale':
      if (recentDatesRelative && _isRecentDate(d)) return _formatRelative(d);
      return _formatLocale(d);
    case 'relative':
      return _formatRelative(d);
    case 'iso':
    default:
      return _formatIso(d);
  }
}

bool _isRecentDate(DateTime d) {
  final diff = DateTime.now().difference(d);
  return !diff.isNegative && diff.inHours < 24;
}

String _formatIso(DateTime d) {
  return '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

String _formatLocale(DateTime d) {
  final locale = intl.Intl.canonicalizedLocale(
    ui.PlatformDispatcher.instance.locale.toLanguageTag(),
  );
  try {
    return intl.DateFormat.yMd(locale).add_jm().format(d);
  } catch (_) {
    return _formatIso(d);
  }
}

String _formatRelative(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}
