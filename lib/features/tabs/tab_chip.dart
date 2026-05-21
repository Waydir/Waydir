import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'tab_state.dart';
import 'tabs_store.dart';

class TabChip extends StatefulWidget {
  final TabState tab;
  final int index;
  final TabsStore tabsStore;

  const TabChip({
    super.key,
    required this.tab,
    required this.index,
    required this.tabsStore,
  });

  @override
  State<TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<TabChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isActive = widget.tabsStore.activeIndex.value == widget.index;
      final title = widget.tab.title.value;
      final fullPath = widget.tab.store.currentPath.value;
      final canClose = widget.tabsStore.tabs.value.length > 1;

      Color bg;
      Color fg;
      if (isActive) {
        bg = AppColors.bgHover;
        fg = AppColors.fg;
      } else if (_hovered) {
        bg = AppColors.bg;
        fg = AppColors.fg;
      } else {
        bg = Colors.transparent;
        fg = AppColors.fgMuted;
      }

      final border = Border(
        right: BorderSide(
          color: (_hovered && !isActive)
              ? Colors.transparent
              : AppColors.bgDivider,
          width: 1,
        ),
      );

      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => widget.tabsStore.selectTab(widget.index),
          onTertiaryTapDown: canClose
              ? (_) => widget.tabsStore.closeTab(widget.tab.id)
              : null,
          child: Tooltip(
            message: fullPath,
            child: Container(
              height: 30,
              constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
              decoration: BoxDecoration(color: bg, border: border),
              padding: const EdgeInsets.only(left: 10, right: 4),
              child: Row(
                children: [
                  Icon(
                    WaydirIconsRegular.folder,
                    size: 14,
                    color: isActive ? AppColors.accent : fg,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                      style: context.txt.row.copyWith(
                        color: fg,
                        fontWeight: isActive
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: (canClose && (_hovered || isActive))
                        ? _CloseButton(
                            onTap: () =>
                                widget.tabsStore.closeTab(widget.tab.id),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgDivider : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Icon(
            WaydirIconsRegular.x,
            size: 11,
            color: _hovered ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}
