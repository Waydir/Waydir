import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../overlays/popup_overlay.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? trailing;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.trailing,
  });
}

class AppDropdown<T> extends StatefulWidget {
  final T value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final double? menuWidth;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.menuWidth,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final _key = GlobalKey();
  bool _hovered = false;
  bool _open = false;

  void _openMenu() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);
    final width = widget.menuWidth ?? box.size.width;
    final pos = Offset(origin.dx, origin.dy + box.size.height + 4);

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    void dismiss() {
      if (entry.mounted) entry.remove();
      if (mounted) setState(() => _open = false);
    }

    entry = OverlayEntry(
      builder: (_) => PopupOverlay(
        position: pos,
        width: width,
        autoDismiss: true,
        onDismiss: dismiss,
        builder: (_) => _AppDropdownMenu<T>(
          width: width,
          items: widget.items,
          selected: widget.value,
          onSelect: (v) {
            widget.onChanged(v);
            dismiss();
          },
        ),
      ),
    );

    setState(() => _open = true);
    overlay.insert(entry);
  }

  AppDropdownItem<T>? _selectedItem() {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: _key,
        onTap: _openMenu,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.bgInput,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (_hovered || _open)
                  ? AppColors.accent.withValues(alpha: 0.6)
                  : AppColors.borderColor,
            ),
          ),
          child: Row(
            children: [
              if (selected?.icon != null) ...[
                Icon(selected!.icon!, size: 13, color: AppColors.fgMuted),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  selected?.label ?? '',
                  style: context.txt.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                WaydirIconsRegular.caretDown,
                size: 12,
                color: AppColors.fgMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppDropdownMenu<T> extends StatelessWidget {
  final double width;
  final List<AppDropdownItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelect;

  const _AppDropdownMenu({
    required this.width,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                _MenuTile<T>(
                  item: item,
                  isSelected: item.value == selected,
                  onTap: () => onSelect(item.value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile<T> extends StatefulWidget {
  final AppDropdownItem<T> item;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MenuTile<T>> createState() => _MenuTileState<T>();
}

class _MenuTileState<T> extends State<_MenuTile<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fg = (_hovered || widget.isSelected)
        ? AppColors.fg
        : AppColors.fgMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 30,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.bgHoverStrong
                : (widget.isSelected
                      ? AppColors.bgSelectedMuted
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (widget.item.icon != null) ...[
                Icon(widget.item.icon!, size: 13, color: fg),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  widget.item.label,
                  style: context.txt.body.copyWith(
                    color: fg,
                    fontWeight: widget.isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.item.trailing != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.item.trailing!,
                  style: context.txt.captionSmall.copyWith(
                    color: AppColors.fgSubtle,
                  ),
                ),
              ],
              if (widget.isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  WaydirIconsRegular.check,
                  size: 12,
                  color: AppColors.accent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
