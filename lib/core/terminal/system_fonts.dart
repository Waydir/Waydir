import 'dart:io';

import '../logging/app_logger.dart';

class SystemFonts {
  SystemFonts._();

  static const _fallback = [
    'monospace',
    'DejaVu Sans Mono',
    'Liberation Mono',
    'Noto Sans Mono',
    'Source Code Pro',
    'JetBrains Mono',
    'Fira Code',
    'Hack',
    'Cascadia Code',
    'Courier New',
    'Consolas',
    'Menlo',
    'Monaco',
  ];

  static Future<List<String>> monospaceFamilies() async {
    final families = <String>{'monospace'};
    if (Platform.isLinux) {
      families.addAll(await _fcList());
    }
    if (families.length <= 1) {
      return _fallback;
    }
    final sorted = families.where((f) => f != 'monospace').toList()..sort();
    return ['monospace', ...sorted];
  }

  static Future<List<String>> _fcList() async {
    final names = <String>{};
    for (final spacing in const ['100', '110']) {
      try {
        final result = await Process.run('fc-list', [
          ':spacing=$spacing',
          'family',
        ]);
        if (result.exitCode != 0) continue;
        for (final line in (result.stdout as String).split('\n')) {
          final family = line.split(',').first.trim();
          if (family.isNotEmpty) names.add(family);
        }
      } catch (e, st) {
        log.warn('terminal', 'font discovery failed', error: e, stack: st);
      }
    }
    return names.toList();
  }
}
