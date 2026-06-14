import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as p;

import '../../core/fs/sftp_session_manager.dart';
import '../../core/logging/app_logger.dart';
import '../../core/platform/platform_paths.dart';
import '../../i18n/strings.g.dart';
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

class ResolveAuthenticationRequired extends ResolveResult {
  const ResolveAuthenticationRequired();
}

class ResolveUnsupported extends ResolveResult {
  const ResolveUnsupported();
}

class SmbCredentials {
  final String username;
  final String password;

  const SmbCredentials({required this.username, required this.password});
}

enum SftpAuthMethod { auto, password, privateKey }

class SftpCredentials {
  final String username;
  final SftpAuthMethod method;
  final String? password;
  final String? privateKeyPath;
  final String? passphrase;

  const SftpCredentials({
    required this.username,
    required this.method,
    this.password,
    this.privateKeyPath,
    this.passphrase,
  });

  const SftpCredentials.password({
    required this.username,
    required String this.password,
  }) : method = SftpAuthMethod.password,
       privateKeyPath = null,
       passphrase = null;

  const SftpCredentials.key({
    required this.username,
    required String this.privateKeyPath,
    this.passphrase,
  }) : method = SftpAuthMethod.privateKey,
       password = null;
}

class LocationResolver {
  LocationResolver._();

  /// Maps `smb://host[:port]/share` → gvfs physical mount root, populated
  /// after a successful mount. Lets the UI keep working with logical URIs
  /// while FS operations use the physical mountpoint.
  static final Map<String, String> _logicalToPhysical = {};

  static Map<String, String> get debugMappings =>
      Map.unmodifiable(_logicalToPhysical);

  static List<String> mountedLocations() {
    _pruneStaleMappings();
    final locations = _logicalToPhysical.keys.toList();
    locations.addAll(SftpSessionManager.activeRoots());
    locations.sort();
    return locations;
  }

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
    if (uri.scheme == LocationScheme.sftp) {
      SftpSessionManager.closeRoot(SftpSessionManager.rootOf(uri));
      return;
    }
    if (uri.scheme != LocationScheme.smb) return;
    if (PlatformPaths.isLinux) {
      final root = _logicalRoot(uri);
      final physical =
          _logicalToPhysical[root] ??
          _findGvfsMountPoint(
            host: uri.host ?? '',
            share: uri.share ?? '',
            port: uri.port,
          );
      final target = physical ?? root;
      final result = await Process.run('gio', ['mount', '-u', target]);
      if (result.exitCode == 0) {
        _logicalToPhysical.remove(root);
      }
      return;
    }
    if (PlatformPaths.isMacOS) {
      final root = _logicalRoot(uri);
      final physical =
          _logicalToPhysical[root] ??
          await _findMacSmbMountPoint(
            host: uri.host ?? '',
            share: uri.share ?? '',
            port: uri.port,
          );
      if (physical == null) {
        _logicalToPhysical.remove(root);
        return;
      }
      final result = await Process.run('diskutil', ['unmount', physical]);
      if (result.exitCode == 0) {
        _logicalToPhysical.remove(root);
        try {
          final dir = Directory(physical);
          if (dir.existsSync()) dir.deleteSync();
        } catch (e, st) {
          log.warn(
            'locations',
            'failed to remove SMB mount directory',
            error: e,
            stack: st,
          );
        }
      }
      return;
    }
  }

  static String _logicalRoot(LocationUri uri) {
    final buf = StringBuffer('smb://');
    final username = uri.username;
    if (username != null && username.isNotEmpty) {
      buf.write(Uri.encodeComponent(username));
      buf.write('@');
    }
    buf.write(uri.host);
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
            return ResolveError(t.errors.smbPortsNotSupportedOnWindows);
          }
          final unc = uri.toWindowsUnc();
          if (unc == null) {
            return ResolveError(t.errors.invalidSmbUri);
          }
          return ResolveSuccess(unc);
        }
        if (PlatformPaths.isLinux) {
          return _resolveSmbLinux(uri);
        }
        if (PlatformPaths.isMacOS) {
          return _resolveSmbMacOS(uri);
        }
        return const ResolveUnsupported();
      case LocationScheme.sftp:
        return _resolveSftp(uri);
      case LocationScheme.other:
        return const ResolveUnsupported();
    }
  }

  static Future<ResolveResult> resolveWithCredentials(
    String input,
    SmbCredentials credentials,
  ) async {
    final uri = LocationUri.parse(input);
    if (uri.scheme != LocationScheme.smb) return resolve(input);
    if (PlatformPaths.isLinux) {
      return _resolveSmbLinux(uri, credentials: credentials);
    }
    if (PlatformPaths.isMacOS) {
      return _resolveSmbMacOS(uri, credentials: credentials);
    }
    return resolve(input);
  }

  static Future<ResolveResult> resolveSftpWithCredentials(
    String input,
    SftpCredentials credentials,
  ) async {
    final uri = LocationUri.parse(input);
    if (uri.scheme != LocationScheme.sftp) return resolve(input);
    return _resolveSftp(uri, credentials: credentials);
  }

  static Future<ResolveResult> _resolveSftp(
    LocationUri uri, {
    SftpCredentials? credentials,
  }) async {
    final host = uri.host;
    if (host == null || host.isEmpty) {
      return ResolveError(t.errors.missingSftpHost);
    }
    try {
      final port = uri.port ?? 22;
      final username = credentials?.username.isNotEmpty == true
          ? credentials!.username
          : (uri.username ?? Platform.environment['USER'] ?? '');
      final outcome = await SftpSessionManager.openSession(
        host: host,
        port: port,
        username: username,
        credentials: credentials,
      );
      switch (outcome.status) {
        case SftpOpenStatus.authRequired:
          return const ResolveAuthenticationRequired();
        case SftpOpenStatus.error:
          return ResolveError(outcome.message ?? t.errors.sftpConnectFailed);
        case SftpOpenStatus.ok:
          final sessionId = outcome.sessionId;
          final hasExplicitPath = _sftpHasExplicitPath(uri.raw);
          final remote = !hasExplicitPath
              ? (sessionId == null
                    ? '/'
                    : SftpSessionManager.defaultRemotePath(sessionId, username))
              : (uri.path == null || uri.path!.isEmpty)
              ? '/'
              : uri.path!.startsWith('/')
              ? uri.path!
              : '/${uri.path}';
          return ResolveSuccess(
            SftpSessionManager.logicalPathForSession(
              host: host,
              port: port,
              user: username,
              remotePath: remote,
            ),
          );
      }
    } catch (e) {
      return ResolveError(t.errors.sftpError(error: e));
    }
  }

  static bool _sftpHasExplicitPath(String raw) {
    final lower = raw.toLowerCase();
    if (!lower.startsWith('sftp://')) return false;
    return raw.substring('sftp://'.length).contains('/');
  }

  static Future<ResolveResult> _resolveSmbLinux(
    LocationUri uri, {
    SmbCredentials? credentials,
  }) async {
    final host = uri.host;
    final share = uri.share;
    if (host == null || host.isEmpty) {
      return ResolveError(t.errors.missingSmbServer);
    }
    if (share == null || share.isEmpty) {
      return ResolveError(t.errors.missingSmbShare);
    }
    final mountTarget = StringBuffer('smb://');
    final username = credentials?.username.trim().isNotEmpty == true
        ? credentials!.username.trim()
        : uri.username;
    if (username != null && username.isNotEmpty) {
      mountTarget.write(Uri.encodeComponent(username));
      mountTarget.write('@');
    }
    mountTarget.write(host);
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

    final mountResult = credentials == null
        ? await Process.run('gio', ['mount', '-a', mountTarget.toString()])
        : await _runGioMountWithCredentials(
            mountTarget.toString(),
            credentials,
            hasUsername: username != null && username.isNotEmpty,
          );
    final mountOut = (mountResult.stdout as String? ?? '').trim();
    final mountErr = (mountResult.stderr as String? ?? '').trim();
    final mountText = '$mountOut\n$mountErr'.toLowerCase();
    final alreadyMounted = mountErr.toLowerCase().contains('already mounted');
    if (mountResult.exitCode != 0 && !alreadyMounted) {
      if (credentials == null && _looksLikeAuthPrompt(mountText)) {
        return const ResolveAuthenticationRequired();
      }
      final msg = mountErr.isNotEmpty ? mountErr : t.errors.gioMountFailed;
      return ResolveError(msg);
    }

    final mountPoint = _findGvfsMountPoint(
      host: host,
      share: share,
      port: uri.port,
    );
    if (mountPoint == null) {
      return ResolveError(t.errors.smbMountedShareNotFound);
    }
    return _resolvedSmbPath(uri, mountPoint);
  }

  static Future<ProcessResult> _runGioMountWithCredentials(
    String mountTarget,
    SmbCredentials credentials, {
    required bool hasUsername,
  }) async {
    final process = await Process.start('gio', ['mount', '-a', mountTarget]);
    final stdoutBuffer = StringBuffer();
    final stderrBuffer = StringBuffer();
    final stdoutSub = process.stdout
        .transform(utf8.decoder)
        .listen(stdoutBuffer.write);
    final stderrSub = process.stderr
        .transform(utf8.decoder)
        .listen(stderrBuffer.write);
    final username = credentials.username.trim();
    final password = credentials.password;
    process.stdin.write(
      hasUsername ? '\n$password\n' : '$username\n\n$password\n',
    );
    await process.stdin.close();
    final exitCode = await process.exitCode;
    await stdoutSub.cancel();
    await stderrSub.cancel();
    return ProcessResult(
      process.pid,
      exitCode,
      stdoutBuffer.toString(),
      stderrBuffer.toString(),
    );
  }

  static Future<ResolveResult> _resolveSmbMacOS(
    LocationUri uri, {
    SmbCredentials? credentials,
  }) async {
    final host = uri.host;
    final share = uri.share;
    if (host == null || host.isEmpty) {
      return ResolveError(t.errors.missingSmbServer);
    }
    if (share == null || share.isEmpty) {
      return ResolveError(t.errors.missingSmbShare);
    }

    final existingMountPoint = await _findMacSmbMountPoint(
      host: host,
      share: share,
      port: uri.port,
    );
    if (existingMountPoint != null) {
      return _resolvedSmbPath(uri, existingMountPoint);
    }

    final username = credentials?.username.trim().isNotEmpty == true
        ? credentials!.username.trim()
        : uri.username;
    final smbUrl = StringBuffer('//');
    if (username != null && username.isNotEmpty) {
      smbUrl.write(Uri.encodeComponent(username));
      if (credentials != null) {
        smbUrl.write(':');
        smbUrl.write(Uri.encodeComponent(credentials.password));
      }
      smbUrl.write('@');
    }
    smbUrl.write(host);
    if (uri.port != null) {
      smbUrl.write(':');
      smbUrl.write(uri.port);
    }
    smbUrl.write('/');
    smbUrl.write(share);

    final mountPoint = _allocateMacMountPoint(share);
    try {
      Directory(mountPoint).createSync(recursive: true);
    } catch (e) {
      return ResolveError(
        t.errors.failedToCreatePath(path: mountPoint, error: e),
      );
    }

    final args = <String>[];
    if (credentials == null) args.add('-N');
    args.addAll([smbUrl.toString(), mountPoint]);

    final result = await Process.run('mount_smbfs', args);
    if (result.exitCode != 0) {
      try {
        final dir = Directory(mountPoint);
        if (dir.existsSync() && dir.listSync().isEmpty) dir.deleteSync();
      } catch (e, st) {
        log.warn(
          'locations',
          'failed to remove SMB mount directory',
          error: e,
          stack: st,
        );
      }
      final err = (result.stderr as String? ?? '').trim();
      final lower = err.toLowerCase();
      final authLike =
          lower.contains('authentication') ||
          lower.contains('permission denied') ||
          lower.contains('not permitted') ||
          lower.contains('password') ||
          lower.contains('credentials');
      if (credentials == null && authLike) {
        return const ResolveAuthenticationRequired();
      }
      return ResolveError(
        err.isNotEmpty ? err : t.errors.mountSmbfsFailed(code: result.exitCode),
      );
    }
    return _resolvedSmbPath(uri, mountPoint);
  }

  static String _allocateMacMountPoint(String share) {
    final safeShare = share.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    var candidate = '/Volumes/$safeShare';
    var n = 1;
    while (Directory(candidate).existsSync()) {
      candidate = '/Volumes/$safeShare-$n';
      n++;
    }
    return candidate;
  }

  static Future<String?> _findMacSmbMountPoint({
    required String host,
    required String share,
    int? port,
  }) async {
    final result = await Process.run('mount', const []);
    if (result.exitCode != 0) return null;
    final wantedHost = host.toLowerCase();
    for (final line in (result.stdout as String).split('\n')) {
      if (!line.contains('(smbfs')) continue;
      final onIdx = line.indexOf(' on ');
      if (onIdx < 0) continue;
      final source = line.substring(0, onIdx);
      if (!source.startsWith('//')) continue;
      final rest = source.substring(2);
      final at = rest.lastIndexOf('@');
      final hostShare = at >= 0 ? rest.substring(at + 1) : rest;
      final slash = hostShare.indexOf('/');
      if (slash < 0) continue;
      var hostPart = hostShare.substring(0, slash).toLowerCase();
      final sharePart = hostShare.substring(slash + 1);
      int? linePort;
      final colon = hostPart.indexOf(':');
      if (colon >= 0) {
        linePort = int.tryParse(hostPart.substring(colon + 1));
        hostPart = hostPart.substring(0, colon);
      }
      if (hostPart != wantedHost) continue;
      if (sharePart != share) continue;
      if (port != null && linePort != null && port != linePort) continue;
      final tail = line.substring(onIdx + 4);
      final parenIdx = tail.lastIndexOf(' (');
      final mountPath = parenIdx < 0 ? tail : tail.substring(0, parenIdx);
      return mountPath;
    }
    return null;
  }

  static bool _looksLikeAuthPrompt(String text) {
    return text.contains('authentication required') ||
        text.contains('password') ||
        text.contains('user and password') ||
        text.contains('access denied') ||
        text.contains('permission denied') ||
        text.contains('logon failure');
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
      } catch (e, st) {
        log.warn(
          'locations',
          'failed to prune stale mount mapping',
          error: e,
          stack: st,
        );
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
    } catch (e, st) {
      log.warn('locations', 'failed to read process uid', error: e, stack: st);
    }
    return null;
  }
}
