import 'package:path/path.dart' as p;

import '../models/file_entry.dart';
import 'archive_reader.dart';

class ArchiveService {
  ArchiveService._();

  static List<FileEntry> levelEntries(
    String archivePath,
    String innerPath,
    List<ArchiveEntry> all,
    DateTime archiveModified,
  ) {
    final prefix = innerPath.isEmpty ? '' : '$innerPath/';
    final byName = <String, FileEntry>{};
    final dirNames = <String>{};

    for (final e in all) {
      if (!e.path.startsWith(prefix)) continue;
      final rest = e.path.substring(prefix.length);
      if (rest.isEmpty) continue;
      final slash = rest.indexOf('/');
      final name = slash < 0 ? rest : rest.substring(0, slash);
      if (name.isEmpty) continue;
      final isDir = slash >= 0 || e.isDir;
      final virtualPath = p.join(archivePath, innerPath, name);
      if (isDir) {
        dirNames.add(name);
        byName.putIfAbsent(
          name,
          () => FileEntry(
            name: name,
            path: virtualPath,
            type: FileItemType.folder,
            size: 0,
            modified: archiveModified,
          ),
        );
      } else {
        byName[name] = FileEntry(
          name: name,
          path: virtualPath,
          type: FileItemType.file,
          size: e.size,
          modified:
              e.modified ??
              (e.mtimeSeconds > 0
                  ? DateTime.fromMillisecondsSinceEpoch(e.mtimeSeconds * 1000)
                  : archiveModified),
        );
      }
    }

    for (final d in dirNames) {
      final existing = byName[d];
      if (existing != null && existing.type != FileItemType.folder) {
        byName[d] = FileEntry(
          name: d,
          path: p.join(archivePath, innerPath, d),
          type: FileItemType.folder,
          size: 0,
          modified: archiveModified,
        );
      }
    }

    return byName.values.toList();
  }
}
