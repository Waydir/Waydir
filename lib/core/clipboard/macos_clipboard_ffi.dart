import 'dart:ffi';

import 'package:ffi/ffi.dart';

final DynamicLibrary _lib = DynamicLibrary.process();

typedef _WriteC = Void Function(Pointer<Utf8> joined, Int32 isCut);
typedef _WriteD = void Function(Pointer<Utf8> joined, int isCut);
final _WriteD _writeFiles = _lib.lookupFunction<_WriteC, _WriteD>(
  'waydir_clipboard_write_files',
);

typedef _ReadC = Pointer<Utf8> Function();
typedef _ReadD = Pointer<Utf8> Function();
final _ReadD _readFiles = _lib.lookupFunction<_ReadC, _ReadD>(
  'waydir_clipboard_read_files',
);

typedef _IsCutC = Int32 Function();
typedef _IsCutD = int Function();
final _IsCutD _isCut = _lib.lookupFunction<_IsCutC, _IsCutD>(
  'waydir_clipboard_is_cut',
);

typedef _FreeC = Void Function(Pointer<Utf8> ptr);
typedef _FreeD = void Function(Pointer<Utf8> ptr);
final _FreeD _free = _lib.lookupFunction<_FreeC, _FreeD>(
  'waydir_clipboard_free',
);

void macWriteFiles(List<String> paths, {required bool isCut}) {
  final ptr = paths.join('\n').toNativeUtf8();
  try {
    _writeFiles(ptr, isCut ? 1 : 0);
  } finally {
    calloc.free(ptr);
  }
}

List<String> macReadFiles() {
  final ptr = _readFiles();
  try {
    final raw = ptr.toDartString();
    return raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  } finally {
    _free(ptr);
  }
}

bool macIsCut() => _isCut() != 0;
