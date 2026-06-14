import 'dart:io';

import 'package:path/path.dart' as p;

class ArchiveLocation {
  final String archivePath;
  final String innerPath;

  const ArchiveLocation(this.archivePath, this.innerPath);

  bool get isRoot => innerPath.isEmpty;
}

class ArchivePath {
  ArchivePath._();

  static const _compoundExtensions = <String>['.tar.gz', '.tar.bz2', '.tar.xz'];

  static const _extensions = <String>{
    '.zip',
    '.tar',
    '.tgz',
    '.tbz',
    '.tbz2',
    '.txz',
    '.jar',
    '.war',
    '.apk',
    '.xpi',
    '.whl',
    '.crx',
    '.epub',
  };

  static bool isArchiveName(String name) {
    final lower = name.toLowerCase();
    for (final ext in _compoundExtensions) {
      if (lower.endsWith(ext)) return true;
    }

    return _extensions.contains(p.extension(lower));
  }

  static ArchiveLocation? resolve(String path) {
    final segments = p.split(path);
    if (segments.isEmpty) return null;

    var prefix = segments.first;
    for (var i = 0; i < segments.length; i++) {
      prefix = i == 0 ? segments.first : p.join(prefix, segments[i]);
      if (!isArchiveName(segments[i])) continue;
      if (FileSystemEntity.typeSync(prefix) != FileSystemEntityType.file) {
        continue;
      }
      final innerSegments = segments.sublist(i + 1);

      return ArchiveLocation(
        prefix,
        innerSegments.isEmpty ? '' : p.joinAll(innerSegments),
      );
    }

    return null;
  }
}
