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
    defaultValue: const Constant('system'),
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
    defaultValue: const Constant('auto'),
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    themeMode,
    terminal,
    terminalCustomCommand,
    isDual,
    splitRatio,
    activePaneIndex,
    sidebarCollapsed,
    restoreSession,
    defaultStartingPath,
    confirmDelete,
    showHiddenDefault,
    rowDensity,
    dateFormat,
    recentDatesRelative,
    deleteKeyBehavior,
    sortKey,
    sortAscending,
    foldersFirst,
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
    if (data.containsKey('terminal_custom_command')) {
      context.handle(
        _terminalCustomCommandMeta,
        terminalCustomCommand.isAcceptableOrUnknown(
          data['terminal_custom_command']!,
          _terminalCustomCommandMeta,
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
      terminalCustomCommand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terminal_custom_command'],
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
      showHiddenDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_hidden_default'],
      )!,
      rowDensity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_density'],
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
  final String terminalCustomCommand;
  final bool isDual;
  final double splitRatio;
  final int activePaneIndex;
  final bool sidebarCollapsed;
  final bool restoreSession;
  final String defaultStartingPath;
  final bool confirmDelete;
  final bool showHiddenDefault;
  final String rowDensity;
  final String dateFormat;
  final bool recentDatesRelative;
  final String deleteKeyBehavior;
  final String sortKey;
  final bool sortAscending;
  final bool foldersFirst;
  const AppSetting({
    required this.id,
    required this.themeMode,
    required this.terminal,
    required this.terminalCustomCommand,
    required this.isDual,
    required this.splitRatio,
    required this.activePaneIndex,
    required this.sidebarCollapsed,
    required this.restoreSession,
    required this.defaultStartingPath,
    required this.confirmDelete,
    required this.showHiddenDefault,
    required this.rowDensity,
    required this.dateFormat,
    required this.recentDatesRelative,
    required this.deleteKeyBehavior,
    required this.sortKey,
    required this.sortAscending,
    required this.foldersFirst,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['theme_mode'] = Variable<String>(themeMode);
    map['terminal'] = Variable<String>(terminal);
    map['terminal_custom_command'] = Variable<String>(terminalCustomCommand);
    map['is_dual'] = Variable<bool>(isDual);
    map['split_ratio'] = Variable<double>(splitRatio);
    map['active_pane_index'] = Variable<int>(activePaneIndex);
    map['sidebar_collapsed'] = Variable<bool>(sidebarCollapsed);
    map['restore_session'] = Variable<bool>(restoreSession);
    map['default_starting_path'] = Variable<String>(defaultStartingPath);
    map['confirm_delete'] = Variable<bool>(confirmDelete);
    map['show_hidden_default'] = Variable<bool>(showHiddenDefault);
    map['row_density'] = Variable<String>(rowDensity);
    map['date_format'] = Variable<String>(dateFormat);
    map['recent_dates_relative'] = Variable<bool>(recentDatesRelative);
    map['delete_key_behavior'] = Variable<String>(deleteKeyBehavior);
    map['sort_key'] = Variable<String>(sortKey);
    map['sort_ascending'] = Variable<bool>(sortAscending);
    map['folders_first'] = Variable<bool>(foldersFirst);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      themeMode: Value(themeMode),
      terminal: Value(terminal),
      terminalCustomCommand: Value(terminalCustomCommand),
      isDual: Value(isDual),
      splitRatio: Value(splitRatio),
      activePaneIndex: Value(activePaneIndex),
      sidebarCollapsed: Value(sidebarCollapsed),
      restoreSession: Value(restoreSession),
      defaultStartingPath: Value(defaultStartingPath),
      confirmDelete: Value(confirmDelete),
      showHiddenDefault: Value(showHiddenDefault),
      rowDensity: Value(rowDensity),
      dateFormat: Value(dateFormat),
      recentDatesRelative: Value(recentDatesRelative),
      deleteKeyBehavior: Value(deleteKeyBehavior),
      sortKey: Value(sortKey),
      sortAscending: Value(sortAscending),
      foldersFirst: Value(foldersFirst),
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
      terminalCustomCommand: serializer.fromJson<String>(
        json['terminalCustomCommand'],
      ),
      isDual: serializer.fromJson<bool>(json['isDual']),
      splitRatio: serializer.fromJson<double>(json['splitRatio']),
      activePaneIndex: serializer.fromJson<int>(json['activePaneIndex']),
      sidebarCollapsed: serializer.fromJson<bool>(json['sidebarCollapsed']),
      restoreSession: serializer.fromJson<bool>(json['restoreSession']),
      defaultStartingPath: serializer.fromJson<String>(
        json['defaultStartingPath'],
      ),
      confirmDelete: serializer.fromJson<bool>(json['confirmDelete']),
      showHiddenDefault: serializer.fromJson<bool>(json['showHiddenDefault']),
      rowDensity: serializer.fromJson<String>(json['rowDensity']),
      dateFormat: serializer.fromJson<String>(json['dateFormat']),
      recentDatesRelative: serializer.fromJson<bool>(
        json['recentDatesRelative'],
      ),
      deleteKeyBehavior: serializer.fromJson<String>(json['deleteKeyBehavior']),
      sortKey: serializer.fromJson<String>(json['sortKey']),
      sortAscending: serializer.fromJson<bool>(json['sortAscending']),
      foldersFirst: serializer.fromJson<bool>(json['foldersFirst']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'themeMode': serializer.toJson<String>(themeMode),
      'terminal': serializer.toJson<String>(terminal),
      'terminalCustomCommand': serializer.toJson<String>(terminalCustomCommand),
      'isDual': serializer.toJson<bool>(isDual),
      'splitRatio': serializer.toJson<double>(splitRatio),
      'activePaneIndex': serializer.toJson<int>(activePaneIndex),
      'sidebarCollapsed': serializer.toJson<bool>(sidebarCollapsed),
      'restoreSession': serializer.toJson<bool>(restoreSession),
      'defaultStartingPath': serializer.toJson<String>(defaultStartingPath),
      'confirmDelete': serializer.toJson<bool>(confirmDelete),
      'showHiddenDefault': serializer.toJson<bool>(showHiddenDefault),
      'rowDensity': serializer.toJson<String>(rowDensity),
      'dateFormat': serializer.toJson<String>(dateFormat),
      'recentDatesRelative': serializer.toJson<bool>(recentDatesRelative),
      'deleteKeyBehavior': serializer.toJson<String>(deleteKeyBehavior),
      'sortKey': serializer.toJson<String>(sortKey),
      'sortAscending': serializer.toJson<bool>(sortAscending),
      'foldersFirst': serializer.toJson<bool>(foldersFirst),
    };
  }

  AppSetting copyWith({
    int? id,
    String? themeMode,
    String? terminal,
    String? terminalCustomCommand,
    bool? isDual,
    double? splitRatio,
    int? activePaneIndex,
    bool? sidebarCollapsed,
    bool? restoreSession,
    String? defaultStartingPath,
    bool? confirmDelete,
    bool? showHiddenDefault,
    String? rowDensity,
    String? dateFormat,
    bool? recentDatesRelative,
    String? deleteKeyBehavior,
    String? sortKey,
    bool? sortAscending,
    bool? foldersFirst,
  }) => AppSetting(
    id: id ?? this.id,
    themeMode: themeMode ?? this.themeMode,
    terminal: terminal ?? this.terminal,
    terminalCustomCommand: terminalCustomCommand ?? this.terminalCustomCommand,
    isDual: isDual ?? this.isDual,
    splitRatio: splitRatio ?? this.splitRatio,
    activePaneIndex: activePaneIndex ?? this.activePaneIndex,
    sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
    restoreSession: restoreSession ?? this.restoreSession,
    defaultStartingPath: defaultStartingPath ?? this.defaultStartingPath,
    confirmDelete: confirmDelete ?? this.confirmDelete,
    showHiddenDefault: showHiddenDefault ?? this.showHiddenDefault,
    rowDensity: rowDensity ?? this.rowDensity,
    dateFormat: dateFormat ?? this.dateFormat,
    recentDatesRelative: recentDatesRelative ?? this.recentDatesRelative,
    deleteKeyBehavior: deleteKeyBehavior ?? this.deleteKeyBehavior,
    sortKey: sortKey ?? this.sortKey,
    sortAscending: sortAscending ?? this.sortAscending,
    foldersFirst: foldersFirst ?? this.foldersFirst,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      terminal: data.terminal.present ? data.terminal.value : this.terminal,
      terminalCustomCommand: data.terminalCustomCommand.present
          ? data.terminalCustomCommand.value
          : this.terminalCustomCommand,
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
      restoreSession: data.restoreSession.present
          ? data.restoreSession.value
          : this.restoreSession,
      defaultStartingPath: data.defaultStartingPath.present
          ? data.defaultStartingPath.value
          : this.defaultStartingPath,
      confirmDelete: data.confirmDelete.present
          ? data.confirmDelete.value
          : this.confirmDelete,
      showHiddenDefault: data.showHiddenDefault.present
          ? data.showHiddenDefault.value
          : this.showHiddenDefault,
      rowDensity: data.rowDensity.present
          ? data.rowDensity.value
          : this.rowDensity,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('terminal: $terminal, ')
          ..write('terminalCustomCommand: $terminalCustomCommand, ')
          ..write('isDual: $isDual, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('activePaneIndex: $activePaneIndex, ')
          ..write('sidebarCollapsed: $sidebarCollapsed, ')
          ..write('restoreSession: $restoreSession, ')
          ..write('defaultStartingPath: $defaultStartingPath, ')
          ..write('confirmDelete: $confirmDelete, ')
          ..write('showHiddenDefault: $showHiddenDefault, ')
          ..write('rowDensity: $rowDensity, ')
          ..write('dateFormat: $dateFormat, ')
          ..write('recentDatesRelative: $recentDatesRelative, ')
          ..write('deleteKeyBehavior: $deleteKeyBehavior, ')
          ..write('sortKey: $sortKey, ')
          ..write('sortAscending: $sortAscending, ')
          ..write('foldersFirst: $foldersFirst')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    themeMode,
    terminal,
    terminalCustomCommand,
    isDual,
    splitRatio,
    activePaneIndex,
    sidebarCollapsed,
    restoreSession,
    defaultStartingPath,
    confirmDelete,
    showHiddenDefault,
    rowDensity,
    dateFormat,
    recentDatesRelative,
    deleteKeyBehavior,
    sortKey,
    sortAscending,
    foldersFirst,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.themeMode == this.themeMode &&
          other.terminal == this.terminal &&
          other.terminalCustomCommand == this.terminalCustomCommand &&
          other.isDual == this.isDual &&
          other.splitRatio == this.splitRatio &&
          other.activePaneIndex == this.activePaneIndex &&
          other.sidebarCollapsed == this.sidebarCollapsed &&
          other.restoreSession == this.restoreSession &&
          other.defaultStartingPath == this.defaultStartingPath &&
          other.confirmDelete == this.confirmDelete &&
          other.showHiddenDefault == this.showHiddenDefault &&
          other.rowDensity == this.rowDensity &&
          other.dateFormat == this.dateFormat &&
          other.recentDatesRelative == this.recentDatesRelative &&
          other.deleteKeyBehavior == this.deleteKeyBehavior &&
          other.sortKey == this.sortKey &&
          other.sortAscending == this.sortAscending &&
          other.foldersFirst == this.foldersFirst);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<String> themeMode;
  final Value<String> terminal;
  final Value<String> terminalCustomCommand;
  final Value<bool> isDual;
  final Value<double> splitRatio;
  final Value<int> activePaneIndex;
  final Value<bool> sidebarCollapsed;
  final Value<bool> restoreSession;
  final Value<String> defaultStartingPath;
  final Value<bool> confirmDelete;
  final Value<bool> showHiddenDefault;
  final Value<String> rowDensity;
  final Value<String> dateFormat;
  final Value<bool> recentDatesRelative;
  final Value<String> deleteKeyBehavior;
  final Value<String> sortKey;
  final Value<bool> sortAscending;
  final Value<bool> foldersFirst;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.terminal = const Value.absent(),
    this.terminalCustomCommand = const Value.absent(),
    this.isDual = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.activePaneIndex = const Value.absent(),
    this.sidebarCollapsed = const Value.absent(),
    this.restoreSession = const Value.absent(),
    this.defaultStartingPath = const Value.absent(),
    this.confirmDelete = const Value.absent(),
    this.showHiddenDefault = const Value.absent(),
    this.rowDensity = const Value.absent(),
    this.dateFormat = const Value.absent(),
    this.recentDatesRelative = const Value.absent(),
    this.deleteKeyBehavior = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.foldersFirst = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.terminal = const Value.absent(),
    this.terminalCustomCommand = const Value.absent(),
    this.isDual = const Value.absent(),
    this.splitRatio = const Value.absent(),
    this.activePaneIndex = const Value.absent(),
    this.sidebarCollapsed = const Value.absent(),
    this.restoreSession = const Value.absent(),
    this.defaultStartingPath = const Value.absent(),
    this.confirmDelete = const Value.absent(),
    this.showHiddenDefault = const Value.absent(),
    this.rowDensity = const Value.absent(),
    this.dateFormat = const Value.absent(),
    this.recentDatesRelative = const Value.absent(),
    this.deleteKeyBehavior = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.foldersFirst = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<String>? themeMode,
    Expression<String>? terminal,
    Expression<String>? terminalCustomCommand,
    Expression<bool>? isDual,
    Expression<double>? splitRatio,
    Expression<int>? activePaneIndex,
    Expression<bool>? sidebarCollapsed,
    Expression<bool>? restoreSession,
    Expression<String>? defaultStartingPath,
    Expression<bool>? confirmDelete,
    Expression<bool>? showHiddenDefault,
    Expression<String>? rowDensity,
    Expression<String>? dateFormat,
    Expression<bool>? recentDatesRelative,
    Expression<String>? deleteKeyBehavior,
    Expression<String>? sortKey,
    Expression<bool>? sortAscending,
    Expression<bool>? foldersFirst,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (themeMode != null) 'theme_mode': themeMode,
      if (terminal != null) 'terminal': terminal,
      if (terminalCustomCommand != null)
        'terminal_custom_command': terminalCustomCommand,
      if (isDual != null) 'is_dual': isDual,
      if (splitRatio != null) 'split_ratio': splitRatio,
      if (activePaneIndex != null) 'active_pane_index': activePaneIndex,
      if (sidebarCollapsed != null) 'sidebar_collapsed': sidebarCollapsed,
      if (restoreSession != null) 'restore_session': restoreSession,
      if (defaultStartingPath != null)
        'default_starting_path': defaultStartingPath,
      if (confirmDelete != null) 'confirm_delete': confirmDelete,
      if (showHiddenDefault != null) 'show_hidden_default': showHiddenDefault,
      if (rowDensity != null) 'row_density': rowDensity,
      if (dateFormat != null) 'date_format': dateFormat,
      if (recentDatesRelative != null)
        'recent_dates_relative': recentDatesRelative,
      if (deleteKeyBehavior != null) 'delete_key_behavior': deleteKeyBehavior,
      if (sortKey != null) 'sort_key': sortKey,
      if (sortAscending != null) 'sort_ascending': sortAscending,
      if (foldersFirst != null) 'folders_first': foldersFirst,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? themeMode,
    Value<String>? terminal,
    Value<String>? terminalCustomCommand,
    Value<bool>? isDual,
    Value<double>? splitRatio,
    Value<int>? activePaneIndex,
    Value<bool>? sidebarCollapsed,
    Value<bool>? restoreSession,
    Value<String>? defaultStartingPath,
    Value<bool>? confirmDelete,
    Value<bool>? showHiddenDefault,
    Value<String>? rowDensity,
    Value<String>? dateFormat,
    Value<bool>? recentDatesRelative,
    Value<String>? deleteKeyBehavior,
    Value<String>? sortKey,
    Value<bool>? sortAscending,
    Value<bool>? foldersFirst,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      themeMode: themeMode ?? this.themeMode,
      terminal: terminal ?? this.terminal,
      terminalCustomCommand:
          terminalCustomCommand ?? this.terminalCustomCommand,
      isDual: isDual ?? this.isDual,
      splitRatio: splitRatio ?? this.splitRatio,
      activePaneIndex: activePaneIndex ?? this.activePaneIndex,
      sidebarCollapsed: sidebarCollapsed ?? this.sidebarCollapsed,
      restoreSession: restoreSession ?? this.restoreSession,
      defaultStartingPath: defaultStartingPath ?? this.defaultStartingPath,
      confirmDelete: confirmDelete ?? this.confirmDelete,
      showHiddenDefault: showHiddenDefault ?? this.showHiddenDefault,
      rowDensity: rowDensity ?? this.rowDensity,
      dateFormat: dateFormat ?? this.dateFormat,
      recentDatesRelative: recentDatesRelative ?? this.recentDatesRelative,
      deleteKeyBehavior: deleteKeyBehavior ?? this.deleteKeyBehavior,
      sortKey: sortKey ?? this.sortKey,
      sortAscending: sortAscending ?? this.sortAscending,
      foldersFirst: foldersFirst ?? this.foldersFirst,
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
    if (terminalCustomCommand.present) {
      map['terminal_custom_command'] = Variable<String>(
        terminalCustomCommand.value,
      );
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
    if (showHiddenDefault.present) {
      map['show_hidden_default'] = Variable<bool>(showHiddenDefault.value);
    }
    if (rowDensity.present) {
      map['row_density'] = Variable<String>(rowDensity.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('themeMode: $themeMode, ')
          ..write('terminal: $terminal, ')
          ..write('terminalCustomCommand: $terminalCustomCommand, ')
          ..write('isDual: $isDual, ')
          ..write('splitRatio: $splitRatio, ')
          ..write('activePaneIndex: $activePaneIndex, ')
          ..write('sidebarCollapsed: $sidebarCollapsed, ')
          ..write('restoreSession: $restoreSession, ')
          ..write('defaultStartingPath: $defaultStartingPath, ')
          ..write('confirmDelete: $confirmDelete, ')
          ..write('showHiddenDefault: $showHiddenDefault, ')
          ..write('rowDensity: $rowDensity, ')
          ..write('dateFormat: $dateFormat, ')
          ..write('recentDatesRelative: $recentDatesRelative, ')
          ..write('deleteKeyBehavior: $deleteKeyBehavior, ')
          ..write('sortKey: $sortKey, ')
          ..write('sortAscending: $sortAscending, ')
          ..write('foldersFirst: $foldersFirst')
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
  final int updatedAt;
  const FolderPref({
    required this.path,
    required this.sortKey,
    required this.sortAscending,
    required this.foldersFirst,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['path'] = Variable<String>(path);
    map['sort_key'] = Variable<String>(sortKey);
    map['sort_ascending'] = Variable<bool>(sortAscending);
    map['folders_first'] = Variable<bool>(foldersFirst);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  FolderPrefsCompanion toCompanion(bool nullToAbsent) {
    return FolderPrefsCompanion(
      path: Value(path),
      sortKey: Value(sortKey),
      sortAscending: Value(sortAscending),
      foldersFirst: Value(foldersFirst),
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
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  FolderPref copyWith({
    String? path,
    String? sortKey,
    bool? sortAscending,
    bool? foldersFirst,
    int? updatedAt,
  }) => FolderPref(
    path: path ?? this.path,
    sortKey: sortKey ?? this.sortKey,
    sortAscending: sortAscending ?? this.sortAscending,
    foldersFirst: foldersFirst ?? this.foldersFirst,
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
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(path, sortKey, sortAscending, foldersFirst, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FolderPref &&
          other.path == this.path &&
          other.sortKey == this.sortKey &&
          other.sortAscending == this.sortAscending &&
          other.foldersFirst == this.foldersFirst &&
          other.updatedAt == this.updatedAt);
}

class FolderPrefsCompanion extends UpdateCompanion<FolderPref> {
  final Value<String> path;
  final Value<String> sortKey;
  final Value<bool> sortAscending;
  final Value<bool> foldersFirst;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const FolderPrefsCompanion({
    this.path = const Value.absent(),
    this.sortKey = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.foldersFirst = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FolderPrefsCompanion.insert({
    required String path,
    this.sortKey = const Value.absent(),
    this.sortAscending = const Value.absent(),
    this.foldersFirst = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : path = Value(path);
  static Insertable<FolderPref> custom({
    Expression<String>? path,
    Expression<String>? sortKey,
    Expression<bool>? sortAscending,
    Expression<bool>? foldersFirst,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (path != null) 'path': path,
      if (sortKey != null) 'sort_key': sortKey,
      if (sortAscending != null) 'sort_ascending': sortAscending,
      if (foldersFirst != null) 'folders_first': foldersFirst,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FolderPrefsCompanion copyWith({
    Value<String>? path,
    Value<String>? sortKey,
    Value<bool>? sortAscending,
    Value<bool>? foldersFirst,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return FolderPrefsCompanion(
      path: path ?? this.path,
      sortKey: sortKey ?? this.sortKey,
      sortAscending: sortAscending ?? this.sortAscending,
      foldersFirst: foldersFirst ?? this.foldersFirst,
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SessionTabsTable sessionTabs = $SessionTabsTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $FolderPrefsTable folderPrefs = $FolderPrefsTable(this);
  late final $RecentAppsTable recentApps = $RecentAppsTable(this);
  late final $DefaultAppsTable defaultApps = $DefaultAppsTable(this);
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
    defaultApps,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<String> terminal,
      Value<String> terminalCustomCommand,
      Value<bool> isDual,
      Value<double> splitRatio,
      Value<int> activePaneIndex,
      Value<bool> sidebarCollapsed,
      Value<bool> restoreSession,
      Value<String> defaultStartingPath,
      Value<bool> confirmDelete,
      Value<bool> showHiddenDefault,
      Value<String> rowDensity,
      Value<String> dateFormat,
      Value<bool> recentDatesRelative,
      Value<String> deleteKeyBehavior,
      Value<String> sortKey,
      Value<bool> sortAscending,
      Value<bool> foldersFirst,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> themeMode,
      Value<String> terminal,
      Value<String> terminalCustomCommand,
      Value<bool> isDual,
      Value<double> splitRatio,
      Value<int> activePaneIndex,
      Value<bool> sidebarCollapsed,
      Value<bool> restoreSession,
      Value<String> defaultStartingPath,
      Value<bool> confirmDelete,
      Value<bool> showHiddenDefault,
      Value<String> rowDensity,
      Value<String> dateFormat,
      Value<bool> recentDatesRelative,
      Value<String> deleteKeyBehavior,
      Value<String> sortKey,
      Value<bool> sortAscending,
      Value<bool> foldersFirst,
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

  ColumnFilters<String> get terminalCustomCommand => $composableBuilder(
    column: $table.terminalCustomCommand,
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

  ColumnFilters<bool> get showHiddenDefault => $composableBuilder(
    column: $table.showHiddenDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowDensity => $composableBuilder(
    column: $table.rowDensity,
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

  ColumnOrderings<String> get terminalCustomCommand => $composableBuilder(
    column: $table.terminalCustomCommand,
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

  ColumnOrderings<bool> get showHiddenDefault => $composableBuilder(
    column: $table.showHiddenDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowDensity => $composableBuilder(
    column: $table.rowDensity,
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

  GeneratedColumn<String> get terminalCustomCommand => $composableBuilder(
    column: $table.terminalCustomCommand,
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

  GeneratedColumn<bool> get showHiddenDefault => $composableBuilder(
    column: $table.showHiddenDefault,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowDensity => $composableBuilder(
    column: $table.rowDensity,
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
                Value<String> terminalCustomCommand = const Value.absent(),
                Value<bool> isDual = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<int> activePaneIndex = const Value.absent(),
                Value<bool> sidebarCollapsed = const Value.absent(),
                Value<bool> restoreSession = const Value.absent(),
                Value<String> defaultStartingPath = const Value.absent(),
                Value<bool> confirmDelete = const Value.absent(),
                Value<bool> showHiddenDefault = const Value.absent(),
                Value<String> rowDensity = const Value.absent(),
                Value<String> dateFormat = const Value.absent(),
                Value<bool> recentDatesRelative = const Value.absent(),
                Value<String> deleteKeyBehavior = const Value.absent(),
                Value<String> sortKey = const Value.absent(),
                Value<bool> sortAscending = const Value.absent(),
                Value<bool> foldersFirst = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                themeMode: themeMode,
                terminal: terminal,
                terminalCustomCommand: terminalCustomCommand,
                isDual: isDual,
                splitRatio: splitRatio,
                activePaneIndex: activePaneIndex,
                sidebarCollapsed: sidebarCollapsed,
                restoreSession: restoreSession,
                defaultStartingPath: defaultStartingPath,
                confirmDelete: confirmDelete,
                showHiddenDefault: showHiddenDefault,
                rowDensity: rowDensity,
                dateFormat: dateFormat,
                recentDatesRelative: recentDatesRelative,
                deleteKeyBehavior: deleteKeyBehavior,
                sortKey: sortKey,
                sortAscending: sortAscending,
                foldersFirst: foldersFirst,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> terminal = const Value.absent(),
                Value<String> terminalCustomCommand = const Value.absent(),
                Value<bool> isDual = const Value.absent(),
                Value<double> splitRatio = const Value.absent(),
                Value<int> activePaneIndex = const Value.absent(),
                Value<bool> sidebarCollapsed = const Value.absent(),
                Value<bool> restoreSession = const Value.absent(),
                Value<String> defaultStartingPath = const Value.absent(),
                Value<bool> confirmDelete = const Value.absent(),
                Value<bool> showHiddenDefault = const Value.absent(),
                Value<String> rowDensity = const Value.absent(),
                Value<String> dateFormat = const Value.absent(),
                Value<bool> recentDatesRelative = const Value.absent(),
                Value<String> deleteKeyBehavior = const Value.absent(),
                Value<String> sortKey = const Value.absent(),
                Value<bool> sortAscending = const Value.absent(),
                Value<bool> foldersFirst = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                themeMode: themeMode,
                terminal: terminal,
                terminalCustomCommand: terminalCustomCommand,
                isDual: isDual,
                splitRatio: splitRatio,
                activePaneIndex: activePaneIndex,
                sidebarCollapsed: sidebarCollapsed,
                restoreSession: restoreSession,
                defaultStartingPath: defaultStartingPath,
                confirmDelete: confirmDelete,
                showHiddenDefault: showHiddenDefault,
                rowDensity: rowDensity,
                dateFormat: dateFormat,
                recentDatesRelative: recentDatesRelative,
                deleteKeyBehavior: deleteKeyBehavior,
                sortKey: sortKey,
                sortAscending: sortAscending,
                foldersFirst: foldersFirst,
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
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$FolderPrefsTableUpdateCompanionBuilder =
    FolderPrefsCompanion Function({
      Value<String> path,
      Value<String> sortKey,
      Value<bool> sortAscending,
      Value<bool> foldersFirst,
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
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderPrefsCompanion(
                path: path,
                sortKey: sortKey,
                sortAscending: sortAscending,
                foldersFirst: foldersFirst,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String path,
                Value<String> sortKey = const Value.absent(),
                Value<bool> sortAscending = const Value.absent(),
                Value<bool> foldersFirst = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FolderPrefsCompanion.insert(
                path: path,
                sortKey: sortKey,
                sortAscending: sortAscending,
                foldersFirst: foldersFirst,
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
  $$DefaultAppsTableTableManager get defaultApps =>
      $$DefaultAppsTableTableManager(_db, _db.defaultApps);
}
