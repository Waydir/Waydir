import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/features/plugins/plugin_models.dart';

FileEntry _file(String name) => FileEntry(
  name: name,
  path: '/tmp/$name',
  type: FileItemType.file,
  size: 0,
  modified: DateTime(2026),
);

FileEntry _folder(String name) => FileEntry(
  name: name,
  path: '/tmp/$name',
  type: FileItemType.folder,
  size: 0,
  modified: DateTime(2026),
);

bool _never(FileEntry _) => false;

void main() {
  group('PluginWhen.matches', () {
    test('empty selection never matches', () {
      expect(const PluginWhen().matches([], _never), isFalse);
    });

    test('extension filter matches only listed types', () {
      const when = PluginWhen(extensions: {'png', 'jpg'});
      expect(when.matches([_file('a.png'), _file('b.jpg')], _never), isTrue);
      expect(when.matches([_file('a.png'), _file('c.gif')], _never), isFalse);
    });

    test('extension filter rejects folders', () {
      const when = PluginWhen(extensions: {'png'});
      expect(when.matches([_folder('photos')], _never), isFalse);
    });

    test('types filter restricts to folders', () {
      const when = PluginWhen(types: {'folder'});
      expect(when.matches([_folder('x')], _never), isTrue);
      expect(when.matches([_file('x.txt')], _never), isFalse);
    });

    test('min and max bound the selection count', () {
      const when = PluginWhen(min: 2, max: 3);
      expect(when.matches([_file('a')], _never), isFalse);
      expect(when.matches([_file('a'), _file('b')], _never), isTrue);
      expect(
        when.matches([_file('a'), _file('b'), _file('c'), _file('d')], _never),
        isFalse,
      );
    });

    test('in_archive=false rejects entries reported as inside an archive', () {
      const when = PluginWhen(inArchive: false);
      expect(when.matches([_file('a.txt')], _never), isTrue);
      expect(when.matches([_file('a.txt')], (_) => true), isFalse);
    });

    test('fromJson parses the declarative filter', () {
      final when = PluginWhen.fromJson({
        'types': ['file'],
        'extensions': ['PNG', 'Jpg'],
        'min': 1,
        'max': 5,
        'in_archive': false,
      });
      expect(when.types, {'file'});
      expect(when.extensions, {'png', 'jpg'});
      expect(when.min, 1);
      expect(when.max, 5);
      expect(when.inArchive, isFalse);
    });
  });

  group('PluginContribution', () {
    const manifest = PluginManifest(
      id: 'webp',
      name: 'WebP',
      version: '1.0.0',
      author: '',
      description: '',
      apiVersion: 2,
      permissions: {'exec'},
    );

    test('fullActionId namespaces plugin and action', () {
      const c = PluginContribution(
        pluginId: 'webp',
        actionId: 'to_webp',
        menu: 'context',
        title: 'Convert',
        group: null,
        icon: null,
        when: PluginWhen(),
        surfaces: {'selection'},
        shortcut: null,
        settings: [],
        initLuaPath: '/x/init.lua',
        pluginDir: '/x',
        manifest: manifest,
      );
      expect(c.fullActionId, 'plugin:webp:to_webp');
      expect(c.allowExec, isTrue);
      expect(c.showsOn('selection'), isTrue);
      expect(c.showsOn('background'), isFalse);
    });
  });

  group('PluginManifest.permsBitmask', () {
    test('maps exec and fs to bits', () {
      PluginManifest m(Set<String> perms) => PluginManifest(
        id: 'p',
        name: 'p',
        version: '1',
        author: '',
        description: '',
        apiVersion: 2,
        permissions: perms,
      );
      expect(m({}).permsBitmask, 0);
      expect(m({'exec'}).permsBitmask, 1);
      expect(m({'fs'}).permsBitmask, 2);
      expect(m({'exec', 'fs'}).permsBitmask, 3);
    });
  });

  group('PluginFormField.listFromJson', () {
    test('parses fields and drops entries without an id', () {
      final fields = PluginFormField.listFromJson([
        {'id': 'name', 'type': 'text', 'label': 'Name', 'default': 'x'},
        {
          'id': 'mode',
          'type': 'select',
          'options': [
            {'value': 'a', 'label': 'A'},
            'b',
          ],
        },
        {'type': 'text'},
      ]);
      expect(fields.length, 2);
      expect(fields.first.id, 'name');
      expect(fields.first.defaultValue, 'x');
      expect(fields[1].options.map((o) => o.value), ['a', 'b']);
    });
  });

  group('Plugin bars', () {
    const manifest = PluginManifest(
      id: 'bars',
      name: 'Bars',
      version: '1.0.0',
      author: '',
      description: '',
      apiVersion: 2,
      permissions: {'exec'},
    );

    test('parses bar state items', () {
      final state = PluginBarState.fromJson({
        'visible': true,
        'items': [
          {'type': 'badge', 'text': '5h 12%', 'level': 'success'},
          {'type': 'button', 'id': 'refresh', 'icon': 'refresh'},
        ],
      });
      expect(state.visible, isTrue);
      expect(state.items.length, 2);
      expect(state.items.first.type, 'badge');
      expect(state.items.first.level, 'success');
      expect(state.items[1].id, 'refresh');
    });

    test('includes bar settings in plugin settings schema', () {
      const plugin = LoadedPlugin(
        manifest: manifest,
        dir: '/tmp/bars',
        enabled: true,
        contributions: [],
        bars: [
          PluginBarContribution(
            pluginId: 'bars',
            barId: 'status',
            scope: 'global',
            title: 'Status',
            icon: null,
            intervalSeconds: 10,
            settings: [
              PluginFormField(id: 'command', type: 'text', label: 'Command'),
            ],
            initLuaPath: '/tmp/bars/init.lua',
            pluginDir: '/tmp/bars',
            manifest: manifest,
          ),
        ],
      );
      expect(plugin.settingsSchema.map((f) => f.id), ['command']);
      expect(plugin.bars.first.runtimeId, 'plugin:bars:bar:status');
      expect(plugin.bars.first.allowExec, isTrue);
    });
  });
}
