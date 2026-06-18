import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart' show WaydirIconsRegular;
import 'package:signals/signals_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import '../../i18n/strings.g.dart';
import '../../core/fs/file_sort.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../../ui/overlays/popup_overlay.dart';
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
const _kLocationWidth = 190.0;
const _kScrollbarThumbWidth = 6.0;
const _kScrollbarGutterWidth = _kScrollbarThumbWidth;
const _kRowPaddingLeft = 8.0;
const _kRowPaddingRight = 10.0;
const _kNameMinWidth = 160.0;
const _kNameManualDefaultWidth = 260.0;
const _kLocationMinWidth = 120.0;
const _kColumnGap = 16.0;
const _kHeaderHeight = 24.0;
const _kResizeHandleWidth = 8.0;
const _kColumnWidthsNameKey = 'name';
const _kColumnWidthsLocationKey = 'location';

/// Optional, user-toggleable file-list columns (Name and the recursive-search
/// Location column are not part of this set). Order here is the display order.
enum FileColumn { size, date, kind, created, added, permissions, owner }

String fileColumnLabel(FileColumn col) {
  final c = t.fileView.columns;
  switch (col) {
    case FileColumn.size:
      return c.size;
    case FileColumn.date:
      return c.dateModified;
    case FileColumn.kind:
      return c.kind;
    case FileColumn.created:
      return c.dateCreated;
    case FileColumn.added:
      return c.dateAdded;
    case FileColumn.permissions:
      return c.permissions;
    case FileColumn.owner:
      return c.owner;
  }
}

SortKey fileColumnSortKey(FileColumn col) {
  switch (col) {
    case FileColumn.size:
      return SortKey.size;
    case FileColumn.date:
      return SortKey.date;
    case FileColumn.kind:
      return SortKey.kind;
    case FileColumn.created:
      return SortKey.created;
    case FileColumn.added:
      return SortKey.added;
    case FileColumn.permissions:
      return SortKey.permissions;
    case FileColumn.owner:
      return SortKey.owner;
  }
}

String fileColumnText(
  FileColumn col,
  FileEntry e, {
  required String dateFmt,
  required bool recentDatesRelative,
  int? folderSize,
}) {
  final isFolder = e.type == FileItemType.folder;
  switch (col) {
    case FileColumn.size:
      if (isFolder) return folderSize == null ? '--' : formatBytes(folderSize);

      return formatBytes(e.size);
    case FileColumn.date:
      return _formatDateBy(
        e.modified,
        dateFmt,
        recentDatesRelative: recentDatesRelative,
      );
    case FileColumn.kind:
      return e.kind;
    case FileColumn.created:
      return _formatDateBy(
        e.created,
        dateFmt,
        recentDatesRelative: recentDatesRelative,
      );
    case FileColumn.added:
      return _formatDateBy(
        e.added,
        dateFmt,
        recentDatesRelative: recentDatesRelative,
      );
    case FileColumn.permissions:
      return e.permissionsString;
    case FileColumn.owner:
      return e.ownerName;
  }
}

Signal<bool> fileColumnSignal(FileColumn col) {
  final s = SettingsStore.instance;
  switch (col) {
    case FileColumn.size:
      return s.showColumnSize;
    case FileColumn.date:
      return s.showColumnDate;
    case FileColumn.kind:
      return s.showColumnKind;
    case FileColumn.created:
      return s.showColumnCreated;
    case FileColumn.added:
      return s.showColumnAdded;
    case FileColumn.permissions:
      return s.showColumnPermissions;
    case FileColumn.owner:
      return s.showColumnOwner;
  }
}

/// Parses the saved column order (a CSV of [FileColumn] names) into the full
/// ordered list. Unknown ids are dropped and any column missing from the saved
/// string is appended in declaration order, so newly added columns always show.
List<FileColumn> parseColumnOrder(String csv) {
  final byName = {for (final c in FileColumn.values) c.name: c};
  final out = <FileColumn>[];
  for (final id in csv.split(',')) {
    final col = byName[id.trim()];
    if (col != null && !out.contains(col)) out.add(col);
  }
  for (final c in FileColumn.values) {
    if (!out.contains(c)) out.add(c);
  }

  return out;
}

String columnOrderToString(List<FileColumn> columns) =>
    columns.map((c) => c.name).join(',');

/// Whether [col] is meaningful on the current platform. Permissions and owner
/// are POSIX concepts that Windows doesn't expose, so they're hidden there.
/// Date added relies on kMDItemDateAdded (macOS xattr) and is macOS-only.
bool columnAvailable(FileColumn col) {
  if (PlatformPaths.isWindows &&
      (col == FileColumn.permissions || col == FileColumn.owner)) {
    return false;
  }

  if (col == FileColumn.added && !PlatformPaths.isMacOS) {
    return false;
  }

  return true;
}

/// All optional columns in the user-defined display order.
List<FileColumn> orderedColumns() => [
  for (final col in parseColumnOrder(SettingsStore.instance.columnOrder.value))
    if (columnAvailable(col)) col,
];

String columnWidthKey(FileColumn col) => col.name;

Map<String, double> parseColumnWidths(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) return const {};

    return {
      for (final entry in decoded.entries)
        if (entry.value is num) entry.key: (entry.value as num).toDouble(),
    };
  } catch (_) {
    return const {};
  }
}

String columnWidthsToString(Map<String, double> widths) {
  final sorted = Map<String, double>.fromEntries(
    widths.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );

  return jsonEncode(sorted);
}

double minColumnWidth(String key) {
  if (key == _kColumnWidthsNameKey) return _kNameMinWidth;
  if (key == _kColumnWidthsLocationKey) return _kLocationMinWidth;

  return 56;
}

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
  final ValueChanged<int>? onPageRows;
  final Map<String, int> folderSizes;

  const FileList({
    super.key,
    required this.files,
    required this.currentPath,
    this.folderSizes = const {},
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
    this.onPageRows,
  });

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  final _scrollController = ScrollController();
  final _hScrollController = ScrollController();
  double _contentWidth = 0;
  bool _isDragOver = false;
  String? _hoveredFolderPath;
  double _rowH = _kRowHeightComfortable;
  double _rowG = _kRowGapComfortable;
  double _itemExt = _kRowHeightComfortable + _kRowGapComfortable;
  double _listHorizontalSpacing = _kRowGapComfortable;
  double _scale = 1.0;
  double _viewportWidth = 0;
  String _dateFmt = 'locale';
  bool _recentDatesRelative = true;
  String? _lastRevealedKey;
  int _lastReportedRows = -1;

  double get _listTopPadding => _rowG;
  double get _listHorizontalPadding => _listHorizontalSpacing;

  double _measureWidth(String text, TextStyle style) {
    if (text.isEmpty) return 0;
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: TextScaler.linear(_scale),
    )..layout();

    return tp.width;
  }

  List<FileColumn> _visibleColumns() => [
    for (final col in orderedColumns())
      if (fileColumnSignal(col).value) col,
  ];

  Map<FileColumn, double> _computeColumnWidths(
    BuildContext context,
    List<FileColumn> columns,
  ) {
    final muted = context.txt.muted;
    final headerStyle = context.txt.fieldLabel;
    final widths = <FileColumn, double>{};
    for (final col in columns) {
      var longest = fileColumnLabel(col);
      for (final e in widget.files) {
        final v = fileColumnText(
          col,
          e,
          dateFmt: _dateFmt,
          recentDatesRelative: _recentDatesRelative,
          folderSize: widget.folderSizes[e.realPath],
        );
        if (v.length > longest.length) longest = v;
      }
      final cellW = _measureWidth(longest, muted);
      final headerW = _measureWidth(fileColumnLabel(col), headerStyle) + 14;
      widths[col] = math.max(cellW, headerW).ceilToDouble() + 8;
    }

    return widths;
  }

  double _persistedColumnWidth(
    Map<String, double> persisted,
    String key,
    double fallback,
  ) {
    final min = minColumnWidth(key);
    final saved = persisted[key];
    if (saved == null || !saved.isFinite) return math.max(min, fallback);

    return math.max(min, saved);
  }

  void _resizeColumn(String key, double delta) {
    if (delta == 0) return;
    final settings = SettingsStore.instance;
    final widths = Map<String, double>.of(
      parseColumnWidths(settings.columnWidths.value),
    );
    final current = _persistedColumnWidth(
      widths,
      key,
      key == _kColumnWidthsNameKey
          ? _kNameManualDefaultWidth
          : key == _kColumnWidthsLocationKey
          ? _kLocationWidth
          : minColumnWidth(key),
    );
    widths[key] = math.max(minColumnWidth(key), current + delta);
    settings.columnWidths.value = columnWidthsToString(widths);
  }

  void _openColumnMenu(BuildContext context, Offset position) {
    showPopup(
      context: context,
      position: position,
      width: 230,
      builder: (_) => const _ColumnConfigMenu(),
    );
  }

  String? _relativeParent(String entryPath, String currentPath) {
    final rel = p.relative(p.dirname(entryPath), from: currentPath);
    if (rel == '.') return null;

    return rel;
  }

  String? _compactLocation(String entryPath, String currentPath) {
    final rel = _relativeParent(entryPath, currentPath);
    if (rel == null) return null;
    final parts = p.split(rel).where((part) => part.isNotEmpty).toList();
    if (parts.length <= 2) return rel;

    return p.join('...', parts[parts.length - 2], parts.last);
  }

  int _rowAt(Offset localPosition) {
    if (localPosition.dy < 0 || localPosition.dx < _listHorizontalPadding) {
      return -1;
    }
    final rightEdge = _contentWidth - _listHorizontalPadding;
    if (_contentWidth > 0 && localPosition.dx >= rightEdge) return -1;

    final adjustedY =
        localPosition.dy + _scrollController.offset - _listTopPadding;
    if (adjustedY < 0) return -1;
    final index = (adjustedY / _itemExt).floor();
    if (index < 0 || index >= widget.files.length) return -1;

    final relativeY = adjustedY % _itemExt;
    if (relativeY >= _rowH) return -1;

    return index;
  }

  bool _canStartRubberBandAt(Offset localPosition) {
    if (_contentWidth <= 0) return true;

    return localPosition.dx < _contentWidth - _listHorizontalPadding;
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
      final top = _listTopPadding + index * _itemExt;
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

  void _reportPageRows() {
    if (widget.onPageRows == null || !_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    if (viewport <= 0 || _itemExt <= 0) return;
    final rows = (viewport / _itemExt).floor().clamp(1, 1 << 20);
    if (rows == _lastReportedRows) return;
    _lastReportedRows = rows;
    widget.onPageRows!(rows);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _hScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final density = SettingsStore.instance.rowDensity.value;
        final horizontalSpacing =
            SettingsStore.instance.fileListHorizontalSpacing.value;
        final verticalSpacing =
            SettingsStore.instance.fileListVerticalSpacing.value;
        _dateFmt = SettingsStore.instance.dateFormat.value;
        _recentDatesRelative = SettingsStore.instance.recentDatesRelative.value;
        _scale = SettingsStore.instance.fileListScale.value;
        _rowH =
            (density == 'compact'
                ? _kRowHeightCompact
                : _kRowHeightComfortable) *
            _scale;
        _rowG = verticalSpacing.toDouble();
        _listHorizontalSpacing = horizontalSpacing.toDouble();
        _itemExt = _rowH + _rowG;
        _revealSelectedRow();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _reportPageRows();
        });

        final columns = _visibleColumns();
        final automaticColumnWidths = _computeColumnWidths(context, columns);
        final resizableColumns =
            SettingsStore.instance.columnWidthMode.value == 'resizable';
        final persistedColumnWidths = parseColumnWidths(
          SettingsStore.instance.columnWidths.value,
        );
        final recursive = widget.recursiveResults;

        return LayoutBuilder(
          builder: (context, constraints) {
            _viewportWidth = constraints.maxWidth;

            final iconSlot = 16 * _scale + 6;
            final rowChrome =
                _listHorizontalPadding * 2 +
                _kScrollbarGutterWidth +
                _kRowPaddingLeft +
                _kRowPaddingRight;
            final automaticOptionalCols = columns.fold<double>(
              0,
              (sum, col) => sum + automaticColumnWidths[col]! + _kColumnGap,
            );
            final automaticFixedCols =
                iconSlot +
                automaticOptionalCols +
                (recursive ? _kLocationWidth + _kColumnGap : 0);
            final automaticAvailable =
                _viewportWidth - rowChrome - automaticFixedCols;
            final automaticNameWidth = math.max(
              _kNameMinWidth,
              automaticAvailable,
            );
            final nameWidth = resizableColumns
                ? _persistedColumnWidth(
                    persistedColumnWidths,
                    _kColumnWidthsNameKey,
                    automaticNameWidth.isFinite
                        ? automaticNameWidth
                        : _kNameManualDefaultWidth,
                  )
                : automaticNameWidth;
            final locationWidth = resizableColumns
                ? _persistedColumnWidth(
                    persistedColumnWidths,
                    _kColumnWidthsLocationKey,
                    _kLocationWidth,
                  )
                : _kLocationWidth;
            final columnWidths = resizableColumns
                ? {
                    for (final col in columns)
                      col: _persistedColumnWidth(
                        persistedColumnWidths,
                        columnWidthKey(col),
                        automaticColumnWidths[col]!,
                      ),
                  }
                : automaticColumnWidths;
            final optionalCols = columns.fold<double>(
              0,
              (sum, col) => sum + columnWidths[col]! + _kColumnGap,
            );
            final fixedCols =
                iconSlot +
                optionalCols +
                (recursive ? locationWidth + _kColumnGap : 0);
            _contentWidth = nameWidth + fixedCols + rowChrome;
            final bodyWidth = math.max(_contentWidth, _viewportWidth);

            return Stack(
              children: [
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false),
                  child: RawScrollbar(
                    controller: _hScrollController,
                    thumbVisibility: bodyWidth > _viewportWidth,
                    thumbColor: AppColors.fgSubtle,
                    thickness: _kScrollbarThumbWidth,
                    crossAxisMargin: 0,
                    radius: Radius.zero,
                    scrollbarOrientation: ScrollbarOrientation.bottom,
                    child: SingleChildScrollView(
                      controller: _hScrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: bodyWidth,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _ListHeader(
                                    recursive: recursive,
                                    leadingWidth: iconSlot,
                                    nameWidth: nameWidth,
                                    locationWidth: locationWidth,
                                    columns: columns,
                                    columnWidths: columnWidths,
                                    resizable: resizableColumns,
                                    sortColumn: widget.sortColumn,
                                    sortAscending: widget.sortAscending,
                                    onSortColumn: widget.onSortColumn,
                                    onResizeColumn: _resizeColumn,
                                    onConfigureColumns: (pos) =>
                                        _openColumnMenu(context, pos),
                                  ),
                                ),
                                SizedBox(
                                  width: _kScrollbarGutterWidth,
                                  height: 24,
                                  child: ColoredBox(color: AppColors.bg),
                                ),
                              ],
                            ),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.bgDivider,
                            ),
                            Expanded(
                              child: RubberBandLayer(
                                scrollController: _scrollController,
                                itemCount: widget.files.length,
                                itemExtent: _itemExt,
                                rowHeight: _rowH,
                                topPadding: _listTopPadding,
                                pathAt: (i) => widget.files[i].path,
                                rowAt: _rowAt,
                                canStartSelectionAt: _canStartRubberBandAt,
                                onSelectionChanged: widget.onRectSelect,
                                onBackgroundTap: widget.onBackgroundTap,
                                child: DropRegion(
                                  formats: [Formats.fileUri, formatLocalFile],
                                  hitTestBehavior: HitTestBehavior.opaque,
                                  onDropOver: (event) {
                                    _updateHover(event.position.local);

                                    return DragHintController
                                                .instance
                                                .mode
                                                .value ==
                                            DragMode.move
                                        ? DropOperation.move
                                        : DropOperation.copy;
                                  },
                                  onDropLeave: (_) => _clearDrag(),
                                  onDropEnded: (_) => _clearDrag(),
                                  onPerformDrop: (event) async {
                                    final pos = event.position.local;
                                    final index = _rowAt(pos);
                                    String? target;
                                    if (index >= 0 &&
                                        widget.files[index].type ==
                                            FileItemType.folder) {
                                      target = widget.files[index].path;
                                    }
                                    final paths = await pathsFromSession(
                                      event.session,
                                    );
                                    final move =
                                        DragHintController
                                            .instance
                                            .mode
                                            .value ==
                                        DragMode.move;
                                    if (paths.isNotEmpty) {
                                      widget.onDropFiles?.call(
                                        paths,
                                        target ?? widget.currentPath,
                                        move: move,
                                      );
                                    }
                                    _clearDrag();
                                  },
                                  child: ScrollConfiguration(
                                    behavior: ScrollConfiguration.of(
                                      context,
                                    ).copyWith(scrollbars: false),
                                    child: GestureDetector(
                                      onSecondaryTapUp: (d) {
                                        final index = _rowAt(d.localPosition);
                                        if (index < 0) {
                                          widget.onBackgroundTap?.call();
                                          widget.onBackgroundContextMenu?.call(
                                            d.globalPosition,
                                          );
                                        }
                                      },
                                      behavior: HitTestBehavior.translucent,
                                      child: MediaQuery.withClampedTextScaling(
                                        minScaleFactor: _scale,
                                        maxScaleFactor: _scale,
                                        child: ListView.builder(
                                          controller: _scrollController,
                                          padding: EdgeInsets.only(
                                            left: _listHorizontalPadding,
                                            top: _listTopPadding,
                                            right:
                                                _listHorizontalPadding +
                                                _kScrollbarGutterWidth,
                                          ),
                                          itemCount: widget.files.length,
                                          itemExtent: _itemExt,
                                          addAutomaticKeepAlives: false,
                                          addRepaintBoundaries: false,
                                          addSemanticIndexes: false,
                                          itemBuilder: (context, i) =>
                                              RepaintBoundary(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: _rowG,
                                                  ),
                                                  child: _ListRow(
                                                    rowHeight: _rowH,
                                                    iconSize: 16 * _scale,
                                                    dateFmt: _dateFmt,
                                                    recentDatesRelative:
                                                        _recentDatesRelative,
                                                    entry: widget.files[i],
                                                    folderSize:
                                                        widget
                                                            .folderSizes[widget
                                                            .files[i]
                                                            .realPath],
                                                    index: i,
                                                    nameWidth: nameWidth,
                                                    locationWidth:
                                                        locationWidth,
                                                    selected: widget
                                                        .selectedPaths
                                                        .contains(
                                                          widget.files[i].path,
                                                        ),
                                                    selectedPaths:
                                                        widget.selectedPaths,
                                                    isCut: widget.cutPaths
                                                        .contains(
                                                          widget.files[i].path,
                                                        ),
                                                    isDraggingSelected: widget
                                                        .selectedPaths
                                                        .isNotEmpty,
                                                    isFolderDragOver:
                                                        _hoveredFolderPath ==
                                                        widget.files[i].path,
                                                    isRenaming:
                                                        widget.renamingPath ==
                                                        widget.files[i].path,
                                                    renameAttempt:
                                                        widget.renameAttempt,
                                                    onRenameSubmit:
                                                        widget.onRenameSubmit,
                                                    onRenameCancel:
                                                        widget.onRenameCancel,
                                                    onSelect: widget.onSelect,
                                                    onOpen: widget.onOpen,
                                                    onContextMenu:
                                                        widget.onContextMenu,
                                                    onMenuAction:
                                                        widget.onMenuAction,
                                                    recursive: recursive,
                                                    columns: columns,
                                                    columnWidths: columnWidths,
                                                    location: recursive
                                                        ? _compactLocation(
                                                            widget
                                                                .files[i]
                                                                .path,
                                                            widget.currentPath,
                                                          )
                                                        : null,
                                                    onOpenInNewTab:
                                                        widget.onOpenInNewTab,
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: _kHeaderHeight + 1,
                  right: 0,
                  bottom: 0,
                  width: _kScrollbarGutterWidth,
                  child: _PinnedVerticalScrollbar(
                    controller: _scrollController,
                  ),
                ),
                if (widget.files.isEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !widget.recursiveResults,
                      child: ColoredBox(
                        color: AppColors.bg,
                        child: _EmptyState(
                          isSearching: widget.recursiveResults,
                          onCloseSearch: widget.onCloseSearch,
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
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ListHeader extends StatelessWidget {
  final bool recursive;
  final double leadingWidth;
  final double nameWidth;
  final double locationWidth;
  final List<FileColumn> columns;
  final Map<FileColumn, double> columnWidths;
  final bool resizable;
  final SortKey sortColumn;
  final bool sortAscending;
  final void Function(SortKey key)? onSortColumn;
  final void Function(String key, double delta)? onResizeColumn;
  final void Function(Offset globalPosition)? onConfigureColumns;
  const _ListHeader({
    this.recursive = false,
    this.leadingWidth = 22,
    this.nameWidth = 0,
    this.locationWidth = _kLocationWidth,
    this.columns = const [],
    this.columnWidths = const {},
    this.resizable = false,
    this.sortColumn = SortKey.name,
    this.sortAscending = true,
    this.onSortColumn,
    this.onResizeColumn,
    this.onConfigureColumns,
  });

  Widget _sortable(String label, SortKey key, TextStyle style) {
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

  Widget _cell({
    required double width,
    required Widget child,
    required String resizeKey,
  }) {
    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          if (resizable && onResizeColumn != null)
            Positioned(
              top: 0,
              right: -_kResizeHandleWidth / 2,
              bottom: 0,
              width: _kResizeHandleWidth,
              child: _ColumnResizeHandle(
                onDelta: (delta) => onResizeColumn!(resizeKey, delta),
              ),
            ),
        ],
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
          SizedBox(
            width: leadingWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _ConfigureColumnsButton(onTap: onConfigureColumns),
            ),
          ),
          _cell(
            width: nameWidth,
            resizeKey: _kColumnWidthsNameKey,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _sortable(
                t.fileView.columns.name,
                SortKey.name,
                headerStyle,
              ),
            ),
          ),
          if (recursive) ...[
            _cell(
              width: locationWidth,
              resizeKey: _kColumnWidthsLocationKey,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  t.fileView.columns.location,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: headerStyle,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          for (final col in columns) ...[
            _cell(
              width: columnWidths[col] ?? 0,
              resizeKey: columnWidthKey(col),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _sortable(
                  fileColumnLabel(col),
                  fileColumnSortKey(col),
                  headerStyle,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

class _ConfigureColumnsButton extends StatefulWidget {
  final void Function(Offset globalPosition)? onTap;
  const _ConfigureColumnsButton({this.onTap});

  @override
  State<_ConfigureColumnsButton> createState() =>
      _ConfigureColumnsButtonState();
}

class _ConfigureColumnsButtonState extends State<_ConfigureColumnsButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (d) => widget.onTap!(d.globalPosition),
        child: Tooltip(
          message: t.fileView.columns.configure,
          child: Container(
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHoverStrong : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              WaydirIconsRegular.slidersHorizontal,
              size: 14,
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnResizeHandle extends StatefulWidget {
  final ValueChanged<double> onDelta;

  const _ColumnResizeHandle({required this.onDelta});

  @override
  State<_ColumnResizeHandle> createState() => _ColumnResizeHandleState();
}

class _ColumnResizeHandleState extends State<_ColumnResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _dragging;

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (details) => widget.onDelta(details.delta.dx),
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        child: Center(
          child: Container(
            width: 1,
            height: double.infinity,
            color: active ? AppColors.accent : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

/// Popup that lets the user toggle optional file-list columns on/off and
/// reorder them by dragging, mirroring the sidebar edit-mode interaction.
class _ColumnConfigMenu extends StatelessWidget {
  const _ColumnConfigMenu();

  void _reorder(int oldIndex, int newIndex) {
    final cols = orderedColumns();
    if (oldIndex < 0 || oldIndex >= cols.length) return;
    var to = newIndex.clamp(0, cols.length - 1);
    if (to == oldIndex) return;
    final moved = cols.removeAt(oldIndex);
    cols.insert(to, moved);
    SettingsStore.instance.columnOrder.value = columnOrderToString(cols);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SignalBuilder(
            builder: (context) {
              final cols = orderedColumns();

              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: cols.length,
                onReorderItem: _reorder,
                itemBuilder: (context, index) {
                  final col = cols[index];

                  return _ColumnConfigRow(
                    key: ValueKey(col),
                    col: col,
                    index: index,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColumnConfigRow extends StatefulWidget {
  final FileColumn col;
  final int index;

  const _ColumnConfigRow({super.key, required this.col, required this.index});

  @override
  State<_ColumnConfigRow> createState() => _ColumnConfigRowState();
}

class _ColumnConfigRowState extends State<_ColumnConfigRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final signal = fileColumnSignal(widget.col);
    final visible = signal.value;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => signal.value = !signal.value,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: _hovered ? AppColors.bgHoverStrong : Colors.transparent,
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Icon(
                    WaydirIconsRegular.list,
                    size: 14,
                    color: AppColors.fgSubtle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  fileColumnLabel(widget.col),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.body.copyWith(
                    color: visible ? AppColors.fg : AppColors.fgMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ColumnCheckbox(value: visible),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnCheckbox extends StatelessWidget {
  final bool value;

  const _ColumnCheckbox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: value ? AppColors.accent : Colors.transparent,
        border: Border.all(
          color: value ? AppColors.accent : AppColors.borderColor,
          width: 1,
        ),
      ),
      child: value
          ? Icon(WaydirIconsRegular.check, size: 10, color: Colors.white)
          : null,
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
  final double nameWidth;
  final double locationWidth;
  final List<FileColumn> columns;
  final Map<FileColumn, double> columnWidths;
  final double rowHeight;
  final double iconSize;
  final String dateFmt;
  final bool recentDatesRelative;
  final String? location;
  final OpenInNewTabCallback? onOpenInNewTab;
  final int? folderSize;

  const _ListRow({
    required this.entry,
    required this.index,
    this.folderSize,
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
    this.nameWidth = 0,
    this.locationWidth = _kLocationWidth,
    this.columns = const [],
    this.columnWidths = const {},
    this.rowHeight = _kRowHeightComfortable,
    this.iconSize = 16,
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

  List<Widget> _buildColumnCells(BuildContext context, FileEntry e) {
    final muted = context.txt.muted;

    return [
      for (final col in widget.columns) ...[
        SizedBox(
          width: widget.columnWidths[col] ?? 0,
          child: Text(
            fileColumnText(
              col,
              e,
              dateFmt: widget.dateFmt,
              recentDatesRelative: widget.recentDatesRelative,
              folderSize: widget.folderSize,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: muted,
          ),
        ),
        const SizedBox(width: 16),
      ],
    ];
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
        borderRadius: BorderRadius.zero,
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
          buildFileIcon(
            name: e.name,
            ext: e.extension,
            isFolder: isFolder,
            size: 20,
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
    if (!widget.selected) {
      widget.onSelect(
        FileSelectionEvent(entry: widget.entry, index: widget.index),
      );
    }

    final pathsToDrag = _pathsToDrag();
    final item = _dragItemForPaths(pathsToDrag);

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

  List<String> _pathsToDrag() {
    final selectedPaths = widget.selectedPaths.toList();
    if (widget.selected && selectedPaths.isNotEmpty) return selectedPaths;

    return [widget.entry.path];
  }

  DragItem _dragItemForPaths(List<String> paths) {
    final item = DragItem(
      localData: {'paths': paths},
      suggestedName: paths.length == 1 ? p.basename(paths.first) : null,
    );
    item.add(formatLocalFile(paths.join('\n')));

    for (final path in paths) {
      item.add(Formats.fileUri(Uri.file(path)));
    }

    return item;
  }

  Future<DragConfiguration> _expandDragConfiguration(
    DragConfiguration configuration,
    DragSession session,
  ) async {
    final paths = _pathsToDrag();
    if (paths.length <= 1 || configuration.items.isEmpty) {
      return configuration;
    }

    final preview = configuration.items.first;
    final extraImages = <TargetedWidgetSnapshot>[];
    for (var i = 1; i < paths.length; i++) {
      extraImages.add(await _transparentDragSnapshot(preview.image));
    }

    return DragConfiguration(
      items: [
        for (final (index, path) in paths.indexed)
          DragConfigurationItem(
            item: _dragItemForPaths([path]),
            image: index == 0 ? preview.image : extraImages[index - 1],
          ),
      ],
      allowedOperations: configuration.allowedOperations,
      options: configuration.options,
    );
  }

  Future<TargetedWidgetSnapshot> _transparentDragSnapshot(
    TargetedWidgetSnapshot preview,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(Colors.transparent, ui.BlendMode.clear);
    final picture = recorder.endRecording();
    final image = await picture.toImage(1, 1);
    picture.dispose();

    return TargetedWidgetSnapshot(
      WidgetSnapshot.image(image),
      Rect.fromLTWH(preview.rect.left, preview.rect.top, 1, 1),
    );
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
          padding: const EdgeInsets.only(
            left: _kRowPaddingLeft,
            right: _kRowPaddingRight,
          ),
          decoration: BoxDecoration(color: _bg, border: _border),
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                buildFileIcon(
                  name: e.name,
                  ext: e.extension,
                  isFolder: isFolder,
                  size: widget.iconSize,
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: widget.nameWidth,
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
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.accent,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(
                            color: AppColors.bgDivider,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
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
                  SizedBox(
                    width: widget.locationWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        widget.location ?? '',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: context.txt.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                ..._buildColumnCells(context, e),
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
          padding: EdgeInsets.only(
            left: widget.selected ? _kRowPaddingLeft - 2 : _kRowPaddingLeft,
            right: _kRowPaddingRight,
          ),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: widget.isFolderDragOver ? BorderRadius.zero : null,
            border: _border,
          ),
          child: Opacity(
            opacity: opacity,
            child: Row(
              children: [
                buildFileIcon(
                  name: e.name,
                  ext: e.extension,
                  isFolder: isFolder,
                  size: widget.iconSize,
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: widget.nameWidth,
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
                  SizedBox(
                    width: widget.locationWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        widget.location ?? '',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: context.txt.muted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                ..._buildColumnCells(context, e),
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
      child: DraggableWidget(
        onDragConfiguration: _expandDragConfiguration,
        child: row,
      ),
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
}) => formatEntryDate(d, mode, recentDatesRelative: recentDatesRelative);

class _PinnedVerticalScrollbar extends StatelessWidget {
  final ScrollController controller;
  const _PinnedVerticalScrollbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackHeight = constraints.maxHeight;

        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            if (!controller.hasClients) return const SizedBox.shrink();
            final position = controller.position;
            if (!position.hasContentDimensions ||
                !position.hasViewportDimension ||
                !position.hasPixels) {
              return const SizedBox.shrink();
            }
            final maxScroll = position.maxScrollExtent;
            final viewport = position.viewportDimension;
            if (maxScroll <= 0 || viewport <= 0) {
              return const SizedBox.shrink();
            }
            final thumbHeight = math.max(
              24.0,
              trackHeight * viewport / (viewport + maxScroll),
            );
            final maxTravel = trackHeight - thumbHeight;
            final t = (position.pixels / maxScroll).clamp(0.0, 1.0);
            final top = maxTravel * t;

            return Stack(
              children: [
                Positioned(
                  top: top,
                  right: 0,
                  width: _kScrollbarThumbWidth,
                  height: thumbHeight,
                  child: GestureDetector(
                    onVerticalDragUpdate: (d) {
                      if (maxTravel <= 0) return;
                      final delta = d.delta.dy / maxTravel * maxScroll;
                      controller.jumpTo(
                        (position.pixels + delta).clamp(
                          position.minScrollExtent,
                          position.maxScrollExtent,
                        ),
                      );
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.fgSubtle),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
