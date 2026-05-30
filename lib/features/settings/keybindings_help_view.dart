import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_modal.dart';

Future<void> showKeybindingsHelp(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const _KeybindingsHelpDialog(),
  );
}

final _groupMeta = <ShortcutGroup, ({String Function() title, IconData icon})>{
  ShortcutGroup.navigation: (
    title: () => t.keybindings.categories.navigation,
    icon: WaydirIconsRegular.compass,
  ),
  ShortcutGroup.tabs: (
    title: () => t.keybindings.categories.tabs,
    icon: WaydirIconsRegular.tabs,
  ),
  ShortcutGroup.panes: (
    title: () => t.keybindings.categories.panes,
    icon: WaydirIconsRegular.columns,
  ),
  ShortcutGroup.fileOps: (
    title: () => t.keybindings.categories.fileOps,
    icon: WaydirIconsRegular.copy,
  ),
  ShortcutGroup.selection: (
    title: () => t.keybindings.categories.selection,
    icon: WaydirIconsRegular.checkSquare,
  ),
  ShortcutGroup.search: (
    title: () => t.keybindings.categories.search,
    icon: WaydirIconsRegular.magnifyingGlass,
  ),
};

final _groupOrder = ShortcutGroup.values;

String _labelFor(ShortcutDef s) => switch (s.id) {
  'open_item' => t.keybindings.openItem,
  'go_up' => t.keybindings.goUp,
  'go_back' => t.keybindings.goBack,
  'go_forward' => t.keybindings.goForward,
  'refresh' => t.keybindings.refresh,
  'quick_look' => t.keybindings.quickLook,
  'cursor_up' => t.keybindings.cursorUp,
  'cursor_down' => t.keybindings.cursorDown,
  'new_tab' => t.keybindings.newTab,
  'close_tab' => t.keybindings.closeTab,
  'next_tab' => t.keybindings.nextTab,
  'prev_tab' => t.keybindings.prevTab,
  'switch_tab' => t.keybindings.switchTab,
  'toggle_dual' => t.keybindings.toggleDual,
  'switch_pane' => t.keybindings.switchPane,
  'focus_terminal' => t.keybindings.focusTerminal,
  'toggle_terminal' => t.keybindings.toggleTerminal,
  'new_terminal_tab' => t.keybindings.newTerminalTab,
  'close_terminal_tab' => t.keybindings.closeTerminalTab,
  'terminal_font_increase' => t.keybindings.terminalFontIncrease,
  'terminal_font_decrease' => t.keybindings.terminalFontDecrease,
  'terminal_font_reset' => t.keybindings.terminalFontReset,
  'toggle_sidebar' => t.keybindings.toggleSidebar,
  'copy' => t.keybindings.copy,
  'cut' => t.keybindings.cut,
  'paste' => t.keybindings.paste,
  'delete' => t.keybindings.delete,
  'rename' => t.keybindings.rename,
  'new_folder' => t.keybindings.newFolder,
  'dual_copy' => t.keybindings.dualCopy,
  'dual_move' => t.keybindings.dualMove,
  'select_all' => t.keybindings.selectAll,
  'select_pattern' => t.keybindings.selectPattern,
  'deselect_all' => t.keybindings.deselectAll,
  'toggle_select' => t.keybindings.toggleSelect,
  'save_selection' => t.keybindings.saveSelection,
  'load_selection' => t.keybindings.loadSelection,
  'search' => t.keybindings.search,
  'recursive_search' => t.keybindings.recursiveSearch,
  'toggle_hidden' => t.menu.showHidden,
  'preferences' => t.keybindings.preferences,
  'help' => t.help.menuLabel,
  'close_search' => t.keybindings.closeSearch,
  _ => s.id,
};

class _KeybindingsHelpDialog extends StatefulWidget {
  const _KeybindingsHelpDialog();

  @override
  State<_KeybindingsHelpDialog> createState() => _KeybindingsHelpDialogState();
}

class _KeybindingsHelpDialogState extends State<_KeybindingsHelpDialog> {
  String _query = '';
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  List<(ShortcutGroup, List<ShortcutDef>)> _filtered() {
    final q = _query.trim().toLowerCase();
    final result = <ShortcutGroup, List<ShortcutDef>>{};
    for (final s in AppShortcuts.all) {
      final label = _labelFor(s).toLowerCase();
      final keys = s.displayKeys.toLowerCase();
      final groupTitle = _groupMeta[s.group]!.title().toLowerCase();
      if (q.isEmpty ||
          label.contains(q) ||
          keys.contains(q) ||
          groupTitle.contains(q)) {
        result.putIfAbsent(s.group, () => []).add(s);
      }
    }
    return [
      for (final g in _groupOrder)
        if (result.containsKey(g)) (g, result[g]!),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width.clamp(360.0, 560.0).toDouble();
    final height = (size.height * 0.9).clamp(360.0, 720.0).toDouble();
    final groups = _filtered();

    return AppModal(
      icon: WaydirIconsRegular.keyboard,
      title: t.keybindings.title,
      width: width,
      height: height,
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        children: [
          _SearchBar(
            controller: _searchCtl,
            onChanged: (v) => setState(() => _query = v),
          ),
          Container(height: 1, color: AppColors.bgDivider),
          Expanded(
            child: groups.isEmpty
                ? const _EmptyState()
                : _ShortcutList(groups: groups),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: AppColors.bgSurface,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.bgInput,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Icon(
              WaydirIconsRegular.magnifyingGlass,
              size: 13,
              color: AppColors.fgSubtle,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                onChanged: onChanged,
                style: context.txt.row,
                cursorColor: AppColors.fg,
                cursorWidth: 1,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: t.search.placeholder,
                  hintStyle: context.txt.row.copyWith(
                    color: AppColors.fgSubtle,
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              _ClearButton(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ClearButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ClearButton({required this.onTap});
  @override
  State<_ClearButton> createState() => _ClearButtonState();
}

class _ClearButtonState extends State<_ClearButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Icon(
          WaydirIconsRegular.x,
          size: 12,
          color: _hovered ? AppColors.fg : AppColors.fgSubtle,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            WaydirIconsRegular.magnifyingGlass,
            size: 28,
            color: AppColors.fgSubtle,
          ),
          const SizedBox(height: 10),
          Text(t.search.noMatches, style: context.txt.muted),
        ],
      ),
    );
  }
}

class _ShortcutList extends StatelessWidget {
  final List<(ShortcutGroup, List<ShortcutDef>)> groups;
  const _ShortcutList({required this.groups});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (int g = 0; g < groups.length; g++) {
      final (group, entries) = groups[g];
      final meta = _groupMeta[group]!;
      items.add(
        _GroupHeader(title: meta.title, icon: meta.icon, isFirst: g == 0),
      );
      for (final entry in entries) {
        items.add(_ShortcutRow(def: entry));
      }
    }
    return ListView(padding: EdgeInsets.zero, children: items);
  }
}

class _GroupHeader extends StatelessWidget {
  final String Function() title;
  final IconData icon;
  final bool isFirst;
  const _GroupHeader({
    required this.title,
    required this.icon,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 14 : 22, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.fgMuted),
          const SizedBox(width: 7),
          Text(title().toUpperCase(), style: context.txt.sectionLabel),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: AppColors.bgDivider)),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatefulWidget {
  final ShortcutDef def;
  const _ShortcutRow({required this.def});

  @override
  State<_ShortcutRow> createState() => _ShortcutRowState();
}

class _ShortcutRowState extends State<_ShortcutRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: _hovered ? AppColors.bgHover : Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _labelFor(widget.def),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.txt.row,
                    ),
                  ),
                  if (widget.def.hint != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.def.hint!() ?? '',
                      style: context.txt.caption.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _KeyBadge(
              primary: widget.def.displayKeys,
              alternate: widget.def.displayAltKeys,
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  final String primary;
  final String? alternate;
  const _KeyBadge({required this.primary, this.alternate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._renderCombo(context, primary),
        if (alternate != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(t.keybindings.or, style: context.txt.micro),
          ),
          ..._renderCombo(context, alternate!),
        ],
      ],
    );
  }

  List<Widget> _renderCombo(BuildContext context, String combo) {
    final parts = combo.split(RegExp(r'\s*\+\s*'));
    final widgets = <Widget>[];
    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text('+', style: context.txt.caption.copyWith(height: 1.2)),
          ),
        );
      }
      widgets.add(_KeyCap(text: parts[i]));
    }
    return widgets;
  }
}

class _KeyCap extends StatelessWidget {
  final String text;
  const _KeyCap({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSubtle,
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(text, textAlign: TextAlign.center, style: context.txt.keyCap),
    );
  }
}
