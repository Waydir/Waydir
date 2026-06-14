import 'dart:async';
import 'dart:convert';

import 'package:waydir_term/xterm.dart';

import '../fs/waydir_core_loader.dart';

const _minPollInterval = Duration(milliseconds: 12);
const _maxPollInterval = Duration(milliseconds: 32);

/// Computes the next poll delay for a pty session. Resets to [min] whenever
/// there is activity so input echo stays responsive, and backs off
/// geometrically toward [max] while the session is idle to avoid waking the
/// event loop needlessly on quiet terminals.
Duration nextPollInterval({
  required Duration current,
  required bool active,
  Duration min = _minPollInterval,
  Duration max = _maxPollInterval,
}) {
  if (active) return min;
  final next = current * 2;

  return next > max ? max : next;
}

/// Bridges an `xterm` [Terminal] to a native pseudo-terminal spawned by
/// `waydir_core` (portable-pty). Output is polled off the native buffer and
/// fed into the terminal; terminal input and resizes are forwarded to the pty.
class PtySession {
  final Terminal terminal;

  // Streaming UTF-8 decoder: the native pty is drained in arbitrary-sized
  // chunks, so a multibyte codepoint (box-drawing, spinners, emoji — common in
  // TUIs like codex) can straddle two reads. A stateless decode would mangle
  // those into replacement chars; the chunked decoder carries the partial
  // bytes across ticks instead.
  late final ByteConversionSink _decoder;

  int? _id;
  Timer? _poll;
  Duration _interval = _minPollInterval;
  bool _exited = false;
  void Function()? _onExit;

  PtySession({int maxLines = 5000}) : terminal = Terminal(maxLines: maxLines) {
    _decoder = const Utf8Decoder(
      allowMalformed: true,
    ).startChunkedConversion(_TerminalSink(terminal));
  }

  bool get isStarted => _id != null;
  bool get hasExited => _exited;

  /// Spawns the shell in [cwd]. Returns false if the native pty is
  /// unavailable. Safe to call once; later calls are no-ops.
  bool start({
    required String cwd,
    String shell = '',
    List<String> args = const [],
    void Function()? onExit,
  }) {
    if (_id != null) return true;
    _onExit = onExit;
    final id = WaydirCoreLoader.ptyOpen(
      shell: shell,
      cwd: cwd,
      args: args,
      cols: terminal.viewWidth,
      rows: terminal.viewHeight,
    );
    if (id == null) return false;
    _id = id;

    terminal.onOutput = (data) {
      final i = _id;
      if (i == null) return;
      WaydirCoreLoader.ptyWrite(i, utf8.encode(data));
      _wake();
    };
    terminal.onResize = (w, h, pw, ph) {
      final i = _id;
      if (i != null) WaydirCoreLoader.ptyResize(i, w, h);
    };

    _schedule();

    return true;
  }

  void _schedule() {
    _poll = Timer(_interval, _tick);
  }

  void _wake() {
    if (_id == null) return;
    _interval = _minPollInterval;
    _poll?.cancel();
    _schedule();
  }

  void _tick() {
    final id = _id;
    if (id == null) return;
    final data = WaydirCoreLoader.ptyRead(id);
    final hadData = data != null && data.isNotEmpty;
    if (hadData) {
      _decoder.add(data);
    }
    if (!WaydirCoreLoader.ptyAlive(id)) {
      _exited = true;
      _poll?.cancel();
      _poll = null;
      final cb = _onExit;
      _onExit = null;
      cb?.call();

      return;
    }
    _interval = nextPollInterval(current: _interval, active: hadData);
    _schedule();
  }

  void dispose() {
    _poll?.cancel();
    _poll = null;
    final id = _id;
    _id = null;
    if (id != null) WaydirCoreLoader.ptyClose(id);
    _decoder.close();
  }
}

/// Sink that forwards decoded output straight into the terminal emulator.
class _TerminalSink implements Sink<String> {
  final Terminal terminal;

  _TerminalSink(this.terminal);

  @override
  void add(String data) {
    if (data.isNotEmpty) terminal.write(data);
  }

  @override
  void close() {}
}
