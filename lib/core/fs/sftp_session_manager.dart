import '../../features/locations/location_resolver.dart'
    show SftpCredentials, SftpAuthMethod;
import '../../features/locations/location_uri.dart';
import 'waydir_core_loader.dart';

enum SftpOpenStatus { ok, authRequired, error }

class SftpOpenOutcome {
  final SftpOpenStatus status;
  final int? sessionId;
  final String? message;

  const SftpOpenOutcome({required this.status, this.sessionId, this.message});
}

class SftpSessionRecord {
  final String root;
  final String host;
  final int port;
  final String user;
  final int sessionId;

  const SftpSessionRecord({
    required this.root,
    required this.host,
    required this.port,
    required this.user,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() => {
    'root': root,
    'host': host,
    'port': port,
    'user': user,
    'sessionId': sessionId,
  };

  factory SftpSessionRecord.fromJson(Map<String, dynamic> json) =>
      SftpSessionRecord(
        root: json['root'] as String,
        host: json['host'] as String,
        port: json['port'] as int,
        user: json['user'] as String,
        sessionId: json['sessionId'] as int,
      );
}

/// Singleton zarządzający aktywnymi sesjami SFTP.
///
/// "Root" sesji to logical URI postaci `sftp://user@host:port` — identyfikuje
/// sesję dla UI (sidebar) i służy do routingu ścieżek na `sessionId` Rust core.
class SftpSessionManager {
  SftpSessionManager._();

  static final Map<String, SftpSessionRecord> _byRoot = {};

  static List<String> activeRoots() => _byRoot.keys.toList();

  static SftpSessionRecord? recordFor(String anyPath) {
    if (!anyPath.startsWith('sftp://')) return null;
    final uri = LocationUri.parse(anyPath);
    final root = rootOf(uri);

    return _byRoot[root];
  }

  /// Zamienia logical SFTP URI na ścieżkę po stronie serwera (`/foo/bar`).
  static String remotePath(String anyPath) {
    if (!anyPath.startsWith('sftp://')) return anyPath;
    final uri = LocationUri.parse(anyPath);
    final p = uri.path ?? '';

    return p.isEmpty ? '/' : '/$p';
  }

  /// Buduje logical URI rootu dla danego LocationUri sftp.
  static String rootOf(LocationUri uri) {
    final buf = StringBuffer('sftp://');
    final user = uri.username;
    if (user != null && user.isNotEmpty) {
      buf.write(Uri.encodeComponent(user));
      buf.write('@');
    }
    buf.write(uri.host ?? '');
    if (uri.port != null && uri.port != 22) {
      buf.write(':');
      buf.write(uri.port);
    }

    return buf.toString();
  }

  static String buildLogicalPath({
    required String host,
    required int port,
    required String user,
    String remotePath = '/',
  }) {
    final buf = StringBuffer('sftp://');
    if (user.isNotEmpty) {
      buf.write(Uri.encodeComponent(user));
      buf.write('@');
    }
    buf.write(host);
    if (port != 22) {
      buf.write(':');
      buf.write(port);
    }
    final trimmed = remotePath.replaceFirst(RegExp('^/+'), '');
    if (trimmed.isNotEmpty) {
      buf.write('/');
      buf.write(trimmed);
    }

    return buf.toString();
  }

  static String logicalPathForRecord(
    SftpSessionRecord record, {
    String remotePath = '/',
  }) {
    return buildLogicalPath(
      host: record.host,
      port: record.port,
      user: record.user,
      remotePath: remotePath,
    );
  }

  static String logicalPathForSession({
    required String host,
    required int port,
    required String user,
    String remotePath = '/',
  }) {
    return buildLogicalPath(
      host: host,
      port: port,
      user: user,
      remotePath: remotePath,
    );
  }

  static String defaultRemotePath(int sessionId, String user) {
    final home = WaydirCoreLoader.sftpRealPath(sessionId, '.');
    if (home != null && home.startsWith('/')) {
      final stat = WaydirCoreLoader.sftpStat(sessionId, home);
      if (stat != null && stat.exists && stat.isDir) {
        return home;
      }
    }
    final candidates = [
      if (user.isNotEmpty) '/home/$user',
      if (user.isNotEmpty) '/Users/$user',
    ];
    for (final path in candidates) {
      final stat = WaydirCoreLoader.sftpStat(sessionId, path);
      if (stat != null && stat.exists && stat.isDir) {
        return path;
      }
    }

    return '/';
  }

  static Future<SftpOpenOutcome> openSession({
    required String host,
    required int port,
    required String username,
    SftpCredentials? credentials,
  }) async {
    final user = credentials?.username.isNotEmpty == true
        ? credentials!.username
        : username;
    final root = buildLogicalPath(host: host, port: port, user: user);
    final existing = _byRoot[root];
    if (existing != null) {
      return SftpOpenOutcome(
        status: SftpOpenStatus.ok,
        sessionId: existing.sessionId,
      );
    }

    int authKind;
    String? password;
    String? keyPath;
    String? passphrase;
    if (credentials == null) {
      authKind = 0; // auto
    } else {
      switch (credentials.method) {
        case SftpAuthMethod.auto:
          authKind = 0;
          break;
        case SftpAuthMethod.password:
          authKind = 1;
          password = credentials.password;
          break;
        case SftpAuthMethod.privateKey:
          authKind = 2;
          keyPath = credentials.privateKeyPath;
          passphrase = credentials.passphrase;
          break;
      }
    }

    final result = WaydirCoreLoader.sftpOpen(
      host: host,
      port: port,
      user: user,
      authKind: authKind,
      password: password,
      keyPath: keyPath,
      passphrase: passphrase,
    );

    if (result.isOk) {
      _byRoot[root] = SftpSessionRecord(
        root: root,
        host: host,
        port: port,
        user: user,
        sessionId: result.sessionId,
      );

      return SftpOpenOutcome(
        status: SftpOpenStatus.ok,
        sessionId: result.sessionId,
      );
    }
    if (result.isAuthRequired) {
      return const SftpOpenOutcome(status: SftpOpenStatus.authRequired);
    }

    return SftpOpenOutcome(
      status: SftpOpenStatus.error,
      message: result.errorMessage,
    );
  }

  static void closeRoot(String root) {
    final rec = _byRoot.remove(root);
    if (rec != null) {
      WaydirCoreLoader.sftpClose(rec.sessionId);
    }
  }

  /// Migawka aktywnych sesji do przekazania do isolate'a roboczego.
  /// Worker nie otwiera nowych połączeń — używa wpisów z migawki do
  /// resolvowania `sessionId` po ścieżkach URI.
  static List<SftpSessionRecord> exportRecords() => _byRoot.values.toList();

  /// Wstrzykuje wpisy sesji w bieżącym isolate (do użycia w isolate'cie
  /// roboczym, gdzie statyczna mapa jest pusta). Nie otwiera nowych sesji.
  static void seedRecords(Iterable<SftpSessionRecord> records) {
    for (final rec in records) {
      _byRoot[rec.root] = rec;
    }
  }

  static void debugReset() {
    for (final rec in _byRoot.values) {
      WaydirCoreLoader.sftpClose(rec.sessionId);
    }
    _byRoot.clear();
  }
}
