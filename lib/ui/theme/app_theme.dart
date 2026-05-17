import 'package:flutter/material.dart';
import 'app_text_styles.dart';

@immutable
class _Palette {
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

  const _Palette({
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
  });
}

const _dark = _Palette(
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
);

const _light = _Palette(
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
);

/// Active color palette. Switched at runtime via [AppColors.brightness];
/// all members are resolved through getters so a full widget rebuild picks
/// up the new palette.
class AppColors {
  AppColors._();

  static Brightness brightness = Brightness.dark;

  static _Palette get _p => brightness == Brightness.light ? _light : _dark;

  static Color get bg => _p.bg;
  static Color get bgSurface => _p.bgSurface;
  static Color get bgSidebar => _p.bgSidebar;
  static Color get bgToolbar => _p.bgToolbar;
  static Color get bgStatus => _p.bgStatus;
  static Color get bgHover => _p.bgHover;
  static Color get bgSelected => _p.bgSelected;
  static Color get bgSelectedMuted => _p.bgSelectedMuted;
  static Color get bgInput => _p.bgInput;
  static Color get bgDivider => _p.bgDivider;
  static Color get borderColor => _p.borderColor;

  static Color get accent => _p.accent;
  static Color get accentHover => _p.accentHover;

  static Color get fg => _p.fg;
  static Color get fgMuted => _p.fgMuted;
  static Color get fgSubtle => _p.fgSubtle;
  static Color get fgAccent => _p.fgAccent;

  static Color get danger => _p.danger;
  static Color get success => _p.success;
  static Color get warning => _p.warning;
  static Color get neutral => _p.neutral;
  static Color get bgHoverStrong => _p.bgHoverStrong;
  static Color get windowCloseHover => _p.windowCloseHover;
  static Color get windowClosePressed => _p.windowClosePressed;
  static Color get shadowSubtle => _p.shadowSubtle;

  static Color get fileCode => _p.accent;
  static Color get fileJs => _p.fileJs;
  static Color get fileHtml => _p.fileHtml;
  static Color get fileCss => _p.fileCss;
  static Color get fileImage => _p.success;
  static Color get fileArchive => _p.fileArchive;
  static Color get fileAudio => _p.fileAudio;
  static Color get fileVideo => _p.fileVideo;
  static Color get fileDefault => _p.fileDefault;

  static Color get folderColor => _p.accent;
}

class AppTheme {
  static const _systemFont = 'system-ui';

  static ThemeData build([Brightness brightness = Brightness.dark]) {
    AppColors.brightness = brightness;
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: AppColors.accent,
        onSecondary: isDark ? Colors.black : Colors.white,
        error: AppColors.danger,
        onError: isDark ? Colors.black : Colors.white,
        surface: AppColors.bgSurface,
        onSurface: AppColors.fg,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      hoverColor: AppColors.bgHover.withValues(alpha: 0.5),
      dividerColor: AppColors.bgDivider,
      iconTheme: IconThemeData(color: AppColors.fgMuted, size: 20),
      textTheme: (isDark ? Typography.whiteCupertino : Typography.blackCupertino)
          .copyWith(
            bodyLarge: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.fg,
              fontFamily: _systemFont,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: AppColors.fg,
              fontFamily: _systemFont,
            ),
            bodySmall: TextStyle(
              fontSize: 13,
              height: 1.3,
              color: AppColors.fgMuted,
              fontFamily: _systemFont,
            ),
            labelLarge: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.fg,
              fontFamily: _systemFont,
            ),
            labelSmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.fgMuted,
              fontFamily: _systemFont,
            ),
            titleMedium: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.fg,
              fontFamily: _systemFont,
            ),
          ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.fgSubtle),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(6),
        thumbVisibility: WidgetStateProperty.all(false),
      ),
      extensions: [AppTextStyles.forBrightness(brightness)],
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(
          fontSize: 13,
          color: AppColors.fg,
          fontFamily: _systemFont,
        ),
        waitDuration: const Duration(milliseconds: 600),
      ),
    );
  }
}
