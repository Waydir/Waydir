import 'dart:io';

import '../logging/app_logger.dart';
import '../platform/platform_paths.dart';

/// Resolves numeric uids/gids to their account names by reading the local
/// `/etc/passwd` and `/etc/group` once and caching the result. Network-backed
/// accounts (LDAP, …) are not covered and fall back to the numeric id, which is
/// acceptable for a display-only "Owner" column.
class PasswdLookup {
  PasswdLookup._();

  static Map<int, String>? _users;
  static Map<int, String>? _groups;

  static Map<int, String> _parse(String path, int idField) {
    final out = <int, String>{};
    try {
      final lines = File(path).readAsLinesSync();
      for (final line in lines) {
        if (line.isEmpty || line.startsWith('#')) continue;
        final parts = line.split(':');
        if (parts.length <= idField) continue;
        final id = int.tryParse(parts[idField]);
        if (id != null) out[id] = parts[0];
      }
    } catch (e, st) {
      log.warn('platform', 'passwd/group lookup failed', error: e, stack: st);
    }
    return out;
  }

  static String userName(int uid) {
    if (!PlatformPaths.isWindows) {
      final users = _users ??= _parse('/etc/passwd', 2);
      final name = users[uid];
      if (name != null) return name;
    }
    return uid == 0 ? '' : '$uid';
  }

  static String groupName(int gid) {
    if (!PlatformPaths.isWindows) {
      final groups = _groups ??= _parse('/etc/group', 2);
      final name = groups[gid];
      if (name != null) return name;
    }
    return gid == 0 ? '' : '$gid';
  }
}
