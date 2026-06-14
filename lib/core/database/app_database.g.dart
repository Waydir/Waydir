// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dark'),
  );
  static const VerificationMeta _terminalMeta = const VerificationMeta(
    'terminal',
  );
  @override
  late final GeneratedColumn<String> terminal = GeneratedColumn<String>(
    'terminal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('builtin'),
  );
  static const VerificationMeta _terminalShellMeta = const VerificationMeta(
    'terminalShell',
  );
  @override
  late final GeneratedColumn<String> terminalShell = GeneratedColumn<String>(
    'terminal_shell',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('system'),
  );
  static const VerificationMeta _terminalCustomCommandMeta =
      const VerificationMeta('terminalCustomCommand');
  @override
  late final GeneratedColumn<String> terminalCustomCommand =
      GeneratedColumn<String>(
        'terminal_custom_command',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _terminalUseSystemFontMeta =
      const VerificationMeta('terminalUseSystemFont');
  @override
  late final GeneratedColumn<bool> terminalUseSystemFont =
      GeneratedColumn<bool>(
        'terminal_use_system_font',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("terminal_use_system_font" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _terminalFontFamilyMeta =
      const VerificationMeta('terminalFontFamily');
  @override
  late final GeneratedColumn<String> terminalFontFamily =
      GeneratedColumn<String>(
        'terminal_font_family',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _terminalFontSizeMeta = const VerificationMeta(
    'terminalFontSize',
  );
  @override
  late final GeneratedColumn<int> terminalFontSize = GeneratedColumn<int>(
    'terminal_font_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(13),
  );
  static const VerificationMeta _terminalLineHeightMeta =
      const VerificationMeta('terminalLineHeight');
  @override
  late final GeneratedColumn<double> terminalLineHeight =
      GeneratedColumn<double>(
        'terminal_line_height',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1.2),
      );
  static const VerificationMeta _isDualMeta = const VerificationMeta('isDual');
  @override
  late final GeneratedColumn<bool> isDual = GeneratedColumn<bool>(
    'is_dual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dual" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _splitRatioMeta = const VerificationMeta(
    'splitRatio',
  );
  @override
  late final GeneratedColumn<double> splitRatio = GeneratedColumn<double>(
    'split_ratio',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _activePaneIndexMeta = const VerificationMeta(
    'activePaneIndex',
  );
  @override
  late final GeneratedColumn<int> activePaneIndex = GeneratedColumn<int>(
    'active_pane_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sidebarCollapsedMeta = const VerificationMeta(
    'sidebarCollapsed',
  );
  @override
  late final GeneratedColumn<bool> sidebarCollapsed = GeneratedColumn<bool>(
    'sidebar_collapsed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sidebar_collapsed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sidebarWidthMeta = const VerificationMeta(
    'sidebarWidth',
  );
  @override
  late final GeneratedColumn<double> sidebarWidth = GeneratedColumn<double>(
    'sidebar_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(200.0),
  );
  static const VerificationMeta _restoreSessionMeta = const VerificationMeta(
    'restoreSession',
  );
  @override
  late final GeneratedColumn<bool> restoreSession = GeneratedColumn<bool>(
    'restore_session',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("restore_session" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _defaultStartingPathMeta =
      const VerificationMeta('defaultStartingPath');
  @override
  late final GeneratedColumn<String> defaultStartingPath =
      GeneratedColumn<String>(
        'default_starting_path',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _confirmDeleteMeta = const VerificationMeta(
    'confirmDelete',
  );
  @override
  late final GeneratedColumn<bool> confirmDelete = GeneratedColumn<bool>(
    'confirm_delete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirm_delete" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _confirmCopyMeta = const VerificationMeta(
    'confirmCopy',
  );
  @override
  late final GeneratedColumn<bool> confirmCopy = GeneratedColumn<bool>(
    'confirm_copy',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirm_copy" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _confirmMoveMeta = const VerificationMeta(
    'confirmMove',
  );
  @override
  late final GeneratedColumn<bool> confirmMove = GeneratedColumn<bool>(
    'confirm_move',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("confirm_move" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showHiddenDefaultMeta = const VerificationMeta(
    'showHiddenDefault',
  );
  @override
  late final GeneratedColumn<bool> showHiddenDefault = GeneratedColumn<bool>(
    'show_hidden_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_hidden_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rowDensityMeta = const VerificationMeta(
    'rowDensity',
  );
  @override
  late final GeneratedColumn<String> rowDensity = GeneratedColumn<String>(
    'row_density',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('comfortable'),
  );
  static const VerificationMeta _fileListHorizontalSpacingMeta =
      const VerificationMeta('fileListHorizontalSpacing');
  @override
  late final GeneratedColumn<int> fileListHorizontalSpacing =
      GeneratedColumn<int>(
        'file_list_horizontal_spacing',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(6),
      );
  static const VerificationMeta _fileListVerticalSpacingMeta =
      const VerificationMeta('fileListVerticalSpacing');
  @override
  late final GeneratedColumn<int> fileListVerticalSpacing =
      GeneratedColumn<int>(
        'file_list_vertical_spacing',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(6),
      );
  static const VerificationMeta _dateFormatMeta = const VerificationMeta(
    'dateFormat',
  );
  @override
  late final GeneratedColumn<String> dateFormat = GeneratedColumn<String>(
    'date_format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('locale'),
  );
  static const VerificationMeta _recentDatesRelativeMeta =
      const VerificationMeta('recentDatesRelative');
  @override
  late final GeneratedColumn<bool> recentDatesRelative = GeneratedColumn<bool>(
    'recent_dates_relative',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("recent_dates_relative" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _deleteKeyBehaviorMeta = const VerificationMeta(
    'deleteKeyBehavior',
  );
  @override
  late final GeneratedColumn<String> deleteKeyBehavior =
      GeneratedColumn<String>(
        'delete_key_behavior',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('trash'),
      );
  static const VerificationMeta _sortKeyMeta = const VerificationMeta(
    'sortKey',
  );
  @override
  late final GeneratedColumn<String> sortKey = GeneratedColumn<String>(
    'sort_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('name'),
  );
  static const VerificationMeta _sortAscendingMeta = const VerificationMeta(
    'sortAscending',
  );
  @override
  late final GeneratedColumn<bool> sortAscending = GeneratedColumn<bool>(
    'sort_ascending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sort_ascending" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _foldersFirstMeta = const VerificationMeta(
    'foldersFirst',
  );
  @override
  late final GeneratedColumn<bool> foldersFirst = GeneratedColumn<bool>(
    'folders_first',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("folders_first" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _naturalSortMeta = const VerificationMeta(
    'naturalSort',
  );
  @override
  late final GeneratedColumn<bool> naturalSort = GeneratedColumn<bool>(
    'natural_sort',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("natural_sort" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortFoldersMeta = const VerificationMeta(
    'sortFolders',
  );
  @override
  late final GeneratedColumn<bool> sortFolders = GeneratedColumn<bool>(
    'sort_folders',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sort_folders" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _searchModeMeta = const VerificationMeta(
    'searchMode',
  );
  @override
  late final GeneratedColumn<String> searchMode = GeneratedColumn<String>(
    'search_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('substring'),
  );
  static const VerificationMeta _rememberFolderStateMeta =
      const VerificationMeta('rememberFolderState');
  @override
  late final GeneratedColumn<bool> rememberFolderState = GeneratedColumn<bool>(
    'remember_folder_state',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remember_folder_state" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _rememberFolderSortMeta =
      const VerificationMeta('rememberFolderSort');
  @override
  late final GeneratedColumn<bool> rememberFolderSort = GeneratedColumn<bool>(
    'remember_folder_sort',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remember_folder_sort" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _typeAheadBufferMeta = const VerificationMeta(
    'typeAheadBuffer',
  );
  @override
  late final GeneratedColumn<bool> typeAheadBuffer = GeneratedColumn<bool>(
    'type_ahead_buffer',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("type_ahead_buffer" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _fileListScaleMeta = const VerificationMeta(
    'fileListScale',
  );
  @override
  late final GeneratedColumn<double> fileListScale = GeneratedColumn<double>(
    'file_list_scale',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _fileViewModeMeta = const VerificationMeta(
    'fileViewMode',
  );
  @override
  late final GeneratedColumn<String> fileViewMode = GeneratedColumn<String>(
    'file_view_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('list'),
  );
  static const VerificationMeta _showColumnSizeMeta = const VerificationMeta(
    'showColumnSize',
  );
  @override
  late final GeneratedColumn<bool> showColumnSize = GeneratedColumn<bool>(
    'show_column_size',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_column_size" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showColumnDateMeta = const VerificationMeta(
    'showColumnDate',
  );
  @override
  late final GeneratedColumn<bool> showColumnDate = GeneratedColumn<bool>(
    'show_column_date',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_column_date" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showColumnKindMeta = const VerificationMeta(
    'showColumnKind',
  );
  @override
  late final GeneratedColumn<bool> showColumnKind = GeneratedColumn<bool>(
    'show_column_kind',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_column_kind" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showColumnCreatedMeta = const VerificationMeta(
    'showColumnCreated',
  );
  @override
  late final GeneratedColumn<bool> showColumnCreated = GeneratedColumn<bool>(
    'show_column_created',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_column_created" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showColumnPermissionsMeta =
      const VerificationMeta('showColumnPermissions');
  @override
  late final GeneratedColumn<bool> showColumnPermissions =
      GeneratedColumn<bool>(
        'show_column_permissions',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_column_permissions" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _showColumnOwnerMeta = const VerificationMeta(
    'showColumnOwner',
  );
  @override
  late final GeneratedColumn<bool> showColumnOwner = GeneratedColumn<bool>(
    'show_column_owner',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_column_owner" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _columnOrderMeta = const VerificationMeta(
    'columnOrder',
  );
  @override
  late final GeneratedColumn<String> columnOrder = GeneratedColumn<String>(
    'column_order',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('kind,size,date,created,permissions,owner'),
  );
  static const VerificationMeta _quickLookUseSystemFontMeta =
      const VerificationMeta('quickLookUseSystemFont');
  @override
  late final GeneratedColumn<bool> quickLookUseSystemFont =
      GeneratedColumn<bool>(
        'quick_look_use_system_font',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("quick_look_use_system_font" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  static const VerificationMeta _quickLookFontFamilyMeta =
      const VerificationMeta('quickLookFontFamily');
  @override
  late final GeneratedColumn<String> quickLookFontFamily =
      GeneratedColumn<String>(
        'quick_look_font_family',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant(''),
      );
  static const VerificationMeta _quickLookFontSizeMeta = const VerificationMeta(
    'quickLookFontSize',
  );
  @override
  late final GeneratedColumn<int> quickLookFontSize = GeneratedColumn<int>(
    'quick_look_font_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(13),
  );
  static const VerificationMeta _quickLookLineHeightMeta =
      const VerificationMeta('quickLookLineHeight');
  @override
  late final GeneratedColumn<double> quickLookLineHeight =
      GeneratedColumn<double>(
        'quick_look_line_height',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1.5),
      );
  static const VerificationMeta _quickLookShowLineNumbersMeta =
      const VerificationMeta('quickLookShowLineNumbers');
  @override
  late final GeneratedColumn<bool> quickLookShowLineNumbers =
      GeneratedColumn<bool>(
        'quick_look_show_line_numbers',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("quick_look_show_line_numbers" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _quickLookRelativeLineNumbersMeta =
      const VerificationMeta('quickLookRelativeLineNumbers');
  @override
  late final GeneratedColumn<bool> quickLookRelativeLineNumbers =
      GeneratedColumn<bool>(
        'quick_look_relative_line_numbers',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("quick_look_relative_line_numbers" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _quickLookVimModeMeta = const VerificationMeta(
    'quickLookVimMode',
  );
  @override
  late final GeneratedColumn<bool> quickLookVimMode = GeneratedColumn<bool>(
    'quick_look_vim_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quick_look_vim_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _quickLookWrapLinesMeta =
      const VerificationMeta('quickLookWrapLines');
  @override
  late final GeneratedColumn<bool> quickLookWrapLines = GeneratedColumn<bool>(
    'quick_look_wrap_lines',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("quick_look_wrap_lines" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _quickLookShowStatisticsMeta =
      const VerificationMeta('quickLookShowStatistics');
  @override
  late final GeneratedColumn<bool> quickLookShowStatistics =
      GeneratedColumn<bool>(
        'quick_look_show_statistics',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("quick_look_show_statistics" IN (0, 1))',
        ),
        defaultValue: const Constant(true),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themeMode,
    terminal,
    terminalShell,
    terminalCustomCommand,
    terminalUseSystemFont,
    terminalFontFamily,
    terminalFontSize,
    terminalLineHeight,
    isDual,
    splitRatio,
    activePaneIndex,
    sidebarCollapsed,
    sidebarWidth,
    restoreSession,
    defaultStartingPath,
    confirmDelete,
    confirmCopy,
    confirmMove,
    showHiddenDefault,
    rowDensity,
    fileListHorizontalSpacing,
    fileListVerticalSpacing,
    dateFormat,
    recentDatesRelative,
    deleteKeyBehavior,
    sortKey,
    sortAscending,
    foldersFirst,
    naturalSort,
    sortFolders,
    searchMode,
    rememberFolderState,
    rememberFolderSort,
    typeAheadBuffer,
    fileListScale,
    fileViewMode,
    showColumnSize,
    showColumnDate,
    showColumnKind,
    showColumnCreated,
    showColumnPermissions,
    showColumnOwner,
    columnOrder,
    quickLookUseSystemFont,
    quickLookFontFamily,
    quickLookFontSize,
    quickLookLineHeight,
    quickLookShowLineNumbers,
    quickLookRelativeLineNumbers,
    quickLookVimMode,
    quickLookWrapLines,
    quickLookShowStatistics,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('terminal')) {
      context.handle(
        _terminalMeta,
        terminal.isAcceptableOrUnknown(data['terminal']!, _terminalMeta),
      );
    }
    if (data.containsKey('terminal_shell')) {
      context.handle(
        _terminalShellMeta,
        terminalShell.isAcceptableOrUnknown(
          data['terminal_shell']!,
          _terminalShellMeta,
        ),
      );
    }
    if (data.containsKey('terminal_custom_command')) {
      context.handle(
        _terminalCustomCommandMeta,
        terminalCustomCommand.isAcceptableOrUnknown(
          data['terminal_custom_command']!,
          _terminalCustomCommandMeta,
        ),
      );
    }
    if (data.containsKey('terminal_use_system_font')) {
      context.handle(
        _terminalUseSystemFontMeta,
        terminalUseSystemFont.isAcceptableOrUnknown(
          data['terminal_use_system_font']!,
          _terminalUseSystemFontMeta,
        ),
      );
    }
    if (data.containsKey('terminal_font_family')) {
      context.handle(
        _terminalFontFamilyMeta,
        terminalFontFamily.isAcceptableOrUnknown(
          data['terminal_font_family']!,
          _terminalFontFamilyMeta,
        ),
      );
    }
    if (data.containsKey('terminal_font_size')) {
      context.handle(
        _terminalFontSizeMeta,
        terminalFontSize.isAcceptableOrUnknown(
          data['terminal_font_size']!,
          _terminalFontSizeMeta,
        ),
      );
    }
    if (data.containsKey('terminal_line_height')) {
      context.handle(
        _terminalLineHeightMeta,
        terminalLineHeight.isAcceptableOrUnknown(
          data['terminal_line_height']!,
          _terminalLineHeightMeta,
        ),
      );
    }
    if (data.containsKey('is_dual')) {
      context.handle(
        _isDualMeta,
        isDual.isAcceptableOrUnknown(data['is_dual']!, _isDualMeta),
      );
    }
    if (data.containsKey('split_ratio')) {
      context.handle(
        _splitRatioMeta,
        splitRatio.isAcceptableOrUnknown(data['split_ratio']!, _splitRatioMeta),
      );
    }
    if (data.containsKey('active_pane_index')) {
      context.handle(
        _activePaneIndexMeta,
        activePaneIndex.isAcceptableOrUnknown(
          data['active_pane_index']!,
          _activePaneIndexMeta,
        ),
      );
    }
    if (data.containsKey('sidebar_collapsed')) {
      context.handle(
        _sidebarCollapsedMeta,
        sidebarCollapsed.isAcceptableOrUnknown(
          data['sidebar_collapsed']!,
          _sidebarCollapsedMeta,
        ),
      );
    }
    if (data.containsKey('sidebar_width')) {
      context.handle(
        _sidebarWidthMeta,
        sidebarWidth.isAcceptableOrUnknown(
          data['sidebar_width']!,
          _sidebarWidthMeta,
        ),
      );
    }
    if (data.containsKey('restore_session')) {
      context.handle(
        _restoreSessionMeta,
        restoreSession.isAcceptableOrUnknown(
          data['restore_session']!,
          _restoreSessionMeta,
        ),
      );
    }
    if (data.containsKey('default_starting_path')) {
      context.handle(
        _defaultStartingPathMeta,
        defaultStartingPath.isAcceptableOrUnknown(
          data['default_starting_path']!,
          _defaultStartingPathMeta,
        ),
      );
    }
    if (data.containsKey('confirm_delete')) {
      context.handle(
        _confirmDeleteMeta,
        confirmDelete.isAcceptableOrUnknown(
          data['confirm_delete']!,
          _confirmDeleteMeta,
        ),
      );
    }
    if (data.containsKey('confirm_copy')) {
      context.handle(
        _confirmCopyMeta,
        confirmCopy.isAcceptableOrUnknown(
          data['confirm_copy']!,
          _confirmCopyMeta,
        ),
      );
    }
    if (data.containsKey('confirm_move')) {
      context.handle(
        _confirmMoveMeta,
        confirmMove.isAcceptableOrUnknown(
          data['confirm_move']!,
          _confirmMoveMeta,
        ),
      );
    }
    if (data.containsKey('show_hidden_default')) {
      context.handle(
        _showHiddenDefaultMeta,
        showHiddenDefault.isAcceptableOrUnknown(
          data['show_hidden_default']!,
          _showHiddenDefaultMeta,
        ),
      );
    }
    if (data.containsKey('row_density')) {
      context.handle(
        _rowDensityMeta,
        rowDensity.isAcceptableOrUnknown(data['row_density']!, _rowDensityMeta),
      );
    }
    if (data.containsKey('file_list_horizontal_spacing')) {
      context.handle(
        _fileListHorizontalSpacingMeta,
        fileListHorizontalSpacing.isAcceptableOrUnknown(
          data['file_list_horizontal_spacing']!,
          _fileListHorizontalSpacingMeta,
        ),
      );
    }
    if (data.containsKey('file_list_vertical_spacing')) {
      context.handle(
        _fileListVerticalSpacingMeta,
        fileListVerticalSpacing.isAcceptableOrUnknown(
          data['file_list_vertical_spacing']!,
          _fileListVerticalSpacingMeta,
        ),
      );
    }
    if (data.containsKey('date_format')) {
      context.handle(
        _dateFormatMeta,
        dateFormat.isAcceptableOrUnknown(data['date_format']!, _dateFormatMeta),
      );
    }
    if (data.containsKey('recent_dates_relative')) {
      context.handle(
        _recentDatesRelativeMeta,
        recentDatesRelative.isAcceptableOrUnknown(
          data['recent_dates_relative']!,
          _recentDatesRelativeMeta,
        ),
      );
    }
    if (data.containsKey('delete_key_behavior')) {
      context.handle(
        _deleteKeyBehaviorMeta,
        deleteKeyBehavior.isAcceptableOrUnknown(
          data['delete_key_behavior']!,
          _deleteKeyBehaviorMeta,
        ),
      );
    }
    if (data.containsKey('sort_key')) {
      context.handle(
        _sortKeyMeta,
        sortKey.isAcceptableOrUnknown(data['sort_key']!, _sortKeyMeta),
      );
    }
    if (data.containsKey('sort_ascending')) {
      context.handle(
        _sortAscendingMeta,
        sortAscending.isAcceptableOrUnknown(
          data['sort_ascending']!,
          _sortAscendingMeta,
        ),
      );
    }
    if (data.containsKey('folders_first')) {
      context.handle(
        _foldersFirstMeta,
        foldersFirst.isAcceptableOrUnknown(
          data['folders_first']!,
          _foldersFirstMeta,
        ),
      );
    }
    if (data.containsKey('natural_sort')) {
      context.handle(
        _naturalSortMeta,
        naturalSort.isAcceptableOrUnknown(
          data['natural_sort']!,
          _naturalSortMeta,
        ),
      );
    }
    if (data.containsKey('sort_folders')) {
      context.handle(
        _sortFoldersMeta,
        sortFolders.isAcceptableOrUnknown(
          data['sort_folders']!,
          _sortFoldersMeta,
        ),
      );
    }
    if (data.containsKey('search_mode')) {
      context.handle(
        _searchModeMeta,
        searchMode.isAcceptableOrUnknown(data['search_mode']!, _searchModeMeta),
      );
    }
    if (data.containsKey('remember_folder_state')) {
      context.handle(
        _rememberFolderStateMeta,
        rememberFolderState.isAcceptableOrUnknown(
          data['remember_folder_state']!,
          _rememberFolderStateMeta,
        ),
      );
    }
    if (data.containsKey('remember_folder_sort')) {
      context.handle(
        _rememberFolderSortMeta,
        rememberFolderSort.isAcceptableOrUnknown(
          data['remember_folder_sort']!,
          _rememberFolderSortMeta,
        ),
      );
    }
    if (data.containsKey('type_ahead_buffer')) {
      context.handle(
        _typeAheadBufferMeta,
        typeAheadBuffer.isAcceptableOrUnknown(
          data['type_ahead_buffer']!,
          _typeAheadBufferMeta,
        ),
      );
    }
    if (data.containsKey('file_list_scale')) {
      context.handle(
        _fileListScaleMeta,
        fileListScale.isAcceptableOrUnknown(
          data['file_list_scale']!,
          _fileListScaleMeta,
        ),
      );
    }
    if (data.containsKey('file_view_mode')) {
      context.handle(
        _fileViewModeMeta,
        fileViewMode.isAcceptableOrUnknown(
          data['file_view_mode']!,
          _fileViewModeMeta,
        ),
      );
    }
    if (data.containsKey('show_column_size')) {
      context.handle(
        _showColumnSizeMeta,
        showColumnSize.isAcceptableOrUnknown(
          data['show_column_size']!,
          _showColumnSizeMeta,
        ),
      );
    }
    if (data.containsKey('show_column_date')) {
      context.handle(
        _showColumnDateMeta,
        showColumnDate.isAcceptableOrUnknown(
          data['show_column_date']!,
          _showColumnDateMeta,
        ),
      );
    }
    if (data.containsKey('show_column_kind')) {
      context.handle(
        _showColumnKindMeta,
        showColumnKind.isAcceptableOrUnknown(
          data['show_column_kind']!,
          _showColumnKindMeta,
        ),
      );
    }
    if (data.containsKey('show_column_created')) {
      context.handle(
        _showColumnCreatedMeta,
        showColumnCreated.isAcceptableOrUnknown(
          data['show_column_created']!,
          _showColumnCreatedMeta,
        ),
      );
    }
    if (data.containsKey('show_column_permissions')) {
      context.handle(
        _showColumnPermissionsMeta,
        showColumnPermissions.isAcceptableOrUnknown(
          data['show_column_permissions']!,
          _showColumnPermissionsMeta,
        ),
      );
    }
    if (data.containsKey('show_column_owner')) {
      context.handle(
        _showColumnOwnerMeta,
        showColumnOwner.isAcceptableOrUnknown(
          data['show_column_owner']!,
          _showColumnOwnerMeta,
        ),
      );
    }
    if (data.containsKey('column_order')) {
      context.handle(
        _columnOrderMeta,
        columnOrder.isAcceptableOrUnknown(
          data['column_order']!,
          _columnOrderMeta,
        ),
      );
    }
    if (data.containsKey('quick_look_use_system_font')) {
      context.handle(
        _quickLookUseSystemFontMeta,
        quickLookUseSystemFont.isAcceptableOrUnknown(
          data['quick_look_use_system_font']!,
          _quickLookUseSystemFontMeta,
        ),
      );
    }
    if (data.containsKey('quick_look_font_family')) {
      context.handle(
        _quickLookFontFamilyMeta,
        quickLookFontFamily.isAcceptableOrUnknown(
          data['quick_look_font_family']!,
          _quickLookFontFamilyMeta,
        ),
      );
    }
    if (data.containsKey('quick_look_font_size')) {
      context.handle(
        _quickLookFontSizeMeta,
        quickLookFontSize.isAcceptableOrUnknown(
          data['quick_look_font_size']!,
          _quickLookFontSizeMeta,
        ),
      );
    }
    if (data.containsKey('quick_look_line_height')) {
      context.handle(
        _quickLookLineHeightMeta,
        quickLookLineHeight.isAcceptableOrUnknown(
          data['quick_look_line_height']!,
          _quickLookLineHeightMeta,
        ),
      );
    }
    if (data.containsKey('quick_look_show_line_numbers')) {
      context.handle(
        _quickLookShowLineNumbersMeta,
        quickLookShowLineNumbers.isAcceptableOrUnknown(
          data['quick_look_show_line_numbers']!,
          _quickLookShowLineNumbersMeta,
        ),
      );
    }
    if (data.containsKey('quick_look_relative_line_numbers')) {
      context.handle(
        _quickLookRelativeLineNumbersMeta,
        quickLookRelativeLineNumbers.isAcceptableOrUnknown(
          data['quick_look_relative_line_numbers']!,
          _quickLookRelativeLineNumbersMeta,
        ),
      );
    }
    if (data.containsKey('quick_look_vim_mode')) {
      context.handle(
        _quickLookVimModeMeta,
        quickLookVimMode.isAcceptableOrUnknown(
          data['quick_look_vim_mode']!,
          _quickLookVimModeMeta,
        ),
      );
    }
    if (data.containsKey('quick_look_wrap_lines')) {
      context.handle(
        _quickLookWrapLinesMeta,
        quickLookWrapLines.isAcceptableOrUnknown(
          data['quick_look_wrap_lines']!,
          _quickLookWrapLinesMeta,
        ),
      );
    }
    if (data.containsKey('quick_look_show_statistics')) {
      context.handle(
        _quickLookShowStatisticsMeta,
        quickLookShowStatistics.isAcceptableOrUnknown(
          data['quick_look_show_statistics']!,
          _quickLookShowStatisticsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      terminal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terminal'],
      )!,
      terminalShell: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terminal_shell'],
      )!,
      terminalCustomCommand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terminal_custom_command'],
      )!,
      terminalUseSystemFont: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}terminal_use_system_font'],
      )!,
      terminalFontFamily: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terminal_font_family'],
      )!,
      terminalFontSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}terminal_font_size'],
      )!,
      terminalLineHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}terminal_line_height'],
      )!,
      isDual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dual'],
      )!,
      splitRatio: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}split_ratio'],
      )!,
      activePaneIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_pane_index'],
      )!,
      sidebarCollapsed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sidebar_collapsed'],
      )!,
      sidebarWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sidebar_width'],
      )!,
      restoreSession: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}restore_session'],
      )!,
      defaultStartingPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_starting_path'],
      )!,
      confirmDelete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirm_delete'],
      )!,
      confirmCopy: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirm_copy'],
      )!,
      confirmMove: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}confirm_move'],
      )!,
      showHiddenDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_hidden_default'],
      )!,
      rowDensity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_density'],
      )!,
      fileListHorizontalSpacing: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_list_horizontal_spacing'],
      )!,
      fileListVerticalSpacing: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_list_vertical_spacing'],
      )!,
      dateFormat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_format'],
      )!,
      recentDatesRelative: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recent_dates_relative'],
      )!,
      deleteKeyBehavior: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}delete_key_behavior'],
      )!,
      sortKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort_key'],
      )!,
      sortAscending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sort_ascending'],
      )!,
      foldersFirst: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}folders_first'],
      )!,
      naturalSort: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}natural_sort'],
      )!,
      sortFolders: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sort_folders'],
      )!,
      searchMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_mode'],
      )!,
      rememberFolderState: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remember_folder_state'],
      )!,
      rememberFolderSort: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remember_folder_sort'],
      )!,
      typeAheadBuffer: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}type_ahead_buffer'],
      )!,
      fileListScale: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}file_list_scale'],
      )!,
      fileViewMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_view_mode'],
      )!,
      showColumnSize: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_column_size'],
      )!,
      showColumnDate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_column_date'],
      )!,
      showColumnKind: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_column_kind'],
      )!,
      showColumnCreated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_column_created'],
      )!,
      showColumnPermissions: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_column_permissions'],
      )!,
      showColumnOwner: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_column_owner'],
      )!,
      columnOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}column_order'],
      )!,
      quickLookUseSystemFont: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quick_look_use_system_font'],
      )!,
      quickLookFontFamily: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quick_look_font_family'],
      )!,
      quickLookFontSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quick_look_font_size'],
      )!,
      quickLookLineHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quick_look_line_height'],
      )!,
      quickLookShowLineNumbers: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quick_look_show_line_numbers'],
      )!,
      quickLookRelativeLineNumbers: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quick_look_relative_line_numbers'],
      )!,
      quickLookVimMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quick_look_vim_mode'],
      )!,
      quickLookWrapLines: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quick_look_wrap_lines'],
      )!,
      quickLookShowStatistics: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}quick_look_show_statistics'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final String themeMode;
  final String terminal;
  final String terminalShell;
  final String terminalCustomCommand;
  final bool terminalUseSystemFont;
  final String terminalFontFamily;
  final int terminalFontSize;
  final double terminalLineHeight;
  final bool isDual;
  final double splitRatio;
  final int activePaneIndex;
  final bool sidebarCollapsed;
  final double sidebarWidth;
  final bool restoreSession;
  final String defaultStartingPath;
  final bool confirmDelete;
  final bool confirmCopy;
  final bool confirmMove;
  final bool showHiddenDefault;
  final String rowDensity;
  final int fileListHorizontalSpacing;
  final int fileListVerticalSpacing;
  final String dateFormat;
  final bool recentDatesRelative;
  final String deleteKeyBehavior;
  final String sortKey;
  final bool sortAscending;
  final bool foldersFirst;
  final bool naturalSort;
  final bool sortFolders;
  final String searchMode;
  final bool rememberFolderState;
  final bool rememberFolderSort;
  final bool typeAheadBuffer;
  final double fileListScale;
  final String fileViewMode;
  final bool showColumnSize;
  final bool showColumnDate;
  final bool showColumnKind;
  final bool showColumnCreated;
  final bool showColumnPermissions;
  final bool showColumnOwner;
  final String columnOrder;
  final bool quickLookUseSystemFont;
  final String quickLookFontFamily;
  final int quickLookFontSize;
  final double quickLookLineHeight;
  final bool quickLookShowLineNumbers;
  final bool quickLookRelativeLineNumbers;
  final bool quickLookVimMode;
  final bool quickLookWrapLines;
  final bool quickLookShowStatistics;
  const AppSetting({
    required this.id,
    required this.themeMode,
    required this.terminal,
    required this.terminalShell,
    required this.terminalCustomCommand,
    required this.terminalUseSystemFont,
    required this.terminalFontFamily,
    required this.terminalFontSize,
    required this.terminalLineHeight,
    required this.isDual,
    required this.splitRatio,
    required this.activePaneIndex,
    required this.sidebarCollapsed,
    required this.sidebarWidth,
    required this.restoreSession,
    required this.defaultStartingPath,
    required this.confirmDelete,
    required this.confirmCopy,
    required this.confirmMove,
    required this.showHiddenDefault,
    required this.rowDensity,
    required this.fileListHorizontalSpacing,
    required this.fileListVerticalSpacing,
    required this.dateFormat,
    required this.recentDatesRelative,
    required this.deleteKeyBehavior,
    required this.sortKey,
    required this.sortAscending,
    required this.foldersFirst,
    required this.naturalSort,
    required this.sortFolders,
    required this.searchMode,
    required this.rememberFolderState,
    required this.rememberFolderSort,
    required this.typeAheadBuffer,
    required this.fileListScale,
    required this.fileViewMode,
    required this.showColumnSize,
    required this.showColumnDate,
    required this.showColumnKind,
    required this.showColumnCreated,
    required this.showColumnPermissions,
    required this.showColumnOwner,
    required this.columnOrder,
    required this.quickLookUseSystemFont,
    required this.quickLookFontFamily,
    required this.quickLookFontSize,
    required this.quickLookLineHeight,
    required this.quickLookShowLineNumbers,
    required this.quickLookRelativeLineNumbers,
    required this.quickLookVimMode,
    required this.quickLookWrapLines,
    required this.quickLookShowStatistics,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme_mode'] = Variable<String>(themeMode);
    map['terminal'] = Variable<String>(terminal);
    map['terminal_shell'] = Variable<String>(terminalShell);
    map['terminal_custom_command'] = Variable<String>(terminalCustomCommand);
    map['terminal_use_system_font'] = Variable<bool>(terminalUseSystemFont);
    map['terminal_font_family'] = Variable<String>(terminalFontFamily);
    map['terminal_font_size'] = Variable<int>(terminalFontSize);
    map['terminal_line_height'] = Variable<double>(terminalLineHeight);
    map['is_dual'] = Variable<bool>(isDual);
    map['split_ratio'] = Variable<double>(splitRatio);
    map['active_pane_index'] = Variable<int>(activePaneIndex);
    map['sidebar_collapsed'] = Variable<bool>(sidebarCollapsed);
    map['sidebar_width'] = Variable<double>(sidebarWidth);
    map['restore_session'] = Variable<bool>(restoreSession);
    map['default_starting_path'] = Variable<String>(defaultStartingPath);
    map['confirm_delete'] = Variable<bool>(confirmDelete);
    map['confirm_copy'] = Variable<bool>(confirmCopy);
    map['confirm_move'] = Variable<bool>(confirmMove);
    map['show_hidden_default'] = Variable<bool>(showHiddenDefault);
    map['row_density'] = Variable<String>(rowDensity);
    map['file_list_horizontal_spacing'] = Variable<int>(
      fileListHorizontalSpacing,
    );
    map['file_list_vertical_spacing'] = Variable<int>(fileListVerticalSpacing);
    map['date_format'] = Variable<String>(dateFormat);
    map['recent_dates_relative'] = Variable<bool>(recentDatesRelative);
    map['delete_key_behavior'] = Variable<String>(deleteKeyBehavior);
    map['sort_key'] = Variable<String>(sortKey);
    map['sort_ascending'] = Variable<bool>(sortAscending);
    map['folders_first'] = Variable<bool>(foldersFirst);
    map['natural_sort'] = Variable<bool>(naturalSort);
    map['sort_folders'] = Variable<bool>(sortFolders);
    map['search_mode'] = Variable<String>(searchMode);
    map['remember_folder_state'] = Variable<bool>(rememberFolderState);
    map['remember_folder_sort'] = Variable<bool>(rememberFolderSort);
    map['type_ahead_buffer'] = Variable<bool>(typeAheadBuffer);
    map['file_list_scale'] = Variable<double>(fileListScale);
    map['file_view_mode'] = Variable<String>(fileViewMode);
    map['show_column_size'] = Variable<bool>(showColumnSize);
    map['show_column_date'] = Variable<bool>(showColumnDate);
    map['show_column_kind'] = Variable<bool>(showColumnKind);
    map['show_column_created'] = Variable<bool>(showColumnCreated);
    map['show_column_permissions'] = Variable<bool>(showColumnPermissions);
    map['show_column_owner'] = Variable<bool>(showColumnOwner);
    map['column_order'] = Variable<String>(columnOrder);
    map['quick_look_use_system_font'] = Variable<bool>(quickLookUseSystemFont);
    map['quick_look_font_family'] = Variable<String>(quickLookFontFamily);
    map['quick_look_font_size'] = Variable<int>(quickLookFontSize);
    map['quick_look_line_height'] = Variable<double>(quickLookLineHeight);
    map['quick_look_show_line_numbers'] = Variable<bool>(
      quickLookShowLineNumbers,
    );
    map['quick_look_relative_line_numbers'] = Variable<bool>(
      quickLookRelativeLineNumbers,
    );
    map['quick_look_vim_mode'] = Variable<bool>(quickLookVimMode);
    map['quick_look_wrap_lines'] = Variable<bool>(quickLookWrapLines);
    map['quick_look_show_statistics'] = Variable<bool>(quickLookShowStatistics);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      terminal: Value(terminal),
      terminalShell: Value(terminalShell),
      terminalCustomCommand: Value(terminalCustomCommand),
      terminalUseSystemFont: Value(terminalUseSystemFont),
      terminalFontFamily: Value(terminalFontFamily),
      terminalFontSize: Value(terminalFontSize),
      terminalLineHeight: Value(terminalLineHeight),
      isDual: Value(isDual),
      splitRatio: Value(splitRatio),
      activePaneIndex: Value(activePaneIndex),
      sidebarCollapsed: Value(sidebarCollapsed),
      sidebarWidth: Value(sidebarWidth),
      restoreSession: Value(restoreSession),
      defaultStartingPath: Value(defaultStartingPath),
      confirmDelete: Value(confirmDelete),
      confirmCopy: Value(confirmCopy),
      confirmMove: Value(confirmMove),
      showHiddenDefault: Value(showHiddenDefault),
      rowDensity: Value(rowDensity),
      fileListHorizontalSpacing: Value(fileListHorizontalSpacing),
      fileListVerticalSpacing: Value(fileListVerticalSpacing),
      dateFormat: Value(dateFormat),
      recentDatesRelative: Value(recentDatesRelative),
      deleteKeyBehavior: Value(deleteKeyBehavior),
      sortKey: Value(sortKey),
      sortAscending: Value(sortAscending),
      foldersFirst: Value(foldersFirst),
      naturalSort: Value(naturalSort),
      sortFolders: Value(sortFolders),
      searchMode: Value(searchMode),
      rememberFolderState: Value(rememberFolderState),
      rememberFolderSort: Value(rememberFolderSort),
      typeAheadBuffer: Value(typeAheadBuffer),
      fileListScale: Value(fileListScale),
      fileViewMode: Value(fileViewMode),
      showColumnSize: Value(showColumnSize),
      showColumnDate: Value(showColumnDate),
      showColumnKind: Value(showColumnKind),
      showColumnCreated: Value(showColumnCreated),
      showColumnPermissions: Value(showColumnPermissions),
      showColumnOwner: Value(showColumnOwner),
      columnOrder: Value(columnOrder),
      quickLookUseSystemFont: Value(quickLookUseSystemFont),
      quickLookFontFamily: Value(quickLookFontFamily),
      quickLookFontSize: Value(quickLookFontSize),
      quickLookLineHeight: Value(quickLookLineHeight),
      quickLookShowLineNumbers: Value(quickLookShowLineNumbers),
      quickLookRelativeLineNumbers: Value(quickLookRelativeLineNumbers),
      quickLookVimMode: Value(quickLookVimMode),
      quickLookWrapLines: Value(quickLookWrapLines),
      quickLookShowStatistics: Value(quickLookShowStatistics),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      terminal: serializer.fromJson<String>(json['terminal']),
      terminalShell: serializer.fromJson<String>(json['terminalShell']),
      terminalCustomCommand: serializer.fromJson<String>(
        json['terminalCustomCommand'],
      ),
      terminalUseSystemFont: serializer.fromJson<bool>(
        json['terminalUseSystemFont'],
      ),
      terminalFontFamily: serializer.fromJson<String>(
        json['terminalFontFamily'],
      ),
      terminalFontSize: serializer.fromJson<int>(json['terminalFontSize']),
      terminalLineHeight: serializer.fromJson<double>(
        json['terminalLineHeight'],
      ),
      isDual: serializer.fromJson<bool>(json['isDual']),
      splitRatio: serializer.fromJson<double>(json['splitRatio']),
      activePaneIndex: serializer.fromJson<int>(json['activePaneIndex']),
      sidebarCollapsed: serializer.fromJson<bool>(json['sidebarCollapsed']),
      sidebarWidth: serializer.fromJson<double>(json['sidebarWidth']),
      restoreSession: serializer.fromJson<bool>(json['restoreSession']),
      defaultStartingPath: serializer.fromJson<String>(
        json['defaultStartingPath'],
      ),
      confirmDelete: serializer.fromJson<bool>(json['confirmDelete']),
      confirmCopy: serializer.fromJson<bool>(json['confirmCopy']),
      confirmMove: serializer.fromJson<bool>(json['confirmMove']),
      showHiddenDefault: serializer.fromJson<bool>(json['showHiddenDefault']),
      rowDensity: serializer.fromJson<String>(json['rowDensity']),
      fileListHorizontalSpacing: serializer.fromJson<int>(
        json['fileListHorizontalSpacing'],
      ),
      fileListVerticalSpacing: serializer.fromJson<int>(
        json['fileListVerticalSpacing'],
      ),
      dateFormat: serializer.fromJson<String>(json['dateFormat']),
      recentDatesRelative: serializer.fromJson<bool>(
        json['recentDatesRelative'],
      ),
      deleteKeyBehavior: serializer.fromJson<String>(json['deleteKeyBehavior']),
      sortKey: serializer.fromJson<String>(json['sortKey']),
      sortAscending: serializer.fromJson<bool>(json['sortAscending']),
      foldersFirst: serializer.fromJson<bool>(json['foldersFirst']),
      naturalSort: serializer.fromJson<bool>(json['naturalSort']),
      sortFolders: serializer.fromJson<bool>(json['sortFolders']),
      searchMode: serializer.fromJson<String>(json['searchMode']),
      rememberFolderState: serializer.fromJson<bool>(
        json['rememberFolderState'],
      ),
      rememberFolderSort: serializer.fromJson<bool>(json['rememberFolderSort']),
      typeAheadBuffer: serializer.fromJson<bool>(json['typeAheadBuffer']),
      fileListScale: serializer.fromJson<double>(json['fileListScale']),
      fileViewMode: serializer.fromJson<String>(json['fileViewMode']),
      showColumnSize: serializer.fromJson<bool>(json['showColumnSize']),
      showColumnDate: serializer.fromJson<bool>(json['showColumnDate']),
      showColumnKind: serializer.fromJson<bool>(json['showColumnKind']),
      showColumnCreated: serializer.fromJson<bool>(json['showColumnCreated']),
      showColumnPermissions: serializer.fromJson<bool>(
        json['showColumnPermissions'],
      ),
      showColumnOwner: serializer.fromJson<bool>(json['showColumnOwner']),
      columnOrder: serializer.fromJson<String>(json['columnOrder']),
      quickLookUseSystemFont: serializer.fromJson<bool>(
        json['quickLookUseSystemFont'],
      ),
      quickLookFontFamily: serializer.fromJson<String>(
        json['quickLookFontFamily'],
      ),
      quickLookFontSize: serializer.fromJson<int>(json['quickLookFontSize']),
      quickLookLineHeight: serializer.fromJson<double>(
        json['quickLookLineHeight'],
      ),
      quickLookShowLineNumbers: serializer.fromJson<bool>(
        json['quickLookShowLineNumbers'],
      ),
      quickLookRelativeLineNumbers: serializer.fromJson<bool>(
        json['quickLookRelativeLineNumbers'],
      ),
      quickLookVimMode: serializer.fromJson<bool>(json['quickLookVimMode']),
      quickLookWrapLines: serializer.fromJson<bool>(json['quickLookWrapLines']),
      quickLookShowStatistics: serializer.fromJson<bool>(
        json['quickLookShowStatistics'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'themeMode': serializer.toJson<String>(themeMode),
      'terminal': serializer.toJson<String>(terminal),
      'terminalShell': serializer.toJson<String>(terminalShell),
      'terminalCustomCommand': serializer.toJson<String>(terminalCustomCommand),
      'terminalUseSystemFont': serializer.toJson<bool>(terminalUseSystemFont),
      'terminalFontFamily': serializer.toJson<String>(terminalFontFamily),
      'terminalFontSize': serializer.toJson<int>(terminalFontSize),
      'terminalLineHeight': serializer.toJson<double>(terminalLineHeight),
      'isDual': serializer.toJson<bool>(isDual),
      'splitRatio': serializer.toJson<double>(splitRatio),
      'activePaneIndex': serializer.toJson<int>(activePaneIndex),
      'sidebarCollapsed': serializer.toJson<bool>(sidebarCollapsed),
      'sidebarWidth': serializer.toJson<double>(sidebarWidth),
      'restoreSession': serializer.toJson<bool>(restoreSession),
      'defaultStartingPath': serializer.toJson<String>(defaultStartingPath),
      'confirmDelete': serializer.toJson<bool>(confirmDelete),
      'confirmCopy': serializer.toJson<bool>(confirmCopy),
      'confirmMove': serializer.toJson<bool>(confirmMove),
      'showHiddenDefault': serializer.toJson<bool>(showHiddenDefault),
      'rowDensity': serializer.toJson<String>(rowDensity),
      'fileListHorizontalSpacing': serializer.toJson<int>(
        fileListHorizontalSpacing,
      ),
      'fileListVerticalSpacing': serializer.toJson<int>(
        fileListVerticalSpacing,
      ),
      'dateFormat': serializer.toJson<String>(dateFormat),
      'recentDatesRelative': serializer.toJson<bool>(recentDatesRelative),
      'deleteKeyBehavior': serializer.toJson<String>(deleteKeyBehavior),
      'sortKey': serializer.toJson<String>(sortKey),
      'sortAscending': serializer.toJson<bool>(sortAscending),
      'foldersFirst': serializer.toJson<bool>(foldersFirst),
      'naturalSort': serializer.toJson<bool>(naturalSort),
      'sortFolders': serializer.toJson<bool>(sortFolders),
      'searchMode': serializer.toJson<String>(searchMode),
      'rememberFolderState': serializer.toJson<bool>(rememberFolderState),
      'rememberFolderSort': serializer.toJson<bool>(rememberFolderSort),
      'typeAheadBuffer': serializer.toJson<bool>(typeAheadBuffer),
      'fileListScale': serializer.toJson<double>(fileListScale),
      'fileViewMode': serializer.toJson<String>(fileViewMode),
      'showColumnSize': serializer.toJson<bool>(showColumnSize),
      'showColumnDate': serializer.toJson<bool>(showColumnDate),
      'showColumnKind': serializer.toJson<bool>(showColumnKind),
      'showColumnCreated': serializer.toJson<bool>(showColumnCreated),
      'showColumnPermissions': serializer.toJson<bool>(showColumnPermissions),
      'showColumnOwner': serializer.toJson<bool>(showColumnOwner),
      'columnOrder': serializer.toJson<String>(columnOrder),
      'quickLookUseSystemFont': serializer.toJson<bool>(quickLookUseSystemFont),
      'quickLookFontFamily': serializer.toJson<String>(quickLookFontFamily),
      'quickLookFontSize': serializer.toJson<int>(quickLookFontSize),
      'quickLookLineHeight': serializer.toJson<double>(quickLookLineHeight),
      'quickLookShowLineNumbers': serializer.toJson<bool>(
        quickLookShowLineNumbers,
      ),
      'quickLookRelativeLineNumbers': serializer.toJson<bool>(
        quickLookRelativeLineNumbers,
      ),
      'quickLookVimMode': serializer.toJson<bool>(quickLookVimMode),
      'quickLookWrapLines': serializer.toJson<bool>(quickLookWrapLines),
      'quickLookShowStatistics': serializer.toJson<bool>(
        quickLookShowStatistics,
      ),
    };
  }

  AppSetting copyWith({
    int? id,
    String? themeMode,
    String? terminal,
    String? terminalShell,
    String? terminalCustomCommand,
    bool? terminalUseSystemFont,
    String? terminalFontFamily,
    int? terminalFontSize,
    double? terminalLineHeight,
    bool? isDual,
    double? splitRatio,
    int? activePaneIndex,
    bool? sidebarCollapsed,
    double? sidebarWidth,
    bool? restoreSession,
    String? defaultStartingPath,
    bool? confirmDelete,
    bool? confirmCopy,
    bool? confirmMove,
    bool? showHiddenDefault,
    String? rowDensity,
    int? fileListHorizontalSpacing,
    int? fileListVerticalSpacing,
    String? dateFormat,
    bool? recentDatesRelative,
    String? deleteKeyBehavior,
    String? sortKey,
    bool? sortAscending,
    bool? foldersFirst,
    bool? naturalSort,
    bool? sortFolders,
    String? searchMode,
    bool? rememberFolderState,
    bool? rememberFolderSort,
    bool? typeAheadBuffer,
    double? fileListScale,
    String? fileViewMode,
    bool? showColumnSize,
    bool? showColumnDate,
    bool? showColumnKind,
    bool? showColumnCreated,
    bool? showColumnPermissions,
    bool? showColumnOwner,
    String? columnOrder,
    bool? quickLookUseSystemFont,
    String? quickLookFontFamily,
    int? quickLookFontSize,
    double? quickLookLineHeight,
    bool? quickLookShowLineNumbers,
    bool? quickLookRelativeLineNumbers,
    bool? quickLookVimMode,
    bool? quickLookWrapLines,
    bool? quickLookShowStatistics,
  }) => AppSetting(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    terminal: terminal ?? this.terminal,
    terminalShell: terminalShell ?? this.terminalShell,
    terminalCustomCommand: terminalCustomCommand ?? this.terminalCustomCommand,
    terminalUseSystemFont: terminalUseSystemFont ?? this.terminalUseSystemFont,
    terminalFontFamily: terminalFontFamily ?? this.terminalFontFamily,
    terminalFontSize: terminalFontSize ?? this.terminalFontSize,
    terminalLineHeight: terminalLineHeight ?? this.terminalLineHeight,
    isDual: isDual ?? this.isDual,
    splitRatio: splitRatio ?? this.splitRatio,
    activePaneIndex: activePaneIndex ?? this.activePaneIndex,
    sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
    sidebarWidth: sidebarWidth ?? this.sidebarWidth,
    restoreSession: restoreSession ?? this.restoreSession,
    defaultStartingPath: defaultStartingPath ?? this.defaultStartingPath,
    confirmDelete: confirmDelete ?? this.confirmDelete,
    confirmCopy: confirmCopy ?? this.confirmCopy,
    confirmMove: confirmMove ?? this.confirmMove,
    showHiddenDefault: showHiddenDefault ?? this.showHiddenDefault,
    rowDensity: rowDensity ?? this.rowDensity,
    fileListHorizontalSpacing:
        fileListHorizontalSpacing ?? this.fileListHorizontalSpacing,
    fileListVerticalSpacing:
        fileListVerticalSpacing ?? this.fileListVerticalSpacing,
    dateFormat: dateFormat ?? this.dateFormat,
    recentDatesRelative: recentDatesRelative ?? this.recentDatesRelative,
    deleteKeyBehavior: deleteKeyBehavior ?? this.deleteKeyBehavior,
    sortKey: sortKey ?? this.sortKey,
    sortAscending: sortAscending ?? this.sortAscending,
    foldersFirst: foldersFirst ?? this.foldersFirst,
    naturalSort: naturalSort ?? this.naturalSort,
    sortFolders: sortFolders ?? this.sortFolders,
    searchMode: searchMode ?? this.searchMode,
    rememberFolderState: rememberFolderState ?? this.rememberFolderState,
    rememberFolderSort: rememberFolderSort ?? this.rememberFolderSort,
    typeAheadBuffer: typeAheadBuffer ?? this.typeAheadBuffer,
    fileListScale: fileListScale ?? this.fileListScale,
    fileViewMode: fileViewMode ?? this.fileViewMode,
    showColumnSize: showColumnSize ?? this.showColumnSize,
    showColumnDate: showColumnDate ?? this.showColumnDate,
    showColumnKind: showColumnKind ?? this.showColumnKind,
    showColumnCreated: showColumnCreated ?? this.showColumnCreated,
    showColumnPermissions: showColumnPermissions ?? this.showColumnPermissions,
    showColumnOwner: showColumnOwner ?? this.showColumnOwner,
    columnOrder: columnOrder ?? this.columnOrder,
    quickLookUseSystemFont:
        quickLookUseSystemFont ?? this.quickLookUseSystemFont,
    quickLookFontFamily: quickLookFontFamily ?? this.quickLookFontFamily,
    quickLookFontSize: quickLookFontSize ?? this.quickLookFontSize,
    quickLookLineHeight: quickLookLineHeight ?? this.quickLookLineHeight,
    quickLookShowLineNumbers:
        quickLookShowLineNumbers ?? this.quickLookShowLineNumbers,
    quickLookRelativeLineNumbers:
        quickLookRelativeLineNumbers ?? this.quickLookRelativeLineNumbers,
    quickLookVimMode: quickLookVimMode ?? this.quickLookVimMode,
    quickLookWrapLines: quickLookWrapLines ?? this.quickLookWrapLines,
    quickLookShowStatistics:
        quickLookShowStatistics ?? this.quickLookShowStatistics,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      terminal: data.terminal.present ? data.terminal.value : this.terminal,
      terminalShell: data.terminalShell.present
          ? data.terminalShell.value
          : this.terminalShell,
      terminalCustomCommand: data.terminalCustomCommand.present
          ? data.terminalCustomCommand.value
          : this.terminalCustomCommand,
      terminalUseSystemFont: data.terminalUseSystemFont.present
          ? data.terminalUseSystemFont.value
          : this.terminalUseSystemFont,
      terminalFontFamily: data.terminalFontFamily.present
          ? data.terminalFontFamily.value
          : this.terminalFontFamily,
      terminalFontSize: data.terminalFontSize.present
          ? data.terminalFontSize.value
          : this.terminalFontSize,
      terminalLineHeight: data.terminalLineHeight.present
          ? data.terminalLineHeight.value
          : this.terminalLineHeight,
      isDual: data.isDual.present ? data.isDual.value : this.isDual,
      splitRatio: data.splitRatio.present
          ? data.splitRatio.value
          : this.splitRatio,
      activePaneIndex: data.activePaneIndex.present
          ? data.activePaneIndex.value
          : this.activePaneIndex,
      sidebarCollapsed: data.sidebarCollapsed.present
          ? data.sidebarCollapsed.value
          : this.sidebarCollapsed,
      sidebarWidth: data.sidebarWidth.present
          ? data.sidebarWidth.value
          : this.sidebarWidth,
      restoreSession: data.restoreSession.present
          ? data.restoreSession.value
          : this.restoreSession,
      defaultStartingPath: data.defaultStartingPath.present
          ? data.defaultStartingPath.value
          : this.defaultStartingPath,
      confirmDelete: data.confirmDelete.present
          ? data.confirmDelete.value
          : this.confirmDelete,
      confirmCopy: data.confirmCopy.present
          ? data.confirmCopy.value
          : this.confirmCopy,
      confirmMove: data.confirmMove.present
          ? data.confirmMove.value
          : this.confirmMove,
      showHiddenDefault: data.showHiddenDefault.present
          ? data.showHiddenDefault.value
          : this.showHiddenDefault,
      rowDensity: data.rowDensity.present
          ? data.rowDensity.value
          : this.rowDensity,
      fileListHorizontalSpacing: data.fileListHorizontalSpacing.present
          ? data.fileListHorizontalSpacing.value
          : this.fileListHorizontalSpacing,
      fileListVerticalSpacing: data.fileListVerticalSpacing.present
          ? data.fileListVerticalSpacing.value
          : this.fileListVerticalSpacing,
      dateFormat: data.dateFormat.present
          ? data.dateFormat.value
          : this.dateFormat,
      recentDatesRelative: data.recentDatesRelative.present
          ? data.recentDatesRelative.value
          : this.recentDatesRelative,
      deleteKeyBehavior: data.deleteKeyBehavior.present
          ? data.deleteKeyBehavior.value
          : this.deleteKeyBehavior,
      sortKey: data.sortKey.present ? data.sortKey.value : this.sortKey,
      sortAscending: data.sortAscending.present
          ? data.sortAscending.value
          : this.sortAscending,
      foldersFirst: data.foldersFirst.present
          ? data.foldersFirst.value
          : this.foldersFirst,
      naturalSort: data.naturalSort.present
          ? data.naturalSort.value
          : this.naturalSort,
      sortFolders: data.sortFolders.present
          ? data.sortFolders.value
          : this.sortFolders,
      searchMode: data.searchMode.present
          ? data.searchMode.value
          : this.searchMode,
      rememberFolderState: data.rememberFolderState.present
          ? data.rememberFolderState.value
          : this.rememberFolderState,
      rememberFolderSort: data.rememberFolderSort.present
          ? data.rememberFolderSort.value
          : this.rememberFolderSort,
      typeAheadBuffer: data.typeAheadBuffer.present
          ? data.typeAheadBuffer.value
          : this.typeAheadBuffer,
      fileListScale: data.fileListScale.present
          ? data.fileListScale.value
          : this.fileListScale,
      fileViewMode: data.fileViewMode.present
          ? data.fileViewMode.value
          : this.fileViewMode,
      showColumnSize: data.showColumnSize.present
          ? data.showColumnSize.value
          : this.showColumnSize,
      showColumnDate: data.showColumnDate.present
          ? data.showColumnDate.value
          : this.showColumnDate,
      showColumnKind: data.showColumnKind.present
          ? data.showColumnKind.value
          : this.showColumnKind,
      showColumnCreated: data.showColumnCreated.present
          ? data.showColumnCreated.value
          : this.showColumnCreated,
      showColumnPermissions: data.showColumnPermissions.present
          ? data.showColumnPermissions.value
          : this.showColumnPermissions,
      showColumnOwner: data.showColumnOwner.present
          ? data.showColumnOwner.value
          : this.showColumnOwner,
      columnOrder: data.columnOrder.present
          ? data.columnOrder.value
          : this.columnOrder,
      quickLookUseSystemFont: data.quickLookUseSystemFont.present
          ? data.quickLookUseSystemFont.value
          : this.quickLookUseSystemFont,
      quickLookFontFamily: data.quickLookFontFamily.present
          ? data.quickLookFontFamily.value
          : this.quickLookFontFamily,
      quickLookFontSize: data.quickLookFontSize.present
          ? data.quickLookFontSize.value
          : this.quickLookFontSize,
      quickLookLineHeight: data.quickLookLineHeight.present
          ? data.quickLookLineHeight.value
          : this.quickLookLineHeight,
      quickLookShowLineNumbers: data.quickLookShowLineNumbers.present
          ? data.quickLookShowLineNumbers.value
          : this.quickLookShowLineNumbers,
      quickLookRelativeLineNumbers: data.quickLookRelativeLineNumbers.present
          ? data.quickLookRelativeLineNumbers.value
          : this.quickLookRelativeLineNumbers,
      quickLookVimMode: data.quickLookVimMode.present
          ? data.quickLookVimMode.value
          : this.quickLookVimMode,
      quickLookWrapLines: data.quickLookWrapLines.present
          ? data.quickLookWrapLines.value
          : this.quickLookWrapLines,
      quickLookShowStatistics: data.quickLookShowStatistics.present
          ? data.quickLookShowStatistics.value
          : this.quickLookShowStatistics,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('terminal: $terminal, ')
          ..write('terminalShell: $terminalShell, ')
          ..write('terminalCustomCommand: $terminalCustomCommand, ')
          ..write('terminalUseSystemFont: $terminalUseSystemFont, ')
          ..write('terminalFontFamily: $terminalFontFamily, ')
          ..write('terminalFontSize: $terminalFontSize, ')
          ..write('terminalLineHeight: $terminalLineHeight, ')
          ..write('isDual: $isDual, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('activePaneIndex: $activePaneIndex, ')
          ..write('sidebarCollapsed: $sidebarCollapsed, ')
          ..write('sidebarWidth: $sidebarWidth, ')
          ..write('restoreSession: $restoreSession, ')
          ..write('defaultStartingPath: $defaultStartingPath, ')
          ..write('confirmDelete: $confirmDelete, ')
          ..write('confirmCopy: $confirmCopy, ')
          ..write('confirmMove: $confirmMove, ')
          ..write('showHiddenDefault: $showHiddenDefault, ')
          ..write('rowDensity: $rowDensity, ')
          ..write('fileListHorizontalSpacing: $fileListHorizontalSpacing, ')
          ..write('fileListVerticalSpacing: $fileListVerticalSpacing, ')
          ..write('dateFormat: $dateFormat, ')
          ..write('recentDatesRelative: $recentDatesRelative, ')
          ..write('deleteKeyBehavior: $deleteKeyBehavior, ')
          ..write('sortKey: $sortKey, ')
          ..write('sortAscending: $sortAscending, ')
          ..write('foldersFirst: $foldersFirst, ')
          ..write('naturalSort: $naturalSort, ')
          ..write('sortFolders: $sortFolders, ')
          ..write('searchMode: $searchMode, ')
          ..write('rememberFolderState: $rememberFolderState, ')
          ..write('rememberFolderSort: $rememberFolderSort, ')
          ..write('typeAheadBuffer: $typeAheadBuffer, ')
          ..write('fileListScale: $fileListScale, ')
          ..write('fileViewMode: $fileViewMode, ')
          ..write('showColumnSize: $showColumnSize, ')
          ..write('showColumnDate: $showColumnDate, ')
          ..write('showColumnKind: $showColumnKind, ')
          ..write('showColumnCreated: $showColumnCreated, ')
          ..write('showColumnPermissions: $showColumnPermissions, ')
          ..write('showColumnOwner: $showColumnOwner, ')
          ..write('columnOrder: $columnOrder, ')
          ..write('quickLookUseSystemFont: $quickLookUseSystemFont, ')
          ..write('quickLookFontFamily: $quickLookFontFamily, ')
          ..write('quickLookFontSize: $quickLookFontSize, ')
          ..write('quickLookLineHeight: $quickLookLineHeight, ')
          ..write('quickLookShowLineNumbers: $quickLookShowLineNumbers, ')
          ..write(
            'quickLookRelativeLineNumbers: $quickLookRelativeLineNumbers, ',
          )
          ..write('quickLookVimMode: $quickLookVimMode, ')
          ..write('quickLookWrapLines: $quickLookWrapLines, ')
          ..write('quickLookShowStatistics: $quickLookShowStatistics')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    themeMode,
    terminal,
    terminalShell,
    terminalCustomCommand,
    terminalUseSystemFont,
    terminalFontFamily,
    terminalFontSize,
    terminalLineHeight,
    isDual,
    splitRatio,
    activePaneIndex,
    sidebarCollapsed,
    sidebarWidth,
    restoreSession,
    defaultStartingPath,
    confirmDelete,
    confirmCopy,
    confirmMove,
    showHiddenDefault,
    rowDensity,
    fileListHorizontalSpacing,
    fileListVerticalSpacing,
    dateFormat,
    recentDatesRelative,
    deleteKeyBehavior,
    sortKey,
    sortAscending,
    foldersFirst,
    naturalSort,
    sortFolders,
    searchMode,
    rememberFolderState,
    rememberFolderSort,
    typeAheadBuffer,
    fileListScale,
    fileViewMode,
    showColumnSize,
    showColumnDate,
    showColumnKind,
    showColumnCreated,
    showColumnPermissions,
    showColumnOwner,
    columnOrder,
    quickLookUseSystemFont,
    quickLookFontFamily,
    quickLookFontSize,
    quickLookLineHeight,
    quickLookShowLineNumbers,
    quickLookRelativeLineNumbers,
    quickLookVimMode,
    quickLookWrapLines,
    quickLookShowStatistics,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.terminal == this.terminal &&
          other.terminalShell == this.terminalShell &&
          other.terminalCustomCommand == this.terminalCustomCommand &&
          other.terminalUseSystemFont == this.terminalUseSystemFont &&
          other.terminalFontFamily == this.terminalFontFamily &&
          other.terminalFontSize == this.terminalFontSize &&
          other.terminalLineHeight == this.terminalLineHeight &&
          other.isDual == this.isDual &&
          other.splitRatio == this.splitRatio &&
          other.activePaneIndex == this.activePaneIndex &&
          other.sidebarCollapsed == this.sidebarCollapsed &&
          other.sidebarWidth == this.sidebarWidth &&
          other.restoreSession == this.restoreSession &&
          other.defaultStartingPath == this.defaultStartingPath &&
          other.confirmDelete == this.confirmDelete &&
          other.confirmCopy == this.confirmCopy &&
          other.confirmMove == this.confirmMove &&
          other.showHiddenDefault == this.showHiddenDefault &&
          other.rowDensity == this.rowDensity &&
          other.fileListHorizontalSpacing == this.fileListHorizontalSpacing &&
          other.fileListVerticalSpacing == this.fileListVerticalSpacing &&
          other.dateFormat == this.dateFormat &&
          other.recentDatesRelative == this.recentDatesRelative &&
          other.deleteKeyBehavior == this.deleteKeyBehavior &&
          other.sortKey == this.sortKey &&
          other.sortAscending == this.sortAscending &&
          other.foldersFirst == this.foldersFirst &&
          other.naturalSort == this.naturalSort &&
          other.sortFolders == this.sortFolders &&
          other.searchMode == this.searchMode &&
          other.rememberFolderState == this.rememberFolderState &&
          other.rememberFolderSort == this.rememberFolderSort &&
          other.typeAheadBuffer == this.typeAheadBuffer &&
          other.fileListScale == this.fileListScale &&
          other.fileViewMode == this.fileViewMode &&
          other.showColumnSize == this.showColumnSize &&
          other.showColumnDate == this.showColumnDate &&
          other.showColumnKind == this.showColumnKind &&
          other.showColumnCreated == this.showColumnCreated &&
          other.showColumnPermissions == this.showColumnPermissions &&
          other.showColumnOwner == this.showColumnOwner &&
          other.columnOrder == this.columnOrder &&
          other.quickLookUseSystemFont == this.quickLookUseSystemFont &&
          other.quickLookFontFamily == this.quickLookFontFamily &&
          other.quickLookFontSize == this.quickLookFontSize &&
          other.quickLookLineHeight == this.quickLookLineHeight &&
          other.quickLookShowLineNumbers == this.quickLookShowLineNumbers &&
          other.quickLookRelativeLineNumbers ==
              this.quickLookRelativeLineNumbers &&
          other.quickLookVimMode == this.quickLookVimMode &&
          other.quickLookWrapLines == this.quickLookWrapLines &&
          other.quickLookShowStatistics == this.quickLookShowStatistics);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> themeMode;
  final Value<String> terminal;
  final Value<String> terminalShell;
  final Value<String> terminalCustomCommand;
  final Value<bool> terminalUseSystemFont;
  final Value<String> terminalFontFamily;
  final Value<int> terminalFontSize;
  final Value<double> terminalLineHeight;
  final Value<bool> isDual;
  final Value<double> splitRatio;
  final Value<int> activePaneIndex;
  final Value<bool> sidebarCollapsed;
  final Value<double> sidebarWidth;
  final Value<bool> restoreSession;
  final Value<String> defaultStartingPath;
  final Value<bool> confirmDelete;
  final Value<bool> confirmCopy;
  final Value<bool> confirmMove;
  final Value<bool> showHiddenDefault;
  final Value<String> rowDensity;
  final Value<int> fileListHorizontalSpacing;
  final Value<int> fileListVerticalSpacing;
  final Value<String> dateFormat;
  final Value<bool> recentDatesRelative;
  final Value<String> deleteKeyBehavior;
  final Value<String> sortKey;
  final Value<bool> sortAscending;
  final Value<bool> foldersFirst;
  final Value<bool> naturalSort;
  final Value<bool> sortFolders;
  final Value<String> searchMode;
  final Value<bool> rememberFolderState;
  final Value<bool> rememberFolderSort;
  final Value<bool> typeAheadBuffer;
  final Value<double> fileListScale;
  final Value<String> fileViewMode;
  final Value<bool> showColumnSize;
  final Value<bool> showColumnDate;
  final Value<bool> showColumnKind;
  final Value<bool> showColumnCreated;
  final Value<bool> showColumnPermissions;
  final Value<bool> showColumnOwner;
  final Value<String> columnOrder;
  final Value<bool> quickLookUseSystemFont;
  final Value<String> quickLookFontFamily;
  final Value<int> quickLookFontSize;
  final Value<double> quickLookLineHeight;
  final Value<bool> quickLookShowLineNumbers;
  final Value<bool> quickLookRelativeLineNumbers;
  final Value<bool> quickLookVimMode;
  final Value<bool> quickLookWrapLines;
  final Value<bool> quickLookShowStatistics;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.terminal = const Value.absent(),
    this.terminalShell = const Value.absent(),
    this.terminalCustomCommand = const Value.absent(),
    this.terminalUseSystemFont = const Value.absent(),
    this.terminalFontFamily = const Value.absent(),
    this.terminalFontSize = const Value.absent(),
    this.terminalLineHeight = const Value.absent(),
    this.isDual = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.activePaneIndex = const Value.absent(),
    this.sidebarCollapsed = const Value.absent(),
    this.sidebarWidth = const Value.absent(),
    this.restoreSession = const Value.absent(),
    this.defaultStartingPath = const Value.absent(),
    this.confirmDelete = const Value.absent(),
    this.confirmCopy = const Value.absent(),
    this.confirmMove = const Value.absent(),
    this.showHiddenDefault = const Value.absent(),
    this.rowDensity = const Value.absent(),
    this.fileListHorizontalSpacing = const Value.absent(),
    this.fileListVerticalSpacing = const Value.absent(),
    this.dateFormat = const Value.absent(),
    this.recentDatesRelative = const Value.absent(),
    this.deleteKeyBehavior = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.foldersFirst = const Value.absent(),
    this.naturalSort = const Value.absent(),
    this.sortFolders = const Value.absent(),
    this.searchMode = const Value.absent(),
    this.rememberFolderState = const Value.absent(),
    this.rememberFolderSort = const Value.absent(),
    this.typeAheadBuffer = const Value.absent(),
    this.fileListScale = const Value.absent(),
    this.fileViewMode = const Value.absent(),
    this.showColumnSize = const Value.absent(),
    this.showColumnDate = const Value.absent(),
    this.showColumnKind = const Value.absent(),
    this.showColumnCreated = const Value.absent(),
    this.showColumnPermissions = const Value.absent(),
    this.showColumnOwner = const Value.absent(),
    this.columnOrder = const Value.absent(),
    this.quickLookUseSystemFont = const Value.absent(),
    this.quickLookFontFamily = const Value.absent(),
    this.quickLookFontSize = const Value.absent(),
    this.quickLookLineHeight = const Value.absent(),
    this.quickLookShowLineNumbers = const Value.absent(),
    this.quickLookRelativeLineNumbers = const Value.absent(),
    this.quickLookVimMode = const Value.absent(),
    this.quickLookWrapLines = const Value.absent(),
    this.quickLookShowStatistics = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.terminal = const Value.absent(),
    this.terminalShell = const Value.absent(),
    this.terminalCustomCommand = const Value.absent(),
    this.terminalUseSystemFont = const Value.absent(),
    this.terminalFontFamily = const Value.absent(),
    this.terminalFontSize = const Value.absent(),
    this.terminalLineHeight = const Value.absent(),
    this.isDual = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.activePaneIndex = const Value.absent(),
    this.sidebarCollapsed = const Value.absent(),
    this.sidebarWidth = const Value.absent(),
    this.restoreSession = const Value.absent(),
    this.defaultStartingPath = const Value.absent(),
    this.confirmDelete = const Value.absent(),
    this.confirmCopy = const Value.absent(),
    this.confirmMove = const Value.absent(),
    this.showHiddenDefault = const Value.absent(),
    this.rowDensity = const Value.absent(),
    this.fileListHorizontalSpacing = const Value.absent(),
    this.fileListVerticalSpacing = const Value.absent(),
    this.dateFormat = const Value.absent(),
    this.recentDatesRelative = const Value.absent(),
    this.deleteKeyBehavior = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.foldersFirst = const Value.absent(),
    this.naturalSort = const Value.absent(),
    this.sortFolders = const Value.absent(),
    this.searchMode = const Value.absent(),
    this.rememberFolderState = const Value.absent(),
    this.rememberFolderSort = const Value.absent(),
    this.typeAheadBuffer = const Value.absent(),
    this.fileListScale = const Value.absent(),
    this.fileViewMode = const Value.absent(),
    this.showColumnSize = const Value.absent(),
    this.showColumnDate = const Value.absent(),
    this.showColumnKind = const Value.absent(),
    this.showColumnCreated = const Value.absent(),
    this.showColumnPermissions = const Value.absent(),
    this.showColumnOwner = const Value.absent(),
    this.columnOrder = const Value.absent(),
    this.quickLookUseSystemFont = const Value.absent(),
    this.quickLookFontFamily = const Value.absent(),
    this.quickLookFontSize = const Value.absent(),
    this.quickLookLineHeight = const Value.absent(),
    this.quickLookShowLineNumbers = const Value.absent(),
    this.quickLookRelativeLineNumbers = const Value.absent(),
    this.quickLookVimMode = const Value.absent(),
    this.quickLookWrapLines = const Value.absent(),
    this.quickLookShowStatistics = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? themeMode,
    Expression<String>? terminal,
    Expression<String>? terminalShell,
    Expression<String>? terminalCustomCommand,
    Expression<bool>? terminalUseSystemFont,
    Expression<String>? terminalFontFamily,
    Expression<int>? terminalFontSize,
    Expression<double>? terminalLineHeight,
    Expression<bool>? isDual,
    Expression<double>? splitRatio,
    Expression<int>? activePaneIndex,
    Expression<bool>? sidebarCollapsed,
    Expression<double>? sidebarWidth,
    Expression<bool>? restoreSession,
    Expression<String>? defaultStartingPath,
    Expression<bool>? confirmDelete,
    Expression<bool>? confirmCopy,
    Expression<bool>? confirmMove,
    Expression<bool>? showHiddenDefault,
    Expression<String>? rowDensity,
    Expression<int>? fileListHorizontalSpacing,
    Expression<int>? fileListVerticalSpacing,
    Expression<String>? dateFormat,
    Expression<bool>? recentDatesRelative,
    Expression<String>? deleteKeyBehavior,
    Expression<String>? sortKey,
    Expression<bool>? sortAscending,
    Expression<bool>? foldersFirst,
    Expression<bool>? naturalSort,
    Expression<bool>? sortFolders,
    Expression<String>? searchMode,
    Expression<bool>? rememberFolderState,
    Expression<bool>? rememberFolderSort,
    Expression<bool>? typeAheadBuffer,
    Expression<double>? fileListScale,
    Expression<String>? fileViewMode,
    Expression<bool>? showColumnSize,
    Expression<bool>? showColumnDate,
    Expression<bool>? showColumnKind,
    Expression<bool>? showColumnCreated,
    Expression<bool>? showColumnPermissions,
    Expression<bool>? showColumnOwner,
    Expression<String>? columnOrder,
    Expression<bool>? quickLookUseSystemFont,
    Expression<String>? quickLookFontFamily,
    Expression<int>? quickLookFontSize,
    Expression<double>? quickLookLineHeight,
    Expression<bool>? quickLookShowLineNumbers,
    Expression<bool>? quickLookRelativeLineNumbers,
    Expression<bool>? quickLookVimMode,
    Expression<bool>? quickLookWrapLines,
    Expression<bool>? quickLookShowStatistics,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (terminal != null) 'terminal': terminal,
      if (terminalShell != null) 'terminal_shell': terminalShell,
      if (terminalCustomCommand != null)
        'terminal_custom_command': terminalCustomCommand,
      if (terminalUseSystemFont != null)
        'terminal_use_system_font': terminalUseSystemFont,
      if (terminalFontFamily != null)
        'terminal_font_family': terminalFontFamily,
      if (terminalFontSize != null) 'terminal_font_size': terminalFontSize,
      if (terminalLineHeight != null)
        'terminal_line_height': terminalLineHeight,
      if (isDual != null) 'is_dual': isDual,
      if (splitRatio != null) 'split_ratio': splitRatio,
      if (activePaneIndex != null) 'active_pane_index': activePaneIndex,
      if (sidebarCollapsed != null) 'sidebar_collapsed': sidebarCollapsed,
      if (sidebarWidth != null) 'sidebar_width': sidebarWidth,
      if (restoreSession != null) 'restore_session': restoreSession,
      if (defaultStartingPath != null)
        'default_starting_path': defaultStartingPath,
      if (confirmDelete != null) 'confirm_delete': confirmDelete,
      if (confirmCopy != null) 'confirm_copy': confirmCopy,
      if (confirmMove != null) 'confirm_move': confirmMove,
      if (showHiddenDefault != null) 'show_hidden_default': showHiddenDefault,
      if (rowDensity != null) 'row_density': rowDensity,
      if (fileListHorizontalSpacing != null)
        'file_list_horizontal_spacing': fileListHorizontalSpacing,
      if (fileListVerticalSpacing != null)
        'file_list_vertical_spacing': fileListVerticalSpacing,
      if (dateFormat != null) 'date_format': dateFormat,
      if (recentDatesRelative != null)
        'recent_dates_relative': recentDatesRelative,
      if (deleteKeyBehavior != null) 'delete_key_behavior': deleteKeyBehavior,
      if (sortKey != null) 'sort_key': sortKey,
      if (sortAscending != null) 'sort_ascending': sortAscending,
      if (foldersFirst != null) 'folders_first': foldersFirst,
      if (naturalSort != null) 'natural_sort': naturalSort,
      if (sortFolders != null) 'sort_folders': sortFolders,
      if (searchMode != null) 'search_mode': searchMode,
      if (rememberFolderState != null)
        'remember_folder_state': rememberFolderState,
      if (rememberFolderSort != null)
        'remember_folder_sort': rememberFolderSort,
      if (typeAheadBuffer != null) 'type_ahead_buffer': typeAheadBuffer,
      if (fileListScale != null) 'file_list_scale': fileListScale,
      if (fileViewMode != null) 'file_view_mode': fileViewMode,
      if (showColumnSize != null) 'show_column_size': showColumnSize,
      if (showColumnDate != null) 'show_column_date': showColumnDate,
      if (showColumnKind != null) 'show_column_kind': showColumnKind,
      if (showColumnCreated != null) 'show_column_created': showColumnCreated,
      if (showColumnPermissions != null)
        'show_column_permissions': showColumnPermissions,
      if (showColumnOwner != null) 'show_column_owner': showColumnOwner,
      if (columnOrder != null) 'column_order': columnOrder,
      if (quickLookUseSystemFont != null)
        'quick_look_use_system_font': quickLookUseSystemFont,
      if (quickLookFontFamily != null)
        'quick_look_font_family': quickLookFontFamily,
      if (quickLookFontSize != null) 'quick_look_font_size': quickLookFontSize,
      if (quickLookLineHeight != null)
        'quick_look_line_height': quickLookLineHeight,
      if (quickLookShowLineNumbers != null)
        'quick_look_show_line_numbers': quickLookShowLineNumbers,
      if (quickLookRelativeLineNumbers != null)
        'quick_look_relative_line_numbers': quickLookRelativeLineNumbers,
      if (quickLookVimMode != null) 'quick_look_vim_mode': quickLookVimMode,
      if (quickLookWrapLines != null)
        'quick_look_wrap_lines': quickLookWrapLines,
      if (quickLookShowStatistics != null)
        'quick_look_show_statistics': quickLookShowStatistics,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? themeMode,
    Value<String>? terminal,
    Value<String>? terminalShell,
    Value<String>? terminalCustomCommand,
    Value<bool>? terminalUseSystemFont,
    Value<String>? terminalFontFamily,
    Value<int>? terminalFontSize,
    Value<double>? terminalLineHeight,
    Value<bool>? isDual,
    Value<double>? splitRatio,
    Value<int>? activePaneIndex,
    Value<bool>? sidebarCollapsed,
    Value<double>? sidebarWidth,
    Value<bool>? restoreSession,
    Value<String>? defaultStartingPath,
    Value<bool>? confirmDelete,
    Value<bool>? confirmCopy,
    Value<bool>? confirmMove,
    Value<bool>? showHiddenDefault,
    Value<String>? rowDensity,
    Value<int>? fileListHorizontalSpacing,
    Value<int>? fileListVerticalSpacing,
    Value<String>? dateFormat,
    Value<bool>? recentDatesRelative,
    Value<String>? deleteKeyBehavior,
    Value<String>? sortKey,
    Value<bool>? sortAscending,
    Value<bool>? foldersFirst,
    Value<bool>? naturalSort,
    Value<bool>? sortFolders,
    Value<String>? searchMode,
    Value<bool>? rememberFolderState,
    Value<bool>? rememberFolderSort,
    Value<bool>? typeAheadBuffer,
    Value<double>? fileListScale,
    Value<String>? fileViewMode,
    Value<bool>? showColumnSize,
    Value<bool>? showColumnDate,
    Value<bool>? showColumnKind,
    Value<bool>? showColumnCreated,
    Value<bool>? showColumnPermissions,
    Value<bool>? showColumnOwner,
    Value<String>? columnOrder,
    Value<bool>? quickLookUseSystemFont,
    Value<String>? quickLookFontFamily,
    Value<int>? quickLookFontSize,
    Value<double>? quickLookLineHeight,
    Value<bool>? quickLookShowLineNumbers,
    Value<bool>? quickLookRelativeLineNumbers,
    Value<bool>? quickLookVimMode,
    Value<bool>? quickLookWrapLines,
    Value<bool>? quickLookShowStatistics,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      terminal: terminal ?? this.terminal,
      terminalShell: terminalShell ?? this.terminalShell,
      terminalCustomCommand:
          terminalCustomCommand ?? this.terminalCustomCommand,
      terminalUseSystemFont:
          terminalUseSystemFont ?? this.terminalUseSystemFont,
      terminalFontFamily: terminalFontFamily ?? this.terminalFontFamily,
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
      terminalLineHeight: terminalLineHeight ?? this.terminalLineHeight,
      isDual: isDual ?? this.isDual,
      splitRatio: splitRatio ?? this.splitRatio,
      activePaneIndex: activePaneIndex ?? this.activePaneIndex,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      restoreSession: restoreSession ?? this.restoreSession,
      defaultStartingPath: defaultStartingPath ?? this.defaultStartingPath,
      confirmDelete: confirmDelete ?? this.confirmDelete,
      confirmCopy: confirmCopy ?? this.confirmCopy,
      confirmMove: confirmMove ?? this.confirmMove,
      showHiddenDefault: showHiddenDefault ?? this.showHiddenDefault,
      rowDensity: rowDensity ?? this.rowDensity,
      fileListHorizontalSpacing:
          fileListHorizontalSpacing ?? this.fileListHorizontalSpacing,
      fileListVerticalSpacing:
          fileListVerticalSpacing ?? this.fileListVerticalSpacing,
      dateFormat: dateFormat ?? this.dateFormat,
      recentDatesRelative: recentDatesRelative ?? this.recentDatesRelative,
      deleteKeyBehavior: deleteKeyBehavior ?? this.deleteKeyBehavior,
      sortKey: sortKey ?? this.sortKey,
      sortAscending: sortAscending ?? this.sortAscending,
      foldersFirst: foldersFirst ?? this.foldersFirst,
      naturalSort: naturalSort ?? this.naturalSort,
      sortFolders: sortFolders ?? this.sortFolders,
      searchMode: searchMode ?? this.searchMode,
      rememberFolderState: rememberFolderState ?? this.rememberFolderState,
      rememberFolderSort: rememberFolderSort ?? this.rememberFolderSort,
      typeAheadBuffer: typeAheadBuffer ?? this.typeAheadBuffer,
      fileListScale: fileListScale ?? this.fileListScale,
      fileViewMode: fileViewMode ?? this.fileViewMode,
      showColumnSize: showColumnSize ?? this.showColumnSize,
      showColumnDate: showColumnDate ?? this.showColumnDate,
      showColumnKind: showColumnKind ?? this.showColumnKind,
      showColumnCreated: showColumnCreated ?? this.showColumnCreated,
      showColumnPermissions:
          showColumnPermissions ?? this.showColumnPermissions,
      showColumnOwner: showColumnOwner ?? this.showColumnOwner,
      columnOrder: columnOrder ?? this.columnOrder,
      quickLookUseSystemFont:
          quickLookUseSystemFont ?? this.quickLookUseSystemFont,
      quickLookFontFamily: quickLookFontFamily ?? this.quickLookFontFamily,
      quickLookFontSize: quickLookFontSize ?? this.quickLookFontSize,
      quickLookLineHeight: quickLookLineHeight ?? this.quickLookLineHeight,
      quickLookShowLineNumbers:
          quickLookShowLineNumbers ?? this.quickLookShowLineNumbers,
      quickLookRelativeLineNumbers:
          quickLookRelativeLineNumbers ?? this.quickLookRelativeLineNumbers,
      quickLookVimMode: quickLookVimMode ?? this.quickLookVimMode,
      quickLookWrapLines: quickLookWrapLines ?? this.quickLookWrapLines,
      quickLookShowStatistics:
          quickLookShowStatistics ?? this.quickLookShowStatistics,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (terminal.present) {
      map['terminal'] = Variable<String>(terminal.value);
    }
    if (terminalShell.present) {
      map['terminal_shell'] = Variable<String>(terminalShell.value);
    }
    if (terminalCustomCommand.present) {
      map['terminal_custom_command'] = Variable<String>(
        terminalCustomCommand.value,
      );
    }
    if (terminalUseSystemFont.present) {
      map['terminal_use_system_font'] = Variable<bool>(
        terminalUseSystemFont.value,
      );
    }
    if (terminalFontFamily.present) {
      map['terminal_font_family'] = Variable<String>(terminalFontFamily.value);
    }
    if (terminalFontSize.present) {
      map['terminal_font_size'] = Variable<int>(terminalFontSize.value);
    }
    if (terminalLineHeight.present) {
      map['terminal_line_height'] = Variable<double>(terminalLineHeight.value);
    }
    if (isDual.present) {
      map['is_dual'] = Variable<bool>(isDual.value);
    }
    if (splitRatio.present) {
      map['split_ratio'] = Variable<double>(splitRatio.value);
    }
    if (activePaneIndex.present) {
      map['active_pane_index'] = Variable<int>(activePaneIndex.value);
    }
    if (sidebarCollapsed.present) {
      map['sidebar_collapsed'] = Variable<bool>(sidebarCollapsed.value);
    }
    if (sidebarWidth.present) {
      map['sidebar_width'] = Variable<double>(sidebarWidth.value);
    }
    if (restoreSession.present) {
      map['restore_session'] = Variable<bool>(restoreSession.value);
    }
    if (defaultStartingPath.present) {
      map['default_starting_path'] = Variable<String>(
        defaultStartingPath.value,
      );
    }
    if (confirmDelete.present) {
      map['confirm_delete'] = Variable<bool>(confirmDelete.value);
    }
    if (confirmCopy.present) {
      map['confirm_copy'] = Variable<bool>(confirmCopy.value);
    }
    if (confirmMove.present) {
      map['confirm_move'] = Variable<bool>(confirmMove.value);
    }
    if (showHiddenDefault.present) {
      map['show_hidden_default'] = Variable<bool>(showHiddenDefault.value);
    }
    if (rowDensity.present) {
      map['row_density'] = Variable<String>(rowDensity.value);
    }
    if (fileListHorizontalSpacing.present) {
      map['file_list_horizontal_spacing'] = Variable<int>(
        fileListHorizontalSpacing.value,
      );
    }
    if (fileListVerticalSpacing.present) {
      map['file_list_vertical_spacing'] = Variable<int>(
        fileListVerticalSpacing.value,
      );
    }
    if (dateFormat.present) {
      map['date_format'] = Variable<String>(dateFormat.value);
    }
    if (recentDatesRelative.present) {
      map['recent_dates_relative'] = Variable<bool>(recentDatesRelative.value);
    }
    if (deleteKeyBehavior.present) {
      map['delete_key_behavior'] = Variable<String>(deleteKeyBehavior.value);
    }
    if (sortKey.present) {
      map['sort_key'] = Variable<String>(sortKey.value);
    }
    if (sortAscending.present) {
      map['sort_ascending'] = Variable<bool>(sortAscending.value);
    }
    if (foldersFirst.present) {
      map['folders_first'] = Variable<bool>(foldersFirst.value);
    }
    if (naturalSort.present) {
      map['natural_sort'] = Variable<bool>(naturalSort.value);
    }
    if (sortFolders.present) {
      map['sort_folders'] = Variable<bool>(sortFolders.value);
    }
    if (searchMode.present) {
      map['search_mode'] = Variable<String>(searchMode.value);
    }
    if (rememberFolderState.present) {
      map['remember_folder_state'] = Variable<bool>(rememberFolderState.value);
    }
    if (rememberFolderSort.present) {
      map['remember_folder_sort'] = Variable<bool>(rememberFolderSort.value);
    }
    if (typeAheadBuffer.present) {
      map['type_ahead_buffer'] = Variable<bool>(typeAheadBuffer.value);
    }
    if (fileListScale.present) {
      map['file_list_scale'] = Variable<double>(fileListScale.value);
    }
    if (fileViewMode.present) {
      map['file_view_mode'] = Variable<String>(fileViewMode.value);
    }
    if (showColumnSize.present) {
      map['show_column_size'] = Variable<bool>(showColumnSize.value);
    }
    if (showColumnDate.present) {
      map['show_column_date'] = Variable<bool>(showColumnDate.value);
    }
    if (showColumnKind.present) {
      map['show_column_kind'] = Variable<bool>(showColumnKind.value);
    }
    if (showColumnCreated.present) {
      map['show_column_created'] = Variable<bool>(showColumnCreated.value);
    }
    if (showColumnPermissions.present) {
      map['show_column_permissions'] = Variable<bool>(
        showColumnPermissions.value,
      );
    }
    if (showColumnOwner.present) {
      map['show_column_owner'] = Variable<bool>(showColumnOwner.value);
    }
    if (columnOrder.present) {
      map['column_order'] = Variable<String>(columnOrder.value);
    }
    if (quickLookUseSystemFont.present) {
      map['quick_look_use_system_font'] = Variable<bool>(
        quickLookUseSystemFont.value,
      );
    }
    if (quickLookFontFamily.present) {
      map['quick_look_font_family'] = Variable<String>(
        quickLookFontFamily.value,
      );
    }
    if (quickLookFontSize.present) {
      map['quick_look_font_size'] = Variable<int>(quickLookFontSize.value);
    }
    if (quickLookLineHeight.present) {
      map['quick_look_line_height'] = Variable<double>(
        quickLookLineHeight.value,
      );
    }
    if (quickLookShowLineNumbers.present) {
      map['quick_look_show_line_numbers'] = Variable<bool>(
        quickLookShowLineNumbers.value,
      );
    }
    if (quickLookRelativeLineNumbers.present) {
      map['quick_look_relative_line_numbers'] = Variable<bool>(
        quickLookRelativeLineNumbers.value,
      );
    }
    if (quickLookVimMode.present) {
      map['quick_look_vim_mode'] = Variable<bool>(quickLookVimMode.value);
    }
    if (quickLookWrapLines.present) {
      map['quick_look_wrap_lines'] = Variable<bool>(quickLookWrapLines.value);
    }
    if (quickLookShowStatistics.present) {
      map['quick_look_show_statistics'] = Variable<bool>(
        quickLookShowStatistics.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('terminal: $terminal, ')
          ..write('terminalShell: $terminalShell, ')
          ..write('terminalCustomCommand: $terminalCustomCommand, ')
          ..write('terminalUseSystemFont: $terminalUseSystemFont, ')
          ..write('terminalFontFamily: $terminalFontFamily, ')
          ..write('terminalFontSize: $terminalFontSize, ')
          ..write('terminalLineHeight: $terminalLineHeight, ')
          ..write('isDual: $isDual, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('activePaneIndex: $activePaneIndex, ')
          ..write('sidebarCollapsed: $sidebarCollapsed, ')
          ..write('sidebarWidth: $sidebarWidth, ')
          ..write('restoreSession: $restoreSession, ')
          ..write('defaultStartingPath: $defaultStartingPath, ')
          ..write('confirmDelete: $confirmDelete, ')
          ..write('confirmCopy: $confirmCopy, ')
          ..write('confirmMove: $confirmMove, ')
          ..write('showHiddenDefault: $showHiddenDefault, ')
          ..write('rowDensity: $rowDensity, ')
          ..write('fileListHorizontalSpacing: $fileListHorizontalSpacing, ')
          ..write('fileListVerticalSpacing: $fileListVerticalSpacing, ')
          ..write('dateFormat: $dateFormat, ')
          ..write('recentDatesRelative: $recentDatesRelative, ')
          ..write('deleteKeyBehavior: $deleteKeyBehavior, ')
          ..write('sortKey: $sortKey, ')
          ..write('sortAscending: $sortAscending, ')
          ..write('foldersFirst: $foldersFirst, ')
          ..write('naturalSort: $naturalSort, ')
          ..write('sortFolders: $sortFolders, ')
          ..write('searchMode: $searchMode, ')
          ..write('rememberFolderState: $rememberFolderState, ')
          ..write('rememberFolderSort: $rememberFolderSort, ')
          ..write('typeAheadBuffer: $typeAheadBuffer, ')
          ..write('fileListScale: $fileListScale, ')
          ..write('fileViewMode: $fileViewMode, ')
          ..write('showColumnSize: $showColumnSize, ')
          ..write('showColumnDate: $showColumnDate, ')
          ..write('showColumnKind: $showColumnKind, ')
          ..write('showColumnCreated: $showColumnCreated, ')
          ..write('showColumnPermissions: $showColumnPermissions, ')
          ..write('showColumnOwner: $showColumnOwner, ')
          ..write('columnOrder: $columnOrder, ')
          ..write('quickLookUseSystemFont: $quickLookUseSystemFont, ')
          ..write('quickLookFontFamily: $quickLookFontFamily, ')
          ..write('quickLookFontSize: $quickLookFontSize, ')
          ..write('quickLookLineHeight: $quickLookLineHeight, ')
          ..write('quickLookShowLineNumbers: $quickLookShowLineNumbers, ')
          ..write(
            'quickLookRelativeLineNumbers: $quickLookRelativeLineNumbers, ',
          )
          ..write('quickLookVimMode: $quickLookVimMode, ')
          ..write('quickLookWrapLines: $quickLookWrapLines, ')
          ..write('quickLookShowStatistics: $quickLookShowStatistics')
          ..write(')'))
        .toString();
  }
}

class $SessionTabsTable extends SessionTabs
    with TableInfo<$SessionTabsTable, SessionTab> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionTabsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _paneIndexMeta = const VerificationMeta(
    'paneIndex',
  );
  @override
  late final GeneratedColumn<int> paneIndex = GeneratedColumn<int>(
    'pane_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tabIndexMeta = const VerificationMeta(
    'tabIndex',
  );
  @override
  late final GeneratedColumn<int> tabIndex = GeneratedColumn<int>(
    'tab_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    paneIndex,
    tabIndex,
    path,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_tabs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionTab> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pane_index')) {
      context.handle(
        _paneIndexMeta,
        paneIndex.isAcceptableOrUnknown(data['pane_index']!, _paneIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_paneIndexMeta);
    }
    if (data.containsKey('tab_index')) {
      context.handle(
        _tabIndexMeta,
        tabIndex.isAcceptableOrUnknown(data['tab_index']!, _tabIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_tabIndexMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionTab map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionTab(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      paneIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pane_index'],
      )!,
      tabIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tab_index'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $SessionTabsTable createAlias(String alias) {
    return $SessionTabsTable(attachedDatabase, alias);
  }
}

class SessionTab extends DataClass implements Insertable<SessionTab> {
  final int id;
  final int paneIndex;
  final int tabIndex;
  final String path;
  final bool isActive;
  const SessionTab({
    required this.id,
    required this.paneIndex,
    required this.tabIndex,
    required this.path,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pane_index'] = Variable<int>(paneIndex);
    map['tab_index'] = Variable<int>(tabIndex);
    map['path'] = Variable<String>(path);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  SessionTabsCompanion toCompanion(bool nullToAbsent) {
    return SessionTabsCompanion(
      id: Value(id),
      paneIndex: Value(paneIndex),
      tabIndex: Value(tabIndex),
      path: Value(path),
      isActive: Value(isActive),
    );
  }

  factory SessionTab.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionTab(
      id: serializer.fromJson<int>(json['id']),
      paneIndex: serializer.fromJson<int>(json['paneIndex']),
      tabIndex: serializer.fromJson<int>(json['tabIndex']),
      path: serializer.fromJson<String>(json['path']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'paneIndex': serializer.toJson<int>(paneIndex),
      'tabIndex': serializer.toJson<int>(tabIndex),
      'path': serializer.toJson<String>(path),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  SessionTab copyWith({
    int? id,
    int? paneIndex,
    int? tabIndex,
    String? path,
    bool? isActive,
  }) => SessionTab(
    id: id ?? this.id,
    paneIndex: paneIndex ?? this.paneIndex,
    tabIndex: tabIndex ?? this.tabIndex,
    path: path ?? this.path,
    isActive: isActive ?? this.isActive,
  );
  SessionTab copyWithCompanion(SessionTabsCompanion data) {
    return SessionTab(
      id: data.id.present ? data.id.value : this.id,
      paneIndex: data.paneIndex.present ? data.paneIndex.value : this.paneIndex,
      tabIndex: data.tabIndex.present ? data.tabIndex.value : this.tabIndex,
      path: data.path.present ? data.path.value : this.path,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionTab(')
          ..write('id: $id, ')
          ..write('paneIndex: $paneIndex, ')
          ..write('tabIndex: $tabIndex, ')
          ..write('path: $path, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, paneIndex, tabIndex, path, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionTab &&
          other.id == this.id &&
          other.paneIndex == this.paneIndex &&
          other.tabIndex == this.tabIndex &&
          other.path == this.path &&
          other.isActive == this.isActive);
}

class SessionTabsCompanion extends UpdateCompanion<SessionTab> {
  final Value<int> id;
  final Value<int> paneIndex;
  final Value<int> tabIndex;
  final Value<String> path;
  final Value<bool> isActive;
  const SessionTabsCompanion({
    this.id = const Value.absent(),
    this.paneIndex = const Value.absent(),
    this.tabIndex = const Value.absent(),
    this.path = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  SessionTabsCompanion.insert({
    this.id = const Value.absent(),
    required int paneIndex,
    required int tabIndex,
    required String path,
    this.isActive = const Value.absent(),
  }) : paneIndex = Value(paneIndex),
       tabIndex = Value(tabIndex),
       path = Value(path);
  static Insertable<SessionTab> custom({
    Expression<int>? id,
    Expression<int>? paneIndex,
    Expression<int>? tabIndex,
    Expression<String>? path,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (paneIndex != null) 'pane_index': paneIndex,
      if (tabIndex != null) 'tab_index': tabIndex,
      if (path != null) 'path': path,
      if (isActive != null) 'is_active': isActive,
    });
  }

  SessionTabsCompanion copyWith({
    Value<int>? id,
    Value<int>? paneIndex,
    Value<int>? tabIndex,
    Value<String>? path,
    Value<bool>? isActive,
  }) {
    return SessionTabsCompanion(
      id: id ?? this.id,
      paneIndex: paneIndex ?? this.paneIndex,
      tabIndex: tabIndex ?? this.tabIndex,
      path: path ?? this.path,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (paneIndex.present) {
      map['pane_index'] = Variable<int>(paneIndex.value);
    }
    if (tabIndex.present) {
      map['tab_index'] = Variable<int>(tabIndex.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionTabsCompanion(')
          ..write('id: $id, ')
          ..write('paneIndex: $paneIndex, ')
          ..write('tabIndex: $tabIndex, ')
          ..write('path: $path, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, Bookmark> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, orderIndex, label, path];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bookmark> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Bookmark map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bookmark(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class Bookmark extends DataClass implements Insertable<Bookmark> {
  final int id;
  final int orderIndex;
  final String label;
  final String path;
  const Bookmark({
    required this.id,
    required this.orderIndex,
    required this.label,
    required this.path,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_index'] = Variable<int>(orderIndex);
    map['label'] = Variable<String>(label);
    map['path'] = Variable<String>(path);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      orderIndex: Value(orderIndex),
      label: Value(label),
      path: Value(path),
    );
  }

  factory Bookmark.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bookmark(
      id: serializer.fromJson<int>(json['id']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      label: serializer.fromJson<String>(json['label']),
      path: serializer.fromJson<String>(json['path']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'label': serializer.toJson<String>(label),
      'path': serializer.toJson<String>(path),
    };
  }

  Bookmark copyWith({int? id, int? orderIndex, String? label, String? path}) =>
      Bookmark(
        id: id ?? this.id,
        orderIndex: orderIndex ?? this.orderIndex,
        label: label ?? this.label,
        path: path ?? this.path,
      );
  Bookmark copyWithCompanion(BookmarksCompanion data) {
    return Bookmark(
      id: data.id.present ? data.id.value : this.id,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      label: data.label.present ? data.label.value : this.label,
      path: data.path.present ? data.path.value : this.path,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bookmark(')
          ..write('id: $id, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('label: $label, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, orderIndex, label, path);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bookmark &&
          other.id == this.id &&
          other.orderIndex == this.orderIndex &&
          other.label == this.label &&
          other.path == this.path);
}

class BookmarksCompanion extends UpdateCompanion<Bookmark> {
  final Value<int> id;
  final Value<int> orderIndex;
  final Value<String> label;
  final Value<String> path;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.label = const Value.absent(),
    this.path = const Value.absent(),
  });
  BookmarksCompanion.insert({
    this.id = const Value.absent(),
    required int orderIndex,
    required String label,
    required String path,
  }) : orderIndex = Value(orderIndex),
       label = Value(label),
       path = Value(path);
  static Insertable<Bookmark> custom({
    Expression<int>? id,
    Expression<int>? orderIndex,
    Expression<String>? label,
    Expression<String>? path,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderIndex != null) 'order_index': orderIndex,
      if (label != null) 'label': label,
      if (path != null) 'path': path,
    });
  }

  BookmarksCompanion copyWith({
    Value<int>? id,
    Value<int>? orderIndex,
    Value<String>? label,
    Value<String>? path,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      orderIndex: orderIndex ?? this.orderIndex,
      label: label ?? this.label,
      path: path ?? this.path,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('label: $label, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }
}

class $FolderPrefsTable extends FolderPrefs
    with TableInfo<$FolderPrefsTable, FolderPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FolderPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortKeyMeta = const VerificationMeta(
    'sortKey',
  );
  @override
  late final GeneratedColumn<String> sortKey = GeneratedColumn<String>(
    'sort_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('name'),
  );
  static const VerificationMeta _sortAscendingMeta = const VerificationMeta(
    'sortAscending',
  );
  @override
  late final GeneratedColumn<bool> sortAscending = GeneratedColumn<bool>(
    'sort_ascending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sort_ascending" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _foldersFirstMeta = const VerificationMeta(
    'foldersFirst',
  );
  @override
  late final GeneratedColumn<bool> foldersFirst = GeneratedColumn<bool>(
    'folders_first',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("folders_first" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cursorPathMeta = const VerificationMeta(
    'cursorPath',
  );
  @override
  late final GeneratedColumn<String> cursorPath = GeneratedColumn<String>(
    'cursor_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _selectedPathsMeta = const VerificationMeta(
    'selectedPaths',
  );
  @override
  late final GeneratedColumn<String> selectedPaths = GeneratedColumn<String>(
    'selected_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    path,
    sortKey,
    sortAscending,
    foldersFirst,
    cursorPath,
    selectedPaths,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'folder_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<FolderPref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('sort_key')) {
      context.handle(
        _sortKeyMeta,
        sortKey.isAcceptableOrUnknown(data['sort_key']!, _sortKeyMeta),
      );
    }
    if (data.containsKey('sort_ascending')) {
      context.handle(
        _sortAscendingMeta,
        sortAscending.isAcceptableOrUnknown(
          data['sort_ascending']!,
          _sortAscendingMeta,
        ),
      );
    }
    if (data.containsKey('folders_first')) {
      context.handle(
        _foldersFirstMeta,
        foldersFirst.isAcceptableOrUnknown(
          data['folders_first']!,
          _foldersFirstMeta,
        ),
      );
    }
    if (data.containsKey('cursor_path')) {
      context.handle(
        _cursorPathMeta,
        cursorPath.isAcceptableOrUnknown(data['cursor_path']!, _cursorPathMeta),
      );
    }
    if (data.containsKey('selected_paths')) {
      context.handle(
        _selectedPathsMeta,
        selectedPaths.isAcceptableOrUnknown(
          data['selected_paths']!,
          _selectedPathsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  FolderPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FolderPref(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      sortKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sort_key'],
      )!,
      sortAscending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sort_ascending'],
      )!,
      foldersFirst: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}folders_first'],
      )!,
      cursorPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor_path'],
      ),
      selectedPaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_paths'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FolderPrefsTable createAlias(String alias) {
    return $FolderPrefsTable(attachedDatabase, alias);
  }
}

class FolderPref extends DataClass implements Insertable<FolderPref> {
  final String path;
  final String sortKey;
  final bool sortAscending;
  final bool foldersFirst;
  final String? cursorPath;
  final String? selectedPaths;
  final int updatedAt;
  const FolderPref({
    required this.path,
    required this.sortKey,
    required this.sortAscending,
    required this.foldersFirst,
    this.cursorPath,
    this.selectedPaths,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['sort_key'] = Variable<String>(sortKey);
    map['sort_ascending'] = Variable<bool>(sortAscending);
    map['folders_first'] = Variable<bool>(foldersFirst);
    if (!nullToAbsent || cursorPath != null) {
      map['cursor_path'] = Variable<String>(cursorPath);
    }
    if (!nullToAbsent || selectedPaths != null) {
      map['selected_paths'] = Variable<String>(selectedPaths);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FolderPrefsCompanion toCompanion(bool nullToAbsent) {
    return FolderPrefsCompanion(
      path: Value(path),
      sortKey: Value(sortKey),
      sortAscending: Value(sortAscending),
      foldersFirst: Value(foldersFirst),
      cursorPath: cursorPath == null && nullToAbsent
          ? const Value.absent()
          : Value(cursorPath),
      selectedPaths: selectedPaths == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedPaths),
      updatedAt: Value(updatedAt),
    );
  }

  factory FolderPref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FolderPref(
      path: serializer.fromJson<String>(json['path']),
      sortKey: serializer.fromJson<String>(json['sortKey']),
      sortAscending: serializer.fromJson<bool>(json['sortAscending']),
      foldersFirst: serializer.fromJson<bool>(json['foldersFirst']),
      cursorPath: serializer.fromJson<String?>(json['cursorPath']),
      selectedPaths: serializer.fromJson<String?>(json['selectedPaths']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'sortKey': serializer.toJson<String>(sortKey),
      'sortAscending': serializer.toJson<bool>(sortAscending),
      'foldersFirst': serializer.toJson<bool>(foldersFirst),
      'cursorPath': serializer.toJson<String?>(cursorPath),
      'selectedPaths': serializer.toJson<String?>(selectedPaths),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  FolderPref copyWith({
    String? path,
    String? sortKey,
    bool? sortAscending,
    bool? foldersFirst,
    Value<String?> cursorPath = const Value.absent(),
    Value<String?> selectedPaths = const Value.absent(),
    int? updatedAt,
  }) => FolderPref(
    path: path ?? this.path,
    sortKey: sortKey ?? this.sortKey,
    sortAscending: sortAscending ?? this.sortAscending,
    foldersFirst: foldersFirst ?? this.foldersFirst,
    cursorPath: cursorPath.present ? cursorPath.value : this.cursorPath,
    selectedPaths: selectedPaths.present
        ? selectedPaths.value
        : this.selectedPaths,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FolderPref copyWithCompanion(FolderPrefsCompanion data) {
    return FolderPref(
      path: data.path.present ? data.path.value : this.path,
      sortKey: data.sortKey.present ? data.sortKey.value : this.sortKey,
      sortAscending: data.sortAscending.present
          ? data.sortAscending.value
          : this.sortAscending,
      foldersFirst: data.foldersFirst.present
          ? data.foldersFirst.value
          : this.foldersFirst,
      cursorPath: data.cursorPath.present
          ? data.cursorPath.value
          : this.cursorPath,
      selectedPaths: data.selectedPaths.present
          ? data.selectedPaths.value
          : this.selectedPaths,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FolderPref(')
          ..write('path: $path, ')
          ..write('sortKey: $sortKey, ')
          ..write('sortAscending: $sortAscending, ')
          ..write('foldersFirst: $foldersFirst, ')
          ..write('cursorPath: $cursorPath, ')
          ..write('selectedPaths: $selectedPaths, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    path,
    sortKey,
    sortAscending,
    foldersFirst,
    cursorPath,
    selectedPaths,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderPref &&
          other.path == this.path &&
          other.sortKey == this.sortKey &&
          other.sortAscending == this.sortAscending &&
          other.foldersFirst == this.foldersFirst &&
          other.cursorPath == this.cursorPath &&
          other.selectedPaths == this.selectedPaths &&
          other.updatedAt == this.updatedAt);
}

class FolderPrefsCompanion extends UpdateCompanion<FolderPref> {
  final Value<String> path;
  final Value<String> sortKey;
  final Value<bool> sortAscending;
  final Value<bool> foldersFirst;
  final Value<String?> cursorPath;
  final Value<String?> selectedPaths;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const FolderPrefsCompanion({
    this.path = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.foldersFirst = const Value.absent(),
    this.cursorPath = const Value.absent(),
    this.selectedPaths = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FolderPrefsCompanion.insert({
    required String path,
    this.sortKey = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.foldersFirst = const Value.absent(),
    this.cursorPath = const Value.absent(),
    this.selectedPaths = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : path = Value(path);
  static Insertable<FolderPref> custom({
    Expression<String>? path,
    Expression<String>? sortKey,
    Expression<bool>? sortAscending,
    Expression<bool>? foldersFirst,
    Expression<String>? cursorPath,
    Expression<String>? selectedPaths,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (sortKey != null) 'sort_key': sortKey,
      if (sortAscending != null) 'sort_ascending': sortAscending,
      if (foldersFirst != null) 'folders_first': foldersFirst,
      if (cursorPath != null) 'cursor_path': cursorPath,
      if (selectedPaths != null) 'selected_paths': selectedPaths,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FolderPrefsCompanion copyWith({
    Value<String>? path,
    Value<String>? sortKey,
    Value<bool>? sortAscending,
    Value<bool>? foldersFirst,
    Value<String?>? cursorPath,
    Value<String?>? selectedPaths,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return FolderPrefsCompanion(
      path: path ?? this.path,
      sortKey: sortKey ?? this.sortKey,
      sortAscending: sortAscending ?? this.sortAscending,
      foldersFirst: foldersFirst ?? this.foldersFirst,
      cursorPath: cursorPath ?? this.cursorPath,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sortKey.present) {
      map['sort_key'] = Variable<String>(sortKey.value);
    }
    if (sortAscending.present) {
      map['sort_ascending'] = Variable<bool>(sortAscending.value);
    }
    if (foldersFirst.present) {
      map['folders_first'] = Variable<bool>(foldersFirst.value);
    }
    if (cursorPath.present) {
      map['cursor_path'] = Variable<String>(cursorPath.value);
    }
    if (selectedPaths.present) {
      map['selected_paths'] = Variable<String>(selectedPaths.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FolderPrefsCompanion(')
          ..write('path: $path, ')
          ..write('sortKey: $sortKey, ')
          ..write('sortAscending: $sortAscending, ')
          ..write('foldersFirst: $foldersFirst, ')
          ..write('cursorPath: $cursorPath, ')
          ..write('selectedPaths: $selectedPaths, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecentAppsTable extends RecentApps
    with TableInfo<$RecentAppsTable, RecentApp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentAppsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mimeMeta = const VerificationMeta('mime');
  @override
  late final GeneratedColumn<String> mime = GeneratedColumn<String>(
    'mime',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
    'app_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appExecMeta = const VerificationMeta(
    'appExec',
  );
  @override
  late final GeneratedColumn<String> appExec = GeneratedColumn<String>(
    'app_exec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconPathMeta = const VerificationMeta(
    'iconPath',
  );
  @override
  late final GeneratedColumn<String> iconPath = GeneratedColumn<String>(
    'icon_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<int> usedAt = GeneratedColumn<int>(
    'used_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    mime,
    appId,
    appName,
    appExec,
    iconPath,
    usedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_apps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentApp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mime')) {
      context.handle(
        _mimeMeta,
        mime.isAcceptableOrUnknown(data['mime']!, _mimeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
        _appIdMeta,
        appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta),
      );
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('app_exec')) {
      context.handle(
        _appExecMeta,
        appExec.isAcceptableOrUnknown(data['app_exec']!, _appExecMeta),
      );
    } else if (isInserting) {
      context.missing(_appExecMeta);
    }
    if (data.containsKey('icon_path')) {
      context.handle(
        _iconPathMeta,
        iconPath.isAcceptableOrUnknown(data['icon_path']!, _iconPathMeta),
      );
    }
    if (data.containsKey('used_at')) {
      context.handle(
        _usedAtMeta,
        usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mime, appId};
  @override
  RecentApp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentApp(
      mime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime'],
      )!,
      appId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_id'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      appExec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_exec'],
      )!,
      iconPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_path'],
      ),
      usedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_at'],
      )!,
    );
  }

  @override
  $RecentAppsTable createAlias(String alias) {
    return $RecentAppsTable(attachedDatabase, alias);
  }
}

class RecentApp extends DataClass implements Insertable<RecentApp> {
  final String mime;
  final String appId;
  final String appName;
  final String appExec;
  final String? iconPath;
  final int usedAt;
  const RecentApp({
    required this.mime,
    required this.appId,
    required this.appName,
    required this.appExec,
    this.iconPath,
    required this.usedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mime'] = Variable<String>(mime);
    map['app_id'] = Variable<String>(appId);
    map['app_name'] = Variable<String>(appName);
    map['app_exec'] = Variable<String>(appExec);
    if (!nullToAbsent || iconPath != null) {
      map['icon_path'] = Variable<String>(iconPath);
    }
    map['used_at'] = Variable<int>(usedAt);
    return map;
  }

  RecentAppsCompanion toCompanion(bool nullToAbsent) {
    return RecentAppsCompanion(
      mime: Value(mime),
      appId: Value(appId),
      appName: Value(appName),
      appExec: Value(appExec),
      iconPath: iconPath == null && nullToAbsent
          ? const Value.absent()
          : Value(iconPath),
      usedAt: Value(usedAt),
    );
  }

  factory RecentApp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentApp(
      mime: serializer.fromJson<String>(json['mime']),
      appId: serializer.fromJson<String>(json['appId']),
      appName: serializer.fromJson<String>(json['appName']),
      appExec: serializer.fromJson<String>(json['appExec']),
      iconPath: serializer.fromJson<String?>(json['iconPath']),
      usedAt: serializer.fromJson<int>(json['usedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mime': serializer.toJson<String>(mime),
      'appId': serializer.toJson<String>(appId),
      'appName': serializer.toJson<String>(appName),
      'appExec': serializer.toJson<String>(appExec),
      'iconPath': serializer.toJson<String?>(iconPath),
      'usedAt': serializer.toJson<int>(usedAt),
    };
  }

  RecentApp copyWith({
    String? mime,
    String? appId,
    String? appName,
    String? appExec,
    Value<String?> iconPath = const Value.absent(),
    int? usedAt,
  }) => RecentApp(
    mime: mime ?? this.mime,
    appId: appId ?? this.appId,
    appName: appName ?? this.appName,
    appExec: appExec ?? this.appExec,
    iconPath: iconPath.present ? iconPath.value : this.iconPath,
    usedAt: usedAt ?? this.usedAt,
  );
  RecentApp copyWithCompanion(RecentAppsCompanion data) {
    return RecentApp(
      mime: data.mime.present ? data.mime.value : this.mime,
      appId: data.appId.present ? data.appId.value : this.appId,
      appName: data.appName.present ? data.appName.value : this.appName,
      appExec: data.appExec.present ? data.appExec.value : this.appExec,
      iconPath: data.iconPath.present ? data.iconPath.value : this.iconPath,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentApp(')
          ..write('mime: $mime, ')
          ..write('appId: $appId, ')
          ..write('appName: $appName, ')
          ..write('appExec: $appExec, ')
          ..write('iconPath: $iconPath, ')
          ..write('usedAt: $usedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(mime, appId, appName, appExec, iconPath, usedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentApp &&
          other.mime == this.mime &&
          other.appId == this.appId &&
          other.appName == this.appName &&
          other.appExec == this.appExec &&
          other.iconPath == this.iconPath &&
          other.usedAt == this.usedAt);
}

class RecentAppsCompanion extends UpdateCompanion<RecentApp> {
  final Value<String> mime;
  final Value<String> appId;
  final Value<String> appName;
  final Value<String> appExec;
  final Value<String?> iconPath;
  final Value<int> usedAt;
  final Value<int> rowid;
  const RecentAppsCompanion({
    this.mime = const Value.absent(),
    this.appId = const Value.absent(),
    this.appName = const Value.absent(),
    this.appExec = const Value.absent(),
    this.iconPath = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentAppsCompanion.insert({
    required String mime,
    required String appId,
    required String appName,
    required String appExec,
    this.iconPath = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mime = Value(mime),
       appId = Value(appId),
       appName = Value(appName),
       appExec = Value(appExec);
  static Insertable<RecentApp> custom({
    Expression<String>? mime,
    Expression<String>? appId,
    Expression<String>? appName,
    Expression<String>? appExec,
    Expression<String>? iconPath,
    Expression<int>? usedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mime != null) 'mime': mime,
      if (appId != null) 'app_id': appId,
      if (appName != null) 'app_name': appName,
      if (appExec != null) 'app_exec': appExec,
      if (iconPath != null) 'icon_path': iconPath,
      if (usedAt != null) 'used_at': usedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentAppsCompanion copyWith({
    Value<String>? mime,
    Value<String>? appId,
    Value<String>? appName,
    Value<String>? appExec,
    Value<String?>? iconPath,
    Value<int>? usedAt,
    Value<int>? rowid,
  }) {
    return RecentAppsCompanion(
      mime: mime ?? this.mime,
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      appExec: appExec ?? this.appExec,
      iconPath: iconPath ?? this.iconPath,
      usedAt: usedAt ?? this.usedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mime.present) {
      map['mime'] = Variable<String>(mime.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (appExec.present) {
      map['app_exec'] = Variable<String>(appExec.value);
    }
    if (iconPath.present) {
      map['icon_path'] = Variable<String>(iconPath.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<int>(usedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentAppsCompanion(')
          ..write('mime: $mime, ')
          ..write('appId: $appId, ')
          ..write('appName: $appName, ')
          ..write('appExec: $appExec, ')
          ..write('iconPath: $iconPath, ')
          ..write('usedAt: $usedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecentEnteredPathsTable extends RecentEnteredPaths
    with TableInfo<$RecentEnteredPathsTable, RecentEnteredPath> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentEnteredPathsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedAtMeta = const VerificationMeta('usedAt');
  @override
  late final GeneratedColumn<int> usedAt = GeneratedColumn<int>(
    'used_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [path, usedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recent_entered_paths';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentEnteredPath> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('used_at')) {
      context.handle(
        _usedAtMeta,
        usedAt.isAcceptableOrUnknown(data['used_at']!, _usedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {path};
  @override
  RecentEnteredPath map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentEnteredPath(
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      usedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_at'],
      )!,
    );
  }

  @override
  $RecentEnteredPathsTable createAlias(String alias) {
    return $RecentEnteredPathsTable(attachedDatabase, alias);
  }
}

class RecentEnteredPath extends DataClass
    implements Insertable<RecentEnteredPath> {
  final String path;
  final int usedAt;
  const RecentEnteredPath({required this.path, required this.usedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['used_at'] = Variable<int>(usedAt);
    return map;
  }

  RecentEnteredPathsCompanion toCompanion(bool nullToAbsent) {
    return RecentEnteredPathsCompanion(
      path: Value(path),
      usedAt: Value(usedAt),
    );
  }

  factory RecentEnteredPath.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentEnteredPath(
      path: serializer.fromJson<String>(json['path']),
      usedAt: serializer.fromJson<int>(json['usedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'path': serializer.toJson<String>(path),
      'usedAt': serializer.toJson<int>(usedAt),
    };
  }

  RecentEnteredPath copyWith({String? path, int? usedAt}) =>
      RecentEnteredPath(path: path ?? this.path, usedAt: usedAt ?? this.usedAt);
  RecentEnteredPath copyWithCompanion(RecentEnteredPathsCompanion data) {
    return RecentEnteredPath(
      path: data.path.present ? data.path.value : this.path,
      usedAt: data.usedAt.present ? data.usedAt.value : this.usedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentEnteredPath(')
          ..write('path: $path, ')
          ..write('usedAt: $usedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(path, usedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentEnteredPath &&
          other.path == this.path &&
          other.usedAt == this.usedAt);
}

class RecentEnteredPathsCompanion extends UpdateCompanion<RecentEnteredPath> {
  final Value<String> path;
  final Value<int> usedAt;
  final Value<int> rowid;
  const RecentEnteredPathsCompanion({
    this.path = const Value.absent(),
    this.usedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentEnteredPathsCompanion.insert({
    required String path,
    this.usedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : path = Value(path);
  static Insertable<RecentEnteredPath> custom({
    Expression<String>? path,
    Expression<int>? usedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (usedAt != null) 'used_at': usedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentEnteredPathsCompanion copyWith({
    Value<String>? path,
    Value<int>? usedAt,
    Value<int>? rowid,
  }) {
    return RecentEnteredPathsCompanion(
      path: path ?? this.path,
      usedAt: usedAt ?? this.usedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (usedAt.present) {
      map['used_at'] = Variable<int>(usedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentEnteredPathsCompanion(')
          ..write('path: $path, ')
          ..write('usedAt: $usedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DefaultAppsTable extends DefaultApps
    with TableInfo<$DefaultAppsTable, DefaultApp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DefaultAppsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _typeKeyMeta = const VerificationMeta(
    'typeKey',
  );
  @override
  late final GeneratedColumn<String> typeKey = GeneratedColumn<String>(
    'type_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appIdMeta = const VerificationMeta('appId');
  @override
  late final GeneratedColumn<String> appId = GeneratedColumn<String>(
    'app_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appExecMeta = const VerificationMeta(
    'appExec',
  );
  @override
  late final GeneratedColumn<String> appExec = GeneratedColumn<String>(
    'app_exec',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconPathMeta = const VerificationMeta(
    'iconPath',
  );
  @override
  late final GeneratedColumn<String> iconPath = GeneratedColumn<String>(
    'icon_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    typeKey,
    appId,
    appName,
    appExec,
    iconPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'default_apps';
  @override
  VerificationContext validateIntegrity(
    Insertable<DefaultApp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('type_key')) {
      context.handle(
        _typeKeyMeta,
        typeKey.isAcceptableOrUnknown(data['type_key']!, _typeKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_typeKeyMeta);
    }
    if (data.containsKey('app_id')) {
      context.handle(
        _appIdMeta,
        appId.isAcceptableOrUnknown(data['app_id']!, _appIdMeta),
      );
    } else if (isInserting) {
      context.missing(_appIdMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('app_exec')) {
      context.handle(
        _appExecMeta,
        appExec.isAcceptableOrUnknown(data['app_exec']!, _appExecMeta),
      );
    } else if (isInserting) {
      context.missing(_appExecMeta);
    }
    if (data.containsKey('icon_path')) {
      context.handle(
        _iconPathMeta,
        iconPath.isAcceptableOrUnknown(data['icon_path']!, _iconPathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {typeKey};
  @override
  DefaultApp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DefaultApp(
      typeKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_key'],
      )!,
      appId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_id'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      appExec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_exec'],
      )!,
      iconPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_path'],
      ),
    );
  }

  @override
  $DefaultAppsTable createAlias(String alias) {
    return $DefaultAppsTable(attachedDatabase, alias);
  }
}

class DefaultApp extends DataClass implements Insertable<DefaultApp> {
  final String typeKey;
  final String appId;
  final String appName;
  final String appExec;
  final String? iconPath;
  const DefaultApp({
    required this.typeKey,
    required this.appId,
    required this.appName,
    required this.appExec,
    this.iconPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['type_key'] = Variable<String>(typeKey);
    map['app_id'] = Variable<String>(appId);
    map['app_name'] = Variable<String>(appName);
    map['app_exec'] = Variable<String>(appExec);
    if (!nullToAbsent || iconPath != null) {
      map['icon_path'] = Variable<String>(iconPath);
    }
    return map;
  }

  DefaultAppsCompanion toCompanion(bool nullToAbsent) {
    return DefaultAppsCompanion(
      typeKey: Value(typeKey),
      appId: Value(appId),
      appName: Value(appName),
      appExec: Value(appExec),
      iconPath: iconPath == null && nullToAbsent
          ? const Value.absent()
          : Value(iconPath),
    );
  }

  factory DefaultApp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DefaultApp(
      typeKey: serializer.fromJson<String>(json['typeKey']),
      appId: serializer.fromJson<String>(json['appId']),
      appName: serializer.fromJson<String>(json['appName']),
      appExec: serializer.fromJson<String>(json['appExec']),
      iconPath: serializer.fromJson<String?>(json['iconPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'typeKey': serializer.toJson<String>(typeKey),
      'appId': serializer.toJson<String>(appId),
      'appName': serializer.toJson<String>(appName),
      'appExec': serializer.toJson<String>(appExec),
      'iconPath': serializer.toJson<String?>(iconPath),
    };
  }

  DefaultApp copyWith({
    String? typeKey,
    String? appId,
    String? appName,
    String? appExec,
    Value<String?> iconPath = const Value.absent(),
  }) => DefaultApp(
    typeKey: typeKey ?? this.typeKey,
    appId: appId ?? this.appId,
    appName: appName ?? this.appName,
    appExec: appExec ?? this.appExec,
    iconPath: iconPath.present ? iconPath.value : this.iconPath,
  );
  DefaultApp copyWithCompanion(DefaultAppsCompanion data) {
    return DefaultApp(
      typeKey: data.typeKey.present ? data.typeKey.value : this.typeKey,
      appId: data.appId.present ? data.appId.value : this.appId,
      appName: data.appName.present ? data.appName.value : this.appName,
      appExec: data.appExec.present ? data.appExec.value : this.appExec,
      iconPath: data.iconPath.present ? data.iconPath.value : this.iconPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DefaultApp(')
          ..write('typeKey: $typeKey, ')
          ..write('appId: $appId, ')
          ..write('appName: $appName, ')
          ..write('appExec: $appExec, ')
          ..write('iconPath: $iconPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(typeKey, appId, appName, appExec, iconPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DefaultApp &&
          other.typeKey == this.typeKey &&
          other.appId == this.appId &&
          other.appName == this.appName &&
          other.appExec == this.appExec &&
          other.iconPath == this.iconPath);
}

class DefaultAppsCompanion extends UpdateCompanion<DefaultApp> {
  final Value<String> typeKey;
  final Value<String> appId;
  final Value<String> appName;
  final Value<String> appExec;
  final Value<String?> iconPath;
  final Value<int> rowid;
  const DefaultAppsCompanion({
    this.typeKey = const Value.absent(),
    this.appId = const Value.absent(),
    this.appName = const Value.absent(),
    this.appExec = const Value.absent(),
    this.iconPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DefaultAppsCompanion.insert({
    required String typeKey,
    required String appId,
    required String appName,
    required String appExec,
    this.iconPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : typeKey = Value(typeKey),
       appId = Value(appId),
       appName = Value(appName),
       appExec = Value(appExec);
  static Insertable<DefaultApp> custom({
    Expression<String>? typeKey,
    Expression<String>? appId,
    Expression<String>? appName,
    Expression<String>? appExec,
    Expression<String>? iconPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (typeKey != null) 'type_key': typeKey,
      if (appId != null) 'app_id': appId,
      if (appName != null) 'app_name': appName,
      if (appExec != null) 'app_exec': appExec,
      if (iconPath != null) 'icon_path': iconPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DefaultAppsCompanion copyWith({
    Value<String>? typeKey,
    Value<String>? appId,
    Value<String>? appName,
    Value<String>? appExec,
    Value<String?>? iconPath,
    Value<int>? rowid,
  }) {
    return DefaultAppsCompanion(
      typeKey: typeKey ?? this.typeKey,
      appId: appId ?? this.appId,
      appName: appName ?? this.appName,
      appExec: appExec ?? this.appExec,
      iconPath: iconPath ?? this.iconPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (typeKey.present) {
      map['type_key'] = Variable<String>(typeKey.value);
    }
    if (appId.present) {
      map['app_id'] = Variable<String>(appId.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (appExec.present) {
      map['app_exec'] = Variable<String>(appExec.value);
    }
    if (iconPath.present) {
      map['icon_path'] = Variable<String>(iconPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DefaultAppsCompanion(')
          ..write('typeKey: $typeKey, ')
          ..write('appId: $appId, ')
          ..write('appName: $appName, ')
          ..write('appExec: $appExec, ')
          ..write('iconPath: $iconPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShortcutBindingsTable extends ShortcutBindings
    with TableInfo<$ShortcutBindingsTable, ShortcutBinding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShortcutBindingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _actionIdMeta = const VerificationMeta(
    'actionId',
  );
  @override
  late final GeneratedColumn<String> actionId = GeneratedColumn<String>(
    'action_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyIdMeta = const VerificationMeta('keyId');
  @override
  late final GeneratedColumn<int> keyId = GeneratedColumn<int>(
    'key_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ctrlMeta = const VerificationMeta('ctrl');
  @override
  late final GeneratedColumn<bool> ctrl = GeneratedColumn<bool>(
    'ctrl',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ctrl" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _shiftMeta = const VerificationMeta('shift');
  @override
  late final GeneratedColumn<bool> shift = GeneratedColumn<bool>(
    'shift',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shift" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _altMeta = const VerificationMeta('alt');
  @override
  late final GeneratedColumn<bool> alt = GeneratedColumn<bool>(
    'alt',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("alt" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [actionId, keyId, ctrl, shift, alt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shortcut_bindings';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShortcutBinding> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('action_id')) {
      context.handle(
        _actionIdMeta,
        actionId.isAcceptableOrUnknown(data['action_id']!, _actionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_actionIdMeta);
    }
    if (data.containsKey('key_id')) {
      context.handle(
        _keyIdMeta,
        keyId.isAcceptableOrUnknown(data['key_id']!, _keyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_keyIdMeta);
    }
    if (data.containsKey('ctrl')) {
      context.handle(
        _ctrlMeta,
        ctrl.isAcceptableOrUnknown(data['ctrl']!, _ctrlMeta),
      );
    }
    if (data.containsKey('shift')) {
      context.handle(
        _shiftMeta,
        shift.isAcceptableOrUnknown(data['shift']!, _shiftMeta),
      );
    }
    if (data.containsKey('alt')) {
      context.handle(
        _altMeta,
        alt.isAcceptableOrUnknown(data['alt']!, _altMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {actionId};
  @override
  ShortcutBinding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShortcutBinding(
      actionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_id'],
      )!,
      keyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}key_id'],
      )!,
      ctrl: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ctrl'],
      )!,
      shift: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shift'],
      )!,
      alt: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}alt'],
      )!,
    );
  }

  @override
  $ShortcutBindingsTable createAlias(String alias) {
    return $ShortcutBindingsTable(attachedDatabase, alias);
  }
}

class ShortcutBinding extends DataClass implements Insertable<ShortcutBinding> {
  final String actionId;
  final int keyId;
  final bool ctrl;
  final bool shift;
  final bool alt;
  const ShortcutBinding({
    required this.actionId,
    required this.keyId,
    required this.ctrl,
    required this.shift,
    required this.alt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['action_id'] = Variable<String>(actionId);
    map['key_id'] = Variable<int>(keyId);
    map['ctrl'] = Variable<bool>(ctrl);
    map['shift'] = Variable<bool>(shift);
    map['alt'] = Variable<bool>(alt);
    return map;
  }

  ShortcutBindingsCompanion toCompanion(bool nullToAbsent) {
    return ShortcutBindingsCompanion(
      actionId: Value(actionId),
      keyId: Value(keyId),
      ctrl: Value(ctrl),
      shift: Value(shift),
      alt: Value(alt),
    );
  }

  factory ShortcutBinding.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShortcutBinding(
      actionId: serializer.fromJson<String>(json['actionId']),
      keyId: serializer.fromJson<int>(json['keyId']),
      ctrl: serializer.fromJson<bool>(json['ctrl']),
      shift: serializer.fromJson<bool>(json['shift']),
      alt: serializer.fromJson<bool>(json['alt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'actionId': serializer.toJson<String>(actionId),
      'keyId': serializer.toJson<int>(keyId),
      'ctrl': serializer.toJson<bool>(ctrl),
      'shift': serializer.toJson<bool>(shift),
      'alt': serializer.toJson<bool>(alt),
    };
  }

  ShortcutBinding copyWith({
    String? actionId,
    int? keyId,
    bool? ctrl,
    bool? shift,
    bool? alt,
  }) => ShortcutBinding(
    actionId: actionId ?? this.actionId,
    keyId: keyId ?? this.keyId,
    ctrl: ctrl ?? this.ctrl,
    shift: shift ?? this.shift,
    alt: alt ?? this.alt,
  );
  ShortcutBinding copyWithCompanion(ShortcutBindingsCompanion data) {
    return ShortcutBinding(
      actionId: data.actionId.present ? data.actionId.value : this.actionId,
      keyId: data.keyId.present ? data.keyId.value : this.keyId,
      ctrl: data.ctrl.present ? data.ctrl.value : this.ctrl,
      shift: data.shift.present ? data.shift.value : this.shift,
      alt: data.alt.present ? data.alt.value : this.alt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShortcutBinding(')
          ..write('actionId: $actionId, ')
          ..write('keyId: $keyId, ')
          ..write('ctrl: $ctrl, ')
          ..write('shift: $shift, ')
          ..write('alt: $alt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(actionId, keyId, ctrl, shift, alt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShortcutBinding &&
          other.actionId == this.actionId &&
          other.keyId == this.keyId &&
          other.ctrl == this.ctrl &&
          other.shift == this.shift &&
          other.alt == this.alt);
}

class ShortcutBindingsCompanion extends UpdateCompanion<ShortcutBinding> {
  final Value<String> actionId;
  final Value<int> keyId;
  final Value<bool> ctrl;
  final Value<bool> shift;
  final Value<bool> alt;
  final Value<int> rowid;
  const ShortcutBindingsCompanion({
    this.actionId = const Value.absent(),
    this.keyId = const Value.absent(),
    this.ctrl = const Value.absent(),
    this.shift = const Value.absent(),
    this.alt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShortcutBindingsCompanion.insert({
    required String actionId,
    required int keyId,
    this.ctrl = const Value.absent(),
    this.shift = const Value.absent(),
    this.alt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : actionId = Value(actionId),
       keyId = Value(keyId);
  static Insertable<ShortcutBinding> custom({
    Expression<String>? actionId,
    Expression<int>? keyId,
    Expression<bool>? ctrl,
    Expression<bool>? shift,
    Expression<bool>? alt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (actionId != null) 'action_id': actionId,
      if (keyId != null) 'key_id': keyId,
      if (ctrl != null) 'ctrl': ctrl,
      if (shift != null) 'shift': shift,
      if (alt != null) 'alt': alt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShortcutBindingsCompanion copyWith({
    Value<String>? actionId,
    Value<int>? keyId,
    Value<bool>? ctrl,
    Value<bool>? shift,
    Value<bool>? alt,
    Value<int>? rowid,
  }) {
    return ShortcutBindingsCompanion(
      actionId: actionId ?? this.actionId,
      keyId: keyId ?? this.keyId,
      ctrl: ctrl ?? this.ctrl,
      shift: shift ?? this.shift,
      alt: alt ?? this.alt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (actionId.present) {
      map['action_id'] = Variable<String>(actionId.value);
    }
    if (keyId.present) {
      map['key_id'] = Variable<int>(keyId.value);
    }
    if (ctrl.present) {
      map['ctrl'] = Variable<bool>(ctrl.value);
    }
    if (shift.present) {
      map['shift'] = Variable<bool>(shift.value);
    }
    if (alt.present) {
      map['alt'] = Variable<bool>(alt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShortcutBindingsCompanion(')
          ..write('actionId: $actionId, ')
          ..write('keyId: $keyId, ')
          ..write('ctrl: $ctrl, ')
          ..write('shift: $shift, ')
          ..write('alt: $alt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PluginSettingsTable extends PluginSettings
    with TableInfo<$PluginSettingsTable, PluginSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PluginSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pluginIdMeta = const VerificationMeta(
    'pluginId',
  );
  @override
  late final GeneratedColumn<String> pluginId = GeneratedColumn<String>(
    'plugin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [pluginId, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plugin_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<PluginSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plugin_id')) {
      context.handle(
        _pluginIdMeta,
        pluginId.isAcceptableOrUnknown(data['plugin_id']!, _pluginIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pluginIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pluginId, key};
  @override
  PluginSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PluginSetting(
      pluginId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PluginSettingsTable createAlias(String alias) {
    return $PluginSettingsTable(attachedDatabase, alias);
  }
}

class PluginSetting extends DataClass implements Insertable<PluginSetting> {
  final String pluginId;
  final String key;
  final String value;
  const PluginSetting({
    required this.pluginId,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plugin_id'] = Variable<String>(pluginId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PluginSettingsCompanion toCompanion(bool nullToAbsent) {
    return PluginSettingsCompanion(
      pluginId: Value(pluginId),
      key: Value(key),
      value: Value(value),
    );
  }

  factory PluginSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PluginSetting(
      pluginId: serializer.fromJson<String>(json['pluginId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'pluginId': serializer.toJson<String>(pluginId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  PluginSetting copyWith({String? pluginId, String? key, String? value}) =>
      PluginSetting(
        pluginId: pluginId ?? this.pluginId,
        key: key ?? this.key,
        value: value ?? this.value,
      );
  PluginSetting copyWithCompanion(PluginSettingsCompanion data) {
    return PluginSetting(
      pluginId: data.pluginId.present ? data.pluginId.value : this.pluginId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PluginSetting(')
          ..write('pluginId: $pluginId, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(pluginId, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PluginSetting &&
          other.pluginId == this.pluginId &&
          other.key == this.key &&
          other.value == this.value);
}

class PluginSettingsCompanion extends UpdateCompanion<PluginSetting> {
  final Value<String> pluginId;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PluginSettingsCompanion({
    this.pluginId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PluginSettingsCompanion.insert({
    required String pluginId,
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : pluginId = Value(pluginId),
       key = Value(key),
       value = Value(value);
  static Insertable<PluginSetting> custom({
    Expression<String>? pluginId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pluginId != null) 'plugin_id': pluginId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PluginSettingsCompanion copyWith({
    Value<String>? pluginId,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PluginSettingsCompanion(
      pluginId: pluginId ?? this.pluginId,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pluginId.present) {
      map['plugin_id'] = Variable<String>(pluginId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PluginSettingsCompanion(')
          ..write('pluginId: $pluginId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DisabledPluginsTable extends DisabledPlugins
    with TableInfo<$DisabledPluginsTable, DisabledPlugin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DisabledPluginsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pluginIdMeta = const VerificationMeta(
    'pluginId',
  );
  @override
  late final GeneratedColumn<String> pluginId = GeneratedColumn<String>(
    'plugin_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [pluginId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'disabled_plugins';
  @override
  VerificationContext validateIntegrity(
    Insertable<DisabledPlugin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plugin_id')) {
      context.handle(
        _pluginIdMeta,
        pluginId.isAcceptableOrUnknown(data['plugin_id']!, _pluginIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pluginIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {pluginId};
  @override
  DisabledPlugin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DisabledPlugin(
      pluginId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plugin_id'],
      )!,
    );
  }

  @override
  $DisabledPluginsTable createAlias(String alias) {
    return $DisabledPluginsTable(attachedDatabase, alias);
  }
}

class DisabledPlugin extends DataClass implements Insertable<DisabledPlugin> {
  final String pluginId;
  const DisabledPlugin({required this.pluginId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plugin_id'] = Variable<String>(pluginId);
    return map;
  }

  DisabledPluginsCompanion toCompanion(bool nullToAbsent) {
    return DisabledPluginsCompanion(pluginId: Value(pluginId));
  }

  factory DisabledPlugin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DisabledPlugin(
      pluginId: serializer.fromJson<String>(json['pluginId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'pluginId': serializer.toJson<String>(pluginId)};
  }

  DisabledPlugin copyWith({String? pluginId}) =>
      DisabledPlugin(pluginId: pluginId ?? this.pluginId);
  DisabledPlugin copyWithCompanion(DisabledPluginsCompanion data) {
    return DisabledPlugin(
      pluginId: data.pluginId.present ? data.pluginId.value : this.pluginId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DisabledPlugin(')
          ..write('pluginId: $pluginId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => pluginId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisabledPlugin && other.pluginId == this.pluginId);
}

class DisabledPluginsCompanion extends UpdateCompanion<DisabledPlugin> {
  final Value<String> pluginId;
  final Value<int> rowid;
  const DisabledPluginsCompanion({
    this.pluginId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DisabledPluginsCompanion.insert({
    required String pluginId,
    this.rowid = const Value.absent(),
  }) : pluginId = Value(pluginId);
  static Insertable<DisabledPlugin> custom({
    Expression<String>? pluginId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (pluginId != null) 'plugin_id': pluginId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DisabledPluginsCompanion copyWith({
    Value<String>? pluginId,
    Value<int>? rowid,
  }) {
    return DisabledPluginsCompanion(
      pluginId: pluginId ?? this.pluginId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (pluginId.present) {
      map['plugin_id'] = Variable<String>(pluginId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DisabledPluginsCompanion(')
          ..write('pluginId: $pluginId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SidebarPrefsTable extends SidebarPrefs
    with TableInfo<$SidebarPrefsTable, SidebarPref> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SidebarPrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemKeyMeta = const VerificationMeta(
    'itemKey',
  );
  @override
  late final GeneratedColumn<String> itemKey = GeneratedColumn<String>(
    'item_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [scope, itemKey, orderIndex, hidden];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sidebar_prefs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SidebarPref> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('item_key')) {
      context.handle(
        _itemKeyMeta,
        itemKey.isAcceptableOrUnknown(data['item_key']!, _itemKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_itemKeyMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scope, itemKey};
  @override
  SidebarPref map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SidebarPref(
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      itemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_key'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
    );
  }

  @override
  $SidebarPrefsTable createAlias(String alias) {
    return $SidebarPrefsTable(attachedDatabase, alias);
  }
}

class SidebarPref extends DataClass implements Insertable<SidebarPref> {
  final String scope;
  final String itemKey;
  final int orderIndex;
  final bool hidden;
  const SidebarPref({
    required this.scope,
    required this.itemKey,
    required this.orderIndex,
    required this.hidden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scope'] = Variable<String>(scope);
    map['item_key'] = Variable<String>(itemKey);
    map['order_index'] = Variable<int>(orderIndex);
    map['hidden'] = Variable<bool>(hidden);
    return map;
  }

  SidebarPrefsCompanion toCompanion(bool nullToAbsent) {
    return SidebarPrefsCompanion(
      scope: Value(scope),
      itemKey: Value(itemKey),
      orderIndex: Value(orderIndex),
      hidden: Value(hidden),
    );
  }

  factory SidebarPref.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SidebarPref(
      scope: serializer.fromJson<String>(json['scope']),
      itemKey: serializer.fromJson<String>(json['itemKey']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      hidden: serializer.fromJson<bool>(json['hidden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scope': serializer.toJson<String>(scope),
      'itemKey': serializer.toJson<String>(itemKey),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'hidden': serializer.toJson<bool>(hidden),
    };
  }

  SidebarPref copyWith({
    String? scope,
    String? itemKey,
    int? orderIndex,
    bool? hidden,
  }) => SidebarPref(
    scope: scope ?? this.scope,
    itemKey: itemKey ?? this.itemKey,
    orderIndex: orderIndex ?? this.orderIndex,
    hidden: hidden ?? this.hidden,
  );
  SidebarPref copyWithCompanion(SidebarPrefsCompanion data) {
    return SidebarPref(
      scope: data.scope.present ? data.scope.value : this.scope,
      itemKey: data.itemKey.present ? data.itemKey.value : this.itemKey,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SidebarPref(')
          ..write('scope: $scope, ')
          ..write('itemKey: $itemKey, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(scope, itemKey, orderIndex, hidden);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SidebarPref &&
          other.scope == this.scope &&
          other.itemKey == this.itemKey &&
          other.orderIndex == this.orderIndex &&
          other.hidden == this.hidden);
}

class SidebarPrefsCompanion extends UpdateCompanion<SidebarPref> {
  final Value<String> scope;
  final Value<String> itemKey;
  final Value<int> orderIndex;
  final Value<bool> hidden;
  final Value<int> rowid;
  const SidebarPrefsCompanion({
    this.scope = const Value.absent(),
    this.itemKey = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.hidden = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SidebarPrefsCompanion.insert({
    required String scope,
    required String itemKey,
    this.orderIndex = const Value.absent(),
    this.hidden = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scope = Value(scope),
       itemKey = Value(itemKey);
  static Insertable<SidebarPref> custom({
    Expression<String>? scope,
    Expression<String>? itemKey,
    Expression<int>? orderIndex,
    Expression<bool>? hidden,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scope != null) 'scope': scope,
      if (itemKey != null) 'item_key': itemKey,
      if (orderIndex != null) 'order_index': orderIndex,
      if (hidden != null) 'hidden': hidden,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SidebarPrefsCompanion copyWith({
    Value<String>? scope,
    Value<String>? itemKey,
    Value<int>? orderIndex,
    Value<bool>? hidden,
    Value<int>? rowid,
  }) {
    return SidebarPrefsCompanion(
      scope: scope ?? this.scope,
      itemKey: itemKey ?? this.itemKey,
      orderIndex: orderIndex ?? this.orderIndex,
      hidden: hidden ?? this.hidden,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (itemKey.present) {
      map['item_key'] = Variable<String>(itemKey.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SidebarPrefsCompanion(')
          ..write('scope: $scope, ')
          ..write('itemKey: $itemKey, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('hidden: $hidden, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SessionTabsTable sessionTabs = $SessionTabsTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $FolderPrefsTable folderPrefs = $FolderPrefsTable(this);
  late final $RecentAppsTable recentApps = $RecentAppsTable(this);
  late final $RecentEnteredPathsTable recentEnteredPaths =
      $RecentEnteredPathsTable(this);
  late final $DefaultAppsTable defaultApps = $DefaultAppsTable(this);
  late final $ShortcutBindingsTable shortcutBindings = $ShortcutBindingsTable(
    this,
  );
  late final $PluginSettingsTable pluginSettings = $PluginSettingsTable(this);
  late final $DisabledPluginsTable disabledPlugins = $DisabledPluginsTable(
    this,
  );
  late final $SidebarPrefsTable sidebarPrefs = $SidebarPrefsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    sessionTabs,
    bookmarks,
    folderPrefs,
    recentApps,
    recentEnteredPaths,
    defaultApps,
    shortcutBindings,
    pluginSettings,
    disabledPlugins,
    sidebarPrefs,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<String> terminal,
      Value<String> terminalShell,
      Value<String> terminalCustomCommand,
      Value<bool> terminalUseSystemFont,
      Value<String> terminalFontFamily,
      Value<int> terminalFontSize,
      Value<double> terminalLineHeight,
      Value<bool> isDual,
      Value<double> splitRatio,
      Value<int> activePaneIndex,
      Value<bool> sidebarCollapsed,
      Value<double> sidebarWidth,
      Value<bool> restoreSession,
      Value<String> defaultStartingPath,
      Value<bool> confirmDelete,
      Value<bool> confirmCopy,
      Value<bool> confirmMove,
      Value<bool> showHiddenDefault,
      Value<String> rowDensity,
      Value<int> fileListHorizontalSpacing,
      Value<int> fileListVerticalSpacing,
      Value<String> dateFormat,
      Value<bool> recentDatesRelative,
      Value<String> deleteKeyBehavior,
      Value<String> sortKey,
      Value<bool> sortAscending,
      Value<bool> foldersFirst,
      Value<bool> naturalSort,
      Value<bool> sortFolders,
      Value<String> searchMode,
      Value<bool> rememberFolderState,
      Value<bool> rememberFolderSort,
      Value<bool> typeAheadBuffer,
      Value<double> fileListScale,
      Value<String> fileViewMode,
      Value<bool> showColumnSize,
      Value<bool> showColumnDate,
      Value<bool> showColumnKind,
      Value<bool> showColumnCreated,
      Value<bool> showColumnPermissions,
      Value<bool> showColumnOwner,
      Value<String> columnOrder,
      Value<bool> quickLookUseSystemFont,
      Value<String> quickLookFontFamily,
      Value<int> quickLookFontSize,
      Value<double> quickLookLineHeight,
      Value<bool> quickLookShowLineNumbers,
      Value<bool> quickLookRelativeLineNumbers,
      Value<bool> quickLookVimMode,
      Value<bool> quickLookWrapLines,
      Value<bool> quickLookShowStatistics,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<String> terminal,
      Value<String> terminalShell,
      Value<String> terminalCustomCommand,
      Value<bool> terminalUseSystemFont,
      Value<String> terminalFontFamily,
      Value<int> terminalFontSize,
      Value<double> terminalLineHeight,
      Value<bool> isDual,
      Value<double> splitRatio,
      Value<int> activePaneIndex,
      Value<bool> sidebarCollapsed,
      Value<double> sidebarWidth,
      Value<bool> restoreSession,
      Value<String> defaultStartingPath,
      Value<bool> confirmDelete,
      Value<bool> confirmCopy,
      Value<bool> confirmMove,
      Value<bool> showHiddenDefault,
      Value<String> rowDensity,
      Value<int> fileListHorizontalSpacing,
      Value<int> fileListVerticalSpacing,
      Value<String> dateFormat,
      Value<bool> recentDatesRelative,
      Value<String> deleteKeyBehavior,
      Value<String> sortKey,
      Value<bool> sortAscending,
      Value<bool> foldersFirst,
      Value<bool> naturalSort,
      Value<bool> sortFolders,
      Value<String> searchMode,
      Value<bool> rememberFolderState,
      Value<bool> rememberFolderSort,
      Value<bool> typeAheadBuffer,
      Value<double> fileListScale,
      Value<String> fileViewMode,
      Value<bool> showColumnSize,
      Value<bool> showColumnDate,
      Value<bool> showColumnKind,
      Value<bool> showColumnCreated,
      Value<bool> showColumnPermissions,
      Value<bool> showColumnOwner,
      Value<String> columnOrder,
      Value<bool> quickLookUseSystemFont,
      Value<String> quickLookFontFamily,
      Value<int> quickLookFontSize,
      Value<double> quickLookLineHeight,
      Value<bool> quickLookShowLineNumbers,
      Value<bool> quickLookRelativeLineNumbers,
      Value<bool> quickLookVimMode,
      Value<bool> quickLookWrapLines,
      Value<bool> quickLookShowStatistics,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terminal => $composableBuilder(
    column: $table.terminal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terminalShell => $composableBuilder(
    column: $table.terminalShell,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terminalCustomCommand => $composableBuilder(
    column: $table.terminalCustomCommand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get terminalUseSystemFont => $composableBuilder(
    column: $table.terminalUseSystemFont,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get terminalFontFamily => $composableBuilder(
    column: $table.terminalFontFamily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get terminalFontSize => $composableBuilder(
    column: $table.terminalFontSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get terminalLineHeight => $composableBuilder(
    column: $table.terminalLineHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDual => $composableBuilder(
    column: $table.isDual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activePaneIndex => $composableBuilder(
    column: $table.activePaneIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sidebarCollapsed => $composableBuilder(
    column: $table.sidebarCollapsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sidebarWidth => $composableBuilder(
    column: $table.sidebarWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get restoreSession => $composableBuilder(
    column: $table.restoreSession,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultStartingPath => $composableBuilder(
    column: $table.defaultStartingPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmDelete => $composableBuilder(
    column: $table.confirmDelete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmCopy => $composableBuilder(
    column: $table.confirmCopy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get confirmMove => $composableBuilder(
    column: $table.confirmMove,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showHiddenDefault => $composableBuilder(
    column: $table.showHiddenDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowDensity => $composableBuilder(
    column: $table.rowDensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileListHorizontalSpacing => $composableBuilder(
    column: $table.fileListHorizontalSpacing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileListVerticalSpacing => $composableBuilder(
    column: $table.fileListVerticalSpacing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dateFormat => $composableBuilder(
    column: $table.dateFormat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recentDatesRelative => $composableBuilder(
    column: $table.recentDatesRelative,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deleteKeyBehavior => $composableBuilder(
    column: $table.deleteKeyBehavior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sortAscending => $composableBuilder(
    column: $table.sortAscending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get foldersFirst => $composableBuilder(
    column: $table.foldersFirst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get naturalSort => $composableBuilder(
    column: $table.naturalSort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sortFolders => $composableBuilder(
    column: $table.sortFolders,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchMode => $composableBuilder(
    column: $table.searchMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rememberFolderState => $composableBuilder(
    column: $table.rememberFolderState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rememberFolderSort => $composableBuilder(
    column: $table.rememberFolderSort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get typeAheadBuffer => $composableBuilder(
    column: $table.typeAheadBuffer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fileListScale => $composableBuilder(
    column: $table.fileListScale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileViewMode => $composableBuilder(
    column: $table.fileViewMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showColumnSize => $composableBuilder(
    column: $table.showColumnSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showColumnDate => $composableBuilder(
    column: $table.showColumnDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showColumnKind => $composableBuilder(
    column: $table.showColumnKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showColumnCreated => $composableBuilder(
    column: $table.showColumnCreated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showColumnPermissions => $composableBuilder(
    column: $table.showColumnPermissions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showColumnOwner => $composableBuilder(
    column: $table.showColumnOwner,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get columnOrder => $composableBuilder(
    column: $table.columnOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quickLookUseSystemFont => $composableBuilder(
    column: $table.quickLookUseSystemFont,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quickLookFontFamily => $composableBuilder(
    column: $table.quickLookFontFamily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quickLookFontSize => $composableBuilder(
    column: $table.quickLookFontSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quickLookLineHeight => $composableBuilder(
    column: $table.quickLookLineHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quickLookShowLineNumbers => $composableBuilder(
    column: $table.quickLookShowLineNumbers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quickLookRelativeLineNumbers => $composableBuilder(
    column: $table.quickLookRelativeLineNumbers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quickLookVimMode => $composableBuilder(
    column: $table.quickLookVimMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quickLookWrapLines => $composableBuilder(
    column: $table.quickLookWrapLines,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get quickLookShowStatistics => $composableBuilder(
    column: $table.quickLookShowStatistics,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terminal => $composableBuilder(
    column: $table.terminal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terminalShell => $composableBuilder(
    column: $table.terminalShell,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terminalCustomCommand => $composableBuilder(
    column: $table.terminalCustomCommand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get terminalUseSystemFont => $composableBuilder(
    column: $table.terminalUseSystemFont,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get terminalFontFamily => $composableBuilder(
    column: $table.terminalFontFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get terminalFontSize => $composableBuilder(
    column: $table.terminalFontSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get terminalLineHeight => $composableBuilder(
    column: $table.terminalLineHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDual => $composableBuilder(
    column: $table.isDual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activePaneIndex => $composableBuilder(
    column: $table.activePaneIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sidebarCollapsed => $composableBuilder(
    column: $table.sidebarCollapsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sidebarWidth => $composableBuilder(
    column: $table.sidebarWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get restoreSession => $composableBuilder(
    column: $table.restoreSession,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultStartingPath => $composableBuilder(
    column: $table.defaultStartingPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmDelete => $composableBuilder(
    column: $table.confirmDelete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmCopy => $composableBuilder(
    column: $table.confirmCopy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get confirmMove => $composableBuilder(
    column: $table.confirmMove,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showHiddenDefault => $composableBuilder(
    column: $table.showHiddenDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowDensity => $composableBuilder(
    column: $table.rowDensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileListHorizontalSpacing => $composableBuilder(
    column: $table.fileListHorizontalSpacing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileListVerticalSpacing => $composableBuilder(
    column: $table.fileListVerticalSpacing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dateFormat => $composableBuilder(
    column: $table.dateFormat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recentDatesRelative => $composableBuilder(
    column: $table.recentDatesRelative,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deleteKeyBehavior => $composableBuilder(
    column: $table.deleteKeyBehavior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sortAscending => $composableBuilder(
    column: $table.sortAscending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get foldersFirst => $composableBuilder(
    column: $table.foldersFirst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get naturalSort => $composableBuilder(
    column: $table.naturalSort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sortFolders => $composableBuilder(
    column: $table.sortFolders,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchMode => $composableBuilder(
    column: $table.searchMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rememberFolderState => $composableBuilder(
    column: $table.rememberFolderState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rememberFolderSort => $composableBuilder(
    column: $table.rememberFolderSort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get typeAheadBuffer => $composableBuilder(
    column: $table.typeAheadBuffer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fileListScale => $composableBuilder(
    column: $table.fileListScale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileViewMode => $composableBuilder(
    column: $table.fileViewMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showColumnSize => $composableBuilder(
    column: $table.showColumnSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showColumnDate => $composableBuilder(
    column: $table.showColumnDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showColumnKind => $composableBuilder(
    column: $table.showColumnKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showColumnCreated => $composableBuilder(
    column: $table.showColumnCreated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showColumnPermissions => $composableBuilder(
    column: $table.showColumnPermissions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showColumnOwner => $composableBuilder(
    column: $table.showColumnOwner,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get columnOrder => $composableBuilder(
    column: $table.columnOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quickLookUseSystemFont => $composableBuilder(
    column: $table.quickLookUseSystemFont,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quickLookFontFamily => $composableBuilder(
    column: $table.quickLookFontFamily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quickLookFontSize => $composableBuilder(
    column: $table.quickLookFontSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quickLookLineHeight => $composableBuilder(
    column: $table.quickLookLineHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quickLookShowLineNumbers => $composableBuilder(
    column: $table.quickLookShowLineNumbers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quickLookRelativeLineNumbers => $composableBuilder(
    column: $table.quickLookRelativeLineNumbers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quickLookVimMode => $composableBuilder(
    column: $table.quickLookVimMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quickLookWrapLines => $composableBuilder(
    column: $table.quickLookWrapLines,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get quickLookShowStatistics => $composableBuilder(
    column: $table.quickLookShowStatistics,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get terminal =>
      $composableBuilder(column: $table.terminal, builder: (column) => column);

  GeneratedColumn<String> get terminalShell => $composableBuilder(
    column: $table.terminalShell,
    builder: (column) => column,
  );

  GeneratedColumn<String> get terminalCustomCommand => $composableBuilder(
    column: $table.terminalCustomCommand,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get terminalUseSystemFont => $composableBuilder(
    column: $table.terminalUseSystemFont,
    builder: (column) => column,
  );

  GeneratedColumn<String> get terminalFontFamily => $composableBuilder(
    column: $table.terminalFontFamily,
    builder: (column) => column,
  );

  GeneratedColumn<int> get terminalFontSize => $composableBuilder(
    column: $table.terminalFontSize,
    builder: (column) => column,
  );

  GeneratedColumn<double> get terminalLineHeight => $composableBuilder(
    column: $table.terminalLineHeight,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDual =>
      $composableBuilder(column: $table.isDual, builder: (column) => column);

  GeneratedColumn<double> get splitRatio => $composableBuilder(
    column: $table.splitRatio,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activePaneIndex => $composableBuilder(
    column: $table.activePaneIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sidebarCollapsed => $composableBuilder(
    column: $table.sidebarCollapsed,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sidebarWidth => $composableBuilder(
    column: $table.sidebarWidth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get restoreSession => $composableBuilder(
    column: $table.restoreSession,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultStartingPath => $composableBuilder(
    column: $table.defaultStartingPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get confirmDelete => $composableBuilder(
    column: $table.confirmDelete,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get confirmCopy => $composableBuilder(
    column: $table.confirmCopy,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get confirmMove => $composableBuilder(
    column: $table.confirmMove,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showHiddenDefault => $composableBuilder(
    column: $table.showHiddenDefault,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowDensity => $composableBuilder(
    column: $table.rowDensity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileListHorizontalSpacing => $composableBuilder(
    column: $table.fileListHorizontalSpacing,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileListVerticalSpacing => $composableBuilder(
    column: $table.fileListVerticalSpacing,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dateFormat => $composableBuilder(
    column: $table.dateFormat,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get recentDatesRelative => $composableBuilder(
    column: $table.recentDatesRelative,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deleteKeyBehavior => $composableBuilder(
    column: $table.deleteKeyBehavior,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sortKey =>
      $composableBuilder(column: $table.sortKey, builder: (column) => column);

  GeneratedColumn<bool> get sortAscending => $composableBuilder(
    column: $table.sortAscending,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get foldersFirst => $composableBuilder(
    column: $table.foldersFirst,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get naturalSort => $composableBuilder(
    column: $table.naturalSort,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sortFolders => $composableBuilder(
    column: $table.sortFolders,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchMode => $composableBuilder(
    column: $table.searchMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get rememberFolderState => $composableBuilder(
    column: $table.rememberFolderState,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get rememberFolderSort => $composableBuilder(
    column: $table.rememberFolderSort,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get typeAheadBuffer => $composableBuilder(
    column: $table.typeAheadBuffer,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fileListScale => $composableBuilder(
    column: $table.fileListScale,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileViewMode => $composableBuilder(
    column: $table.fileViewMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showColumnSize => $composableBuilder(
    column: $table.showColumnSize,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showColumnDate => $composableBuilder(
    column: $table.showColumnDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showColumnKind => $composableBuilder(
    column: $table.showColumnKind,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showColumnCreated => $composableBuilder(
    column: $table.showColumnCreated,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showColumnPermissions => $composableBuilder(
    column: $table.showColumnPermissions,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showColumnOwner => $composableBuilder(
    column: $table.showColumnOwner,
    builder: (column) => column,
  );

  GeneratedColumn<String> get columnOrder => $composableBuilder(
    column: $table.columnOrder,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quickLookUseSystemFont => $composableBuilder(
    column: $table.quickLookUseSystemFont,
    builder: (column) => column,
  );

  GeneratedColumn<String> get quickLookFontFamily => $composableBuilder(
    column: $table.quickLookFontFamily,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quickLookFontSize => $composableBuilder(
    column: $table.quickLookFontSize,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quickLookLineHeight => $composableBuilder(
    column: $table.quickLookLineHeight,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quickLookShowLineNumbers => $composableBuilder(
    column: $table.quickLookShowLineNumbers,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quickLookRelativeLineNumbers => $composableBuilder(
    column: $table.quickLookRelativeLineNumbers,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quickLookVimMode => $composableBuilder(
    column: $table.quickLookVimMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quickLookWrapLines => $composableBuilder(
    column: $table.quickLookWrapLines,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get quickLookShowStatistics => $composableBuilder(
    column: $table.quickLookShowStatistics,
    builder: (column) => column,
  );
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> terminal = const Value.absent(),
                Value<String> terminalShell = const Value.absent(),
                Value<String> terminalCustomCommand = const Value.absent(),
                Value<bool> terminalUseSystemFont = const Value.absent(),
                Value<String> terminalFontFamily = const Value.absent(),
                Value<int> terminalFontSize = const Value.absent(),
                Value<double> terminalLineHeight = const Value.absent(),
                Value<bool> isDual = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<int> activePaneIndex = const Value.absent(),
                Value<bool> sidebarCollapsed = const Value.absent(),
                Value<double> sidebarWidth = const Value.absent(),
                Value<bool> restoreSession = const Value.absent(),
                Value<String> defaultStartingPath = const Value.absent(),
                Value<bool> confirmDelete = const Value.absent(),
                Value<bool> confirmCopy = const Value.absent(),
                Value<bool> confirmMove = const Value.absent(),
                Value<bool> showHiddenDefault = const Value.absent(),
                Value<String> rowDensity = const Value.absent(),
                Value<int> fileListHorizontalSpacing = const Value.absent(),
                Value<int> fileListVerticalSpacing = const Value.absent(),
                Value<String> dateFormat = const Value.absent(),
                Value<bool> recentDatesRelative = const Value.absent(),
                Value<String> deleteKeyBehavior = const Value.absent(),
                Value<String> sortKey = const Value.absent(),
                Value<bool> sortAscending = const Value.absent(),
                Value<bool> foldersFirst = const Value.absent(),
                Value<bool> naturalSort = const Value.absent(),
                Value<bool> sortFolders = const Value.absent(),
                Value<String> searchMode = const Value.absent(),
                Value<bool> rememberFolderState = const Value.absent(),
                Value<bool> rememberFolderSort = const Value.absent(),
                Value<bool> typeAheadBuffer = const Value.absent(),
                Value<double> fileListScale = const Value.absent(),
                Value<String> fileViewMode = const Value.absent(),
                Value<bool> showColumnSize = const Value.absent(),
                Value<bool> showColumnDate = const Value.absent(),
                Value<bool> showColumnKind = const Value.absent(),
                Value<bool> showColumnCreated = const Value.absent(),
                Value<bool> showColumnPermissions = const Value.absent(),
                Value<bool> showColumnOwner = const Value.absent(),
                Value<String> columnOrder = const Value.absent(),
                Value<bool> quickLookUseSystemFont = const Value.absent(),
                Value<String> quickLookFontFamily = const Value.absent(),
                Value<int> quickLookFontSize = const Value.absent(),
                Value<double> quickLookLineHeight = const Value.absent(),
                Value<bool> quickLookShowLineNumbers = const Value.absent(),
                Value<bool> quickLookRelativeLineNumbers = const Value.absent(),
                Value<bool> quickLookVimMode = const Value.absent(),
                Value<bool> quickLookWrapLines = const Value.absent(),
                Value<bool> quickLookShowStatistics = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                themeMode: themeMode,
                terminal: terminal,
                terminalShell: terminalShell,
                terminalCustomCommand: terminalCustomCommand,
                terminalUseSystemFont: terminalUseSystemFont,
                terminalFontFamily: terminalFontFamily,
                terminalFontSize: terminalFontSize,
                terminalLineHeight: terminalLineHeight,
                isDual: isDual,
                splitRatio: splitRatio,
                activePaneIndex: activePaneIndex,
                sidebarCollapsed: sidebarCollapsed,
                sidebarWidth: sidebarWidth,
                restoreSession: restoreSession,
                defaultStartingPath: defaultStartingPath,
                confirmDelete: confirmDelete,
                confirmCopy: confirmCopy,
                confirmMove: confirmMove,
                showHiddenDefault: showHiddenDefault,
                rowDensity: rowDensity,
                fileListHorizontalSpacing: fileListHorizontalSpacing,
                fileListVerticalSpacing: fileListVerticalSpacing,
                dateFormat: dateFormat,
                recentDatesRelative: recentDatesRelative,
                deleteKeyBehavior: deleteKeyBehavior,
                sortKey: sortKey,
                sortAscending: sortAscending,
                foldersFirst: foldersFirst,
                naturalSort: naturalSort,
                sortFolders: sortFolders,
                searchMode: searchMode,
                rememberFolderState: rememberFolderState,
                rememberFolderSort: rememberFolderSort,
                typeAheadBuffer: typeAheadBuffer,
                fileListScale: fileListScale,
                fileViewMode: fileViewMode,
                showColumnSize: showColumnSize,
                showColumnDate: showColumnDate,
                showColumnKind: showColumnKind,
                showColumnCreated: showColumnCreated,
                showColumnPermissions: showColumnPermissions,
                showColumnOwner: showColumnOwner,
                columnOrder: columnOrder,
                quickLookUseSystemFont: quickLookUseSystemFont,
                quickLookFontFamily: quickLookFontFamily,
                quickLookFontSize: quickLookFontSize,
                quickLookLineHeight: quickLookLineHeight,
                quickLookShowLineNumbers: quickLookShowLineNumbers,
                quickLookRelativeLineNumbers: quickLookRelativeLineNumbers,
                quickLookVimMode: quickLookVimMode,
                quickLookWrapLines: quickLookWrapLines,
                quickLookShowStatistics: quickLookShowStatistics,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> terminal = const Value.absent(),
                Value<String> terminalShell = const Value.absent(),
                Value<String> terminalCustomCommand = const Value.absent(),
                Value<bool> terminalUseSystemFont = const Value.absent(),
                Value<String> terminalFontFamily = const Value.absent(),
                Value<int> terminalFontSize = const Value.absent(),
                Value<double> terminalLineHeight = const Value.absent(),
                Value<bool> isDual = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<int> activePaneIndex = const Value.absent(),
                Value<bool> sidebarCollapsed = const Value.absent(),
                Value<double> sidebarWidth = const Value.absent(),
                Value<bool> restoreSession = const Value.absent(),
                Value<String> defaultStartingPath = const Value.absent(),
                Value<bool> confirmDelete = const Value.absent(),
                Value<bool> confirmCopy = const Value.absent(),
                Value<bool> confirmMove = const Value.absent(),
                Value<bool> showHiddenDefault = const Value.absent(),
                Value<String> rowDensity = const Value.absent(),
                Value<int> fileListHorizontalSpacing = const Value.absent(),
                Value<int> fileListVerticalSpacing = const Value.absent(),
                Value<String> dateFormat = const Value.absent(),
                Value<bool> recentDatesRelative = const Value.absent(),
                Value<String> deleteKeyBehavior = const Value.absent(),
                Value<String> sortKey = const Value.absent(),
                Value<bool> sortAscending = const Value.absent(),
                Value<bool> foldersFirst = const Value.absent(),
                Value<bool> naturalSort = const Value.absent(),
                Value<bool> sortFolders = const Value.absent(),
                Value<String> searchMode = const Value.absent(),
                Value<bool> rememberFolderState = const Value.absent(),
                Value<bool> rememberFolderSort = const Value.absent(),
                Value<bool> typeAheadBuffer = const Value.absent(),
                Value<double> fileListScale = const Value.absent(),
                Value<String> fileViewMode = const Value.absent(),
                Value<bool> showColumnSize = const Value.absent(),
                Value<bool> showColumnDate = const Value.absent(),
                Value<bool> showColumnKind = const Value.absent(),
                Value<bool> showColumnCreated = const Value.absent(),
                Value<bool> showColumnPermissions = const Value.absent(),
                Value<bool> showColumnOwner = const Value.absent(),
                Value<String> columnOrder = const Value.absent(),
                Value<bool> quickLookUseSystemFont = const Value.absent(),
                Value<String> quickLookFontFamily = const Value.absent(),
                Value<int> quickLookFontSize = const Value.absent(),
                Value<double> quickLookLineHeight = const Value.absent(),
                Value<bool> quickLookShowLineNumbers = const Value.absent(),
                Value<bool> quickLookRelativeLineNumbers = const Value.absent(),
                Value<bool> quickLookVimMode = const Value.absent(),
                Value<bool> quickLookWrapLines = const Value.absent(),
                Value<bool> quickLookShowStatistics = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                themeMode: themeMode,
                terminal: terminal,
                terminalShell: terminalShell,
                terminalCustomCommand: terminalCustomCommand,
                terminalUseSystemFont: terminalUseSystemFont,
                terminalFontFamily: terminalFontFamily,
                terminalFontSize: terminalFontSize,
                terminalLineHeight: terminalLineHeight,
                isDual: isDual,
                splitRatio: splitRatio,
                activePaneIndex: activePaneIndex,
                sidebarCollapsed: sidebarCollapsed,
                sidebarWidth: sidebarWidth,
                restoreSession: restoreSession,
                defaultStartingPath: defaultStartingPath,
                confirmDelete: confirmDelete,
                confirmCopy: confirmCopy,
                confirmMove: confirmMove,
                showHiddenDefault: showHiddenDefault,
                rowDensity: rowDensity,
                fileListHorizontalSpacing: fileListHorizontalSpacing,
                fileListVerticalSpacing: fileListVerticalSpacing,
                dateFormat: dateFormat,
                recentDatesRelative: recentDatesRelative,
                deleteKeyBehavior: deleteKeyBehavior,
                sortKey: sortKey,
                sortAscending: sortAscending,
                foldersFirst: foldersFirst,
                naturalSort: naturalSort,
                sortFolders: sortFolders,
                searchMode: searchMode,
                rememberFolderState: rememberFolderState,
                rememberFolderSort: rememberFolderSort,
                typeAheadBuffer: typeAheadBuffer,
                fileListScale: fileListScale,
                fileViewMode: fileViewMode,
                showColumnSize: showColumnSize,
                showColumnDate: showColumnDate,
                showColumnKind: showColumnKind,
                showColumnCreated: showColumnCreated,
                showColumnPermissions: showColumnPermissions,
                showColumnOwner: showColumnOwner,
                columnOrder: columnOrder,
                quickLookUseSystemFont: quickLookUseSystemFont,
                quickLookFontFamily: quickLookFontFamily,
                quickLookFontSize: quickLookFontSize,
                quickLookLineHeight: quickLookLineHeight,
                quickLookShowLineNumbers: quickLookShowLineNumbers,
                quickLookRelativeLineNumbers: quickLookRelativeLineNumbers,
                quickLookVimMode: quickLookVimMode,
                quickLookWrapLines: quickLookWrapLines,
                quickLookShowStatistics: quickLookShowStatistics,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$SessionTabsTableCreateCompanionBuilder =
    SessionTabsCompanion Function({
      Value<int> id,
      required int paneIndex,
      required int tabIndex,
      required String path,
      Value<bool> isActive,
    });
typedef $$SessionTabsTableUpdateCompanionBuilder =
    SessionTabsCompanion Function({
      Value<int> id,
      Value<int> paneIndex,
      Value<int> tabIndex,
      Value<String> path,
      Value<bool> isActive,
    });

class $$SessionTabsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionTabsTable> {
  $$SessionTabsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paneIndex => $composableBuilder(
    column: $table.paneIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tabIndex => $composableBuilder(
    column: $table.tabIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionTabsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionTabsTable> {
  $$SessionTabsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paneIndex => $composableBuilder(
    column: $table.paneIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tabIndex => $composableBuilder(
    column: $table.tabIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionTabsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionTabsTable> {
  $$SessionTabsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get paneIndex =>
      $composableBuilder(column: $table.paneIndex, builder: (column) => column);

  GeneratedColumn<int> get tabIndex =>
      $composableBuilder(column: $table.tabIndex, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$SessionTabsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionTabsTable,
          SessionTab,
          $$SessionTabsTableFilterComposer,
          $$SessionTabsTableOrderingComposer,
          $$SessionTabsTableAnnotationComposer,
          $$SessionTabsTableCreateCompanionBuilder,
          $$SessionTabsTableUpdateCompanionBuilder,
          (
            SessionTab,
            BaseReferences<_$AppDatabase, $SessionTabsTable, SessionTab>,
          ),
          SessionTab,
          PrefetchHooks Function()
        > {
  $$SessionTabsTableTableManager(_$AppDatabase db, $SessionTabsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionTabsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionTabsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionTabsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> paneIndex = const Value.absent(),
                Value<int> tabIndex = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => SessionTabsCompanion(
                id: id,
                paneIndex: paneIndex,
                tabIndex: tabIndex,
                path: path,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int paneIndex,
                required int tabIndex,
                required String path,
                Value<bool> isActive = const Value.absent(),
              }) => SessionTabsCompanion.insert(
                id: id,
                paneIndex: paneIndex,
                tabIndex: tabIndex,
                path: path,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionTabsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionTabsTable,
      SessionTab,
      $$SessionTabsTableFilterComposer,
      $$SessionTabsTableOrderingComposer,
      $$SessionTabsTableAnnotationComposer,
      $$SessionTabsTableCreateCompanionBuilder,
      $$SessionTabsTableUpdateCompanionBuilder,
      (
        SessionTab,
        BaseReferences<_$AppDatabase, $SessionTabsTable, SessionTab>,
      ),
      SessionTab,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      required int orderIndex,
      required String label,
      required String path,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<int> id,
      Value<int> orderIndex,
      Value<String> label,
      Value<String> path,
    });

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          Bookmark,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
          Bookmark,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> path = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                orderIndex: orderIndex,
                label: label,
                path: path,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int orderIndex,
                required String label,
                required String path,
              }) => BookmarksCompanion.insert(
                id: id,
                orderIndex: orderIndex,
                label: label,
                path: path,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      Bookmark,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (Bookmark, BaseReferences<_$AppDatabase, $BookmarksTable, Bookmark>),
      Bookmark,
      PrefetchHooks Function()
    >;
typedef $$FolderPrefsTableCreateCompanionBuilder =
    FolderPrefsCompanion Function({
      required String path,
      Value<String> sortKey,
      Value<bool> sortAscending,
      Value<bool> foldersFirst,
      Value<String?> cursorPath,
      Value<String?> selectedPaths,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$FolderPrefsTableUpdateCompanionBuilder =
    FolderPrefsCompanion Function({
      Value<String> path,
      Value<String> sortKey,
      Value<bool> sortAscending,
      Value<bool> foldersFirst,
      Value<String?> cursorPath,
      Value<String?> selectedPaths,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$FolderPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $FolderPrefsTable> {
  $$FolderPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sortAscending => $composableBuilder(
    column: $table.sortAscending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get foldersFirst => $composableBuilder(
    column: $table.foldersFirst,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursorPath => $composableBuilder(
    column: $table.cursorPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedPaths => $composableBuilder(
    column: $table.selectedPaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FolderPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $FolderPrefsTable> {
  $$FolderPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sortKey => $composableBuilder(
    column: $table.sortKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sortAscending => $composableBuilder(
    column: $table.sortAscending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get foldersFirst => $composableBuilder(
    column: $table.foldersFirst,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursorPath => $composableBuilder(
    column: $table.cursorPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedPaths => $composableBuilder(
    column: $table.selectedPaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FolderPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FolderPrefsTable> {
  $$FolderPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get sortKey =>
      $composableBuilder(column: $table.sortKey, builder: (column) => column);

  GeneratedColumn<bool> get sortAscending => $composableBuilder(
    column: $table.sortAscending,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get foldersFirst => $composableBuilder(
    column: $table.foldersFirst,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cursorPath => $composableBuilder(
    column: $table.cursorPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedPaths => $composableBuilder(
    column: $table.selectedPaths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FolderPrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FolderPrefsTable,
          FolderPref,
          $$FolderPrefsTableFilterComposer,
          $$FolderPrefsTableOrderingComposer,
          $$FolderPrefsTableAnnotationComposer,
          $$FolderPrefsTableCreateCompanionBuilder,
          $$FolderPrefsTableUpdateCompanionBuilder,
          (
            FolderPref,
            BaseReferences<_$AppDatabase, $FolderPrefsTable, FolderPref>,
          ),
          FolderPref,
          PrefetchHooks Function()
        > {
  $$FolderPrefsTableTableManager(_$AppDatabase db, $FolderPrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FolderPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FolderPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FolderPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<String> sortKey = const Value.absent(),
                Value<bool> sortAscending = const Value.absent(),
                Value<bool> foldersFirst = const Value.absent(),
                Value<String?> cursorPath = const Value.absent(),
                Value<String?> selectedPaths = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderPrefsCompanion(
                path: path,
                sortKey: sortKey,
                sortAscending: sortAscending,
                foldersFirst: foldersFirst,
                cursorPath: cursorPath,
                selectedPaths: selectedPaths,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                Value<String> sortKey = const Value.absent(),
                Value<bool> sortAscending = const Value.absent(),
                Value<bool> foldersFirst = const Value.absent(),
                Value<String?> cursorPath = const Value.absent(),
                Value<String?> selectedPaths = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderPrefsCompanion.insert(
                path: path,
                sortKey: sortKey,
                sortAscending: sortAscending,
                foldersFirst: foldersFirst,
                cursorPath: cursorPath,
                selectedPaths: selectedPaths,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FolderPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FolderPrefsTable,
      FolderPref,
      $$FolderPrefsTableFilterComposer,
      $$FolderPrefsTableOrderingComposer,
      $$FolderPrefsTableAnnotationComposer,
      $$FolderPrefsTableCreateCompanionBuilder,
      $$FolderPrefsTableUpdateCompanionBuilder,
      (
        FolderPref,
        BaseReferences<_$AppDatabase, $FolderPrefsTable, FolderPref>,
      ),
      FolderPref,
      PrefetchHooks Function()
    >;
typedef $$RecentAppsTableCreateCompanionBuilder =
    RecentAppsCompanion Function({
      required String mime,
      required String appId,
      required String appName,
      required String appExec,
      Value<String?> iconPath,
      Value<int> usedAt,
      Value<int> rowid,
    });
typedef $$RecentAppsTableUpdateCompanionBuilder =
    RecentAppsCompanion Function({
      Value<String> mime,
      Value<String> appId,
      Value<String> appName,
      Value<String> appExec,
      Value<String?> iconPath,
      Value<int> usedAt,
      Value<int> rowid,
    });

class $$RecentAppsTableFilterComposer
    extends Composer<_$AppDatabase, $RecentAppsTable> {
  $$RecentAppsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appExec => $composableBuilder(
    column: $table.appExec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconPath => $composableBuilder(
    column: $table.iconPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentAppsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentAppsTable> {
  $$RecentAppsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mime => $composableBuilder(
    column: $table.mime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appExec => $composableBuilder(
    column: $table.appExec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconPath => $composableBuilder(
    column: $table.iconPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentAppsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentAppsTable> {
  $$RecentAppsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mime =>
      $composableBuilder(column: $table.mime, builder: (column) => column);

  GeneratedColumn<String> get appId =>
      $composableBuilder(column: $table.appId, builder: (column) => column);

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get appExec =>
      $composableBuilder(column: $table.appExec, builder: (column) => column);

  GeneratedColumn<String> get iconPath =>
      $composableBuilder(column: $table.iconPath, builder: (column) => column);

  GeneratedColumn<int> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);
}

class $$RecentAppsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentAppsTable,
          RecentApp,
          $$RecentAppsTableFilterComposer,
          $$RecentAppsTableOrderingComposer,
          $$RecentAppsTableAnnotationComposer,
          $$RecentAppsTableCreateCompanionBuilder,
          $$RecentAppsTableUpdateCompanionBuilder,
          (
            RecentApp,
            BaseReferences<_$AppDatabase, $RecentAppsTable, RecentApp>,
          ),
          RecentApp,
          PrefetchHooks Function()
        > {
  $$RecentAppsTableTableManager(_$AppDatabase db, $RecentAppsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentAppsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentAppsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentAppsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mime = const Value.absent(),
                Value<String> appId = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<String> appExec = const Value.absent(),
                Value<String?> iconPath = const Value.absent(),
                Value<int> usedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentAppsCompanion(
                mime: mime,
                appId: appId,
                appName: appName,
                appExec: appExec,
                iconPath: iconPath,
                usedAt: usedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mime,
                required String appId,
                required String appName,
                required String appExec,
                Value<String?> iconPath = const Value.absent(),
                Value<int> usedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentAppsCompanion.insert(
                mime: mime,
                appId: appId,
                appName: appName,
                appExec: appExec,
                iconPath: iconPath,
                usedAt: usedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecentAppsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentAppsTable,
      RecentApp,
      $$RecentAppsTableFilterComposer,
      $$RecentAppsTableOrderingComposer,
      $$RecentAppsTableAnnotationComposer,
      $$RecentAppsTableCreateCompanionBuilder,
      $$RecentAppsTableUpdateCompanionBuilder,
      (RecentApp, BaseReferences<_$AppDatabase, $RecentAppsTable, RecentApp>),
      RecentApp,
      PrefetchHooks Function()
    >;
typedef $$RecentEnteredPathsTableCreateCompanionBuilder =
    RecentEnteredPathsCompanion Function({
      required String path,
      Value<int> usedAt,
      Value<int> rowid,
    });
typedef $$RecentEnteredPathsTableUpdateCompanionBuilder =
    RecentEnteredPathsCompanion Function({
      Value<String> path,
      Value<int> usedAt,
      Value<int> rowid,
    });

class $$RecentEnteredPathsTableFilterComposer
    extends Composer<_$AppDatabase, $RecentEnteredPathsTable> {
  $$RecentEnteredPathsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentEnteredPathsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentEnteredPathsTable> {
  $$RecentEnteredPathsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedAt => $composableBuilder(
    column: $table.usedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentEnteredPathsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentEnteredPathsTable> {
  $$RecentEnteredPathsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get usedAt =>
      $composableBuilder(column: $table.usedAt, builder: (column) => column);
}

class $$RecentEnteredPathsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentEnteredPathsTable,
          RecentEnteredPath,
          $$RecentEnteredPathsTableFilterComposer,
          $$RecentEnteredPathsTableOrderingComposer,
          $$RecentEnteredPathsTableAnnotationComposer,
          $$RecentEnteredPathsTableCreateCompanionBuilder,
          $$RecentEnteredPathsTableUpdateCompanionBuilder,
          (
            RecentEnteredPath,
            BaseReferences<
              _$AppDatabase,
              $RecentEnteredPathsTable,
              RecentEnteredPath
            >,
          ),
          RecentEnteredPath,
          PrefetchHooks Function()
        > {
  $$RecentEnteredPathsTableTableManager(
    _$AppDatabase db,
    $RecentEnteredPathsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentEnteredPathsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentEnteredPathsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentEnteredPathsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> path = const Value.absent(),
                Value<int> usedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentEnteredPathsCompanion(
                path: path,
                usedAt: usedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                Value<int> usedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentEnteredPathsCompanion.insert(
                path: path,
                usedAt: usedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecentEnteredPathsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentEnteredPathsTable,
      RecentEnteredPath,
      $$RecentEnteredPathsTableFilterComposer,
      $$RecentEnteredPathsTableOrderingComposer,
      $$RecentEnteredPathsTableAnnotationComposer,
      $$RecentEnteredPathsTableCreateCompanionBuilder,
      $$RecentEnteredPathsTableUpdateCompanionBuilder,
      (
        RecentEnteredPath,
        BaseReferences<
          _$AppDatabase,
          $RecentEnteredPathsTable,
          RecentEnteredPath
        >,
      ),
      RecentEnteredPath,
      PrefetchHooks Function()
    >;
typedef $$DefaultAppsTableCreateCompanionBuilder =
    DefaultAppsCompanion Function({
      required String typeKey,
      required String appId,
      required String appName,
      required String appExec,
      Value<String?> iconPath,
      Value<int> rowid,
    });
typedef $$DefaultAppsTableUpdateCompanionBuilder =
    DefaultAppsCompanion Function({
      Value<String> typeKey,
      Value<String> appId,
      Value<String> appName,
      Value<String> appExec,
      Value<String?> iconPath,
      Value<int> rowid,
    });

class $$DefaultAppsTableFilterComposer
    extends Composer<_$AppDatabase, $DefaultAppsTable> {
  $$DefaultAppsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get typeKey => $composableBuilder(
    column: $table.typeKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appExec => $composableBuilder(
    column: $table.appExec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconPath => $composableBuilder(
    column: $table.iconPath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DefaultAppsTableOrderingComposer
    extends Composer<_$AppDatabase, $DefaultAppsTable> {
  $$DefaultAppsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get typeKey => $composableBuilder(
    column: $table.typeKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appId => $composableBuilder(
    column: $table.appId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appExec => $composableBuilder(
    column: $table.appExec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconPath => $composableBuilder(
    column: $table.iconPath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DefaultAppsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DefaultAppsTable> {
  $$DefaultAppsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get typeKey =>
      $composableBuilder(column: $table.typeKey, builder: (column) => column);

  GeneratedColumn<String> get appId =>
      $composableBuilder(column: $table.appId, builder: (column) => column);

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get appExec =>
      $composableBuilder(column: $table.appExec, builder: (column) => column);

  GeneratedColumn<String> get iconPath =>
      $composableBuilder(column: $table.iconPath, builder: (column) => column);
}

class $$DefaultAppsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DefaultAppsTable,
          DefaultApp,
          $$DefaultAppsTableFilterComposer,
          $$DefaultAppsTableOrderingComposer,
          $$DefaultAppsTableAnnotationComposer,
          $$DefaultAppsTableCreateCompanionBuilder,
          $$DefaultAppsTableUpdateCompanionBuilder,
          (
            DefaultApp,
            BaseReferences<_$AppDatabase, $DefaultAppsTable, DefaultApp>,
          ),
          DefaultApp,
          PrefetchHooks Function()
        > {
  $$DefaultAppsTableTableManager(_$AppDatabase db, $DefaultAppsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DefaultAppsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DefaultAppsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DefaultAppsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> typeKey = const Value.absent(),
                Value<String> appId = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<String> appExec = const Value.absent(),
                Value<String?> iconPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DefaultAppsCompanion(
                typeKey: typeKey,
                appId: appId,
                appName: appName,
                appExec: appExec,
                iconPath: iconPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String typeKey,
                required String appId,
                required String appName,
                required String appExec,
                Value<String?> iconPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DefaultAppsCompanion.insert(
                typeKey: typeKey,
                appId: appId,
                appName: appName,
                appExec: appExec,
                iconPath: iconPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DefaultAppsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DefaultAppsTable,
      DefaultApp,
      $$DefaultAppsTableFilterComposer,
      $$DefaultAppsTableOrderingComposer,
      $$DefaultAppsTableAnnotationComposer,
      $$DefaultAppsTableCreateCompanionBuilder,
      $$DefaultAppsTableUpdateCompanionBuilder,
      (
        DefaultApp,
        BaseReferences<_$AppDatabase, $DefaultAppsTable, DefaultApp>,
      ),
      DefaultApp,
      PrefetchHooks Function()
    >;
typedef $$ShortcutBindingsTableCreateCompanionBuilder =
    ShortcutBindingsCompanion Function({
      required String actionId,
      required int keyId,
      Value<bool> ctrl,
      Value<bool> shift,
      Value<bool> alt,
      Value<int> rowid,
    });
typedef $$ShortcutBindingsTableUpdateCompanionBuilder =
    ShortcutBindingsCompanion Function({
      Value<String> actionId,
      Value<int> keyId,
      Value<bool> ctrl,
      Value<bool> shift,
      Value<bool> alt,
      Value<int> rowid,
    });

class $$ShortcutBindingsTableFilterComposer
    extends Composer<_$AppDatabase, $ShortcutBindingsTable> {
  $$ShortcutBindingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ctrl => $composableBuilder(
    column: $table.ctrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shift => $composableBuilder(
    column: $table.shift,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get alt => $composableBuilder(
    column: $table.alt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ShortcutBindingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShortcutBindingsTable> {
  $$ShortcutBindingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get actionId => $composableBuilder(
    column: $table.actionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get keyId => $composableBuilder(
    column: $table.keyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ctrl => $composableBuilder(
    column: $table.ctrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shift => $composableBuilder(
    column: $table.shift,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get alt => $composableBuilder(
    column: $table.alt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ShortcutBindingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShortcutBindingsTable> {
  $$ShortcutBindingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get actionId =>
      $composableBuilder(column: $table.actionId, builder: (column) => column);

  GeneratedColumn<int> get keyId =>
      $composableBuilder(column: $table.keyId, builder: (column) => column);

  GeneratedColumn<bool> get ctrl =>
      $composableBuilder(column: $table.ctrl, builder: (column) => column);

  GeneratedColumn<bool> get shift =>
      $composableBuilder(column: $table.shift, builder: (column) => column);

  GeneratedColumn<bool> get alt =>
      $composableBuilder(column: $table.alt, builder: (column) => column);
}

class $$ShortcutBindingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShortcutBindingsTable,
          ShortcutBinding,
          $$ShortcutBindingsTableFilterComposer,
          $$ShortcutBindingsTableOrderingComposer,
          $$ShortcutBindingsTableAnnotationComposer,
          $$ShortcutBindingsTableCreateCompanionBuilder,
          $$ShortcutBindingsTableUpdateCompanionBuilder,
          (
            ShortcutBinding,
            BaseReferences<
              _$AppDatabase,
              $ShortcutBindingsTable,
              ShortcutBinding
            >,
          ),
          ShortcutBinding,
          PrefetchHooks Function()
        > {
  $$ShortcutBindingsTableTableManager(
    _$AppDatabase db,
    $ShortcutBindingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShortcutBindingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShortcutBindingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShortcutBindingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> actionId = const Value.absent(),
                Value<int> keyId = const Value.absent(),
                Value<bool> ctrl = const Value.absent(),
                Value<bool> shift = const Value.absent(),
                Value<bool> alt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShortcutBindingsCompanion(
                actionId: actionId,
                keyId: keyId,
                ctrl: ctrl,
                shift: shift,
                alt: alt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String actionId,
                required int keyId,
                Value<bool> ctrl = const Value.absent(),
                Value<bool> shift = const Value.absent(),
                Value<bool> alt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShortcutBindingsCompanion.insert(
                actionId: actionId,
                keyId: keyId,
                ctrl: ctrl,
                shift: shift,
                alt: alt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShortcutBindingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShortcutBindingsTable,
      ShortcutBinding,
      $$ShortcutBindingsTableFilterComposer,
      $$ShortcutBindingsTableOrderingComposer,
      $$ShortcutBindingsTableAnnotationComposer,
      $$ShortcutBindingsTableCreateCompanionBuilder,
      $$ShortcutBindingsTableUpdateCompanionBuilder,
      (
        ShortcutBinding,
        BaseReferences<_$AppDatabase, $ShortcutBindingsTable, ShortcutBinding>,
      ),
      ShortcutBinding,
      PrefetchHooks Function()
    >;
typedef $$PluginSettingsTableCreateCompanionBuilder =
    PluginSettingsCompanion Function({
      required String pluginId,
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PluginSettingsTableUpdateCompanionBuilder =
    PluginSettingsCompanion Function({
      Value<String> pluginId,
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PluginSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $PluginSettingsTable> {
  $$PluginSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pluginId => $composableBuilder(
    column: $table.pluginId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PluginSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $PluginSettingsTable> {
  $$PluginSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pluginId => $composableBuilder(
    column: $table.pluginId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PluginSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PluginSettingsTable> {
  $$PluginSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pluginId =>
      $composableBuilder(column: $table.pluginId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PluginSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PluginSettingsTable,
          PluginSetting,
          $$PluginSettingsTableFilterComposer,
          $$PluginSettingsTableOrderingComposer,
          $$PluginSettingsTableAnnotationComposer,
          $$PluginSettingsTableCreateCompanionBuilder,
          $$PluginSettingsTableUpdateCompanionBuilder,
          (
            PluginSetting,
            BaseReferences<_$AppDatabase, $PluginSettingsTable, PluginSetting>,
          ),
          PluginSetting,
          PrefetchHooks Function()
        > {
  $$PluginSettingsTableTableManager(
    _$AppDatabase db,
    $PluginSettingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PluginSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PluginSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PluginSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pluginId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PluginSettingsCompanion(
                pluginId: pluginId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String pluginId,
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PluginSettingsCompanion.insert(
                pluginId: pluginId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PluginSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PluginSettingsTable,
      PluginSetting,
      $$PluginSettingsTableFilterComposer,
      $$PluginSettingsTableOrderingComposer,
      $$PluginSettingsTableAnnotationComposer,
      $$PluginSettingsTableCreateCompanionBuilder,
      $$PluginSettingsTableUpdateCompanionBuilder,
      (
        PluginSetting,
        BaseReferences<_$AppDatabase, $PluginSettingsTable, PluginSetting>,
      ),
      PluginSetting,
      PrefetchHooks Function()
    >;
typedef $$DisabledPluginsTableCreateCompanionBuilder =
    DisabledPluginsCompanion Function({
      required String pluginId,
      Value<int> rowid,
    });
typedef $$DisabledPluginsTableUpdateCompanionBuilder =
    DisabledPluginsCompanion Function({
      Value<String> pluginId,
      Value<int> rowid,
    });

class $$DisabledPluginsTableFilterComposer
    extends Composer<_$AppDatabase, $DisabledPluginsTable> {
  $$DisabledPluginsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get pluginId => $composableBuilder(
    column: $table.pluginId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DisabledPluginsTableOrderingComposer
    extends Composer<_$AppDatabase, $DisabledPluginsTable> {
  $$DisabledPluginsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get pluginId => $composableBuilder(
    column: $table.pluginId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DisabledPluginsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DisabledPluginsTable> {
  $$DisabledPluginsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get pluginId =>
      $composableBuilder(column: $table.pluginId, builder: (column) => column);
}

class $$DisabledPluginsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DisabledPluginsTable,
          DisabledPlugin,
          $$DisabledPluginsTableFilterComposer,
          $$DisabledPluginsTableOrderingComposer,
          $$DisabledPluginsTableAnnotationComposer,
          $$DisabledPluginsTableCreateCompanionBuilder,
          $$DisabledPluginsTableUpdateCompanionBuilder,
          (
            DisabledPlugin,
            BaseReferences<
              _$AppDatabase,
              $DisabledPluginsTable,
              DisabledPlugin
            >,
          ),
          DisabledPlugin,
          PrefetchHooks Function()
        > {
  $$DisabledPluginsTableTableManager(
    _$AppDatabase db,
    $DisabledPluginsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DisabledPluginsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DisabledPluginsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DisabledPluginsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> pluginId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DisabledPluginsCompanion(pluginId: pluginId, rowid: rowid),
          createCompanionCallback:
              ({
                required String pluginId,
                Value<int> rowid = const Value.absent(),
              }) => DisabledPluginsCompanion.insert(
                pluginId: pluginId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DisabledPluginsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DisabledPluginsTable,
      DisabledPlugin,
      $$DisabledPluginsTableFilterComposer,
      $$DisabledPluginsTableOrderingComposer,
      $$DisabledPluginsTableAnnotationComposer,
      $$DisabledPluginsTableCreateCompanionBuilder,
      $$DisabledPluginsTableUpdateCompanionBuilder,
      (
        DisabledPlugin,
        BaseReferences<_$AppDatabase, $DisabledPluginsTable, DisabledPlugin>,
      ),
      DisabledPlugin,
      PrefetchHooks Function()
    >;
typedef $$SidebarPrefsTableCreateCompanionBuilder =
    SidebarPrefsCompanion Function({
      required String scope,
      required String itemKey,
      Value<int> orderIndex,
      Value<bool> hidden,
      Value<int> rowid,
    });
typedef $$SidebarPrefsTableUpdateCompanionBuilder =
    SidebarPrefsCompanion Function({
      Value<String> scope,
      Value<String> itemKey,
      Value<int> orderIndex,
      Value<bool> hidden,
      Value<int> rowid,
    });

class $$SidebarPrefsTableFilterComposer
    extends Composer<_$AppDatabase, $SidebarPrefsTable> {
  $$SidebarPrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SidebarPrefsTableOrderingComposer
    extends Composer<_$AppDatabase, $SidebarPrefsTable> {
  $$SidebarPrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemKey => $composableBuilder(
    column: $table.itemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SidebarPrefsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SidebarPrefsTable> {
  $$SidebarPrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get itemKey =>
      $composableBuilder(column: $table.itemKey, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);
}

class $$SidebarPrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SidebarPrefsTable,
          SidebarPref,
          $$SidebarPrefsTableFilterComposer,
          $$SidebarPrefsTableOrderingComposer,
          $$SidebarPrefsTableAnnotationComposer,
          $$SidebarPrefsTableCreateCompanionBuilder,
          $$SidebarPrefsTableUpdateCompanionBuilder,
          (
            SidebarPref,
            BaseReferences<_$AppDatabase, $SidebarPrefsTable, SidebarPref>,
          ),
          SidebarPref,
          PrefetchHooks Function()
        > {
  $$SidebarPrefsTableTableManager(_$AppDatabase db, $SidebarPrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SidebarPrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SidebarPrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SidebarPrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scope = const Value.absent(),
                Value<String> itemKey = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SidebarPrefsCompanion(
                scope: scope,
                itemKey: itemKey,
                orderIndex: orderIndex,
                hidden: hidden,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scope,
                required String itemKey,
                Value<int> orderIndex = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SidebarPrefsCompanion.insert(
                scope: scope,
                itemKey: itemKey,
                orderIndex: orderIndex,
                hidden: hidden,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SidebarPrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SidebarPrefsTable,
      SidebarPref,
      $$SidebarPrefsTableFilterComposer,
      $$SidebarPrefsTableOrderingComposer,
      $$SidebarPrefsTableAnnotationComposer,
      $$SidebarPrefsTableCreateCompanionBuilder,
      $$SidebarPrefsTableUpdateCompanionBuilder,
      (
        SidebarPref,
        BaseReferences<_$AppDatabase, $SidebarPrefsTable, SidebarPref>,
      ),
      SidebarPref,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SessionTabsTableTableManager get sessionTabs =>
      $$SessionTabsTableTableManager(_db, _db.sessionTabs);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$FolderPrefsTableTableManager get folderPrefs =>
      $$FolderPrefsTableTableManager(_db, _db.folderPrefs);
  $$RecentAppsTableTableManager get recentApps =>
      $$RecentAppsTableTableManager(_db, _db.recentApps);
  $$RecentEnteredPathsTableTableManager get recentEnteredPaths =>
      $$RecentEnteredPathsTableTableManager(_db, _db.recentEnteredPaths);
  $$DefaultAppsTableTableManager get defaultApps =>
      $$DefaultAppsTableTableManager(_db, _db.defaultApps);
  $$ShortcutBindingsTableTableManager get shortcutBindings =>
      $$ShortcutBindingsTableTableManager(_db, _db.shortcutBindings);
  $$PluginSettingsTableTableManager get pluginSettings =>
      $$PluginSettingsTableTableManager(_db, _db.pluginSettings);
  $$DisabledPluginsTableTableManager get disabledPlugins =>
      $$DisabledPluginsTableTableManager(_db, _db.disabledPlugins);
  $$SidebarPrefsTableTableManager get sidebarPrefs =>
      $$SidebarPrefsTableTableManager(_db, _db.sidebarPrefs);
}
