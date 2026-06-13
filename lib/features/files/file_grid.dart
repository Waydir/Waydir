import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals_flutter.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../utils/drag_drop.dart';
import '../../utils/format.dart';
import '../operations/drag_hint.dart';
import 'file_icons.dart';
import 'file_view.dart'
    show
        BackgroundContextMenuCallback,
        FileContextMenuCallback,
        FileDropCallback,
        FileOpenCallback,
        FileSelectCallback,
        OpenInNewTabCallback,
        RenameCancelCallback,
        RenameSubmitCallback;

const _kGridDoubleTapMs = 300;

// Base metrics at 100% scale. Everything below is multiplied by the user's
// file list scale (0.5x - 2.0x) so the grid zooms uniformly: tile, thumbnail,
// labels and spacing all grow or shrink together.
const _kGridBaseTileWidth = 152.0;
const _kGridBaseThumb = 80.0;
const _kGridGap = 12.0;
const _kGridPadding = 12.0;
const _kTilePadding = 8.0;
const _kThumbGap = 8.0;
const _kNameBlock = 36.0;
const _kCaptionGap = 4.0;
const _kCaptionBlock = 18.0;
const _kTileBorder = 1.0;

double _gridTileHeight(double scale) =>
    ((_kGridBaseThumb +
                    _kThumbGap +
                    _kNameBlock +
                    _kCaptionGap +
                    _kCaptionBlock +
                    _kTilePadding * 2) *
                scale +
            _kTileBorder * 2)
        .ceilToDouble();

class FileGrid extends StatefulWidget {
  final List<FileEntry> files;
  final String currentPath;
  final FileSelectCallback onSelect;
  final FileOpenCallback onOpen;
  final BackgroundContextMenuCallback? onBackgroundContextMenu;
  final FileContextMenuCallback? onContextMenu;
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
  final ValueChanged<int>? onPageRows;
  final ValueChanged<int>? onGridColumns;
  final VoidCallback? onBackgroundTap;

  const FileGrid({
    super.key,
    required this.files,
    required this.currentPath,
    required this.onSelect,
    required this.onOpen,
    this.onBackgroundContextMenu,
    this.onContextMenu,
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
    this.onPageRows,
    this.onGridColumns,
    this.onBackgroundTap,
  });

  @override
  State<FileGrid> createState() => _FileGridState();
}

class _FileGridState extends State<FileGrid> {
  final _scrollController = ScrollController();
  String? _lastRevealedKey;
  String? _hoveredFolderPath;
  bool _isDragOver = false;
  int _lastColumns = 0;
  int _lastRows = 0;
  double _tileHeight = _kGridBaseThumb;

  @override
  void didUpdateWidget(covariant FileGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cursorIndex != widget.cursorIndex ||
        oldWidget.files != widget.files) {
      _revealSelectedTile();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _indexAt(Offset localPosition, double tileWidth, int columns) {
    final y = localPosition.dy + _scrollController.offset - _kGridPadding;
    final x = localPosition.dx - _kGridPadding;
    if (x < 0 || y < 0) return -1;
    final col = (x / (tileWidth + _kGridGap)).floor();
    final row = (y / (_tileHeight + _kGridGap)).floor();
    if (col < 0 || col >= columns || row < 0) return -1;
    final inCol = x - col * (tileWidth + _kGridGap);
    final inRow = y - row * (_tileHeight + _kGridGap);
    if (inCol > tileWidth || inRow > _tileHeight) return -1;
    final index = row * columns + col;
    return index >= 0 && index < widget.files.length ? index : -1;
  }

  void _updateHover(Offset localPosition, double tileWidth, int columns) {
    final index = _indexAt(localPosition, tileWidth, columns);
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

  void _revealSelectedTile() {
    final index = widget.cursorIndex;
    if (index < 0 || index >= widget.files.length || _lastColumns <= 0) {
      return;
    }
    final key = '$index:${widget.files[index].path}:$_lastColumns';
    if (key == _lastRevealedKey) return;
    _lastRevealedKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients || _lastColumns <= 0) {
        return;
      }
      final row = index ~/ _lastColumns;
      final top = _kGridPadding + row * (_tileHeight + _kGridGap);
      final bottom = top + _tileHeight;
      final viewport = _scrollController.position.viewportDimension;
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

  void _reportMetrics(BoxConstraints constraints, int columns) {
    final rows = (constraints.maxHeight / (_tileHeight + _kGridGap))
        .floor()
        .clamp(1, 1 << 20);
    if (columns != _lastColumns) {
      _lastColumns = columns;
      widget.onGridColumns?.call(columns);
    }
    if (rows != _lastRows) {
      _lastRows = rows;
      widget.onPageRows?.call(rows * columns);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final scale = SettingsStore.instance.fileListScale.value;
        final thumbSize = _kGridBaseThumb * scale;
        final tileHeight = _gridTileHeight(scale);
        _tileHeight = tileHeight;
        return LayoutBuilder(
          builder: (context, constraints) {
            final available = (constraints.maxWidth - _kGridPadding * 2).clamp(
              1.0,
              double.infinity,
            );
            final idealWidth = _kGridBaseTileWidth * scale;
            final columns = (available / (idealWidth + _kGridGap))
                .round()
                .clamp(1, 1000);
            final tileWidth = (available - (columns - 1) * _kGridGap) / columns;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _reportMetrics(constraints, columns);
            });
            _revealSelectedTile();
            return Stack(
              children: [
                DropRegion(
                  formats: [Formats.fileUri, formatLocalFile],
                  hitTestBehavior: HitTestBehavior.opaque,
                  onDropOver: (event) {
                    _updateHover(event.position.local, tileWidth, columns);
                    return DragHintController.instance.mode.value ==
                            DragMode.move
                        ? DropOperation.move
                        : DropOperation.copy;
                  },
                  onDropLeave: (_) => _clearDrag(),
                  onDropEnded: (_) => _clearDrag(),
                  onPerformDrop: (event) async {
                    final pos = event.position.local;
                    final index = _indexAt(pos, tileWidth, columns);
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
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.onBackgroundTap,
                    onSecondaryTapUp: (details) {
                      final index = _indexAt(
                        details.localPosition,
                        tileWidth,
                        columns,
                      );
                      if (index < 0) {
                        widget.onBackgroundTap?.call();
                        widget.onBackgroundContextMenu?.call(
                          details.globalPosition,
                        );
                      }
                    },
                    child: GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(_kGridPadding),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: tileHeight,
                        crossAxisSpacing: _kGridGap,
                        mainAxisSpacing: _kGridGap,
                      ),
                      itemCount: widget.files.length,
                      itemBuilder: (context, index) {
                        final entry = widget.files[index];
                        return _GridTile(
                          entry: entry,
                          index: index,
                          scale: scale,
                          thumbSize: thumbSize,
                          selected: widget.selectedPaths.contains(entry.path),
                          isCut: widget.cutPaths.contains(entry.path),
                          isFolderDragOver: _hoveredFolderPath == entry.path,
                          isRenaming: widget.renamingPath == entry.path,
                          renameAttempt: widget.renameAttempt,
                          onRenameSubmit: widget.onRenameSubmit,
                          onRenameCancel: widget.onRenameCancel,
                          onSelect: widget.onSelect,
                          onOpen: widget.onOpen,
                          onContextMenu: widget.onContextMenu,
                          onOpenInNewTab: widget.onOpenInNewTab,
                        );
                      },
                    ),
                  ),
                ),
                if (widget.files.isEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !widget.recursiveResults,
                      child: ColoredBox(
                        color: AppColors.bg,
                        child: _GridEmptyState(
                          isSearching: widget.recursiveResults,
                          onCloseSearch: widget.onCloseSearch,
                        ),
                      ),
                    ),
                  ),
                if (_isDragOver)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
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

class _GridTile extends StatefulWidget {
  final FileEntry entry;
  final int index;
  final double scale;
  final double thumbSize;
  final bool selected;
  final bool isCut;
  final bool isFolderDragOver;
  final bool isRenaming;
  final int renameAttempt;
  final RenameSubmitCallback? onRenameSubmit;
  final RenameCancelCallback? onRenameCancel;
  final FileSelectCallback onSelect;
  final FileOpenCallback onOpen;
  final FileContextMenuCallback? onContextMenu;
  final OpenInNewTabCallback? onOpenInNewTab;

  const _GridTile({
    required this.entry,
    required this.index,
    required this.scale,
    required this.thumbSize,
    required this.selected,
    required this.isCut,
    required this.isFolderDragOver,
    required this.isRenaming,
    required this.renameAttempt,
    this.onRenameSubmit,
    this.onRenameCancel,
    required this.onSelect,
    required this.onOpen,
    this.onContextMenu,
    this.onOpenInNewTab,
  });

  @override
  State<_GridTile> createState() => _GridTileState();
}

class _GridTileState extends State<_GridTile> {
  bool _hovered = false;
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
  void didUpdateWidget(covariant _GridTile oldWidget) {
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

  @override
  void dispose() {
    _disposeRenameFields();
    super.dispose();
  }

  void _initRenameFields() {
    _renameCommitted = false;
    final name = widget.entry.name;
    final dotIndex = widget.entry.type == FileItemType.file
        ? name.lastIndexOf('.')
        : -1;
    final selectionEnd = dotIndex > 0 ? dotIndex : name.length;
    _renameController = TextEditingController(text: name);
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

  void _commitRename() {
    if (_renameCommitted) return;
    _renameCommitted = true;
    widget.onRenameSubmit?.call(_renameController?.text ?? '');
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!).inMilliseconds < _kGridDoubleTapMs) {
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

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final selected = widget.selected;
    final scale = widget.scale;
    final thumbSize = widget.thumbSize;
    final nameStyle = context.txt.row.copyWith(
      fontSize: (context.txt.row.fontSize ?? 13) * scale,
      color: selected ? AppColors.fg : AppColors.fgMuted,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      height: 1.25,
    );
    final captionStyle = context.txt.caption.copyWith(
      fontSize: (context.txt.caption.fontSize ?? 11) * scale,
      color: AppColors.fgSubtle,
      height: 1.15,
    );
    final bg = widget.isFolderDragOver
        ? AppColors.accent.withValues(alpha: 0.12)
        : selected
        ? AppColors.bgSelectedMuted
        : _hovered
        ? AppColors.bgHover
        : Colors.transparent;
    final border = widget.isFolderDragOver
        ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
        : selected
        ? Border.all(color: AppColors.accent.withValues(alpha: 0.7))
        : Border.all(color: Colors.transparent);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onSecondaryTapUp: _handleSecondaryTap,
        child: Opacity(
          opacity: widget.isCut ? 0.45 : 1,
          child: Container(
            padding: EdgeInsets.all(_kTilePadding * scale),
            decoration: BoxDecoration(
              color: bg,
              border: border,
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: thumbSize,
                  height: thumbSize,
                  child: _GridPreview(entry: entry, thumbSize: thumbSize),
                ),
                SizedBox(height: _kThumbGap * scale),
                if (widget.isRenaming &&
                    _renameController != null &&
                    _renameFocusNode != null)
                  SizedBox(
                    height: _kNameBlock * scale,
                    child: TextField(
                      controller: _renameController,
                      focusNode: _renameFocusNode,
                      onSubmitted: (_) => _commitRename(),
                      onEditingComplete: _commitRename,
                      onTapOutside: (_) => _commitRename(),
                      onChanged: (_) => _renameCommitted = false,
                      style: nameStyle.copyWith(color: AppColors.fg),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        filled: true,
                        fillColor: AppColors.bgInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.zero,
                          borderSide: BorderSide(color: AppColors.accent),
                        ),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[/\\]')),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: _kNameBlock * scale,
                    child: Center(
                      child: Text(
                        entry.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: nameStyle,
                      ),
                    ),
                  ),
                SizedBox(height: _kCaptionGap * scale),
                SizedBox(
                  height: _kCaptionBlock * scale,
                  child: Text(
                    entry.type == FileItemType.folder
                        ? entry.kind
                        : '${entry.kind} · ${formatBytes(entry.size)}',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: captionStyle,
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

class _GridPreview extends StatelessWidget {
  final FileEntry entry;
  final double thumbSize;

  const _GridPreview({required this.entry, required this.thumbSize});

  @override
  Widget build(BuildContext context) {
    final isFolder = entry.type == FileItemType.folder;
    final thumbnail = !isFolder && _isThumbnailable(entry)
        ? _ImageThumbnail(entry: entry, thumbSize: thumbSize)
        : null;
    return Center(
      child:
          thumbnail ??
          buildFileIcon(
            name: entry.name,
            ext: entry.extension,
            isFolder: isFolder,
            size: thumbSize * (isFolder ? 0.78 : 0.7),
          ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final FileEntry entry;
  final double thumbSize;

  const _ImageThumbnail({required this.entry, required this.thumbSize});

  @override
  Widget build(BuildContext context) {
    final file = File(entry.realPath);
    final cache = (thumbSize * 2.2).round().clamp(96, 360);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: AppColors.bgDivider)),
      child: ClipRect(
        child: Image.file(
          file,
          width: thumbSize,
          height: thumbSize,
          cacheWidth: cache,
          cacheHeight: cache,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => buildFileIcon(
            name: entry.name,
            ext: entry.extension,
            isFolder: false,
            size: thumbSize * 0.7,
          ),
        ),
      ),
    );
  }
}

class _GridEmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback? onCloseSearch;

  const _GridEmptyState({this.isSearching = false, this.onCloseSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
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
              style: context.txt.dialogTitle.copyWith(color: AppColors.fgMuted),
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
              style: context.txt.dialogTitle.copyWith(color: AppColors.fgMuted),
            ),
        ],
      ),
    );
  }
}

bool _isThumbnailable(FileEntry entry) {
  if (PlatformPaths.isRemoteUri(entry.realPath)) return false;
  switch (entry.extension) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
    case 'bmp':
      return true;
    default:
      return false;
  }
}
