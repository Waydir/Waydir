import 'dart:convert';
import 'dart:io';

import 'package:signals/signals.dart';

import 'package:path/path.dart' as p;

import '../platform/app_dirs.dart';
import 'log_entry.dart';

class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static const int _ringCapacity = 500;
  static const int _retentionDays = 7;

  final ListSignal<LogEntry> entries = listSignal<LogEntry>([]);

  IOSink? _sink;
  bool _initialized = false;

  String get _fileName {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'waydir-$y$m$d.log';
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final dir = Directory(await AppDirs.logs());
      await _rotate(dir);
      final file = File(p.join(dir.path, _fileName));
      _sink = file.openWrite(mode: FileMode.append);
    } catch (_) {
      _sink = null;
    }
  }

  Future<void> _rotate(Directory dir) async {
    try {
      final cutoff = DateTime.now().subtract(
        const Duration(days: _retentionDays),
      );
      await for (final ent in dir.list()) {
        if (ent is! File) continue;
        final name = p.basename(ent.path);
        if (!name.startsWith('waydir-') || !name.endsWith('.log')) continue;
        final stat = await ent.stat();
        if (stat.modified.isBefore(cutoff)) {
          await ent.delete();
        }
      }
    } catch (_) {}
  }

  void warn(String tag, String message, {Object? error, StackTrace? stack}) {
    _add(LogLevel.warn, tag, message, error, stack);
  }

  void error(String tag, String message, {Object? error, StackTrace? stack}) {
    _add(LogLevel.error, tag, message, error, stack);
  }

  void _add(
    LogLevel level,
    String tag,
    String message,
    Object? error,
    StackTrace? stack,
  ) {
    final msg = error == null ? message : '$message: $error';
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: msg,
      stackTrace: stack?.toString(),
    );

    final list = entries.value;
    if (list.length >= _ringCapacity) {
      list.removeRange(0, list.length - _ringCapacity + 1);
    }
    entries.add(entry);

    try {
      _sink?.writeln(jsonEncode(entry.toJson()));
    } catch (_) {}
  }

  Future<String> logsDir() => AppDirs.logs();

  Future<String> currentLogFile() async =>
      p.join(await AppDirs.logs(), _fileName);

  void clear() => entries.value = [];

  Future<void> dispose() async {
    try {
      await _sink?.flush();
      await _sink?.close();
    } catch (_) {}
    _sink = null;
  }
}

AppLogger get log => AppLogger.instance;
