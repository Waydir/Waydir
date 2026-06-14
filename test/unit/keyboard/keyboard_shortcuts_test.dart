import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/keyboard/keyboard_shortcuts.dart';

void main() {
  setUp(() => AppShortcuts.applyOverrides({}));
  tearDown(() {
    AppShortcuts.applyOverrides({});
    AppShortcuts.setPluginShortcuts([]);
  });

  group('KeyChord.sameChord', () {
    test('equal chords match', () {
      const a = KeyChord(key: LogicalKeyboardKey.keyA, ctrl: true);
      const b = KeyChord(key: LogicalKeyboardKey.keyA, ctrl: true);
      expect(a.sameChord(b), isTrue);
    });

    test('different key does not match', () {
      const a = KeyChord(key: LogicalKeyboardKey.keyA, ctrl: true);
      const b = KeyChord(key: LogicalKeyboardKey.keyB, ctrl: true);
      expect(a.sameChord(b), isFalse);
    });

    test('different modifier does not match', () {
      const a = KeyChord(key: LogicalKeyboardKey.keyA, ctrl: true);
      const b = KeyChord(key: LogicalKeyboardKey.keyA, ctrl: true, shift: true);
      expect(a.sameChord(b), isFalse);
    });

    test('chords with no modifiers match', () {
      const a = KeyChord(key: LogicalKeyboardKey.f5);
      const b = KeyChord(key: LogicalKeyboardKey.f5);
      expect(a.sameChord(b), isTrue);
    });
  });

  group('KeyChord JSON round-trip', () {
    test('serialises and deserialises with all modifiers', () {
      const original = KeyChord(
        key: LogicalKeyboardKey.keyZ,
        ctrl: true,
        shift: true,
        alt: true,
      );

      final restored = KeyChord.fromJson(original.toJson());

      expect(restored.sameChord(original), isTrue);
    });

    test('serialises and deserialises without modifiers', () {
      const original = KeyChord(key: LogicalKeyboardKey.f9);

      final restored = KeyChord.fromJson(original.toJson());

      expect(restored.sameChord(original), isTrue);
    });

    test('missing modifier fields default to false', () {
      final chord = KeyChord.fromJson({'key': LogicalKeyboardKey.keyA.keyId});

      expect(chord.ctrl, isFalse);
      expect(chord.shift, isFalse);
      expect(chord.alt, isFalse);
    });
  });

  group('AppShortcuts.parseChord', () {
    final cases = <(String, KeyChord)>[
      (
        'ctrl+shift+x',
        KeyChord(key: LogicalKeyboardKey.keyX, ctrl: true, shift: true),
      ),
      ('alt+enter', KeyChord(key: LogicalKeyboardKey.enter, alt: true)),
      ('ctrl+space', KeyChord(key: LogicalKeyboardKey.space, ctrl: true)),
      ('f5', KeyChord(key: LogicalKeyboardKey.f5)),
      ('f12', KeyChord(key: LogicalKeyboardKey.f12)),
      ('ctrl+0', KeyChord(key: LogicalKeyboardKey.digit0, ctrl: true)),
      ('shift+tab', KeyChord(key: LogicalKeyboardKey.tab, shift: true)),
      (
        'ctrl+alt+delete',
        KeyChord(key: LogicalKeyboardKey.delete, ctrl: true, alt: true),
      ),
    ];

    for (final (spec, expected) in cases) {
      test('parses "$spec"', () {
        final chord = AppShortcuts.parseChord(spec);
        expect(chord, isNotNull);
        expect(chord!.sameChord(expected), isTrue);
      });
    }

    test('treats cmd, meta, super, command as ctrl', () {
      for (final alias in ['cmd', 'meta', 'super', 'command']) {
        final chord = AppShortcuts.parseChord('$alias+a');
        expect(chord!.ctrl, isTrue, reason: '$alias should map to ctrl');
      }
    });

    test('treats option as alt', () {
      final chord = AppShortcuts.parseChord('option+a')!;
      expect(chord.alt, isTrue);
    });

    test('returns null when no key token is present', () {
      expect(AppShortcuts.parseChord('ctrl+shift'), isNull);
    });

    test('returns null for an empty string', () {
      expect(AppShortcuts.parseChord(''), isNull);
    });

    test('parsing is case-insensitive', () {
      final lower = AppShortcuts.parseChord('ctrl+a')!;
      final upper = AppShortcuts.parseChord('CTRL+A')!;
      expect(lower.sameChord(upper), isTrue);
    });
  });

  group('AppShortcuts overrides', () {
    test('effectiveBinding returns default before any override', () {
      final def = AppShortcuts.getById('select_all');

      expect(AppShortcuts.isOverridden('select_all'), isFalse);
      expect(
        AppShortcuts.effectiveBinding(
          'select_all',
        ).sameChord(def.defaultBinding),
        isTrue,
      );
    });

    test('effectiveBinding returns override after applyOverrides', () {
      final custom = AppShortcuts.parseChord('ctrl+shift+a')!;

      AppShortcuts.applyOverrides({'select_all': custom});

      expect(AppShortcuts.isOverridden('select_all'), isTrue);
      expect(
        AppShortcuts.effectiveBinding('select_all').sameChord(custom),
        isTrue,
      );
    });

    test('applyOverrides clears all previous overrides', () {
      AppShortcuts.applyOverrides({
        'select_all': AppShortcuts.parseChord('ctrl+shift+a')!,
      });

      AppShortcuts.applyOverrides({});

      expect(AppShortcuts.isOverridden('select_all'), isFalse);
    });

    test(
      'non-overridden shortcuts remain at default after partial override',
      () {
        AppShortcuts.applyOverrides({
          'select_all': AppShortcuts.parseChord('ctrl+shift+a')!,
        });

        final refreshBinding = AppShortcuts.effectiveBinding('refresh');
        expect(
          refreshBinding.sameChord(
            AppShortcuts.getById('refresh').defaultBinding,
          ),
          isTrue,
        );
      },
    );
  });

  group('AppShortcuts.conflictFor', () {
    test('returns conflicting def when another action uses the same chord', () {
      final selectAllBinding = AppShortcuts.getById(
        'select_all',
      ).defaultBinding;

      final conflict = AppShortcuts.conflictFor(selectAllBinding, 'new_tab');

      expect(conflict, isNotNull);
      expect(conflict!.id, 'select_all');
    });

    test('returns null for a chord no action uses', () {
      final free = AppShortcuts.parseChord('ctrl+alt+f9')!;

      expect(AppShortcuts.conflictFor(free, 'select_all'), isNull);
    });

    test('excludes the exceptId from conflict check', () {
      final binding = AppShortcuts.getById('select_all').defaultBinding;

      expect(AppShortcuts.conflictFor(binding, 'select_all'), isNull);
    });

    test('detects conflict with overridden binding', () {
      final newChord = AppShortcuts.parseChord('ctrl+alt+f9')!;
      AppShortcuts.applyOverrides({'refresh': newChord});

      final conflict = AppShortcuts.conflictFor(newChord, 'select_all');

      expect(conflict, isNotNull);
      expect(conflict!.id, 'refresh');
    });
  });

  group('AppShortcuts.isChordUsedByBuiltin', () {
    test('flags a chord bound by a built-in shortcut', () {
      final selectAll = AppShortcuts.getById('select_all').defaultBinding;
      expect(AppShortcuts.isChordUsedByBuiltin(selectAll), isTrue);
    });

    test('clears a chord no built-in uses', () {
      final free = AppShortcuts.parseChord('ctrl+alt+f9')!;
      expect(AppShortcuts.isChordUsedByBuiltin(free), isFalse);
    });

    test('detects when an overridden built-in now uses the chord', () {
      final customChord = AppShortcuts.parseChord('ctrl+alt+f8')!;
      AppShortcuts.applyOverrides({'select_all': customChord});

      expect(AppShortcuts.isChordUsedByBuiltin(customChord), isTrue);
    });
  });

  group('AppShortcuts.setPluginShortcuts', () {
    final pluginDef = ShortcutDef(
      id: 'plugin:test:run',
      label: () => 'Run',
      group: ShortcutGroup.plugins,
      key: LogicalKeyboardKey.f10,
    );

    test('registered plugin shortcut is accessible via getById', () {
      AppShortcuts.setPluginShortcuts([pluginDef]);

      expect(AppShortcuts.tryGetById('plugin:test:run'), isNotNull);
      expect(AppShortcuts.getById('plugin:test:run').id, 'plugin:test:run');
    });

    test('plugin shortcut appears in all list', () {
      AppShortcuts.setPluginShortcuts([pluginDef]);

      expect(AppShortcuts.all.any((d) => d.id == 'plugin:test:run'), isTrue);
    });

    test('clearing plugin shortcuts removes them from all', () {
      AppShortcuts.setPluginShortcuts([pluginDef]);
      AppShortcuts.setPluginShortcuts([]);

      expect(AppShortcuts.tryGetById('plugin:test:run'), isNull);
      expect(AppShortcuts.all.any((d) => d.id == 'plugin:test:run'), isFalse);
    });

    test('replaces previous plugin set on each call', () {
      final other = ShortcutDef(
        id: 'plugin:test:other',
        label: () => 'Other',
        group: ShortcutGroup.plugins,
        key: LogicalKeyboardKey.f11,
      );

      AppShortcuts.setPluginShortcuts([pluginDef]);
      AppShortcuts.setPluginShortcuts([other]);

      expect(AppShortcuts.tryGetById('plugin:test:run'), isNull);
      expect(AppShortcuts.tryGetById('plugin:test:other'), isNotNull);
    });

    test(
      'built-in shortcuts still accessible after plugin shortcuts are set',
      () {
        AppShortcuts.setPluginShortcuts([pluginDef]);

        expect(AppShortcuts.tryGetById('select_all'), isNotNull);
      },
    );
  });

  group('ShortcutDef.defaultBinding', () {
    test('returns chord matching the def fields', () {
      final def = AppShortcuts.getById('select_all');
      final binding = def.defaultBinding;

      expect(binding.key, LogicalKeyboardKey.keyA);
      expect(binding.ctrl, isTrue);
      expect(binding.shift, isFalse);
      expect(binding.alt, isFalse);
    });
  });
}
