import 'dart:io';

import '../core/logging/app_logger.dart';
import '../core/platform/platform_paths.dart';

class LaunchOptions {
  final List<String> folders;
  final String? selectPath;
  final bool split;
  final bool showHelp;
  final bool showVersion;

  const LaunchOptions({
    this.folders = const [],
    this.selectPath,
    this.split = false,
    this.showHelp = false,
    this.showVersion = false,
  });

  bool get opensLocation => folders.isNotEmpty || selectPath != null;
}

class LaunchArgs {
  LaunchArgs._();

  static LaunchOptions options = const LaunchOptions();

  static const String helpText = '''
Waydir - desktop file manager

Usage: waydir [options] [path...]

Arguments:
  path...               One or more folders to open, each in its own tab.

Options:
  -s, --split           Open the first two paths side by side in split view.
  -r, --reveal <file>   Open the containing folder and select <file>.
      --select <file>   Alias for --reveal.
  -v, --version         Print the version and exit.
  -h, --help            Show this help and exit.
''';

  static void parse(List<String> args) {
    final folders = <String>[];
    String? selectPath;
    var split = false;
    var showHelp = false;
    var showVersion = false;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '-h':
        case '--help':
          showHelp = true;
        case '-v':
        case '--version':
          showVersion = true;
        case '-s':
        case '--split':
          split = true;
        case '-r':
        case '--reveal':
        case '--select':
          if (i + 1 < args.length) {
            final file = _resolveFile(args[++i]);
            if (file != null) selectPath = file;
          }
        default:
          if (arg.startsWith('--select=')) {
            final file = _resolveFile(arg.substring('--select='.length));
            if (file != null) selectPath = file;
          } else if (arg.startsWith('--reveal=')) {
            final file = _resolveFile(arg.substring('--reveal='.length));
            if (file != null) selectPath = file;
          } else if (arg.startsWith('-')) {
            continue;
          } else {
            final resolved = _resolve(arg);
            if (resolved == null) continue;
            if (resolved.isDirectory) {
              folders.add(resolved.path);
            } else {
              selectPath = resolved.path;
            }
          }
      }
    }

    options = LaunchOptions(
      folders: folders,
      selectPath: selectPath,
      split: split,
      showHelp: showHelp,
      showVersion: showVersion,
    );
  }

  static String? _resolveFile(String raw) {
    final resolved = _resolve(raw);
    if (resolved == null || resolved.isDirectory) return null;
    return resolved.path;
  }

  static _ResolvedPath? _resolve(String raw) {
    final expanded = PlatformPaths.expandTilde(
      PlatformPaths.expandEnvVars(raw.trim()),
    );
    if (expanded.isEmpty) return null;
    final normalized = PlatformPaths.normalize(expanded);
    try {
      if (Directory(normalized).existsSync()) {
        return _ResolvedPath(normalized, true);
      }
      if (File(normalized).existsSync()) {
        return _ResolvedPath(normalized, false);
      }
    } catch (e, st) {
      log.warn('launch', 'failed to resolve launch path', error: e, stack: st);
    }
    return null;
  }
}

class _ResolvedPath {
  final String path;
  final bool isDirectory;
  const _ResolvedPath(this.path, this.isDirectory);
}
