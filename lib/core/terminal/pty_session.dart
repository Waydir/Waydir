import 'dart:async';
import 'dart:convert';

import 'package:waydir_term/xterm.dart';

import '../fs/waydir_core_loader.dart';

/// Bridges an `xterm` [Terminal] to a native pseudo-terminal spawned by
/// `waydir_core` (portable-pty). Output is polled off the native buffer and
/// fed into the terminal; terminal input and resizes are forwarded to the pty.
class PtySession {
  final Terminal terminal;
  final _utf8 = const Utf8Decoder(allowMalformed: true);

  int? _id;
  Timer? _poll;
  bool _exited = false;
  void Function()? _onExit;

  PtySession({int maxLines = 5000}) : terminal = Terminal(maxLines: maxLines);

  bool get isStarted => _id != null;
  bool get hasExited => _exited;

  /// Spawns the shell in [cwd]. Returns false if the native pty is
  /// unavailable. Safe to call once; later calls are no-ops.
  bool start({
    required String cwd,
    String shell = '',
    void Function()? onExit,
  }) {
    if (_id != null) return true;
    _onExit = onExit;
    final id = WaydirCoreLoader.ptyOpen(
      shell: shell,
      cwd: cwd,
      cols: terminal.viewWidth,
      rows: terminal.viewHeight,
    );
    if (id == null) return false;
    _id = id;

    terminal.onOutput = (data) {
      final i = _id;
      if (i != null) WaydirCoreLoader.ptyWrite(i, utf8.encode(data));
    };
    terminal.onResize = (w, h, pw, ph) {
      final i = _id;
      if (i != null) WaydirCoreLoader.ptyResize(i, w, h);
    };

    _poll = Timer.periodic(const Duration(milliseconds: 16), (_) => _drain());
    return true;
  }

  void _drain() {
    final id = _id;
    if (id == null) return;
    final data = WaydirCoreLoader.ptyRead(id);
    if (data != null && data.isNotEmpty) {
      terminal.write(_utf8.convert(data));
    }
    if (!WaydirCoreLoader.ptyAlive(id)) {
      _exited = true;
      _poll?.cancel();
      _poll = null;
      final cb = _onExit;
      _onExit = null;
      cb?.call();
    }
  }

  void dispose() {
    _poll?.cancel();
    _poll = null;
    final id = _id;
    _id = null;
    if (id != null) WaydirCoreLoader.ptyClose(id);
  }
}
