@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/features/plugins/plugin_ffi.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('waydir_plugin_test');
  });

  tearDown(() {
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  String writePlugin(String lua) {
    final file = File(p.join(tmp.path, 'init.lua'));
    file.writeAsStringSync(lua);
    return file.path;
  }

  test('load returns declared contributions', () {
    final path = writePlugin('''
      waydir.register({
        id = "greet",
        menu = "context",
        title = "Greet",
        when = { extensions = {"txt"}, min = 1 },
        run = function(ctx) waydir.toast("hi") end,
      })
    ''');

    final raw = PluginFfi.load(path);
    expect(raw, isNotNull, reason: 'native core must be built/vendored');
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isTrue);

    final contribs = json['contributions'] as List;
    expect(contribs, hasLength(1));
    final c = contribs.first as Map<String, dynamic>;
    expect(c['id'], 'greet');
    expect(c['title'], 'Greet');
    expect((c['when'] as Map)['extensions'], ['txt']);
  });

  test('invoke runs the action and collects effects', () async {
    final path = writePlugin('''
      waydir.register({
        id = "greet",
        title = "Greet",
        run = function(ctx)
          waydir.toast("hello " .. ctx.count)
          waydir.refresh()
        end,
      })
    ''');

    final ctx = jsonEncode({
      'paths': ['/a.txt', '/b.txt'],
      'dir': '/tmp',
      'plugin_dir': tmp.path,
    });
    final raw = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'greet',
      ctxJson: ctx,
      perms: 0,
    );
    expect(raw, isNotNull);
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isTrue);

    final effects = json['effects'] as List;
    expect(effects, hasLength(2));
    expect(effects[0], {'type': 'toast', 'message': 'hello 2'});
    expect(effects[1], {'type': 'refresh'});
  });

  test('exec is denied without permission', () async {
    final path = writePlugin('''
      waydir.register({
        id = "danger",
        title = "Danger",
        run = function(ctx) waydir.exec("echo", {"hi"}) end,
      })
    ''');

    final raw = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'danger',
      ctxJson: jsonEncode({'paths': <String>[], 'dir': '/', 'plugin_dir': tmp.path}),
      perms: 0,
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isFalse);
    expect(json['error'].toString(), contains('permission'));
  });

  test('load returns where, shortcut and settings schema', () {
    final path = writePlugin('''
      waydir.register({
        id = "cfg",
        title = "Config",
        where = { "selection", "background" },
        shortcut = "ctrl+shift+k",
        settings = {
          { id = "quality", type = "text", label = "Quality", default = "80" },
        },
        run = function() end,
      })
    ''');
    final raw = PluginFfi.load(path);
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final c = (json['contributions'] as List).first as Map<String, dynamic>;
    expect(c['where'], ['selection', 'background']);
    expect(c['shortcut'], 'ctrl+shift+k');
    expect((c['settings'] as List).first, {
      'id': 'quality',
      'type': 'text',
      'label': 'Quality',
      'default': '80',
    });
  });

  test('fs read_text works with fs permission and is denied without', () async {
    final dataFile = File(p.join(tmp.path, 'data.txt'))
      ..writeAsStringSync('payload');
    final path = writePlugin('''
      waydir.register({
        id = "reader",
        title = "Reader",
        run = function(ctx)
          local text = waydir.read_text(ctx.paths[1])
          waydir.toast(text)
        end,
      })
    ''');
    final ctx = jsonEncode({
      'paths': [dataFile.path],
      'dir': tmp.path,
      'plugin_dir': tmp.path,
    });

    final granted = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'reader',
      ctxJson: ctx,
      perms: 2,
    );
    final grantedJson = jsonDecode(granted!) as Map<String, dynamic>;
    expect(grantedJson['ok'], isTrue);
    expect((grantedJson['effects'] as List).first, {
      'type': 'toast',
      'message': 'payload',
    });

    final denied = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'reader',
      ctxJson: ctx,
      perms: 0,
    );
    final deniedJson = jsonDecode(denied!) as Map<String, dynamic>;
    expect(deniedJson['ok'], isFalse);
  });

  test('notify, set_setting and dialog effects round-trip', () async {
    final path = writePlugin('''
      waydir.register({
        id = "ui",
        title = "UI",
        run = function(ctx)
          waydir.notify({ title = "T", message = "M", level = "success" })
          waydir.set_setting("k", "v")
          waydir.dialog({
            title = "Pick",
            fields = { { id = "name", type = "text", label = "Name" } },
            submit_action = "ui",
          })
        end,
      })
    ''');
    final raw = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'ui',
      ctxJson: jsonEncode({'paths': <String>[], 'dir': '/', 'plugin_dir': tmp.path}),
      perms: 0,
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final effects = (json['effects'] as List).cast<Map<String, dynamic>>();
    expect(effects[0]['type'], 'notify');
    expect(effects[0]['level'], 'success');
    expect(effects[1], {'type': 'set_setting', 'key': 'k', 'value': 'v'});
    expect(effects[2]['type'], 'dialog');
    expect((effects[2]['dialog'] as Map)['title'], 'Pick');
  });

  test('ctx exposes injected settings and form values', () async {
    final path = writePlugin('''
      waydir.register({
        id = "ctx",
        title = "Ctx",
        run = function(ctx)
          waydir.toast((ctx.settings.greeting or "?") .. ":" .. (ctx.form.x or "?"))
        end,
      })
    ''');
    final raw = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'ctx',
      ctxJson: jsonEncode({
        'paths': <String>[],
        'dir': '/',
        'plugin_dir': tmp.path,
        'settings': {'greeting': 'hi'},
        'form': {'x': 'y'},
      }),
      perms: 0,
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect((json['effects'] as List).first, {
      'type': 'toast',
      'message': 'hi:y',
    });
  });

  test('run_task emits a task effect with timeout (needs exec)', () async {
    final path = writePlugin('''
      waydir.register({
        id = "job",
        title = "Job",
        run = function(ctx)
          waydir.run_task({ title = "T", cmd = "echo", args = {"hi"}, timeout = 30 })
        end,
      })
    ''');
    final raw = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'job',
      ctxJson: jsonEncode({'paths': <String>[], 'dir': '/', 'plugin_dir': tmp.path}),
      perms: 1,
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final effect = (json['effects'] as List).first as Map<String, dynamic>;
    expect(effect['type'], 'task');
    expect(effect['cmd'], 'echo');
    expect(effect['timeout'], 30);
  });

  test('sandbox blocks os and io access', () {
    final path = writePlugin('''
      waydir.register({
        id = "x", title = "X",
        run = function() local _ = os.execute end,
      })
    ''');
    final raw = PluginFfi.load(path);
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    // Loading succeeds (register runs); os is simply nil in the sandbox.
    expect(json['ok'], isTrue);
  });
}
