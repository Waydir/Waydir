import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import 'bookmark_store.dart';
import 'breadcrumbs/breadcrumb_bar.dart';
import 'breadcrumbs/crumb.dart';
import 'navigation_store.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../i18n/strings.g.dart';
import '../../ui/overlays/toast.dart';

class PaneLocationBar extends StatelessWidget {
  final NavigationStore store;

  const PaneLocationBar({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.bgToolbar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
      child: Row(
        children: [
          Watch(
            (context) => _ToolBtn(
              WaydirIconsRegular.arrowLeft,
              store.goBack,
              store.canGoBack.value,
              t.toolbar.back,
            ),
          ),
          Watch(
            (context) => _ToolBtn(
              WaydirIconsRegular.arrowRight,
              store.goForward,
              store.canGoForward.value,
              t.toolbar.forward,
            ),
          ),
          _ToolBtn(WaydirIconsRegular.arrowUp, store.goUp, true, t.toolbar.up),
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
          Watch((context) {
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
          }),
          Watch(
            (context) => _ToolBtn(
              WaydirIconsRegular.magnifyingGlass,
              () => store.searchActive.value
                  ? store.closeSearch()
                  : store.openSearch(),
              true,
              t.toolbar.search,
            ),
          ),
          _NewFolderButton(store: store),
          const SizedBox(width: 4),
        ],
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
  final _editorKeyFocusNode = FocusNode();
  void Function()? _disposePathListener;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.store.currentPath.value);
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
    _disposePathListener?.call();
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _editorKeyFocusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _controller.text = widget.store.currentPath.value;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus && _editing) {
      _cancel();
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
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
    setState(() => _editing = false);
    _controller.text = widget.store.currentPath.value;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final path = widget.store.currentPath.value;
      return GestureDetector(
        onTap: _editing ? null : _startEditing,
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
      );
    });
  }

  Widget _buildEditor() {
    return Row(
      children: [
        Expanded(
          child: KeyboardListener(
            focusNode: _editorKeyFocusNode,
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _cancel();
              }
            },
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _submit(),
              onTapOutside: (_) => _cancel(),
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
