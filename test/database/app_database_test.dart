import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waydir/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('AppSettings', () {
    test('getSettings creates default row on first call', () async {
      final settings = await db.getSettings();

      expect(settings.themeMode, 'dark');
      expect(settings.terminal, 'auto');
      expect(settings.terminalCustomCommand, '');
      expect(settings.isDual, false);
      expect(settings.splitRatio, 0.5);
      expect(settings.activePaneIndex, 0);
      expect(settings.dateFormat, 'locale');
      expect(settings.recentDatesRelative, true);
    });

    test('getSettings returns existing row on subsequent calls', () async {
      final first = await db.getSettings();
      final second = await db.getSettings();

      expect(first.id, second.id);
    });

    test('updateSettings persists changes', () async {
      await db.getSettings();
      await db.updateSettings(
        const AppSettingsCompanion(
          terminal: Value('alacritty'),
          terminalCustomCommand: Value('alacritty -e'),
          isDual: Value(true),
          splitRatio: Value(0.7),
          activePaneIndex: Value(1),
        ),
      );

      final settings = await db.getSettings();
      expect(settings.terminal, 'alacritty');
      expect(settings.terminalCustomCommand, 'alacritty -e');
      expect(settings.isDual, true);
      expect(settings.splitRatio, 0.7);
      expect(settings.activePaneIndex, 1);
    });

    test('updateSettings partial update leaves other fields intact', () async {
      await db.getSettings();
      await db.updateSettings(
        const AppSettingsCompanion(terminal: Value('kitty')),
      );

      final settings = await db.getSettings();
      expect(settings.terminal, 'kitty');
      expect(settings.isDual, false);
      expect(settings.splitRatio, 0.5);
    });
  });

  group('SessionTabs', () {
    test('getTabs returns empty list initially', () async {
      final tabs = await db.getTabs();
      expect(tabs, isEmpty);
    });

    test('replaceTabs inserts rows', () async {
      await db.replaceTabs([
        SessionTabsCompanion.insert(
          paneIndex: 0,
          tabIndex: 0,
          path: '/home/user',
          isActive: const Value(true),
        ),
        SessionTabsCompanion.insert(
          paneIndex: 0,
          tabIndex: 1,
          path: '/home/user/docs',
          isActive: const Value(false),
        ),
        SessionTabsCompanion.insert(
          paneIndex: 1,
          tabIndex: 0,
          path: '/home/user/downloads',
          isActive: const Value(true),
        ),
      ]);

      final tabs = await db.getTabs();
      expect(tabs.length, 3);
      expect(tabs[0].paneIndex, 0);
      expect(tabs[0].tabIndex, 0);
      expect(tabs[0].path, '/home/user');
      expect(tabs[0].isActive, true);
      expect(tabs[1].paneIndex, 0);
      expect(tabs[1].tabIndex, 1);
      expect(tabs[2].paneIndex, 1);
    });

    test('replaceTabs replaces previous rows', () async {
      await db.replaceTabs([
        SessionTabsCompanion.insert(
          paneIndex: 0,
          tabIndex: 0,
          path: '/old',
          isActive: const Value(true),
        ),
      ]);

      await db.replaceTabs([
        SessionTabsCompanion.insert(
          paneIndex: 0,
          tabIndex: 0,
          path: '/new',
          isActive: const Value(true),
        ),
      ]);

      final tabs = await db.getTabs();
      expect(tabs.length, 1);
      expect(tabs[0].path, '/new');
    });

    test('getTabs returns rows ordered by paneIndex then tabIndex', () async {
      await db.replaceTabs([
        SessionTabsCompanion.insert(
          paneIndex: 1,
          tabIndex: 0,
          path: '/pane1',
          isActive: const Value(true),
        ),
        SessionTabsCompanion.insert(
          paneIndex: 0,
          tabIndex: 1,
          path: '/pane0tab1',
          isActive: const Value(false),
        ),
        SessionTabsCompanion.insert(
          paneIndex: 0,
          tabIndex: 0,
          path: '/pane0tab0',
          isActive: const Value(true),
        ),
      ]);

      final tabs = await db.getTabs();
      expect(tabs[0].path, '/pane0tab0');
      expect(tabs[1].path, '/pane0tab1');
      expect(tabs[2].path, '/pane1');
    });
  });

  group('Bookmarks', () {
    test('getBookmarks returns empty list initially', () async {
      final bookmarks = await db.getBookmarks();
      expect(bookmarks, isEmpty);
    });

    test('addBookmark inserts rows in order', () async {
      await db.addBookmark('Downloads', '/home/user/Downloads');
      await db.addBookmark('Projects', '/home/user/Projects');

      final bookmarks = await db.getBookmarks();
      expect(bookmarks.length, 2);
      expect(bookmarks[0].label, 'Downloads');
      expect(bookmarks[0].path, '/home/user/Downloads');
      expect(bookmarks[1].label, 'Projects');
      expect(bookmarks[1].orderIndex, bookmarks[0].orderIndex + 1);
    });

    test('getBookmarkByPath returns matching row', () async {
      final added = await db.addBookmark('Projects', '/home/user/Projects');

      final bookmark = await db.getBookmarkByPath('/home/user/Projects');
      expect(bookmark?.id, added.id);
    });

    test('renameBookmark updates label', () async {
      final added = await db.addBookmark('Projects', '/home/user/Projects');

      await db.renameBookmark(added.id, 'Code');

      final bookmark = await db.getBookmarkByPath('/home/user/Projects');
      expect(bookmark?.label, 'Code');
    });

    test('deleteBookmark removes row', () async {
      final added = await db.addBookmark('Projects', '/home/user/Projects');

      await db.deleteBookmark(added.id);

      final bookmarks = await db.getBookmarks();
      expect(bookmarks, isEmpty);
    });
  });
}
