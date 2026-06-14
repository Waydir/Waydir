import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../ui/theme/app_theme.dart';

typedef RubberBandSelectCallback =
    void Function(Set<String> paths, {bool additive});
typedef RubberBandStartPredicate = bool Function(Offset localPosition);

class RubberBandLayer extends StatefulWidget {
  final ScrollController scrollController;
  final int itemCount;
  final double itemExtent;
  final double rowHeight;
  final double topPadding;
  final String Function(int index) pathAt;
  final int Function(Offset localPosition) rowAt;
  final RubberBandStartPredicate? canStartSelectionAt;
  final RubberBandSelectCallback? onSelectionChanged;
  final VoidCallback? onBackgroundTap;
  final Widget child;

  const RubberBandLayer({
    super.key,
    required this.scrollController,
    required this.itemCount,
    required this.itemExtent,
    required this.rowHeight,
    this.topPadding = 0,
    required this.pathAt,
    required this.rowAt,
    this.canStartSelectionAt,
    required this.onSelectionChanged,
    this.onBackgroundTap,
    required this.child,
  });

  @override
  State<RubberBandLayer> createState() => _RubberBandLayerState();
}

class _RubberBandLayerState extends State<RubberBandLayer> {
  static const _kThreshold = 4.0;
  static const _kAutoScrollZone = 30.0;
  static const _kAutoScrollSpeed = 8.0;
  static const _kAutoScrollIntervalMs = 16;

  Offset? _startContent;
  Offset? _currentContent;
  double _currentLocalY = 0;
  bool _active = false;
  Timer? _autoScrollTimer;
  Set<String> _lastPaths = const {};

  Rect get _contentRect {
    if (_startContent == null || _currentContent == null) return Rect.zero;

    return Rect.fromPoints(_startContent!, _currentContent!);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  Offset _toContent(Offset local) {
    return Offset(local.dx, local.dy + widget.scrollController.offset);
  }

  Set<String> _pathsInRect(Rect rect) {
    if (widget.itemCount == 0) return const {};
    final top = rect.top - widget.topPadding;
    final bottom = rect.bottom - widget.topPadding;
    if (bottom <= 0) return const {};
    final topRow = (top / widget.itemExtent).floor();
    final bottomRow = (bottom / widget.itemExtent).floor();
    final first = max(0, topRow);
    final last = min(widget.itemCount - 1, bottomRow);
    final paths = <String>{};
    for (int i = first; i <= last; i++) {
      final rowTop = i * widget.itemExtent;
      final rowBottom = rowTop + widget.rowHeight;
      if (bottom > rowTop && top < rowBottom) {
        paths.add(widget.pathAt(i));
      }
    }

    return paths;
  }

  void _fireSelection() {
    final paths = _pathsInRect(_contentRect);
    if (_setsEqual(paths, _lastPaths)) return;
    _lastPaths = paths;
    final additive = HardwareKeyboard.instance.isControlPressed;
    widget.onSelectionChanged?.call(paths, additive: additive);
  }

  bool _setsEqual(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;

    return a.containsAll(b);
  }

  void _startAutoScroll(double viewportHeight) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: _kAutoScrollIntervalMs),
      (_) {
        if (!_active) {
          _autoScrollTimer?.cancel();

          return;
        }
        final y = _currentLocalY;
        double delta = 0;
        if (y < _kAutoScrollZone) {
          delta = -_kAutoScrollSpeed * (1 - y / _kAutoScrollZone);
        } else if (y > viewportHeight - _kAutoScrollZone) {
          delta =
              _kAutoScrollSpeed * (1 - (viewportHeight - y) / _kAutoScrollZone);
        }
        if (delta == 0) return;
        final sc = widget.scrollController;
        final newOffset = (sc.offset + delta).clamp(
          sc.position.minScrollExtent,
          sc.position.maxScrollExtent,
        );
        if (newOffset == sc.offset) return;
        sc.jumpTo(newOffset);
        _currentContent = Offset(
          _currentContent!.dx,
          _currentLocalY + newOffset,
        );
        _fireSelection();
        setState(() {});
      },
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons != 1) return;
    if (widget.canStartSelectionAt?.call(event.localPosition) == false) {
      return;
    }
    final index = widget.rowAt(event.localPosition);
    if (index >= 0) return;
    final content = _toContent(event.localPosition);
    _startContent = content;
    _currentContent = content;
    _currentLocalY = event.localPosition.dy;
    _active = false;
    _lastPaths = const {};
  }

  void _handlePointerMove(PointerMoveEvent event, double viewportHeight) {
    if (_startContent == null) return;
    final content = _toContent(event.localPosition);
    _currentContent = content;
    _currentLocalY = event.localPosition.dy;
    if (!_active) {
      final dx = (content.dx - _startContent!.dx).abs();
      final dy = (content.dy - _startContent!.dy).abs();
      if (dx < _kThreshold && dy < _kThreshold) return;
      _active = true;
      _startAutoScroll(viewportHeight);
    }
    _fireSelection();
    setState(() {});
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_startContent != null && !_active) {
      widget.onBackgroundTap?.call();
    }
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (_active) {
      setState(() {
        _active = false;
        _startContent = null;
        _currentContent = null;
        _lastPaths = const {};
      });
    } else {
      _startContent = null;
      _currentContent = null;
      _lastPaths = const {};
    }
  }

  Widget _buildOverlay() {
    if (!_active || _startContent == null || _currentContent == null) {
      return const SizedBox.shrink();
    }
    final offset = widget.scrollController.offset;
    final vpDim = widget.scrollController.position.viewportDimension;
    final top = (min(_startContent!.dy, _currentContent!.dy) - offset).clamp(
      0.0,
      vpDim,
    );
    final bottom = (max(_startContent!.dy, _currentContent!.dy) - offset).clamp(
      0.0,
      vpDim,
    );
    final left = min(_startContent!.dx, _currentContent!.dx);
    final right = max(_startContent!.dx, _currentContent!.dx);
    final w = right - left;
    final h = bottom - top;
    if (w < 1 || h < 1) return const SizedBox.shrink();

    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight;

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handlePointerDown,
          onPointerMove: (e) => _handlePointerMove(e, viewportHeight),
          onPointerUp: _handlePointerUp,
          child: Stack(children: [widget.child, _buildOverlay()]),
        );
      },
    );
  }
}
