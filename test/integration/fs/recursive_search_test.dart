@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/fs/recursive_search.dart';
import 'package:waydir/core/fs/waydir_core_loader.dart';

void main() {
  test(
    'terminal callback fires exactly once even when cancelled early',
    () async {
      expect(WaydirCoreLoader.load(), isNotNull);

      final root = Directory.systemTemp.createTempSync('waydir_search_cancel');
      try {
        for (var i = 0; i < 2000; i++) {
          File('${root.path}/f$i.txt').writeAsStringSync('$i');
        }

        var done = 0;
        var error = 0;

        final handle = RecursiveSearch.start(
          root: root.path,
          query: 'f',
          includeHidden: true,
          onBatch: (_) {},
          onProgress: (_, _) {},
          onDone: () => done++,
          onError: (_) => error++,
        );
        handle.cancel();

        final deadline = DateTime.now().add(const Duration(seconds: 5));
        while (done + error == 0 && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));

        expect(
          done + error,
          1,
          reason: 'exactly one terminal callback expected',
        );
      } finally {
        root.deleteSync(recursive: true);
      }
    },
  );
}
