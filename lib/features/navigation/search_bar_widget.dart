import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'navigation_store.dart';

class AppSearchBar extends StatefulWidget {
  final NavigationStore store;

  const AppSearchBar({super.key, required this.store});

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late FocusNode _wrapperFocusNode;
  void Function()? _disposeFocusEffect;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.store.searchQuery.value);
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.tab) {
          widget.store.cycleSearchMode();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
    _wrapperFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    _initFocusEffect();
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
    _disposeFocusEffect?.call();
    _controller.dispose();
    _focusNode.dispose();
    _wrapperFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    child: KeyboardListener(
                      focusNode: _wrapperFocusNode,
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.escape) {
                          widget.store.closeSearch();
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
                          hintText: t.search.placeholder,
                          hintStyle: context.txt.body.copyWith(
                            color: AppColors.fgSubtle,
                          ),
                        ),
                        cursorColor: AppColors.accent,
                        cursorHeight: 14,
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
        final enabled = !PlatformPaths.isSftpUri(
          widget.store.currentPath.value,
        );
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
            ],
          ),
        );
      },
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
