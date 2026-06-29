import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../logging/app_logger.dart';

const int _oRdonly = 0;
const int _oWronly = 1;
const int _oCreat = 0x40;
const int _oTrunc = 0x200;
const int _oCloexec = 0x80000;

typedef _OpenNative = Int32 Function(Pointer<Utf8>, Int32, Uint32);
typedef _OpenDart = int Function(Pointer<Utf8>, int, int);

typedef _CloseNative = Int32 Function(Int32);
typedef _CloseDart = int Function(int);

typedef _CfrNative =
    IntPtr Function(
      Int32,
      Pointer<Int64>,
      Int32,
      Pointer<Int64>,
      IntPtr,
      Uint32,
    );
typedef _CfrDart =
    int Function(int, Pointer<Int64>, int, Pointer<Int64>, int, int);

typedef _CloneNative = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _CloneDart = int Function(Pointer<Utf8>, Pointer<Utf8>, int);

enum FastCopyResult { done, unsupported, cancelled }

/// Best-effort native fast-copy. Uses copy_file_range on Linux (server-side
/// / reflink copy), clonefile on macOS (APFS copy-on-write) and CopyFileEx on
/// Windows (kernel-side buffered copy). Returns unsupported on any failure so
/// the caller falls back to a portable copy.
///
/// On Linux [destinationPath] is created/truncated. On macOS it MUST NOT
/// exist (clonefile requirement) — callers copy into a fresh temp sibling,
/// which satisfies this.
class NativeCopy {
  NativeCopy._();

  static final DynamicLibrary? _lib = _open();

  static DynamicLibrary? _open() {
    try {
      if (Platform.isLinux) return DynamicLibrary.open('libc.so.6');
      if (Platform.isMacOS) return DynamicLibrary.process();
      if (Platform.isWindows) return null;
    } catch (e, st) {
      log.warn(
        'fs.copy',
        'native copy library open failed',
        error: e,
        stack: st,
      );
    }

    return null;
  }

  static Future<FastCopyResult> tryFastCopy(
    String sourcePath,
    String destinationPath, {
    void Function(int bytes)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    if (Platform.isWindows) {
      return _windowsCopyFileEx(sourcePath, destinationPath, onProgress)
          ? FastCopyResult.done
          : FastCopyResult.unsupported;
    }
    final lib = _lib;
    if (lib == null) return FastCopyResult.unsupported;
    if (Platform.isLinux) {
      return _linuxCopyFileRange(
        lib,
        sourcePath,
        destinationPath,
        onProgress,
        shouldCancel,
      );
    }
    if (Platform.isMacOS) {
      return _macClonefile(lib, sourcePath, destinationPath, onProgress)
          ? FastCopyResult.done
          : FastCopyResult.unsupported;
    }

    return FastCopyResult.unsupported;
  }

  static bool _macClonefile(
    DynamicLibrary lib,
    String src,
    String dst,
    void Function(int bytes)? onProgress,
  ) {
    final clonefile = lib.lookupFunction<_CloneNative, _CloneDart>('clonefile');
    final s = src.toNativeUtf8();
    final d = dst.toNativeUtf8();
    try {
      final ok = clonefile(s, d, 0) == 0;
      if (ok && onProgress != null) {
        try {
          onProgress(File(src).lengthSync());
        } catch (e, st) {
          log.warn(
            'fs.copy',
            'fast copy progress stat failed',
            error: e,
            stack: st,
          );
        }
      }

      return ok;
    } catch (e, st) {
      log.warn('fs.copy', 'mac clonefile failed', error: e, stack: st);

      return false;
    } finally {
      calloc.free(s);
      calloc.free(d);
    }
  }

  static bool _windowsCopyFileEx(
    String src,
    String dst,
    void Function(int bytes)? onProgress,
  ) {
    final s = src.toNativeUtf16();
    final d = dst.toNativeUtf16();
    try {
      final ok =
          CopyFileEx(
            s,
            d,
            nullptr,
            nullptr,
            nullptr,
            COPY_FILE_FAIL_IF_EXISTS,
          ) !=
          0;
      if (ok && onProgress != null) {
        try {
          onProgress(File(src).lengthSync());
        } catch (e, st) {
          log.warn(
            'fs.copy',
            'fast copy progress stat failed',
            error: e,
            stack: st,
          );
        }
      }

      return ok;
    } catch (e, st) {
      log.warn('fs.copy', 'windows CopyFileEx failed', error: e, stack: st);

      return false;
    } finally {
      calloc.free(s);
      calloc.free(d);
    }
  }

  static const int _copyFileRangeProgressChunk = 32 * 1024 * 1024;

  static Future<FastCopyResult> _linuxCopyFileRange(
    DynamicLibrary lib,
    String src,
    String dst,
    void Function(int bytes)? onProgress,
    bool Function()? shouldCancel,
  ) async {
    final open = lib.lookupFunction<_OpenNative, _OpenDart>('open');
    final close = lib.lookupFunction<_CloseNative, _CloseDart>('close');
    final cfr = lib.lookupFunction<_CfrNative, _CfrDart>('copy_file_range');

    final int total;
    try {
      total = File(src).lengthSync();
    } catch (e, st) {
      log.warn(
        'fs.copy',
        'fast copy source length failed',
        error: e,
        stack: st,
      );

      return FastCopyResult.unsupported;
    }

    final sPtr = src.toNativeUtf8();
    final dPtr = dst.toNativeUtf8();
    int fdIn = -1;
    int fdOut = -1;
    try {
      fdIn = open(sPtr, _oRdonly | _oCloexec, 0);
      if (fdIn < 0) return FastCopyResult.unsupported;
      fdOut = open(dPtr, _oWronly | _oCreat | _oTrunc | _oCloexec, 0x1A4);
      if (fdOut < 0) return FastCopyResult.unsupported;

      if (total == 0) return FastCopyResult.done;

      var remaining = total;
      var emitted = 0;
      while (remaining > 0) {
        final want = remaining < _copyFileRangeProgressChunk
            ? remaining
            : _copyFileRangeProgressChunk;
        final n = cfr(fdIn, nullptr, fdOut, nullptr, want, 0);
        if (n < 0) {
          _rollbackReportedProgress(onProgress, emitted);

          return FastCopyResult.unsupported;
        }
        if (n == 0) break;
        remaining -= n;
        emitted += n;
        onProgress?.call(n);
        if (remaining > 0) {
          await Future<void>.delayed(Duration.zero);
          if (shouldCancel != null && shouldCancel()) {
            return FastCopyResult.cancelled;
          }
        }
      }

      return remaining == 0 ? FastCopyResult.done : FastCopyResult.unsupported;
    } catch (e, st) {
      log.warn('fs.copy', 'linux copy_file_range failed', error: e, stack: st);

      return FastCopyResult.unsupported;
    } finally {
      if (fdIn >= 0) {
        try {
          close(fdIn);
        } catch (e, st) {
          log.warn('fs.copy', 'failed to close input fd', error: e, stack: st);
        }
      }
      if (fdOut >= 0) {
        try {
          close(fdOut);
        } catch (e, st) {
          log.warn('fs.copy', 'failed to close output fd', error: e, stack: st);
        }
      }
      calloc.free(sPtr);
      calloc.free(dPtr);
    }
  }

  static void _rollbackReportedProgress(
    void Function(int bytes)? onProgress,
    int emitted,
  ) {
    if (emitted > 0) onProgress?.call(-emitted);
  }
}
