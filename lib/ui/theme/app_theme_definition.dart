import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';

@immutable
class TerminalColors {
  final Color black;
  final Color red;
  final Color green;
  final Color yellow;
  final Color blue;
  final Color magenta;
  final Color cyan;
  final Color white;
  final Color brightBlack;
  final Color brightRed;
  final Color brightGreen;
  final Color brightYellow;
  final Color brightBlue;
  final Color brightMagenta;
  final Color brightCyan;
  final Color brightWhite;

  const TerminalColors({
    required this.black,
    required this.red,
    required this.green,
    required this.yellow,
    required this.blue,
    required this.magenta,
    required this.cyan,
    required this.white,
    required this.brightBlack,
    required this.brightRed,
    required this.brightGreen,
    required this.brightYellow,
    required this.brightBlue,
    required this.brightMagenta,
    required this.brightCyan,
    required this.brightWhite,
  });

  static const standard = TerminalColors(
    black: Color(0xFF000000),
    red: Color(0xFFCD3131),
    green: Color(0xFF0DBC79),
    yellow: Color(0xFFE5E510),
    blue: Color(0xFF2472C8),
    magenta: Color(0xFFBC3FBC),
    cyan: Color(0xFF11A8CD),
    white: Color(0xFFE5E5E5),
    brightBlack: Color(0xFF666666),
    brightRed: Color(0xFFF14C4C),
    brightGreen: Color(0xFF23D18B),
    brightYellow: Color(0xFFF5F543),
    brightBlue: Color(0xFF3B8EEA),
    brightMagenta: Color(0xFFD670D6),
    brightCyan: Color(0xFF29B8DB),
    brightWhite: Color(0xFFFFFFFF),
  );

  factory TerminalColors.fromJson(Map<String, dynamic> json) {
    Color read(String key, Color fallback) {
      final value = json[key];
      if (value is! String) return fallback;
      try {
        return parseThemeColor(value, key);
      } catch (e) {
        return fallback;
      }
    }

    const d = standard;
    return TerminalColors(
      black: read('black', d.black),
      red: read('red', d.red),
      green: read('green', d.green),
      yellow: read('yellow', d.yellow),
      blue: read('blue', d.blue),
      magenta: read('magenta', d.magenta),
      cyan: read('cyan', d.cyan),
      white: read('white', d.white),
      brightBlack: read('brightBlack', d.brightBlack),
      brightRed: read('brightRed', d.brightRed),
      brightGreen: read('brightGreen', d.brightGreen),
      brightYellow: read('brightYellow', d.brightYellow),
      brightBlue: read('brightBlue', d.brightBlue),
      brightMagenta: read('brightMagenta', d.brightMagenta),
      brightCyan: read('brightCyan', d.brightCyan),
      brightWhite: read('brightWhite', d.brightWhite),
    );
  }

  Map<String, String> toJson() => {
    'black': _hex(black),
    'red': _hex(red),
    'green': _hex(green),
    'yellow': _hex(yellow),
    'blue': _hex(blue),
    'magenta': _hex(magenta),
    'cyan': _hex(cyan),
    'white': _hex(white),
    'brightBlack': _hex(brightBlack),
    'brightRed': _hex(brightRed),
    'brightGreen': _hex(brightGreen),
    'brightYellow': _hex(brightYellow),
    'brightBlue': _hex(brightBlue),
    'brightMagenta': _hex(brightMagenta),
    'brightCyan': _hex(brightCyan),
    'brightWhite': _hex(brightWhite),
  };
}

@immutable
class AppThemePalette {
  final Color bg;
  final Color bgSurface;
  final Color bgSidebar;
  final Color bgToolbar;
  final Color bgStatus;
  final Color bgHover;
  final Color bgSelected;
  final Color bgSelectedMuted;
  final Color bgInput;
  final Color bgDivider;
  final Color borderColor;
  final Color accent;
  final Color accentHover;
  final Color fg;
  final Color fgMuted;
  final Color fgSubtle;
  final Color fgAccent;
  final Color danger;
  final Color success;
  final Color warning;
  final Color neutral;
  final Color bgHoverStrong;
  final Color windowCloseHover;
  final Color windowClosePressed;
  final Color shadowSubtle;
  final Color fileJs;
  final Color fileHtml;
  final Color fileCss;
  final Color fileArchive;
  final Color fileAudio;
  final Color fileVideo;
  final Color fileDefault;
  final TerminalColors terminal;

  const AppThemePalette({
    required this.bg,
    required this.bgSurface,
    required this.bgSidebar,
    required this.bgToolbar,
    required this.bgStatus,
    required this.bgHover,
    required this.bgSelected,
    required this.bgSelectedMuted,
    required this.bgInput,
    required this.bgDivider,
    required this.borderColor,
    required this.accent,
    required this.accentHover,
    required this.fg,
    required this.fgMuted,
    required this.fgSubtle,
    required this.fgAccent,
    required this.danger,
    required this.success,
    required this.warning,
    required this.neutral,
    required this.bgHoverStrong,
    required this.windowCloseHover,
    required this.windowClosePressed,
    required this.shadowSubtle,
    required this.fileJs,
    required this.fileHtml,
    required this.fileCss,
    required this.fileArchive,
    required this.fileAudio,
    required this.fileVideo,
    required this.fileDefault,
    this.terminal = TerminalColors.standard,
  });

  factory AppThemePalette.fromJson(Map<String, dynamic> json) {
    Color read(String key) {
      final value = json[key];
      if (value is! String) {
        throw FormatException(t.preferences.appearance.missingColor(key: key));
      }
      return parseThemeColor(value, key);
    }

    return AppThemePalette(
      bg: read('bg'),
      bgSurface: read('bgSurface'),
      bgSidebar: read('bgSidebar'),
      bgToolbar: read('bgToolbar'),
      bgStatus: read('bgStatus'),
      bgHover: read('bgHover'),
      bgSelected: read('bgSelected'),
      bgSelectedMuted: read('bgSelectedMuted'),
      bgInput: read('bgInput'),
      bgDivider: read('bgDivider'),
      borderColor: read('borderColor'),
      accent: read('accent'),
      accentHover: read('accentHover'),
      fg: read('fg'),
      fgMuted: read('fgMuted'),
      fgSubtle: read('fgSubtle'),
      fgAccent: read('fgAccent'),
      danger: read('danger'),
      success: read('success'),
      warning: read('warning'),
      neutral: read('neutral'),
      bgHoverStrong: read('bgHoverStrong'),
      windowCloseHover: read('windowCloseHover'),
      windowClosePressed: read('windowClosePressed'),
      shadowSubtle: read('shadowSubtle'),
      fileJs: read('fileJs'),
      fileHtml: read('fileHtml'),
      fileCss: read('fileCss'),
      fileArchive: read('fileArchive'),
      fileAudio: read('fileAudio'),
      fileVideo: read('fileVideo'),
      fileDefault: read('fileDefault'),
      terminal: json['terminal'] is Map<String, dynamic>
          ? TerminalColors.fromJson(json['terminal'] as Map<String, dynamic>)
          : TerminalColors.standard,
    );
  }

  Map<String, dynamic> toJson() => {
    'bg': _hex(bg),
    'bgSurface': _hex(bgSurface),
    'bgSidebar': _hex(bgSidebar),
    'bgToolbar': _hex(bgToolbar),
    'bgStatus': _hex(bgStatus),
    'bgHover': _hex(bgHover),
    'bgSelected': _hex(bgSelected),
    'bgSelectedMuted': _hex(bgSelectedMuted),
    'bgInput': _hex(bgInput),
    'bgDivider': _hex(bgDivider),
    'borderColor': _hex(borderColor),
    'accent': _hex(accent),
    'accentHover': _hex(accentHover),
    'fg': _hex(fg),
    'fgMuted': _hex(fgMuted),
    'fgSubtle': _hex(fgSubtle),
    'fgAccent': _hex(fgAccent),
    'danger': _hex(danger),
    'success': _hex(success),
    'warning': _hex(warning),
    'neutral': _hex(neutral),
    'bgHoverStrong': _hex(bgHoverStrong),
    'windowCloseHover': _hex(windowCloseHover),
    'windowClosePressed': _hex(windowClosePressed),
    'shadowSubtle': _hex(shadowSubtle),
    'fileJs': _hex(fileJs),
    'fileHtml': _hex(fileHtml),
    'fileCss': _hex(fileCss),
    'fileArchive': _hex(fileArchive),
    'fileAudio': _hex(fileAudio),
    'fileVideo': _hex(fileVideo),
    'fileDefault': _hex(fileDefault),
    'terminal': terminal.toJson(),
  };
}

@immutable
class AppThemeDefinition {
  final String id;
  final String name;
  final Brightness brightness;
  final AppThemePalette palette;
  final bool builtIn;

  const AppThemeDefinition({
    required this.id,
    required this.name,
    required this.brightness,
    required this.palette,
    this.builtIn = false,
  });

  factory AppThemeDefinition.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final brightness = json['brightness'];
    final palette = json['palette'];
    if (id is! String || id.trim().isEmpty) {
      throw FormatException(t.preferences.appearance.missingThemeId);
    }
    if (name is! String || name.trim().isEmpty) {
      throw FormatException(t.preferences.appearance.missingThemeName);
    }
    if (brightness is! String) {
      throw FormatException(t.preferences.appearance.missingThemeBrightness);
    }
    if (palette is! Map<String, dynamic>) {
      throw FormatException(t.preferences.appearance.missingThemePalette);
    }
    return AppThemeDefinition(
      id: id.trim(),
      name: name.trim(),
      brightness: _parseBrightness(brightness),
      palette: AppThemePalette.fromJson(palette),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brightness': brightness == Brightness.dark ? 'dark' : 'light',
    'palette': palette.toJson(),
  };
}

Color parseThemeColor(String value, String key) {
  var hex = value.trim();
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  } else if (hex.startsWith('0x') || hex.startsWith('0X')) {
    hex = hex.substring(2);
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8 || !RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hex)) {
    throw FormatException(t.preferences.appearance.invalidColor(key: key));
  }
  return Color(int.parse(hex, radix: 16));
}

Brightness _parseBrightness(String value) {
  return switch (value.trim().toLowerCase()) {
    'dark' => Brightness.dark,
    'light' => Brightness.light,
    _ => throw FormatException(t.preferences.appearance.invalidThemeBrightness),
  };
}

String _hex(Color color) {
  final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#${(a + r + g + b).toUpperCase()}';
}
