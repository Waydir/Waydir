import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import '../../i18n/strings.g.dart';
import '../logging/app_logger.dart';

typedef _SearchNative =
    Pointer<Uint8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Bool,
      Uint8,
      Bool,
      Uint32,
      Pointer<IntPtr>,
    );
typedef _SearchDart =
    Pointer<Uint8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      bool,
      int,
      bool,
      int,
      Pointer<IntPtr>,
    );

typedef _SearchStartNative =
    Pointer<Void> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Bool,
      Uint8,
      Bool,
      Uint32,
    );
typedef _SearchStartDart =
    Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>, bool, int, bool, int);

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

// PTY

typedef _PtyOpenNative =
    Uint64 Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Uint16,
      Uint16,
    );
typedef _PtyOpenDart =
    int Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int, int);

typedef _PtyReadNative = Pointer<Uint8> Function(Uint64, Pointer<IntPtr>);
typedef _PtyReadDart = Pointer<Uint8> Function(int, Pointer<IntPtr>);

typedef _PtyWriteNative = Int32 Function(Uint64, Pointer<Uint8>, IntPtr);
typedef _PtyWriteDart = int Function(int, Pointer<Uint8>, int);

typedef _PtyResizeNative = Int32 Function(Uint64, Uint16, Uint16);
typedef _PtyResizeDart = int Function(int, int, int);

typedef _PtyAliveNative = Int32 Function(Uint64);
typedef _PtyAliveDart = int Function(int);

typedef _PtyCloseNative = Void Function(Uint64);
typedef _PtyCloseDart = void Function(int);

typedef _AbiNative = Uint32 Function();
typedef _AbiDart = int Function();

typedef _StrNative = Pointer<Utf8> Function();
typedef _StrDart = Pointer<Utf8> Function();

// PDF

typedef _PdfSizesNative =
    Pointer<Uint8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<IntPtr>);
typedef _PdfSizesDart =
    Pointer<Uint8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<IntPtr>);

typedef _PdfRenderNative =
    Pointer<Uint8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Int32,
      Int32,
      Pointer<Int32>,
      Pointer<Int32>,
      Pointer<IntPtr>,
    );
typedef _PdfRenderDart =
    Pointer<Uint8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      int,
      int,
      Pointer<Int32>,
      Pointer<Int32>,
      Pointer<IntPtr>,
    );

// SFTP

final class SftpStatStruct extends Struct {
  @Int32()
  external int exists;
  @Int32()
  external int isDir;
  @Int64()
  external int size;
  @Int64()
  external int mtimeMs;
}

typedef _SftpOpenNative =
    Pointer<Utf8> Function(
      Pointer<Utf8>,
      Uint16,
      Pointer<Utf8>,
      Uint32,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Uint32>,
      Pointer<Uint64>,
    );
typedef _SftpOpenDart =
    Pointer<Utf8> Function(
      Pointer<Utf8>,
      int,
      Pointer<Utf8>,
      int,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Uint32>,
      Pointer<Uint64>,
    );

typedef _SftpCloseNative = Void Function(Uint64);
typedef _SftpCloseDart = void Function(int);

typedef _SftpRealPathNative = Pointer<Utf8> Function(Uint64, Pointer<Utf8>);
typedef _SftpRealPathDart = Pointer<Utf8> Function(int, Pointer<Utf8>);

typedef _SftpListNative =
    Pointer<Uint8> Function(Uint64, Pointer<Utf8>, Pointer<IntPtr>);
typedef _SftpListDart =
    Pointer<Uint8> Function(int, Pointer<Utf8>, Pointer<IntPtr>);

typedef _SftpStatNative =
    Int32 Function(Uint64, Pointer<Utf8>, Pointer<SftpStatStruct>);
typedef _SftpStatDart =
    int Function(int, Pointer<Utf8>, Pointer<SftpStatStruct>);

typedef _SftpReadNative =
    Pointer<Uint8> Function(Uint64, Pointer<Utf8>, Pointer<IntPtr>);
typedef _SftpReadDart =
    Pointer<Uint8> Function(int, Pointer<Utf8>, Pointer<IntPtr>);

typedef _SftpReadRangeNative =
    Pointer<Uint8> Function(
      Uint64,
      Pointer<Utf8>,
      Int64,
      Int64,
      Pointer<IntPtr>,
    );
typedef _SftpReadRangeDart =
    Pointer<Uint8> Function(int, Pointer<Utf8>, int, int, Pointer<IntPtr>);

typedef _SftpWriteNative =
    Int32 Function(Uint64, Pointer<Utf8>, Pointer<Uint8>, IntPtr);
typedef _SftpWriteDart = int Function(int, Pointer<Utf8>, Pointer<Uint8>, int);

typedef _SftpWriteChunkNative =
    Int32 Function(Uint64, Pointer<Utf8>, Pointer<Uint8>, IntPtr, Int32);
typedef _SftpWriteChunkDart =
    int Function(int, Pointer<Utf8>, Pointer<Uint8>, int, int);

typedef _SftpMkdirNative = Int32 Function(Uint64, Pointer<Utf8>, Int32);
typedef _SftpMkdirDart = int Function(int, Pointer<Utf8>, int);

typedef _SftpRemoveNative = Int32 Function(Uint64, Pointer<Utf8>, Int32);
typedef _SftpRemoveDart = int Function(int, Pointer<Utf8>, int);

typedef _SftpRenameNative =
    Int32 Function(Uint64, Pointer<Utf8>, Pointer<Utf8>);
typedef _SftpRenameDart = int Function(int, Pointer<Utf8>, Pointer<Utf8>);

typedef _SftpFreeStrNative = Void Function(Pointer<Utf8>);
typedef _SftpFreeStrDart = void Function(Pointer<Utf8>);

typedef _SftpOpenWriterNative =
    Int32 Function(Uint64, Pointer<Utf8>, Int32, Pointer<Uint64>);
typedef _SftpOpenWriterDart =
    int Function(int, Pointer<Utf8>, int, Pointer<Uint64>);

typedef _SftpWriterWriteNative = Int32 Function(Uint64, Pointer<Uint8>, IntPtr);
typedef _SftpWriterWriteDart = int Function(int, Pointer<Uint8>, int);

typedef _SftpWriterCloseNative = Int32 Function(Uint64);
typedef _SftpWriterCloseDart = int Function(int);

typedef _SftpOpenReaderNative =
    Int32 Function(Uint64, Pointer<Utf8>, Pointer<Uint64>, Pointer<Int64>);
typedef _SftpOpenReaderDart =
    int Function(int, Pointer<Utf8>, Pointer<Uint64>, Pointer<Int64>);

typedef _SftpReaderReadNative =
    Pointer<Uint8> Function(Uint64, IntPtr, Pointer<IntPtr>);
typedef _SftpReaderReadDart =
    Pointer<Uint8> Function(int, int, Pointer<IntPtr>);

typedef _SftpReaderCloseNative = Int32 Function(Uint64);
typedef _SftpReaderCloseDart = int Function(int);

class SftpOpenResult {
  /// 0 = ok, 1 = auth required, 2 = error
  final int status;
  final int sessionId;
  final String? errorMessage;

  const SftpOpenResult({
    required this.status,
    required this.sessionId,
    this.errorMessage,
  });

  bool get isOk => status == 0;
  bool get isAuthRequired => status == 1;
  bool get isError => status == 2;
}

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

class PdfRenderedPage {
  final int width;
  final int height;
  final Uint8List rgba;
  const PdfRenderedPage(this.width, this.height, this.rgba);
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

  static const int _requiredAbi = 16;

  static DynamicLibrary? _cached;
  static bool _tried = false;
  static String? _resolvedPath;
  static final Set<String> _warnedNativeOps = {};

  static void _warnNative(
    String operation,
    Object error,
    StackTrace stack, {
    bool once = false,
  }) {
    if (once && !_warnedNativeOps.add(operation)) return;
    log.warn(
      'ffi.waydir_core',
      '$operation failed',
      error: error,
      stack: stack,
    );
  }

  static DynamicLibrary? load() {
    if (_tried) return _cached;
    _tried = true;
    final failures = <String>[];
    for (final path in _candidatePaths()) {
      try {
        final lib = DynamicLibrary.open(path);
        final abi = lib.lookupFunction<_AbiNative, _AbiDart>('waydir_core_abi');
        final value = abi();
        if (value < _requiredAbi) {
          failures.add('$path: abi $value < required $_requiredAbi');
          continue;
        }
        _cached = lib;
        _resolvedPath = path;
        return lib;
      } catch (e) {
        failures.add('$path: $e');
      }
    }
    log.error(
      'ffi.waydir_core',
      '${t.errors.nativeCoreNotFound(paths: _candidatePaths().join(', '))}'
          ' | ${failures.join(' | ')}',
    );
    return null;
  }

  static DynamicLibrary requireLib() {
    final lib = load();
    if (lib == null) {
      throw WaydirCoreException(
        t.errors.nativeCoreNotFound(paths: _candidatePaths().join(', ')),
      );
    }
    return lib;
  }

  /// Runs the native recursive search. Returns a FileEntryCodec buffer.
  /// Throws [WaydirCoreException] if the library is missing.
  static Uint8List? search(
    String root,
    String query,
    bool includeHidden, {
    int mode = 0,
    bool content = false,
    int maxDepth = 0,
  }) {
    final lib = requireLib();
    final search = lib.lookupFunction<_SearchNative, _SearchDart>(
      'waydir_search',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final rootPtr = root.toNativeUtf8();
    final queryPtr = query.toNativeUtf8();
    final outLen = calloc<IntPtr>();
    try {
      final buf = search(
        rootPtr,
        queryPtr,
        includeHidden,
        mode,
        content,
        maxDepth,
        outLen,
      );
      if (buf == nullptr) return null;
      final len = outLen.value;
      final copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return copy;
    } catch (e, st) {
      _warnNative('search', e, st);
      return null;
    } finally {
      calloc.free(rootPtr);
      calloc.free(queryPtr);
      calloc.free(outLen);
    }
  }

  static int? searchStart(
    String root,
    String query,
    bool includeHidden, {
    int mode = 0,
    bool content = false,
    int maxDepth = 0,
  }) {
    final lib = requireLib();
    final start = lib.lookupFunction<_SearchStartNative, _SearchStartDart>(
      'waydir_search_start',
    );
    final rootPtr = root.toNativeUtf8();
    final queryPtr = query.toNativeUtf8();
    try {
      final session = start(
        rootPtr,
        queryPtr,
        includeHidden,
        mode,
        content,
        maxDepth,
      );
      if (session == nullptr) return null;
      return session.address;
    } catch (e, st) {
      _warnNative('search start', e, st);
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
    } catch (e, st) {
      _warnNative('search poll', e, st);
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
    } catch (e, st) {
      _warnNative('folder scan start', e, st);
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
    } catch (e, st) {
      _warnNative('folder scan poll', e, st);
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
    } catch (e, st) {
      _warnNative('list dir', e, st);
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
    } catch (e, st) {
      _warnNative('enumerate', e, st);
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
      final items = _decodeNativeTrashItems(bytes);
      log.warn(
        'ffi.trash',
        'native trash list returned ${items.length} entries; ${buildInfo()}',
      );
      return items;
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
      } catch (e, st) {
        _warnNative('read native version symbol $name', e, st, once: true);
        return '?';
      }
    }

    int abi() {
      try {
        return lib.lookupFunction<_AbiNative, _AbiDart>('waydir_core_abi')();
      } catch (e, st) {
        _warnNative('read native ABI symbol', e, st, once: true);
        return 0;
      }
    }

    return '${sym('waydir_core_version')} (${sym('waydir_core_git')}) '
        'abi=${abi()}';
  }

  static SftpOpenResult sftpOpen({
    required String host,
    required int port,
    required String user,
    required int authKind,
    String? password,
    String? keyPath,
    String? passphrase,
  }) {
    final lib = requireLib();
    final open = lib.lookupFunction<_SftpOpenNative, _SftpOpenDart>(
      'waydir_sftp_session_open',
    );
    final freeStr = lib.lookupFunction<_SftpFreeStrNative, _SftpFreeStrDart>(
      'waydir_sftp_free_cstr',
    );
    final hostP = host.toNativeUtf8();
    final userP = user.toNativeUtf8();
    final passP = (password ?? '').isEmpty
        ? nullptr.cast<Utf8>()
        : password!.toNativeUtf8();
    final keyP = (keyPath ?? '').isEmpty
        ? nullptr.cast<Utf8>()
        : keyPath!.toNativeUtf8();
    final phP = (passphrase ?? '').isEmpty
        ? nullptr.cast<Utf8>()
        : passphrase!.toNativeUtf8();
    final outStatus = calloc<Uint32>();
    final outSession = calloc<Uint64>();
    try {
      final errPtr = open(
        hostP,
        port,
        userP,
        authKind,
        passP,
        keyP,
        phP,
        outStatus,
        outSession,
      );
      String? errMsg;
      if (errPtr != nullptr) {
        errMsg = errPtr.toDartString();
        freeStr(errPtr);
      }
      return SftpOpenResult(
        status: outStatus.value,
        sessionId: outSession.value,
        errorMessage: errMsg,
      );
    } finally {
      calloc.free(hostP);
      calloc.free(userP);
      if (passP != nullptr) calloc.free(passP);
      if (keyP != nullptr) calloc.free(keyP);
      if (phP != nullptr) calloc.free(phP);
      calloc.free(outStatus);
      calloc.free(outSession);
    }
  }

  static void sftpClose(int sessionId) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_SftpCloseNative, _SftpCloseDart>(
      'waydir_sftp_session_close',
    );
    fn(sessionId);
  }

  static String? sftpRealPath(int sessionId, String path) {
    final lib = requireLib();
    final _SftpRealPathDart fn;
    final _SftpFreeStrDart freeStr;
    try {
      fn = lib.lookupFunction<_SftpRealPathNative, _SftpRealPathDart>(
        'waydir_sftp_realpath',
      );
      freeStr = lib.lookupFunction<_SftpFreeStrNative, _SftpFreeStrDart>(
        'waydir_sftp_free_cstr',
      );
    } catch (e, st) {
      _warnNative('sftp realpath symbol lookup', e, st, once: true);
      return null;
    }
    final pathP = path.toNativeUtf8();
    try {
      final ptr = fn(sessionId, pathP);
      if (ptr == nullptr) return null;
      final out = ptr.toDartString();
      freeStr(ptr);
      return out;
    } finally {
      calloc.free(pathP);
    }
  }

  static Uint8List? sftpList(int sessionId, String path) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_SftpListNative, _SftpListDart>(
      'waydir_sftp_list',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final pathP = path.toNativeUtf8();
    final outLen = calloc<IntPtr>();
    try {
      final buf = fn(sessionId, pathP, outLen);
      if (buf == nullptr) return null;
      final len = outLen.value;
      final copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return copy;
    } finally {
      calloc.free(pathP);
      calloc.free(outLen);
    }
  }

  static ({bool exists, bool isDir, int size, int mtimeMs})? sftpStat(
    int sessionId,
    String path,
  ) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_SftpStatNative, _SftpStatDart>(
      'waydir_sftp_stat',
    );
    final pathP = path.toNativeUtf8();
    final outStat = calloc<SftpStatStruct>();
    try {
      final rc = fn(sessionId, pathP, outStat);
      if (rc != 0) return null;
      return (
        exists: outStat.ref.exists != 0,
        isDir: outStat.ref.isDir != 0,
        size: outStat.ref.size,
        mtimeMs: outStat.ref.mtimeMs,
      );
    } finally {
      calloc.free(pathP);
      calloc.free(outStat);
    }
  }

  static Uint8List? sftpRead(
    int sessionId,
    String path, {
    int start = -1,
    int length = -1,
  }) {
    final lib = requireLib();
    final rangeRequested = start >= 0 || length >= 0;
    _SftpReadRangeDart? rangeFn;
    if (rangeRequested) {
      try {
        rangeFn = lib.lookupFunction<_SftpReadRangeNative, _SftpReadRangeDart>(
          'waydir_sftp_read_range',
        );
      } catch (e, st) {
        _warnNative('sftp read range symbol lookup', e, st, once: true);
      }
    }
    final fn = rangeFn == null
        ? lib.lookupFunction<_SftpReadNative, _SftpReadDart>('waydir_sftp_read')
        : null;
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final pathP = path.toNativeUtf8();
    final outLen = calloc<IntPtr>();
    try {
      final buf = rangeFn == null
          ? fn!(sessionId, pathP, outLen)
          : rangeFn(sessionId, pathP, start, length, outLen);
      if (buf == nullptr) return null;
      final len = outLen.value;
      var copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      if (rangeRequested && rangeFn == null) {
        final s = start > 0 ? start : 0;
        if (s >= copy.length) return Uint8List(0);
        final end = length > 0
            ? s + length > copy.length
                  ? copy.length
                  : s + length
            : copy.length;
        copy = Uint8List.sublistView(copy, s, end);
      }
      return copy;
    } finally {
      calloc.free(pathP);
      calloc.free(outLen);
    }
  }

  static bool sftpWrite(int sessionId, String path, Uint8List data) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_SftpWriteNative, _SftpWriteDart>(
      'waydir_sftp_write',
    );
    final pathP = path.toNativeUtf8();
    final dataPtr = calloc<Uint8>(data.length);
    try {
      if (data.isNotEmpty) {
        dataPtr.asTypedList(data.length).setRange(0, data.length, data);
      }
      return fn(sessionId, pathP, dataPtr, data.length) == 0;
    } finally {
      calloc.free(pathP);
      calloc.free(dataPtr);
    }
  }

  static bool supportsSftpWriteChunk() {
    final lib = requireLib();
    try {
      lib.lookupFunction<_SftpWriteChunkNative, _SftpWriteChunkDart>(
        'waydir_sftp_write_chunk',
      );
      return true;
    } catch (e, st) {
      _warnNative('sftp write chunk support lookup', e, st, once: true);
      return false;
    }
  }

  static bool sftpWriteChunk(
    int sessionId,
    String path,
    Uint8List data, {
    required bool append,
  }) {
    final lib = requireLib();
    final _SftpWriteChunkDart fn;
    try {
      fn = lib.lookupFunction<_SftpWriteChunkNative, _SftpWriteChunkDart>(
        'waydir_sftp_write_chunk',
      );
    } catch (e, st) {
      _warnNative('sftp write chunk symbol lookup', e, st, once: true);
      return false;
    }
    final pathP = path.toNativeUtf8();
    final dataPtr = calloc<Uint8>(data.length);
    try {
      if (data.isNotEmpty) {
        dataPtr.asTypedList(data.length).setRange(0, data.length, data);
      }
      return fn(sessionId, pathP, dataPtr, data.length, append ? 1 : 0) == 0;
    } finally {
      calloc.free(pathP);
      calloc.free(dataPtr);
    }
  }

  static bool supportsSftpStreaming() {
    final lib = requireLib();
    try {
      lib.lookupFunction<_SftpOpenWriterNative, _SftpOpenWriterDart>(
        'waydir_sftp_open_writer',
      );
      lib.lookupFunction<_SftpReaderReadNative, _SftpReaderReadDart>(
        'waydir_sftp_reader_read',
      );
      return true;
    } catch (e, st) {
      _warnNative('sftp streaming support lookup', e, st, once: true);
      return false;
    }
  }

  static int? sftpOpenWriter(
    int sessionId,
    String path, {
    bool append = false,
  }) {
    final lib = requireLib();
    final _SftpOpenWriterDart fn;
    try {
      fn = lib.lookupFunction<_SftpOpenWriterNative, _SftpOpenWriterDart>(
        'waydir_sftp_open_writer',
      );
    } catch (e, st) {
      _warnNative('sftp open writer symbol lookup', e, st, once: true);
      return null;
    }
    final pathP = path.toNativeUtf8();
    final outId = calloc<Uint64>();
    try {
      final rc = fn(sessionId, pathP, append ? 1 : 0, outId);
      if (rc != 0) return null;
      return outId.value;
    } finally {
      calloc.free(pathP);
      calloc.free(outId);
    }
  }

  static bool sftpWriterWrite(int writerId, Uint8List data) {
    final lib = requireLib();
    final _SftpWriterWriteDart fn;
    try {
      fn = lib.lookupFunction<_SftpWriterWriteNative, _SftpWriterWriteDart>(
        'waydir_sftp_writer_write',
      );
    } catch (e, st) {
      _warnNative('sftp writer write symbol lookup', e, st, once: true);
      return false;
    }
    if (data.isEmpty) {
      return fn(writerId, nullptr, 0) == 0;
    }
    final dataPtr = calloc<Uint8>(data.length);
    try {
      dataPtr.asTypedList(data.length).setRange(0, data.length, data);
      return fn(writerId, dataPtr, data.length) == 0;
    } finally {
      calloc.free(dataPtr);
    }
  }

  static bool sftpWriterClose(int writerId) {
    final lib = requireLib();
    final _SftpWriterCloseDart fn;
    try {
      fn = lib.lookupFunction<_SftpWriterCloseNative, _SftpWriterCloseDart>(
        'waydir_sftp_writer_close',
      );
    } catch (e, st) {
      _warnNative('sftp writer close symbol lookup', e, st, once: true);
      return false;
    }
    return fn(writerId) == 0;
  }

  static ({int readerId, int size})? sftpOpenReader(
    int sessionId,
    String path,
  ) {
    final lib = requireLib();
    final _SftpOpenReaderDart fn;
    try {
      fn = lib.lookupFunction<_SftpOpenReaderNative, _SftpOpenReaderDart>(
        'waydir_sftp_open_reader',
      );
    } catch (e, st) {
      _warnNative('sftp open reader symbol lookup', e, st, once: true);
      return null;
    }
    final pathP = path.toNativeUtf8();
    final outId = calloc<Uint64>();
    final outSize = calloc<Int64>();
    try {
      final rc = fn(sessionId, pathP, outId, outSize);
      if (rc != 0) return null;
      return (readerId: outId.value, size: outSize.value);
    } finally {
      calloc.free(pathP);
      calloc.free(outId);
      calloc.free(outSize);
    }
  }

  static Uint8List? sftpReaderRead(int readerId, int maxLen) {
    final lib = requireLib();
    final _SftpReaderReadDart fn;
    try {
      fn = lib.lookupFunction<_SftpReaderReadNative, _SftpReaderReadDart>(
        'waydir_sftp_reader_read',
      );
    } catch (e, st) {
      _warnNative('sftp reader read symbol lookup', e, st, once: true);
      return null;
    }
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final outLen = calloc<IntPtr>();
    try {
      final buf = fn(readerId, maxLen, outLen);
      if (buf == nullptr) return null;
      final len = outLen.value;
      final copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return copy;
    } finally {
      calloc.free(outLen);
    }
  }

  static bool sftpReaderClose(int readerId) {
    final lib = requireLib();
    final _SftpReaderCloseDart fn;
    try {
      fn = lib.lookupFunction<_SftpReaderCloseNative, _SftpReaderCloseDart>(
        'waydir_sftp_reader_close',
      );
    } catch (e, st) {
      _warnNative('sftp reader close symbol lookup', e, st, once: true);
      return false;
    }
    return fn(readerId) == 0;
  }

  static bool sftpMkdir(int sessionId, String path, {bool recursive = false}) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_SftpMkdirNative, _SftpMkdirDart>(
      'waydir_sftp_mkdir',
    );
    final pathP = path.toNativeUtf8();
    try {
      return fn(sessionId, pathP, recursive ? 1 : 0) == 0;
    } finally {
      calloc.free(pathP);
    }
  }

  static bool sftpRemove(int sessionId, String path, {bool recursive = false}) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_SftpRemoveNative, _SftpRemoveDart>(
      'waydir_sftp_remove',
    );
    final pathP = path.toNativeUtf8();
    try {
      return fn(sessionId, pathP, recursive ? 1 : 0) == 0;
    } finally {
      calloc.free(pathP);
    }
  }

  static bool sftpRename(int sessionId, String from, String to) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_SftpRenameNative, _SftpRenameDart>(
      'waydir_sftp_rename',
    );
    final fromP = from.toNativeUtf8();
    final toP = to.toNativeUtf8();
    try {
      return fn(sessionId, fromP, toP) == 0;
    } finally {
      calloc.free(fromP);
      calloc.free(toP);
    }
  }

  static bool supportsPty() {
    final lib = load();
    if (lib == null) return false;
    try {
      lib.lookupFunction<_PtyOpenNative, _PtyOpenDart>('waydir_pty_open');
      return true;
    } catch (e, st) {
      _warnNative('pty support lookup', e, st, once: true);
      return false;
    }
  }

  /// Spawns a shell on a pseudo-terminal. Returns the session id, or null.
  static int? ptyOpen({
    required String shell,
    required String cwd,
    required int cols,
    required int rows,
    List<String> args = const [],
  }) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_PtyOpenNative, _PtyOpenDart>(
      'waydir_pty_open',
    );
    final shellPtr = shell.toNativeUtf8();
    final cwdPtr = cwd.toNativeUtf8();
    final argsPtr = args.join('\n').toNativeUtf8();
    try {
      final id = fn(shellPtr, cwdPtr, argsPtr, cols, rows);
      return id == 0 ? null : id;
    } catch (e, st) {
      _warnNative('pty open', e, st);
      return null;
    } finally {
      calloc.free(shellPtr);
      calloc.free(cwdPtr);
      calloc.free(argsPtr);
    }
  }

  // Resolved once and reused: the pty hot path runs on a timer many times a
  // second per terminal, so a dlsym per call is pure overhead.
  static _PtyReadDart? _ptyReadFn;
  static _PtyWriteDart? _ptyWriteFn;
  static _PtyAliveDart? _ptyAliveFn;
  static _FreeDart? _freeFn;

  /// Drains pending shell output, or null if nothing is buffered.
  static Uint8List? ptyRead(int id) {
    final lib = requireLib();
    final fn = _ptyReadFn ??= lib.lookupFunction<_PtyReadNative, _PtyReadDart>(
      'waydir_pty_read',
    );
    final free = _freeFn ??= lib.lookupFunction<_FreeNative, _FreeDart>(
      'waydir_free',
    );
    final outLen = calloc<IntPtr>();
    try {
      final buf = fn(id, outLen);
      if (buf == nullptr) return null;
      final len = outLen.value;
      final copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return copy;
    } catch (e, st) {
      _warnNative('pty read', e, st);
      return null;
    } finally {
      calloc.free(outLen);
    }
  }

  static void ptyWrite(int id, Uint8List data) {
    if (data.isEmpty) return;
    final lib = requireLib();
    final fn = _ptyWriteFn ??= lib
        .lookupFunction<_PtyWriteNative, _PtyWriteDart>('waydir_pty_write');
    final dataPtr = calloc<Uint8>(data.length);
    try {
      dataPtr.asTypedList(data.length).setRange(0, data.length, data);
      fn(id, dataPtr, data.length);
    } finally {
      calloc.free(dataPtr);
    }
  }

  static void ptyResize(int id, int cols, int rows) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_PtyResizeNative, _PtyResizeDart>(
      'waydir_pty_resize',
    );
    fn(id, cols, rows);
  }

  static bool ptyAlive(int id) {
    final lib = requireLib();
    final fn = _ptyAliveFn ??= lib
        .lookupFunction<_PtyAliveNative, _PtyAliveDart>('waydir_pty_alive');
    return fn(id) != 0;
  }

  static void ptyClose(int id) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_PtyCloseNative, _PtyCloseDart>(
      'waydir_pty_close',
    );
    fn(id);
  }

  /// Full path to the vendored Pdfium library, resolved next to the loaded
  /// `waydir_core`. Empty string when the core was found by bare name, letting
  /// the native side fall back to a system-installed Pdfium.
  static String _pdfiumPath() {
    final core = _resolvedPath;
    if (core == null || !core.contains(Platform.pathSeparator)) return '';
    final name = Platform.isWindows
        ? 'pdfium.dll'
        : Platform.isMacOS
        ? 'libpdfium.dylib'
        : 'libpdfium.so';
    return p.join(p.dirname(core), name);
  }

  /// Aspect ratio (height / width) of every page in [pdfPath]. Lets the UI
  /// reserve each page's height before it is rendered, keeping the scrollbar
  /// stable. Returns null on failure.
  static List<double>? pdfPageAspects(String pdfPath) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_PdfSizesNative, _PdfSizesDart>(
      'waydir_pdf_page_sizes',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final libPtr = _pdfiumPath().toNativeUtf8();
    final pathPtr = pdfPath.toNativeUtf8();
    final outLen = calloc<IntPtr>();
    try {
      final buf = fn(libPtr, pathPtr, outLen);
      if (buf == nullptr) return null;
      final len = outLen.value;
      final bytes = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      final data = ByteData.sublistView(bytes);
      final count = data.getUint32(0, Endian.big);
      final aspects = <double>[];
      var off = 4;
      for (var i = 0; i < count && off + 8 <= bytes.length; i++) {
        final w = data.getFloat32(off, Endian.big);
        final h = data.getFloat32(off + 4, Endian.big);
        off += 8;
        aspects.add(w > 0 && h > 0 ? h / w : 1.414);
      }
      return aspects;
    } catch (e, st) {
      _warnNative('PDF page aspects', e, st);
      return null;
    } finally {
      calloc.free(libPtr);
      calloc.free(pathPtr);
      calloc.free(outLen);
    }
  }

  /// Renders page [pageIndex] of [pdfPath] to an RGBA8888 buffer scaled to
  /// [targetWidth]. Returns null on failure. Runs synchronously and blocks the
  /// calling isolate, so callers should invoke it off the UI thread.
  static PdfRenderedPage? pdfRenderPage(
    String pdfPath,
    int pageIndex,
    int targetWidth,
  ) {
    final lib = requireLib();
    final fn = lib.lookupFunction<_PdfRenderNative, _PdfRenderDart>(
      'waydir_pdf_render',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>('waydir_free');
    final libPtr = _pdfiumPath().toNativeUtf8();
    final pathPtr = pdfPath.toNativeUtf8();
    final outW = calloc<Int32>();
    final outH = calloc<Int32>();
    final outLen = calloc<IntPtr>();
    try {
      final buf = fn(
        libPtr,
        pathPtr,
        pageIndex,
        targetWidth,
        outW,
        outH,
        outLen,
      );
      if (buf == nullptr) return null;
      final len = outLen.value;
      final copy = Uint8List.fromList(buf.asTypedList(len));
      free(buf, len);
      return PdfRenderedPage(outW.value, outH.value, copy);
    } catch (e, st) {
      _warnNative('PDF page render', e, st);
      return null;
    } finally {
      calloc.free(libPtr);
      calloc.free(pathPtr);
      calloc.free(outW);
      calloc.free(outH);
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
      devTarget,
      p.join(exeDir, 'lib', lib),
      p.join(exeDir, lib),
      if (Platform.isMacOS)
        p.normalize(p.join(exeDir, '..', 'Frameworks', lib)),
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

    if (count == 0xFFFFFFFF) {
      final message = readString() ?? t.errors.nativeTrashListFailed;
      log.error('ffi.trash', message);
      throw WaydirCoreException(
        t.errors.nativeTrashListFailedWithMessage(message: message),
      );
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
