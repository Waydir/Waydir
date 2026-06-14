import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../i18n/strings.g.dart';
import '../models/file_entry.dart';
import '../platform/platform_paths.dart';
import 'fs_backend.dart';
import 'sftp_session_manager.dart';
import 'waydir_core_loader.dart';

class SftpFs implements FsBackend {
  const SftpFs();

  @override
  String get id => 'sftp';

  @override
  bool handles(String path) => PlatformPaths.isSftpUri(path);

  int _sessionFor(String path) {
    final rec = SftpSessionManager.recordFor(path);
    if (rec == null) {
      throw FileSystemException(t.errors.sftpNoActiveSessionFor(path: path));
    }

    return rec.sessionId;
  }

  String _remote(String path) => SftpSessionManager.remotePath(path);

  /// Buduje logiczny URI z remote path (np. `/etc/foo`) używając sesji
  /// rozpoznanej po `referencePath`.
  String _logicalFrom(String referencePath, String remotePath) {
    final rec = SftpSessionManager.recordFor(referencePath);
    if (rec == null) return referencePath;

    return SftpSessionManager.buildLogicalPath(
      host: rec.host,
      port: rec.port,
      user: rec.user,
      remotePath: remotePath,
    );
  }

  @override
  Future<List<FileEntry>> listDirectory(String path) async {
    final sessionId = _sessionFor(path);
    final remote = _remote(path);
    final buf = WaydirCoreLoader.sftpList(sessionId, remote);
    if (buf == null) {
      throw FileSystemException(t.errors.sftpListingFailed, path);
    }
    final decoded = FileEntryCodec.decode(buf);

    return decoded
        .map(
          (e) => FileEntry.raw(
            name: e.name,
            path: _logicalFrom(path, e.path),
            type: e.type,
            size: e.size,
            modifiedMs: e.modifiedMs,
          ),
        )
        .toList();
  }

  @override
  Future<FileEntry?> stat(String path) async {
    final sessionId = _sessionFor(path);
    final remote = _remote(path);
    final s = WaydirCoreLoader.sftpStat(sessionId, remote);
    if (s == null || !s.exists) return null;
    final name = PlatformPaths.fileName(path);

    return FileEntry.raw(
      name: name.isEmpty ? remote : name,
      path: path,
      type: s.isDir ? FileItemType.folder : FileItemType.file,
      size: s.size,
      modifiedMs: s.mtimeMs,
    );
  }

  @override
  Future<bool> exists(String path) async {
    final s = await stat(path);

    return s != null;
  }

  @override
  Future<Stream<List<int>>> openRead(
    String path, {
    int? start,
    int? end,
  }) async {
    final sessionId = _sessionFor(path);
    final remote = _remote(path);
    final s = start ?? -1;
    final length = (end != null && start != null) ? end - start : -1;
    final bytes = WaydirCoreLoader.sftpRead(
      sessionId,
      remote,
      start: s,
      length: length,
    );
    if (bytes == null) {
      throw FileSystemException(t.errors.sftpReadFailed, path);
    }
    final controller = StreamController<List<int>>();
    controller.add(bytes);
    controller.close();

    return controller.stream;
  }

  @override
  Future<void> writeBytes(String path, Uint8List bytes) async {
    final sessionId = _sessionFor(path);
    final remote = _remote(path);
    final ok = WaydirCoreLoader.sftpWrite(sessionId, remote, bytes);
    if (!ok) throw FileSystemException(t.errors.sftpWriteFailed, path);
  }

  @override
  Future<void> mkdir(String path, {bool recursive = false}) async {
    final sessionId = _sessionFor(path);
    final remote = _remote(path);
    final ok = WaydirCoreLoader.sftpMkdir(
      sessionId,
      remote,
      recursive: recursive,
    );
    if (!ok) throw FileSystemException(t.errors.sftpMkdirFailed, path);
  }

  @override
  Future<void> remove(String path, {bool recursive = false}) async {
    final sessionId = _sessionFor(path);
    final remote = _remote(path);
    final ok = WaydirCoreLoader.sftpRemove(
      sessionId,
      remote,
      recursive: recursive,
    );
    if (!ok) throw FileSystemException(t.errors.sftpRemoveFailed, path);
  }

  @override
  Future<void> rename(String from, String to) async {
    final sessionId = _sessionFor(from);
    final ok = WaydirCoreLoader.sftpRename(
      sessionId,
      _remote(from),
      _remote(to),
    );
    if (!ok) throw FileSystemException(t.errors.sftpRenameFailed, from);
  }

  @override
  Future<void> copyWithin(String from, String to) async {
    final stream = await openRead(from);
    final builder = BytesBuilder(copy: false);
    await for (final chunk in stream) {
      builder.add(chunk);
    }
    await writeBytes(to, builder.toBytes());
  }
}
