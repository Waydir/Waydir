import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../core/models/file_entry.dart';
import '../../features/files/file_icons.dart';
import '../../features/navigation/navigation_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'code_editor.dart';
import 'image_preview.dart';
import 'info_panel.dart';
import 'quick_look_common.dart';
import 'quick_look_io.dart';

Future<void> showQuickLook({
  required BuildContext context,
  required NavigationStore store,
  FileEntry? explicitEntry,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: t.quickLook.title,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 110),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _QuickLook(store: store, explicitEntry: explicitEntry);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _QuickLook extends StatefulWidget {
  final NavigationStore store;
  final FileEntry? explicitEntry;

  const _QuickLook({required this.store, this.explicitEntry});

  @override
  State<_QuickLook> createState() => _QuickLookState();
}

class _QuickLookState extends State<_QuickLook> {
  final _focus = FocusNode();
  final _editorActive = ValueNotifier<bool>(false);
  bool _compact = true;
  bool _showInfo = true;
  String? _presentationKey;
  DateTime? _lastCursorRepeatAt;

  static const _cursorRepeatInterval = Duration(milliseconds: 70);

  @override
  void initState() {
    super.initState();
    final entry = widget.store.cursorEntry.value;
    _compact = _defaultCompact(entry);
    _presentationKey = entry?.realPath;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _editorActive.dispose();
    super.dispose();
  }

  bool _acceptCursorRepeat() {
    final now = DateTime.now();
    final last = _lastCursorRepeatAt;
    if (last != null && now.difference(last) < _cursorRepeatInterval) {
      return false;
    }
    _lastCursorRepeatAt = now;
    return true;
  }

  KeyEventResult _stepCursor(int delta, bool isRepeat) {
    if (isRepeat && !_acceptCursorRepeat()) return KeyEventResult.handled;
    if (!isRepeat) _lastCursorRepeatAt = null;
    widget.store.moveCursor(delta);
    return KeyEventResult.handled;
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final isRepeat = event is KeyRepeatEvent;
    if (event is! KeyDownEvent && !isRepeat) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (!isRepeat && key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    final isDown = key == LogicalKeyboardKey.arrowDown;
    final isUp = key == LogicalKeyboardKey.arrowUp;

    if (_editorActive.value) {
      final stepModifier = Platform.isMacOS
          ? HardwareKeyboard.instance.isAltPressed
          : HardwareKeyboard.instance.isControlPressed;
      if (stepModifier && (isDown || isUp)) {
        _focus.requestFocus();
        return _stepCursor(isDown ? 1 : -1, isRepeat);
      }
      return KeyEventResult.ignored;
    }

    if (!isRepeat && AppShortcuts.matches('quick_look', key)) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (isDown) return _stepCursor(1, isRepeat);
    if (isUp) return _stepCursor(-1, isRepeat);
    return KeyEventResult.ignored;
  }

  static bool _defaultCompact(FileEntry? entry) {
    if (entry == null || entry.type == FileItemType.folder) return true;
    return !imageExts.contains(entry.extension);
  }

  void _setCompact(bool value) {
    if (_compact == value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _compact == value) return;
      setState(() => _compact = value);
    });
  }

  void _syncPresentation(FileEntry? entry) {
    final key = entry?.realPath;
    if (_presentationKey == key) return;
    _presentationKey = key;
    _setCompact(_defaultCompact(entry));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = (size.width * 0.7).clamp(480.0, 1100.0);
    final height = (size.height * 0.78).clamp(360.0, 900.0);
    return Focus(
      onKeyEvent: _handleKey,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOut,
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              border: Border.all(color: AppColors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: SignalBuilder(
              builder: (_) {
                final override = widget.explicitEntry;
                if (override != null) {
                  return Column(
                    children: [
                      _Header(
                        entry: override,
                        compact: true,
                        showInfo: true,
                        onToggleInfo: () {},
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      Container(height: 1, color: AppColors.bgDivider),
                      Expanded(
                        child: override.type == FileItemType.folder
                            ? MultiProperties(entries: [override])
                            : PropertiesOnly(entry: override),
                      ),
                    ],
                  );
                }
                final selected = widget.store.selectedPaths.value;
                if (selected.length > 1) {
                  final entries = widget.store.selectedEntries;
                  return Column(
                    children: [
                      _Header(
                        entry: null,
                        compact: true,
                        showInfo: _showInfo,
                        multiCount: entries.length,
                        onToggleInfo: () {},
                        onClose: () => Navigator.of(context).pop(),
                      ),
                      Container(height: 1, color: AppColors.bgDivider),
                      Expanded(child: MultiProperties(entries: entries)),
                    ],
                  );
                }
                if (selected.length == 1) {
                  final entries = widget.store.selectedEntries;
                  if (entries.length == 1 &&
                      entries.first.type == FileItemType.folder) {
                    final entry = entries.first;
                    _syncPresentation(entry);
                    return Column(
                      children: [
                        _Header(
                          entry: entry,
                          compact: true,
                          showInfo: true,
                          onToggleInfo: () {},
                          onClose: () => Navigator.of(context).pop(),
                        ),
                        Container(height: 1, color: AppColors.bgDivider),
                        Expanded(child: MultiProperties(entries: entries)),
                      ],
                    );
                  }
                }
                final entry = widget.store.cursorEntry.value;
                _syncPresentation(entry);
                return Column(
                  children: [
                    _Header(
                      entry: entry,
                      compact: _compact,
                      showInfo: _showInfo,
                      onToggleInfo: () =>
                          setState(() => _showInfo = !_showInfo),
                      onClose: () => Navigator.of(context).pop(),
                    ),
                    Container(height: 1, color: AppColors.bgDivider),
                    Expanded(
                      child: _Body(
                        entry: entry,
                        editorActive: _editorActive,
                        showInfo: _showInfo,
                        onCompactChanged: _setCompact,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FileEntry? entry;
  final bool compact;
  final bool showInfo;
  final VoidCallback onToggleInfo;
  final VoidCallback onClose;
  final int? multiCount;

  const _Header({
    required this.entry,
    required this.compact,
    required this.showInfo,
    required this.onToggleInfo,
    required this.onClose,
    this.multiCount,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final multi = multiCount != null;
    final name = multi
        ? t.quickLook.items(count: multiCount!)
        : e?.name ?? t.quickLook.noSelection;
    final hasPreview = !multi && e != null && !compact;
    return Container(
      height: 46,
      color: AppColors.bgSidebar,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          if (multi)
            Icon(WaydirIconsRegular.copy, size: 18, color: AppColors.accent)
          else if (e == null)
            Icon(WaydirIconsRegular.file, size: 18, color: AppColors.fgMuted)
          else
            buildFileIcon(
              name: e.name,
              ext: e.extension,
              isFolder: e.type == FileItemType.folder,
              size: 18,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: context.txt.bodyEmphasis,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (hasPreview) ...[
            _HeaderButton(
              icon: WaydirIconsRegular.info,
              active: showInfo,
              tooltip: t.menu.properties,
              onTap: onToggleInfo,
            ),
            const SizedBox(width: 4),
          ],
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatefulWidget {
  final IconData icon;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final bg = active
        ? AppColors.accent.withValues(alpha: 0.16)
        : _hover
        ? AppColors.bgHover
        : Colors.transparent;
    final fg = active
        ? AppColors.accent
        : _hover
        ? AppColors.fg
        : AppColors.fgMuted;
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(widget.icon, size: 16, color: fg),
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
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _hover ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Icon(
            Icons.close,
            size: 16,
            color: _hover ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

Widget _split(Widget preview, FileEntry entry, {required bool showInfo}) {
  if (!showInfo) return preview;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: preview),
      Container(width: 1, color: AppColors.bgDivider),
      SizedBox(
        width: panelWidth,
        child: InfoPanel(entry: entry),
      ),
    ],
  );
}

class _Body extends StatelessWidget {
  final FileEntry? entry;
  final ValueNotifier<bool> editorActive;
  final bool showInfo;
  final ValueChanged<bool> onCompactChanged;

  const _Body({
    required this.entry,
    required this.editorActive,
    required this.showInfo,
    required this.onCompactChanged,
  });

  @override
  Widget build(BuildContext context) {
    final e = entry;
    void release() => WidgetsBinding.instance.addPostFrameCallback(
      (_) => editorActive.value = false,
    );

    if (e == null || e.type == FileItemType.folder) {
      release();
      onCompactChanged(true);
      return PropertiesOnly(entry: e);
    }
    if (imageExts.contains(e.extension)) {
      release();
      onCompactChanged(false);
      return _split(ImagePreview(path: e.realPath), e, showInfo: showInfo);
    }
    if (binaryExts.contains(e.extension)) {
      release();
      onCompactChanged(true);
      return PropertiesOnly(entry: e);
    }
    return _ProbeLoader(
      entry: e,
      editorActive: editorActive,
      showInfo: showInfo,
      onCompactChanged: onCompactChanged,
    );
  }
}

class _ProbeLoader extends StatelessWidget {
  final FileEntry entry;
  final ValueNotifier<bool> editorActive;
  final bool showInfo;
  final ValueChanged<bool> onCompactChanged;

  const _ProbeLoader({
    required this.entry,
    required this.editorActive,
    required this.showInfo,
    required this.onCompactChanged,
  });

  @override
  Widget build(BuildContext context) {
    void release() => WidgetsBinding.instance.addPostFrameCallback(
      (_) => editorActive.value = false,
    );
    return AsyncRetain<Probe>(
      cacheKey: entry.realPath,
      loader: () => probeFile(entry),
      loading: const QlCentered.spinner(),
      builder: (res) {
        switch (res.kind) {
          case QlKind.text:
            onCompactChanged(false);
            return _split(
              CodeEditor(
                key: ValueKey(entry.realPath),
                path: entry.realPath,
                extension: entry.extension,
                initial: res.text,
                editorActive: editorActive,
              ),
              entry,
              showInfo: showInfo,
            );
          case QlKind.binary:
          case QlKind.tooLarge:
            release();
            onCompactChanged(true);
            return PropertiesOnly(entry: entry);
          case QlKind.error:
            release();
            onCompactChanged(true);
            return PropertiesOnly(entry: entry);
        }
      },
    );
  }
}
