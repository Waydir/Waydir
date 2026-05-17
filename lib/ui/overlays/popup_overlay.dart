import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showPopup({
  required BuildContext context,
  required Offset position,
  required WidgetBuilder builder,
  double width = 180,
  bool autoDismiss = true,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => PopupOverlay(
      position: position,
      width: width,
      autoDismiss: autoDismiss,
      onDismiss: () {
        if (entry.mounted) entry.remove();
      },
      builder: builder,
    ),
  );

  overlay.insert(entry);
}

class PopupOverlay extends StatefulWidget {
  final Offset position;
  final double width;
  final bool autoDismiss;
  final VoidCallback onDismiss;
  final WidgetBuilder builder;

  const PopupOverlay({
    super.key,
    required this.position,
    required this.width,
    required this.autoDismiss,
    required this.onDismiss,
    required this.builder,
  });

  @override
  State<PopupOverlay> createState() => _PopupOverlayState();
}

class _PopupOverlayState extends State<PopupOverlay>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    duration: const Duration(milliseconds: 120),
    vsync: this,
  );
  late final _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    if (widget.autoDismiss) {
      HardwareKeyboard.instance.addHandler(_onKey);
    }
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _dismiss();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    if (widget.autoDismiss) {
      HardwareKeyboard.instance.removeHandler(_onKey);
    }
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_controller.isAnimating) return;
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        return Stack(
          children: [
            if (widget.autoDismiss)
              Positioned.fill(
                child: MouseRegion(
                  child: GestureDetector(
                    onTap: _dismiss,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: _ClampedPositionDelegate(widget.position),
                child: FadeTransition(
                  opacity: _opacity,
                  child: Material(
                    type: MaterialType.transparency,
                    child: widget.builder(context),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ClampedPositionDelegate extends SingleChildLayoutDelegate {
  final Offset position;
  _ClampedPositionDelegate(this.position);

  static const double _margin = 4;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxX = (size.width - childSize.width - _margin).clamp(
      _margin,
      double.infinity,
    );
    final maxY = (size.height - childSize.height - _margin).clamp(
      _margin,
      double.infinity,
    );
    final dx = position.dx.clamp(_margin, maxX).toDouble();
    final dy = position.dy.clamp(_margin, maxY).toDouble();
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_ClampedPositionDelegate oldDelegate) =>
      oldDelegate.position != position;
}
