import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../fs/passwd_lookup.dart';
import '../platform/platform_paths.dart';
import '../platform/win32_attributes.dart';
import 'file_kind_names.dart';

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

  /// Creation (birth) time as epoch milliseconds, falling back to unix ctime
  /// on filesystems without a birth time. 0 when unknown.
  final int createdMs;

  /// Time the file was added to its current location, as epoch milliseconds.
  /// On macOS this is kMDItemDateAdded (xattr); on other platforms it falls
  /// back to [createdMs]. 0 when unknown.
  final int addedMs;

  /// Unix mode bits (type + permissions), 0 when unknown (e.g. non-unix).
  final int mode;

  /// Owning user / group ids, 0 when unknown.
  final int uid;
  final int gid;

  DateTime? _modified;
  DateTime get modified =>
      _modified ??= DateTime.fromMillisecondsSinceEpoch(modifiedMs);

  DateTime? _created;
  DateTime get created =>
      _created ??= DateTime.fromMillisecondsSinceEpoch(createdMs);

  DateTime? _added;
  DateTime get added => _added ??= DateTime.fromMillisecondsSinceEpoch(addedMs);

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
    DateTime? created,
    DateTime? added,
    this.mode = 0,
    this.uid = 0,
    this.gid = 0,
    String? realPath,
  }) : modifiedMs = modified.millisecondsSinceEpoch,
       createdMs = (created ?? modified).millisecondsSinceEpoch,
       addedMs = (added ?? created ?? modified).millisecondsSinceEpoch,
       _modified = modified,
       _created = created,
       _added = added,
       _realPath = realPath;

  FileEntry.raw({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.modifiedMs,
    this.createdMs = 0,
    this.addedMs = 0,
    this.mode = 0,
    this.uid = 0,
    this.gid = 0,
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
      created: stat.changed,
      mode: stat.mode,
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

  String get kind {
    if (type == FileItemType.folder) return 'Folder';

    return kindLabelForFile(name, extension);
  }

  /// Unix-style permission string (e.g. "drwxr-xr-x"), or "--" when [mode] is
  /// unknown (non-unix listings, archives, …).
  String get permissionsString {
    if (mode == 0) return '--';
    const flags = ['x', 'w', 'r'];
    final sb = StringBuffer();
    sb.write(type == FileItemType.folder ? 'd' : '-');
    for (var shift = 8; shift >= 0; shift--) {
      sb.write((mode & (1 << shift)) != 0 ? flags[shift % 3] : '-');
    }

    return sb.toString();
  }

  /// Owner user name resolved from [uid] via [PasswdLookup], falling back to
  /// the numeric uid. Empty when ownership is unknown (uid 0 and root unmapped).
  String get ownerName => PasswdLookup.userName(uid);
}

/// Compact binary codec for shipping large [FileEntry] lists across an
/// isolate port. A single [Uint8List] is copied far cheaper than thousands
/// of individual objects + their strings. Used only above a size threshold;
/// below it, plain object lists win on overhead.
class FileEntryCodec {
  FileEntryCodec._();

  static const int threshold = 2000;
  static const int _magic = 0x57444952; // 'WDIR'

  /// Fixed-size record header, mirroring `codec.rs::RECORD_HEAD`. Layout
  /// (big-endian): u8 is_dir, i64 size, i64 mtime_ms, i64 ctime_ms,
  /// i64 added_ms, u32 mode, u32 uid, u32 gid, u32 name_len, u32 path_len.
  static const int _recordHead = 1 + 8 + 8 + 8 + 8 + 4 + 4 + 4 + 4 + 4;

  static Uint8List encode(List<FileEntry> entries) {
    final b = BytesBuilder(copy: false);
    final header = ByteData(8);
    header.setUint32(0, _magic);
    header.setUint32(4, entries.length);
    b.add(header.buffer.asUint8List());

    for (final e in entries) {
      final nameB = utf8.encode(e.name);
      final pathB = utf8.encode(e.path);
      final rec = ByteData(_recordHead);
      rec.setUint8(0, e.type == FileItemType.folder ? 0 : 1);
      rec.setInt64(1, e.size);
      rec.setInt64(9, e.modifiedMs);
      rec.setInt64(17, e.createdMs);
      rec.setInt64(25, e.addedMs);
      rec.setUint32(33, e.mode);
      rec.setUint32(37, e.uid);
      rec.setUint32(41, e.gid);
      rec.setUint32(45, nameB.length);
      rec.setUint32(49, pathB.length);
      b.add(rec.buffer.asUint8List());
      b.add(nameB);
      b.add(pathB);
    }

    return b.toBytes();
  }

  static int countOf(Uint8List bytes) {
    final view = ByteData.sublistView(bytes);
    if (view.getUint32(0) != _magic) {
      throw const FormatException('bad FileEntry blob');
    }

    return view.getUint32(4);
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
      final createdMs = view.getInt64(off + 17);
      final addedMs = view.getInt64(off + 25);
      final mode = view.getUint32(off + 33);
      final uid = view.getUint32(off + 37);
      final gid = view.getUint32(off + 41);
      final nameLen = view.getUint32(off + 45);
      final pathLen = view.getUint32(off + 49);
      off += _recordHead;
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
          createdMs: createdMs,
          addedMs: addedMs,
          mode: mode,
          uid: uid,
          gid: gid,
        ),
      );
    }

    return out;
  }
}
