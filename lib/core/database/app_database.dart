import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../platform/app_dirs.dart';

part 'app_database.g.dart';

class AppSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get themeMode => text().withDefault(const Constant('dark'))();
  TextColumn get terminal => text().withDefault(const Constant('builtin'))();
  TextColumn get terminalShell =>
      text().withDefault(const Constant('system'))();
  TextColumn get terminalCustomCommand =>
      text().withDefault(const Constant(''))();
  BoolColumn get terminalUseSystemFont =>
      boolean().withDefault(const Constant(true))();
  TextColumn get terminalFontFamily => text().withDefault(const Constant(''))();
  IntColumn get terminalFontSize => integer().withDefault(const Constant(13))();
  RealColumn get terminalLineHeight =>
      real().withDefault(const Constant(1.2))();
  BoolColumn get isDual => boolean().withDefault(const Constant(false))();
  RealColumn get splitRatio => real().withDefault(const Constant(0.5))();
  IntColumn get activePaneIndex => integer().withDefault(const Constant(0))();
  BoolColumn get sidebarCollapsed =>
      boolean().withDefault(const Constant(false))();
  RealColumn get sidebarWidth => real().withDefault(const Constant(200.0))();
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
  IntColumn get fileListHorizontalSpacing =>
      integer().withDefault(const Constant(6))();
  IntColumn get fileListVerticalSpacing =>
      integer().withDefault(const Constant(6))();
  TextColumn get dateFormat => text().withDefault(const Constant('locale'))();
  BoolColumn get recentDatesRelative =>
      boolean().withDefault(const Constant(true))();
  TextColumn get deleteKeyBehavior =>
      text().withDefault(const Constant('trash'))();
  TextColumn get sortKey => text().withDefault(const Constant('name'))();
  BoolColumn get sortAscending => boolean().withDefault(const Constant(true))();
  BoolColumn get foldersFirst => boolean().withDefault(const Constant(true))();
  BoolColumn get naturalSort => boolean().withDefault(const Constant(true))();
  BoolColumn get sortFolders => boolean().withDefault(const Constant(true))();
  TextColumn get searchMode =>
      text().withDefault(const Constant('substring'))();
  BoolColumn get rememberFolderState =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get rememberFolderSort =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get typeAheadBuffer =>
      boolean().withDefault(const Constant(true))();
  RealColumn get fileListScale => real().withDefault(const Constant(1.0))();
  TextColumn get fileViewMode => text().withDefault(const Constant('list'))();
  BoolColumn get showColumnSize =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showColumnDate =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showColumnKind =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showColumnCreated =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showColumnAdded =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showColumnPermissions =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get showColumnOwner =>
      boolean().withDefault(const Constant(false))();
  TextColumn get columnOrder => text().withDefault(
    const Constant('kind,size,date,created,added,permissions,owner'),
  )();
  TextColumn get columnWidthMode =>
      text().withDefault(const Constant('automatic'))();
  TextColumn get columnWidths => text().withDefault(const Constant('{}'))();
  BoolColumn get quickLookUseSystemFont =>
      boolean().withDefault(const Constant(true))();
  TextColumn get quickLookFontFamily =>
      text().withDefault(const Constant(''))();
  IntColumn get quickLookFontSize =>
      integer().withDefault(const Constant(13))();
  RealColumn get quickLookLineHeight =>
      real().withDefault(const Constant(1.5))();
  BoolColumn get quickLookShowLineNumbers =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quickLookRelativeLineNumbers =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quickLookVimMode =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get quickLookWrapLines =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get quickLookShowStatistics =>
      boolean().withDefault(const Constant(true))();
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
  TextColumn get cursorPath => text().nullable()();
  TextColumn get selectedPaths => text().nullable()();
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

class RecentEnteredPaths extends Table {
  TextColumn get path => text()();
  IntColumn get usedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {path};
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

class ShortcutBindings extends Table {
  TextColumn get actionId => text()();
  IntColumn get keyId => integer()();
  BoolColumn get ctrl => boolean().withDefault(const Constant(false))();
  BoolColumn get shift => boolean().withDefault(const Constant(false))();
  BoolColumn get alt => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {actionId};
}

/// Per-plugin persisted configuration. [value] holds a JSON-encoded scalar so
/// any field type from a plugin's settings schema round-trips unchanged.
class PluginSettings extends Table {
  TextColumn get pluginId => text()();
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {pluginId, key};
}

/// Plugins the user has explicitly turned off. Presence means disabled.
class DisabledPlugins extends Table {
  TextColumn get pluginId => text()();

  @override
  Set<Column> get primaryKey => {pluginId};
}

/// User overrides for sidebar layout: section and item order plus visibility.
/// [scope] is `section` for whole sections, otherwise the section id
/// (`favorites`, `devices`, `network`) whose items are being ordered. [itemKey]
/// is the section id (for `section` scope) or a stable item key within a scope.
class SidebarPrefs extends Table {
  TextColumn get scope => text()();
  TextColumn get itemKey => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {scope, itemKey};
}

@DriftDatabase(
  tables: [
    AppSettings,
    SessionTabs,
    Bookmarks,
    FolderPrefs,
    RecentApps,
    RecentEnteredPaths,
    DefaultApps,
    ShortcutBindings,
    PluginSettings,
    DisabledPlugins,
    SidebarPrefs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 38;

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
      if (from < 15) {
        await addSettingColumn(appSettings.fileListHorizontalSpacing);
        await addSettingColumn(appSettings.fileListVerticalSpacing);
      }
      Future<void> addFolderPrefColumn(GeneratedColumn column) async {
        final existing = await customSelect(
          'PRAGMA table_info(folder_prefs)',
        ).get();
        final names = existing.map((r) => r.read<String>('name')).toSet();
        if (!names.contains(column.name)) {
          await m.addColumn(folderPrefs, column);
        }
      }

      if (from < 16) {
        await addSettingColumn(appSettings.rememberFolderState);
        await addSettingColumn(appSettings.rememberFolderSort);
        await addFolderPrefColumn(folderPrefs.cursorPath);
        await addFolderPrefColumn(folderPrefs.selectedPaths);
      }
      if (from < 17) {
        await m.createTable(recentEnteredPaths);
      }
      if (from < 18) {
        await addSettingColumn(appSettings.terminalFontFamily);
        await addSettingColumn(appSettings.terminalFontSize);
        await addSettingColumn(appSettings.terminalLineHeight);
      }
      if (from < 19) {
        await addSettingColumn(appSettings.terminalUseSystemFont);
      }
      if (from < 20) {
        await addSettingColumn(appSettings.fileListScale);
      }
      if (from < 21) {
        await m.createTable(shortcutBindings);
      }
      if (from < 22) {
        await addSettingColumn(appSettings.naturalSort);
      }
      if (from < 23) {
        await addSettingColumn(appSettings.terminalShell);
      }
      if (from < 24) {
        await addSettingColumn(appSettings.sidebarWidth);
      }
      if (from < 25) {
        await m.createTable(pluginSettings);
      }
      if (from < 26) {
        await m.createTable(disabledPlugins);
      }
      if (from < 27) {
        await addSettingColumn(appSettings.sortFolders);
      }
      if (from < 28) {
        await m.createTable(sidebarPrefs);
      }
      if (from < 29) {
        await addSettingColumn(appSettings.showColumnSize);
        await addSettingColumn(appSettings.showColumnDate);
        await addSettingColumn(appSettings.showColumnKind);
        await addSettingColumn(appSettings.showColumnCreated);
        await addSettingColumn(appSettings.showColumnPermissions);
        await addSettingColumn(appSettings.showColumnOwner);
      }
      if (from < 30) {
        await addSettingColumn(appSettings.columnOrder);
      }
      if (from < 31) {
        await addSettingColumn(appSettings.quickLookUseSystemFont);
        await addSettingColumn(appSettings.quickLookFontFamily);
        await addSettingColumn(appSettings.quickLookFontSize);
        await addSettingColumn(appSettings.quickLookLineHeight);
        await addSettingColumn(appSettings.quickLookShowLineNumbers);
        await addSettingColumn(appSettings.quickLookVimMode);
      }
      if (from < 32) {
        await addSettingColumn(appSettings.quickLookWrapLines);
      }
      if (from < 33) {
        await addSettingColumn(appSettings.quickLookRelativeLineNumbers);
        await addSettingColumn(appSettings.quickLookShowStatistics);
      }
      if (from < 34) {
        await customStatement(
          "UPDATE app_settings SET show_column_kind = 1, column_order = 'kind,size,date,created,permissions,owner' WHERE show_column_size = 1 AND show_column_date = 1 AND show_column_kind = 0 AND show_column_created = 0 AND show_column_permissions = 0 AND show_column_owner = 0 AND column_order = 'size,date,kind,created,permissions,owner'",
        );
      }
      if (from < 35) {
        await addSettingColumn(appSettings.fileViewMode);
      }
      if (from < 36) {
        await addSettingColumn(appSettings.typeAheadBuffer);
      }
      if (from < 37) {
        await addSettingColumn(appSettings.showColumnAdded);
      }
      if (from < 38) {
        await addSettingColumn(appSettings.columnWidthMode);
        await addSettingColumn(appSettings.columnWidths);
      }
    },
  );

  Future<List<String>> getDisabledPlugins() {
    return select(disabledPlugins).map((r) => r.pluginId).get();
  }

  Future<void> setPluginDisabled(String pluginId, bool disabled) async {
    if (disabled) {
      await into(disabledPlugins).insertOnConflictUpdate(
        DisabledPluginsCompanion.insert(pluginId: pluginId),
      );
    } else {
      await (delete(
        disabledPlugins,
      )..where((t) => t.pluginId.equals(pluginId))).go();
    }
  }

  Future<List<PluginSetting>> getPluginSettings(String pluginId) {
    return (select(
      pluginSettings,
    )..where((t) => t.pluginId.equals(pluginId))).get();
  }

  Future<List<PluginSetting>> getAllPluginSettings() {
    return select(pluginSettings).get();
  }

  Future<void> setPluginSetting(String pluginId, String key, String value) {
    return into(pluginSettings).insertOnConflictUpdate(
      PluginSettingsCompanion.insert(
        pluginId: pluginId,
        key: key,
        value: value,
      ),
    );
  }

  Future<void> clearPluginSettings(String pluginId) {
    return (delete(
      pluginSettings,
    )..where((t) => t.pluginId.equals(pluginId))).go();
  }

  Future<List<ShortcutBinding>> getShortcutBindings() {
    return select(shortcutBindings).get();
  }

  Future<void> setShortcutBinding(ShortcutBindingsCompanion companion) {
    return into(shortcutBindings).insertOnConflictUpdate(companion);
  }

  Future<void> deleteShortcutBinding(String actionId) {
    return (delete(
      shortcutBindings,
    )..where((t) => t.actionId.equals(actionId))).go();
  }

  Future<void> clearShortcutBindings() {
    return delete(shortcutBindings).go();
  }

  Future<List<SidebarPref>> getSidebarPrefs() {
    return select(sidebarPrefs).get();
  }

  Future<void> setSidebarPref(
    String scope,
    String itemKey, {
    required int orderIndex,
    required bool hidden,
  }) {
    return into(sidebarPrefs).insertOnConflictUpdate(
      SidebarPrefsCompanion.insert(
        scope: scope,
        itemKey: itemKey,
        orderIndex: Value(orderIndex),
        hidden: Value(hidden),
      ),
    );
  }

  Future<void> setSidebarOrder(String scope, List<String> keysInOrder) async {
    await batch((b) {
      for (var i = 0; i < keysInOrder.length; i++) {
        final idx = i;
        b.insert(
          sidebarPrefs,
          SidebarPrefsCompanion.insert(
            scope: scope,
            itemKey: keysInOrder[idx],
            orderIndex: Value(idx),
          ),
          onConflict: DoUpdate(
            (_) => SidebarPrefsCompanion(orderIndex: Value(idx)),
          ),
        );
      }
    });
  }

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

  static const int _maxRecentEnteredPaths = 20;

  Future<List<String>> getRecentEnteredPaths({int limit = 20}) {
    return (select(recentEnteredPaths)
          ..orderBy([(t) => OrderingTerm.desc(t.usedAt)])
          ..limit(limit))
        .map((row) => row.path)
        .get();
  }

  Future<void> recordRecentEnteredPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    await into(recentEnteredPaths).insertOnConflictUpdate(
      RecentEnteredPathsCompanion.insert(
        path: trimmed,
        usedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    await _pruneRecentEnteredPaths();
  }

  Future<void> _pruneRecentEnteredPaths() async {
    final keep =
        await (select(recentEnteredPaths)
              ..orderBy([
                (t) => OrderingTerm.desc(t.usedAt),
                (t) => OrderingTerm.desc(t.path),
              ])
              ..limit(_maxRecentEnteredPaths))
            .map((row) => row.path)
            .get();
    if (keep.length < _maxRecentEnteredPaths) return;
    await (delete(recentEnteredPaths)..where((t) => t.path.isNotIn(keep))).go();
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

  Future<void> setFolderUiState(
    String path, {
    required String? cursorPath,
    required String? selectedPaths,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated =
        await (update(folderPrefs)..where((t) => t.path.equals(path))).write(
          FolderPrefsCompanion(
            cursorPath: Value(cursorPath),
            selectedPaths: Value(selectedPaths),
            updatedAt: Value(now),
          ),
        );
    if (updated == 0) {
      await into(folderPrefs).insert(
        FolderPrefsCompanion.insert(
          path: path,
          cursorPath: Value(cursorPath),
          selectedPaths: Value(selectedPaths),
          updatedAt: Value(now),
        ),
      );
    }
    await _pruneFolderPrefs();
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
