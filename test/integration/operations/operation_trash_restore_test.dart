@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/platform/trash_location.dart';
import 'package:waydir/core/platform/platform_paths.dart';

void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('waydir_trash_restore_');
    PlatformPaths.trashPathOverride = p.join(tmpDir.path, 'trash', 'files');
  });

  tearDown(() {
    PlatformPaths.trashPathOverride = null;
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test(
    'TrashRepository restores freedesktop metadata entries in an isolated trash',
    () async {
      final name = 'note_${DateTime.now().microsecondsSinceEpoch}.txt';
      final targetDir = Directory(p.join(tmpDir.path, 'restore_target'))
        ..createSync(recursive: true);
      final restored = File(p.join(targetDir.path, 'restored_$name'));
      final entry = await _createFreedesktopTrashEntry(restored.path);

      await TrashRepository.instance.restore(entry);

      expect(restored.readAsStringSync(), 'payload');
    },
    skip: !Platform.isLinux,
  );
}

Future<TrashEntry> _createFreedesktopTrashEntry(String originalPath) async {
  final filesDir = PlatformPaths.trashPath!;
  final infoDir = p.join(p.dirname(filesDir), 'info');
  Directory(filesDir).createSync(recursive: true);
  Directory(infoDir).createSync(recursive: true);

  final trashedName = 'waydir_test_${DateTime.now().microsecondsSinceEpoch}';
  File(p.join(filesDir, trashedName)).writeAsStringSync('payload');
  File(p.join(infoDir, '$trashedName.trashinfo')).writeAsStringSync('''
[Trash Info]
Path=$originalPath
DeletionDate=2026-05-21T00:00:00
''');

  final entries = await TrashRepository.instance.listRoot();
  return entries.firstWhere(
    (entry) => entry.displayName == p.basename(originalPath),
  );
}
