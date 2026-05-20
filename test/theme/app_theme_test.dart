import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:waydir/ui/theme/app_theme.dart';
import 'package:waydir/ui/theme/app_theme_registry.dart';
import 'package:waydir/features/files/file_icons.dart';

void main() {
  group('AppTheme', () {
    test('build returns ThemeData with dark brightness', () {
      final theme = AppTheme.build();
      expect(theme.brightness, Brightness.dark);
    });

    test('build has NoSplash splashFactory', () {
      final theme = AppTheme.build();
      expect(theme.splashFactory, NoSplash.splashFactory);
    });

    test('build uses correct scaffold background', () {
      final theme = AppTheme.build();
      expect(theme.scaffoldBackgroundColor, AppColors.bg);
    });

    test('build uses light brightness for light theme', () {
      final theme = AppTheme.build(lightTheme);
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, const Color(0xFFF4F5F7));
    });

    test('build exposes nord theme colors', () {
      final theme = AppTheme.build(nordTheme);
      expect(theme.brightness, Brightness.dark);
      expect(AppColors.bg, const Color(0xFF2E3440));
      expect(AppColors.accent, const Color(0xFF88C0D0));
    });

    test('palette constants are consistent', () {
      AppTheme.build(darkTheme);
      expect(AppColors.accent, const Color(0xFF5CA8FF));
      expect(AppColors.bg, const Color(0xFF181818));
      expect(AppColors.bgSurface, const Color(0xFF1E1E1E));
      expect(AppColors.fg, const Color(0xFFE4E4E4));
      expect(AppColors.fgMuted, const Color(0xFF9CA3AF));
      expect(AppColors.bgHover, const Color(0xFF2A2D31));
      expect(AppColors.bgSelected, const Color(0xFF2A2D31));
    });
  });

  group('FileIcons', () {
    testWidgets('buildFileIcon returns SVG widget', (
      WidgetTester tester,
    ) async {
      final widget = buildFileIcon(
        name: 'test.dart',
        ext: 'dart',
        isFolder: false,
      );

      expect(widget, isNotNull);
    });
  });
}
