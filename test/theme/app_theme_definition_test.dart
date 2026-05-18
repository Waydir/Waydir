import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/ui/theme/app_theme_definition.dart';
import 'package:waydir/ui/theme/app_theme_registry.dart';

void main() {
  group('AppThemeDefinition', () {
    test('parses a complete json theme', () {
      final json = darkTheme.toJson()
        ..['id'] = 'custom'
        ..['name'] = 'Custom';

      final theme = AppThemeDefinition.fromJson(json);

      expect(theme.id, 'custom');
      expect(theme.name, 'Custom');
      expect(theme.brightness, Brightness.dark);
      expect(theme.palette.bg, darkTheme.palette.bg);
      expect(theme.palette.accent, darkTheme.palette.accent);
    });

    test('parses rgb and argb hex colors', () {
      expect(parseThemeColor('#181818', 'bg'), const Color(0xFF181818));
      expect(parseThemeColor('#33181818', 'bg'), const Color(0x33181818));
      expect(parseThemeColor('0xFF181818', 'bg'), const Color(0xFF181818));
    });

    test('rejects missing required color fields', () {
      final json = darkTheme.toJson()
        ..['id'] = 'broken'
        ..['name'] = 'Broken';
      final palette = Map<String, dynamic>.from(json['palette'] as Map);
      palette.remove('accent');
      json['palette'] = palette;

      expect(
        () => AppThemeDefinition.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid colors', () {
      expect(
        () => parseThemeColor('#XYZ', 'accent'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
