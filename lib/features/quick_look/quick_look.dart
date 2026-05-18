import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';

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
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Quick Look',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 110),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _QuickLook(store: store);
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

  const _QuickLook({required this.store});

  @override
  State<_QuickLook> createState() => _QuickLookState();
}

class _QuickLookState extends State<_QuickLook> {
  final _focus = FocusNode();
  final _editorActive = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
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

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (_editorActive.value) return KeyEventResult.ignored;
    if (key == LogicalKeyboardKey.space) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.store.moveCursor(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      widget.store.moveCursor(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Focus(
      onKeyEvent: _handleKey,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: (size.width * 0.78).clamp(480.0, 1280.0),
            height: (size.height * 0.82).clamp(360.0, 980.0),
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
            child: Watch((_) {
              final entry = widget.store.cursorEntry.value;
              return Column(
                children: [
                  _Header(
                    entry: entry,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                  Container(height: 1, color: AppColors.bgDivider),
                  Expanded(
                    child: _Body(entry: entry, editorActive: _editorActive),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FileEntry? entry;
  final VoidCallback onClose;

  const _Header({required this.entry, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final name = e?.name ?? t.quickLook.noSelection;
    return Container(
      height: 46,
      color: AppColors.bgSidebar,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          PhosphorIcon(
            e == null
                ? PhosphorIconsRegular.file
                : e.type == FileItemType.folder
                ? PhosphorIconsRegular.folder
                : fileIcon(e.extension),
            size: 18,
            color: e == null
                ? AppColors.fgMuted
                : e.type == FileItemType.folder
                ? AppColors.accent
                : fileIconColor(e.extension),
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
          _CloseButton(onTap: onClose),
        ],
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
            borderRadius: BorderRadius.circular(6),
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

Widget _split(Widget preview, FileEntry entry) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: preview),
      Container(width: 1, color: AppColors.bgDivider),
      SizedBox(width: panelWidth, child: InfoPanel(entry: entry)),
    ],
  );
}

class _Body extends StatelessWidget {
  final FileEntry? entry;
  final ValueNotifier<bool> editorActive;

  const _Body({required this.entry, required this.editorActive});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    void release() => WidgetsBinding.instance.addPostFrameCallback(
      (_) => editorActive.value = false,
    );

    if (e == null || e.type == FileItemType.folder) {
      release();
      return PropertiesOnly(entry: e);
    }
    if (imageExts.contains(e.extension)) {
      release();
      return _split(ImagePreview(path: e.realPath), e);
    }
    return _TextLoader(entry: e, editorActive: editorActive);
  }
}

class _TextLoader extends StatelessWidget {
  final FileEntry entry;
  final ValueNotifier<bool> editorActive;

  const _TextLoader({required this.entry, required this.editorActive});

  @override
  Widget build(BuildContext context) {
    return AsyncRetain<TextResult>(
      cacheKey: entry.realPath,
      loader: () => readText(entry),
      loading: const QlCentered.spinner(),
      builder: (res) {
        if (res.error != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => editorActive.value = false,
          );
          return PropertiesOnly(entry: entry, note: res.error);
        }
        return _split(
          CodeEditor(
            key: ValueKey(entry.realPath),
            path: entry.realPath,
            extension: entry.extension,
            initial: res.text,
            editorActive: editorActive,
          ),
          entry,
        );
      },
    );
  }
}
