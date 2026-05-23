import 'dart:io';

import 'package:flutter/services.dart';

import '../../i18n/strings.g.dart';

enum ShortcutGroup { navigation, tabs, panes, fileOps, selection, search }

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
  });

  String get displayKeys => _format(ctrl, shift, alt, key, customKeyDisplay);

  String? get displayAltKeys {
    if (altKey == null) return null;
    return _format(altCtrl, altShift, false, altKey!);
  }

  bool matchesKey(LogicalKeyboardKey eventKey) => eventKey == key;

  bool matchesAltKey(LogicalKeyboardKey eventKey) =>
      altKey != null && eventKey == altKey;

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

  static String _keyLabel(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.enter) return 'Enter';
    if (key == LogicalKeyboardKey.backspace) return 'Backspace';
    if (key == LogicalKeyboardKey.delete) return 'Delete';
    if (key == LogicalKeyboardKey.escape) return 'Esc';
    if (key == LogicalKeyboardKey.insert) return 'Insert';
    if (key == LogicalKeyboardKey.tab) return 'Tab';
    if (key == LogicalKeyboardKey.arrowLeft) return '←';
    if (key == LogicalKeyboardKey.arrowRight) return '→';
    if (key == LogicalKeyboardKey.arrowUp) return '↑';
    if (key == LogicalKeyboardKey.arrowDown) return '↓';
    return key.keyLabel;
  }
}

class AppShortcuts {
  static bool get isControl {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    if (Platform.isMacOS) {
      return pressed.contains(LogicalKeyboardKey.metaLeft) ||
          pressed.contains(LogicalKeyboardKey.metaRight);
    }
    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight);
  }

  static bool get isShift =>
      HardwareKeyboard.instance.logicalKeysPressed.contains(
        LogicalKeyboardKey.shiftLeft,
      ) ||
      HardwareKeyboard.instance.logicalKeysPressed.contains(
        LogicalKeyboardKey.shiftRight,
      );

  static final all = <ShortcutDef>[
    ShortcutDef(
      id: 'open_item',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.enter,
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
    ),
    ShortcutDef(
      id: 'go_forward',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.arrowRight,
      alt: true,
    ),
    ShortcutDef(
      id: 'refresh',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.keyR,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'cursor_up',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.arrowUp,
    ),
    ShortcutDef(
      id: 'cursor_down',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.arrowDown,
    ),
    ShortcutDef(
      id: 'quick_look',
      label: () => '',
      group: ShortcutGroup.navigation,
      key: LogicalKeyboardKey.space,
      customKeyDisplay: 'Space',
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
      group: ShortcutGroup.panes,
      key: LogicalKeyboardKey.keyB,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'switch_pane',
      label: () => '',
      group: ShortcutGroup.panes,
      key: LogicalKeyboardKey.tab,
    ),
    ShortcutDef(
      id: 'copy',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.keyC,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'cut',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.keyX,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'paste',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.keyV,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'delete',
      label: () => '',
      group: ShortcutGroup.fileOps,
      key: LogicalKeyboardKey.delete,
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
      group: ShortcutGroup.panes,
      key: LogicalKeyboardKey.keyH,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'preferences',
      label: () => '',
      group: ShortcutGroup.search,
      key: LogicalKeyboardKey.comma,
      ctrl: true,
    ),
    ShortcutDef(
      id: 'close_search',
      label: () => '',
      group: ShortcutGroup.search,
      key: LogicalKeyboardKey.escape,
    ),
  ];

  static final _byId = {for (final s in all) s.id: s};

  static ShortcutDef getById(String id) => _byId[id]!;

  static bool isKey(String id, LogicalKeyboardKey key) =>
      _byId[id]?.matchesKey(key) == true ||
      _byId[id]?.matchesAltKey(key) == true;
}
