import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../../core/fs/waydir_core_loader.dart';
import '../../core/logging/app_logger.dart';

typedef _LoadNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _LoadDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef _InvokeNative =
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _InvokeDart =
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

typedef _BarUpdateNative =
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef _BarUpdateDart =
    Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

typedef _BarClickNative =
    Pointer<Utf8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
    );
typedef _BarClickDart =
    Pointer<Utf8> Function(
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
      Pointer<Utf8>,
    );

typedef _FreeNative = Void Function(Pointer<Utf8>);
typedef _FreeDart = void Function(Pointer<Utf8>);

class PluginFfi {
  PluginFfi._();

  /// Loads a plugin entry file and returns the raw JSON describing its
  /// registered contributions, or null if the native core is unavailable.
  ///
  /// Routed through the long-lived worker isolate so plugin loading never
  /// runs on the UI isolate, even at startup with many plugins.
  static Future<String?> load(String initLuaPath) {
    return _request(['load', initLuaPath]);
  }

  /// Runs a plugin action off the UI isolate. Returns the raw effects JSON.
  ///
  /// Actions run on a fresh ephemeral isolate (not the shared worker): a user
  /// action may legitimately call `waydir.exec` for up to a few seconds, and
  /// keeping it off the worker stops one slow action from stalling status-bar
  /// polling.
  static Future<String?> invoke({
    required String initLuaPath,
    required String actionId,
    required String ctxJson,
  }) {
    return Isolate.run(() => _invokeSync(initLuaPath, actionId, ctxJson));
  }

  static Future<String?> barUpdate({
    required String initLuaPath,
    required String barId,
    required String ctxJson,
  }) {
    return _request(['barUpdate', initLuaPath, barId, ctxJson]);
  }

  static Future<String?> barClick({
    required String initLuaPath,
    required String barId,
    required String itemId,
    required String ctxJson,
  }) {
    return _request(['barClick', initLuaPath, barId, itemId, ctxJson]);
  }

  // --- Long-lived worker isolate ---------------------------------------------
  //
  // load() and the bar update/click paths fire frequently (bars poll on an
  // interval, per pane). Spawning a fresh isolate and re-opening the native
  // library on every call is wasteful, so they share one persistent isolate
  // that opens the library once and dispatches commands over a port.

  static Isolate? _workerIsolate;
  static Future<SendPort>? _commandPort;

  static Future<SendPort> _ensureWorker() {
    return _commandPort ??= () async {
      final handshake = ReceivePort();
      _workerIsolate = await Isolate.spawn(_workerMain, handshake.sendPort);
      final port = await handshake.first as SendPort;
      handshake.close();

      return port;
    }();
  }

  static Future<String?> _request(List<Object?> command) async {
    final port = await _ensureWorker();
    final reply = ReceivePort();
    port.send([reply.sendPort, ...command]);
    final result = await reply.first;
    reply.close();

    return result as String?;
  }

  /// Tears down the worker isolate. Used by tests so the process can exit; the
  /// app keeps it alive for its whole lifetime.
  static void shutdown() {
    _workerIsolate?.kill(priority: Isolate.immediate);
    _workerIsolate = null;
    _commandPort = null;
  }

  static void _workerMain(SendPort handshake) {
    final commands = ReceivePort();
    handshake.send(commands.sendPort);
    commands.listen((message) {
      final m = message as List;
      final reply = m[0] as SendPort;
      final op = m[1] as String;
      String? result;
      switch (op) {
        case 'load':
          result = _loadSync(m[2] as String);
        case 'barUpdate':
          result = _barUpdateSync(
            m[2] as String,
            m[3] as String,
            m[4] as String,
          );
        case 'barClick':
          result = _barClickSync(
            m[2] as String,
            m[3] as String,
            m[4] as String,
            m[5] as String,
          );
      }
      reply.send(result);
    });
  }

  static String? _loadSync(String initLuaPath) {
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
    } catch (e, st) {
      log.error('plugins', 'plugin load failed', error: e, stack: st);

      return null;
    } finally {
      calloc.free(pathPtr);
    }
  }

  static String? _invokeSync(
    String initLuaPath,
    String actionId,
    String ctxJson,
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
      final res = fn(pathPtr, actionPtr, ctxPtr);
      if (res == nullptr) return null;
      final out = res.toDartString();
      free(res);

      return out;
    } catch (e, st) {
      log.error('plugins', 'plugin invoke failed', error: e, stack: st);

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
      final res = fn(pathPtr, barPtr, ctxPtr);
      if (res == nullptr) return null;
      final out = res.toDartString();
      free(res);

      return out;
    } catch (e, st) {
      log.error('plugins', 'plugin bar update failed', error: e, stack: st);

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
      final res = fn(pathPtr, barPtr, itemPtr, ctxPtr);
      if (res == nullptr) return null;
      final out = res.toDartString();
      free(res);

      return out;
    } catch (e, st) {
      log.error('plugins', 'plugin bar click failed', error: e, stack: st);

      return null;
    } finally {
      calloc.free(pathPtr);
      calloc.free(barPtr);
      calloc.free(itemPtr);
      calloc.free(ctxPtr);
    }
  }
}
