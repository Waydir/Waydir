import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:xdg_directories/xdg_directories.dart' as xdg;

class PlatformPaths {
  PlatformPaths._();

  static String get separator => Platform.pathSeparator;

  static String get homePath {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ??
          '${Platform.environment['HOMEDRIVE'] ?? 'C:'}${Platform.environment['HOMEPATH'] ?? r'\Users\Default'}';
    }
    return Platform.environment['HOME'] ?? '/';
  }

  static String get rootPath {
    if (Platform.isWindows) {
      return _windowsDriveRoot(homePath);
    }
    return '/';
  }

  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;

  static bool isRoot(String path) {
    if (Platform.isWindows) {
      final cleaned = _normalizeWindowsPath(path);
      return RegExp(r'^[A-Za-z]:\\?$').hasMatch(cleaned);
    }
    return path == '/';
  }

  static String parentOf(String path) {
    if (Platform.isWindows) {
      final cleaned = _normalizeWindowsPath(path);
      final root = _windowsDriveRoot(cleaned);
      if (cleaned == root || cleaned == root.replaceAll(r'\', '')) {
        return root;
      }
      final parent = p.dirname(cleaned);
      return parent.isEmpty ? root : parent;
    }
    if (path == '/') return '/';
    final parent = p.dirname(path);
    return parent.isEmpty ? '/' : parent;
  }

  static String join(String part1, [String? part2, String? part3]) {
    return p.join(part1, part2, part3);
  }

  static List<String> segments(String path) {
    if (Platform.isWindows) {
      final cleaned = _normalizeWindowsPath(path);
      final root = _windowsDriveRoot(cleaned);
      final rest = cleaned.length > root.length
          ? cleaned.substring(root.length)
          : '';
      final parts = rest.split(separator).where((s) => s.isNotEmpty).toList();
      return [root.replaceAll(r'\', '').replaceAll('/', ''), ...parts];
    }
    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    return parts;
  }

  static String buildPartialPath(List<String> segments, int upToIndex) {
    if (Platform.isWindows) {
      final driveLetter = segments.first;
      if (upToIndex == 0) return '$driveLetter\\';
      final rest = segments.sublist(1, upToIndex + 1).join(separator);
      return '$driveLetter\\$rest';
    }
    return '/${segments.sublist(0, upToIndex + 1).join('/')}';
  }

  static String? _xdgDir(String key) {
    if (!Platform.isLinux) return null;
    try {
      final dir = xdg.getUserDirectory(key);
      return dir?.path;
    } catch (_) {
      return null;
    }
  }

  static String get desktopPath =>
      _xdgDir('DESKTOP') ?? join(homePath, 'Desktop');
  static String get documentsPath =>
      _xdgDir('DOCUMENTS') ?? join(homePath, 'Documents');
  static String get downloadsPath =>
      _xdgDir('DOWNLOAD') ?? join(homePath, 'Downloads');
  static String get picturesPath =>
      _xdgDir('PICTURES') ?? join(homePath, 'Pictures');
  static String get musicPath => _xdgDir('MUSIC') ?? join(homePath, 'Music');
  static String get videosPath => _xdgDir('VIDEOS') ?? join(homePath, 'Videos');

  static String? get trashPath {
    if (Platform.isLinux) {
      final xdgData = Platform.environment['XDG_DATA_HOME'];
      final base = (xdgData == null || xdgData.isEmpty)
          ? join(homePath, '.local', 'share')
          : xdgData;
      return p.join(base, 'Trash', 'files');
    }
    if (Platform.isMacOS) return join(homePath, '.Trash');
    return null;
  }

  static bool get canOpenTrash => isLinux || isMacOS || isWindows;

  static bool isValidFileName(String name) {
    if (name.isEmpty || name == '.' || name == '..') return false;
    if (Platform.isWindows) {
      if (name.contains(RegExp(r'[/\\:*?"<>|]'))) return false;
      final upper = name.toUpperCase();
      const reserved = [
        'CON',
        'PRN',
        'AUX',
        'NUL',
        'COM1',
        'COM2',
        'COM3',
        'COM4',
        'COM5',
        'COM6',
        'COM7',
        'COM8',
        'COM9',
        'LPT1',
        'LPT2',
        'LPT3',
        'LPT4',
        'LPT5',
        'LPT6',
        'LPT7',
        'LPT8',
        'LPT9',
      ];
      final base = upper.contains('.')
          ? upper.substring(0, upper.indexOf('.'))
          : upper;
      if (reserved.contains(base)) return false;
      if (name.endsWith('.') || name.endsWith(' ')) return false;
    } else {
      if (name.contains('/')) return false;
    }
    return true;
  }

  static String fileName(String path) {
    return p.basename(path);
  }

  static String normalize(String path) {
    if (Platform.isWindows) {
      return _normalizeWindowsPath(path);
    }
    return path;
  }

  static List<String> listDrives() {
    if (!Platform.isWindows) return [];
    final drives = <String>[];
    for (var i = 65; i <= 90; i++) {
      final letter = String.fromCharCode(i);
      final root = '$letter:\\';
      try {
        if (Directory(root).existsSync()) {
          drives.add(root);
        }
      } catch (_) {}
    }
    return drives;
  }

  static String _windowsDriveRoot(String path) {
    if (path.length >= 2 && path[1] == ':') {
      return '${path[0].toUpperCase()}:\\';
    }
    return 'C:\\';
  }

  static String _normalizeWindowsPath(String path) {
    var p = path.replaceAll('/', r'\');
    if (p.length >= 2 && p[1] == ':' && (p.length == 2 || p[2] != r'\')) {
      p = '${p.substring(0, 2)}\\${p.substring(2)}';
    }
    return p;
  }
}
