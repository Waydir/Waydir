import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_modal.dart';

Future<void> showHelpDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const _HelpDialog(),
  );
}

class _HelpPage {
  final String Function() title;
  final String Function() body;
  final String? assetPath;
  final IconData icon;

  const _HelpPage({
    required this.title,
    required this.body,
    required this.icon,
    this.assetPath,
  });
}

final _pages = [
  _HelpPage(
    title: () => t.help.pages.navigation.title,
    body: () => t.help.pages.navigation.body,
    assetPath: 'docs/gifs/navigating.gif',
    icon: WaydirIconsRegular.compass,
  ),
  _HelpPage(
    title: () => t.help.pages.tabs.title,
    body: () => t.help.pages.tabs.body,
    assetPath: 'docs/gifs/tabs.gif',
    icon: WaydirIconsRegular.tabs,
  ),
  _HelpPage(
    title: () => t.help.pages.dualPane.title,
    body: () => t.help.pages.dualPane.body,
    assetPath: 'docs/gifs/dual_pane_copy.gif',
    icon: WaydirIconsRegular.columns,
  ),
  _HelpPage(
    title: () => t.help.pages.selection.title,
    body: () => t.help.pages.selection.body,
    assetPath: 'docs/gifs/selection.gif',
    icon: WaydirIconsRegular.selectionAll,
  ),
  _HelpPage(
    title: () => t.help.pages.fileOps.title,
    body: () => t.help.pages.fileOps.body,
    assetPath: 'docs/gifs/file_operations.gif',
    icon: WaydirIconsRegular.copy,
  ),
  _HelpPage(
    title: () => t.help.pages.quickLook.title,
    body: () => t.help.pages.quickLook.body,
    assetPath: 'docs/gifs/quick_look_images.gif',
    icon: WaydirIconsRegular.image,
  ),
  _HelpPage(
    title: () => t.help.pages.search.title,
    body: () => t.help.pages.search.body,
    assetPath: 'docs/gifs/search.gif',
    icon: WaydirIconsRegular.magnifyingGlass,
  ),
  _HelpPage(
    title: () => t.help.pages.multiRename.title,
    body: () => t.help.pages.multiRename.body,
    assetPath: 'docs/gifs/multi_rename.gif',
    icon: WaydirIconsRegular.textAa,
  ),
  _HelpPage(
    title: () => t.help.pages.archives.title,
    body: () => t.help.pages.archives.body,
    assetPath: 'docs/gifs/archive_browsing.gif',
    icon: WaydirIconsRegular.archive,
  ),
  _HelpPage(
    title: () => t.help.pages.remote.title,
    body: () => t.help.pages.remote.body,
    assetPath: 'docs/gifs/sftp.gif',
    icon: WaydirIconsRegular.hardDrive,
  ),
  _HelpPage(
    title: () => t.help.pages.terminal.title,
    body: () => t.help.pages.terminal.body,
    assetPath: 'docs/gifs/terminal.gif',
    icon: WaydirIconsRegular.terminal,
  ),
];

class _HelpDialog extends StatefulWidget {
  const _HelpDialog();

  @override
  State<_HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<_HelpDialog> {
  int _selectedIndex = 0;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();

      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _select((_selectedIndex + 1) % _pages.length);

      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _select((_selectedIndex - 1 + _pages.length) % _pages.length);

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _select(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width.clamp(720.0, 980.0).toDouble();
    final height = (size.height * 0.86).clamp(500.0, 760.0).toDouble();
    final page = _pages[_selectedIndex];

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: AppModal(
        icon: WaydirIconsRegular.info,
        title: t.help.title,
        width: width,
        height: height,
        onClose: () => Navigator.of(context).pop(),
        child: Row(
          children: [
            SizedBox(
              width: 220,
              child: _HelpTabs(
                selectedIndex: _selectedIndex,
                onSelect: _select,
              ),
            ),
            Container(width: 1, color: AppColors.bgDivider),
            Expanded(child: _HelpPageView(page: page)),
          ],
        ),
      ),
    );
  }
}

class _HelpTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _HelpTabs({required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSidebar,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _pages.length,
        itemBuilder: (context, index) {
          return _HelpTab(
            page: _pages[index],
            selected: selectedIndex == index,
            onTap: () => onSelect(index),
          );
        },
      ),
    );
  }
}

class _HelpTab extends StatefulWidget {
  final _HelpPage page;
  final bool selected;
  final VoidCallback onTap;

  const _HelpTab({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_HelpTab> createState() => _HelpTabState();
}

class _HelpTabState extends State<_HelpTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected
        ? AppColors.fgAccent
        : _hovered
        ? AppColors.fg
        : AppColors.fgMuted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.bgSelected
                : _hovered
                ? AppColors.bgHover
                : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.selected ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(widget.page.icon, size: 15, color: color),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  widget.page.title(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.txt.rowEmphasis.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpPageView extends StatelessWidget {
  final _HelpPage page;

  const _HelpPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(page.title(), style: context.txt.pageTitle),
          const SizedBox(height: 8),
          _HelpMarkdown(data: page.body()),
          const SizedBox(height: 16),
          Container(
            height: 480,
            decoration: BoxDecoration(
              color: AppColors.bg,
              border: Border.all(color: AppColors.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: page.assetPath == null
                  ? _HelpDemoPlaceholder(icon: page.icon)
                  : Image.asset(
                      page.assetPath!,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) =>
                          _HelpDemoPlaceholder(icon: page.icon),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpDemoPlaceholder extends StatelessWidget {
  final IconData icon;

  const _HelpDemoPlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: AppColors.fgMuted),
        const SizedBox(height: 12),
        Text(t.help.demoComingSoon, style: context.txt.bodyMuted),
      ],
    );
  }
}

class _HelpMarkdown extends StatelessWidget {
  final String data;

  const _HelpMarkdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final base = context.txt.bodyMuted.copyWith(height: 1.45);
    final emphasis = context.txt.bodyEmphasis.copyWith(height: 1.45);
    final mono = context.txt.keyCap.copyWith(
      color: AppColors.fg,
      backgroundColor: AppColors.bgInput,
    );

    return MarkdownBody(
      data: data,
      selectable: false,
      styleSheet: MarkdownStyleSheet(
        p: base,
        listBullet: base,
        strong: emphasis,
        em: base.copyWith(fontStyle: FontStyle.italic),
        code: mono,
        blockSpacing: 8,
      ),
    );
  }
}
