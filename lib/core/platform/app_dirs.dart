import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Single source of truth for Waydir application directories.
///
/// Each directory is resolved and created at most once (cached future), so
/// callers never duplicate platform-path logic or `create(recursive:)` calls.
class AppDirs {
  AppDirs._();

  static Future<String>? _support;
  static Future<String>? _logs;
  static Future<String>? _themes;
  static Future<String>? _plugins;

  /// Base app-support dir. Matches the location the database has always used,
  /// so existing user data is never relocated.
  static Future<String> support() {
    return _support ??= _resolveSupport();
  }

  static Future<String> _resolveSupport() async {
    final String dir;
    if (Platform.isLinux) {
      final xdg = Platform.environment['XDG_CONFIG_HOME'];
      final base = xdg != null && xdg.isNotEmpty
          ? xdg
          : p.join(Platform.environment['HOME'] ?? '', '.config');
      dir = p.join(base, 'waydir');
    } else {
      dir = (await getApplicationSupportDirectory()).path;
    }
    await Directory(dir).create(recursive: true);
    return dir;
  }

  static Future<String> logs() {
    return _logs ??= _resolveChild('logs');
  }

  static Future<String> themes() {
    return _themes ??= _resolveChild('themes');
  }

  static Future<String> plugins() {
    return _plugins ??= _resolveChild('plugins');
  }

  static Future<String> _resolveChild(String name) async {
    final base = await support();
    final dir = p.join(base, name);
    await Directory(dir).create(recursive: true);
    return dir;
  }
}
