import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../../core/fs/file_system_service.dart';
import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import 'bookmark_store.dart';
import 'breadcrumbs/breadcrumb_bar.dart';
import 'breadcrumbs/crumb.dart';
import 'navigation_store.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../i18n/strings.g.dart';
import '../../ui/overlays/context_menu.dart';
import '../../ui/overlays/toast.dart';

class PaneLocationBar extends StatelessWidget {
  final NavigationStore store;
  final VoidCallback? onMultiRename;

  const PaneLocationBar({super.key, required this.store, this.onMultiRename});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.bgToolbar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          children: [
            SignalBuilder(
              builder: (context) => _ToolBtn(
                WaydirIconsRegular.arrowLeft,
                store.goBack,
                store.canGoBack.value,
                t.toolbar.back,
              ),
            ),
            SignalBuilder(
              builder: (context) => _ToolBtn(
                WaydirIconsRegular.arrowRight,
                store.goForward,
                store.canGoForward.value,
                t.toolbar.forward,
              ),
            ),
            _ToolBtn(
              WaydirIconsRegular.arrowUp,
              store.goUp,
              true,
              t.toolbar.up,
            ),
            Container(
              width: 1,
              height: 16,
              color: AppColors.bgDivider,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
            _ToolBtn(
              WaydirIconsRegular.arrowClockwise,
              store.refresh,
              true,
              t.toolbar.refresh,
            ),
            const SizedBox(width: 6),
            Expanded(child: _PathBar(store: store)),
            const SizedBox(width: 6),
            _RightActions(
              store: store,
              toolbarWidth: constraints.maxWidth,
              onMultiRename: onMultiRename,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _RightActions extends StatelessWidget {
  final NavigationStore store;
  final double toolbarWidth;
  final VoidCallback? onMultiRename;

  const _RightActions({
    required this.store,
    required this.toolbarWidth,
    this.onMultiRename,
  });

  static const double _collapseBelow = 480.0;

  @override
  Widget build(BuildContext context) {
    if (toolbarWidth < _collapseBelow) {
      return _OverflowMenuButton(store: store, onMultiRename: onMultiRename);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onMultiRename != null)
          SignalBuilder(
            builder: (context) {
              if (store.selectedCount.value < 2) return const SizedBox.shrink();
              return _ToolBtn(
                WaydirIconsRegular.pencilSimple,
                onMultiRename!,
                true,
                t.menu.multiRename,
              );
            },
          ),
        SignalBuilder(
          builder: (context) {
            final path = store.currentPath.value;
            final bookmarked = BookmarkStore.instance.containsPath(path);
            return _ToolBtn(
              WaydirIconsRegular.bookmarkSimple,
              () => unawaited(BookmarkStore.instance.togglePath(path)),
              path.isNotEmpty,
              bookmarked
                  ? t.menu.removeBookmark
                  : t.sidebar.connectDialog.addBookmark,
              active: bookmarked,
            );
          },
        ),
        SignalBuilder(
          builder: (context) => _ToolBtn(
            WaydirIconsRegular.magnifyingGlass,
            () => store.searchActive.value
                ? store.closeSearch()
                : store.openSearch(),
            true,
            t.toolbar.search,
          ),
        ),
        _NewFolderButton(store: store),
      ],
    );
  }
}

class _OverflowMenuButton extends StatefulWidget {
  final NavigationStore store;
  final VoidCallback? onMultiRename;
  const _OverflowMenuButton({required this.store, this.onMultiRename});

  @override
  State<_OverflowMenuButton> createState() => _OverflowMenuButtonState();
}

class _OverflowMenuButtonState extends State<_OverflowMenuButton> {
  bool _hovered = false;

  static const String _actionBookmark = 'bookmark';
  static const String _actionSearch = 'search';
  static const String _actionNewFolder = 'newFolder';
  static const String _actionMultiRename = 'multiRename';

  void _open() {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(
      Offset(0, box.size.height + 2),
      ancestor: overlay,
    );
    final path = widget.store.currentPath.value;
    final bookmarked = BookmarkStore.instance.containsPath(path);
    final selCount = widget.store.selectedCount.value;
    final showMultiRename = widget.onMultiRename != null && selCount >= 2;

    showContextMenu(
      context: context,
      position: position,
      items: [
        if (showMultiRename)
          ContextMenuItem(
            icon: WaydirIconsRegular.pencilSimple,
            label: t.menu.multiRename,
            action: _actionMultiRename,
          ),
        ContextMenuItem(
          icon: WaydirIconsRegular.bookmarkSimple,
          label: bookmarked
              ? t.menu.removeBookmark
              : t.sidebar.connectDialog.addBookmark,
          action: _actionBookmark,
          enabled: path.isNotEmpty,
        ),
        ContextMenuItem(
          icon: WaydirIconsRegular.magnifyingGlass,
          label: t.toolbar.search,
          action: _actionSearch,
        ),
        ContextMenuItem(
          icon: WaydirIconsRegular.folderPlus,
          label: t.toolbar.newFolder,
          action: _actionNewFolder,
        ),
      ],
      onSelect: (action) {
        switch (action) {
          case _actionBookmark:
            unawaited(BookmarkStore.instance.togglePath(path));
          case _actionSearch:
            widget.store.searchActive.value
                ? widget.store.closeSearch()
                : widget.store.openSearch();
          case _actionNewFolder:
            widget.store.startCreate();
          case _actionMultiRename:
            widget.onMultiRename?.call();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: t.toolbar.more,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _open,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
            ),
            child: Icon(
              WaydirIconsRegular.dotsThreeOutline,
              size: 16,
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final String tooltip;
  final bool active;

  const _ToolBtn(
    this.icon,
    this.onTap,
    this.enabled,
    this.tooltip, {
    this.active = false,
  });

  @override
  State<_ToolBtn> createState() => _ToolBtnState();
}

class _ToolBtnState extends State<_ToolBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? AppColors.bgHover
                  : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(widget.icon, size: 16, color: _iconColor),
          ),
        ),
      ),
    );
  }

  Color get _iconColor {
    if (!widget.enabled) return AppColors.fgSubtle;
    if (widget.active) return AppColors.warning;
    return _hovered ? AppColors.fg : AppColors.fgMuted;
  }
}

class _PathBar extends StatefulWidget {
  final NavigationStore store;

  const _PathBar({required this.store});

  @override
  State<_PathBar> createState() => _PathBarState();
}

class _PathBarState extends State<_PathBar> {
  bool _editing = false;
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  final _suggestionLayerLink = LayerLink();
  OverlayEntry? _suggestionOverlay;
  List<_PathSuggestion> _suggestions = const [];
  int _suggestionIndex = -1;
  int _suggestionToken = 0;
  bool _choosingSuggestion = false;
  void Function()? _disposePathListener;

  static const int _maxSuggestions = 8;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.store.currentPath.value);
    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
    _initPathEffect();
  }

  @override
  void didUpdateWidget(covariant _PathBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      _disposePathListener?.call();
      _initPathEffect();
    }
  }

  void _initPathEffect() {
    _disposePathListener = effect(() {
      final path = widget.store.currentPath.value;
      if (!_editing && _controller.text != path) {
        _controller.text = path;
      }
    });
  }

  @override
  void dispose() {
    _hideSuggestions();
    _disposePathListener?.call();
    _controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    _controller.text = widget.store.currentPath.value;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      _queueSuggestions();
    });
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus && _editing && !_choosingSuggestion) {
      _cancel();
    }
    if (_focusNode.hasFocus && _editing) _queueSuggestions();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    _hideSuggestions();
    setState(() => _editing = false);
    if (text.isEmpty || text == widget.store.currentPath.value) {
      _controller.text = widget.store.currentPath.value;
      return;
    }
    final ok = await widget.store.navigateToEnteredPath(text);
    if (!ok && mounted) {
      _controller.text = widget.store.currentPath.value;
      showToast(context: context, message: t.errors.pathNotFound);
    }
  }

  void _cancel() {
    _hideSuggestions();
    setState(() => _editing = false);
    _controller.text = widget.store.currentPath.value;
  }

  void _handleControllerChanged() {
    if (!_editing) return;
    _queueSuggestions();
  }

  void _queueSuggestions() {
    final token = ++_suggestionToken;
    if (!_editing || !_focusNode.hasFocus) {
      _setSuggestions(const []);
      return;
    }
    unawaited(_loadSuggestions(token));
  }

  Future<void> _loadSuggestions(int token) async {
    final value = _controller.value;
    final suggestions = _isAllSelected(value)
        ? await _recentPathSuggestions()
        : await _folderPathSuggestions(value);
    if (!mounted || token != _suggestionToken) return;
    if (!_editing || !_focusNode.hasFocus) return;
    _setSuggestions(suggestions);
  }

  void _setSuggestions(List<_PathSuggestion> suggestions) {
    if (!mounted) return;
    setState(() {
      _suggestions = suggestions;
      if (suggestions.isEmpty) {
        _suggestionIndex = -1;
      } else if (_suggestionIndex < 0 ||
          _suggestionIndex >= suggestions.length) {
        _suggestionIndex = 0;
      }
    });
    if (suggestions.isEmpty) {
      _hideSuggestions();
    } else {
      _showSuggestions();
    }
  }

  bool _isAllSelected(TextEditingValue value) {
    final textLength = value.text.length;
    if (textLength == 0) return false;
    final selection = value.selection;
    if (!selection.isValid || selection.isCollapsed) return false;
    return selection.start == 0 && selection.end == textLength;
  }

  Future<List<_PathSuggestion>> _recentPathSuggestions() async {
    final settings = SettingsStore.instance;
    if (!settings.isLoaded) return const [];
    try {
      final paths = await settings.db.getRecentEnteredPaths();
      return [
        for (final path in paths)
          _PathSuggestion(
            path: path,
            label: path,
            icon: WaydirIconsRegular.clockClockwise,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<_PathSuggestion>> _folderPathSuggestions(
    TextEditingValue value,
  ) async {
    if (!value.selection.isCollapsed) return const [];
    final input = value.text.trim();
    if (input.isEmpty) return const [];
    final parts = _PathInputParts.from(input);
    if (parts == null) return const [];
    try {
      final entries = _samePath(parts.parent, widget.store.currentPath.value)
          ? widget.store.files.value
          : await FileSystemService.listDirectory(parts.parent);
      final prefix = parts.prefix.toLowerCase();
      final folders =
          entries
              .where((entry) => entry.type == FileItemType.folder)
              .where(
                (entry) => widget.store.showHidden.value || !entry.isHidden,
              )
              .where((entry) => entry.name.toLowerCase().startsWith(prefix))
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );
      final suggestions = <_PathSuggestion>[];
      for (final entry in folders) {
        final path = _samePath(parts.parent, widget.store.currentPath.value)
            ? entry.path
            : PlatformPaths.join(parts.parent, entry.name);
        if (_samePath(path, input)) continue;
        suggestions.add(
          _PathSuggestion(
            path: path,
            label: path,
            icon: WaydirIconsRegular.folder,
          ),
        );
        if (suggestions.length >= _maxSuggestions) break;
      }
      return suggestions;
    } catch (_) {
      return const [];
    }
  }

  bool _samePath(String a, String b) {
    if (PlatformPaths.isRemoteUri(a) || PlatformPaths.isRemoteUri(b)) {
      return a == b;
    }
    return PlatformPaths.normalize(a) == PlatformPaths.normalize(b);
  }

  void _showSuggestions() {
    if (_suggestionOverlay != null) {
      _suggestionOverlay!.markNeedsBuild();
      return;
    }
    _suggestionOverlay = OverlayEntry(
      builder: (_) => CompositedTransformFollower(
        link: _suggestionLayerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 2),
        child: Align(
          alignment: Alignment.topLeft,
          widthFactor: 1,
          heightFactor: 1,
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: _suggestionWidth,
              child: _PathSuggestionPopup(
                suggestions: _suggestions,
                highlightedIndex: _suggestionIndex,
                onPointerDown: _completeSuggestion,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_suggestionOverlay!);
  }

  void _hideSuggestions() {
    _suggestionToken++;
    _suggestions = const [];
    _suggestionIndex = -1;
    final overlay = _suggestionOverlay;
    _suggestionOverlay = null;
    overlay?.remove();
  }

  double get _suggestionWidth {
    final box = context.findRenderObject() as RenderBox?;
    return box?.size.width ?? 360;
  }

  KeyEventResult _handleEditorKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_suggestionOverlay != null) {
        _setSuggestions(const []);
      } else {
        _cancel();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_suggestions.isEmpty) return KeyEventResult.ignored;
      setState(() {
        _suggestionIndex = (_suggestionIndex + 1) % _suggestions.length;
      });
      _suggestionOverlay?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (_suggestions.isEmpty) return KeyEventResult.ignored;
      setState(() {
        _suggestionIndex =
            (_suggestionIndex - 1 + _suggestions.length) % _suggestions.length;
      });
      _suggestionOverlay?.markNeedsBuild();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      if (_suggestions.isEmpty || _suggestionIndex < 0) {
        return KeyEventResult.ignored;
      }
      _completeSuggestion(_suggestions[_suggestionIndex]);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      unawaited(_submit());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _completeSuggestion(_PathSuggestion suggestion) {
    _choosingSuggestion = true;
    _controller.value = TextEditingValue(
      text: suggestion.path,
      selection: TextSelection.collapsed(offset: suggestion.path.length),
    );
    _hideSuggestions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _queueSuggestions();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _choosingSuggestion = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final path = widget.store.currentPath.value;
        return GestureDetector(
          onTap: _editing ? null : _startEditing,
          child: CompositedTransformTarget(
            link: _suggestionLayerLink,
            child: Container(
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.bgInput,
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: _editing ? AppColors.accent : AppColors.borderColor,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: _editing ? 4 : 8),
              child: _editing ? _buildEditor() : _buildBreadcrumbs(path),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditor() {
    return Row(
      children: [
        Expanded(
          child: Focus(
            onKeyEvent: _handleEditorKey,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _submit(),
              onTapOutside: (_) {
                if (!_choosingSuggestion) _cancel();
              },
              style: context.txt.body,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 4,
                ),
                border: InputBorder.none,
              ),
              cursorColor: AppColors.accent,
              cursorHeight: 14,
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _cancel,
            child: Padding(
              padding: const EdgeInsets.only(left: 2, right: 2),
              child: Icon(
                WaydirIconsRegular.x,
                size: 14,
                color: AppColors.fgMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbs(String path) {
    return BreadcrumbBar(
      crumbs: crumbsFromPath(path),
      onNavigate: widget.store.navigateTo,
    );
  }
}

class _PathSuggestion {
  final String path;
  final String label;
  final IconData icon;

  const _PathSuggestion({
    required this.path,
    required this.label,
    required this.icon,
  });
}

class _PathInputParts {
  final String parent;
  final String prefix;

  const _PathInputParts({required this.parent, required this.prefix});

  static _PathInputParts? from(String input) {
    if (input.isEmpty) return null;
    if (_endsWithSeparator(input)) {
      final parent = _stripTrailingSeparators(input);
      if (parent.isEmpty) return const _PathInputParts(parent: '/', prefix: '');
      return _PathInputParts(parent: parent, prefix: '');
    }
    final parent = PlatformPaths.parentOf(input);
    if (parent.isEmpty || parent == '.') return null;
    return _PathInputParts(
      parent: parent,
      prefix: PlatformPaths.fileName(input),
    );
  }

  static bool _endsWithSeparator(String input) {
    if (input.endsWith('/')) return true;
    return PlatformPaths.isWindows && input.endsWith(r'\');
  }

  static String _stripTrailingSeparators(String input) {
    if (input == '/') return '/';
    if (PlatformPaths.isWindows && RegExp(r'^[A-Za-z]:\\?$').hasMatch(input)) {
      return input.endsWith(r'\') ? input : '$input\\';
    }
    if ((PlatformPaths.isSmbUri(input) || PlatformPaths.isSftpUri(input)) &&
        input.indexOf('/', input.indexOf('://') + 3) < 0) {
      return input.endsWith('/') ? input.substring(0, input.length - 1) : input;
    }
    var out = input;
    while (out.length > 1 && _endsWithSeparator(out)) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }
}

class _PathSuggestionPopup extends StatefulWidget {
  final List<_PathSuggestion> suggestions;
  final int highlightedIndex;
  final ValueChanged<_PathSuggestion> onPointerDown;

  static const double _rowHeight = 30;
  static const int _maxVisibleRows = 5;

  const _PathSuggestionPopup({
    required this.suggestions,
    required this.highlightedIndex,
    required this.onPointerDown,
  });

  @override
  State<_PathSuggestionPopup> createState() => _PathSuggestionPopupState();
}

class _PathSuggestionPopupState extends State<_PathSuggestionPopup> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _PathSuggestionPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedIndex != oldWidget.highlightedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToHighlighted());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHighlighted() {
    if (!_scrollController.hasClients) return;
    final index = widget.highlightedIndex;
    if (index < 0) return;
    final itemTop = index * _PathSuggestionPopup._rowHeight;
    final itemBottom = itemTop + _PathSuggestionPopup._rowHeight;
    final viewport = _scrollController.position.viewportDimension;
    final offset = _scrollController.offset;
    double? target;
    if (itemTop < offset) {
      target = itemTop;
    } else if (itemBottom > offset + viewport) {
      target = itemBottom - viewport;
    }
    if (target != null) {
      _scrollController.jumpTo(
        target.clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.suggestions;
    final highlightedIndex = widget.highlightedIndex;
    final onPointerDown = widget.onPointerDown;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSubtle.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  _PathSuggestionPopup._rowHeight *
                      _PathSuggestionPopup._maxVisibleRows +
                  8,
            ),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 4),
              shrinkWrap: true,
              primary: false,
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                final highlighted = index == highlightedIndex;
                final fg = highlighted ? AppColors.fg : AppColors.fgMuted;
                return Listener(
                  onPointerDown: (_) => onPointerDown(suggestion),
                  child: Container(
                    height: _PathSuggestionPopup._rowHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? AppColors.bgHoverStrong
                          : Colors.transparent,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      children: [
                        Icon(suggestion.icon, size: 14, color: fg),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            suggestion.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: context.txt.body.copyWith(color: fg),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.bgInput,
              border: Border(top: BorderSide(color: AppColors.bgDivider)),
            ),
            child: Row(
              children: [
                Text(
                  'Tab',
                  style: context.txt.keyCap.copyWith(color: AppColors.fg),
                ),
                const SizedBox(width: 5),
                Text(
                  t.search.complete,
                  style: context.txt.caption.copyWith(color: AppColors.fgMuted),
                ),
                const SizedBox(width: 14),
                Text(
                  'Enter',
                  style: context.txt.keyCap.copyWith(color: AppColors.fg),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    t.search.go,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: context.txt.caption.copyWith(
                      color: AppColors.fgMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewFolderButton extends StatefulWidget {
  final NavigationStore store;

  const _NewFolderButton({required this.store});

  @override
  State<_NewFolderButton> createState() => _NewFolderButtonState();
}

class _NewFolderButtonState extends State<_NewFolderButton> {
  bool _hovered = false;

  void _createFolder() {
    widget.store.startCreate();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: t.toolbar.newFolder,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _createFolder,
          child: Container(
            width: 30,
            height: 30,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              WaydirIconsRegular.folderPlus,
              size: 16,
              color: _hovered ? AppColors.fg : AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}
