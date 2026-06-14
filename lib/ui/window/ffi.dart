import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

final DynamicLibrary _lib = DynamicLibrary.process();

typedef SetMinSizeC = Void Function(Int32 w, Int32 h);
typedef SetMinSizeD = void Function(int w, int h);
final SetMinSizeD setMinSize = _lib.lookupFunction<SetMinSizeC, SetMinSizeD>(
  'waydir_window_set_min_size',
);

typedef VoidC = Void Function();
typedef VoidD = void Function();

final VoidD show = _lib.lookupFunction<VoidC, VoidD>('waydir_window_show');
final VoidD hide = _lib.lookupFunction<VoidC, VoidD>('waydir_window_hide');
final VoidD minimize = _lib.lookupFunction<VoidC, VoidD>(
  'waydir_window_minimize',
);
final VoidD maximize = _lib.lookupFunction<VoidC, VoidD>(
  'waydir_window_maximize',
);
final VoidD restore = _lib.lookupFunction<VoidC, VoidD>(
  'waydir_window_restore',
);
final VoidD close = _lib.lookupFunction<VoidC, VoidD>('waydir_window_close');
final VoidD startDragging = _lib.lookupFunction<VoidC, VoidD>(
  'waydir_window_start_dragging',
);
final VoidD centerWindow = _lib.lookupFunction<VoidC, VoidD>(
  'waydir_window_center',
);

typedef IntQueryC = Int32 Function();
typedef IntQueryD = int Function();
final IntQueryD _isMaximized = _lib.lookupFunction<IntQueryC, IntQueryD>(
  'waydir_window_is_maximized',
);
final IntQueryD _isVisible = _lib.lookupFunction<IntQueryC, IntQueryD>(
  'waydir_window_is_visible',
);

bool isMaximized() => _isMaximized() != 0;
bool isVisible() => _isVisible() != 0;

typedef SetSizeC = Void Function(Int32 w, Int32 h);
typedef SetSizeD = void Function(int w, int h);
final SetSizeD setSize = _lib.lookupFunction<SetSizeC, SetSizeD>(
  'waydir_window_set_size',
);

typedef GetSizeC = Void Function(Pointer<Int32> w, Pointer<Int32> h);
typedef GetSizeD = void Function(Pointer<Int32> w, Pointer<Int32> h);
final GetSizeD _getSize = _lib.lookupFunction<GetSizeC, GetSizeD>(
  'waydir_window_get_size',
);

({int width, int height}) getSize() {
  final wp = calloc<Int32>();
  final hp = calloc<Int32>();
  try {
    _getSize(wp, hp);

    return (width: wp.value, height: hp.value);
  } finally {
    calloc.free(wp);
    calloc.free(hp);
  }
}

void setTitle(String title) {
  if (Platform.isWindows) {
    final ptr = title.toNativeUtf16();
    try {
      final fn = _lib
          .lookupFunction<
            Void Function(Pointer<Utf16>),
            void Function(Pointer<Utf16>)
          >('waydir_window_set_title');
      fn(ptr);
    } finally {
      calloc.free(ptr);
    }
  } else {
    final ptr = title.toNativeUtf8();
    try {
      final fn = _lib
          .lookupFunction<
            Void Function(Pointer<Utf8>),
            void Function(Pointer<Utf8>)
          >('waydir_window_set_title');
      fn(ptr);
    } finally {
      calloc.free(ptr);
    }
  }
}
