import 'package:flutter/material.dart';

import '../../ui/theme/app_theme.dart';

class ToolbarButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
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
  });

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
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
                  : AppColors.bgToolbar.withValues(alpha: 0),
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
