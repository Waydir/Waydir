import 'dart:io';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';
import 'macos_clipboard_ffi.dart';

class FileClipboard {
  static bool get _isWayland =>
      Platform.environment.containsKey('WAYLAND_DISPLAY');

  static Future<void> writeFiles(
    List<String> paths, {
    required bool isCut,
  }) async {
    if (Platform.isMacOS) {
      _writeMacOS(paths, isCut: isCut);

      return;
    }

    try {
      if (Platform.isWindows) {
        await _writeWindows(paths);
      } else if (_isWayland) {
        await _runWrite('wl-copy', [
          '-f',
          '-t',
          'text/uri-list',
        ], paths.map((p) => Uri.file(p).toString()).join('\n'));
      } else {
        await _runWrite('xclip', [
          '-selection',
          'clipboard',
          '-t',
          'text/uri-list',
        ], paths.map((p) => Uri.file(p).toString()).join('\n'));
      }
    } catch (e, st) {
      log.warn(
        'clipboard',
        'native file clipboard write failed',
        error: e,
        stack: st,
      );
    }

    try {
      final uris = paths.map((p) => Uri.file(p).toString()).join('\n');
      final action = isCut ? 'cut' : 'copy';
      await Clipboard.setData(ClipboardData(text: 'x-special/$action\n$uris'));
    } catch (e, st) {
      log.warn(
        'clipboard',
        'text clipboard fallback write failed',
        error: e,
        stack: st,
      );
    }
  }

  static Future<List<String>> readFilePaths() async {
    try {
      if (Platform.isWindows) {
        return await _readWindows();
      } else if (Platform.isMacOS) {
        return await _readMacOS();
      } else if (_isWayland) {
        return await _readWayland();
      } else {
        return await _readX11();
      }
    } catch (e, st) {
      log.warn('clipboard', 'file clipboard read failed', error: e, stack: st);

      return [];
    }
  }

  static Future<bool> isCutOperation() async {
    try {
      if (Platform.isMacOS) return macIsCut();

      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text?.startsWith('x-special/cut') ?? false) return true;

      if (!Platform.isWindows && !Platform.isMacOS && !_isWayland) {
        final output = await _runRead('xclip', [
          '-selection',
          'clipboard',
          '-t',
          'x-special/gnome-copied-files',
          '-o',
        ]);
        if (output != null && output.trim().startsWith('cut')) return true;
      }

      return false;
    } catch (e, st) {
      log.warn(
        'clipboard',
        'clipboard cut-state read failed',
        error: e,
        stack: st,
      );

      return false;
    }
  }

  static Future<void> _writeWindows(List<String> paths) async {
    final escaped = paths.map((p) => "'${p.replaceAll("'", "''")}'").join(',');
    final process = await Process.start('powershell', [
      '-NoProfile',
      '-Command',
      'Set-Clipboard -LiteralPath @($escaped)',
    ]);
    await process.exitCode;
  }

  static Future<List<String>> _readWindows() async {
    final output = await _runRead('powershell', [
      '-NoProfile',
      '-Command',
      '(Get-Clipboard -Format FileDropList).FullName',
    ]);
    if (output == null || output.trim().isEmpty) return [];

    return output
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  static void _writeMacOS(List<String> paths, {required bool isCut}) {
    macWriteFiles(paths, isCut: isCut);
  }

  static Future<List<String>> _readMacOS() async {
    return macReadFiles();
  }

  static Future<List<String>> _readX11() async {
    var output = await _runRead('xclip', [
      '-selection',
      'clipboard',
      '-t',
      'text/uri-list',
      '-o',
    ]);
    if (output != null) {
      final paths = _parseUris(output);
      if (paths.isNotEmpty) return paths;
    }

    output = await _runRead('xclip', [
      '-selection',
      'clipboard',
      '-t',
      'x-special/gnome-copied-files',
      '-o',
    ]);
    if (output != null) {
      final lines = output.split('\n');

      return _parseUris(lines.skip(1).join('\n'));
    }

    return [];
  }

  static Future<List<String>> _readWayland() async {
    final types = await _runRead('wl-paste', [
      '-l',
    ], timeout: const Duration(seconds: 1));
    if (types == null || !types.contains('text/uri-list')) return [];

    final output = await _runRead('wl-paste', [
      '-t',
      'text/uri-list',
    ], timeout: const Duration(seconds: 1));
    if (output != null) return _parseUris(output);

    return [];
  }

  static Future<void> _runWrite(
    String cmd,
    List<String> args,
    String input,
  ) async {
    final process = await Process.start(cmd, args);
    process.stdin.write(input);
    await process.stdin.close();
    await process.exitCode;
  }

  static Future<String?> _runRead(
    String cmd,
    List<String> args, {
    Duration? timeout,
  }) async {
    final process = await Process.start(cmd, args);
    final stdoutFuture = process.stdout
        .transform(const SystemEncoding().decoder)
        .join();

    int exitCode;
    if (timeout != null) {
      exitCode = await process.exitCode.timeout(
        timeout,
        onTimeout: () {
          process.kill();

          return -1;
        },
      );
    } else {
      exitCode = await process.exitCode;
    }

    if (exitCode != 0) {
      await process.stderr.drain();

      return null;
    }

    return await stdoutFuture;
  }

  static List<String> _parseUris(String raw) {
    const prefix = 'file://';

    return raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith(prefix))
        .map((l) {
          try {
            return Uri.parse(l).toFilePath();
          } catch (e) {
            return '';
          }
        })
        .where((p) => p.isNotEmpty)
        .toList();
  }
}
