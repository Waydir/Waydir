import 'dart:async';

import 'package:drift/drift.dart';
import 'package:signals/signals.dart';

import '../database/app_database.dart';

class SettingsStore {
  static final SettingsStore instance = SettingsStore._();

  SettingsStore._();

  final themeMode = signal<String>('system');
  final terminal = signal<String>('auto');
  final terminalCustomCommand = signal<String>('');
  final sessionIsDual = signal<bool>(false);
  final sessionSplitRatio = signal<double>(0.5);
  final sessionActivePaneIndex = signal<int>(0);
  final sidebarCollapsed = signal<bool>(false);
  final restoreSession = signal<bool>(true);
  final defaultStartingPath = signal<String>('');
  final confirmDelete = signal<bool>(true);
  final showHiddenDefault = signal<bool>(false);
  final rowDensity = signal<String>('comfortable');
  final dateFormat = signal<String>('locale');
  final recentDatesRelative = signal<bool>(true);
  final deleteKeyBehavior = signal<String>('trash');
  final sortKey = signal<String>('name');
  final sortAscending = signal<bool>(true);
  final foldersFirst = signal<bool>(true);

  late final AppDatabase _db;
  bool _loaded = false;
  Timer? _saveDebounce;
  final _disposers = <void Function()>[];

  AppDatabase get db => _db;

  Future<void> load() async {
    if (_loaded) return;
    _db = AppDatabase();
    await _loadFromDb();
    _loaded = true;
    _wireAutoSave();
  }

  Future<void> _loadFromDb() async {
    final row = await _db.getSettings();
    themeMode.value = row.themeMode;
    terminal.value = row.terminal;
    terminalCustomCommand.value = row.terminalCustomCommand;
    sessionIsDual.value = row.isDual;
    sessionSplitRatio.value = row.splitRatio;
    sessionActivePaneIndex.value = row.activePaneIndex;
    sidebarCollapsed.value = row.sidebarCollapsed;
    restoreSession.value = row.restoreSession;
    defaultStartingPath.value = row.defaultStartingPath;
    confirmDelete.value = row.confirmDelete;
    showHiddenDefault.value = row.showHiddenDefault;
    rowDensity.value = row.rowDensity;
    dateFormat.value = row.dateFormat;
    recentDatesRelative.value = row.recentDatesRelative;
    deleteKeyBehavior.value = row.deleteKeyBehavior;
    sortKey.value = row.sortKey;
    sortAscending.value = row.sortAscending;
    foldersFirst.value = row.foldersFirst;
  }

  void _wireAutoSave() {
    _disposers.add(
      effect(() {
        themeMode.value;
        terminal.value;
        terminalCustomCommand.value;
        sessionIsDual.value;
        sessionSplitRatio.value;
        sessionActivePaneIndex.value;
        sidebarCollapsed.value;
        restoreSession.value;
        defaultStartingPath.value;
        confirmDelete.value;
        showHiddenDefault.value;
        rowDensity.value;
        dateFormat.value;
        recentDatesRelative.value;
        deleteKeyBehavior.value;
        sortKey.value;
        sortAscending.value;
        foldersFirst.value;
        if (!_loaded) return;
        _scheduleSave();
      }),
    );
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 200), _save);
  }

  Future<void> _save() async {
    try {
      await _db.updateSettings(
        AppSettingsCompanion(
          themeMode: Value(themeMode.value),
          terminal: Value(terminal.value),
          terminalCustomCommand: Value(terminalCustomCommand.value),
          isDual: Value(sessionIsDual.value),
          splitRatio: Value(sessionSplitRatio.value),
          activePaneIndex: Value(sessionActivePaneIndex.value),
          sidebarCollapsed: Value(sidebarCollapsed.value),
          restoreSession: Value(restoreSession.value),
          defaultStartingPath: Value(defaultStartingPath.value),
          confirmDelete: Value(confirmDelete.value),
          showHiddenDefault: Value(showHiddenDefault.value),
          rowDensity: Value(rowDensity.value),
          dateFormat: Value(dateFormat.value),
          recentDatesRelative: Value(recentDatesRelative.value),
          deleteKeyBehavior: Value(deleteKeyBehavior.value),
          sortKey: Value(sortKey.value),
          sortAscending: Value(sortAscending.value),
          foldersFirst: Value(foldersFirst.value),
        ),
      );
    } catch (_) {}
  }

  void dispose() {
    for (final d in _disposers) {
      d();
    }
    _disposers.clear();
    _saveDebounce?.cancel();
  }
}
