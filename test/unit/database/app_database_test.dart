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
      expect(settings.terminal, 'builtin');
      expect(settings.terminalCustomCommand, '');
      expect(settings.isDual, false);
      expect(settings.splitRatio, 0.5);
      expect(settings.activePaneIndex, 0);
      expect(settings.fileListHorizontalSpacing, 6);
      expect(settings.fileListVerticalSpacing, 6);
      expect(settings.columnWidthMode, 'automatic');
      expect(settings.columnWidths, '{}');
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
          fileListHorizontalSpacing: Value(8),
          fileListVerticalSpacing: Value(4),
          columnWidthMode: Value('resizable'),
          columnWidths: Value('{"name":240}'),
          isDual: Value(true),
          splitRatio: Value(0.7),
          activePaneIndex: Value(1),
        ),
      );

      final settings = await db.getSettings();
      expect(settings.terminal, 'alacritty');
      expect(settings.terminalCustomCommand, 'alacritty -e');
      expect(settings.fileListHorizontalSpacing, 8);
      expect(settings.fileListVerticalSpacing, 4);
      expect(settings.columnWidthMode, 'resizable');
      expect(settings.columnWidths, '{"name":240}');
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

  group('RecentEnteredPaths', () {
    test('returns most recently recorded paths first', () async {
      await db.recordRecentEnteredPath('/tmp/one');
      await db.recordRecentEnteredPath('/tmp/two');
      await db.recordRecentEnteredPath('/tmp/one');

      final paths = await db.getRecentEnteredPaths();

      expect(paths.take(2), ['/tmp/one', '/tmp/two']);
    });

    test('keeps only latest 20 paths', () async {
      for (var i = 0; i < 25; i++) {
        await db.recordRecentEnteredPath('/tmp/$i');
      }

      final paths = await db.getRecentEnteredPaths(limit: 30);

      expect(paths.length, 20);
      expect(paths, isNot(contains('/tmp/0')));
      expect(paths, contains('/tmp/24'));
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

  group('SidebarPrefs', () {
    test('getSidebarPrefs returns empty list initially', () async {
      expect(await db.getSidebarPrefs(), isEmpty);
    });

    test('setSidebarOrder writes ascending order indices', () async {
      await db.setSidebarOrder('section', ['network', 'favorites', 'devices']);

      final rows = await db.getSidebarPrefs()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      expect(rows.map((r) => r.itemKey), ['network', 'favorites', 'devices']);
      expect(rows.map((r) => r.orderIndex), [0, 1, 2]);
      expect(rows.every((r) => !r.hidden), isTrue);
    });

    test('setSidebarOrder updates indices but preserves hidden flag', () async {
      await db.setSidebarOrder('favorites', ['home', 'music']);
      await db.setSidebarPref(
        'favorites',
        'music',
        orderIndex: 1,
        hidden: true,
      );

      await db.setSidebarOrder('favorites', ['music', 'home']);

      final rows = await db.getSidebarPrefs();
      final music = rows.firstWhere((r) => r.itemKey == 'music');
      expect(music.orderIndex, 0);
      expect(music.hidden, isTrue);
    });

    test('setSidebarPref upserts a single row', () async {
      await db.setSidebarPref(
        'section',
        'network',
        orderIndex: 2,
        hidden: true,
      );

      final row = (await db.getSidebarPrefs()).single;
      expect(row.scope, 'section');
      expect(row.itemKey, 'network');
      expect(row.orderIndex, 2);
      expect(row.hidden, isTrue);

      await db.setSidebarPref(
        'section',
        'network',
        orderIndex: 2,
        hidden: false,
      );
      expect((await db.getSidebarPrefs()).single.hidden, isFalse);
    });
  });
}
