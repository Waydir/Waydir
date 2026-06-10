import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/logging/app_logger.dart';
import 'package:waydir/ui/theme/app_theme_registry.dart';

void main() {
  group('AppThemeRegistry', () {
    late Directory dir;

    final builtInIds = builtInThemes.map((theme) => theme.id).toList();

    setUp(() {
      dir = Directory.systemTemp.createTempSync('waydir_theme_registry_');
      log.clear();
    });

    tearDown(() {
      dir.deleteSync(recursive: true);
      log.clear();
    });

    test('starts with built-in themes', () {
      final registry = AppThemeRegistry();

      expect(registry.themes.map((theme) => theme.id), builtInIds);
    });

    test('includes One Dark as a built-in theme', () {
      final registry = AppThemeRegistry();
      final theme = registry.resolve('one-dark');

      expect(theme.name, 'One Dark');
      expect(theme.builtIn, isTrue);
      expect(theme.palette.bg.toARGB32(), 0xFF282C34);
      expect(theme.palette.terminal.blue.toARGB32(), 0xFF61AFEF);
    });

    test('loads valid custom themes after built-ins', () async {
      final json = darkTheme.toJson()
        ..['id'] = 'midnight'
        ..['name'] = 'Midnight';
      File('${dir.path}/midnight.json').writeAsStringSync(jsonEncode(json));

      final registry = AppThemeRegistry();
      await registry.load(customThemesPath: dir.path);

      expect(registry.themes.map((theme) => theme.id), [
        ...builtInIds,
        'midnight',
      ]);
      expect(registry.resolve('midnight').name, 'Midnight');
    });

    test('skips invalid themes and logs diagnostics entries', () async {
      File('${dir.path}/broken.json').writeAsStringSync('{"id":"broken"}');

      final registry = AppThemeRegistry();
      await registry.load(customThemesPath: dir.path);

      expect(registry.themes.map((theme) => theme.id), builtInIds);
      expect(log.entries.value, isNotEmpty);
      expect(log.entries.value.last.tag, 'theme');
    });

    test('custom themes cannot replace built-ins', () async {
      final json = darkTheme.toJson()
        ..['id'] = 'dark'
        ..['name'] = 'Other Dark';
      File('${dir.path}/dark.json').writeAsStringSync(jsonEncode(json));

      final registry = AppThemeRegistry();
      await registry.load(customThemesPath: dir.path);

      expect(registry.resolve('dark').name, 'Dark');
      expect(registry.themes.length, builtInThemes.length);
      expect(log.entries.value.last.message, contains('duplicate id'));
    });

    test('unknown ids resolve to dark and log once', () {
      final registry = AppThemeRegistry();

      expect(registry.resolve('missing').id, 'dark');
      expect(registry.resolve('missing').id, 'dark');
      expect(
        log.entries.value.where((entry) => entry.tag == 'theme'),
        hasLength(1),
      );
    });
  });
}
