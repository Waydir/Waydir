import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// Linux open() flags (x86_64/arm64 share these values).
const int _oRdonly = 0;
const int _oWronly = 1;
const int _oCreat = 0x40;
const int _oTrunc = 0x200;
const int _oCloexec = 0x80000;

typedef _OpenNative = Int32 Function(Pointer<Utf8>, Int32, Uint32);
typedef _OpenDart = int Function(Pointer<Utf8>, int, int);

typedef _CloseNative = Int32 Function(Int32);
typedef _CloseDart = int Function(int);

// ssize_t copy_file_range(int, loff_t*, int, loff_t*, size_t, unsigned)
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

// int clonefile(const char*, const char*, int) — macOS.
typedef _CloneNative = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _CloneDart = int Function(Pointer<Utf8>, Pointer<Utf8>, int);

/// Best-effort native fast-copy. Uses copy_file_range on Linux (server-side
/// / reflink copy) and clonefile on macOS (APFS copy-on-write). Returns
/// false on any failure so the caller falls back to a portable copy.
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
    } catch (_) {}
    return null;
  }

  static bool tryFastCopy(
    String sourcePath,
    String destinationPath, {
    void Function(int bytes)? onProgress,
  }) {
    final lib = _lib;
    if (lib == null) return false;
    if (Platform.isLinux) {
      return _linuxCopyFileRange(lib, sourcePath, destinationPath, onProgress);
    }
    if (Platform.isMacOS) {
      return _macClonefile(lib, sourcePath, destinationPath, onProgress);
    }
    return false;
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
        } catch (_) {}
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      calloc.free(s);
      calloc.free(d);
    }
  }

  // Cap per-syscall transfer so progress can be reported on big files.
  static const int _cfrChunk = 32 * 1024 * 1024;

  static bool _linuxCopyFileRange(
    DynamicLibrary lib,
    String src,
    String dst,
    void Function(int bytes)? onProgress,
  ) {
    final open = lib.lookupFunction<_OpenNative, _OpenDart>('open');
    final close = lib.lookupFunction<_CloseNative, _CloseDart>('close');
    final cfr = lib.lookupFunction<_CfrNative, _CfrDart>('copy_file_range');

    final int total;
    try {
      total = File(src).lengthSync();
    } catch (_) {
      return false;
    }

    final sPtr = src.toNativeUtf8();
    final dPtr = dst.toNativeUtf8();
    int fdIn = -1;
    int fdOut = -1;
    try {
      fdIn = open(sPtr, _oRdonly | _oCloexec, 0);
      if (fdIn < 0) return false;
      fdOut = open(dPtr, _oWronly | _oCreat | _oTrunc | _oCloexec, 0x1A4);
      if (fdOut < 0) return false;

      if (total == 0) return true; // empty file: fds created the target.

      var remaining = total;
      var emitted = 0;
      while (remaining > 0) {
        final want = remaining < _cfrChunk ? remaining : _cfrChunk;
        final n = cfr(fdIn, nullptr, fdOut, nullptr, want, 0);
        if (n < 0) {
          // Partial fail: undo reported bytes so the portable fallback,
          // which recopies the whole file, does not double-count.
          if (emitted > 0) onProgress?.call(-emitted);
          return false; // EXDEV/ENOSYS/EINVAL → fall back.
        }
        if (n == 0) break; // unexpected short source.
        remaining -= n;
        emitted += n;
        onProgress?.call(n);
      }
      return remaining == 0;
    } catch (_) {
      return false;
    } finally {
      if (fdIn >= 0) {
        try {
          close(fdIn);
        } catch (_) {}
      }
      if (fdOut >= 0) {
        try {
          close(fdOut);
        } catch (_) {}
      }
      calloc.free(sPtr);
      calloc.free(dPtr);
    }
  }
}
