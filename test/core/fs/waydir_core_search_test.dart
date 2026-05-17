import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/core/fs/waydir_core_loader.dart';

void main() {
  test('native search finds matching names recursively', () {
    final lib = WaydirCoreLoader.load();
    if (lib == null) {
      // Native helper not built in this environment; skipped.
      return;
    }

    final root = Directory.systemTemp.createTempSync('waydir_core_test');
    try {
      File('${root.path}/alpha.txt').writeAsStringSync('x');
      final sub = Directory('${root.path}/nested')..createSync();
      File('${sub.path}/alpha_deep.log').writeAsStringSync('y');
      File('${sub.path}/unrelated.bin').writeAsStringSync('z');

      final blob = WaydirCoreLoader.search(root.path, 'alpha', true);
      expect(blob, isNotNull);
      final entries = FileEntryCodec.decode(blob!);
      final names = entries.map((e) => e.name).toSet();
      expect(names.contains('alpha.txt'), isTrue);
      expect(names.contains('alpha_deep.log'), isTrue);
      expect(names.contains('unrelated.bin'), isFalse);
    } finally {
      root.deleteSync(recursive: true);
    }
  });
}
