// Button widgets ported from bitsdojo_window 0.1.6 (MIT). See
// third_party/bitsdojo_window/LICENSE. Painter icons originally by
// https://github.com/esDotDev.

import 'dart:math';

import 'package:flutter/widgets.dart';

import 'window.dart';

class WindowButtonColors {
  WindowButtonColors({
    Color? normal,
    Color? mouseOver,
    Color? mouseDown,
    Color? iconNormal,
    Color? iconMouseOver,
    Color? iconMouseDown,
  }) : normal = normal ?? _defaults.normal,
       mouseOver = mouseOver ?? _defaults.mouseOver,
       mouseDown = mouseDown ?? _defaults.mouseDown,
       iconNormal = iconNormal ?? _defaults.iconNormal,
       iconMouseOver = iconMouseOver ?? _defaults.iconMouseOver,
       iconMouseDown = iconMouseDown ?? _defaults.iconMouseDown;

  final Color normal;
  final Color mouseOver;
  final Color mouseDown;
  final Color iconNormal;
  final Color iconMouseOver;
  final Color iconMouseDown;
}

final WindowButtonColors _defaults = WindowButtonColors(
  normal: const Color(0x00000000),
  mouseOver: const Color(0xFF404040),
  mouseDown: const Color(0xFF202020),
  iconNormal: const Color(0xFF805306),
  iconMouseOver: const Color(0xFFFFFFFF),
  iconMouseDown: const Color(0xFFF0F0F0),
);

final WindowButtonColors _closeDefaults = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: const Color(0xFF805306),
  iconMouseOver: const Color(0xFFFFFFFF),
);

typedef _IconBuilder = Widget Function(Color color);

class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.colors,
    required this.iconBuilder,
    required this.onPressed,
    this.animate = false,
  });

  final WindowButtonColors colors;
  final _IconBuilder iconBuilder;
  final VoidCallback onPressed;
  final bool animate;
  static const Size size = Size(46, 30);

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hover = false;
  bool _pressed = false;

  Color _bg() {
    if (_pressed) return widget.colors.mouseDown;
    if (_hover) return widget.colors.mouseOver;
    return widget.colors.normal;
  }

  Color _icon() {
    if (_pressed) return widget.colors.iconMouseDown;
    if (_hover) return widget.colors.iconMouseOver;
    return widget.colors.iconNormal;
  }

  @override
  Widget build(BuildContext context) {
    final fadeOutColor = widget.colors.mouseOver.withValues(alpha: 0);
    final duration = Duration(
      milliseconds: widget.animate ? (_hover ? 100 : 200) : 0,
    );
    return SizedBox(
      width: _WindowButton.size.width,
      height: _WindowButton.size.height,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _pressed = false;
        }),
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) {
            setState(() => _pressed = false);
            widget.onPressed();
          },
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOut,
            color: _hover || _pressed ? _bg() : fadeOutColor,
            child: Center(child: widget.iconBuilder(_icon())),
          ),
        ),
      ),
    );
  }
}

class MinimizeWindowButton extends StatelessWidget {
  const MinimizeWindowButton({
    super.key,
    this.colors,
    this.onPressed,
    this.animate = false,
  });

  final WindowButtonColors? colors;
  final VoidCallback? onPressed;
  final bool animate;

  @override
  Widget build(BuildContext context) => _WindowButton(
    colors: colors ?? _defaults,
    animate: animate,
    iconBuilder: (c) => _MinimizeIcon(color: c),
    onPressed: onPressed ?? appWindow.minimize,
  );
}

class MaximizeWindowButton extends StatelessWidget {
  const MaximizeWindowButton({
    super.key,
    this.colors,
    this.onPressed,
    this.animate = false,
  });

  final WindowButtonColors? colors;
  final VoidCallback? onPressed;
  final bool animate;

  @override
  Widget build(BuildContext context) => _WindowButton(
    colors: colors ?? _defaults,
    animate: animate,
    iconBuilder: (c) => _MaximizeIcon(color: c),
    onPressed: onPressed ?? appWindow.maximizeOrRestore,
  );
}

class CloseWindowButton extends StatelessWidget {
  const CloseWindowButton({
    super.key,
    this.colors,
    this.onPressed,
    this.animate = false,
  });

  final WindowButtonColors? colors;
  final VoidCallback? onPressed;
  final bool animate;

  @override
  Widget build(BuildContext context) => _WindowButton(
    colors: colors ?? _closeDefaults,
    animate: animate,
    iconBuilder: (c) => _CloseIcon(color: c),
    onPressed: onPressed ?? appWindow.close,
  );
}

class _CloseIcon extends StatelessWidget {
  const _CloseIcon({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: Stack(
      children: [
        Transform.rotate(
          angle: pi * .25,
          child: Center(child: Container(width: 14, height: 1, color: color)),
        ),
        Transform.rotate(
          angle: pi * -.25,
          child: Center(child: Container(width: 14, height: 1, color: color)),
        ),
      ],
    ),
  );
}

class _MaximizeIcon extends StatelessWidget {
  const _MaximizeIcon({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.center,
    child: CustomPaint(
      size: const Size(10, 10),
      painter: _MaximizePainter(color),
    ),
  );
}

class _MaximizePainter extends CustomPainter {
  _MaximizePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width - 1, size.height - 1), p);
  }

  @override
  bool shouldRepaint(covariant _MaximizePainter old) => old.color != color;
}

class _MinimizeIcon extends StatelessWidget {
  const _MinimizeIcon({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.center,
    child: CustomPaint(
      size: const Size(10, 10),
      painter: _MinimizePainter(color),
    ),
  );
}

class _MinimizePainter extends CustomPainter {
  _MinimizePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _MinimizePainter old) => old.color != color;
}
