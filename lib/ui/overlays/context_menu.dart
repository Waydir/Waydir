import 'dart:async';

import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_icon.dart';
import 'popup_overlay.dart';

class ContextMenuItem {
  final IconData icon;
  final String label;
  final String action;
  final bool danger;
  final bool isToggle;
  final ReadonlySignal<bool>? toggleSignal;
  final String? shortcut;
  final bool enabled;

  /// When non-null this item opens a cascading submenu instead of firing an
  /// action on tap.
  final List<ContextMenuItem>? children;

  /// Optional path to a real icon file (PNG/SVG) shown instead of [icon].
  final String? iconPath;

  /// Optional widget shown instead of [icon]; used for tag colour dots.
  final Widget? leading;

  const ContextMenuItem({
    required this.icon,
    required this.label,
    required this.action,
    this.danger = false,
    this.isToggle = false,
    this.toggleSignal,
    this.shortcut,
    this.enabled = true,
    this.children,
    this.iconPath,
    this.leading,
  });

  static const divider = ContextMenuItem._divider();

  const ContextMenuItem._divider()
    : icon = const IconData(0),
      label = '',
      action = '__divider__',
      danger = false,
      isToggle = false,
      toggleSignal = null,
      shortcut = null,
      enabled = true,
      children = null,
      iconPath = null,
      leading = null;

  bool get isDivider => action == '__divider__';
  bool get hasChildren => children != null && children!.isNotEmpty;
}

void showContextMenu({
  required BuildContext context,
  required Offset position,
  required List<ContextMenuItem> items,
  required void Function(String action) onSelect,
}) {
  final overlay = Overlay.of(context);
  final entries = <OverlayEntry>[];
  Timer? pendingDismiss;

  void dismissAll() {
    pendingDismiss?.cancel();
    pendingDismiss = null;
    for (final e in entries) {
      if (e.mounted) e.remove();
    }
    entries.clear();
  }

  void dismissFrom(int depth) {
    while (entries.length > depth) {
      final e = entries.removeLast();
      if (e.mounted) e.remove();
    }
  }

  void dismissFromSoon(int depth) {
    pendingDismiss?.cancel();
    pendingDismiss = Timer(const Duration(milliseconds: 90), () {
      pendingDismiss = null;
      dismissFrom(depth);
    });
  }

  void cancelPendingDismiss() {
    pendingDismiss?.cancel();
    pendingDismiss = null;
  }

  void dismissFromNow(int depth) {
    cancelPendingDismiss();
    dismissFrom(depth);
  }

  void openMenu(int depth, Offset pos, List<ContextMenuItem> menuItems) {
    dismissFromNow(depth);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => PopupOverlay(
        position: pos,
        width: 180,
        // Only the root menu carries the dismiss barrier; it sits below the
        // submenus so an outside click closes the whole cascade.
        autoDismiss: depth == 0,
        onDismiss: dismissAll,
        builder: (_) => _ContextMenuBody(
          items: menuItems,
          onEnterMenu: depth == 0 ? () {} : cancelPendingDismiss,
          onExitMenu: () => dismissFromSoon(depth == 0 ? 1 : depth),
          onCloseSubmenus: () => dismissFromNow(depth + 1),
          onScheduleCloseSubmenus: () => dismissFromSoon(depth + 1),
          onSelect: (action) {
            final item = menuItems.firstWhere(
              (i) => !i.isDivider && i.action == action,
              orElse: () => menuItems.first,
            );
            if (item.hasChildren) return;
            onSelect(action);
            if (!item.isToggle) dismissAll();
          },
          onOpenSubmenu: (item, rect) => openMenu(
            depth + 1,
            Offset(rect.right - 4, rect.top),
            item.children!,
          ),
        ),
      ),
    );
    entries.add(entry);
    overlay.insert(entry);
  }

  openMenu(0, position, items);
}

class _ContextMenuBody extends StatelessWidget {
  final List<ContextMenuItem> items;
  final VoidCallback onEnterMenu;
  final VoidCallback onExitMenu;
  final VoidCallback onCloseSubmenus;
  final VoidCallback onScheduleCloseSubmenus;
  final void Function(String action) onSelect;
  final void Function(ContextMenuItem item, Rect tileRect) onOpenSubmenu;

  const _ContextMenuBody({
    required this.items,
    required this.onEnterMenu,
    required this.onExitMenu,
    required this.onCloseSubmenus,
    required this.onScheduleCloseSubmenus,
    required this.onSelect,
    required this.onOpenSubmenu,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onEnterMenu(),
      onExit: (_) => onExitMenu(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 180, maxWidth: 360),
        child: IntrinsicWidth(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items.asMap().entries.map((e) {
                  if (e.value.isDivider) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.bgDivider,
                      ),
                    );
                  }

                  return _ContextMenuItemTile(
                    item: e.value,
                    onTap: () => onSelect(e.value.action),
                    onOpenSubmenu: onOpenSubmenu,
                    onCloseSubmenus: onCloseSubmenus,
                    onScheduleCloseSubmenus: onScheduleCloseSubmenus,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContextMenuItemTile extends StatefulWidget {
  final ContextMenuItem item;
  final VoidCallback onTap;
  final VoidCallback onCloseSubmenus;
  final VoidCallback onScheduleCloseSubmenus;
  final void Function(ContextMenuItem item, Rect tileRect) onOpenSubmenu;

  const _ContextMenuItemTile({
    required this.item,
    required this.onTap,
    required this.onCloseSubmenus,
    required this.onScheduleCloseSubmenus,
    required this.onOpenSubmenu,
  });

  @override
  State<_ContextMenuItemTile> createState() => _ContextMenuItemTileState();
}

class _ContextMenuItemTileState extends State<_ContextMenuItemTile> {
  bool _hovered = false;

  void _openSubmenu() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);
    widget.onOpenSubmenu(widget.item, origin & box.size);
  }

  void _handleTap() {
    if (!widget.item.enabled) return;
    if (widget.item.hasChildren) {
      _openSubmenu();
    } else {
      widget.onTap();
    }
  }

  void _handleEnter() {
    setState(() => _hovered = true);
    if (!widget.item.enabled) {
      widget.onCloseSubmenus();

      return;
    }
    if (widget.item.hasChildren) {
      _openSubmenu();
    } else {
      widget.onCloseSubmenus();
    }
  }

  void _handleExit() {
    setState(() => _hovered = false);
    if (widget.item.hasChildren) {
      widget.onScheduleCloseSubmenus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dangerColor = AppColors.danger;
    final hoverBg = item.danger
        ? dangerColor.withValues(alpha: 0.12)
        : AppColors.bgHoverStrong;
    final fg = !item.enabled
        ? AppColors.fgMuted.withValues(alpha: 0.45)
        : _hovered
        ? (item.danger ? dangerColor : AppColors.fg)
        : AppColors.fgMuted;

    return MouseRegion(
      cursor: item.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => _handleEnter(),
      onExit: (_) => _handleExit(),
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _hovered && item.enabled ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            children: [
              if (item.leading != null)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Center(child: item.leading),
                )
              else if (item.iconPath != null)
                AppIcon(path: item.iconPath, size: 16)
              else
                Icon(item.icon, size: 14, color: fg),
              const SizedBox(width: 8),
              Text(
                item.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.txt.body.copyWith(color: fg),
              ),
              const Spacer(),
              if (item.shortcut != null) ...[
                const SizedBox(width: 16),
                Text(
                  item.shortcut!,
                  maxLines: 1,
                  softWrap: false,
                  style: context.txt.captionSmall.copyWith(
                    color: fg.withValues(alpha: 0.5),
                  ),
                ),
              ],
              if (item.toggleSignal != null) ...[
                const SizedBox(width: 8),
                SignalBuilder(
                  builder: (_) => _Checkbox(value: item.toggleSignal!.value),
                ),
              ],
              if (item.hasChildren) ...[
                const SizedBox(width: 8),
                Icon(WaydirIconsRegular.caretRight, size: 12, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool value;

  const _Checkbox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: value ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: value ? AppColors.accent : AppColors.borderColor,
          width: 1,
        ),
      ),
      child: value
          ? Icon(WaydirIconsRegular.check, size: 10, color: Colors.white)
          : null,
    );
  }
}
