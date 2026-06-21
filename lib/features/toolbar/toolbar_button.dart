import 'package:flutter/material.dart';

import '../../core/keyboard/keyboard_shortcuts.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';

class ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final String? shortcutId;
  final bool enabled;
  final bool active;
  final VoidCallback onTap;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.active,
    required this.onTap,
    this.shortcutId,
  });

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
  bool _hovered = false;

  String? get _shortcutDisplay => widget.shortcutId == null
      ? null
      : AppShortcuts.tryGetById(widget.shortcutId!)?.displayKeys;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      richMessage: _buildMessage(context),
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
                  : AppColors.bgToolbar.withValues(alpha: 0),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(widget.icon, size: 16, color: _iconColor),
          ),
        ),
      ),
    );
  }

  InlineSpan _buildMessage(BuildContext context) {
    final shortcut = _shortcutDisplay;
    if (shortcut == null) {
      return TextSpan(text: widget.tooltip);
    }

    return TextSpan(
      children: [
        TextSpan(text: widget.tooltip),
        const WidgetSpan(child: SizedBox(width: 10)),
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _TooltipKeyCap(label: shortcut),
        ),
      ],
    );
  }

  Color get _iconColor {
    if (!widget.enabled) return AppColors.fgSubtle;
    if (widget.active) return AppColors.warning;

    return _hovered ? AppColors.fg : AppColors.fgMuted;
  }
}

class _TooltipKeyCap extends StatelessWidget {
  final String label;

  const _TooltipKeyCap({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(label, style: context.txt.keyCap),
    );
  }
}
