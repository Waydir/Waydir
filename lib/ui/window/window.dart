import 'dart:io';
import 'package:flutter/widgets.dart';

import 'ffi.dart' as ffi;

class AppWindow {
  AppWindow._();

  Alignment _alignment = Alignment.center;

  Alignment get alignment => _alignment;
  set alignment(Alignment value) {
    _alignment = value;
    if (value == Alignment.center) ffi.centerWindow();
  }

  set minSize(Size value) {
    ffi.setMinSize(value.width.toInt(), value.height.toInt());
  }

  Size get size {
    final s = ffi.getSize();
    return Size(s.width.toDouble(), s.height.toDouble());
  }

  set size(Size value) {
    ffi.setSize(value.width.toInt(), value.height.toInt());
    if (_alignment == Alignment.center) ffi.centerWindow();
  }

  set title(String value) => ffi.setTitle(value);

  bool get isMaximized => ffi.isMaximized();
  bool get isVisible => ffi.isVisible();

  void show() => ffi.show();
  void hide() => ffi.hide();
  void minimize() => ffi.minimize();
  void maximize() => ffi.maximize();
  void restore() => ffi.restore();
  void close() => ffi.close();

  void maximizeOrRestore() {
    if (isMaximized) {
      restore();
    } else {
      maximize();
    }
  }

  void startDragging() => ffi.startDragging();
}

final AppWindow appWindow = AppWindow._();

bool get isWindowChromeSupported =>
    !Platform.isMacOS && (Platform.isWindows || Platform.isLinux);
