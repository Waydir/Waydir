import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/keyboard/keyboard_shortcuts.dart';

void main() {
  group('AppShortcuts.parseChord', () {
    test('parses modifiers and a letter key', () {
      final chord = AppShortcuts.parseChord('ctrl+shift+x');
      expect(chord, isNotNull);
      expect(chord!.ctrl, isTrue);
      expect(chord.shift, isTrue);
      expect(chord.alt, isFalse);
      expect(chord.key, LogicalKeyboardKey.keyX);
    });

    test('treats cmd/meta as ctrl and parses function keys', () {
      final chord = AppShortcuts.parseChord('cmd+f5');
      expect(chord!.ctrl, isTrue);
      expect(chord.key, LogicalKeyboardKey.f5);
    });

    test('parses named keys', () {
      expect(
        AppShortcuts.parseChord('alt+enter')!.key,
        LogicalKeyboardKey.enter,
      );
      expect(
        AppShortcuts.parseChord('ctrl+space')!.key,
        LogicalKeyboardKey.space,
      );
    });

    test('returns null when no key token present', () {
      expect(AppShortcuts.parseChord('ctrl+shift'), isNull);
      expect(AppShortcuts.parseChord(''), isNull);
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
  });
}
