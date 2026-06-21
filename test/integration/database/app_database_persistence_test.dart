@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/core/database/app_database.dart' hide Tags;

void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('waydir_db_persist_');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test('persists settings, bookmarks and tabs across reopen', () async {
    final path = p.join(tmpDir.path, 'waydir.sqlite');
    var db = AppDatabase(NativeDatabase(File(path)));

    await db.getSettings();
    await db.updateSettings(
      const AppSettingsCompanion(
        themeMode: Value('nord'),
        terminal: Value('wezterm'),
        isDual: Value(true),
        splitRatio: Value(0.7),
        confirmCopy: Value(true),
        confirmMove: Value(false),
      ),
    );
    await db.addBookmark('Workspace', '/tmp/workspace');
    await db.replaceTabs([
      SessionTabsCompanion.insert(
        paneIndex: 0,
        tabIndex: 0,
        path: '/tmp/workspace',
        isActive: const Value(true),
      ),
      SessionTabsCompanion.insert(
        paneIndex: 1,
        tabIndex: 0,
        path: '/tmp/downloads',
        isActive: const Value(true),
      ),
    ]);
    await db.close();

    db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);

    final settings = await db.getSettings();
    final bookmarks = await db.getBookmarks();
    final tabs = await db.getTabs();

    expect(settings.themeMode, 'nord');
    expect(settings.terminal, 'wezterm');
    expect(settings.isDual, isTrue);
    expect(settings.splitRatio, 0.7);
    expect(settings.confirmCopy, isTrue);
    expect(settings.confirmMove, isFalse);
    expect(bookmarks.single.label, 'Workspace');
    expect(bookmarks.single.path, '/tmp/workspace');
    expect(tabs.map((tab) => tab.path), ['/tmp/workspace', '/tmp/downloads']);
  });
}
