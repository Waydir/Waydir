import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../i18n/strings.g.dart';
import '../models/file_entry.dart';
import '../platform/platform_paths.dart';
import 'fs_backend.dart';
import 'waydir_core_loader.dart';

/// Backend dla ścieżek lokalnych oraz tych zmapowanych przez gvfs/UNC
/// (`smb://` które `LocationResolver` rozwiązuje na fizyczne mountpointy).
class LocalFs implements FsBackend {
  const LocalFs();

  @override
  String get id => 'local';

  @override
  bool handles(String path) => !PlatformPaths.isSftpUri(path);

  @override
  Future<List<FileEntry>> listDirectory(String path) async {
    final native = WaydirCoreLoader.listDir(path);
    if (native == null) {
      throw FileSystemException(t.errors.directoryNotReadable, path);
    }
    return FileEntryCodec.decode(native);
  }

  @override
  Future<FileEntry?> stat(String path) async {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    final entity = type == FileSystemEntityType.directory
        ? Directory(path) as FileSystemEntity
        : (type == FileSystemEntityType.link ? Link(path) : File(path));
    return FileEntry.fromFileSystemEntity(entity);
  }

  @override
  Future<bool> exists(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    return type != FileSystemEntityType.notFound;
  }

  @override
  Future<Stream<List<int>>> openRead(
    String path, {
    int? start,
    int? end,
  }) async {
    return File(path).openRead(start, end);
  }

  @override
  Future<void> writeBytes(String path, Uint8List bytes) =>
      File(path).writeAsBytes(bytes, flush: true);

  @override
  Future<void> mkdir(String path, {bool recursive = false}) async {
    await Directory(path).create(recursive: recursive);
  }

  @override
  Future<void> remove(String path, {bool recursive = false}) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: recursive);
    } else if (type != FileSystemEntityType.notFound) {
      await File(path).delete();
    }
  }

  @override
  Future<void> rename(String from, String to) async {
    final type = await FileSystemEntity.type(from, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      await Directory(from).rename(to);
    } else if (type == FileSystemEntityType.link) {
      await Link(from).rename(to);
    } else {
      await File(from).rename(to);
    }
  }

  @override
  Future<void> copyWithin(String from, String to) async {
    await File(from).copy(to);
  }
}
