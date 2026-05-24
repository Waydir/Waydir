import '../../core/platform/platform_paths.dart';
import '../../core/platform/trash_location.dart';

enum LocationScheme { local, windowsUnc, smb, trash, other }

class LocationUri {
  final LocationScheme scheme;
  final String raw;
  final String? host;
  final int? port;
  final String? share;
  final String? path;

  const LocationUri._({
    required this.scheme,
    required this.raw,
    this.host,
    this.port,
    this.share,
    this.path,
  });

  bool get isNetwork =>
      scheme == LocationScheme.smb || scheme == LocationScheme.windowsUnc;

  bool get isLocal => scheme == LocationScheme.local;

  String get displayLabel {
    switch (scheme) {
      case LocationScheme.smb:
        final h = host ?? '';
        final s = share ?? '';
        final p = (path == null || path!.isEmpty) ? '' : '/$path';
        if (s.isEmpty) return h.isEmpty ? raw : h;
        return '$h/$s$p';
      case LocationScheme.windowsUnc:
        return raw;
      case LocationScheme.trash:
        return 'Trash';
      case LocationScheme.local:
      case LocationScheme.other:
        return PlatformPaths.fileName(raw).isEmpty ? raw : PlatformPaths.fileName(raw);
    }
  }

  /// Convert smb:// URI to a Windows UNC path, e.g.
  /// smb://host/share/sub → \\host\share\sub
  String? toWindowsUnc() {
    if (scheme != LocationScheme.smb) return null;
    if (host == null || host!.isEmpty) return null;
    final buf = StringBuffer(r'\\');
    buf.write(host);
    if (share != null && share!.isNotEmpty) {
      buf.write(r'\');
      buf.write(share);
      if (path != null && path!.isNotEmpty) {
        buf.write(r'\');
        buf.write(path!.replaceAll('/', r'\'));
      }
    }
    return buf.toString();
  }

  /// Convert a Windows UNC path to an smb:// URI.
  String? toSmbUri() {
    if (scheme == LocationScheme.smb) return raw;
    if (scheme != LocationScheme.windowsUnc) return null;
    if (host == null || host!.isEmpty) return null;
    final buf = StringBuffer('smb://');
    buf.write(host);
    if (share != null && share!.isNotEmpty) {
      buf.write('/');
      buf.write(share);
      if (path != null && path!.isNotEmpty) {
        buf.write('/');
        buf.write(path!.replaceAll(r'\', '/'));
      }
    }
    return buf.toString();
  }

  static LocationUri parse(String input) {
    final s = input.trim();
    if (s.isEmpty) {
      return LocationUri._(scheme: LocationScheme.local, raw: s);
    }
    if (isTrashPath(s)) {
      return LocationUri._(scheme: LocationScheme.trash, raw: s);
    }
    final lower = s.toLowerCase();
    if (lower.startsWith('smb://')) {
      return _parseSmb(s);
    }
    if (s.startsWith(r'\\') &&
        !s.startsWith(r'\\?\') &&
        !s.startsWith(r'\\.\')) {
      return _parseUnc(s);
    }
    // Other URI schemes we don't handle natively but want to preserve.
    final schemeMatch = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://').firstMatch(s);
    if (schemeMatch != null) {
      return LocationUri._(scheme: LocationScheme.other, raw: s);
    }
    return LocationUri._(scheme: LocationScheme.local, raw: s);
  }

  static LocationUri _parseSmb(String s) {
    final rest = s.substring('smb://'.length);
    final parts = rest.split('/');
    final authority = parts.isNotEmpty ? parts[0] : '';
    String host = authority;
    int? port;
    final colon = authority.lastIndexOf(':');
    if (colon > 0 && colon < authority.length - 1) {
      final maybePort = int.tryParse(authority.substring(colon + 1));
      if (maybePort != null) {
        host = authority.substring(0, colon);
        port = maybePort;
      }
    }
    final share = parts.length > 1 ? parts[1] : null;
    final path = parts.length > 2 ? parts.sublist(2).join('/') : null;
    return LocationUri._(
      scheme: LocationScheme.smb,
      raw: s,
      host: host,
      port: port,
      share: share,
      path: path,
    );
  }

  static LocationUri _parseUnc(String s) {
    final rest = s.substring(2);
    final parts = rest.split(RegExp(r'[\\/]+')).where((p) => p.isNotEmpty).toList();
    final host = parts.isNotEmpty ? parts[0] : '';
    final share = parts.length > 1 ? parts[1] : null;
    final path = parts.length > 2 ? parts.sublist(2).join(r'\') : null;
    return LocationUri._(
      scheme: LocationScheme.windowsUnc,
      raw: s,
      host: host,
      share: share,
      path: path,
    );
  }
}
