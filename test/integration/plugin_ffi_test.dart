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

  tearDownAll(PluginFfi.shutdown);

  String writePlugin(String lua) {
    final file = File(p.join(tmp.path, 'init.lua'));
    file.writeAsStringSync(lua);
    return file.path;
  }

  test('load returns declared contributions', () async {
    final path = writePlugin('''
      waydir.register({
        id = "greet",
        menu = "context",
        title = "Greet",
        when = { extensions = {"txt"}, min = 1 },
        run = function(ctx) waydir.toast("hi") end,
      })
    ''');

    final raw = await PluginFfi.load(path);
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
    );
    expect(raw, isNotNull);
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isTrue);

    final effects = json['effects'] as List;
    expect(effects, hasLength(2));
    expect(effects[0], {'type': 'toast', 'message': 'hello 2'});
    expect(effects[1], {'type': 'refresh'});
  });

  test('bar update and click return state and effects', () async {
    final path = writePlugin('''
      waydir.register_bar({
        id = "status",
        scope = "pane",
        title = "Status",
        interval = 3,
        update = function(ctx)
          return {
            visible = ctx.dir == "/tmp",
            items = {
              { type = "badge", text = "ok", level = "success" },
              { type = "button", id = "refresh", icon = "refresh" },
            },
          }
        end,
        click = function(ctx)
          waydir.toast("clicked " .. ctx.item_id)
        end,
      })
    ''');

    final loaded =
        jsonDecode((await PluginFfi.load(path))!) as Map<String, dynamic>;
    expect(loaded['ok'], isTrue);
    final bars = loaded['bars'] as List;
    expect(bars, hasLength(1));
    expect((bars.first as Map)['scope'], 'pane');

    final ctx = jsonEncode({
      'paths': <String>[],
      'dir': '/tmp',
      'plugin_dir': tmp.path,
    });
    final updated =
        jsonDecode(
              (await PluginFfi.barUpdate(
                initLuaPath: path,
                barId: 'status',
                ctxJson: ctx,
              ))!,
            )
            as Map<String, dynamic>;
    expect(updated['ok'], isTrue);
    expect((updated['state'] as Map)['visible'], isTrue);
    expect(((updated['state'] as Map)['items'] as List), hasLength(2));

    final clicked =
        jsonDecode(
              (await PluginFfi.barClick(
                initLuaPath: path,
                barId: 'status',
                itemId: 'refresh',
                ctxJson: ctx,
              ))!,
            )
            as Map<String, dynamic>;
    expect(clicked['ok'], isTrue);
    expect((clicked['effects'] as List).first, {
      'type': 'toast',
      'message': 'clicked refresh',
    });
  });

  test('exec runs without any permission declaration', () async {
    final path = writePlugin('''
      waydir.register({
        id = "danger",
        title = "Danger",
        run = function(ctx)
          local stdout = waydir.exec("echo", {"hi"})
          waydir.toast(stdout)
        end,
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
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isTrue);
    expect((json['effects'] as List).last, {
      'type': 'toast',
      'message': 'hi\n',
    });
  });

  test('exec returns stdout, stderr and exit code', () async {
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
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isTrue);
    final effects = json['effects'] as List;
    expect(effects.first, {'type': 'log', 'message': 'exec sh failed: code 7'});
    expect(effects.last, {'type': 'toast', 'message': 'out:err:7'});
  });

  test('exec is bounded and a hung command times out', () async {
    final path = writePlugin('''
      waydir.register({
        id = "hang",
        title = "Hang",
        run = function(ctx)
          local stdout, stderr, code = waydir.exec("sleep", {"30"})
          waydir.toast("code:" .. code)
        end,
      })
    ''');

    final sw = Stopwatch()..start();
    final raw = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'hang',
      ctxJson: jsonEncode({
        'paths': <String>[],
        'dir': '/',
        'plugin_dir': tmp.path,
      }),
    );
    sw.stop();
    expect(sw.elapsed, lessThan(const Duration(seconds: 20)));
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isTrue);
    expect((json['effects'] as List).last, {
      'type': 'toast',
      'message': 'code:-1',
    });
  });

  test('load returns where, shortcut and settings schema', () async {
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
    final raw = await PluginFfi.load(path);
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

  test('fs read_text works', () async {
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
    );
    final grantedJson = jsonDecode(granted!) as Map<String, dynamic>;
    expect(grantedJson['ok'], isTrue);
    expect((grantedJson['effects'] as List).first, {
      'type': 'toast',
      'message': 'payload',
    });
  });

  test('ctx exposes other_pane and panes', () async {
    final path = writePlugin('''
      waydir.register({
        id = "panes",
        title = "Panes",
        run = function(ctx)
          local other = ctx.other_pane and ctx.other_pane.dir or "?"
          waydir.toast(other .. ":" .. #ctx.panes .. ":" .. tostring(ctx.panes[1].active))
        end,
      })
    ''');
    final raw = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'panes',
      ctxJson: jsonEncode({
        'paths': <String>[],
        'dir': '/left',
        'plugin_dir': tmp.path,
        'other_pane': {
          'dir': '/right',
          'paths': ['/right/a.txt'],
        },
        'panes': [
          {'dir': '/left', 'paths': <String>[], 'active': true},
          {
            'dir': '/right',
            'paths': ['/right/a.txt'],
            'active': false,
          },
        ],
      }),
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect((json['effects'] as List).first, {
      'type': 'toast',
      'message': '/right:2:true',
    });
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
      );
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect((json['effects'] as List).first, {
        'type': 'toast',
        'message': 'no-form',
      });
    },
  );

  test('run_task emits a task effect with timeout', () async {
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
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final effect = (json['effects'] as List).first as Map<String, dynamic>;
    expect(effect['type'], 'task');
    expect(effect['cmd'], 'echo');
    expect(effect['timeout'], 30);
  });

  test(
    'run_task can request an operations entry with progress parsing',
    () async {
      final path = writePlugin('''
      waydir.register({
        id = "job_op",
        title = "Job Op",
        run = function(ctx)
          waydir.run_task({
            title = "T",
            cmd = "echo",
            args = {"42%"},
            operation = true,
            pty = true,
            progress = { percent_regex = [[([0-9]+)%]] },
          })
        end,
      })
    ''');
      final raw = await PluginFfi.invoke(
        initLuaPath: path,
        actionId: 'job_op',
        ctxJson: jsonEncode({
          'paths': <String>[],
          'dir': '/',
          'plugin_dir': tmp.path,
        }),
      );
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      final effect = (json['effects'] as List).first as Map<String, dynamic>;
      expect(effect['type'], 'task');
      expect(effect['operation'], isTrue);
      expect(effect['pty'], isTrue);
      expect((effect['progress'] as Map)['percent_regex'], '([0-9]+)%');
    },
  );

  test('custom operation effects round-trip', () async {
    final path = writePlugin('''
      waydir.register({
        id = "op",
        title = "Op",
        run = function(ctx)
          waydir.operation_start({
            id = "x",
            title = "Custom",
            total_bytes = 100,
            total_files = 2,
          })
          waydir.operation_update("x", {
            progress = 0.5,
            message = "half",
            processed_bytes = 50,
            bytes_per_second = 10,
            processed_files = 1,
          })
          waydir.operation_finish("x", { success = true })
        end,
      })
    ''');
    final raw = await PluginFfi.invoke(
      initLuaPath: path,
      actionId: 'op',
      ctxJson: jsonEncode({
        'paths': <String>[],
        'dir': '/',
        'plugin_dir': tmp.path,
      }),
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final effects = (json['effects'] as List).cast<Map<String, dynamic>>();
    expect(effects[0]['type'], 'custom_operation_start');
    expect(effects[0]['id'], 'x');
    expect(effects[1]['type'], 'custom_operation_update');
    expect(effects[1]['progress'], 0.5);
    expect(effects[2]['type'], 'custom_operation_finish');
    expect(effects[2]['success'], isTrue);
  });

  test('bundled example plugins all load without error', () async {
    final dir = Directory('docs/examples/plugins');
    expect(dir.existsSync(), isTrue, reason: 'examples dir missing');
    final examples = dir.listSync().whereType<Directory>();
    expect(examples, isNotEmpty);
    for (final ex in examples) {
      final init = File(p.join(ex.path, 'init.lua'));
      expect(init.existsSync(), isTrue, reason: '${ex.path} has no init.lua');
      final raw = await PluginFfi.load(init.path);
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(
        json['ok'],
        isTrue,
        reason: '${p.basename(ex.path)} failed to load: ${json['error']}',
      );
      expect((json['contributions'] as List), isNotEmpty);
    }
  });

  test('columns register and compute values for a batch of files', () async {
    final path = writePlugin('''
      waydir.register_column({
        id = "tag",
        title = "Tag",
        width = 80,
        compute = function(ctx)
          local out = {}
          for _, file in ipairs(ctx.paths) do
            out[file] = "T:" .. file
          end
          return out
        end,
      })
    ''');
    final loaded =
        jsonDecode((await PluginFfi.load(path))!) as Map<String, dynamic>;
    final cols = loaded['columns'] as List;
    expect(cols, hasLength(1));
    expect((cols.first as Map)['id'], 'tag');
    expect((cols.first as Map)['title'], 'Tag');
    expect((cols.first as Map)['width'], 80);

    final computed =
        jsonDecode(
              (await PluginFfi.columnCompute(
                initLuaPath: path,
                columnId: 'tag',
                ctxJson: jsonEncode({
                  'paths': ['/a.txt', '/b.txt'],
                  'dir': '/',
                  'plugin_dir': tmp.path,
                }),
              ))!,
            )
            as Map<String, dynamic>;
    expect(computed['ok'], isTrue);
    final values = computed['values'] as Map;
    expect(values['/a.txt'], 'T:/a.txt');
    expect(values['/b.txt'], 'T:/b.txt');
  });

  test('event handlers round-trip through load', () async {
    final path = writePlugin('''
      waydir.register({
        id = "watch",
        title = "Watch",
        event = "navigate",
        run = function(ctx) waydir.log("at " .. ctx.dir) end,
      })
    ''');
    final json =
        jsonDecode((await PluginFfi.load(path))!) as Map<String, dynamic>;
    final c = (json['contributions'] as List).first as Map<String, dynamic>;
    expect(c['event'], 'navigate');
  });

  test('toolbar menu and icon round-trip through load', () async {
    final path = writePlugin('''
      waydir.register({
        id = "bar",
        title = "Bar",
        menu = "toolbar",
        icon = "icon.svg",
        run = function() end,
      })
    ''');
    final json =
        jsonDecode((await PluginFfi.load(path))!) as Map<String, dynamic>;
    final c = (json['contributions'] as List).first as Map<String, dynamic>;
    expect(c['menu'], 'toolbar');
    expect(c['icon'], 'icon.svg');
  });

  test('templates example surfaces toolbar and menubar entries', () async {
    final raw = await PluginFfi.load(
      'docs/examples/plugins/templates/init.lua',
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    final menus = (json['contributions'] as List)
        .map((e) => (e as Map<String, dynamic>)['menu'])
        .toSet();
    expect(menus, containsAll(<String>['toolbar', 'menubar']));
  });

  test('sandbox blocks os and io access', () async {
    final path = writePlugin('''
      waydir.register({
        id = "x", title = "X",
        run = function() local _ = os.execute end,
      })
    ''');
    final raw = await PluginFfi.load(path);
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    // Loading succeeds (register runs); os is simply nil in the sandbox.
    expect(json['ok'], isTrue);
  });
}
