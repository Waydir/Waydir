import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'filter_query.dart';
import 'navigation_store.dart';

class AppSearchBar extends StatefulWidget {
  final NavigationStore store;

  const AppSearchBar({super.key, required this.store});

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late _SearchQueryController _controller;
  late FocusNode _focusNode;
  late FocusNode _wrapperFocusNode;
  final _suggestionLayerLink = LayerLink();
  final _suggestionTargetKey = GlobalKey();
  OverlayEntry? _suggestionOverlay;
  void Function()? _disposeFocusEffect;
  void Function()? _disposeModeEffect;
  int _suggestionIndex = 0;
  bool _suggestionsDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = _SearchQueryController(text: widget.store.searchQuery.value);
    _controller.highlightFilters =
        SettingsStore.instance.searchMode.value == filterSearchMode;
    _controller.addListener(_onInputChanged);
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (SettingsStore.instance.searchMode.value == filterSearchMode) {
            final suggestions = _currentSuggestions();
            if (event.logicalKey == LogicalKeyboardKey.escape &&
                _suggestionOverlay != null) {
              _dismissSuggestions();

              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
                suggestions.isNotEmpty) {
              setState(() {
                _suggestionIndex = (_suggestionIndex + 1) % suggestions.length;
              });
              _suggestionOverlay?.markNeedsBuild();

              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
                suggestions.isNotEmpty) {
              setState(() {
                _suggestionIndex =
                    (_suggestionIndex - 1 + suggestions.length) %
                    suggestions.length;
              });
              _suggestionOverlay?.markNeedsBuild();

              return KeyEventResult.handled;
            }
            if ((event.logicalKey == LogicalKeyboardKey.tab ||
                    event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
                _acceptHighlightedSuggestion(suggestions)) {
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            widget.store.cycleSearchMode();

            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
    );
    _focusNode.addListener(_onInputChanged);
    _wrapperFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _initFocusEffect();
    _disposeModeEffect = effect(() {
      SettingsStore.instance.searchMode.value;
      _controller.highlightFilters =
          SettingsStore.instance.searchMode.value == filterSearchMode;
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      _disposeFocusEffect?.call();
      _initFocusEffect();
    }
  }

  void _initFocusEffect() {
    _disposeFocusEffect = effect(() {
      widget.store.searchFocusRequest.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode.requestFocus();
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      });
    });
  }

  @override
  void dispose() {
    _hideSuggestions();
    _disposeFocusEffect?.call();
    _disposeModeEffect?.call();
    _controller.removeListener(_onInputChanged);
    _focusNode.removeListener(_onInputChanged);
    _controller.dispose();
    _focusNode.dispose();
    _wrapperFocusNode.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    _suggestionIndex = 0;
    _suggestionsDismissed = false;
    if (!mounted) return;
    setState(() {});
    _syncSuggestionsOverlay();
  }

  List<FilterSuggestion> _currentSuggestions() {
    if (SettingsStore.instance.searchMode.value != filterSearchMode) {
      return const [];
    }
    if (!_focusNode.hasFocus) return const [];

    return filterSuggestions(
      _controller.text,
      _controller.selection.baseOffset,
    );
  }

  bool _acceptHighlightedSuggestion(List<FilterSuggestion> suggestions) {
    if (suggestions.isEmpty) return false;
    final index = _boundedSuggestionIndex(suggestions.length);
    _applySuggestion(suggestions[index]);

    return true;
  }

  int _boundedSuggestionIndex(int count) {
    if (count <= 0) return -1;
    if (_suggestionIndex < 0) return 0;
    if (_suggestionIndex >= count) return count - 1;

    return _suggestionIndex;
  }

  void _applySuggestion(FilterSuggestion suggestion) {
    _suggestionsDismissed = false;
    final next = applyFilterSuggestion(
      _controller.text,
      _controller.selection.baseOffset,
      suggestion,
    );
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    widget.store.setSearchQuery(next);
    _focusNode.requestFocus();
    _syncSuggestionsOverlay();
  }

  void _syncSuggestionsOverlay() {
    if (_suggestionsDismissed) {
      _hideSuggestions();

      return;
    }
    final suggestions = _currentSuggestions();
    if (suggestions.isEmpty) {
      _hideSuggestions();

      return;
    }
    _showSuggestions();
  }

  void _showSuggestions() {
    if (_suggestionOverlay != null) {
      _suggestionOverlay!.markNeedsBuild();

      return;
    }
    _suggestionOverlay = OverlayEntry(
      builder: (_) {
        final suggestions = _currentSuggestions();
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return CompositedTransformFollower(
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
                child: _FilterSuggestions(
                  suggestions: suggestions,
                  highlightedIndex: _boundedSuggestionIndex(suggestions.length),
                  onSelected: _applySuggestion,
                ),
              ),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_suggestionOverlay!);
  }

  void _hideSuggestions() {
    final overlay = _suggestionOverlay;
    _suggestionOverlay = null;
    overlay?.remove();
  }

  void _dismissSuggestions() {
    _suggestionsDismissed = true;
    _hideSuggestions();
  }

  double get _suggestionWidth {
    final targetBox =
        _suggestionTargetKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final targetWidth = targetBox?.size.width ?? 360;
    final maxWidth = (overlayBox?.size.width ?? targetWidth) - 16;

    return targetWidth.clamp(280, maxWidth < 280 ? 280 : maxWidth).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncSuggestionsOverlay();
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgToolbar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(
                    WaydirIconsRegular.magnifyingGlass,
                    size: 16,
                    color: AppColors.fgMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CompositedTransformTarget(
                      key: _suggestionTargetKey,
                      link: _suggestionLayerLink,
                      child: KeyboardListener(
                        focusNode: _wrapperFocusNode,
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.escape) {
                            if (_suggestionOverlay != null) {
                              _dismissSuggestions();
                            } else {
                              widget.store.closeSearch();
                            }
                          }
                        },
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onChanged: (v) => widget.store.setSearchQuery(v),
                          onSubmitted: (_) {
                            widget.store.openSelected();
                          },
                          style: context.txt.body,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            border: InputBorder.none,
                            hintText:
                                SettingsStore.instance.searchMode.value ==
                                    filterSearchMode
                                ? t.search.filterPlaceholder
                                : t.search.placeholder,
                            hintStyle: context.txt.body.copyWith(
                              color: AppColors.fgSubtle,
                            ),
                          ),
                          cursorColor: AppColors.accent,
                          cursorHeight: 14,
                        ),
                      ),
                    ),
                  ),
                  _ModeToggle(store: widget.store),
                  _ContentToggle(store: widget.store),
                  _RecursiveToggle(store: widget.store),
                  const SizedBox(width: 6),
                  _CloseButton(onTap: widget.store.closeSearch),
                ],
              ),
            ),
          ),
          _StatusLine(store: widget.store),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final NavigationStore store;
  const _StatusLine({required this.store});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final child = _statusText(context, store);
        if (child == null) return const SizedBox.shrink();
        final searching = store.isSearching.value;

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: searching
                    ? Center(
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.fgMuted,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Flexible(child: child),
            ],
          ),
        );
      },
    );
  }
}

Widget? _statusText(BuildContext context, NavigationStore store) {
  final err = store.searchPatternError.value;
  if (err != null) {
    return Text(
      err,
      style: context.txt.bodyMuted.copyWith(color: AppColors.danger),
    );
  }
  final walks = store.searchRecursive.value || store.searchContent.value;
  final searching = store.isSearching.value;
  final query = store.searchQuery.value.trim();
  final count = store.visibleFiles.value.length;

  String text;
  if (!walks) {
    text = t.search.results(count: count);
  } else if (query.isEmpty) {
    return null;
  } else if (searching && count == 0 && store.searchScannedDirs.value == 0) {
    text = t.search.starting;
  } else if (searching || count > 0) {
    text =
        '${t.search.found(count: count)} · ${t.search.scanning(dirs: store.searchScannedDirs.value)}';
  } else {
    text = t.search.noMatches;
  }

  return Text(text, style: context.txt.bodyMuted);
}

class _RecursiveToggle extends StatefulWidget {
  final NavigationStore store;

  const _RecursiveToggle({required this.store});

  @override
  State<_RecursiveToggle> createState() => _RecursiveToggleState();
}

class _RecursiveToggleState extends State<_RecursiveToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final active = widget.store.searchRecursive.value;

        return Tooltip(
          message: t.search.subfoldersShortcut,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              onTap: widget.store.toggleRecursive,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : (_hovered ? AppColors.bgHover : Colors.transparent),
                  borderRadius: BorderRadius.zero,
                  border: active
                      ? Border.all(
                          color: AppColors.accent.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      WaydirIconsRegular.treeStructure,
                      size: 14,
                      color: active ? AppColors.accent : AppColors.fgMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      t.search.subfolders,
                      style: context.txt.row.copyWith(
                        color: active ? AppColors.accent : AppColors.fgMuted,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
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
}

class _ContentToggle extends StatefulWidget {
  final NavigationStore store;

  const _ContentToggle({required this.store});

  @override
  State<_ContentToggle> createState() => _ContentToggleState();
}

class _ContentToggleState extends State<_ContentToggle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final active = widget.store.searchContent.value;
        final enabled =
            !PlatformPaths.isSftpUri(widget.store.currentPath.value) &&
            SettingsStore.instance.searchMode.value != filterSearchMode;
        final fg = !enabled
            ? AppColors.fgSubtle
            : (active ? AppColors.accent : AppColors.fgMuted);

        return Tooltip(
          message: enabled
              ? t.search.contentSearch
              : t.search.contentSftpUnsupported,
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
            onExit: enabled ? (_) => setState(() => _hovered = false) : null,
            child: GestureDetector(
              onTap: enabled ? widget.store.toggleContent : null,
              child: Container(
                height: 24,
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: active && enabled
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : (_hovered && enabled
                            ? AppColors.bgHover
                            : Colors.transparent),
                  borderRadius: BorderRadius.zero,
                  border: active && enabled
                      ? Border.all(
                          color: AppColors.accent.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(WaydirIconsRegular.fileTxt, size: 14, color: fg),
                    const SizedBox(width: 4),
                    Text(
                      t.search.content,
                      style: context.txt.row.copyWith(
                        color: fg,
                        fontWeight: active && enabled
                            ? FontWeight.w600
                            : FontWeight.normal,
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
}

class _ModeToggle extends StatelessWidget {
  final NavigationStore store;

  const _ModeToggle({required this.store});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final current = SettingsStore.instance.searchMode.value;
        final content = store.searchContent.value;

        return Container(
          height: 24,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.bgDivider),
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModeSegment(
                mode: 'substring',
                label: 'Aa',
                tooltip: t.search.modeSubstring,
                active: current == 'substring',
                onTap: () => store.setSearchMode('substring'),
              ),
              Container(width: 1, height: 24, color: AppColors.bgDivider),
              _ModeSegment(
                mode: 'glob',
                label: '*',
                tooltip: t.search.modeGlob,
                active: current == 'glob',
                enabled: !content,
                onTap: () => store.setSearchMode('glob'),
              ),
              Container(width: 1, height: 24, color: AppColors.bgDivider),
              _ModeSegment(
                mode: 'regex',
                label: '.*',
                tooltip: t.search.modeRegex,
                active: current == 'regex',
                onTap: () => store.setSearchMode('regex'),
              ),
              Container(width: 1, height: 24, color: AppColors.bgDivider),
              _ModeSegment(
                mode: filterSearchMode,
                label: 'F',
                tooltip: t.search.modeFilter,
                active: current == filterSearchMode,
                onTap: () => store.setSearchMode(filterSearchMode),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterSuggestions extends StatelessWidget {
  final List<FilterSuggestion> suggestions;
  final int highlightedIndex;
  final ValueChanged<FilterSuggestion> onSelected;

  static const double _rowHeight = 28;

  const _FilterSuggestions({
    required this.suggestions,
    required this.highlightedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _FilterSuggestionPopup(
      suggestions: suggestions,
      highlightedIndex: highlightedIndex,
      onSelected: onSelected,
    );
  }
}

class _FilterSuggestionPopup extends StatefulWidget {
  final List<FilterSuggestion> suggestions;
  final int highlightedIndex;
  final ValueChanged<FilterSuggestion> onSelected;

  const _FilterSuggestionPopup({
    required this.suggestions,
    required this.highlightedIndex,
    required this.onSelected,
  });

  @override
  State<_FilterSuggestionPopup> createState() => _FilterSuggestionPopupState();
}

class _FilterSuggestionPopupState extends State<_FilterSuggestionPopup> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _FilterSuggestionPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedIndex != oldWidget.highlightedIndex) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToHighlighted(),
      );
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
    final itemTop = index * _FilterSuggestions._rowHeight;
    final itemBottom = itemTop + _FilterSuggestions._rowHeight;
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

    return Container(
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(maxHeight: 184),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          top: BorderSide(color: AppColors.bgDivider),
          bottom: BorderSide(color: AppColors.bgDivider),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              primary: false,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];

                return _FilterSuggestionRow(
                  suggestion: suggestion,
                  highlighted: index == widget.highlightedIndex,
                  onPointerDown: () => widget.onSelected(suggestion),
                );
              },
            ),
          ),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 30),
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
                    t.search.complete,
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

class _FilterSuggestionRow extends StatefulWidget {
  final FilterSuggestion suggestion;
  final bool highlighted;
  final VoidCallback onPointerDown;

  const _FilterSuggestionRow({
    required this.suggestion,
    required this.highlighted,
    required this.onPointerDown,
  });

  @override
  State<_FilterSuggestionRow> createState() => _FilterSuggestionRowState();
}

class _FilterSuggestionRowState extends State<_FilterSuggestionRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.highlighted || _hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => widget.onPointerDown(),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 30),
          color: active ? AppColors.bgHoverStrong : Colors.transparent,
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  widget.suggestion.label,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.code.copyWith(
                    color: active ? AppColors.fg : AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.suggestion.detail,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.row.copyWith(
                    color: active ? AppColors.fg : AppColors.fgMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSegment extends StatefulWidget {
  final String mode;
  final String label;
  final String tooltip;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _ModeSegment({
    required this.mode,
    required this.label,
    required this.tooltip,
    required this.active,
    this.enabled = true,
    required this.onTap,
  });

  @override
  State<_ModeSegment> createState() => _ModeSegmentState();
}

class _ModeSegmentState extends State<_ModeSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final enabled = widget.enabled;
    final color = !enabled
        ? AppColors.fgSubtle
        : (active ? AppColors.accent : AppColors.fgMuted);

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        child: GestureDetector(
          onTap: enabled ? widget.onTap : null,
          child: Container(
            height: 24,
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            color: active && enabled
                ? AppColors.accent.withValues(alpha: 0.15)
                : (_hovered && enabled
                      ? AppColors.bgHover
                      : Colors.transparent),
            child: Text(
              widget.label,
              style: context.txt.row.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: t.search.close,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              WaydirIconsRegular.x,
              size: 14,
              color: AppColors.fgMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchQueryController extends TextEditingController {
  bool highlightFilters = false;

  _SearchQueryController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? context.txt.body;
    if (!highlightFilters || text.isEmpty) {
      return TextSpan(text: text, style: base);
    }
    final children = <InlineSpan>[];
    final matches = RegExp(r'(\S+)').allMatches(text).toList();
    var offset = 0;
    for (final match in matches) {
      if (match.start > offset) {
        children.add(TextSpan(text: text.substring(offset, match.start)));
      }
      final token = match.group(0)!;
      final colon = token.indexOf(':');
      if (colon > 0) {
        final key = token.substring(0, colon + 1);
        final value = token.substring(colon + 1);
        final known = filterQueryKeys.contains(
          token.substring(0, colon).toLowerCase(),
        );
        children.add(
          TextSpan(
            text: key,
            style: base.copyWith(
              color: known ? AppColors.accent : AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        if (value.isNotEmpty) {
          children.add(
            TextSpan(
              text: value,
              style: base.copyWith(color: AppColors.fg),
            ),
          );
        }
      } else {
        children.add(TextSpan(text: token, style: base));
      }
      offset = match.end;
    }
    if (offset < text.length) {
      children.add(TextSpan(text: text.substring(offset)));
    }

    return TextSpan(style: base, children: children);
  }
}
