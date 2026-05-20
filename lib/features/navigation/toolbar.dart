import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import 'navigation_store.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';
import '../../i18n/strings.g.dart';
import '../../ui/overlays/context_menu.dart';

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

  const _ToolBtn(this.icon, this.onTap, this.enabled, this.tooltip);

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
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.enabled
                  ? (_hovered ? AppColors.fg : AppColors.fgMuted)
                  : AppColors.fgSubtle,
            ),
          ),
        ),
      ),
    );
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

  void _submit() {
    final text = _controller.text.trim();
    setState(() => _editing = false);
    if (text.isNotEmpty && text != widget.store.currentPath.value) {
      widget.store.navigateTo(text);
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
            borderRadius: BorderRadius.circular(4),
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
    if (isTrashPath(path)) {
      final subs = path == kTrashPath
          ? const <String>[]
          : path.substring(kTrashPath.length + 1).split('/');
      final atRoot = subs.isEmpty;
      return Row(
        children: [
          MouseRegion(
            cursor: atRoot
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: atRoot ? null : () => widget.store.navigateTo(kTrashPath),
              child: Row(
                children: [
                  Icon(
                    WaydirIconsRegular.trashSimple,
                    size: 13,
                    color: AppColors.fgAccent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t.sidebar.trash,
                    style: atRoot ? context.txt.bodyEmphasis : context.txt.body,
                  ),
                ],
              ),
            ),
          ),
          for (int i = 0; i < subs.length; i++)
            ..._segmentRow(
              ['', kTrashPath, ...subs],
              i + 2,
              isWindows: false,
              isLast: i == subs.length - 1,
              flexibleLast: i == subs.length - 1,
              partialOverride:
                  '$kTrashPath/${subs.sublist(0, i + 1).join('/')}',
            ),
        ],
      );
    }
    final segments = PlatformPaths.segments(path);
    final isWindows = PlatformPaths.isWindows;

    return LayoutBuilder(
      builder: (context, constraints) {
        final txt = context.txt;
        final regular = txt.body;
        final bold = txt.bodyEmphasis;
        const segPadding = 6.0;
        const caretWidth = 16.0;
        const ellipsisWidth = 14.0 + segPadding;

        double measure(String text, TextStyle style) {
          final tp = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          return tp.width;
        }

        double segW(String s, {bool last = false}) =>
            measure(s, last ? bold : regular) + segPadding;

        final maxW = constraints.maxWidth;

        final rootLabel = isWindows ? '${segments.first}\\' : '/';
        final rootW = segW(rootLabel);

        final widths = <double>[];
        double total = rootW;
        final offset = isWindows ? 1 : 0;
        for (int i = offset; i < segments.length; i++) {
          final w =
              caretWidth + segW(segments[i], last: i == segments.length - 1);
          widths.add(w);
          total += w;
        }

        if (total <= maxW) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BreadcrumbSegment(
                label: rootLabel,
                onTap: () => widget.store.navigateTo(
                  isWindows ? PlatformPaths.rootPath : '/',
                ),
              ),
              for (int i = 0; i < segments.length - offset; i++)
                ..._segmentRow(
                  segments,
                  i + offset,
                  isWindows: isWindows,
                  isLast: i + offset == segments.length - 1,
                  flexibleLast: false,
                ),
            ],
          );
        }

        final reserved = rootW + caretWidth + ellipsisWidth;
        double remaining = maxW - reserved;
        final shown = <int>[];
        for (int i = segments.length - 1; i >= offset; i--) {
          final idx = i - offset;
          if (shown.isEmpty || widths[idx] <= remaining) {
            shown.insert(0, idx);
            remaining -= widths[idx];
            if (remaining <= 0 && shown.isNotEmpty) break;
          } else {
            break;
          }
        }
        final hidden = List.generate(shown.first, (i) => i);

        return Row(
          children: [
            _BreadcrumbSegment(
              label: rootLabel,
              onTap: () => widget.store.navigateTo(
                isWindows ? PlatformPaths.rootPath : '/',
              ),
            ),
            _caretIcon(),
            _EllipsisMenu(
              hiddenIndices: hidden,
              allSegments: segments,
              isWindows: isWindows,
              offset: offset,
              store: widget.store,
            ),
            for (int k = 0; k < shown.length; k++)
              ...() {
                final i = shown[k] + offset;
                final isLast = i == segments.length - 1;
                return _segmentRow(
                  segments,
                  i,
                  isWindows: isWindows,
                  isLast: isLast,
                  flexibleLast: isLast,
                );
              }(),
          ],
        );
      },
    );
  }

  List<Widget> _segmentRow(
    List<String> segments,
    int i, {
    required bool isWindows,
    required bool isLast,
    required bool flexibleLast,
    String? partialOverride,
  }) {
    final partial =
        partialOverride ?? PlatformPaths.buildPartialPath(segments, i);
    final segment = _BreadcrumbSegment(
      label: segments[i],
      onTap: isLast ? null : () => widget.store.navigateTo(partial),
      isLast: isLast,
      ellipsisOverflow: flexibleLast,
    );
    return [_caretIcon(), flexibleLast ? Flexible(child: segment) : segment];
  }

  Widget _caretIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Icon(
        WaydirIconsRegular.caretRight,
        size: 14,
        color: AppColors.fgSubtle,
      ),
    );
  }
}

class _EllipsisMenu extends StatefulWidget {
  final List<int> hiddenIndices;
  final List<String> allSegments;
  final bool isWindows;
  final int offset;
  final NavigationStore store;

  const _EllipsisMenu({
    required this.hiddenIndices,
    required this.allSegments,
    required this.isWindows,
    required this.offset,
    required this.store,
  });

  @override
  State<_EllipsisMenu> createState() => _EllipsisMenuState();
}

class _EllipsisMenuState extends State<_EllipsisMenu> {
  bool _hovered = false;

  void _openMenu() {
    final box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(
      Offset(0, box.size.height + 2),
      ancestor: overlay,
    );

    showContextMenu(
      context: context,
      position: offset,
      items: widget.hiddenIndices
          .map(
            (i) => ContextMenuItem(
              icon: WaydirIconsRegular.folder,
              label: widget.allSegments[i + widget.offset],
              action: '$i',
            ),
          )
          .toList(),
      onSelect: (action) {
        final i = int.parse(action) + widget.offset;
        final partial = PlatformPaths.buildPartialPath(widget.allSegments, i);
        widget.store.navigateTo(partial);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _openMenu,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: _hovered
              ? BoxDecoration(
                  color: AppColors.bgHover,
                  borderRadius: BorderRadius.circular(3),
                )
              : null,
          child: Tooltip(
            message: widget.hiddenIndices
                .map((i) => widget.allSegments[i + widget.offset])
                .join(' › '),
            child: Text(
              '…',
              style: context.txt.body.copyWith(
                color: _hovered ? AppColors.fg : AppColors.fgMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BreadcrumbSegment extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLast;
  final bool ellipsisOverflow;

  const _BreadcrumbSegment({
    required this.label,
    this.onTap,
    this.isLast = false,
    this.ellipsisOverflow = false,
  });

  @override
  State<_BreadcrumbSegment> createState() => _BreadcrumbSegmentState();
}

class _BreadcrumbSegmentState extends State<_BreadcrumbSegment> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final clickable = widget.onTap != null;
    final text = Text(
      widget.label,
      maxLines: 1,
      softWrap: false,
      overflow: widget.ellipsisOverflow
          ? TextOverflow.ellipsis
          : TextOverflow.clip,
      style: context.txt.body.copyWith(
        color: widget.isLast
            ? AppColors.fg
            : (clickable ? AppColors.fgMuted : AppColors.fg),
        fontWeight: widget.isLast ? FontWeight.w500 : FontWeight.normal,
      ),
    );
    return MouseRegion(
      onEnter: clickable ? (_) => setState(() => _hovered = true) : null,
      onExit: clickable ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          decoration: _hovered
              ? BoxDecoration(
                  color: AppColors.bgHover,
                  borderRadius: BorderRadius.circular(3),
                )
              : null,
          child: text,
        ),
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
              borderRadius: BorderRadius.circular(4),
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
