import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../../core/fs/waydir_core_loader.dart';

typedef _LoadNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _LoadDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef _InvokeNative =
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _InvokeDart =
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int);

typedef _BarUpdateNative =
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _BarUpdateDart =
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int);

typedef _BarClickNative =
    Pointer<Utf8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Int32,
    );
typedef _BarClickDart =
    Pointer<Utf8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      int,
    );

typedef _FreeNative = Void Function(Pointer<Utf8>);
typedef _FreeDart = void Function(Pointer<Utf8>);

class PluginFfi {
  PluginFfi._();

  /// Loads a plugin entry file and returns the raw JSON describing its
  /// registered contributions, or null if the native core is unavailable.
  static String? load(String initLuaPath) {
    final lib = WaydirCoreLoader.load();
    if (lib == null) return null;
    final fn = lib.lookupFunction<_LoadNative, _LoadDart>('waydir_plugin_load');
    final free = lib.lookupFunction<_FreeNative, _FreeDart>(
      'waydir_plugin_str_free',
    );
    final pathPtr = initLuaPath.toNativeUtf8();
    try {
      final res = fn(pathPtr);
      if (res == nullptr) return null;
      final out = res.toDartString();
      free(res);
      return out;
    } catch (_) {
      return null;
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// Runs a plugin action off the UI isolate. Returns the raw effects JSON.
  /// `perms` is a bitmask matching `PluginManifest.permsBitmask`.
  static Future<String?> invoke({
    required String initLuaPath,
    required String actionId,
    required String ctxJson,
    required int perms,
  }) {
    return Isolate.run(
      () => _invokeSync(initLuaPath, actionId, ctxJson, perms),
    );
  }

  static Future<String?> barUpdate({
    required String initLuaPath,
    required String barId,
    required String ctxJson,
    required int perms,
  }) {
    return Isolate.run(
      () => _barUpdateSync(initLuaPath, barId, ctxJson, perms),
    );
  }

  static Future<String?> barClick({
    required String initLuaPath,
    required String barId,
    required String itemId,
    required String ctxJson,
    required int perms,
  }) {
    return Isolate.run(
      () => _barClickSync(initLuaPath, barId, itemId, ctxJson, perms),
    );
  }

  static String? _invokeSync(
    String initLuaPath,
    String actionId,
    String ctxJson,
    int perms,
  ) {
    final lib = WaydirCoreLoader.load();
    if (lib == null) return null;
    final fn = lib.lookupFunction<_InvokeNative, _InvokeDart>(
      'waydir_plugin_invoke',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>(
      'waydir_plugin_str_free',
    );
    final pathPtr = initLuaPath.toNativeUtf8();
    final actionPtr = actionId.toNativeUtf8();
    final ctxPtr = ctxJson.toNativeUtf8();
    try {
      final res = fn(pathPtr, actionPtr, ctxPtr, perms);
      if (res == nullptr) return null;
      final out = res.toDartString();
      free(res);
      return out;
    } catch (_) {
      return null;
    } finally {
      calloc.free(pathPtr);
      calloc.free(actionPtr);
      calloc.free(ctxPtr);
    }
  }

  static String? _barUpdateSync(
    String initLuaPath,
    String barId,
    String ctxJson,
    int perms,
  ) {
    final lib = WaydirCoreLoader.load();
    if (lib == null) return null;
    final fn = lib.lookupFunction<_BarUpdateNative, _BarUpdateDart>(
      'waydir_plugin_bar_update',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>(
      'waydir_plugin_str_free',
    );
    final pathPtr = initLuaPath.toNativeUtf8();
    final barPtr = barId.toNativeUtf8();
    final ctxPtr = ctxJson.toNativeUtf8();
    try {
      final res = fn(pathPtr, barPtr, ctxPtr, perms);
      if (res == nullptr) return null;
      final out = res.toDartString();
      free(res);
      return out;
    } catch (_) {
      return null;
    } finally {
      calloc.free(pathPtr);
      calloc.free(barPtr);
      calloc.free(ctxPtr);
    }
  }

  static String? _barClickSync(
    String initLuaPath,
    String barId,
    String itemId,
    String ctxJson,
    int perms,
  ) {
    final lib = WaydirCoreLoader.load();
    if (lib == null) return null;
    final fn = lib.lookupFunction<_BarClickNative, _BarClickDart>(
      'waydir_plugin_bar_click',
    );
    final free = lib.lookupFunction<_FreeNative, _FreeDart>(
      'waydir_plugin_str_free',
    );
    final pathPtr = initLuaPath.toNativeUtf8();
    final barPtr = barId.toNativeUtf8();
    final itemPtr = itemId.toNativeUtf8();
    final ctxPtr = ctxJson.toNativeUtf8();
    try {
      final res = fn(pathPtr, barPtr, itemPtr, ctxPtr, perms);
      if (res == nullptr) return null;
      final out = res.toDartString();
      free(res);
      return out;
    } catch (_) {
      return null;
    } finally {
      calloc.free(pathPtr);
      calloc.free(barPtr);
      calloc.free(itemPtr);
      calloc.free(ctxPtr);
    }
  }
}
