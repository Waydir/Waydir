import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../theme/app_theme.dart';

class AppCloseButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const AppCloseButton({super.key, required this.onTap, this.size = 26});

  @override
  State<AppCloseButton> createState() => _AppCloseButtonState();
}

class _AppCloseButtonState extends State<AppCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.zero,
          ),
          child: Icon(
            WaydirIconsRegular.x,
            size: 14,
            color: _hovered ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}
