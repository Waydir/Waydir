import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../platform/app_dirs.dart';

part 'app_database.g.dart';

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get themeMode => text().withDefault(const Constant('dark'))();
  TextColumn get terminal => text().withDefault(const Constant('auto'))();
  TextColumn get terminalCustomCommand =>
      text().withDefault(const Constant(''))();
  BoolColumn get isDual => boolean().withDefault(const Constant(false))();
  RealColumn get splitRatio => real().withDefault(const Constant(0.5))();
  IntColumn get activePaneIndex => integer().withDefault(const Constant(0))();
  BoolColumn get sidebarCollapsed =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get restoreSession =>
      boolean().withDefault(const Constant(true))();
  TextColumn get defaultStartingPath =>
      text().withDefault(const Constant(''))();
  BoolColumn get confirmDelete => boolean().withDefault(const Constant(true))();
  BoolColumn get confirmCopy => boolean().withDefault(const Constant(false))();
  BoolColumn get confirmMove => boolean().withDefault(const Constant(true))();
  BoolColumn get showHiddenDefault =>
      boolean().withDefault(const Constant(false))();
  TextColumn get rowDensity =>
      text().withDefault(const Constant('comfortable'))();
  TextColumn get dateFormat => text().withDefault(const Constant('locale'))();
  BoolColumn get recentDatesRelative =>
      boolean().withDefault(const Constant(true))();
  TextColumn get deleteKeyBehavior =>
      text().withDefault(const Constant('trash'))();
  TextColumn get sortKey => text().withDefault(const Constant('name'))();
  BoolColumn get sortAscending => boolean().withDefault(const Constant(true))();
  BoolColumn get foldersFirst => boolean().withDefault(const Constant(true))();
  TextColumn get searchMode =>
      text().withDefault(const Constant('substring'))();
}

class SessionTabs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get paneIndex => integer()();
  IntColumn get tabIndex => integer()();
  TextColumn get path => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get orderIndex => integer()();
  TextColumn get label => text()();
  TextColumn get path => text().unique()();
}

class FolderPrefs extends Table {
  TextColumn get path => text()();
  TextColumn get sortKey => text().withDefault(const Constant('name'))();
  BoolColumn get sortAscending => boolean().withDefault(const Constant(true))();
  BoolColumn get foldersFirst => boolean().withDefault(const Constant(true))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {path};
}

class RecentApps extends Table {
  TextColumn get mime => text()();
  TextColumn get appId => text()();
  TextColumn get appName => text()();
  TextColumn get appExec => text()();
  TextColumn get iconPath => text().nullable()();
  IntColumn get usedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {mime, appId};
}

/// Waydir's own "file type → application" default mapping. Independent of the
/// OS associations: [typeKey] is the MIME type on Linux/macOS and the file
/// extension (with dot) on Windows.
class DefaultApps extends Table {
  TextColumn get typeKey => text()();
  TextColumn get appId => text()();
  TextColumn get appName => text()();
  TextColumn get appExec => text()();
  TextColumn get iconPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {typeKey};
}

@DriftDatabase(
  tables: [
    AppSettings,
    SessionTabs,
    Bookmarks,
    FolderPrefs,
    RecentApps,
    DefaultApps,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(bookmarks);
      }
      Future<void> addSettingColumn(GeneratedColumn column) async {
        final existing = await customSelect(
          'PRAGMA table_info(app_settings)',
        ).get();
        final names = existing.map((r) => r.read<String>('name')).toSet();
        if (!names.contains(column.name)) {
          await m.addColumn(appSettings, column);
        }
      }

      if (from < 3) {
        await addSettingColumn(appSettings.sidebarCollapsed);
      }
      if (from < 4) {
        await addSettingColumn(appSettings.restoreSession);
        await addSettingColumn(appSettings.defaultStartingPath);
        await addSettingColumn(appSettings.confirmDelete);
        await addSettingColumn(appSettings.showHiddenDefault);
        await addSettingColumn(appSettings.rowDensity);
        await addSettingColumn(appSettings.dateFormat);
      }
      if (from < 5) {
        await addSettingColumn(appSettings.recentDatesRelative);
      }
      if (from < 6) {
        await addSettingColumn(appSettings.deleteKeyBehavior);
      }
      if (from < 7) {
        await addSettingColumn(appSettings.sortKey);
        await addSettingColumn(appSettings.sortAscending);
        await addSettingColumn(appSettings.foldersFirst);
      }
      if (from < 8) {
        await m.createTable(folderPrefs);
      }
      if (from < 9) {
        await m.createTable(recentApps);
      }
      if (from < 10) {
        await m.createTable(defaultApps);
      }
      if (from < 11) {
        await addSettingColumn(appSettings.themeMode);
      }
      if (from < 12) {
        await customStatement(
          "UPDATE app_settings SET theme_mode = 'dark' WHERE theme_mode = 'system'",
        );
      }
      if (from < 13) {
        await addSettingColumn(appSettings.confirmCopy);
        await addSettingColumn(appSettings.confirmMove);
      }
      if (from < 14) {
        await addSettingColumn(appSettings.searchMode);
      }
    },
  );

  Future<DefaultApp?> getDefaultApp(String typeKey) {
    return (select(
      defaultApps,
    )..where((t) => t.typeKey.equals(typeKey))).getSingleOrNull();
  }

  Future<void> setDefaultApp({
    required String typeKey,
    required String appId,
    required String appName,
    required String appExec,
    String? iconPath,
  }) {
    return into(defaultApps).insertOnConflictUpdate(
      DefaultAppsCompanion.insert(
        typeKey: typeKey,
        appId: appId,
        appName: appName,
        appExec: appExec,
        iconPath: Value(iconPath),
      ),
    );
  }

  Future<void> clearDefaultApp(String typeKey) {
    return (delete(defaultApps)..where((t) => t.typeKey.equals(typeKey))).go();
  }

  Future<List<RecentApp>> getRecentApps(String mime, {int limit = 3}) {
    return (select(recentApps)
          ..where((t) => t.mime.equals(mime))
          ..orderBy([(t) => OrderingTerm.desc(t.usedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> recordRecentApp({
    required String mime,
    required String appId,
    required String appName,
    required String appExec,
    String? iconPath,
  }) {
    return into(recentApps).insertOnConflictUpdate(
      RecentAppsCompanion.insert(
        mime: mime,
        appId: appId,
        appName: appName,
        appExec: appExec,
        iconPath: Value(iconPath),
        usedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'waydir.db',
      native: DriftNativeOptions(databaseDirectory: _getDatabaseDirectory),
    );
  }

  static Future<String> _getDatabaseDirectory() => AppDirs.support();

  Future<AppSetting> getSettings() {
    return (select(appSettings)..limit(1)).getSingleOrNull().then((row) {
      if (row != null) return row;
      return into(appSettings).insertReturning(AppSettingsCompanion.insert());
    });
  }

  Future<void> updateSettings(AppSettingsCompanion companion) {
    return (update(appSettings)..where((t) => t.id.equals(1))).write(companion);
  }

  Future<void> replaceTabs(List<SessionTabsCompanion> rows) async {
    await (delete(sessionTabs)).go();
    await batch((b) {
      b.insertAll(sessionTabs, rows);
    });
  }

  Future<List<SessionTab>> getTabs() {
    return (select(sessionTabs)..orderBy([
          (t) => OrderingTerm.asc(t.paneIndex),
          (t) => OrderingTerm.asc(t.tabIndex),
        ]))
        .get();
  }

  Future<List<Bookmark>> getBookmarks() {
    return (select(
      bookmarks,
    )..orderBy([(t) => OrderingTerm.asc(t.orderIndex)])).get();
  }

  Future<Bookmark?> getBookmarkByPath(String path) {
    return (select(
      bookmarks,
    )..where((t) => t.path.equals(path))).getSingleOrNull();
  }

  Future<Bookmark> addBookmark(String label, String path) async {
    final maxOrder = bookmarks.orderIndex.max();
    final row = await (selectOnly(
      bookmarks,
    )..addColumns([maxOrder])).getSingleOrNull();
    final nextOrder = (row?.read(maxOrder) ?? -1) + 1;
    return into(bookmarks).insertReturning(
      BookmarksCompanion.insert(
        orderIndex: nextOrder,
        label: label,
        path: path,
      ),
    );
  }

  Future<void> renameBookmark(int id, String label) {
    return (update(bookmarks)..where((t) => t.id.equals(id))).write(
      BookmarksCompanion(label: Value(label)),
    );
  }

  Future<void> deleteBookmark(int id) {
    return (delete(bookmarks)..where((t) => t.id.equals(id))).go();
  }

  Future<void> reorderBookmarks(List<int> idsInOrder) async {
    await batch((b) {
      for (var i = 0; i < idsInOrder.length; i++) {
        b.update(
          bookmarks,
          BookmarksCompanion(orderIndex: Value(i)),
          where: (t) => t.id.equals(idsInOrder[i]),
        );
      }
    });
  }

  /// Keep at most this many remembered per-folder sort preferences.
  static const int _maxFolderPrefs = 500;

  Future<FolderPref?> getFolderPref(String path) {
    return (select(
      folderPrefs,
    )..where((t) => t.path.equals(path))).getSingleOrNull();
  }

  Future<void> setFolderPref(
    String path, {
    required String sortKey,
    required bool sortAscending,
    required bool foldersFirst,
  }) async {
    await into(folderPrefs).insertOnConflictUpdate(
      FolderPrefsCompanion.insert(
        path: path,
        sortKey: Value(sortKey),
        sortAscending: Value(sortAscending),
        foldersFirst: Value(foldersFirst),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    await _pruneFolderPrefs();
  }

  Future<void> deleteFolderPref(String path) {
    return (delete(folderPrefs)..where((t) => t.path.equals(path))).go();
  }

  Future<void> _pruneFolderPrefs() async {
    final countExp = folderPrefs.path.count();
    final row = await (selectOnly(
      folderPrefs,
    )..addColumns([countExp])).getSingle();
    final total = row.read(countExp) ?? 0;
    if (total <= _maxFolderPrefs) return;
    final cutoff =
        await (select(folderPrefs)
              ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
              ..limit(1, offset: _maxFolderPrefs - 1))
            .getSingle();
    await (delete(
      folderPrefs,
    )..where((t) => t.updatedAt.isSmallerThanValue(cutoff.updatedAt))).go();
  }
}
