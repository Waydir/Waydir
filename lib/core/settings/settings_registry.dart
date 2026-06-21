import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals.dart';

import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme_definition.dart';
import '../../ui/theme/app_theme_registry.dart';
import '../terminal/shell_detector.dart';
import '../terminal/terminal.dart';
import 'settings_store.dart';

enum SettingsCategory { general, appearance, terminal, quickLook }

enum SettingKind { toggle, choice, text }

class SettingChoice<T> {
  final T value;
  final String Function() label;
  final IconData icon;

  const SettingChoice({
    required this.value,
    required this.label,
    required this.icon,
  });
}

abstract class AppSetting<T> {
  final String id;
  final SettingsCategory category;
  final SettingKind kind;
  final String Function() label;
  final String? Function()? hint;
  final List<String> searchTerms;
  final Signal<T> signal;

  const AppSetting({
    required this.id,
    required this.category,
    required this.kind,
    required this.label,
    this.hint,
    this.searchTerms = const [],
    required this.signal,
  });

  T get value => signal.value;

  set value(T next) => signal.value = next;

  String displayValue();
}

class ToggleSetting extends AppSetting<bool> {
  const ToggleSetting({
    required super.id,
    required super.category,
    required super.label,
    super.hint,
    super.searchTerms,
    required super.signal,
  }) : super(kind: SettingKind.toggle);

  void toggle() => value = !value;

  @override
  String displayValue() =>
      value ? t.commandPalette.enabled : t.commandPalette.disabled;
}

class ChoiceSetting<T> extends AppSetting<T> {
  List<SettingChoice<T>> choices;

  ChoiceSetting({
    required super.id,
    required super.category,
    required super.label,
    super.hint,
    super.searchTerms,
    required super.signal,
    required this.choices,
  }) : super(kind: SettingKind.choice);

  SettingChoice<T> choiceFor(T value) {
    return choices.firstWhere(
      (choice) => choice.value == value,
      orElse: () => choices.first,
    );
  }

  @override
  String displayValue() => choiceFor(value).label();
}

class TextSetting extends AppSetting<String> {
  final String hintText;

  const TextSetting({
    required super.id,
    required super.category,
    required super.label,
    super.hint,
    super.searchTerms,
    required super.signal,
    this.hintText = '',
  }) : super(kind: SettingKind.text);

  @override
  String displayValue() => value.isEmpty ? hintText : value;
}

class SettingsRegistry {
  SettingsRegistry._();

  static final SettingsRegistry instance = SettingsRegistry._();

  late final List<AppSetting<dynamic>> all = [
    ToggleSetting(
      id: 'general.restoreSession',
      category: SettingsCategory.general,
      label: () => t.preferences.general.restoreSession,
      hint: () => t.preferences.general.restoreSessionHint,
      searchTerms: const ['startup', 'tabs', 'panes'],
      signal: SettingsStore.instance.restoreSession,
    ),
    TextSetting(
      id: 'general.defaultStartingPath',
      category: SettingsCategory.general,
      label: () => t.preferences.general.defaultPath,
      hint: () => t.preferences.general.defaultPathHint,
      hintText: t.preferences.general.defaultPathPlaceholder,
      searchTerms: const ['startup', 'home', 'path'],
      signal: SettingsStore.instance.defaultStartingPath,
    ),
    ToggleSetting(
      id: 'general.confirmDelete',
      category: SettingsCategory.general,
      label: () => t.preferences.general.confirmDelete,
      hint: () => t.preferences.general.confirmDeleteHint,
      searchTerms: const ['delete', 'file operations'],
      signal: SettingsStore.instance.confirmDelete,
    ),
    ToggleSetting(
      id: 'general.confirmCopy',
      category: SettingsCategory.general,
      label: () => t.preferences.general.confirmCopy,
      hint: () => t.preferences.general.confirmCopyHint,
      searchTerms: const ['copy', 'file operations'],
      signal: SettingsStore.instance.confirmCopy,
    ),
    ToggleSetting(
      id: 'general.confirmMove',
      category: SettingsCategory.general,
      label: () => t.preferences.general.confirmMove,
      hint: () => t.preferences.general.confirmMoveHint,
      searchTerms: const ['move', 'file operations'],
      signal: SettingsStore.instance.confirmMove,
    ),
    ToggleSetting(
      id: 'general.dragMovesByDefault',
      category: SettingsCategory.general,
      label: () => t.preferences.general.dragMovesByDefault,
      hint: () => t.preferences.general.dragMovesByDefaultHint,
      searchTerms: const ['drag', 'drop', 'move', 'copy', 'file operations'],
      signal: SettingsStore.instance.dragMovesByDefault,
    ),
    ToggleSetting(
      id: 'general.rememberFolderState',
      category: SettingsCategory.general,
      label: () => t.preferences.general.rememberFolderState,
      hint: () => t.preferences.general.rememberFolderStateHint,
      searchTerms: const ['selection', 'cursor', 'folder', 'remember'],
      signal: SettingsStore.instance.rememberFolderState,
    ),
    ToggleSetting(
      id: 'general.rememberFolderSort',
      category: SettingsCategory.general,
      label: () => t.preferences.general.rememberFolderSort,
      hint: () => t.preferences.general.rememberFolderSortHint,
      searchTerms: const ['sort', 'folder', 'remember'],
      signal: SettingsStore.instance.rememberFolderSort,
    ),
    ToggleSetting(
      id: 'general.typeAheadBuffer',
      category: SettingsCategory.general,
      label: () => t.preferences.general.typeAheadBuffer,
      hint: () => t.preferences.general.typeAheadBufferHint,
      searchTerms: const ['type', 'ahead', 'jump', 'search', 'keyboard'],
      signal: SettingsStore.instance.typeAheadBuffer,
    ),
    ChoiceSetting<String>(
      id: 'general.deleteKeyBehavior',
      category: SettingsCategory.general,
      label: () => t.preferences.general.deleteKeyBehavior,
      hint: () => t.preferences.general.deleteKeyBehaviorHint,
      searchTerms: const ['delete', 'trash', 'recycle'],
      signal: SettingsStore.instance.deleteKeyBehavior,
      choices: [
        SettingChoice(
          value: 'trash',
          label: () => t.preferences.general.deleteKeyTrash,
          icon: WaydirIconsRegular.trashSimple,
        ),
        SettingChoice(
          value: 'permanent',
          label: () => t.preferences.general.deleteKeyPermanent,
          icon: WaydirIconsRegular.trash,
        ),
      ],
    ),
    ChoiceSetting<String>(
      id: 'terminal.shell',
      category: SettingsCategory.terminal,
      label: () => t.preferences.terminal.shellLabel,
      hint: () => t.preferences.terminal.shellHint,
      searchTerms: const ['terminal', 'shell', 'bash', 'zsh', 'powershell'],
      signal: SettingsStore.instance.terminalShell,
      choices: _shellChoices(const []),
    ),
    ChoiceSetting<String>(
      id: 'terminal.external',
      category: SettingsCategory.terminal,
      label: () => t.preferences.general.terminalLabel,
      hint: () => t.preferences.general.terminalHint,
      searchTerms: const ['terminal', 'open in terminal'],
      signal: SettingsStore.instance.terminal,
      choices: _externalTerminalChoices(const []),
    ),
    TextSetting(
      id: 'terminal.externalCustomCommand',
      category: SettingsCategory.terminal,
      label: () => t.preferences.general.terminalCustomLabel,
      hint: () => t.preferences.general.terminalCustomHelp,
      hintText: t.preferences.general.terminalCustomHint,
      searchTerms: const ['terminal', 'command'],
      signal: SettingsStore.instance.terminalCustomCommand,
    ),
    ToggleSetting(
      id: 'terminal.useSystemFont',
      category: SettingsCategory.terminal,
      label: () => t.preferences.terminal.useSystemFont,
      hint: () => t.preferences.terminal.useSystemFontHint,
      searchTerms: const ['terminal', 'font', 'system', 'monospace'],
      signal: SettingsStore.instance.terminalUseSystemFont,
    ),
    ChoiceSetting<String>(
      id: 'terminal.fontFamily',
      category: SettingsCategory.terminal,
      label: () => t.preferences.terminal.fontFamily,
      hint: () => t.preferences.terminal.fontFamilyHint,
      searchTerms: const ['terminal', 'font', 'family', 'monospace'],
      signal: SettingsStore.instance.terminalFontFamily,
      choices: _fontChoices(const ['monospace']),
    ),
    ChoiceSetting<int>(
      id: 'terminal.fontSize',
      category: SettingsCategory.terminal,
      label: () => t.preferences.terminal.fontSize,
      hint: () => t.preferences.terminal.fontSizeHint,
      searchTerms: const ['terminal', 'font', 'size', 'zoom'],
      signal: SettingsStore.instance.terminalFontSize,
      choices: [
        for (final value in SettingsStore.terminalFontSizes)
          SettingChoice(
            value: value,
            label: () => '${value}px',
            icon: WaydirIconsRegular.textAa,
          ),
      ],
    ),
    ChoiceSetting<double>(
      id: 'terminal.lineHeight',
      category: SettingsCategory.terminal,
      label: () => t.preferences.terminal.lineHeight,
      hint: () => t.preferences.terminal.lineHeightHint,
      searchTerms: const ['terminal', 'line', 'height', 'spacing', 'leading'],
      signal: SettingsStore.instance.terminalLineHeight,
      choices: [
        for (final value in const [1.0, 1.1, 1.2, 1.3, 1.4, 1.5])
          SettingChoice(
            value: value,
            label: () => value.toStringAsFixed(1),
            icon: WaydirIconsRegular.rows,
          ),
      ],
    ),
    ChoiceSetting<String>(
      id: 'terminal.copyPasteMode',
      category: SettingsCategory.terminal,
      label: () => t.preferences.terminal.copyPasteMode,
      hint: () => t.preferences.terminal.copyPasteModeHint,
      searchTerms: const [
        'terminal',
        'copy',
        'paste',
        'clipboard',
        'ctrl',
        'shift',
        'modifier',
      ],
      signal: SettingsStore.instance.terminalCopyPasteMode,
      choices: [
        SettingChoice(
          value: 'standard',
          label: () => Platform.isMacOS
              ? t.preferences.terminal.copyPasteModeStandardMac
              : t.preferences.terminal.copyPasteModeStandard,
          icon: WaydirIconsRegular.copy,
        ),
        SettingChoice(
          value: 'shift',
          label: () => Platform.isMacOS
              ? t.preferences.terminal.copyPasteModeShiftMac
              : t.preferences.terminal.copyPasteModeShift,
          icon: WaydirIconsRegular.clipboard,
        ),
      ],
    ),
    ChoiceSetting<String>(
      id: 'appearance.theme',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.theme,
      hint: () => t.preferences.appearance.themeHint,
      searchTerms: const [
        'theme',
        'dark',
        'light',
        'nord',
        'tokyo',
        'gruvbox',
        'dracula',
        'solarized',
        'catppuccin',
        'appearance',
      ],
      signal: SettingsStore.instance.themeId,
      choices: [
        for (final theme in AppThemeRegistry.instance.themes)
          SettingChoice(
            value: theme.id,
            label: () => _themeLabel(theme),
            icon: _themeIcon(theme),
          ),
      ],
    ),
    ToggleSetting(
      id: 'appearance.showHiddenDefault',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.showHidden,
      hint: () => t.preferences.appearance.showHiddenHint,
      searchTerms: const ['hidden', 'dotfiles', 'files'],
      signal: SettingsStore.instance.showHiddenDefault,
    ),
    ChoiceSetting<String>(
      id: 'appearance.rowDensity',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.rowDensity,
      searchTerms: const ['rows', 'density', 'compact', 'comfortable'],
      signal: SettingsStore.instance.rowDensity,
      choices: [
        SettingChoice(
          value: 'comfortable',
          label: () => t.preferences.appearance.rowDensityComfortable,
          icon: WaydirIconsRegular.rows,
        ),
        SettingChoice(
          value: 'compact',
          label: () => t.preferences.appearance.rowDensityCompact,
          icon: WaydirIconsRegular.list,
        ),
      ],
    ),
    ChoiceSetting<int>(
      id: 'appearance.fileListHorizontalSpacing',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.fileListHorizontalSpacing,
      searchTerms: const ['files', 'spacing', 'horizontal', 'padding'],
      signal: SettingsStore.instance.fileListHorizontalSpacing,
      choices: _spacingChoices(WaydirIconsRegular.arrowsLeftRight),
    ),
    ChoiceSetting<String>(
      id: 'appearance.columnWidthMode',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.columnWidthMode,
      searchTerms: const ['files', 'columns', 'width', 'resize'],
      signal: SettingsStore.instance.columnWidthMode,
      choices: [
        SettingChoice(
          value: 'automatic',
          label: () => t.preferences.appearance.columnWidthModeAutomatic,
          icon: WaydirIconsRegular.magicWand,
        ),
        SettingChoice(
          value: 'resizable',
          label: () => t.preferences.appearance.columnWidthModeResizable,
          icon: WaydirIconsRegular.columns,
        ),
      ],
    ),
    ChoiceSetting<int>(
      id: 'appearance.fileListVerticalSpacing',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.fileListVerticalSpacing,
      searchTerms: const ['files', 'spacing', 'vertical', 'rows', 'gap'],
      signal: SettingsStore.instance.fileListVerticalSpacing,
      choices: _spacingChoices(WaydirIconsRegular.rows),
    ),
    ChoiceSetting<String>(
      id: 'appearance.dateFormat',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.dateFormat,
      searchTerms: const ['date', 'time', 'modified', 'relative', 'iso'],
      signal: SettingsStore.instance.dateFormat,
      choices: [
        SettingChoice(
          value: 'iso',
          label: () => t.preferences.appearance.dateFormatIso,
          icon: WaydirIconsRegular.calendar,
        ),
        SettingChoice(
          value: 'locale',
          label: () => t.preferences.appearance.dateFormatLocale,
          icon: WaydirIconsRegular.calendarBlank,
        ),
        SettingChoice(
          value: 'relative',
          label: () => t.preferences.appearance.dateFormatRelative,
          icon: WaydirIconsRegular.clockClockwise,
        ),
      ],
    ),
    ToggleSetting(
      id: 'appearance.recentDatesRelative',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.recentDatesRelative,
      hint: () => t.preferences.appearance.recentDatesRelativeHint,
      searchTerms: const ['date', 'time', 'recent', 'relative'],
      signal: SettingsStore.instance.recentDatesRelative,
    ),
    ToggleSetting(
      id: 'appearance.foldersFirst',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.foldersFirst,
      hint: () => t.preferences.appearance.foldersFirstHint,
      searchTerms: const ['sort', 'folders', 'order'],
      signal: SettingsStore.instance.foldersFirst,
    ),
    ToggleSetting(
      id: 'appearance.sortFolders',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.sortFolders,
      hint: () => t.preferences.appearance.sortFoldersHint,
      searchTerms: const ['sort', 'folders', 'order', 'files', 'lock'],
      signal: SettingsStore.instance.sortFolders,
    ),
    ToggleSetting(
      id: 'appearance.naturalSort',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.naturalSort,
      hint: () => t.preferences.appearance.naturalSortHint,
      searchTerms: const ['sort', 'natural', 'numeric', 'number', 'order'],
      signal: SettingsStore.instance.naturalSort,
    ),
    ChoiceSetting<String>(
      id: 'appearance.sortKey',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.sortKey,
      searchTerms: const ['sort', 'order', 'name', 'size', 'date'],
      signal: SettingsStore.instance.sortKey,
      choices: [
        SettingChoice(
          value: 'name',
          label: () => t.preferences.appearance.sortKeyName,
          icon: WaydirIconsRegular.textAa,
        ),
        SettingChoice(
          value: 'size',
          label: () => t.preferences.appearance.sortKeySize,
          icon: WaydirIconsRegular.ruler,
        ),
        SettingChoice(
          value: 'date',
          label: () => t.preferences.appearance.sortKeyDate,
          icon: WaydirIconsRegular.calendar,
        ),
      ],
    ),
    ToggleSetting(
      id: 'appearance.sortAscending',
      category: SettingsCategory.appearance,
      label: () => t.preferences.appearance.sortAscending,
      hint: () => t.preferences.appearance.sortDirection,
      searchTerms: const ['sort', 'ascending', 'descending', 'order'],
      signal: SettingsStore.instance.sortAscending,
    ),
    ToggleSetting(
      id: 'quickLook.useSystemFont',
      category: SettingsCategory.quickLook,
      label: () => t.preferences.quickLook.useSystemFont,
      hint: () => t.preferences.quickLook.useSystemFontHint,
      searchTerms: const [
        'quick look',
        'editor',
        'font',
        'system',
        'monospace',
      ],
      signal: SettingsStore.instance.quickLookUseSystemFont,
    ),
    ChoiceSetting<String>(
      id: 'quickLook.fontFamily',
      category: SettingsCategory.quickLook,
      label: () => t.preferences.quickLook.fontFamily,
      hint: () => t.preferences.quickLook.fontFamilyHint,
      searchTerms: const [
        'quick look',
        'editor',
        'font',
        'family',
        'monospace',
      ],
      signal: SettingsStore.instance.quickLookFontFamily,
      choices: _fontChoices(const ['monospace']),
    ),
    ChoiceSetting<int>(
      id: 'quickLook.fontSize',
      category: SettingsCategory.quickLook,
      label: () => t.preferences.quickLook.fontSize,
      hint: () => t.preferences.quickLook.fontSizeHint,
      searchTerms: const ['quick look', 'editor', 'font', 'size'],
      signal: SettingsStore.instance.quickLookFontSize,
      choices: [
        for (final value in SettingsStore.terminalFontSizes)
          SettingChoice(
            value: value,
            label: () => '${value}px',
            icon: WaydirIconsRegular.textAa,
          ),
      ],
    ),
    ChoiceSetting<double>(
      id: 'quickLook.lineHeight',
      category: SettingsCategory.quickLook,
      label: () => t.preferences.quickLook.lineHeight,
      hint: () => t.preferences.quickLook.lineHeightHint,
      searchTerms: const [
        'quick look',
        'editor',
        'line',
        'height',
        'spacing',
        'leading',
      ],
      signal: SettingsStore.instance.quickLookLineHeight,
      choices: [
        for (final value in const [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.8, 2.0])
          SettingChoice(
            value: value,
            label: () => value.toStringAsFixed(1),
            icon: WaydirIconsRegular.rows,
          ),
      ],
    ),
    ToggleSetting(
      id: 'quickLook.showLineNumbers',
      category: SettingsCategory.quickLook,
      label: () => t.preferences.quickLook.showLineNumbers,
      hint: () => t.preferences.quickLook.showLineNumbersHint,
      searchTerms: const ['quick look', 'editor', 'line numbers', 'gutter'],
      signal: SettingsStore.instance.quickLookShowLineNumbers,
    ),
    ToggleSetting(
      id: 'quickLook.relativeLineNumbers',
      category: SettingsCategory.quickLook,
      label: () => t.preferences.quickLook.relativeLineNumbers,
      hint: () => t.preferences.quickLook.relativeLineNumbersHint,
      searchTerms: const [
        'quick look',
        'editor',
        'line numbers',
        'relative',
        'vim',
      ],
      signal: SettingsStore.instance.quickLookRelativeLineNumbers,
    ),
    ToggleSetting(
      id: 'quickLook.showStatistics',
      category: SettingsCategory.quickLook,
      label: () => t.preferences.quickLook.showStatistics,
      hint: () => t.preferences.quickLook.showStatisticsHint,
      searchTerms: const [
        'quick look',
        'statistics',
        'breakdown',
        'size',
        'type',
      ],
      signal: SettingsStore.instance.quickLookShowStatistics,
    ),
    ToggleSetting(
      id: 'quickLook.wrapLines',
      category: SettingsCategory.quickLook,
      label: () => t.preferences.quickLook.wrapLines,
      hint: () => t.preferences.quickLook.wrapLinesHint,
      searchTerms: const ['quick look', 'editor', 'wrap', 'line wrap'],
      signal: SettingsStore.instance.quickLookWrapLines,
    ),
    ToggleSetting(
      id: 'quickLook.vimMode',
      category: SettingsCategory.quickLook,
      label: () => t.preferences.quickLook.vimMode,
      hint: () => t.preferences.quickLook.vimModeHint,
      searchTerms: const ['quick look', 'editor', 'vim', 'modal', 'keys'],
      signal: SettingsStore.instance.quickLookVimMode,
    ),
  ];

  List<AppSetting<dynamic>> byCategory(SettingsCategory category) {
    return all.where((setting) => setting.category == category).toList();
  }

  AppSetting<dynamic> byId(String id) {
    return all.firstWhere((setting) => setting.id == id);
  }

  void refreshTerminalFontChoices(List<String> families) {
    final setting = byId('terminal.fontFamily') as ChoiceSetting<String>;
    final current = setting.value;
    final names = [
      ...families,
      if (current.isNotEmpty && !families.contains(current)) current,
    ];
    setting.choices = _fontChoices(names);
  }

  void refreshQuickLookFontChoices(List<String> families) {
    final setting = byId('quickLook.fontFamily') as ChoiceSetting<String>;
    final current = setting.value;
    final names = [
      ...families,
      if (current.isNotEmpty && !families.contains(current)) current,
    ];
    setting.choices = _fontChoices(names);
  }

  Future<void> refreshExternalTerminalChoices() async {
    final terminals = await TerminalService.availableTerminals();
    final setting = byId('terminal.external') as ChoiceSetting<String>;
    setting.choices = _externalTerminalChoices(terminals);
  }

  void refreshShellChoices() {
    final setting = byId('terminal.shell') as ChoiceSetting<String>;
    final detected = ShellDetector.detect();
    final current = setting.value;
    final extra =
        current.isNotEmpty &&
            current != 'system' &&
            !detected.any((s) => s.path == current)
        ? current
        : null;
    setting.choices = _shellChoices(detected, extra: extra);
  }

  void refreshThemeChoices() {
    final setting = byId('appearance.theme') as ChoiceSetting<String>;
    setting.choices = [
      for (final theme in AppThemeRegistry.instance.themes)
        SettingChoice(
          value: theme.id,
          label: () => _themeLabel(theme),
          icon: _themeIcon(theme),
        ),
    ];
  }
}

List<SettingChoice<String>> _externalTerminalChoices(
  List<ExternalTerminal> terminals,
) {
  return [
    SettingChoice(
      value: 'builtin',
      label: () => t.preferences.general.terminalBuiltin,
      icon: WaydirIconsRegular.terminal,
    ),
    SettingChoice(
      value: 'auto',
      label: () => t.preferences.general.terminalAuto,
      icon: WaydirIconsRegular.magicWand,
    ),
    for (final term in terminals)
      SettingChoice(
        value: term.id,
        label: () => term.displayName,
        icon: WaydirIconsRegular.appWindow,
      ),
    SettingChoice(
      value: 'custom',
      label: () => t.preferences.general.terminalCustom,
      icon: WaydirIconsRegular.code,
    ),
  ];
}

List<SettingChoice<String>> _shellChoices(
  List<ShellOption> shells, {
  String? extra,
}) {
  return [
    SettingChoice(
      value: 'system',
      label: () => t.preferences.terminal.shellSystem,
      icon: WaydirIconsRegular.magicWand,
    ),
    for (final shell in shells)
      SettingChoice(
        value: shell.path,
        label: () => shell.label,
        icon: WaydirIconsRegular.terminal,
      ),
    if (extra != null)
      SettingChoice(
        value: extra,
        label: () => extra,
        icon: WaydirIconsRegular.terminal,
      ),
  ];
}

List<SettingChoice<String>> _fontChoices(List<String> families) {
  return [
    for (final family in families)
      SettingChoice(
        value: family,
        label: () => family,
        icon: WaydirIconsRegular.textAa,
      ),
  ];
}

List<SettingChoice<int>> _spacingChoices(IconData icon) {
  return [
    for (final value in const [0, 2, 4, 6, 8, 10, 12, 16])
      SettingChoice(value: value, label: () => '${value}px', icon: icon),
  ];
}

String _themeLabel(AppThemeDefinition theme) => switch (theme.id) {
  'dark' => t.preferences.appearance.themeDark,
  'light' => t.preferences.appearance.themeLight,
  'nord' => t.preferences.appearance.themeNord,
  _ => theme.name,
};

IconData _themeIcon(AppThemeDefinition theme) {
  if (theme.id == 'light') return WaydirIconsRegular.sun;
  if (theme.id == 'dark') return WaydirIconsRegular.moon;

  return WaydirIconsRegular.palette;
}
