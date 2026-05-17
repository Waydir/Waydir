import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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

  /// Modification time stored as epoch milliseconds. Keeping an int instead
  /// of a [DateTime] avoids retaining a heap object per entry; the [DateTime]
  /// is materialised lazily and only when actually read.
  final int modifiedMs;

  DateTime? _modified;
  DateTime get modified =>
      _modified ??= DateTime.fromMillisecondsSinceEpoch(modifiedMs);

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
    required DateTime modified,
    String? realPath,
  }) : modifiedMs = modified.millisecondsSinceEpoch,
       _modified = modified,
       _realPath = realPath;

  FileEntry.raw({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.modifiedMs,
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

/// Compact binary codec for shipping large [FileEntry] lists across an
/// isolate port. A single [Uint8List] is copied far cheaper than thousands
/// of individual objects + their strings. Used only above a size threshold;
/// below it, plain object lists win on overhead.
class FileEntryCodec {
  FileEntryCodec._();

  static const int threshold = 2000;
  static const int _magic = 0x57444952; // 'WDIR'

  static Uint8List encode(List<FileEntry> entries) {
    final b = BytesBuilder(copy: false);
    final header = ByteData(8);
    header.setUint32(0, _magic);
    header.setUint32(4, entries.length);
    b.add(header.buffer.asUint8List());

    for (final e in entries) {
      final nameB = utf8.encode(e.name);
      final pathB = utf8.encode(e.path);
      final rec = ByteData(1 + 8 + 8 + 4 + 4);
      rec.setUint8(0, e.type == FileItemType.folder ? 0 : 1);
      rec.setInt64(1, e.size);
      rec.setInt64(9, e.modifiedMs);
      rec.setUint32(17, nameB.length);
      rec.setUint32(21, pathB.length);
      b.add(rec.buffer.asUint8List());
      b.add(nameB);
      b.add(pathB);
    }
    return b.toBytes();
  }

  static List<FileEntry> decode(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    if (view.getUint32(0) != _magic) {
      throw const FormatException('bad FileEntry blob');
    }
    final count = view.getUint32(4);
    final out = <FileEntry>[];
    var off = 8;
    for (var i = 0; i < count; i++) {
      final type = view.getUint8(off) == 0
          ? FileItemType.folder
          : FileItemType.file;
      final size = view.getInt64(off + 1);
      final modifiedMs = view.getInt64(off + 9);
      final nameLen = view.getUint32(off + 17);
      final pathLen = view.getUint32(off + 21);
      off += 25;
      final name = utf8.decode(bytes.sublist(off, off + nameLen));
      off += nameLen;
      final path = utf8.decode(bytes.sublist(off, off + pathLen));
      off += pathLen;
      out.add(
        FileEntry.raw(
          name: name,
          path: path,
          type: type,
          size: size,
          modifiedMs: modifiedMs,
        ),
      );
    }
    return out;
  }
}
