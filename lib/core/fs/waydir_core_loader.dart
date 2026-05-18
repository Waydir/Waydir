import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../logging/app_logger.dart';

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

typedef _SearchStartNative =
    Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>, Bool);
typedef _SearchStartDart =
    Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>, bool);

typedef _SearchPollNative =
    Pointer<Uint8> Function(
      Pointer<Void>,
      Pointer<IntPtr>,
      Pointer<IntPtr>,
      Pointer<Int32>,
    );
typedef _SearchPollDart =
    Pointer<Uint8> Function(
      Pointer<Void>,
      Pointer<IntPtr>,
      Pointer<IntPtr>,
      Pointer<Int32>,
    );

typedef _SessionVoidNative = Void Function(Pointer<Void>);
typedef _SessionVoidDart = void Function(Pointer<Void>);

typedef _ListNative =
    Pointer<Uint8> Function(Pointer<Utf8>, Bool, Pointer<IntPtr>);
typedef _ListDart =
    Pointer<Uint8> Function(Pointer<Utf8>, bool, Pointer<IntPtr>);

typedef _EnumNative =
    Pointer<Uint8> Function(Pointer<Utf8>, Bool, Pointer<IntPtr>);
typedef _EnumDart =
    Pointer<Uint8> Function(Pointer<Utf8>, bool, Pointer<IntPtr>);

typedef _FreeNative = Void Function(Pointer<Uint8>, IntPtr);
typedef _FreeDart = void Function(Pointer<Uint8>, int);

typedef _AbiNative = Uint32 Function();
typedef _AbiDart = int Function();

typedef _StrNative = Pointer<Utf8> Function();
typedef _StrDart = Pointer<Utf8> Function();

/// Thrown when the required `waydir_core` native library cannot be loaded.
/// `waydir_core` is a hard dependency: directory listing, recursive search
/// and delete enumeration run exclusively in Rust — there is no Dart
/// fallback. A missing library is a deployment error, not a soft condition.
class WaydirCoreException implements Exception {
  final String message;
  const WaydirCoreException(this.message);
  @override
  String toString() => 'WaydirCoreException: $message';
}

class SearchPollResult {
  final Uint8List? batch;
  final int scanned;
  final bool done;
  const SearchPollResult(this.batch, this.scanned, this.done);
}

/// Loads the required `waydir_core` native helper (Rust). Cached.
/// [requireLib] throws [WaydirCoreException] if it is absent so callers
/// fail loudly instead of silently degrading.
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
        final abi = lib.lookupFunction<_AbiNative, _AbiDart>('waydir_core_abi');
        if (abi() < 1) continue;
        _cached = lib;
        return lib;
      } catch (_) {}
    }
    log.error(
      'ffi.waydir_core',
      'native waydir_core not found; searched: '
          '${_candidatePaths().join(", ")}',
    );
    return null;
  }

  static DynamicLibrary requireLib() {
    final lib = load();
    if (lib == null) {
      throw WaydirCoreException(
        'native waydir_core not found; searched: '
        '${_candidatePaths().join(", ")}',
      );
    }
    return lib;
  }

  /// Runs the native recursive search. Returns a FileEntryCodec buffer.
  /// Throws [WaydirCoreException] if the library is missing.
  static Uint8List? search(String root, String query, bool includeHidden) {
    final lib = requireLib();
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

  static int? searchStart(String root, String query, bool includeHidden) {
    final lib = requireLib();
    final start = lib.lookupFunction<_SearchStartNative, _SearchStartDart>(
      'waydir_search_start',
    );
    final rootPtr = root.toNativeUtf8();
    final queryPtr = query.toNativeUtf8();
    try {
      final session = start(rootPtr, queryPtr, includeHidden);
      if (session == nullptr) return null;
      return session.address;
    } catch (_) {
      return null;
    } finally {
      calloc.free(rootPtr);
      calloc.free(queryPtr);
    }
  }

  static SearchPollResult searchPoll(int session) {
    final lib = requireLib();
    final poll = lib.lookupFunction<_SearchPollNative, _SearchPollDart>(
      'waydir_search_poll',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final sessionPtr = Pointer<Void>.fromAddress(session);
    final outLen = calloc<IntPtr>();
    final outScanned = calloc<IntPtr>();
    final outDone = calloc<Int32>();
    try {
      final buf = poll(sessionPtr, outLen, outScanned, outDone);
      final scanned = outScanned.value;
      final done = outDone.value != 0;
      if (buf == nullptr) {
        return SearchPollResult(null, scanned, done);
      }
      final len = outLen.value;
      final copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return SearchPollResult(copy, scanned, done);
    } catch (_) {
      return const SearchPollResult(null, 0, true);
    } finally {
      calloc.free(outLen);
      calloc.free(outScanned);
      calloc.free(outDone);
    }
  }

  static void searchCancel(int session) {
    final lib = requireLib();
    final cancel = lib.lookupFunction<_SessionVoidNative, _SessionVoidDart>(
      'waydir_search_cancel',
    );
    cancel(Pointer<Void>.fromAddress(session));
  }

  static void searchFree(int session) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_SessionVoidNative, _SessionVoidDart>(
      'waydir_search_free',
    );
    fn(Pointer<Void>.fromAddress(session));
  }

  /// Native single-directory listing. Returns a FileEntryCodec buffer or
  /// null if unavailable / failed (e.g. unreadable directory).
  static Uint8List? listDir(String path, {bool withStat = true}) {
    final lib = requireLib();
    final list = lib.lookupFunction<_ListNative, _ListDart>('waydir_list');
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final pathPtr = path.toNativeUtf8();
    final outLen = calloc<IntPtr>();
    try {
      final buf = list(pathPtr, withStat, outLen);
      if (buf == nullptr) return null;
      final len = outLen.value;
      final copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return copy;
    } catch (_) {
      return null;
    } finally {
      calloc.free(pathPtr);
      calloc.free(outLen);
    }
  }

  /// Recursive enumeration for delete pre-scans. [postorder] yields
  /// deepest-first ordering. Returns a FileEntryCodec buffer or null.
  static Uint8List? enumerate(String root, {bool postorder = true}) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_EnumNative, _EnumDart>('waydir_enumerate');
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final rootPtr = root.toNativeUtf8();
    final outLen = calloc<IntPtr>();
    try {
      final buf = fn(rootPtr, postorder, outLen);
      if (buf == nullptr) return null;
      final len = outLen.value;
      final copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return copy;
    } catch (_) {
      return null;
    } finally {
      calloc.free(rootPtr);
      calloc.free(outLen);
    }
  }

  /// "{version} ({git}) abi={n}" for the loaded native lib, or null if
  /// the library is absent.
  static String? buildInfo() {
    final lib = load();
    if (lib == null) return null;
    String sym(String name) {
      try {
        return lib
            .lookupFunction<_StrNative, _StrDart>(name)()
            .toDartString();
      } catch (_) {
        return '?';
      }
    }

    int abi() {
      try {
        return lib.lookupFunction<_AbiNative, _AbiDart>('waydir_core_abi')();
      } catch (_) {
        return 0;
      }
    }

    return '${sym('waydir_core_version')} (${sym('waydir_core_git')}) '
        'abi=${abi()}';
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
