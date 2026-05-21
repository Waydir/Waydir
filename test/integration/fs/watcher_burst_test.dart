@Tags(<String>['integration'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/fs/directory_watcher_service.dart';

void main() {
  late Directory tmpDir;
  late DirectoryWatcherService watcher;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('waydir_watch_burst_');
    watcher = DirectoryWatcherService();
  });

  tearDown(() {
    watcher.dispose();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test('coalesces burst changes and stops after dispose', () async {
    final batches = <Set<String>>[];
    final firstBatch = Completer<void>();

    watcher.watch(tmpDir.path, (changed, fullReload) {
      batches.add(changed);
      if (!firstBatch.isCompleted) firstBatch.complete();
    });

    final expected = <String>{};
    for (var i = 0; i < 20; i++) {
      final path = p.join(tmpDir.path, 'file_$i.txt');
      expected.add(path);
      File(path).writeAsStringSync('$i');
    }

    await firstBatch.future.timeout(const Duration(seconds: 5));
    final observed = batches.expand((batch) => batch).toSet();
    expect(observed.containsAll(expected), isTrue);

    watcher.dispose();
    final afterDisposeCount = batches.length;
    File(p.join(tmpDir.path, 'after_dispose.txt')).writeAsStringSync('x');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(batches.length, afterDisposeCount);
  });
}
