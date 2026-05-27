import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../../i18n/strings.g.dart';
import 'native_copy.dart';

typedef _ChmodNative = Int32 Function(Pointer<Utf8>, Uint32);
typedef _ChmodDart = int Function(Pointer<Utf8>, int);

final class _Timeval extends Struct {
  @IntPtr()
  external int tvSec;

  @IntPtr()
  external int tvUsec;
}

typedef _UtimesNative = Int32 Function(Pointer<Utf8>, Pointer<_Timeval>);
typedef _UtimesDart = int Function(Pointer<Utf8>, Pointer<_Timeval>);

class SafeFileReplace {
  SafeFileReplace._();

  static final DynamicLibrary? _libc = _openLibc();

  /// Copies [source] to [destinationPath] via a temp sibling, then atomically
  /// swaps it in. Returns false (leaving no target) if [isCancelled] fired
  /// mid-copy; the partial temp file is always cleaned up.
  static Future<bool> copyFile(
    File source,
    String destinationPath, {
    void Function(int bytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final tempPath = temporarySiblingPath(destinationPath);
    Object? copyError;
    StackTrace? copyStack;
    var tempReady = false;
    var cancelled = false;

    try {
      cancelled = !await _copyToPath(
        source,
        tempPath,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
      if (cancelled) return false;
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
    return true;
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

  /// Returns false if the copy was cancelled mid-stream, true on completion.
  static Future<bool> _copyToPath(
    File source,
    String destinationPath, {
    void Function(int bytes)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final fast = await NativeCopy.tryFastCopy(
      source.path,
      destinationPath,
      onProgress: onProgress,
      shouldCancel: isCancelled,
    );
    if (fast == FastCopyResult.done) return true;
    if (fast == FastCopyResult.cancelled) return false;

    const chunkSize = 8 * 1024 * 1024;
    // Yield to the event loop (so a pending cancel can be delivered) once
    // per this many bytes, instead of every chunk — far fewer event-loop
    // turns at cache speed while keeping cancel latency well under a second.
    const yieldEvery = 16 * 1024 * 1024;
    final input = source.openSync(mode: FileMode.read);
    final output = File(destinationPath).openSync(mode: FileMode.write);
    final buffer = Uint8List(chunkSize);
    Object? error;
    StackTrace? stack;
    var completed = true;
    var sinceYield = 0;

    try {
      while (true) {
        if (isCancelled != null && isCancelled()) {
          completed = false;
          break;
        }
        final n = input.readIntoSync(buffer);
        if (n <= 0) break;
        output.writeFromSync(buffer, 0, n);
        onProgress?.call(n);
        sinceYield += n;
        if (sinceYield >= yieldEvery) {
          sinceYield = 0;
          await Future<void>.delayed(Duration.zero);
        }
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
    return completed;
  }

  static void _copyBasicMetadata(File source, File destination) {
    try {
      final stat = source.statSync();
      if (!_copyTimes(destination.path, stat.accessed, stat.modified)) {
        destination.setLastModifiedSync(stat.modified);
      }
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

  static bool _copyTimes(String path, DateTime accessed, DateTime modified) {
    if (Platform.isWindows) return false;
    final libc = _libc;
    if (libc == null) return false;
    final nativePath = path.toNativeUtf8();
    final times = calloc<_Timeval>(2);
    try {
      times[0].tvSec = accessed.millisecondsSinceEpoch ~/ 1000;
      times[0].tvUsec = (accessed.microsecondsSinceEpoch % 1000000);
      times[1].tvSec = modified.millisecondsSinceEpoch ~/ 1000;
      times[1].tvUsec = (modified.microsecondsSinceEpoch % 1000000);
      final utimes = libc.lookupFunction<_UtimesNative, _UtimesDart>('utimes');
      return utimes(nativePath, times) == 0;
    } catch (_) {
      return false;
    } finally {
      calloc.free(times);
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
          t.errors.moveFileExFailed(error: GetLastError()),
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
