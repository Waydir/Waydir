import 'package:flutter/material.dart';
import 'app_text_styles.dart';
import 'app_theme_definition.dart';
import 'app_theme_registry.dart';

class AppColors {
  AppColors._();

  static AppThemeDefinition activeTheme = darkTheme;

  static Brightness get brightness => activeTheme.brightness;

  static void setTheme(AppThemeDefinition theme) {
    activeTheme = theme;
  }

  static AppThemePalette get _p => activeTheme.palette;

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

  static Color get compareUnique => _p.success;
  static Color get compareNewer => _p.accent;
  static Color get compareOlder => _p.neutral;
  static Color get compareDiffer => _p.warning;

  static TerminalColors get terminal => _p.terminal;
}

class AppTheme {
  static const _systemFont = 'system-ui';

  static ThemeData build([AppThemeDefinition theme = darkTheme]) {
    AppColors.setTheme(theme);
    final brightness = theme.brightness;
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
      textTheme:
          (isDark ? Typography.whiteCupertino : Typography.blackCupertino)
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
        radius: Radius.zero,
        thickness: WidgetStateProperty.all(6),
        thumbVisibility: WidgetStateProperty.all(false),
      ),
      extensions: [AppTextStyles.forBrightness()],
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.zero,
        ),
        textStyle: TextStyle(
          fontSize: 13,
          color: AppColors.fg,
          fontFamily: _systemFont,
        ),
        waitDuration: const Duration(milliseconds: 600),
      ),
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      menuButtonTheme: const MenuButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      chipTheme: const ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
      elevatedButtonTheme: const ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
        ),
      ),
      checkboxTheme: const CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        borderRadius: BorderRadius.zero,
      ),
      sliderTheme: const SliderThemeData(
        overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      tabBarTheme: const TabBarThemeData(indicator: BoxDecoration()),
    );
  }
}
