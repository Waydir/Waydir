import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:signals/signals.dart';

import '../database/app_database.dart';
import '../keyboard/keyboard_shortcuts.dart';
import '../logging/app_logger.dart';

class SettingsStore {
  static final SettingsStore instance = SettingsStore._();

  SettingsStore._();

  final themeId = signal<String>('dark');
  final terminal = signal<String>('builtin');
  final terminalShell = signal<String>('system');
  final terminalCustomCommand = signal<String>('');
  final terminalUseSystemFont = signal<bool>(true);
  final terminalFontFamily = signal<String>('');
  final terminalFontSize = signal<int>(13);
  final terminalLineHeight = signal<double>(1.2);
  final terminalCopyPasteMode = signal<String>(_defaultCopyPasteMode());
  final sessionIsDual = signal<bool>(false);
  final sessionSplitRatio = signal<double>(0.5);
  final sessionActivePaneIndex = signal<int>(0);
  final sidebarCollapsed = signal<bool>(false);
  final sidebarWidth = signal<double>(200.0);
  final restoreSession = signal<bool>(true);
  final defaultStartingPath = signal<String>('');
  final confirmDelete = signal<bool>(true);
  final confirmCopy = signal<bool>(false);
  final confirmMove = signal<bool>(true);
  final showHiddenDefault = signal<bool>(false);
  final dragMovesByDefault = signal<bool>(false);
  final rowDensity = signal<String>('comfortable');
  final fileListHorizontalSpacing = signal<int>(6);
  final fileListVerticalSpacing = signal<int>(6);
  final dateFormat = signal<String>('locale');
  final recentDatesRelative = signal<bool>(true);
  final deleteKeyBehavior = signal<String>('trash');
  final sortKey = signal<String>('name');
  final sortAscending = signal<bool>(true);
  final foldersFirst = signal<bool>(true);
  final naturalSort = signal<bool>(true);
  final sortFolders = signal<bool>(true);
  final searchMode = signal<String>('substring');
  final rememberFolderState = signal<bool>(true);
  final rememberFolderSort = signal<bool>(true);
  final typeAheadBuffer = signal<bool>(true);
  final fileListScale = signal<double>(1.0);
  final fileViewMode = signal<String>('list');
  final showColumnSize = signal<bool>(true);
  final showColumnDate = signal<bool>(true);
  final showColumnKind = signal<bool>(true);
  final showColumnCreated = signal<bool>(false);
  final showColumnAdded = signal<bool>(false);
  final showColumnPermissions = signal<bool>(false);
  final showColumnOwner = signal<bool>(false);
  final columnOrder = signal<String>(
    'kind,size,date,created,added,permissions,owner',
  );
  final columnWidthMode = signal<String>('automatic');
  final columnWidths = signal<String>('{}');
  final quickLookUseSystemFont = signal<bool>(true);
  final quickLookFontFamily = signal<String>('');
  final quickLookFontSize = signal<int>(13);
  final quickLookLineHeight = signal<double>(1.5);
  final quickLookShowLineNumbers = signal<bool>(false);
  final quickLookRelativeLineNumbers = signal<bool>(false);
  final quickLookVimMode = signal<bool>(false);
  final quickLookWrapLines = signal<bool>(true);
  final quickLookShowStatistics = signal<bool>(true);
  final shortcutBindings = signal<Map<String, KeyChord>>({});

  late final AppDatabase _db;
  bool _loaded = false;
  Timer? _saveDebounce;
  final _disposers = <void Function()>[];

  static String _defaultCopyPasteMode() {
    if (Platform.isMacOS) return 'standard';
    if (Platform.isLinux) return 'shift';

    return 'standard';
  }

  AppDatabase get db => _db;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    _db = AppDatabase();
    await _loadFromDb();
    _loaded = true;
    _wireAutoSave();
  }

  Future<void> _loadFromDb() async {
    final row = await _db.getSettings();
    themeId.value = row.themeMode == 'system' ? 'dark' : row.themeMode;
    terminal.value = row.terminal;
    terminalShell.value = row.terminalShell;
    terminalCustomCommand.value = row.terminalCustomCommand;
    terminalUseSystemFont.value = row.terminalUseSystemFont;
    terminalFontFamily.value = row.terminalFontFamily;
    terminalFontSize.value = row.terminalFontSize;
    terminalLineHeight.value = row.terminalLineHeight;
    terminalCopyPasteMode.value = row.terminalCopyPasteMode.isEmpty
        ? _defaultCopyPasteMode()
        : row.terminalCopyPasteMode;
    sessionIsDual.value = row.isDual;
    sessionSplitRatio.value = row.splitRatio;
    sessionActivePaneIndex.value = row.activePaneIndex;
    sidebarCollapsed.value = row.sidebarCollapsed;
    sidebarWidth.value = row.sidebarWidth;
    restoreSession.value = row.restoreSession;
    defaultStartingPath.value = row.defaultStartingPath;
    confirmDelete.value = row.confirmDelete;
    confirmCopy.value = row.confirmCopy;
    confirmMove.value = row.confirmMove;
    showHiddenDefault.value = row.showHiddenDefault;
    dragMovesByDefault.value = row.dragMovesByDefault;
    rowDensity.value = row.rowDensity;
    fileListHorizontalSpacing.value = row.fileListHorizontalSpacing;
    fileListVerticalSpacing.value = row.fileListVerticalSpacing;
    dateFormat.value = row.dateFormat;
    recentDatesRelative.value = row.recentDatesRelative;
    deleteKeyBehavior.value = row.deleteKeyBehavior;
    sortKey.value = row.sortKey;
    sortAscending.value = row.sortAscending;
    foldersFirst.value = row.foldersFirst;
    naturalSort.value = row.naturalSort;
    sortFolders.value = row.sortFolders;
    searchMode.value = row.searchMode;
    rememberFolderState.value = row.rememberFolderState;
    rememberFolderSort.value = row.rememberFolderSort;
    typeAheadBuffer.value = row.typeAheadBuffer;
    fileListScale.value = row.fileListScale;
    fileViewMode.value = row.fileViewMode;
    showColumnSize.value = row.showColumnSize;
    showColumnDate.value = row.showColumnDate;
    showColumnKind.value = row.showColumnKind;
    showColumnCreated.value = row.showColumnCreated;
    showColumnAdded.value = row.showColumnAdded;
    showColumnPermissions.value = row.showColumnPermissions;
    showColumnOwner.value = row.showColumnOwner;
    columnOrder.value = row.columnOrder;
    columnWidthMode.value = row.columnWidthMode;
    columnWidths.value = row.columnWidths;
    quickLookUseSystemFont.value = row.quickLookUseSystemFont;
    quickLookFontFamily.value = row.quickLookFontFamily;
    quickLookFontSize.value = row.quickLookFontSize;
    quickLookLineHeight.value = row.quickLookLineHeight;
    quickLookShowLineNumbers.value = row.quickLookShowLineNumbers;
    quickLookRelativeLineNumbers.value = row.quickLookRelativeLineNumbers;
    quickLookVimMode.value = row.quickLookVimMode;
    quickLookWrapLines.value = row.quickLookWrapLines;
    quickLookShowStatistics.value = row.quickLookShowStatistics;
    final shortcutRows = await _db.getShortcutBindings();
    final bindings = <String, KeyChord>{};
    for (final row in shortcutRows) {
      final def = AppShortcuts.getById(row.actionId);
      if (!def.editable) continue;
      bindings[row.actionId] = KeyChord(
        key: LogicalKeyboardKey(row.keyId),
        ctrl: row.ctrl,
        shift: row.shift,
        alt: row.alt,
      );
    }
    shortcutBindings.value = Map.unmodifiable(bindings);
    AppShortcuts.applyOverrides(bindings);
  }

  Future<void> setShortcutBinding(String actionId, KeyChord chord) async {
    final def = AppShortcuts.getById(actionId);
    if (!def.editable) return;
    final next = Map<String, KeyChord>.of(shortcutBindings.value);
    if (chord.sameChord(def.defaultBinding)) {
      next.remove(actionId);
      await _db.deleteShortcutBinding(actionId);
    } else {
      next[actionId] = chord;
      await _db.setShortcutBinding(
        ShortcutBindingsCompanion.insert(
          actionId: actionId,
          keyId: chord.key.keyId,
          ctrl: Value(chord.ctrl),
          shift: Value(chord.shift),
          alt: Value(chord.alt),
        ),
      );
    }
    shortcutBindings.value = Map.unmodifiable(next);
    AppShortcuts.applyOverrides(next);
  }

  Future<void> resetShortcutBinding(String actionId) async {
    final def = AppShortcuts.getById(actionId);
    if (!def.editable) return;
    final next = Map<String, KeyChord>.of(shortcutBindings.value)
      ..remove(actionId);
    await _db.deleteShortcutBinding(actionId);
    shortcutBindings.value = Map.unmodifiable(next);
    AppShortcuts.applyOverrides(next);
  }

  Future<void> resetShortcutBindings() async {
    await _db.clearShortcutBindings();
    shortcutBindings.value = const {};
    AppShortcuts.applyOverrides(const {});
  }

  void _wireAutoSave() {
    _disposers.add(
      effect(() {
        themeId.value;
        terminal.value;
        terminalShell.value;
        terminalCustomCommand.value;
        terminalUseSystemFont.value;
        terminalFontFamily.value;
        terminalFontSize.value;
        terminalLineHeight.value;
        terminalCopyPasteMode.value;
        sessionIsDual.value;
        sessionSplitRatio.value;
        sessionActivePaneIndex.value;
        sidebarCollapsed.value;
        sidebarWidth.value;
        restoreSession.value;
        defaultStartingPath.value;
        confirmDelete.value;
        confirmCopy.value;
        confirmMove.value;
        showHiddenDefault.value;
        dragMovesByDefault.value;
        rowDensity.value;
        fileListHorizontalSpacing.value;
        fileListVerticalSpacing.value;
        dateFormat.value;
        recentDatesRelative.value;
        deleteKeyBehavior.value;
        sortKey.value;
        sortAscending.value;
        foldersFirst.value;
        naturalSort.value;
        sortFolders.value;
        searchMode.value;
        rememberFolderState.value;
        rememberFolderSort.value;
        typeAheadBuffer.value;
        fileListScale.value;
        fileViewMode.value;
        showColumnSize.value;
        showColumnDate.value;
        showColumnKind.value;
        showColumnCreated.value;
        showColumnAdded.value;
        showColumnPermissions.value;
        showColumnOwner.value;
        columnOrder.value;
        columnWidthMode.value;
        columnWidths.value;
        quickLookUseSystemFont.value;
        quickLookFontFamily.value;
        quickLookFontSize.value;
        quickLookLineHeight.value;
        quickLookShowLineNumbers.value;
        quickLookRelativeLineNumbers.value;
        quickLookVimMode.value;
        quickLookWrapLines.value;
        quickLookShowStatistics.value;
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
          themeMode: Value(themeId.value),
          terminal: Value(terminal.value),
          terminalShell: Value(terminalShell.value),
          terminalCustomCommand: Value(terminalCustomCommand.value),
          terminalUseSystemFont: Value(terminalUseSystemFont.value),
          terminalFontFamily: Value(terminalFontFamily.value),
          terminalFontSize: Value(terminalFontSize.value),
          terminalLineHeight: Value(terminalLineHeight.value),
          terminalCopyPasteMode: Value(terminalCopyPasteMode.value),
          isDual: Value(sessionIsDual.value),
          splitRatio: Value(sessionSplitRatio.value),
          activePaneIndex: Value(sessionActivePaneIndex.value),
          sidebarCollapsed: Value(sidebarCollapsed.value),
          sidebarWidth: Value(sidebarWidth.value),
          restoreSession: Value(restoreSession.value),
          defaultStartingPath: Value(defaultStartingPath.value),
          confirmDelete: Value(confirmDelete.value),
          confirmCopy: Value(confirmCopy.value),
          confirmMove: Value(confirmMove.value),
          showHiddenDefault: Value(showHiddenDefault.value),
          dragMovesByDefault: Value(dragMovesByDefault.value),
          rowDensity: Value(rowDensity.value),
          fileListHorizontalSpacing: Value(fileListHorizontalSpacing.value),
          fileListVerticalSpacing: Value(fileListVerticalSpacing.value),
          dateFormat: Value(dateFormat.value),
          recentDatesRelative: Value(recentDatesRelative.value),
          deleteKeyBehavior: Value(deleteKeyBehavior.value),
          sortKey: Value(sortKey.value),
          sortAscending: Value(sortAscending.value),
          foldersFirst: Value(foldersFirst.value),
          naturalSort: Value(naturalSort.value),
          sortFolders: Value(sortFolders.value),
          searchMode: Value(searchMode.value),
          rememberFolderState: Value(rememberFolderState.value),
          rememberFolderSort: Value(rememberFolderSort.value),
          typeAheadBuffer: Value(typeAheadBuffer.value),
          fileListScale: Value(fileListScale.value),
          fileViewMode: Value(fileViewMode.value),
          showColumnSize: Value(showColumnSize.value),
          showColumnDate: Value(showColumnDate.value),
          showColumnKind: Value(showColumnKind.value),
          showColumnCreated: Value(showColumnCreated.value),
          showColumnAdded: Value(showColumnAdded.value),
          showColumnPermissions: Value(showColumnPermissions.value),
          showColumnOwner: Value(showColumnOwner.value),
          columnOrder: Value(columnOrder.value),
          columnWidthMode: Value(columnWidthMode.value),
          columnWidths: Value(columnWidths.value),
          quickLookUseSystemFont: Value(quickLookUseSystemFont.value),
          quickLookFontFamily: Value(quickLookFontFamily.value),
          quickLookFontSize: Value(quickLookFontSize.value),
          quickLookLineHeight: Value(quickLookLineHeight.value),
          quickLookShowLineNumbers: Value(quickLookShowLineNumbers.value),
          quickLookRelativeLineNumbers: Value(
            quickLookRelativeLineNumbers.value,
          ),
          quickLookVimMode: Value(quickLookVimMode.value),
          quickLookWrapLines: Value(quickLookWrapLines.value),
          quickLookShowStatistics: Value(quickLookShowStatistics.value),
        ),
      );
    } catch (e, st) {
      log.error('settings', 'failed to save settings', error: e, stack: st);
    }
  }

  static const terminalFontSizes = [10, 11, 12, 13, 14, 15, 16, 18, 20, 22, 24];
  static const defaultTerminalFontSize = 13;

  void increaseTerminalFontSize() => _stepTerminalFontSize(1);

  void decreaseTerminalFontSize() => _stepTerminalFontSize(-1);

  void resetTerminalFontSize() =>
      terminalFontSize.value = defaultTerminalFontSize;

  void _stepTerminalFontSize(int direction) {
    final sizes = terminalFontSizes;
    final current = terminalFontSize.value;
    var index = sizes.indexOf(current);
    if (index < 0) {
      index = sizes.indexWhere((s) => s >= current);
      if (index < 0) index = sizes.length - 1;
    }
    final next = (index + direction).clamp(0, sizes.length - 1);
    terminalFontSize.value = sizes[next];
  }

  static const fileListScaleMin = 0.5;
  static const fileListScaleMax = 2.0;
  static const fileListScaleStep = 0.1;
  static const defaultFileListScale = 1.0;

  void increaseFileListScale() => _stepFileListScale(1);

  void decreaseFileListScale() => _stepFileListScale(-1);

  void resetFileListScale() => fileListScale.value = defaultFileListScale;

  void _stepFileListScale(int direction) {
    final steps = (fileListScale.value / fileListScaleStep).round();
    final next = (steps + direction) * fileListScaleStep;
    fileListScale.value = next.clamp(fileListScaleMin, fileListScaleMax);
  }

  void dispose() {
    for (final d in _disposers) {
      d();
    }
    _disposers.clear();
    _saveDebounce?.cancel();
  }
}
