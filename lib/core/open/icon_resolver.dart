import 'dart:io';

import 'package:path/path.dart' as p;

import '../logging/app_logger.dart';

/// Resolves a freedesktop `Icon=` value (a bare name like `firefox`, or an
/// absolute path) to a concrete icon file, following the icon theme spec
/// closely enough for an app picker: it honours the active GTK icon theme,
/// falls back through `hicolor`/`Adwaita`, prefers larger raster sizes and the
/// `apps` category, and also accepts SVG and legacy pixmaps.
///
/// Results are memoised for the process lifetime since the icon tree does not
/// change while the app is running.
class IconResolver {
  IconResolver._();
  static final IconResolver instance = IconResolver._();

  final Map<String, String?> _cache = {};
  List<String>? _baseDirs;
  List<String>? _themes;

  String? resolve(String? icon) {
    if (icon == null || icon.isEmpty) return null;
    if (p.isAbsolute(icon)) {
      return File(icon).existsSync() ? icon : null;
    }

    return _cache.putIfAbsent(icon, () => _search(icon));
  }

  List<String> get _bases => _baseDirs ??= _computeBaseDirs();

  List<String> get _themeNames => _themes ??= _computeThemes();

  List<String> _computeBaseDirs() {
    final home = Platform.environment['HOME'] ?? '';
    final dataHome = Platform.environment['XDG_DATA_HOME'];
    final dataDirs = Platform.environment['XDG_DATA_DIRS'];
    final dirs = <String>[
      p.join(home, '.icons'),
      p.join(
        (dataHome != null && dataHome.isNotEmpty)
            ? dataHome
            : p.join(home, '.local', 'share'),
        'icons',
      ),
      ...((dataDirs != null && dataDirs.isNotEmpty)
              ? dataDirs.split(':')
              : ['/usr/local/share', '/usr/share'])
          .map((d) => p.join(d, 'icons')),
      '/usr/share/pixmaps',
    ];

    return dirs.where((d) => Directory(d).existsSync()).toList();
  }

  List<String> _computeThemes() {
    final themes = <String>[];
    final envTheme = Platform.environment['GTK_ICON_THEME'];
    if (envTheme != null && envTheme.isNotEmpty) themes.add(envTheme);
    try {
      final r = Process.runSync('gsettings', [
        'get',
        'org.gnome.desktop.interface',
        'icon-theme',
      ]);
      if (r.exitCode == 0) {
        final t = (r.stdout as String).trim().replaceAll("'", '');
        if (t.isNotEmpty) themes.add(t);
      }
    } catch (e, st) {
      log.warn('open', 'icon theme lookup failed', error: e, stack: st);
    }
    for (final fallback in ['Adwaita', 'hicolor', 'gnome']) {
      if (!themes.contains(fallback)) themes.add(fallback);
    }

    return themes;
  }

  /// Largest first: app pickers look best with crisp icons; scalable (SVG)
  /// works at any size so it is tried early.
  static const _sizeDirs = [
    'scalable',
    '512x512',
    '256x256',
    '128x128',
    '96x96',
    '64x64',
    '48x48',
    '32x32',
    '24x24',
    '22x22',
    '16x16',
  ];
  static const _categories = ['apps', 'mimetypes', 'devices', ''];
  static const _exts = ['png', 'svg', 'xpm'];

  String? _search(String name) {
    for (final base in _bases) {
      for (final ext in _exts) {
        final flat = p.join(base, '$name.$ext');
        if (File(flat).existsSync()) return flat;
      }
      for (final theme in _themeNames) {
        final themeDir = p.join(base, theme);
        if (!Directory(themeDir).existsSync()) continue;
        for (final size in _sizeDirs) {
          for (final cat in _categories) {
            for (final ext in _exts) {
              final candidate = cat.isEmpty
                  ? p.join(themeDir, size, '$name.$ext')
                  : p.join(themeDir, size, cat, '$name.$ext');
              if (File(candidate).existsSync()) return candidate;
              final alt = cat.isEmpty
                  ? null
                  : p.join(themeDir, cat, size, '$name.$ext');
              if (alt != null && File(alt).existsSync()) return alt;
            }
          }
        }
      }
    }

    return null;
  }
}
