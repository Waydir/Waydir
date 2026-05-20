import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:waydir/ui/theme/app_theme.dart';
import 'package:waydir/ui/theme/app_theme_registry.dart';
import 'package:waydir/features/files/file_icons.dart';

void main() {
  group('AppColors', () {
    test('fileIconColor returns correct colors for known extensions', () {
      expect(fileIconColor('dart'), const Color(0xFF5CA8FF));
      expect(fileIconColor('py'), const Color(0xFF5CA8FF));
      expect(fileIconColor('pdf'), const Color(0xFFCF6679));
      expect(fileIconColor('zip'), const Color(0xFFFAB387));
      expect(fileIconColor('mp3'), const Color(0xFFCBA6F7));
      expect(fileIconColor('mp4'), const Color(0xFFF5C2E7));
      expect(fileIconColor('png'), const Color(0xFFA6E3A1));
      expect(fileIconColor('md'), const Color(0xFF7CBCFF));
      expect(fileIconColor('txt'), const Color(0xFF9CA3AF));
    });

    test('fileIconColor returns default for unknown extension', () {
      expect(fileIconColor('xyz'), const Color(0xFF6B6B6B));
      expect(fileIconColor(''), const Color(0xFF6B6B6B));
    });

    test('fileIconColor handles grouped extensions', () {
      expect(fileIconColor('js'), fileIconColor('ts'));
      expect(fileIconColor('jpg'), fileIconColor('png'));
      expect(fileIconColor('wav'), fileIconColor('mp3'));
      expect(fileIconColor('avi'), fileIconColor('mp4'));
      expect(fileIconColor('tar'), fileIconColor('zip'));
    });

    test('fileIcon returns WaydirIconsRegular.file for unknown extension', () {
      expect(fileIcon('xyz'), WaydirIconsRegular.file);
      expect(fileIcon(''), WaydirIconsRegular.file);
    });

    test('fileIcon returns correct icon for code files', () {
      expect(fileIcon('dart'), WaydirIconsRegular.fileCode);
      expect(fileIcon('py'), WaydirIconsRegular.fileCode);
      expect(fileIcon('js'), WaydirIconsRegular.fileJs);
      expect(fileIcon('ts'), WaydirIconsRegular.fileTs);
      expect(fileIcon('html'), WaydirIconsRegular.fileHtml);
      expect(fileIcon('css'), WaydirIconsRegular.fileCss);
      expect(fileIcon('json'), WaydirIconsRegular.fileCode);
    });

    test('fileIcon returns correct icon for media files', () {
      expect(fileIcon('png'), WaydirIconsRegular.fileImage);
      expect(fileIcon('pdf'), WaydirIconsRegular.filePdf);
      expect(fileIcon('mp3'), WaydirIconsRegular.fileAudio);
      expect(fileIcon('mp4'), WaydirIconsRegular.fileVideo);
      expect(fileIcon('zip'), WaydirIconsRegular.fileZip);
      expect(fileIcon('md'), WaydirIconsRegular.fileMd);
      expect(fileIcon('txt'), WaydirIconsRegular.fileTxt);
    });
  });

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
}
