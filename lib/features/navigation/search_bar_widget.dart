import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
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
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.bgToolbar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
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
          SignalBuilder(
            builder: (context) {
              final searching = widget.store.isSearching.value;
              if (!searching) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.fgMuted,
                  ),
                ),
              );
            },
          ),
          _ModeToggle(store: widget.store),
          _RecursiveToggle(store: widget.store),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _StatusText(store: widget.store),
          ),
          _CloseButton(onTap: widget.store.closeSearch),
        ],
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final NavigationStore store;
  const _StatusText({required this.store});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(builder: (context) => _buildText(context));
  }

  Widget _buildText(BuildContext context) {
    final err = store.searchPatternError.value;
    if (err != null) {
      return Text(
        err,
        style: context.txt.bodyMuted.copyWith(color: AppColors.danger),
      );
    }
    final recursive = store.searchRecursive.value;
    final searching = store.isSearching.value;
    final query = store.searchQuery.value.trim();
    final count = store.visibleFiles.value.length;

    String text;
    if (!recursive) {
      text = t.search.results(count: count);
    } else if (query.isEmpty) {
      text = t.search.placeholder;
    } else if (searching && count == 0 && store.searchScannedDirs.value == 0) {
      text = t.search.starting;
    } else if (searching) {
      text =
          '${t.search.found(count: count)} · ${t.search.scanning(dirs: store.searchScannedDirs.value)}';
    } else if (count == 0) {
      text = t.search.noMatches;
    } else {
      text =
          '${t.search.found(count: count)} · ${t.search.scanning(dirs: store.searchScannedDirs.value)}';
    }
    return Text(text, style: context.txt.bodyMuted);
  }
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

class _ModeToggle extends StatelessWidget {
  final NavigationStore store;

  const _ModeToggle({required this.store});

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final current = SettingsStore.instance.searchMode.value;
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
  final VoidCallback onTap;

  const _ModeSegment({
    required this.mode,
    required this.label,
    required this.tooltip,
    required this.active,
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
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 24,
            constraints: const BoxConstraints(minWidth: 26),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            color: active
                ? AppColors.accent.withValues(alpha: 0.15)
                : (_hovered ? AppColors.bgHover : Colors.transparent),
            child: Text(
              widget.label,
              style: context.txt.row.copyWith(
                color: active ? AppColors.accent : AppColors.fgMuted,
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
