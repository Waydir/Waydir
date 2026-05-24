import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/platform/platform_paths.dart';
import 'location_uri.dart';

sealed class ResolveResult {
  const ResolveResult();
}

class ResolveSuccess extends ResolveResult {
  final String physicalPath;
  const ResolveSuccess(this.physicalPath);
}

class ResolveError extends ResolveResult {
  final String message;
  const ResolveError(this.message);
}

class ResolveUnsupported extends ResolveResult {
  const ResolveUnsupported();
}

class LocationResolver {
  LocationResolver._();

  /// Maps `smb://host[:port]/share` → gvfs physical mount root, populated
  /// after a successful mount. Lets the UI keep working with logical URIs
  /// while FS operations use the physical mountpoint.
  static final Map<String, String> _logicalToPhysical = {};

  static Map<String, String> get debugMappings =>
      Map.unmodifiable(_logicalToPhysical);

  static void debugSetMappingForTests(String logicalRoot, String physicalRoot) {
    assert(() {
      _logicalToPhysical[logicalRoot] = physicalRoot;
      return true;
    }());
  }

  static void debugClearMappingsForTests() {
    assert(() {
      _logicalToPhysical.clear();
      return true;
    }());
  }

  static String? physicalToLogical(String physical) {
    _pruneStaleMappings();
    for (final entry in _logicalToPhysical.entries) {
      final physicalRoot = entry.value;
      if (physical == physicalRoot) return entry.key;
      final prefix = physicalRoot.endsWith('/')
          ? physicalRoot
          : '$physicalRoot/';
      if (physical.startsWith(prefix)) {
        final sub = physical.substring(prefix.length);
        return '${entry.key}/$sub';
      }
    }
    return _gvfsPathToLogical(physical);
  }

  static String? logicalToPhysical(String logical) {
    if (!logical.startsWith('smb://')) return null;
    _pruneStaleMappings();
    for (final entry in _logicalToPhysical.entries) {
      final logicalRoot = entry.key;
      if (logical == logicalRoot) return entry.value;
      final prefix = '$logicalRoot/';
      if (logical.startsWith(prefix)) {
        final sub = logical.substring(prefix.length);
        return p.join(entry.value, sub);
      }
    }
    return null;
  }

  static void forget(String logical) {
    final uri = LocationUri.parse(logical);
    if (uri.scheme != LocationScheme.smb) return;
    _logicalToPhysical.remove(_logicalRoot(uri));
  }

  static bool isMapped(String logical) => logicalToPhysical(logical) != null;

  static Future<void> unmount(String logical) async {
    final uri = LocationUri.parse(logical);
    if (uri.scheme != LocationScheme.smb || !PlatformPaths.isLinux) return;
    final root = _logicalRoot(uri);
    final result = await Process.run('gio', ['mount', '-u', root]);
    if (result.exitCode == 0) _logicalToPhysical.remove(root);
  }

  static String _logicalRoot(LocationUri uri) {
    final buf = StringBuffer('smb://')..write(uri.host);
    if (uri.port != null) {
      buf.write(':');
      buf.write(uri.port);
    }
    buf.write('/');
    buf.write(uri.share);
    return buf.toString();
  }

  static Future<ResolveResult> resolve(String input) async {
    final uri = LocationUri.parse(input);
    switch (uri.scheme) {
      case LocationScheme.local:
      case LocationScheme.trash:
      case LocationScheme.windowsUnc:
        return ResolveSuccess(input);
      case LocationScheme.smb:
        if (PlatformPaths.isWindows) {
          if (uri.port != null) {
            return const ResolveError('SMB ports are not supported on Windows');
          }
          final unc = uri.toWindowsUnc();
          if (unc == null) {
            return const ResolveError('Invalid smb:// URI');
          }
          return ResolveSuccess(unc);
        }
        if (PlatformPaths.isLinux) {
          return _resolveSmbLinux(uri);
        }
        return const ResolveUnsupported();
      case LocationScheme.other:
        return const ResolveUnsupported();
    }
  }

  static Future<ResolveResult> _resolveSmbLinux(LocationUri uri) async {
    final host = uri.host;
    final share = uri.share;
    if (host == null || host.isEmpty) {
      return const ResolveError('Missing server in smb:// URI');
    }
    if (share == null || share.isEmpty) {
      return const ResolveError('Missing share in smb:// URI');
    }
    final mountTarget = StringBuffer('smb://')..write(host);
    if (uri.port != null) {
      mountTarget.write(':');
      mountTarget.write(uri.port);
    }
    mountTarget.write('/');
    mountTarget.write(share);

    final existingMountPoint = _findGvfsMountPoint(
      host: host,
      share: share,
      port: uri.port,
    );
    if (existingMountPoint != null) {
      return _resolvedSmbPath(uri, existingMountPoint);
    }

    final mountResult = await Process.run('gio', [
      'mount',
      '-a',
      mountTarget.toString(),
    ]);
    final mountErr = (mountResult.stderr as String? ?? '').trim();
    final alreadyMounted = mountErr.toLowerCase().contains('already mounted');
    if (mountResult.exitCode != 0 && !alreadyMounted) {
      final msg = mountErr.isNotEmpty ? mountErr : 'gio mount failed';
      return ResolveError(msg);
    }

    final mountPoint = _findGvfsMountPoint(
      host: host,
      share: share,
      port: uri.port,
    );
    if (mountPoint == null) {
      return const ResolveError('Mounted share could not be located in gvfs');
    }
    return _resolvedSmbPath(uri, mountPoint);
  }

  static ResolveSuccess _resolvedSmbPath(LocationUri uri, String mountPoint) {
    _logicalToPhysical[_logicalRoot(uri)] = mountPoint;
    final sub = uri.path;
    final fullPath = (sub == null || sub.isEmpty)
        ? mountPoint
        : p.join(mountPoint, sub.replaceAll('\\', '/'));
    return ResolveSuccess(fullPath);
  }

  static void _pruneStaleMappings() {
    _logicalToPhysical.removeWhere((_, physical) {
      try {
        return !Directory(physical).existsSync();
      } catch (_) {
        return true;
      }
    });
  }

  static String? _findGvfsMountPoint({
    required String host,
    required String share,
    int? port,
  }) {
    final uid = Platform.environment['UID'] ?? _processUid();
    if (uid == null) return null;
    final gvfsDir = Directory('/run/user/$uid/gvfs');
    if (!gvfsDir.existsSync()) return null;
    final wantedHost = host.toLowerCase();
    for (final entry in gvfsDir.listSync()) {
      final name = p.basename(entry.path);
      if (!name.startsWith('smb-share:')) continue;
      final attrs = <String, String>{};
      for (final pair in name.substring('smb-share:'.length).split(',')) {
        final eq = pair.indexOf('=');
        if (eq <= 0) continue;
        attrs[pair.substring(0, eq)] = pair.substring(eq + 1);
      }
      if ((attrs['server'] ?? '').toLowerCase() != wantedHost) continue;
      if ((attrs['share'] ?? '') != share) continue;
      final entryPort = attrs['port'];
      final wantedPort = port?.toString();
      if (entryPort != wantedPort) continue;
      return entry.path;
    }
    return null;
  }

  static String? _gvfsPathToLogical(String physical) {
    final normalized = p.normalize(physical);
    final marker = '${p.separator}gvfs${p.separator}smb-share:';
    final markerIndex = normalized.indexOf(marker);
    if (markerIndex < 0) return null;
    final mountStart = markerIndex + '${p.separator}gvfs${p.separator}'.length;
    final tail = normalized.substring(mountStart);
    final slash = tail.indexOf(p.separator);
    final mountName = slash < 0 ? tail : tail.substring(0, slash);
    if (!mountName.startsWith('smb-share:')) return null;
    final attrs = <String, String>{};
    for (final pair in mountName.substring('smb-share:'.length).split(',')) {
      final eq = pair.indexOf('=');
      if (eq <= 0) continue;
      attrs[pair.substring(0, eq)] = pair.substring(eq + 1);
    }
    final host = attrs['server'];
    final share = attrs['share'];
    if (host == null || host.isEmpty || share == null || share.isEmpty) {
      return null;
    }
    final buf = StringBuffer('smb://')..write(host);
    final port = attrs['port'];
    if (port != null && port.isNotEmpty) {
      buf.write(':');
      buf.write(port);
    }
    buf.write('/');
    buf.write(share);
    if (slash >= 0 && slash < tail.length - 1) {
      buf.write('/');
      buf.write(tail.substring(slash + 1).replaceAll(p.separator, '/'));
    }
    return buf.toString();
  }

  static String? _processUid() {
    try {
      final r = Process.runSync('id', ['-u']);
      if (r.exitCode == 0) {
        return (r.stdout as String).trim();
      }
    } catch (_) {}
    return null;
  }
}
