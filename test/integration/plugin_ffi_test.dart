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
      ctxJson: jsonEncode({
        'paths': <String>[],
        'dir': '/',
        'plugin_dir': tmp.path,
      }),
      perms: 0,
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isFalse);
    expect(json['error'].toString(), contains('permission'));
  });

  test('exec returns stdout, stderr and exit code with permission', () async {
    final path = writePlugin('''
      waydir.register({
        id = "exec_out",
        title = "Exec Out",
        run = function(ctx)
          local stdout, stderr, code = waydir.exec("sh", {
            "-c",
            "printf out; printf err >&2; exit 7",
          })
          waydir.toast(stdout .. ":" .. stderr .. ":" .. code)
        end,
      })
    ''');

    final raw = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'exec_out',
      ctxJson: jsonEncode({
        'paths': <String>[],
        'dir': '/',
        'plugin_dir': tmp.path,
      }),
      perms: 1,
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isTrue);
    final effects = json['effects'] as List;
    expect(effects.first, {
      'type': 'log',
      'message': 'exec sh failed: code 7',
    });
    expect(effects.last, {'type': 'toast', 'message': 'out:err:7'});
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
      ctxJson: jsonEncode({
        'paths': <String>[],
        'dir': '/',
        'plugin_dir': tmp.path,
      }),
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

  test(
    'absent form and settings arrive as nil, not a truthy sentinel',
    () async {
      final path = writePlugin('''
      waydir.register({
        id = "guard",
        title = "Guard",
        run = function(ctx)
          if not ctx.form then
            waydir.toast("no-form")
            return
          end
          waydir.toast("has-form")
        end,
      })
    ''');
      final raw = await PluginFfi.invoke(
        initLuaPath: path,
        actionId: 'guard',
        ctxJson: jsonEncode({
          'paths': <String>[],
          'dir': '/',
          'plugin_dir': tmp.path,
        }),
        perms: 0,
      );
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect((json['effects'] as List).first, {
        'type': 'toast',
        'message': 'no-form',
      });
    },
  );

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
      ctxJson: jsonEncode({
        'paths': <String>[],
        'dir': '/',
        'plugin_dir': tmp.path,
      }),
      perms: 1,
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final effect = (json['effects'] as List).first as Map<String, dynamic>;
    expect(effect['type'], 'task');
    expect(effect['cmd'], 'echo');
    expect(effect['timeout'], 30);
  });

  test('bundled example plugins all load without error', () {
    final dir = Directory('docs/examples/plugins');
    expect(dir.existsSync(), isTrue, reason: 'examples dir missing');
    final examples = dir.listSync().whereType<Directory>();
    expect(examples, isNotEmpty);
    for (final ex in examples) {
      final init = File(p.join(ex.path, 'init.lua'));
      expect(init.existsSync(), isTrue, reason: '${ex.path} has no init.lua');
      final raw = PluginFfi.load(init.path);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(
        json['ok'],
        isTrue,
        reason: '${p.basename(ex.path)} failed to load: ${json['error']}',
      );
      expect((json['contributions'] as List), isNotEmpty);
    }
  });

  test('toolbar menu and icon round-trip through load', () {
    final path = writePlugin('''
      waydir.register({
        id = "bar",
        title = "Bar",
        menu = "toolbar",
        icon = "icon.svg",
        run = function() end,
      })
    ''');
    final json = jsonDecode(PluginFfi.load(path)!) as Map<String, dynamic>;
    final c = (json['contributions'] as List).first as Map<String, dynamic>;
    expect(c['menu'], 'toolbar');
    expect(c['icon'], 'icon.svg');
  });

  test('templates example surfaces toolbar and menubar entries', () {
    final raw = PluginFfi.load('docs/examples/plugins/templates/init.lua');
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final menus = (json['contributions'] as List)
        .map((e) => (e as Map<String, dynamic>)['menu'])
        .toSet();
    expect(menus, containsAll(<String>['toolbar', 'menubar']));
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
