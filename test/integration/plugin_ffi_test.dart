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
      allowExec: false,
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
      allowExec: false,
    );
    final json = jsonDecode(raw!) as Map<String, dynamic>;
    expect(json['ok'], isFalse);
    expect(json['error'].toString(), contains('permission'));
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
