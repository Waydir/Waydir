import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:waydir_term/src/core/buffer/cell_offset.dart';
import 'package:waydir_term/src/core/buffer/range_line.dart';
import 'package:waydir_term/src/core/mouse/button.dart';
import 'package:waydir_term/src/core/mouse/button_state.dart';
import 'package:waydir_term/src/terminal_view.dart';
import 'package:waydir_term/src/ui/controller.dart';
import 'package:waydir_term/src/ui/gesture/gesture_detector.dart';
import 'package:waydir_term/src/ui/pointer_input.dart';
import 'package:waydir_term/src/ui/render.dart';

class TerminalGestureHandler extends StatefulWidget {
  const TerminalGestureHandler({
    super.key,
    required this.terminalView,
    required this.terminalController,
    this.child,
    this.onTapUp,
    this.onSingleTapUp,
    this.onTapDown,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.readOnly = false,
  });

  final TerminalViewState terminalView;

  final TerminalController terminalController;

  final Widget? child;

  final GestureTapUpCallback? onTapUp;

  final GestureTapUpCallback? onSingleTapUp;

  final GestureTapDownCallback? onTapDown;

  final GestureTapDownCallback? onSecondaryTapDown;

  final GestureTapUpCallback? onSecondaryTapUp;

  final GestureTapDownCallback? onTertiaryTapDown;

  final GestureTapUpCallback? onTertiaryTapUp;

  final bool readOnly;

  @override
  State<TerminalGestureHandler> createState() => _TerminalGestureHandlerState();
}

class _TerminalGestureHandlerState extends State<TerminalGestureHandler> {
  TerminalViewState get terminalView => widget.terminalView;

  RenderTerminal get renderTerminal => terminalView.renderTerminal;

  Timer? _selectionScrollTimer;

  Offset? _lastSelectionDragPosition;

  CellOffset? _selectionStartCell;

  BufferRangeLine? _selectionStartWord;

  bool _selectingWords = false;

  static const _selectionScrollEdge = 28.0;

  static const _selectionScrollInterval = Duration(milliseconds: 33);

  @override
  void dispose() {
    _stopSelectionAutoscroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TerminalGestureDetector(
      child: widget.child,
      onTapUp: widget.onTapUp,
      onSingleTapUp: onSingleTapUp,
      onTapDown: onTapDown,
      onSecondaryTapDown: onSecondaryTapDown,
      onSecondaryTapUp: onSecondaryTapUp,
      onTertiaryTapDown: onSecondaryTapDown,
      onTertiaryTapUp: onSecondaryTapUp,
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressUp: onLongPressUp,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onDragCancel: onDragCancel,
      onDoubleTapDown: onDoubleTapDown,
    );
  }

  bool get _shouldSendTapEvent =>
      !widget.readOnly &&
      widget.terminalController.shouldSendPointerInput(PointerInput.tap);

  void _tapDown(
    GestureTapDownCallback? callback,
    TapDownDetails details,
    TerminalMouseButton button, {
    bool forceCallback = false,
  }) {
    // Check if the terminal should and can handle the tap down event.
    var handled = false;
    if (_shouldSendTapEvent) {
      handled = renderTerminal.mouseEvent(
        button,
        TerminalMouseButtonState.down,
        details.localPosition,
      );
    }
    // If the event was not handled by the terminal, use the supplied callback.
    if (!handled || forceCallback) {
      callback?.call(details);
    }
  }

  void _tapUp(
    GestureTapUpCallback? callback,
    TapUpDetails details,
    TerminalMouseButton button, {
    bool forceCallback = false,
  }) {
    // Check if the terminal should and can handle the tap up event.
    var handled = false;
    if (_shouldSendTapEvent) {
      handled = renderTerminal.mouseEvent(
        button,
        TerminalMouseButtonState.up,
        details.localPosition,
      );
    }
    // If the event was not handled by the terminal, use the supplied callback.
    if (!handled || forceCallback) {
      callback?.call(details);
    }
  }

  void onTapDown(TapDownDetails details) {
    // onTapDown is special, as it will always call the supplied callback.
    // The TerminalView depends on it to bring the terminal into focus.
    _tapDown(
      widget.onTapDown,
      details,
      TerminalMouseButton.left,
      forceCallback: true,
    );
  }

  void onSingleTapUp(TapUpDetails details) {
    _tapUp(widget.onSingleTapUp, details, TerminalMouseButton.left);
  }

  void onSecondaryTapDown(TapDownDetails details) {
    _tapDown(widget.onSecondaryTapDown, details, TerminalMouseButton.right);
  }

  void onSecondaryTapUp(TapUpDetails details) {
    _tapUp(widget.onSecondaryTapUp, details, TerminalMouseButton.right);
  }

  void onTertiaryTapDown(TapDownDetails details) {
    _tapDown(widget.onTertiaryTapDown, details, TerminalMouseButton.middle);
  }

  void onTertiaryTapUp(TapUpDetails details) {
    _tapUp(widget.onTertiaryTapUp, details, TerminalMouseButton.right);
  }

  void onDoubleTapDown(TapDownDetails details) {
    renderTerminal.selectWord(details.localPosition);
  }

  void onLongPressStart(LongPressStartDetails details) {
    _selectionStartWord = renderTerminal.getWordBoundary(details.localPosition);
    _selectingWords = true;
    final word = _selectionStartWord;
    if (word == null) return;
    renderTerminal.selectWordRange(word);
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _lastSelectionDragPosition = details.localPosition;
    _updateDragSelection();
    _updateSelectionAutoscroll();
  }

  void onLongPressUp() {
    _stopSelectionAutoscroll();
  }

  void onDragStart(DragStartDetails details) {
    _lastSelectionDragPosition = details.localPosition;
    _selectingWords = details.kind != PointerDeviceKind.mouse;

    if (_selectingWords) {
      _selectionStartWord =
          renderTerminal.getWordBoundary(details.localPosition);
      _selectionStartCell = null;
      final word = _selectionStartWord;
      if (word == null) return;
      renderTerminal.selectWordRange(word);
    } else {
      _selectionStartCell = renderTerminal.getCellOffset(details.localPosition);
      _selectionStartWord = null;
      renderTerminal.selectCharactersFromCell(_selectionStartCell!);
    }
    _updateSelectionAutoscroll();
  }

  void onDragUpdate(DragUpdateDetails details) {
    _lastSelectionDragPosition = details.localPosition;
    _updateDragSelection();
    _updateSelectionAutoscroll();
  }

  void onDragEnd(DragEndDetails details) {
    _stopSelectionAutoscroll();
  }

  void onDragCancel() {
    _stopSelectionAutoscroll();
  }

  void _updateDragSelection() {
    final current = _lastSelectionDragPosition;
    if (current == null) return;
    if (_selectingWords) {
      final start = _selectionStartWord;
      if (start == null) return;
      renderTerminal.selectWordRange(start, current);
    } else {
      final start = _selectionStartCell;
      if (start == null) return;
      renderTerminal.selectCharactersFromCell(start, current);
    }
  }

  void _updateSelectionAutoscroll() {
    final position = _lastSelectionDragPosition;
    if (position == null) {
      _cancelSelectionAutoscroll();
      return;
    }
    final delta =
        _selectionScrollDelta(position.dy, renderTerminal.size.height);
    if (delta == 0) {
      _cancelSelectionAutoscroll();
      return;
    }
    _selectionScrollTimer ??= Timer.periodic(
      _selectionScrollInterval,
      (_) => _tickSelectionAutoscroll(),
    );
  }

  double _selectionScrollDelta(double y, double height) {
    if (y < 0) return y;
    if (y < _selectionScrollEdge) return -(_selectionScrollEdge - y);
    if (y > height) return y - height;
    if (y > height - _selectionScrollEdge) {
      return y - (height - _selectionScrollEdge);
    }
    return 0;
  }

  void _tickSelectionAutoscroll() {
    final position = _lastSelectionDragPosition;
    if (position == null) {
      _cancelSelectionAutoscroll();
      return;
    }
    final delta =
        _selectionScrollDelta(position.dy, renderTerminal.size.height);
    if (delta == 0) {
      _cancelSelectionAutoscroll();
      return;
    }
    if (!terminalView.scrollSelectionBy(delta)) {
      _cancelSelectionAutoscroll();
      return;
    }
    _updateDragSelection();
  }

  void _cancelSelectionAutoscroll() {
    _selectionScrollTimer?.cancel();
    _selectionScrollTimer = null;
  }

  void _stopSelectionAutoscroll() {
    _cancelSelectionAutoscroll();
    _lastSelectionDragPosition = null;
    _selectionStartCell = null;
    _selectionStartWord = null;
  }
}
