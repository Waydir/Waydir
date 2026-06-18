@Tags(<String>['integration'])
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:waydir/core/database/app_database.dart';

void main() {
  late Directory tmpDir;

  setUp(() {
    tmpDir = Directory.systemTemp.createTempSync('waydir_db_migration_');
  });

  tearDown(() {
    if (tmpDir.existsSync()) tmpDir.deleteSync(recursive: true);
  });

  test('migrates v12 database to current schema without losing data', () async {
    final path = p.join(tmpDir.path, 'legacy.sqlite');
    _createSchemaV12(path);

    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(db.close);

    final settings = await db.getSettings();
    final bookmarks = await db.getBookmarks();
    final tabs = await db.getTabs();

    expect(settings.themeMode, 'nord');
    expect(settings.terminal, 'kitty');
    expect(settings.confirmCopy, isFalse);
    expect(settings.confirmMove, isTrue);
    expect(settings.fileListHorizontalSpacing, 6);
    expect(settings.fileListVerticalSpacing, 6);
    expect(settings.columnWidthMode, 'automatic');
    expect(settings.columnWidths, '{}');
    expect(bookmarks.single.path, '/tmp/project');
    expect(tabs.single.path, '/tmp/project');

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), db.schemaVersion);

    final recentPathsTable = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'recent_entered_paths'",
        )
        .getSingleOrNull();
    expect(recentPathsTable, isNotNull);

    final sidebarPrefsTable = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'sidebar_prefs'",
        )
        .getSingleOrNull();
    expect(sidebarPrefsTable, isNotNull);
  });
}

void _createSchemaV12(String path) {
  final db = sqlite3.open(path);
  try {
    db.execute('''
CREATE TABLE app_settings (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  theme_mode TEXT NOT NULL DEFAULT 'dark',
  terminal TEXT NOT NULL DEFAULT 'auto',
  terminal_custom_command TEXT NOT NULL DEFAULT '',
  is_dual INTEGER NOT NULL DEFAULT 0 CHECK (is_dual IN (0, 1)),
  split_ratio REAL NOT NULL DEFAULT 0.5,
  active_pane_index INTEGER NOT NULL DEFAULT 0,
  sidebar_collapsed INTEGER NOT NULL DEFAULT 0 CHECK (sidebar_collapsed IN (0, 1)),
  restore_session INTEGER NOT NULL DEFAULT 1 CHECK (restore_session IN (0, 1)),
  default_starting_path TEXT NOT NULL DEFAULT '',
  confirm_delete INTEGER NOT NULL DEFAULT 1 CHECK (confirm_delete IN (0, 1)),
  show_hidden_default INTEGER NOT NULL DEFAULT 0 CHECK (show_hidden_default IN (0, 1)),
  row_density TEXT NOT NULL DEFAULT 'comfortable',
  date_format TEXT NOT NULL DEFAULT 'locale',
  recent_dates_relative INTEGER NOT NULL DEFAULT 1 CHECK (recent_dates_relative IN (0, 1)),
  delete_key_behavior TEXT NOT NULL DEFAULT 'trash',
  sort_key TEXT NOT NULL DEFAULT 'name',
  sort_ascending INTEGER NOT NULL DEFAULT 1 CHECK (sort_ascending IN (0, 1)),
  folders_first INTEGER NOT NULL DEFAULT 1 CHECK (folders_first IN (0, 1))
);
CREATE TABLE session_tabs (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  pane_index INTEGER NOT NULL,
  tab_index INTEGER NOT NULL,
  path TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 0 CHECK (is_active IN (0, 1))
);
CREATE TABLE bookmarks (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  order_index INTEGER NOT NULL,
  label TEXT NOT NULL,
  path TEXT NOT NULL UNIQUE
);
CREATE TABLE folder_prefs (
  path TEXT NOT NULL PRIMARY KEY,
  sort_key TEXT NOT NULL DEFAULT 'name',
  sort_ascending INTEGER NOT NULL DEFAULT 1 CHECK (sort_ascending IN (0, 1)),
  folders_first INTEGER NOT NULL DEFAULT 1 CHECK (folders_first IN (0, 1)),
  updated_at INTEGER NOT NULL DEFAULT 0
);
CREATE TABLE recent_apps (
  mime TEXT NOT NULL,
  app_id TEXT NOT NULL,
  app_name TEXT NOT NULL,
  app_exec TEXT NOT NULL,
  icon_path TEXT,
  used_at INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (mime, app_id)
);
CREATE TABLE default_apps (
  type_key TEXT NOT NULL,
  app_id TEXT NOT NULL,
  app_name TEXT NOT NULL,
  app_exec TEXT NOT NULL,
  icon_path TEXT,
  PRIMARY KEY (type_key)
);
INSERT INTO app_settings (
  theme_mode,
  terminal,
  terminal_custom_command,
  is_dual,
  split_ratio,
  active_pane_index,
  sidebar_collapsed,
  restore_session,
  default_starting_path,
  confirm_delete,
  show_hidden_default,
  row_density,
  date_format,
  recent_dates_relative,
  delete_key_behavior,
  sort_key,
  sort_ascending,
  folders_first
) VALUES (
  'nord',
  'kitty',
  'kitty -e',
  1,
  0.65,
  1,
  1,
  0,
  '/tmp/project',
  0,
  1,
  'compact',
  'iso',
  0,
  'delete',
  'modified',
  0,
  0
);
INSERT INTO bookmarks (order_index, label, path)
VALUES (0, 'Project', '/tmp/project');
INSERT INTO session_tabs (pane_index, tab_index, path, is_active)
VALUES (0, 0, '/tmp/project', 1);
PRAGMA user_version = 12;
''');
  } finally {
    db.close();
  }
}
