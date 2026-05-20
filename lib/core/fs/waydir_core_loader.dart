import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

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

typedef _FolderScanStartNative = Pointer<Void> Function(Pointer<Utf8>);
typedef _FolderScanStartDart = Pointer<Void> Function(Pointer<Utf8>);

typedef _FolderScanPollNative =
    Void Function(
      Pointer<Void>,
      Pointer<Uint64>,
      Pointer<IntPtr>,
      Pointer<Int32>,
    );
typedef _FolderScanPollDart =
    void Function(
      Pointer<Void>,
      Pointer<Uint64>,
      Pointer<IntPtr>,
      Pointer<Int32>,
    );

typedef _ListNative =
    Pointer<Uint8> Function(Pointer<Utf8>, Bool, Pointer<IntPtr>);
typedef _ListDart =
    Pointer<Uint8> Function(Pointer<Utf8>, bool, Pointer<IntPtr>);

typedef _EnumNative =
    Pointer<Uint8> Function(Pointer<Utf8>, Bool, Pointer<IntPtr>);
typedef _EnumDart =
    Pointer<Uint8> Function(Pointer<Utf8>, bool, Pointer<IntPtr>);

typedef _TrashNative =
    Pointer<Uint8> Function(Pointer<Pointer<Utf8>>, IntPtr, Pointer<IntPtr>);
typedef _TrashDart =
    Pointer<Uint8> Function(Pointer<Pointer<Utf8>>, int, Pointer<IntPtr>);

typedef _TrashListNative = Pointer<Uint8> Function(Pointer<IntPtr>);
typedef _TrashListDart = Pointer<Uint8> Function(Pointer<IntPtr>);

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

class FolderScanPollResult {
  final int bytes;
  final int items;
  final bool done;
  const FolderScanPollResult(this.bytes, this.items, this.done);
}

class WaydirTrashFailure {
  final String path;
  final String message;

  const WaydirTrashFailure(this.path, this.message);
}

class NativeTrashItem {
  final String id;
  final String name;
  final String originalPath;
  final DateTime deletedAt;
  final int size;
  final bool isDirectory;

  const NativeTrashItem({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.deletedAt,
    required this.size,
    required this.isDirectory,
  });
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

  static int? folderScanStart(String root) {
    final lib = requireLib();
    final start = lib
        .lookupFunction<_FolderScanStartNative, _FolderScanStartDart>(
          'waydir_folder_scan_start',
        );
    final rootPtr = root.toNativeUtf8();
    try {
      final session = start(rootPtr);
      if (session == nullptr) return null;
      return session.address;
    } catch (_) {
      return null;
    } finally {
      calloc.free(rootPtr);
    }
  }

  static FolderScanPollResult folderScanPoll(int session) {
    final lib = requireLib();
    final poll = lib.lookupFunction<_FolderScanPollNative, _FolderScanPollDart>(
      'waydir_folder_scan_poll',
    );
    final sessionPtr = Pointer<Void>.fromAddress(session);
    final outBytes = calloc<Uint64>();
    final outItems = calloc<IntPtr>();
    final outDone = calloc<Int32>();
    try {
      poll(sessionPtr, outBytes, outItems, outDone);
      return FolderScanPollResult(
        outBytes.value,
        outItems.value,
        outDone.value != 0,
      );
    } catch (_) {
      return const FolderScanPollResult(0, 0, true);
    } finally {
      calloc.free(outBytes);
      calloc.free(outItems);
      calloc.free(outDone);
    }
  }

  static void folderScanCancel(int session) {
    final lib = requireLib();
    final cancel = lib.lookupFunction<_SessionVoidNative, _SessionVoidDart>(
      'waydir_folder_scan_cancel',
    );
    cancel(Pointer<Void>.fromAddress(session));
  }

  static void folderScanFree(int session) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_SessionVoidNative, _SessionVoidDart>(
      'waydir_folder_scan_free',
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

  static List<WaydirTrashFailure> trash(List<String> paths) {
    if (paths.isEmpty) return const [];
    final lib = requireLib();
    final fn = lib.lookupFunction<_TrashNative, _TrashDart>('waydir_trash');
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final pathPtrs = calloc<Pointer<Utf8>>(paths.length);
    final allocated = <Pointer<Utf8>>[];
    final outLen = calloc<IntPtr>();
    try {
      for (var i = 0; i < paths.length; i++) {
        final ptr = paths[i].toNativeUtf8();
        allocated.add(ptr);
        pathPtrs[i] = ptr;
      }
      final buf = fn(pathPtrs, paths.length, outLen);
      if (buf == nullptr) return const [];
      final len = outLen.value;
      final bytes = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return _decodeTrashFailures(bytes);
    } finally {
      for (final ptr in allocated) {
        calloc.free(ptr);
      }
      calloc.free(pathPtrs);
      calloc.free(outLen);
    }
  }

  static List<NativeTrashItem> trashList() {
    final lib = requireLib();
    final fn = lib.lookupFunction<_TrashListNative, _TrashListDart>(
      'waydir_trash_list',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final outLen = calloc<IntPtr>();
    try {
      final buf = fn(outLen);
      if (buf == nullptr) return const [];
      final len = outLen.value;
      final bytes = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return _decodeNativeTrashItems(bytes);
    } finally {
      calloc.free(outLen);
    }
  }

  static List<WaydirTrashFailure> trashRestore(List<String> ids) =>
      _trashById('waydir_trash_restore', ids);

  static List<WaydirTrashFailure> trashPurge(List<String> ids) =>
      _trashById('waydir_trash_purge', ids);

  static List<WaydirTrashFailure> _trashById(String symbol, List<String> ids) {
    if (ids.isEmpty) return const [];
    final lib = requireLib();
    final fn = lib.lookupFunction<_TrashNative, _TrashDart>(symbol);
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final idPtrs = calloc<Pointer<Utf8>>(ids.length);
    final allocated = <Pointer<Utf8>>[];
    final outLen = calloc<IntPtr>();
    try {
      for (var i = 0; i < ids.length; i++) {
        final ptr = ids[i].toNativeUtf8();
        allocated.add(ptr);
        idPtrs[i] = ptr;
      }
      final buf = fn(idPtrs, ids.length, outLen);
      if (buf == nullptr) return const [];
      final len = outLen.value;
      final bytes = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return _decodeTrashFailures(bytes);
    } finally {
      for (final ptr in allocated) {
        calloc.free(ptr);
      }
      calloc.free(idPtrs);
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
        return lib.lookupFunction<_StrNative, _StrDart>(name)().toDartString();
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

  static List<WaydirTrashFailure> _decodeTrashFailures(Uint8List bytes) {
    final failures = <WaydirTrashFailure>[];
    final data = ByteData.sublistView(bytes);
    var off = 0;
    while (off + 8 <= bytes.length) {
      final pathLen = data.getUint32(off);
      final msgLen = data.getUint32(off + 4);
      off += 8;
      if (off + pathLen + msgLen > bytes.length) break;
      final path = utf8.decode(bytes.sublist(off, off + pathLen));
      off += pathLen;
      final msg = utf8.decode(bytes.sublist(off, off + msgLen));
      off += msgLen;
      failures.add(WaydirTrashFailure(path, msg));
    }
    return failures;
  }

  static List<NativeTrashItem> _decodeNativeTrashItems(Uint8List bytes) {
    final items = <NativeTrashItem>[];
    final data = ByteData.sublistView(bytes);
    var off = 0;
    if (bytes.length < 4) return const [];
    final count = data.getUint32(off);
    off += 4;

    String? readString() {
      if (off + 4 > bytes.length) return null;
      final len = data.getUint32(off);
      off += 4;
      if (off + len > bytes.length) return null;
      final value = utf8.decode(bytes.sublist(off, off + len));
      off += len;
      return value;
    }

    for (var i = 0; i < count; i++) {
      final id = readString();
      final name = readString();
      final originalPath = readString();
      if (id == null || name == null || originalPath == null) break;
      if (off + 17 > bytes.length) break;
      final deletedAtMs = data.getUint64(off);
      off += 8;
      final size = data.getUint64(off);
      off += 8;
      final isDirectory = bytes[off] != 0;
      off += 1;
      items.add(
        NativeTrashItem(
          id: id,
          name: name,
          originalPath: originalPath,
          deletedAt: DateTime.fromMillisecondsSinceEpoch(
            deletedAtMs,
            isUtc: true,
          ).toLocal(),
          size: size,
          isDirectory: isDirectory,
        ),
      );
    }
    return items;
  }
}
