import 'dart:io';

import 'package:flutter/services.dart';

import '../../i18n/strings.g.dart';

enum ShortcutGroup {
  navigation,
  quickLook,
  view,
  tabs,
  panes,
  terminal,
  fileOps,
  selection,
  search,
  general,
  plugins,
}

class KeyChord {
  final LogicalKeyboardKey key;
  final bool ctrl;
  final bool shift;
  final bool alt;

  const KeyChord({
    required this.key,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
  });

  bool sameChord(KeyChord other) =>
      key == other.key &&
      ctrl == other.ctrl &&
      shift == other.shift &&
      alt == other.alt;

  Map<String, dynamic> toJson() => {
    'key': key.keyId,
    'ctrl': ctrl,
    'shift': shift,
    'alt': alt,
  };

  static KeyChord fromJson(Map<String, dynamic> json) => KeyChord(
    key: LogicalKeyboardKey(json['key'] as int),
    ctrl: json['ctrl'] as bool? ?? false,
    shift: json['shift'] as bool? ?? false,
    alt: json['alt'] as bool? ?? false,
  );
}

class ShortcutDef {
  final String id;
  final String Function() label;
  final String? Function()? hint;
  final ShortcutGroup group;
  final LogicalKeyboardKey key;
  final bool ctrl;
  final bool shift;
  final bool alt;
  final LogicalKeyboardKey? altKey;
  final bool altCtrl;
  final bool altShift;
  final String? customKeyDisplay;
  final bool editable;

  const ShortcutDef({
    required this.id,
    required this.label,
    this.hint,
    required this.group,
    required this.key,
    this.ctrl = false,
    this.shift = false,
    this.alt = false,
    this.altKey,
    this.altCtrl = false,
    this.altShift = false,
    this.customKeyDisplay,
    this.editable = true,
  });

  KeyChord get defaultBinding =>
      KeyChord(key: key, ctrl: ctrl, shift: shift, alt: alt);

  KeyChord get binding => AppShortcuts.effectiveBinding(id);

  String get displayKeys {
    final b = binding;

    return _format(
      b.ctrl,
      b.shift,
      b.alt,
      b.key,
      AppShortcuts.isOverridden(id) ? null : customKeyDisplay,
    );
  }

  String? get displayAltKeys {
    if (altKey == null) return null;
    if (AppShortcuts.isOverridden(id)) return null;

    return _format(altCtrl, altShift, false, altKey!);
  }

  bool matchesKey(LogicalKeyboardKey eventKey) => eventKey == binding.key;

  bool matchesAltKey(LogicalKeyboardKey eventKey) =>
      altKey != null && !AppShortcuts.isOverridden(id) && eventKey == altKey;

  static String _format(
    bool c,
    bool s,
    bool a,
    LogicalKeyboardKey key, [
    String? customDisplay,
  ]) {
    final parts = <String>[];
    if (c) parts.add(Platform.isMacOS ? '⌘' : 'Ctrl');
    if (s) parts.add(Platform.isMacOS ? '⇧' : 'Shift');
    if (a) parts.add(Platform.isMacOS ? '⌥' : 'Alt');
    parts.add(customDisplay ?? _keyLabel(key));

    return parts.join('+');
  }

  static String formatBinding(KeyChord b) =>
      _format(b.ctrl, b.shift, b.alt, b.key);

  static String _keyLabel(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.delete) return 'Delete';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.insert) return 'Insert';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.space) return 'Space';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    final label = key.keyLabel;
    if (label.isNotEmpty) {
      return label.length == 1 ? label.toUpperCase() : label;
    }

    return key.debugName ?? 'Key';
  }
}

final Set<LogicalKeyboardKey> kModifierKeys = {
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.controlRight,
  LogicalKeyboardKey.shift,
  LogicalKeyboardKey.shiftLeft,
  LogicalKeyboardKey.shiftRight,
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.altLeft,
  LogicalKeyboardKey.altRight,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.metaLeft,
  LogicalKeyboardKey.metaRight,
};

class AppShortcuts {
  static final Map<String, KeyChord> _overrides = {};

  static bool get isControl {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (Platform.isMacOS) {
      return pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight);
    }

    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }

  static PhysicalKeyboardKey get terminalTogglePhysicalKey => Platform.isMacOS
      ? PhysicalKeyboardKey.keyJ
      : PhysicalKeyboardKey.backquote;

  static bool get isShift =>
      HardwareKeyboard.instance.logicalKeysPressed.contains(
        LogicalKeyboardKey.shiftLeft,
      ) ||
      HardwareKeyboard.instance.logicalKeysPressed.contains(
        LogicalKeyboardKey.shiftRight,
      );

  static bool get isAlt => HardwareKeyboard.instance.isAltPressed;

  static void applyOverrides(Map<String, KeyChord> overrides) {
    _overrides
      ..clear()
      ..addAll(overrides);
  }

  static bool isOverridden(String id) => _overrides.containsKey(id);

  static KeyChord effectiveBinding(String id) {
    final def = _byId[id]!;

    return _overrides[id] ?? def.defaultBinding;
  }

  static ShortcutDef? conflictFor(KeyChord chord, String exceptId) {
    for (final def in all) {
      if (def.id == exceptId) continue;
      if (effectiveBinding(def.id).sameChord(chord)) return def;
      if (!isOverridden(def.id) &&
          def.altKey != null &&
          KeyChord(
            key: def.altKey!,
            ctrl: def.altCtrl,
            shift: def.altShift,
          ).sameChord(chord)) {
        return def;
      }
    }

    return null;
  }

  static final List<ShortcutDef> _builtin = <ShortcutDef>[
    ShortcutDef(
      id: 'open_item',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.enter,
      editable: false,
    ),
    ShortcutDef(
      id: 'go_up',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.backspace,
    ),
    ShortcutDef(
      id: 'go_back',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.arrowLeft,
      alt: true,
      editable: false,
    ),
    ShortcutDef(
      id: 'go_forward',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.arrowRight,
      alt: true,
      editable: false,
    ),
    ShortcutDef(
      id: 'refresh',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.keyR,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'focus_path',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.keyL,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'cursor_up',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.arrowUp,
      editable: false,
    ),
    ShortcutDef(
      id: 'cursor_down',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.arrowDown,
      editable: false,
    ),
    ShortcutDef(
      id: 'page_up',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.pageUp,
      editable: false,
    ),
    ShortcutDef(
      id: 'page_down',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.pageDown,
      editable: false,
    ),
    ShortcutDef(
      id: 'home',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.home,
      editable: false,
    ),
    ShortcutDef(
      id: 'end',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.end,
      editable: false,
    ),
    ShortcutDef(
      id: 'quick_look',
      label: () => '',
      group: ShortcutGroup.quickLook,
      key: LogicalKeyboardKey.space,
      customKeyDisplay: 'Space',
    ),
    ShortcutDef(
      id: 'quick_look_close',
      label: () => '',
      group: ShortcutGroup.quickLook,
      key: LogicalKeyboardKey.space,
      customKeyDisplay: 'Space',
    ),
    ShortcutDef(
      id: 'quick_look_prev_file',
      label: () => '',
      group: ShortcutGroup.quickLook,
      key: LogicalKeyboardKey.arrowUp,
      editable: false,
    ),
    ShortcutDef(
      id: 'quick_look_next_file',
      label: () => '',
      group: ShortcutGroup.quickLook,
      key: LogicalKeyboardKey.arrowDown,
      editable: false,
    ),
    ShortcutDef(
      id: 'quick_look_prev_file_edit',
      label: () => '',
      group: ShortcutGroup.quickLook,
      key: LogicalKeyboardKey.arrowUp,
      ctrl: !Platform.isMacOS,
      alt: Platform.isMacOS,
      editable: false,
    ),
    ShortcutDef(
      id: 'quick_look_next_file_edit',
      label: () => '',
      group: ShortcutGroup.quickLook,
      key: LogicalKeyboardKey.arrowDown,
      ctrl: !Platform.isMacOS,
      alt: Platform.isMacOS,
      editable: false,
    ),
    ShortcutDef(
      id: 'quick_look_save',
      label: () => '',
      group: ShortcutGroup.quickLook,
      key: LogicalKeyboardKey.keyS,
      ctrl: true,
      editable: false,
    ),
    ShortcutDef(
      id: 'new_tab',
      label: () => '',
      group: ShortcutGroup.tabs,
      key: LogicalKeyboardKey.keyT,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'close_tab',
      label: () => '',
      group: ShortcutGroup.tabs,
      key: LogicalKeyboardKey.keyW,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'next_tab',
      label: () => '',
      group: ShortcutGroup.tabs,
      key: LogicalKeyboardKey.tab,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'prev_tab',
      label: () => '',
      group: ShortcutGroup.tabs,
      key: LogicalKeyboardKey.tab,
      ctrl: true,
      shift: true,
    ),
    ShortcutDef(
      id: 'switch_tab',
      label: () => '',
      group: ShortcutGroup.tabs,
      key: LogicalKeyboardKey.digit1,
      ctrl: true,
      customKeyDisplay: '1…9',
      editable: false,
    ),
    ShortcutDef(
      id: 'toggle_dual',
      label: () => '',
      group: ShortcutGroup.panes,
      key: LogicalKeyboardKey.f9,
      altKey: LogicalKeyboardKey.keyD,
      altCtrl: true,
    ),
    ShortcutDef(
      id: 'toggle_sidebar',
      label: () => '',
      group: ShortcutGroup.view,
      key: LogicalKeyboardKey.keyB,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'toggle_view',
      label: () => '',
      group: ShortcutGroup.view,
      key: LogicalKeyboardKey.keyG,
      ctrl: true,
      shift: true,
    ),
    ShortcutDef(
      id: 'switch_pane',
      label: () => '',
      group: ShortcutGroup.panes,
      key: LogicalKeyboardKey.tab,
      editable: false,
    ),
    ShortcutDef(
      id: 'focus_terminal',
      label: () => '',
      group: ShortcutGroup.terminal,
      key: Platform.isMacOS
          ? LogicalKeyboardKey.keyJ
          : LogicalKeyboardKey.backquote,
      ctrl: true,
      customKeyDisplay: Platform.isMacOS ? 'J' : '`',
    ),
    ShortcutDef(
      id: 'toggle_terminal',
      label: () => '',
      group: ShortcutGroup.terminal,
      key: Platform.isMacOS
          ? LogicalKeyboardKey.keyJ
          : LogicalKeyboardKey.backquote,
      ctrl: true,
      shift: true,
      customKeyDisplay: Platform.isMacOS ? 'J' : '`',
    ),
    ShortcutDef(
      id: 'new_terminal_tab',
      label: () => '',
      group: ShortcutGroup.terminal,
      key: LogicalKeyboardKey.keyT,
      ctrl: true,
      shift: true,
    ),
    ShortcutDef(
      id: 'close_terminal_tab',
      label: () => '',
      group: ShortcutGroup.terminal,
      key: LogicalKeyboardKey.keyW,
      ctrl: true,
      shift: true,
    ),
    ShortcutDef(
      id: 'insert_relative_paths',
      label: () => '',
      group: ShortcutGroup.terminal,
      key: LogicalKeyboardKey.enter,
      ctrl: true,
      editable: false,
    ),
    ShortcutDef(
      id: 'insert_absolute_paths',
      label: () => '',
      group: ShortcutGroup.terminal,
      key: LogicalKeyboardKey.enter,
      ctrl: true,
      shift: true,
      editable: false,
    ),
    ShortcutDef(
      id: 'terminal_font_increase',
      label: () => '',
      group: ShortcutGroup.terminal,
      key: LogicalKeyboardKey.equal,
      ctrl: true,
      customKeyDisplay: '+',
    ),
    ShortcutDef(
      id: 'terminal_font_decrease',
      label: () => '',
      group: ShortcutGroup.terminal,
      key: LogicalKeyboardKey.minus,
      ctrl: true,
      customKeyDisplay: '-',
    ),
    ShortcutDef(
      id: 'terminal_font_reset',
      label: () => '',
      group: ShortcutGroup.terminal,
      key: LogicalKeyboardKey.digit0,
      ctrl: true,
      customKeyDisplay: '0',
    ),
    ShortcutDef(
      id: 'file_list_zoom_in',
      label: () => '',
      group: ShortcutGroup.view,
      key: LogicalKeyboardKey.equal,
      ctrl: true,
      customKeyDisplay: '+',
    ),
    ShortcutDef(
      id: 'file_list_zoom_out',
      label: () => '',
      group: ShortcutGroup.view,
      key: LogicalKeyboardKey.minus,
      ctrl: true,
      customKeyDisplay: '-',
    ),
    ShortcutDef(
      id: 'file_list_zoom_reset',
      label: () => '',
      group: ShortcutGroup.view,
      key: LogicalKeyboardKey.digit0,
      ctrl: true,
      customKeyDisplay: '0',
    ),
    ShortcutDef(
      id: 'copy',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.keyC,
      ctrl: true,
      editable: false,
    ),
    ShortcutDef(
      id: 'cut',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.keyX,
      ctrl: true,
      editable: false,
    ),
    ShortcutDef(
      id: 'paste',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.keyV,
      ctrl: true,
      editable: false,
    ),
    ShortcutDef(
      id: 'delete',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.delete,
    ),
    ShortcutDef(
      id: 'delete_permanent',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.delete,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'rename',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.f2,
    ),
    ShortcutDef(
      id: 'new_folder',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.f7,
    ),
    ShortcutDef(
      id: 'dual_copy',
      label: () => '',
      hint: () => t.keybindings.dualHint,
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.f5,
    ),
    ShortcutDef(
      id: 'dual_move',
      label: () => '',
      hint: () => t.keybindings.dualHint,
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.f6,
    ),
    ShortcutDef(
      id: 'select_all',
      label: () => '',
      group: ShortcutGroup.selection,
      key: LogicalKeyboardKey.keyA,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'select_pattern',
      label: () => '',
      group: ShortcutGroup.selection,
      key: LogicalKeyboardKey.keyS,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'deselect_all',
      label: () => '',
      group: ShortcutGroup.selection,
      key: LogicalKeyboardKey.escape,
      editable: false,
    ),
    ShortcutDef(
      id: 'invert_selection',
      label: () => '',
      group: ShortcutGroup.selection,
      key: LogicalKeyboardKey.keyI,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'toggle_select',
      label: () => '',
      group: ShortcutGroup.selection,
      key: LogicalKeyboardKey.insert,
    ),
    ShortcutDef(
      id: 'save_selection',
      label: () => '',
      group: ShortcutGroup.selection,
      key: LogicalKeyboardKey.keyS,
      ctrl: true,
      shift: true,
    ),
    ShortcutDef(
      id: 'load_selection',
      label: () => '',
      group: ShortcutGroup.selection,
      key: LogicalKeyboardKey.keyL,
      ctrl: true,
      shift: true,
    ),
    ShortcutDef(
      id: 'compute_folder_size',
      label: () => '',
      group: ShortcutGroup.selection,
      key: LogicalKeyboardKey.keyS,
      alt: true,
    ),
    ShortcutDef(
      id: 'search',
      label: () => '',
      group: ShortcutGroup.search,
      key: LogicalKeyboardKey.keyF,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'recursive_search',
      label: () => '',
      group: ShortcutGroup.search,
      key: LogicalKeyboardKey.keyF,
      ctrl: true,
      shift: true,
    ),
    ShortcutDef(
      id: 'toggle_hidden',
      label: () => '',
      group: ShortcutGroup.view,
      key: LogicalKeyboardKey.keyH,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'preferences',
      label: () => '',
      group: ShortcutGroup.general,
      key: LogicalKeyboardKey.comma,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'help',
      label: () => '',
      group: ShortcutGroup.general,
      key: LogicalKeyboardKey.slash,
      shift: true,
      customKeyDisplay: '?',
      editable: false,
    ),
    ShortcutDef(
      id: 'close_search',
      label: () => '',
      group: ShortcutGroup.search,
      key: LogicalKeyboardKey.escape,
      editable: false,
    ),
  ];

  /// Dynamic shortcuts contributed by plugins. Replaced wholesale on reload.
  static List<ShortcutDef> _pluginDefs = const [];

  static List<ShortcutDef> get all => [..._builtin, ..._pluginDefs];

  static Map<String, ShortcutDef> _byId = {for (final s in _builtin) s.id: s};

  /// Registers plugin-contributed shortcuts and rebuilds the id index.
  static void setPluginShortcuts(List<ShortcutDef> defs) {
    _pluginDefs = defs;
    _byId = {for (final s in all) s.id: s};
  }

  static ShortcutDef getById(String id) => _byId[id]!;
  static ShortcutDef? tryGetById(String id) => _byId[id];

  /// True if [chord] is already bound by a built-in shortcut. Used to stop
  /// plugins from shadowing core keys.
  static bool isChordUsedByBuiltin(KeyChord chord) {
    for (final def in _builtin) {
      if (effectiveBinding(def.id).sameChord(chord)) return true;
      if (!isOverridden(def.id) &&
          def.altKey != null &&
          KeyChord(
            key: def.altKey!,
            ctrl: def.altCtrl,
            shift: def.altShift,
          ).sameChord(chord)) {
        return true;
      }
    }

    return false;
  }

  static const Map<String, LogicalKeyboardKey> _namedKeys = {
    'space': LogicalKeyboardKey.space,
    'enter': LogicalKeyboardKey.enter,
    'return': LogicalKeyboardKey.enter,
    'tab': LogicalKeyboardKey.tab,
    'escape': LogicalKeyboardKey.escape,
    'esc': LogicalKeyboardKey.escape,
    'backspace': LogicalKeyboardKey.backspace,
    'delete': LogicalKeyboardKey.delete,
    'del': LogicalKeyboardKey.delete,
    'up': LogicalKeyboardKey.arrowUp,
    'down': LogicalKeyboardKey.arrowDown,
    'left': LogicalKeyboardKey.arrowLeft,
    'right': LogicalKeyboardKey.arrowRight,
    'home': LogicalKeyboardKey.home,
    'end': LogicalKeyboardKey.end,
    'pageup': LogicalKeyboardKey.pageUp,
    'pagedown': LogicalKeyboardKey.pageDown,
    'comma': LogicalKeyboardKey.comma,
    'period': LogicalKeyboardKey.period,
    'slash': LogicalKeyboardKey.slash,
  };

  /// Parses a chord spec like `"ctrl+shift+x"` or `"alt+f5"` into a [KeyChord],
  /// or null if no key token is recognised. Modifier names: ctrl/control, cmd/
  /// meta (treated as ctrl), shift, alt/option.
  static KeyChord? parseChord(String spec) {
    final parts = spec
        .toLowerCase()
        .split('+')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    var ctrl = false, shift = false, alt = false;
    LogicalKeyboardKey? key;
    for (final part in parts) {
      switch (part) {
        case 'ctrl':
        case 'control':
        case 'cmd':
        case 'command':
        case 'meta':
        case 'super':
          ctrl = true;
        case 'shift':
          shift = true;
        case 'alt':
        case 'option':
          alt = true;
        default:
          key = _parseKeyToken(part);
      }
    }
    if (key == null) return null;

    return KeyChord(key: key, ctrl: ctrl, shift: shift, alt: alt);
  }

  static LogicalKeyboardKey? _parseKeyToken(String token) {
    if (_namedKeys.containsKey(token)) return _namedKeys[token];
    if (token.length == 1) {
      final code = token.codeUnitAt(0);
      if (code >= 0x61 && code <= 0x7a) {
        return LogicalKeyboardKey(
          LogicalKeyboardKey.keyA.keyId + (code - 0x61),
        );
      }
      if (code >= 0x30 && code <= 0x39) {
        return LogicalKeyboardKey(
          LogicalKeyboardKey.digit0.keyId + (code - 0x30),
        );
      }
    }
    final fn = RegExp(r'^f([1-9]|1[0-2])$').firstMatch(token);
    if (fn != null) {
      final n = int.parse(fn.group(1)!);

      return LogicalKeyboardKey(LogicalKeyboardKey.f1.keyId + (n - 1));
    }

    return null;
  }

  static bool isKey(String id, LogicalKeyboardKey key) {
    final def = _byId[id];
    if (def == null) return false;

    return def.matchesKey(key) || def.matchesAltKey(key);
  }

  static bool matches(String id, LogicalKeyboardKey key) {
    final def = _byId[id];
    if (def == null) return false;
    final ctrl = isControl;
    final shift = isShift;
    final alt = isAlt;
    final b = effectiveBinding(id);
    if (key == b.key && ctrl == b.ctrl && shift == b.shift && alt == b.alt) {
      return true;
    }
    if (!isOverridden(id) &&
        def.altKey != null &&
        key == def.altKey &&
        ctrl == def.altCtrl &&
        shift == def.altShift &&
        !alt) {
      return true;
    }

    return false;
  }

  static bool matchesIgnoreShift(String id, LogicalKeyboardKey key) {
    final def = _byId[id];
    if (def == null) return false;
    final b = effectiveBinding(id);

    return key == b.key && isControl == b.ctrl && isAlt == b.alt;
  }
}
