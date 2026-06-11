import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:xdg_directories/xdg_directories.dart' as xdg;

class PlatformPaths {
  PlatformPaths._();

  static String? trashPathOverride;
  static bool? isWindowsOverrideForTesting;
  static String? homePathOverrideForTesting;
  static final p.Context _windowsPath = p.Context(style: p.Style.windows);

  static String get separator => Platform.pathSeparator;

  static String get homePath {
    final override = homePathOverrideForTesting;
    if (override != null) return override;
    if (isWindows) {
      return Platform.environment['USERPROFILE'] ??
          '${Platform.environment['HOMEDRIVE'] ?? 'C:'}${Platform.environment['HOMEPATH'] ?? r'\Users\Default'}';
    }
    return Platform.environment['HOME'] ?? '/';
  }

  static String get rootPath {
    if (isWindows) {
      return _windowsDriveRoot(homePath);
    }
    return '/';
  }

  static bool get isWindows =>
      isWindowsOverrideForTesting ?? Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;

  static bool isSmbUri(String path) => path.startsWith('smb://');

  static bool isSftpUri(String path) => path.startsWith('sftp://');

  static bool isRemoteUri(String path) => isSmbUri(path) || isSftpUri(path);

  /// Whether [path] lives on a network/remote filesystem (logical remote URIs,
  /// Windows UNC or mapped network drives, Linux gvfs mounts). Used to keep the
  /// local-FS machinery (directory watcher, synchronous git probing) off slow
  /// network paths so the UI doesn't stall during transfers.
  static bool isNetworkPath(String path) {
    if (path.isEmpty) return false;
    if (isRemoteUri(path)) return true;
    if (isWindows) return _windowsIsNetworkPath(path);
    if (isLinux) return path.contains('/gvfs/');
    return false;
  }

  static int Function(Pointer<Utf16>)? _getDriveType;
  static bool _getDriveTypeResolved = false;

  static bool _windowsIsNetworkPath(String path) {
    final cleaned = _normalizeWindowsPath(path);
    if (_isWindowsUncPath(cleaned)) return true;
    if (!RegExp(r'^[A-Za-z]:').hasMatch(cleaned)) return false;
    final fn = _resolveGetDriveType();
    if (fn == null) return false;
    final ptr = _windowsDriveRoot(cleaned).toNativeUtf16();
    try {
      return fn(ptr) == 4; // DRIVE_REMOTE
    } catch (_) {
      return false;
    } finally {
      malloc.free(ptr);
    }
  }

  static int Function(Pointer<Utf16>)? _resolveGetDriveType() {
    if (_getDriveTypeResolved) return _getDriveType;
    _getDriveTypeResolved = true;
    try {
      _getDriveType = DynamicLibrary.open('kernel32.dll')
          .lookupFunction<
            Uint32 Function(Pointer<Utf16>),
            int Function(Pointer<Utf16>)
          >('GetDriveTypeW');
    } catch (_) {
      _getDriveType = null;
    }
    return _getDriveType;
  }

  static bool isRoot(String path) {
    if (isSmbUri(path) || isSftpUri(path)) {
      final scheme = isSftpUri(path) ? 'sftp://' : 'smb://';
      final rest = path.substring(scheme.length);
      final slashes = '/'.allMatches(rest).length;
      return slashes <= 1;
    }
    if (isWindows) {
      final cleaned = _normalizeWindowsPath(path);
      if (_isWindowsUncPath(cleaned)) {
        final parts = _stripTrailingWindowsSeparator(
          cleaned,
        ).substring(2).split(r'\').where((s) => s.isNotEmpty).toList();
        return parts.length <= 1;
      }
      return RegExp(r'^[A-Za-z]:\\?$').hasMatch(cleaned);
    }
    return path == '/';
  }

  static String parentOf(String path) {
    if (isSmbUri(path) || isSftpUri(path)) {
      final scheme = isSftpUri(path) ? 'sftp://' : 'smb://';
      final rest = path.substring(scheme.length);
      final slash = rest.lastIndexOf('/');
      if (slash < 0) return path;
      return '$scheme${rest.substring(0, slash)}';
    }
    if (isWindows) {
      final cleaned = _normalizeWindowsPath(path);
      if (_isWindowsUncPath(cleaned)) {
        final trimmed = _stripTrailingWindowsSeparator(cleaned);
        final parts = trimmed
            .substring(2)
            .split(r'\')
            .where((s) => s.isNotEmpty)
            .toList();
        if (parts.length <= 1) return _ensureTrailingWindowsSeparator(trimmed);
        return '\\\\${parts.sublist(0, parts.length - 1).join('\\')}';
      }
      final root = _windowsRoot(cleaned);
      final cleanedTrimmed = _stripTrailingWindowsSeparator(cleaned);
      final rootTrimmed = _stripTrailingWindowsSeparator(root);
      if (cleanedTrimmed == rootTrimmed) {
        return root;
      }
      final parent = _windowsPath.dirname(cleanedTrimmed);
      if (parent.isEmpty ||
          parent == '.' ||
          parent.length < rootTrimmed.length) {
        return root;
      }
      return parent;
    }
    if (path == '/') return '/';
    final parent = p.dirname(path);
    return parent.isEmpty ? '/' : parent;
  }

  static String join(String part1, [String? part2, String? part3]) {
    if (isSmbUri(part1) || isSftpUri(part1)) {
      final parts = [part1, ?part2, ?part3];
      return parts.where((part) => part.isNotEmpty).fold<String>('', (
        acc,
        part,
      ) {
        if (acc.isEmpty) return part.replaceAll(RegExp(r'/+$'), '');
        return '${acc.replaceAll(RegExp(r'/+$'), '')}/${part.replaceAll(RegExp(r'^/+'), '')}';
      });
    }
    if (isWindows) return _windowsPath.join(part1, part2, part3);
    return p.join(part1, part2, part3);
  }

  static List<String> segments(String path) {
    if (isSmbUri(path) || isSftpUri(path)) {
      final scheme = isSftpUri(path) ? 'sftp://' : 'smb://';
      final rest = path.substring(scheme.length);
      final parts = rest.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) return [scheme];
      final root = '$scheme${parts.first}';
      return [root, ...parts.sublist(1)];
    }
    if (isWindows) {
      final cleaned = _normalizeWindowsPath(path);
      if (_isWindowsUncPath(cleaned)) {
        final parts = _stripTrailingWindowsSeparator(
          cleaned,
        ).substring(2).split(r'\').where((s) => s.isNotEmpty).toList();
        if (parts.isEmpty) return [_stripTrailingWindowsSeparator(cleaned)];
        return ['\\\\${parts.first}', ...parts.sublist(1)];
      }
      final root = _windowsDriveRoot(cleaned);
      final rest = cleaned.length > root.length
          ? cleaned.substring(root.length)
          : '';
      final parts = rest.split(r'\').where((s) => s.isNotEmpty).toList();
      final rootLabel = root.replaceAll(r'\', '').replaceAll('/', '');
      return [rootLabel, ...parts];
    }
    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    return parts;
  }

  static String buildPartialPath(List<String> segments, int upToIndex) {
    if (segments.isNotEmpty &&
        (segments.first.startsWith('smb://') ||
            segments.first.startsWith('sftp://'))) {
      if (upToIndex == 0) return segments.first;
      return '${segments.first}/${segments.sublist(1, upToIndex + 1).join('/')}';
    }
    if (isWindows) {
      final root = segments.first;
      if (upToIndex == 0) return _ensureTrailingWindowsSeparator(root);
      final rest = segments.sublist(1, upToIndex + 1).join(r'\');
      return '${_ensureTrailingWindowsSeparator(root)}$rest';
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
  static String get videosPath =>
      _xdgDir('VIDEOS') ??
      join(homePath, Platform.isMacOS ? 'Movies' : 'Videos');

  static String? get trashPath {
    final override = trashPathOverride;
    if (override != null) return override;
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
    if (isSmbUri(path) || isSftpUri(path)) {
      final scheme = isSftpUri(path) ? 'sftp://' : 'smb://';
      final rest = path.substring(scheme.length);
      final slash = rest.lastIndexOf('/');
      if (slash < 0) return rest;
      return rest.substring(slash + 1);
    }
    if (isWindows) return _windowsPath.basename(path);
    return p.basename(path);
  }

  static String expandTilde(String path) {
    if (!path.startsWith('~')) return path;
    if (path == '~') return homePath;
    final second = path[1];
    if (second == '/' || (isWindows && second == r'\')) {
      return join(homePath, path.substring(2));
    }
    return path;
  }

  static String normalize(String path) {
    if (isSmbUri(path) || isSftpUri(path)) return path;
    if (isWindows) {
      return _normalizeWindowsPath(path);
    }
    return path;
  }

  static List<String> listDrives() {
    if (!isWindows) return [];
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

  /// Normalises a path for native directory listing. On Windows a bare UNC
  /// share root (e.g. `\\server\share`) must carry a trailing separator or
  /// `read_dir` rejects it, so the share root lists empty. No-op elsewhere.
  static String listablePath(String path) {
    if (!isWindows || isRemoteUri(path)) return path;
    final cleaned = _normalizeWindowsPath(path);
    final uncRoot = _windowsUncRoot(cleaned);
    if (uncRoot != null &&
        _stripTrailingWindowsSeparator(cleaned) ==
            _stripTrailingWindowsSeparator(uncRoot)) {
      return _ensureTrailingWindowsSeparator(cleaned);
    }
    return path;
  }

  /// Returns the host of a Windows UNC server root (`\\host` with no share),
  /// or null otherwise. Native directory listing cannot enumerate the shares
  /// of a bare server, so callers list them via share discovery the way
  /// Explorer does.
  static String? windowsUncServerRoot(String path) {
    if (!isWindows || path.isEmpty) return null;
    final cleaned = _normalizeWindowsPath(path);
    if (!_isWindowsUncPath(cleaned)) return null;
    final parts = _stripTrailingWindowsSeparator(
      cleaned,
    ).substring(2).split(r'\').where((s) => s.isNotEmpty).toList();
    if (parts.length != 1) return null;
    return parts.first;
  }

  static String _windowsDriveRoot(String path) {
    if (path.length >= 2 && path[1] == ':') {
      return '${path[0].toUpperCase()}:\\';
    }
    return 'C:\\';
  }

  static String _windowsRoot(String path) {
    return _windowsUncRoot(path) ?? _windowsDriveRoot(path);
  }

  static bool _isWindowsUncPath(String path) {
    return path.startsWith(r'\\') &&
        !path.startsWith(r'\\?\') &&
        !path.startsWith(r'\\.\');
  }

  static String? _windowsUncRoot(String path) {
    if (!_isWindowsUncPath(path)) return null;
    final parts = path
        .substring(2)
        .split(r'\')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length < 2) {
      return _ensureTrailingWindowsSeparator(path);
    }
    return '\\\\${parts[0]}\\${parts[1]}\\';
  }

  static String _normalizeWindowsPath(String path) {
    var p = path.replaceAll('/', r'\');
    if (p.length >= 2 && p[1] == ':' && (p.length == 2 || p[2] != r'\')) {
      p = '${p.substring(0, 2)}\\${p.substring(2)}';
    }
    return p;
  }

  static String _ensureTrailingWindowsSeparator(String path) {
    return path.endsWith(r'\') ? path : '$path\\';
  }

  static String _stripTrailingWindowsSeparator(String path) {
    var out = path;
    while (out.length > 1 && out.endsWith(r'\')) {
      if (RegExp(r'^[A-Za-z]:\\$').hasMatch(out)) break;
      out = out.substring(0, out.length - 1);
    }
    return out;
  }
}
