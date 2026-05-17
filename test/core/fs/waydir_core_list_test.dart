import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/models/file_entry.dart';
import 'package:waydir/core/fs/waydir_core_loader.dart';

void main() {
  test('native list returns sorted entries with size and mtime', () {
    final lib = WaydirCoreLoader.load();
    if (lib == null) return; // native helper absent: skip.

    final root = Directory.systemTemp.createTempSync('waydir_list_test');
    try {
      Directory('${root.path}/zeta_dir').createSync();
      File('${root.path}/beta.txt').writeAsStringSync('hello');
      File('${root.path}/Alpha.bin').writeAsBytesSync([1, 2, 3, 4]);

      final blob = WaydirCoreLoader.listDir(root.path);
      expect(blob, isNotNull);
      final entries = FileEntryCodec.decode(blob!);

      expect(entries.map((e) => e.name).toList(), [
        'zeta_dir',
        'Alpha.bin',
        'beta.txt',
      ]);
      expect(entries[0].type, FileItemType.folder);
      final beta = entries.firstWhere((e) => e.name == 'beta.txt');
      expect(beta.size, 5);
      expect(beta.modifiedMs, greaterThan(0));
    } finally {
      root.deleteSync(recursive: true);
    }
  });

  test('native list returns null for a missing directory', () {
    if (WaydirCoreLoader.load() == null) return;
    final missing =
        '${Directory.systemTemp.path}/waydir_does_not_exist_zzz_123';
    expect(WaydirCoreLoader.listDir(missing), isNull);
  });
}
