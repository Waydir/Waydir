import 'package:flutter/widgets.dart';

import 'window.dart';

class MoveWindow extends StatelessWidget {
  const MoveWindow({super.key, this.child, this.onDoubleTap});

  final Widget? child;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => appWindow.startDragging(),
      onDoubleTap: onDoubleTap ?? appWindow.maximizeOrRestore,
      child: child ?? const SizedBox.expand(),
    );
  }
}
