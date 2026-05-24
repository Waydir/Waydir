import 'dart:async';
import 'dart:typed_data';

import '../models/file_entry.dart';
import '../platform/platform_paths.dart';

/// Abstract filesystem operations decoupled from `dart:io`.
///
/// Two backends exist today: [LocalFs] (lokalny dysk i SMB-via-OS-mount) i
/// [SftpFs] (zdalny SSH/SFTP przez Rust core). Routing po prefiksie ścieżki
/// realizuje [FsBackendRegistry].
abstract class FsBackend {
  String get id;

  /// Czy backend obsługuje podaną ścieżkę.
  bool handles(String path);

  Future<List<FileEntry>> listDirectory(String path);

  Future<FileEntry?> stat(String path);

  Future<bool> exists(String path);

  Future<Stream<List<int>>> openRead(String path, {int? start, int? end});

  Future<void> writeBytes(String path, Uint8List bytes);

  Future<void> mkdir(String path, {bool recursive = false});

  Future<void> remove(String path, {bool recursive = false});

  Future<void> rename(String from, String to);

  /// Skrót — gdy źródło i cel są na tym samym backendzie i serwer wspiera
  /// natywne kopiowanie. Może rzucić [UnsupportedError] — wtedy callsite
  /// powinien fallbackować na streaming przez [openRead]/[writeBytes].
  Future<void> copyWithin(String from, String to);
}

/// Stałe metadane o pliku — surogat [FileEntry] dla operacji które nie
/// wymagają pełnego rekordu listingu.
class FsStatResult {
  final bool isDir;
  final int size;
  final int modifiedMs;
  final bool exists;

  const FsStatResult({
    required this.isDir,
    required this.size,
    required this.modifiedMs,
    required this.exists,
  });

  static const FsStatResult missing = FsStatResult(
    isDir: false,
    size: 0,
    modifiedMs: 0,
    exists: false,
  );
}

/// Routing: która implementacja obsługuje daną ścieżkę.
class FsBackendRegistry {
  FsBackendRegistry._();

  static final List<FsBackend> _backends = [];
  static FsBackend? _local;

  static void register(FsBackend backend) {
    _backends.removeWhere((b) => b.id == backend.id);
    _backends.add(backend);
  }

  static void registerLocal(FsBackend backend) {
    _local = backend;
    register(backend);
  }

  static FsBackend forPath(String path) {
    for (final b in _backends) {
      if (b.handles(path)) return b;
    }
    final local = _local;
    if (local != null) return local;
    throw StateError('No FsBackend registered for path: $path');
  }

  static bool isRemoteScheme(String path) => PlatformPaths.isSftpUri(path);

  static void debugReset() {
    _backends.clear();
    _local = null;
  }
}
