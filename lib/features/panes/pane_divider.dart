import 'package:flutter/material.dart';
import '../../ui/theme/app_theme.dart';
import 'shell_store.dart';

class PaneDivider extends StatefulWidget {
  final ShellStore shell;
  final double totalWidth;

  static const double hitWidth = 10;

  const PaneDivider({super.key, required this.shell, required this.totalWidth});

  @override
  State<PaneDivider> createState() => _PaneDividerState();
}

class _PaneDividerState extends State<PaneDivider> {
  bool _hovered = false;
  double _startX = 0;
  double _startRatio = 0.5;

  static const double _lineWidth = 1;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      hitTestBehavior: HitTestBehavior.opaque,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onPanStart: (details) {
          _startX = details.globalPosition.dx;
          _startRatio = widget.shell.splitRatio.value;
        },
        onPanUpdate: (details) {
          final dx = details.globalPosition.dx - _startX;
          widget.shell.setSplitRatio(_startRatio + dx / widget.totalWidth);
        },
        child: SizedBox(
          width: PaneDivider.hitWidth,
          child: Center(
            child: Container(
              width: _hovered ? 3 : _lineWidth,
              color: _hovered ? AppColors.accent : AppColors.bgDivider,
            ),
          ),
        ),
      ),
    );
  }
}
