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
    tmpDir = Directory.systemTemp.createTempSync('waydir_watch_');
    watcher = DirectoryWatcherService();
  });

  tearDown(() {
    watcher.dispose();
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  Future<Set<String>> nextChange() async {
    final completer = Completer<Set<String>>();
    watcher.watch(tmpDir.path, (changed, full) {
      if (!completer.isCompleted) completer.complete(changed);
    });
    return completer.future.timeout(const Duration(seconds: 5));
  }

  test('reports successive changes without dying after the first', () async {
    final first = nextChange();
    File(p.join(tmpDir.path, 'a.txt')).writeAsStringSync('1');
    await first;

    final completer = Completer<void>();
    watcher.watch(tmpDir.path, (changed, full) {
      if (!completer.isCompleted) completer.complete();
    });
    File(p.join(tmpDir.path, 'b.txt')).writeAsStringSync('2');
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () =>
          fail('watcher stopped delivering events after the first change'),
    );
  });
}
