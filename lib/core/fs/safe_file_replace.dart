import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'native_copy.dart';

typedef _ChmodNative = Int32 Function(Pointer<Utf8>, Uint32);
typedef _ChmodDart = int Function(Pointer<Utf8>, int);

class SafeFileReplace {
  SafeFileReplace._();

  static final DynamicLibrary? _libc = _openLibc();

  static void copyFile(
    File source,
    String destinationPath, {
    void Function(int bytes)? onProgress,
  }) {
    final tempPath = temporarySiblingPath(destinationPath);
    Object? copyError;
    StackTrace? copyStack;
    var tempReady = false;

    try {
      _copyToPath(source, tempPath, onProgress: onProgress);
      _copyBasicMetadata(source, File(tempPath));
      tempReady = true;
      replaceWithFile(tempPath, destinationPath);
    } catch (e, st) {
      copyError = e;
      copyStack = st;
    } finally {
      if (!tempReady ||
          FileSystemEntity.typeSync(tempPath, followLinks: false) !=
              FileSystemEntityType.notFound) {
        try {
          File(tempPath).deleteSync();
        } catch (_) {}
      }
    }

    if (copyError != null) {
      Error.throwWithStackTrace(copyError, copyStack!);
    }
  }

  static void replaceWithFile(String replacementPath, String destinationPath) {
    if (Platform.isWindows) {
      _replaceWindows(replacementPath, destinationPath);
      return;
    }
    File(replacementPath).renameSync(destinationPath);
  }

  static String temporarySiblingPath(String path) {
    final separator = Platform.pathSeparator;
    final split = path.lastIndexOf(separator);
    final dir = split >= 0 ? path.substring(0, split) : '.';
    final name = split >= 0 ? path.substring(split + 1) : path;
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    for (var counter = 0; counter < 10000; counter++) {
      final tempPath = '$dir$separator.$name.waydir_tmp_${timestamp}_$counter';
      if (FileSystemEntity.typeSync(tempPath, followLinks: false) ==
          FileSystemEntityType.notFound) {
        return tempPath;
      }
    }

    return '$dir$separator.$name.waydir_tmp_${DateTime.now().microsecondsSinceEpoch}';
  }

  static void cleanupLeftovers(String directoryPath) {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) return;
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    try {
      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is! File) continue;
        final name = _fileName(entity.path);
        if (!name.contains('.waydir_tmp_')) continue;
        try {
          if (entity.statSync().modified.isBefore(cutoff)) {
            entity.deleteSync();
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  static void _copyToPath(
    File source,
    String destinationPath, {
    void Function(int bytes)? onProgress,
  }) {
    if (NativeCopy.tryFastCopy(
      source.path,
      destinationPath,
      onProgress: onProgress,
    )) {
      return;
    }

    const chunkSize = 1024 * 1024;
    final input = source.openSync(mode: FileMode.read);
    final output = File(destinationPath).openSync(mode: FileMode.write);
    Object? error;
    StackTrace? stack;

    try {
      while (true) {
        final chunk = input.readSync(chunkSize);
        if (chunk.isEmpty) break;
        output.writeFromSync(chunk);
        onProgress?.call(chunk.length);
      }
      output.flushSync();
    } catch (e, st) {
      error = e;
      stack = st;
    } finally {
      input.closeSync();
      output.closeSync();
    }

    if (error != null) {
      Error.throwWithStackTrace(error, stack!);
    }
  }

  static void _copyBasicMetadata(File source, File destination) {
    try {
      final stat = source.statSync();
      destination.setLastModifiedSync(stat.modified);
      if (!Platform.isWindows) {
        _chmod(destination.path, stat.mode);
      }
    } catch (_) {}
  }

  static void _chmod(String path, int mode) {
    final permissions = mode & 0x1FF;
    if (_nativeChmod(path, permissions)) return;
    try {
      Process.runSync('chmod', [permissions.toRadixString(8), path]);
    } catch (_) {}
  }

  static bool _nativeChmod(String path, int permissions) {
    final libc = _libc;
    if (libc == null) return false;
    final nativePath = path.toNativeUtf8();
    try {
      final chmod = libc.lookupFunction<_ChmodNative, _ChmodDart>('chmod');
      return chmod(nativePath, permissions) == 0;
    } catch (_) {
      return false;
    } finally {
      calloc.free(nativePath);
    }
  }

  static DynamicLibrary? _openLibc() {
    if (Platform.isWindows) return null;
    try {
      if (Platform.isLinux) return DynamicLibrary.open('libc.so.6');
      return DynamicLibrary.process();
    } catch (_) {
      return null;
    }
  }

  static void _replaceWindows(String replacementPath, String destinationPath) {
    final replacement = replacementPath.toNativeUtf16();
    final destination = destinationPath.toNativeUtf16();
    try {
      final result = MoveFileEx(
        replacement,
        destination,
        MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH,
      );
      if (result == 0) {
        throw FileSystemException(
          'MoveFileEx failed with Windows error ${GetLastError()}',
          destinationPath,
        );
      }
    } finally {
      calloc.free(replacement);
      calloc.free(destination);
    }
  }

  static String _fileName(String path) {
    final separator = Platform.pathSeparator;
    final split = path.lastIndexOf(separator);
    return split >= 0 ? path.substring(split + 1) : path;
  }
}
