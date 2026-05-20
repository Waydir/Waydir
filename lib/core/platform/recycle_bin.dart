import 'dart:io';
import 'dart:typed_data';

import '../logging/app_logger.dart';
import 'platform_paths.dart';

class RecycleBinEntry {
  final String dataPath;
  final String infoPath;
  final String originalPath;
  final DateTime deletedAt;
  final int size;
  final bool isDirectory;

  const RecycleBinEntry({
    required this.dataPath,
    required this.infoPath,
    required this.originalPath,
    required this.deletedAt,
    required this.size,
    required this.isDirectory,
  });

  String get name {
    final i = originalPath.lastIndexOf(RegExp(r'[\\/]'));
    return i < 0 ? originalPath : originalPath.substring(i + 1);
  }
}

class _Info {
  final String originalPath;
  final DateTime deletedAt;
  final int size;
  const _Info({
    required this.originalPath,
    required this.deletedAt,
    required this.size,
  });
}

class RecycleBinService {
  static const int _filetimeUnixEpoch = 116444736000000000;

  static Future<List<RecycleBinEntry>> list() async {
    if (!Platform.isWindows) return const [];

    final entries = <RecycleBinEntry>[];
    final sidDirs = _findSidDirs();
    if (sidDirs.isEmpty) {
      log.warn(
        'recycle_bin',
        'no accessible \$Recycle.Bin\\<SID> folders found across drives',
      );
      return const [];
    }
    for (final binDir in sidDirs) {
      List<FileSystemEntity> children;
      try {
        children = binDir.listSync(followLinks: false);
      } catch (e, s) {
        log.warn(
          'recycle_bin',
          'failed to list ${binDir.path}',
          error: e,
          stack: s,
        );
        continue;
      }
      for (final ent in children) {
        final name = PlatformPaths.fileName(ent.path);
        if (!name.startsWith(r'$I')) continue;
        final dataName = '\$R${name.substring(2)}';
        final dataPath = '${binDir.path}\\$dataName';
        final isDir = Directory(dataPath).existsSync();
        final isFile = File(dataPath).existsSync();
        if (!isDir && !isFile) continue;
        try {
          final info = _parseInfo(ent.path);
          if (info == null) continue;
          entries.add(
            RecycleBinEntry(
              dataPath: dataPath,
              infoPath: ent.path,
              originalPath: info.originalPath,
              deletedAt: info.deletedAt,
              size: info.size,
              isDirectory: isDir,
            ),
          );
        } catch (e, s) {
          log.warn(
            'recycle_bin',
            'failed to parse ${ent.path}',
            error: e,
            stack: s,
          );
        }
      }
    }
    entries.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return entries;
  }

  /// Enumerates every `<drive>:\$Recycle.Bin\<SID>` folder the process can
  /// read. Avoids the `whoami`/SID lookup so a single shell quirk can't hide
  /// the entire trash, and naturally picks up bins on every drive.
  static List<Directory> _findSidDirs() {
    final out = <Directory>[];
    for (var i = 0; i < 26; i++) {
      final letter = String.fromCharCode(65 + i);
      final root = Directory('$letter:\\\$Recycle.Bin');
      if (!root.existsSync()) continue;
      try {
        for (final ent in root.listSync(followLinks: false)) {
          if (ent is! Directory) continue;
          final name = PlatformPaths.fileName(ent.path);
          if (!name.startsWith('S-1-')) continue;
          out.add(ent);
        }
      } catch (e, s) {
        log.warn(
          'recycle_bin',
          'failed to list ${root.path}',
          error: e,
          stack: s,
        );
      }
    }
    return out;
  }

  static Future<void> restore(RecycleBinEntry e) async {
    final parentDir = Directory(PlatformPaths.parentOf(e.originalPath));
    if (!parentDir.existsSync()) parentDir.createSync(recursive: true);
    if (e.isDirectory) {
      Directory(e.dataPath).renameSync(e.originalPath);
    } else {
      File(e.dataPath).renameSync(e.originalPath);
    }
    _deleteIfExists(e.infoPath);
  }

  static Future<void> deletePermanently(RecycleBinEntry e) async {
    if (e.isDirectory) {
      Directory(e.dataPath).deleteSync(recursive: true);
    } else if (File(e.dataPath).existsSync()) {
      File(e.dataPath).deleteSync();
    }
    _deleteIfExists(e.infoPath);
  }

  static void _deleteIfExists(String path) {
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  }

  static _Info? _parseInfo(String path) {
    final bytes = File(path).readAsBytesSync();
    if (bytes.length < 24) return null;
    final bd = ByteData.sublistView(bytes);
    final version = bd.getUint64(0, Endian.little);
    final size = bd.getUint64(8, Endian.little);
    final filetime = bd.getUint64(16, Endian.little);
    final unixMs = (filetime - _filetimeUnixEpoch) ~/ 10000;
    final deletedAt = DateTime.fromMillisecondsSinceEpoch(
      unixMs,
      isUtc: true,
    ).toLocal();

    String originalPath;
    if (version == 1) {
      const fixedBytes = 520;
      if (bytes.length < 24 + fixedBytes) return null;
      originalPath = _utf16(bytes, 24, fixedBytes);
    } else {
      if (bytes.length < 28) return null;
      final pathChars = bd.getUint32(24, Endian.little);
      final pathBytes = pathChars * 2;
      if (bytes.length < 28 + pathBytes) return null;
      originalPath = _utf16(bytes, 28, pathBytes);
    }
    return _Info(originalPath: originalPath, deletedAt: deletedAt, size: size);
  }

  static String _utf16(Uint8List bytes, int offset, int length) {
    final bd = ByteData.sublistView(bytes, offset, offset + length);
    final sb = StringBuffer();
    for (var i = 0; i + 1 < length; i += 2) {
      final code = bd.getUint16(i, Endian.little);
      if (code == 0) break;
      sb.writeCharCode(code);
    }
    return sb.toString();
  }
}
