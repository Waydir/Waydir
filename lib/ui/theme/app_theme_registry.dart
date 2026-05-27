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
  ),
);

const builtInThemes = [darkTheme, lightTheme, nordTheme];
