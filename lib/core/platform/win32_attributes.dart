import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

const _fileAttributeHidden = 0x2;
const _fileAttributeSystem = 0x4;
const _invalidFileAttributes = 0xFFFFFFFF;

DynamicLibrary? _kernel32;
int Function(Pointer<Utf16>)? _getFileAttributesW;

DynamicLibrary? _shell32;
int Function(
  int,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  int,
)?
_shellExecuteW;

void _ensureKernel32() {
  if (_kernel32 != null) return;
  _kernel32 = DynamicLibrary.open('kernel32.dll');
  _getFileAttributesW = _kernel32!
      .lookupFunction<
        Uint32 Function(Pointer<Utf16>),
        int Function(Pointer<Utf16>)
      >('GetFileAttributesW');
}

void _ensureShell32() {
  if (_shell32 != null) return;
  _shell32 = DynamicLibrary.open('shell32.dll');
  _shellExecuteW = _shell32!
      .lookupFunction<
        IntPtr Function(
          IntPtr,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Int32,
        ),
        int Function(
          int,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          int,
        )
      >('ShellExecuteW');
}

bool isHiddenOnWindows(String path) {
  if (!Platform.isWindows) return false;
  _ensureKernel32();
  final pathPtr = path.toNativeUtf16();
  try {
    final attrs = _getFileAttributesW!(pathPtr);
    if (attrs == _invalidFileAttributes) return false;

    return (attrs & _fileAttributeHidden) != 0 ||
        (attrs & _fileAttributeSystem) != 0;
  } finally {
    calloc.free(pathPtr);
  }
}

void shellOpenOnWindows(String path) {
  if (!Platform.isWindows) return;
  _ensureShell32();
  final verb = 'open'.toNativeUtf16();
  final file = path.toNativeUtf16();
  try {
    _shellExecuteW!(0, verb, file, nullptr, nullptr, 1);
  } finally {
    calloc.free(verb);
    calloc.free(file);
  }
}

/// Launches [appExe] with [filePath] as its argument via the shell. Works for
/// classic Win32 apps; the shell resolves PATH and app paths for us.
bool shellOpenWithAppOnWindows(String appExe, String filePath) {
  if (!Platform.isWindows) return false;
  _ensureShell32();
  final verb = 'open'.toNativeUtf16();
  final exe = appExe.toNativeUtf16();
  final params = '"$filePath"'.toNativeUtf16();
  try {
    final ret = _shellExecuteW!(0, verb, exe, params, nullptr, 1);

    return ret > 32;
  } finally {
    calloc.free(verb);
    calloc.free(exe);
    calloc.free(params);
  }
}

DynamicLibrary? _shlwapi;
int Function(
  int,
  int,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Utf16>,
  Pointer<Uint32>,
)?
_assocQueryStringW;

void _ensureShlwapi() {
  if (_shlwapi != null) return;
  _shlwapi = DynamicLibrary.open('shlwapi.dll');
  _assocQueryStringW = _shlwapi!
      .lookupFunction<
        Int32 Function(
          Uint32,
          Int32,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Uint32>,
        ),
        int Function(
          int,
          int,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Utf16>,
          Pointer<Uint32>,
        )
      >('AssocQueryStringW');
}

/// ASSOCSTR values from shlwapi.h
const assocStrCommand = 1;
const assocStrExecutable = 2;
const assocStrFriendlyAppName = 4;

/// Wraps `AssocQueryStringW`. [assoc] is typically a file extension
/// (e.g. `.png`) or a ProgId. Returns null when no association exists.
String? assocQueryStringOnWindows(int str, String assoc) {
  if (!Platform.isWindows) return null;
  _ensureShlwapi();
  final assocPtr = assoc.toNativeUtf16();
  final sizePtr = calloc<Uint32>();
  try {
    final probe = _assocQueryStringW!(
      0,
      str,
      assocPtr,
      nullptr,
      nullptr,
      sizePtr,
    );
    final needed = sizePtr.value;
    if (probe != 0 && needed == 0) return null;
    final outPtr = calloc<Uint16>(needed + 1).cast<Utf16>();
    try {
      final hr = _assocQueryStringW!(
        0,
        str,
        assocPtr,
        nullptr,
        outPtr,
        sizePtr,
      );
      if (hr != 0) return null;
      final value = outPtr.toDartString();

      return value.isEmpty ? null : value;
    } finally {
      calloc.free(outPtr);
    }
  } finally {
    calloc.free(assocPtr);
    calloc.free(sizePtr);
  }
}
