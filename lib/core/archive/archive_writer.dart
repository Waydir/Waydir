import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import 'archive_reader.dart' show ArchiveReadException, ArchiveReader;

enum ArchiveFormat { zip, tar, tarGz, tarBz2, tarXz }

enum CompressionLevel { store, normal, maximum }

extension ArchiveFormatInfo on ArchiveFormat {
  String get extension => switch (this) {
    ArchiveFormat.zip => 'zip',
    ArchiveFormat.tar => 'tar',
    ArchiveFormat.tarGz => 'tar.gz',
    ArchiveFormat.tarBz2 => 'tar.bz2',
    ArchiveFormat.tarXz => 'tar.xz',
  };

  String get label => switch (this) {
    ArchiveFormat.zip => 'ZIP',
    ArchiveFormat.tar => 'TAR',
    ArchiveFormat.tarGz => 'TAR.GZ',
    ArchiveFormat.tarBz2 => 'TAR.BZ2',
    ArchiveFormat.tarXz => 'TAR.XZ',
  };
}

ArchiveFormat? archiveFormatFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
    return ArchiveFormat.tarGz;
  }
  if (lower.endsWith('.tar.bz2') ||
      lower.endsWith('.tbz2') ||
      lower.endsWith('.tbz')) {
    return ArchiveFormat.tarBz2;
  }
  if (lower.endsWith('.tar.xz') || lower.endsWith('.txz')) {
    return ArchiveFormat.tarXz;
  }
  if (lower.endsWith('.tar')) return ArchiveFormat.tar;
  if (lower.endsWith('.zip') ||
      lower.endsWith('.jar') ||
      lower.endsWith('.war') ||
      lower.endsWith('.apk') ||
      lower.endsWith('.xpi') ||
      lower.endsWith('.whl') ||
      lower.endsWith('.crx') ||
      lower.endsWith('.epub')) {
    return ArchiveFormat.zip;
  }
  return null;
}

class _PlannedEntry {
  final String absPath;
  final String archiveName;
  final bool isDir;
  final int size;
  const _PlannedEntry(this.absPath, this.archiveName, this.isDir, this.size);
}

class ArchiveWriter {
  ArchiveWriter._();

  static List<_PlannedEntry> _plan(List<String> sources) {
    final out = <_PlannedEntry>[];
    for (final src in sources) {
      final base = p.dirname(src);
      final type = FileSystemEntity.typeSync(src);
      if (type == FileSystemEntityType.notFound) continue;
      if (type == FileSystemEntityType.directory) {
        out.add(_PlannedEntry(src, p.relative(src, from: base), true, 0));
        for (final e in Directory(
          src,
        ).listSync(recursive: true, followLinks: false)) {
          final isDir = e is Directory;
          int size = 0;
          if (!isDir) {
            try {
              size = File(e.path).lengthSync();
            } catch (_) {
              continue;
            }
          }
          out.add(
            _PlannedEntry(e.path, p.relative(e.path, from: base), isDir, size),
          );
        }
      } else {
        int size = 0;
        try {
          size = File(src).lengthSync();
        } catch (_) {
          continue;
        }
        out.add(_PlannedEntry(src, p.relative(src, from: base), false, size));
      }
    }
    return out;
  }

  static int planCount(List<String> sources) => _plan(sources).length;

  static void create(
    List<String> sources,
    String destPath,
    ArchiveFormat format,
    CompressionLevel level, {
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    final archive = Archive();
    final planned = _plan(sources);

    for (final entry in planned) {
      if (isCancelled != null && isCancelled()) return;

      final name = entry.isDir ? '${entry.archiveName}/' : entry.archiveName;
      if (entry.isDir) {
        final archiveFile = ArchiveFile.directory(name);
        archive.add(archiveFile);
      } else {
        final bytes = File(entry.absPath).readAsBytesSync();
        final archiveFile = ArchiveFile.bytes(name, bytes);
        archive.add(archiveFile);
      }
      onEntry?.call(entry.archiveName);
    }

    if (isCancelled != null && isCancelled()) return;

    List<int> encoded;
    try {
      switch (format) {
        case ArchiveFormat.zip:
          final levelInt = level == CompressionLevel.store
              ? 0
              : (level == CompressionLevel.maximum ? 9 : 6);
          encoded = ZipEncoder().encode(archive, level: levelInt);
        case ArchiveFormat.tar:
          encoded = TarEncoder().encode(archive);
        case ArchiveFormat.tarGz:
          final tarBytes = TarEncoder().encode(archive);
          encoded = GZipEncoder().encode(tarBytes);
        case ArchiveFormat.tarBz2:
          final tarBytes = TarEncoder().encode(archive);
          encoded = BZip2Encoder().encode(tarBytes);
        case ArchiveFormat.tarXz:
          final tarBytes = TarEncoder().encode(archive);
          encoded = XZEncoder().encode(tarBytes);
      }
    } catch (e) {
      throw ArchiveReadException('Could not create archive: $e');
    }

    if (isCancelled != null && isCancelled()) return;

    File(destPath).writeAsBytesSync(encoded);
  }

  static void _copyInto(String src, String destDir) {
    final type = FileSystemEntity.typeSync(src);
    final target = p.join(destDir, p.basename(src));
    if (type == FileSystemEntityType.directory) {
      Directory(target).createSync(recursive: true);
      for (final e in Directory(src).listSync(followLinks: false)) {
        _copyInto(e.path, target);
      }
    } else if (type == FileSystemEntityType.file) {
      Directory(destDir).createSync(recursive: true);
      File(src).copySync(target);
    }
  }

  static int editPlanCount(String archivePath, List<String> addSources) {
    var count = 0;
    try {
      count += ArchiveReader.listEntries(archivePath).length;
    } catch (_) {}
    count += planCount(addSources);
    return count;
  }

  static void mutate(
    String archivePath, {
    List<String> addSources = const [],
    String addInner = '',
    List<String> deleteInner = const [],
    String? renameFromInner,
    String? renameToName,
    void Function(String name)? onEntry,
    bool Function()? isCancelled,
  }) {
    final format = archiveFormatFromName(archivePath);
    if (format == null) {
      throw const ArchiveReadException('unsupported archive format');
    }
    final work = Directory(
      p.join(
        Directory.systemTemp.path,
        'waydir-archive-edit',
        DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    )..createSync(recursive: true);
    final tree = Directory(p.join(work.path, 'tree'))
      ..createSync(recursive: true);
    final tmpArchive = p.join(work.path, p.basename(archivePath));
    try {
      ArchiveReader.extractAll(archivePath, tree.path);

      for (final rel in deleteInner) {
        final target = p.join(tree.path, rel);
        final type = FileSystemEntity.typeSync(target);
        if (type == FileSystemEntityType.directory) {
          Directory(target).deleteSync(recursive: true);
        } else if (type != FileSystemEntityType.notFound) {
          File(target).deleteSync();
        }
      }

      if (renameFromInner != null && renameToName != null) {
        final from = p.join(tree.path, renameFromInner);
        final to = p.join(p.dirname(from), renameToName);
        final type = FileSystemEntity.typeSync(from);
        if (type == FileSystemEntityType.directory) {
          Directory(from).renameSync(to);
        } else if (type != FileSystemEntityType.notFound) {
          File(from).renameSync(to);
        }
      }

      final innerDir = addInner.isEmpty
          ? tree.path
          : p.join(tree.path, addInner);
      if (addSources.isNotEmpty) {
        Directory(innerDir).createSync(recursive: true);
        for (final s in addSources) {
          if (isCancelled != null && isCancelled()) break;
          _copyInto(s, innerDir);
        }
      }

      final roots = tree
          .listSync(followLinks: false)
          .map((e) => e.path)
          .toList();
      create(
        roots,
        tmpArchive,
        format,
        CompressionLevel.normal,
        onEntry: onEntry,
        isCancelled: isCancelled,
      );
      if (isCancelled != null && isCancelled()) return;
      File(tmpArchive).copySync(archivePath);
    } finally {
      try {
        work.deleteSync(recursive: true);
      } catch (_) {}
    }
  }
}
