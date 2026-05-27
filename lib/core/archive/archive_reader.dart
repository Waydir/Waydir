import 'dart:io';
import 'package:archive/archive_io.dart';

import '../../i18n/strings.g.dart';

class ArchiveReadException implements Exception {
  final String message;
  const ArchiveReadException(this.message);
  @override
  String toString() => message;
}

class ArchiveEntry {
  final String path;
  final int size;
  final bool isDir;
  final int mtimeSeconds;

  const ArchiveEntry({
    required this.path,
    required this.size,
    required this.isDir,
    required this.mtimeSeconds,
  });
}

class ArchiveReader {
  ArchiveReader._();

  static String _normalize(String path) {
    var p = path.replaceAll('\\', '/');
    while (p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    while (p.startsWith('./')) {
      p = p.substring(2);
    }
    return p;
  }

  static bool _isUnsafe(String path) {
    if (path.startsWith('/')) return true;
    for (final seg in path.split('/')) {
      if (seg == '..') return true;
    }
    return false;
  }

  static Archive _readArchive(String archivePath) {
    final lower = archivePath.toLowerCase();
    try {
      if (lower.endsWith('.zip') ||
          lower.endsWith('.jar') ||
          lower.endsWith('.war') ||
          lower.endsWith('.apk') ||
          lower.endsWith('.xpi') ||
          lower.endsWith('.whl') ||
          lower.endsWith('.crx') ||
          lower.endsWith('.epub')) {
        return ZipDecoder().decodeStream(InputFileStream(archivePath));
      } else if (lower.endsWith('.tar')) {
        return TarDecoder().decodeStream(InputFileStream(archivePath));
      }
      final bytes = File(archivePath).readAsBytesSync();
      if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
        final decoded = GZipDecoder().decodeBytes(bytes);
        return TarDecoder().decodeBytes(decoded);
      } else if (lower.endsWith('.tar.bz2') ||
          lower.endsWith('.tbz2') ||
          lower.endsWith('.tbz')) {
        final decoded = BZip2Decoder().decodeBytes(bytes);
        return TarDecoder().decodeBytes(decoded);
      } else if (lower.endsWith('.tar.xz') || lower.endsWith('.txz')) {
        final decoded = XZDecoder().decodeBytes(bytes);
        return TarDecoder().decodeBytes(decoded);
      }
      throw ArchiveReadException(t.errors.unsupportedArchiveFormat);
    } catch (e) {
      throw ArchiveReadException(t.errors.archiveReadFailed(error: e));
    }
  }

  static List<ArchiveEntry> listEntries(String archivePath) {
    final archive = _readArchive(archivePath);
    final entries = <ArchiveEntry>[];
    for (final entry in archive) {
      final raw = entry.name;
      final isDir = entry.isFile == false || raw.endsWith('/');
      final name = _normalize(raw);
      if (name.isNotEmpty) {
        entries.add(
          ArchiveEntry(
            path: name,
            size: entry.size,
            isDir: isDir,
            mtimeSeconds: entry.lastModTime,
          ),
        );
      }
    }
    return entries;
  }

  static void extractEntry(
    String archivePath,
    String innerPath,
    String destPath,
  ) {
    final archive = _readArchive(archivePath);
    final target = _normalize(innerPath);
    var found = false;

    for (final entry in archive) {
      final raw = entry.name;
      if (_normalize(raw) == target) {
        found = true;
        if (entry.isFile) {
          final file = File(destPath);
          file.parent.createSync(recursive: true);
          final data = entry.content as List<int>;
          file.writeAsBytesSync(data);
        }
        break;
      }
    }
    if (!found) {
      throw ArchiveReadException(
        t.errors.archiveEntryNotFound(path: innerPath),
      );
    }
  }

  static String extractTree(
    String archivePath,
    String innerPath,
    String stagingDir,
  ) {
    final archive = _readArchive(archivePath);
    final target = _normalize(innerPath);
    final baseName = target.contains('/')
        ? target.substring(target.lastIndexOf('/') + 1)
        : target;
    final stagedRoot = '$stagingDir/$baseName';
    var found = false;

    for (final entry in archive) {
      final raw = entry.name;
      final epath = _normalize(raw);
      String dest;

      if (epath == target) {
        dest = stagedRoot;
      } else if (epath.startsWith('$target/')) {
        dest = '$stagedRoot/${epath.substring(target.length + 1)}';
      } else {
        continue;
      }

      found = true;
      final isDir = entry.isFile == false || raw.endsWith('/');
      if (isDir) {
        Directory(dest).createSync(recursive: true);
        continue;
      }

      final file = File(dest);
      file.parent.createSync(recursive: true);
      final data = entry.content as List<int>;
      file.writeAsBytesSync(data);
    }

    if (!found) {
      throw ArchiveReadException(
        t.errors.archiveEntryNotFound(path: innerPath),
      );
    }
    return stagedRoot;
  }

  static void extractAll(
    String archivePath,
    String destDir, {
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    extractAllResolved(
      archivePath,
      (epath, isDir) => '$destDir/$epath',
      onEntry: onEntry,
      isCancelled: isCancelled,
    );
  }

  static void extractAllResolved(
    String archivePath,
    String? Function(String epath, bool isDir) resolveDest, {
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    final archive = _readArchive(archivePath);

    for (final entry in archive) {
      if (isCancelled != null && isCancelled()) break;

      final raw = entry.name;
      final epath = _normalize(raw);
      if (epath.isEmpty || _isUnsafe(epath)) continue;

      final isDir = entry.isFile == false || raw.endsWith('/');
      onEntry?.call(epath);

      final dest = resolveDest(epath, isDir);
      if (dest == null) continue;

      if (isDir) {
        Directory(dest).createSync(recursive: true);
        continue;
      }

      final file = File(dest);
      file.parent.createSync(recursive: true);
      final data = entry.content as List<int>;
      file.writeAsBytesSync(data);
    }
  }
}
