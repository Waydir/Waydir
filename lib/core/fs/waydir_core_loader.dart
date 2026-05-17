import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

typedef _SearchNative =
    Pointer<Uint8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Bool,
      Pointer<IntPtr>,
    );
typedef _SearchDart =
    Pointer<Uint8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      bool,
      Pointer<IntPtr>,
    );

typedef _FreeNative = Void Function(Pointer<Uint8>, IntPtr);
typedef _FreeDart = void Function(Pointer<Uint8>, int);

typedef _AbiNative = Uint32 Function();
typedef _AbiDart = int Function();

/// Loads the optional `waydir_core` native helper (Rust). Mirrors the
/// libarchive loader: best-effort, cached, never throws. When unavailable
/// the caller falls back to the pure-Dart implementation.
class WaydirCoreLoader {
  WaydirCoreLoader._();

  static DynamicLibrary? _cached;
  static bool _tried = false;

  static DynamicLibrary? load() {
    if (_tried) return _cached;
    _tried = true;
    for (final path in _candidatePaths()) {
      try {
        final lib = DynamicLibrary.open(path);
        final abi = lib
            .lookupFunction<_AbiNative, _AbiDart>('waydir_core_abi');
        if (abi() != 1) continue;
        _cached = lib;
        return lib;
      } catch (_) {}
    }
    return null;
  }

  /// Runs the native recursive search. Returns a FileEntryCodec buffer or
  /// null if the library is missing or the call failed.
  static Uint8List? search(String root, String query, bool includeHidden) {
    final lib = load();
    if (lib == null) return null;
    final search = lib.lookupFunction<_SearchNative, _SearchDart>(
      'waydir_search',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final rootPtr = root.toNativeUtf8();
    final queryPtr = query.toNativeUtf8();
    final outLen = calloc<IntPtr>();
    try {
      final buf = search(rootPtr, queryPtr, includeHidden, outLen);
      if (buf == nullptr) return null;
      final len = outLen.value;
      final copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return copy;
    } catch (_) {
      return null;
    } finally {
      calloc.free(rootPtr);
      calloc.free(queryPtr);
      calloc.free(outLen);
    }
  }

  static List<String> _candidatePaths() {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final lib = Platform.isWindows
        ? 'waydir_core.dll'
        : Platform.isMacOS
        ? 'libwaydir_core.dylib'
        : 'libwaydir_core.so';
    final devTarget = p.join(
      Directory.current.path,
      'rust',
      'waydir_core',
      'target',
      'release',
      lib,
    );
    return [
      p.join(exeDir, 'lib', lib),
      p.join(exeDir, lib),
      if (Platform.isMacOS)
        p.normalize(p.join(exeDir, '..', 'Frameworks', lib)),
      devTarget,
      lib,
    ];
  }
}
