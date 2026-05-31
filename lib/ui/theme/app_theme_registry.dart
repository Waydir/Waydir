import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/logging/app_logger.dart';
import '../../core/platform/app_dirs.dart';
import '../../i18n/strings.g.dart';
import 'app_theme_definition.dart';

class AppThemeRegistry {
  AppThemeRegistry();

  static final AppThemeRegistry instance = AppThemeRegistry();
  static const defaultThemeId = 'dark';

  final _themes = <AppThemeDefinition>[...builtInThemes];
  final _warnedUnknownIds = <String>{};
  String? _cachedThemesDir;

  List<AppThemeDefinition> get themes => List.unmodifiable(_themes);

  AppThemeDefinition get defaultTheme => _themes.firstWhere(
    (theme) => theme.id == defaultThemeId,
    orElse: () => builtInThemes.first,
  );

  Future<void> load({String? customThemesPath}) async {
    _themes
      ..clear()
      ..addAll(builtInThemes);
    final dir = customThemesPath ?? await AppDirs.themes();
    _cachedThemesDir = dir;
    await _loadCustomThemes(dir);
  }

  void loadSync() {
    final dirPath = _cachedThemesDir;
    if (dirPath == null) return;
    _themes
      ..clear()
      ..addAll(builtInThemes);
    _loadCustomThemesSync(dirPath);
  }

  AppThemeDefinition resolve(String id) {
    for (final theme in _themes) {
      if (theme.id == id) return theme;
    }
    if (id.isNotEmpty && id != defaultThemeId && _warnedUnknownIds.add(id)) {
      log.warn(
        'theme',
        t.preferences.appearance.unknownThemeUsingDefault(
          id: id,
          theme: t.preferences.appearance.themeDark,
        ),
      );
    }
    return defaultTheme;
  }

  Future<void> _loadCustomThemes(String dirPath) async {
    final dir = Directory(dirPath);
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        return;
      }
      await for (final entity in dir.list()) {
        if (entity is! File ||
            p.extension(entity.path).toLowerCase() != '.json') {
          continue;
        }
        await _loadThemeFile(entity);
      }
    } catch (error, stack) {
      log.warn(
        'theme',
        t.preferences.appearance.couldNotLoadCustomThemes,
        error: error,
        stack: stack,
      );
    }
  }

  void _loadCustomThemesSync(String dirPath) {
    final dir = Directory(dirPath);
    try {
      if (!dir.existsSync()) return;
      for (final entity in dir.listSync()) {
        if (entity is! File ||
            p.extension(entity.path).toLowerCase() != '.json') {
          continue;
        }
        _loadThemeFileSync(entity);
      }
    } catch (error, stack) {
      log.warn(
        'theme',
        t.preferences.appearance.couldNotLoadCustomThemes,
        error: error,
        stack: stack,
      );
    }
  }

  Future<void> _loadThemeFile(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw FormatException(
          t.preferences.appearance.themeFileMustContainJsonObject,
        );
      }
      final theme = AppThemeDefinition.fromJson(decoded);
      if (_themes.any((existing) => existing.id == theme.id)) {
        log.warn(
          'theme',
          t.preferences.appearance.skippingDuplicateTheme(
            id: theme.id,
            path: file.path,
          ),
        );
        return;
      }
      _themes.add(theme);
    } catch (error, stack) {
      log.warn(
        'theme',
        t.preferences.appearance.skippingThemeFile(path: file.path),
        error: error,
        stack: stack,
      );
    }
  }

  void _loadThemeFileSync(File file) {
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, dynamic>) {
        throw FormatException(
          t.preferences.appearance.themeFileMustContainJsonObject,
        );
      }
      final theme = AppThemeDefinition.fromJson(decoded);
      if (_themes.any((existing) => existing.id == theme.id)) {
        return;
      }
      _themes.add(theme);
    } catch (_) {}
  }
}

const darkTheme = AppThemeDefinition(
  id: 'dark',
  name: 'Dark',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF181818),
    bgSurface: Color(0xFF1E1E1E),
    bgSidebar: Color(0xFF121212),
    bgToolbar: Color(0xFF121212),
    bgStatus: Color(0xFF121212),
    bgHover: Color(0xFF2A2D31),
    bgSelected: Color(0xFF2A2D31),
    bgSelectedMuted: Color(0xFF2A2D31),
    bgInput: Color(0xFF2A2D31),
    bgDivider: Color(0xFF3A3A3A),
    borderColor: Color(0xFF3A3A3A),
    accent: Color(0xFF5CA8FF),
    accentHover: Color(0xFF7CBCFF),
    fg: Color(0xFFE4E4E4),
    fgMuted: Color(0xFF9CA3AF),
    fgSubtle: Color(0xFF4A4A4A),
    fgAccent: Color(0xFF7CBCFF),
    danger: Color(0xFFCF6679),
    success: Color(0xFFA6E3A1),
    warning: Color(0xFFF9E2AF),
    neutral: Color(0xFF7B8794),
    bgHoverStrong: Color(0xFF333639),
    windowCloseHover: Color(0xFFE81123),
    windowClosePressed: Color(0xFFBF0F1F),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFF7DF1E),
    fileHtml: Color(0xFFE34F26),
    fileCss: Color(0xFF1572B6),
    fileArchive: Color(0xFFFAB387),
    fileAudio: Color(0xFFCBA6F7),
    fileVideo: Color(0xFFF5C2E7),
    fileDefault: Color(0xFF6B6B6B),
  ),
);

const lightTheme = AppThemeDefinition(
  id: 'light',
  name: 'Light',
  brightness: Brightness.light,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFFF4F5F7),
    bgSurface: Color(0xFFFFFFFF),
    bgSidebar: Color(0xFFEDEEF0),
    bgToolbar: Color(0xFFEDEEF0),
    bgStatus: Color(0xFFEDEEF0),
    bgHover: Color(0xFFE4E7EB),
    bgSelected: Color(0xFFD6E4FB),
    bgSelectedMuted: Color(0xFFE4E7EB),
    bgInput: Color(0xFFFFFFFF),
    bgDivider: Color(0xFFD7DAE0),
    borderColor: Color(0xFFD7DAE0),
    accent: Color(0xFF2F7FE5),
    accentHover: Color(0xFF1D63C9),
    fg: Color(0xFF15171A),
    fgMuted: Color(0xFF4A515C),
    fgSubtle: Color(0xFF878D98),
    fgAccent: Color(0xFF1D63C9),
    danger: Color(0xFFC8323C),
    success: Color(0xFF1F7A33),
    warning: Color(0xFF9A6B00),
    neutral: Color(0xFF566270),
    bgHoverStrong: Color(0xFFD7DAE0),
    windowCloseHover: Color(0xFFE81123),
    windowClosePressed: Color(0xFFBF0F1F),
    shadowSubtle: Color(0x1A000000),
    fileJs: Color(0xFFC9A800),
    fileHtml: Color(0xFFE34F26),
    fileCss: Color(0xFF1572B6),
    fileArchive: Color(0xFFC9762B),
    fileAudio: Color(0xFF8A5CF0),
    fileVideo: Color(0xFFC2418A),
    fileDefault: Color(0xFF9AA0A6),
    terminal: TerminalColors(
      black: Color(0xFF000000),
      red: Color(0xFFCD3131),
      green: Color(0xFF00BC00),
      yellow: Color(0xFF949800),
      blue: Color(0xFF0451A5),
      magenta: Color(0xFFBC05BC),
      cyan: Color(0xFF0598BC),
      white: Color(0xFF555555),
      brightBlack: Color(0xFF686868),
      brightRed: Color(0xFFCD3131),
      brightGreen: Color(0xFF14CE14),
      brightYellow: Color(0xFFB5BA00),
      brightBlue: Color(0xFF0451A5),
      brightMagenta: Color(0xFFBC05BC),
      brightCyan: Color(0xFF0598BC),
      brightWhite: Color(0xFFA5A5A5),
    ),
  ),
);

const nordTheme = AppThemeDefinition(
  id: 'nord',
  name: 'Nord',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF2E3440),
    bgSurface: Color(0xFF3B4252),
    bgSidebar: Color(0xFF242933),
    bgToolbar: Color(0xFF242933),
    bgStatus: Color(0xFF242933),
    bgHover: Color(0xFF434C5E),
    bgSelected: Color(0xFF4C566A),
    bgSelectedMuted: Color(0xFF434C5E),
    bgInput: Color(0xFF3B4252),
    bgDivider: Color(0xFF4C566A),
    borderColor: Color(0xFF4C566A),
    accent: Color(0xFF88C0D0),
    accentHover: Color(0xFF8FBCBB),
    fg: Color(0xFFECEFF4),
    fgMuted: Color(0xFFD8DEE9),
    fgSubtle: Color(0xFF81A1C1),
    fgAccent: Color(0xFF8FBCBB),
    danger: Color(0xFFBF616A),
    success: Color(0xFFA3BE8C),
    warning: Color(0xFFEBCB8B),
    neutral: Color(0xFF81A1C1),
    bgHoverStrong: Color(0xFF4C566A),
    windowCloseHover: Color(0xFFBF616A),
    windowClosePressed: Color(0xFFA84F58),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFEBCB8B),
    fileHtml: Color(0xFFD08770),
    fileCss: Color(0xFF5E81AC),
    fileArchive: Color(0xFFD08770),
    fileAudio: Color(0xFFB48EAD),
    fileVideo: Color(0xFFB48EAD),
    fileDefault: Color(0xFF81A1C1),
    terminal: TerminalColors(
      black: Color(0xFF3B4252),
      red: Color(0xFFBF616A),
      green: Color(0xFFA3BE8C),
      yellow: Color(0xFFEBCB8B),
      blue: Color(0xFF81A1C1),
      magenta: Color(0xFFB48EAD),
      cyan: Color(0xFF88C0D0),
      white: Color(0xFFE5E9F0),
      brightBlack: Color(0xFF4C566A),
      brightRed: Color(0xFFBF616A),
      brightGreen: Color(0xFFA3BE8C),
      brightYellow: Color(0xFFEBCB8B),
      brightBlue: Color(0xFF5E81AC),
      brightMagenta: Color(0xFFB48EAD),
      brightCyan: Color(0xFF8FBCBB),
      brightWhite: Color(0xFFECEFF4),
    ),
  ),
);

const tokyoNightTheme = AppThemeDefinition(
  id: 'tokyo-night',
  name: 'Tokyo Night',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF1A1B26),
    bgSurface: Color(0xFF1F2335),
    bgSidebar: Color(0xFF16161E),
    bgToolbar: Color(0xFF16161E),
    bgStatus: Color(0xFF16161E),
    bgHover: Color(0xFF292E42),
    bgSelected: Color(0xFF283457),
    bgSelectedMuted: Color(0xFF292E42),
    bgInput: Color(0xFF1F2335),
    bgDivider: Color(0xFF3B4261),
    borderColor: Color(0xFF3B4261),
    accent: Color(0xFF7AA2F7),
    accentHover: Color(0xFF89DDFF),
    fg: Color(0xFFC0CAF5),
    fgMuted: Color(0xFFA9B1D6),
    fgSubtle: Color(0xFF565F89),
    fgAccent: Color(0xFF89DDFF),
    danger: Color(0xFFF7768E),
    success: Color(0xFF9ECE6A),
    warning: Color(0xFFE0AF68),
    neutral: Color(0xFF737AA2),
    bgHoverStrong: Color(0xFF343A55),
    windowCloseHover: Color(0xFFF7768E),
    windowClosePressed: Color(0xFFDB4B4B),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFE0AF68),
    fileHtml: Color(0xFFFF9E64),
    fileCss: Color(0xFF7AA2F7),
    fileArchive: Color(0xFFFF9E64),
    fileAudio: Color(0xFFBB9AF7),
    fileVideo: Color(0xFF9D7CD8),
    fileDefault: Color(0xFF737AA2),
    terminal: TerminalColors(
      black: Color(0xFF15161E),
      red: Color(0xFFF7768E),
      green: Color(0xFF9ECE6A),
      yellow: Color(0xFFE0AF68),
      blue: Color(0xFF7AA2F7),
      magenta: Color(0xFFBB9AF7),
      cyan: Color(0xFF7DCFFF),
      white: Color(0xFFA9B1D6),
      brightBlack: Color(0xFF414868),
      brightRed: Color(0xFFF7768E),
      brightGreen: Color(0xFF9ECE6A),
      brightYellow: Color(0xFFE0AF68),
      brightBlue: Color(0xFF7AA2F7),
      brightMagenta: Color(0xFFBB9AF7),
      brightCyan: Color(0xFF7DCFFF),
      brightWhite: Color(0xFFC0CAF5),
    ),
  ),
);

const gruvboxDarkTheme = AppThemeDefinition(
  id: 'gruvbox-dark',
  name: 'Gruvbox Dark',
  brightness: Brightness.dark,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFF282828),
    bgSurface: Color(0xFF32302F),
    bgSidebar: Color(0xFF1D2021),
    bgToolbar: Color(0xFF1D2021),
    bgStatus: Color(0xFF1D2021),
    bgHover: Color(0xFF3C3836),
    bgSelected: Color(0xFF504945),
    bgSelectedMuted: Color(0xFF3C3836),
    bgInput: Color(0xFF32302F),
    bgDivider: Color(0xFF504945),
    borderColor: Color(0xFF504945),
    accent: Color(0xFF83A598),
    accentHover: Color(0xFF8EC07C),
    fg: Color(0xFFEBDBB2),
    fgMuted: Color(0xFFA89984),
    fgSubtle: Color(0xFF665C54),
    fgAccent: Color(0xFF8EC07C),
    danger: Color(0xFFFB4934),
    success: Color(0xFFB8BB26),
    warning: Color(0xFFFABD2F),
    neutral: Color(0xFF928374),
    bgHoverStrong: Color(0xFF504945),
    windowCloseHover: Color(0xFFFB4934),
    windowClosePressed: Color(0xFFCC241D),
    shadowSubtle: Color(0x33000000),
    fileJs: Color(0xFFFABD2F),
    fileHtml: Color(0xFFFE8019),
    fileCss: Color(0xFF83A598),
    fileArchive: Color(0xFFFE8019),
    fileAudio: Color(0xFFD3869B),
    fileVideo: Color(0xFFB16286),
    fileDefault: Color(0xFF928374),
    terminal: TerminalColors(
      black: Color(0xFF282828),
      red: Color(0xFFCC241D),
      green: Color(0xFF98971A),
      yellow: Color(0xFFD79921),
      blue: Color(0xFF458588),
      magenta: Color(0xFFB16286),
      cyan: Color(0xFF689D6A),
      white: Color(0xFFA89984),
      brightBlack: Color(0xFF928374),
      brightRed: Color(0xFFFB4934),
      brightGreen: Color(0xFFB8BB26),
      brightYellow: Color(0xFFFABD2F),
      brightBlue: Color(0xFF83A598),
      brightMagenta: Color(0xFFD3869B),
      brightCyan: Color(0xFF8EC07C),
      brightWhite: Color(0xFFEBDBB2),
    ),
  ),
);

const gruvboxLightTheme = AppThemeDefinition(
  id: 'gruvbox-light',
  name: 'Gruvbox Light',
  brightness: Brightness.light,
  builtIn: true,
  palette: AppThemePalette(
    bg: Color(0xFFFBF1C7),
    bgSurface: Color(0xFFF9F5D7),
    bgSidebar: Color(0xFFF2E5BC),
    bgToolbar: Color(0xFFF2E5BC),
    bgStatus: Color(0xFFF2E5BC),
    bgHover: Color(0xFFEBDBB2),
    bgSelected: Color(0xFFD5C4A1),
    bgSelectedMuted: Color(0xFFEBDBB2),
    bgInput: Color(0xFFF9F5D7),
    bgDivider: Color(0xFFD5C4A1),
    borderColor: Color(0xFFD5C4A1),
    accent: Color(0xFF076678),
    accentHover: Color(0xFF427B58),
    fg: Color(0xFF3C3836),
    fgMuted: Color(0xFF665C54),
    fgSubtle: Color(0xFFA89984),
    fgAccent: Color(0xFF427B58),
    danger: Color(0xFF9D0006),
    success: Color(0xFF79740E),
    warning: Color(0xFFB57614),
    neutral: Color(0xFF7C6F64),
    bgHoverStrong: Color(0xFFD5C4A1),
    windowCloseHover: Color(0xFFCC241D),
    windowClosePressed: Color(0xFF9D0006),
    shadowSubtle: Color(0x1A000000),
    fileJs: Color(0xFFB57614),
    fileHtml: Color(0xFFAF3A03),
    fileCss: Color(0xFF076678),
    fileArchive: Color(0xFFAF3A03),
    fileAudio: Color(0xFF8F3F71),
    fileVideo: Color(0xFFB16286),
    fileDefault: Color(0xFF928374),
    terminal: TerminalColors(
      black: Color(0xFFFBF1C7),
      red: Color(0xFFCC241D),
      green: Color(0xFF98971A),
      yellow: Color(0xFFD79921),
      blue: Color(0xFF458588),
      magenta: Color(0xFFB16286),
      cyan: Color(0xFF689D6A),
      white: Color(0xFF7C6F64),
      brightBlack: Color(0xFF928374),
      brightRed: Color(0xFF9D0006),
      brightGreen: Color(0xFF79740E),
      brightYellow: Color(0xFFB57614),
      brightBlue: Color(0xFF076678),
      brightMagenta: Color(0xFF8F3F71),
      brightCyan: Color(0xFF427B58),
      brightWhite: Color(0xFF3C3836),
    ),
  ),
);

const builtInThemes = [
  darkTheme,
  lightTheme,
  nordTheme,
  tokyoNightTheme,
  gruvboxDarkTheme,
  gruvboxLightTheme,
];
