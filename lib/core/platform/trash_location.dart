import 'dart:io';

import 'package:path/path.dart' as p;

import '../fs/waydir_core_loader.dart';
import 'platform_paths.dart';

/// Virtual path that represents the user's trash / recycle bin.
///
/// The real on-disk location (e.g. `~/.local/share/Trash/files` on Linux or
/// the per-drive `$Recycle.Bin` on Windows) is never shown to the user when
/// they reach the trash through the sidebar — instead this sentinel is used
/// and rendered as a friendly label. Navigating manually to the real path
/// keeps working as an ordinary directory.
///
/// Sub-folders inside the trash keep the alias as a prefix, e.g.
/// `::trash/<deleted-item>/<sub-dir>`.
const String kTrashPath = '::trash';

class TrashAccessDeniedException implements Exception {
  const TrashAccessDeniedException();
}

bool isTrashPath(String path) =>
    path == kTrashPath || path.startsWith('$kTrashPath/');

/// Returns the virtual parent of a trash path, never escaping above the
/// trash root itself.
String trashParentOf(String path) {
  if (path == kTrashPath) return kTrashPath;
  final i = path.lastIndexOf('/');
  if (i <= kTrashPath.length - 1) return kTrashPath;
  return path.substring(0, i);
}

/// A top-level item that lives in the trash and can be restored or purged.
class TrashEntry {
  /// Stable virtual path: `::trash/<onDiskName>`.
  final String virtualPath;

  /// Name shown to the user (original basename when known).
  final String displayName;

  /// Real on-disk location of the trashed data.
  final String realDataPath;

  /// Original location the item was deleted from, if recorded.
  final String? originalPath;

  final DateTime deletedAt;
  final int size;
  final bool isDirectory;

  /// Linux only: path of the `.trashinfo` metadata file.
  final String? infoPath;

  /// Native trash identifier used for restore/purge on supported platforms.
  final String? nativeId;

  const TrashEntry({
    required this.virtualPath,
    required this.displayName,
    required this.realDataPath,
    required this.deletedAt,
    required this.size,
    required this.isDirectory,
    this.originalPath,
    this.infoPath,
    this.nativeId,
  });
}

/// Listing of a directory inside the trash (a sub-folder of a trashed item).
class TrashChild {
  final String displayName;
  final String virtualPath;
  final String realPath;
  final bool isDirectory;
  final int size;
  final DateTime modified;

  const TrashChild({
    required this.displayName,
    required this.virtualPath,
    required this.realPath,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });
}

/// Single entry point for the unified trash, regardless of platform.
class TrashRepository {
  TrashRepository._();
  static final TrashRepository instance = TrashRepository._();

  /// Maps `::trash/<seg0>` -> real on-disk base path, so descending into a
  /// sub-folder can still resolve the real location after a fresh load.
  final Map<String, String> _realBase = {};

  /// Whether restoring entries is supported on this platform.
  bool get canRestore => !PlatformPaths.isMacOS;

  Future<List<TrashEntry>> listRoot() async {
    if (PlatformPaths.isWindows) return _listWindowsRoot();
    if (PlatformPaths.isLinux) return _listFreedesktopRoot();
    if (PlatformPaths.isMacOS) return _listMacRoot();
    return const [];
  }

  Future<List<TrashEntry>> _listWindowsRoot() async {
    final items = WaydirCoreLoader.trashList();
    final out = <TrashEntry>[];
    for (final e in items) {
      final vpath = '$kTrashPath/${e.id}';
      _realBase[vpath] = e.id;
      out.add(
        TrashEntry(
          virtualPath: vpath,
          displayName: e.name,
          realDataPath: '',
          originalPath: e.originalPath.isEmpty ? null : e.originalPath,
          deletedAt: e.deletedAt,
          size: e.size,
          isDirectory: e.isDirectory,
          nativeId: e.id,
        ),
      );
    }
    out.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return out;
  }

  Future<List<TrashEntry>> _listFreedesktopRoot() async {
    final filesDir = PlatformPaths.trashPath;
    if (filesDir == null) return const [];
    final dir = Directory(filesDir);
    if (!dir.existsSync()) return const [];
    final infoDir = p.join(p.dirname(filesDir), 'info');
    final out = <TrashEntry>[];
    for (final ent in dir.listSync(followLinks: false)) {
      final name = PlatformPaths.fileName(ent.path);
      final isDir = ent is Directory;
      FileStat stat;
      try {
        stat = ent.statSync();
      } catch (_) {
        continue;
      }
      final info = _readTrashInfo(p.join(infoDir, '$name.trashinfo'));
      final vpath = '$kTrashPath/$name';
      _realBase[vpath] = ent.path;
      out.add(
        TrashEntry(
          virtualPath: vpath,
          displayName: info?.originalPath == null
              ? name
              : p.basename(info!.originalPath!),
          realDataPath: ent.path,
          originalPath: info?.originalPath,
          deletedAt: info?.deletedAt ?? stat.modified,
          size: stat.size,
          isDirectory: isDir,
          infoPath: info == null ? null : p.join(infoDir, '$name.trashinfo'),
        ),
      );
    }
    out.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return out;
  }

  Future<List<TrashEntry>> _listMacRoot() async {
    final filesDir = PlatformPaths.trashPath;
    if (filesDir == null) return const [];
    final dir = Directory(filesDir);
    if (!dir.existsSync()) return const [];
    final out = <TrashEntry>[];
    late final List<FileSystemEntity> entries;
    try {
      entries = dir.listSync(followLinks: false);
    } on FileSystemException catch (e) {
      final code = e.osError?.errorCode;
      if (code == 1 || code == 13) {
        throw const TrashAccessDeniedException();
      }
      rethrow;
    }
    for (final ent in entries) {
      final name = PlatformPaths.fileName(ent.path);
      if (name == '.DS_Store') continue;
      FileStat stat;
      try {
        stat = ent.statSync();
      } catch (_) {
        continue;
      }
      final vpath = '$kTrashPath/$name';
      _realBase[vpath] = ent.path;
      out.add(
        TrashEntry(
          virtualPath: vpath,
          displayName: name,
          realDataPath: ent.path,
          deletedAt: stat.modified,
          size: stat.size,
          isDirectory: ent is Directory,
        ),
      );
    }
    out.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return out;
  }

  /// Resolves a virtual trash path (deeper than the root) to its real
  /// on-disk directory. Re-lists the root when the mapping is unknown
  /// (e.g. navigated via history without visiting the root first).
  Future<String?> _resolveRealDir(String virtualPath) async {
    final rest = virtualPath.substring(kTrashPath.length + 1);
    final segs = rest.split('/');
    final seg0Key = '$kTrashPath/${segs.first}';
    var base = _realBase[seg0Key];
    if (base == null) {
      await listRoot();
      base = _realBase[seg0Key];
    }
    if (base == null) return null;
    if (segs.length == 1) return base;
    return p.joinAll([base, ...segs.sublist(1)]);
  }

  Future<List<TrashChild>> listSub(String virtualPath) async {
    if (PlatformPaths.isWindows) return const [];
    final realDir = await _resolveRealDir(virtualPath);
    if (realDir == null) return const [];
    final dir = Directory(realDir);
    if (!dir.existsSync()) return const [];
    final out = <TrashChild>[];
    for (final ent in dir.listSync(followLinks: false)) {
      final name = PlatformPaths.fileName(ent.path);
      FileStat stat;
      try {
        stat = ent.statSync();
      } catch (_) {
        continue;
      }
      out.add(
        TrashChild(
          displayName: name,
          virtualPath: '$virtualPath/$name',
          realPath: ent.path,
          isDirectory: ent is Directory,
          size: stat.size,
          modified: stat.modified,
        ),
      );
    }
    return out;
  }

  Future<void> restore(TrashEntry e) async {
    if (PlatformPaths.isWindows) {
      final id = e.nativeId;
      if (id != null) {
        final fails = WaydirCoreLoader.trashRestore([id]);
        if (fails.isNotEmpty) {
          throw FileSystemException(fails.first.message);
        }
      }
      return;
    }
    final original = e.originalPath;
    if (original == null) return;
    final target = p.isAbsolute(original)
        ? original
        : p.join(PlatformPaths.homePath, original);
    final parent = Directory(p.dirname(target));
    if (!parent.existsSync()) parent.createSync(recursive: true);
    if (e.isDirectory) {
      Directory(e.realDataPath).renameSync(target);
    } else {
      File(e.realDataPath).renameSync(target);
    }
    final info = e.infoPath;
    if (info != null) {
      final f = File(info);
      if (f.existsSync()) f.deleteSync();
    }
    _realBase.remove(e.virtualPath);
  }

  Future<void> deletePermanently(TrashEntry e) async {
    if (PlatformPaths.isWindows) {
      final id = e.nativeId;
      if (id != null) {
        final fails = WaydirCoreLoader.trashPurge([id]);
        if (fails.isNotEmpty) {
          throw FileSystemException(fails.first.message);
        }
      }
      return;
    }
    if (e.isDirectory) {
      final d = Directory(e.realDataPath);
      if (d.existsSync()) d.deleteSync(recursive: true);
    } else {
      final f = File(e.realDataPath);
      if (f.existsSync()) f.deleteSync();
    }
    final info = e.infoPath;
    if (info != null) {
      final f = File(info);
      if (f.existsSync()) f.deleteSync();
    }
    _realBase.remove(e.virtualPath);
  }

  _TrashInfo? _readTrashInfo(String path) {
    try {
      final f = File(path);
      if (!f.existsSync()) return null;
      String? rawPath;
      String? rawDate;
      for (final line in f.readAsLinesSync()) {
        if (line.startsWith('Path=')) {
          rawPath = line.substring(5);
        } else if (line.startsWith('DeletionDate=')) {
          rawDate = line.substring(13);
        }
      }
      if (rawPath == null) return null;
      String original;
      try {
        original = Uri.decodeFull(rawPath);
      } catch (_) {
        original = rawPath;
      }
      return _TrashInfo(
        originalPath: original,
        deletedAt: rawDate == null ? null : DateTime.tryParse(rawDate),
      );
    } catch (_) {
      return null;
    }
  }
}

class _TrashInfo {
  final String? originalPath;
  final DateTime? deletedAt;
  const _TrashInfo({this.originalPath, this.deletedAt});
}
