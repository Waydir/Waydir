import 'dart:io';
import '../platform/platform_paths.dart';
import '../platform/win32_attributes.dart';

enum FileItemType { folder, file }

class FileSelectionEvent {
  final FileEntry entry;
  final int index;

  const FileSelectionEvent({required this.entry, required this.index});
}

class FileEntry {
  final String name;
  final String path;
  final FileItemType type;
  final int size;
  final DateTime modified;

  late final String nameLower = name.toLowerCase();

  /// Real on-disk path, used when [path] is a virtual location (e.g. an item
  /// shown inside the trash). Falls back to [path] for ordinary entries.
  final String? _realPath;

  String get realPath => _realPath ?? path;

  FileEntry({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.modified,
    String? realPath,
  }) : _realPath = realPath;

  factory FileEntry.fromFileSystemEntity(FileSystemEntity entity) {
    final stat = entity.statSync();
    return FileEntry(
      name: PlatformPaths.fileName(entity.path),
      path: entity.path,
      type: entity is Directory ? FileItemType.folder : FileItemType.file,
      size: stat.size,
      modified: stat.modified,
    );
  }

  String get extension {
    if (type == FileItemType.folder) return '';
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  bool get isHidden {
    if (PlatformPaths.isWindows) {
      return name.startsWith('.') || isHiddenOnWindows(path);
    }
    return name.startsWith('.');
  }
}
