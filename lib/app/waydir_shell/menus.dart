part of '../waydir_shell.dart';

mixin _WaydirMenuMixin
    on
        State<WaydirShell>,
        _WaydirStateBase,
        _WaydirActionsMixin,
        _WaydirTerminalMixin {
  final Map<String, String> _pluginCustomOperationIds = {};

  void _handleBackgroundContextMenu(Offset position) {
    final store = _active;
    if (store.isTrashView) {
      showContextMenu(
        context: context,
        position: position,
        items: [
          ContextMenuItem(
            icon: WaydirIconsRegular.arrowClockwise,
            label: t.toolbar.refresh,
            action: 'refresh',
          ),
          ContextMenuItem(
            icon: WaydirIconsRegular.selectionAll,
            label: t.menu.selectAll,
            action: 'select_all',
          ),
        ],
        onSelect: _handleBackgroundMenuAction,
      );
      return;
    }
    final canPaste = store.canPaste.value;
    final items = <ContextMenuItem>[
      ContextMenuItem(
        icon: WaydirIconsRegular.clipboard,
        label: t.menu.paste,
        action: 'paste',
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.terminal,
        label: t.menu.openInTerminal,
        action: 'open_in_terminal',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.folderPlus,
        label: t.toolbar.newFolder,
        action: 'new_folder',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.arrowClockwise,
        label: t.toolbar.refresh,
        action: 'refresh',
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.selectionAll,
        label: t.menu.selectAll,
        action: 'select_all',
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.info,
        label: t.menu.properties,
        action: 'properties',
      ),
    ];
    if (!canPaste) items.removeAt(0);

    final pluginItems = _backgroundPluginItems();
    if (pluginItems.isNotEmpty) {
      items.add(ContextMenuItem.divider);
      items.addAll(pluginItems);
    }

    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: _handleBackgroundMenuAction,
    );
  }

  void _handleBackgroundMenuAction(String action) {
    final store = _active;
    if (action.startsWith('plugin:')) {
      _runPluginAction(action, background: true);
      return;
    }
    switch (action) {
      case 'paste':
        store.paste();
      case 'new_folder':
        store.startCreate();
      case 'refresh':
        store.refresh();
      case 'select_all':
        store.selectAll();
      case 'open_in_terminal':
        _openInTerminal(store.currentPath.value);
      case 'properties':
        _openFolderProperties(store.currentPath.value);
    }
  }

  List<ContextMenuItem> _backgroundPluginItems() {
    final contributions = PluginStore.instance.backgroundContributions();
    return [
      for (final c in contributions)
        ContextMenuItem(
          icon: pluginGlyph(c.icon),
          label: c.title,
          action: c.fullActionId,
          iconPath: _pluginIconPath(c),
        ),
    ];
  }

  Future<void> _handleContextMenu(
    FileSelectionEvent event,
    Offset position,
  ) async {
    final store = _active;
    store.onContextMenu(event);

    final entries = store.selectedEntries;
    final count = entries.length;
    final isSingleFolder =
        count == 1 && entries.first.type == FileItemType.folder;
    final isSingleFile = count == 1 && entries.first.type == FileItemType.file;
    final canVerifyChecksum =
        isSingleFile &&
        !PlatformPaths.isRemoteUri(entries.first.realPath) &&
        !FileSystemService.isInsideArchive(entries.first.realPath);
    final isRecursive = store.searchActive.value && store.searchRecursive.value;

    final openWithItems = isSingleFile
        ? _openWithItemsFor(entries.first)
        : const <ContextMenuItem>[];

    final archiveEntries = entries
        .where(
          (e) =>
              e.type == FileItemType.file &&
              ArchivePath.isArchiveName(e.name) &&
              !FileSystemService.isInsideArchive(e.path),
        )
        .toList();
    final canExtract =
        archiveEntries.isNotEmpty && archiveEntries.length == count;
    final canCompress =
        entries.isNotEmpty &&
        entries.every((e) => !FileSystemService.isInsideArchive(e.path));
    final compressBase = count == 1
        ? (entries.first.type == FileItemType.folder
              ? entries.first.name
              : p.basenameWithoutExtension(entries.first.name))
        : _sanitizeArchiveBase(
            p.basename(store.currentPath.value),
            store.currentPath.value,
          );
    final compressItem = canCompress
        ? ContextMenuItem(
            icon: WaydirIconsRegular.fileZip,
            label: t.menu.compress,
            action: 'compress',
            children: [
              ContextMenuItem(
                icon: WaydirIconsRegular.fileZip,
                label: t.menu.compressTo(name: '$compressBase.zip'),
                action: 'compress_zip',
              ),
              ContextMenuItem(
                icon: WaydirIconsRegular.fileZip,
                label: t.menu.compressTo(name: '$compressBase.tar.gz'),
                action: 'compress_targz',
              ),
              ContextMenuItem.divider,
              ContextMenuItem(
                icon: WaydirIconsRegular.slidersHorizontal,
                label: t.menu.compressOptions,
                action: 'compress_options',
              ),
            ],
          )
        : null;

    final extractItem = canExtract
        ? ContextMenuItem(
            icon: WaydirIconsRegular.archive,
            label: t.menu.extract,
            action: 'extract',
            children: [
              ContextMenuItem(
                icon: WaydirIconsRegular.arrowLineDown,
                label: t.menu.extractHere,
                action: 'extract_here',
              ),
              ContextMenuItem(
                icon: WaydirIconsRegular.folderPlus,
                label: count == 1
                    ? t.menu.extractToFolder(
                        name: FileSystemService.archiveBaseName(
                          archiveEntries.first.name,
                        ),
                      )
                    : t.menu.extractEach,
                action: 'extract_to_folder',
              ),
            ],
          )
        : null;

    if (store.isTrashView) {
      final binItems = <ContextMenuItem>[
        if (store.canRestoreFromTrash)
          ContextMenuItem(
            icon: WaydirIconsRegular.arrowCounterClockwise,
            label: count == 1
                ? t.menu.restore
                : t.menu.restoreItems(count: count),
            action: 'restore',
          ),
        ContextMenuItem(
          icon: WaydirIconsRegular.trash,
          label: count == 1
              ? t.menu.deletePermanently
              : t.menu.deletePermanentlyItems(count: count),
          action: 'delete_permanent_bin',
          danger: true,
        ),
        ContextMenuItem.divider,
        ContextMenuItem(
          icon: WaydirIconsRegular.info,
          label: t.menu.properties,
          action: 'properties',
        ),
      ];
      showContextMenu(
        context: context,
        position: position,
        items: binItems,
        onSelect: _handleMenuAction,
      );
      return;
    }

    final items = <ContextMenuItem>[
      if (count == 1 && !isSingleFile)
        ContextMenuItem(
          icon: WaydirIconsRegular.folderOpen,
          label: t.menu.open,
          action: 'open',
        ),
      ...openWithItems,
      ?extractItem,
      ?compressItem,
      if (isRecursive && count == 1)
        ContextMenuItem(
          icon: WaydirIconsRegular.arrowSquareOut,
          label: t.menu.openLocation,
          action: 'open_location',
        ),
      if (isSingleFolder) ...[
        ContextMenuItem(
          icon: WaydirIconsRegular.arrowSquareOut,
          label: t.menu.openInNewTab,
          action: 'open_in_new_tab',
        ),
        ContextMenuItem(
          icon: WaydirIconsRegular.terminal,
          label: t.menu.openInTerminal,
          action: 'open_in_terminal',
        ),
      ],
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.copy,
        label: t.menu.copy,
        action: 'copy',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.scissors,
        label: t.menu.cut,
        action: 'cut',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.clipboard,
        label: t.menu.paste,
        action: 'paste',
      ),
      if (count == 1) ContextMenuItem.divider,
      if (count == 1)
        ContextMenuItem(
          icon: WaydirIconsRegular.copy,
          label: t.menu.copyPath,
          action: 'copy_path',
        ),
      if (canVerifyChecksum)
        ContextMenuItem(
          icon: WaydirIconsRegular.checkSquare,
          label: t.menu.verifyChecksum,
          action: 'verify_checksum',
        ),
      ContextMenuItem.divider,
      if (count == 1)
        ContextMenuItem(
          icon: WaydirIconsRegular.pencilSimple,
          label: t.menu.rename,
          action: 'rename',
          shortcut: 'F2',
        ),
      if (count >= 2)
        ContextMenuItem(
          icon: WaydirIconsRegular.pencilSimple,
          label: t.menu.multiRename,
          action: 'multi_rename',
        ),
      ContextMenuItem(
        icon: WaydirIconsRegular.trashSimple,
        label: count == 1
            ? t.menu.moveToTrash
            : t.menu.moveToTrashItems(count: count),
        action: 'trash',
      ),
      ContextMenuItem(
        icon: WaydirIconsRegular.trash,
        label: count == 1
            ? t.menu.deletePermanently
            : t.menu.deletePermanentlyItems(count: count),
        action: 'delete_permanent',
        danger: true,
      ),
      ContextMenuItem.divider,
      ContextMenuItem(
        icon: WaydirIconsRegular.info,
        label: t.menu.properties,
        action: 'properties',
      ),
    ];

    final pluginItems = _pluginContextItems(entries);
    if (pluginItems.isNotEmpty) {
      items.add(ContextMenuItem.divider);
      items.addAll(pluginItems);
    }

    showContextMenu(
      context: context,
      position: position,
      items: items,
      onSelect: _handleMenuAction,
    );
  }

  List<ContextMenuItem> _pluginContextItems(List<FileEntry> entries) {
    final contributions = PluginStore.instance.contextContributionsFor(entries);
    ContextMenuItem leaf(PluginContribution c) => ContextMenuItem(
      icon: pluginGlyph(c.icon),
      label: c.title,
      action: c.fullActionId,
      iconPath: _pluginIconPath(c),
    );

    final items = <ContextMenuItem>[];
    final groupIndex = <String, int>{};
    for (final c in contributions) {
      final group = c.group;
      if (group == null) {
        items.add(leaf(c));
        continue;
      }
      final at = groupIndex[group];
      if (at == null) {
        groupIndex[group] = items.length;
        items.add(
          ContextMenuItem(
            icon: pluginGlyph(c.icon),
            label: group,
            action: 'plugin-group:$group',
            iconPath: _pluginIconPath(c),
            children: [leaf(c)],
          ),
        );
      } else {
        final parent = items[at];
        items[at] = ContextMenuItem(
          icon: parent.icon,
          label: parent.label,
          action: parent.action,
          iconPath: parent.iconPath,
          children: [...parent.children!, leaf(c)],
        );
      }
    }
    return items;
  }

  String? _pluginIconPath(PluginContribution c) => c.iconPath;

  /// Guards against a plugin that re-emits `dialog` on every pass, which would
  /// otherwise loop modals forever.
  static const int _maxPluginDialogDepth = 8;

  Future<void> _runPluginAction(
    String fullActionId, {
    bool background = false,
    Map<String, dynamic>? form,
    int depth = 0,
  }) async {
    final contribution = PluginStore.instance.contributionByFullId(
      fullActionId,
    );
    if (contribution == null) return;
    try {
      final store = _active;
      final paths = background
          ? const <String>[]
          : store.selectedEntries.map((e) => e.realPath).toList();
      final effects = await PluginStore.instance.invoke(
        contribution,
        paths: paths,
        dir: store.currentPath.value,
        form: form,
      );
      if (!mounted) return;
      await _applyPluginEffects(
        effects,
        contribution,
        background: background,
        depth: depth,
      );
    } catch (e, st) {
      log.error(
        'plugins',
        'action ${contribution.fullActionId} failed: $e\n$st',
      );
      if (mounted) _notifyPluginError(contribution, '$e');
    }
  }

  void _notifyPluginError(PluginContribution c, String? message) {
    final clean = _cleanPluginError(message);
    _notificationStore.add(
      AppNotification(
        title: c.manifest.name,
        message: clean.isNotEmpty ? clean : t.preferences.plugins.actionFailed,
        type: NotificationType.autoDismiss,
        icon: WaydirIconsRegular.gearSix,
        accentColor: AppColors.danger,
      ),
    );
  }

  String _cleanPluginError(String? raw) {
    if (raw == null) return '';
    final firstLine = raw.split('\n').first.trim();
    return firstLine.replaceFirst(RegExp(r'^runtime error:\s*'), '');
  }

  Future<void> _applyPluginEffects(
    List<PluginEffect> effects,
    PluginContribution contribution, {
    required bool background,
    int depth = 0,
  }) async {
    for (final effect in effects) {
      switch (effect.type) {
        case 'toast':
          if (effect.message != null) {
            showToast(context: context, message: effect.message!);
          }
        case 'notify':
          _notifyFromPlugin(contribution, effect);
        case 'refresh':
          _active.refresh();
        case 'log':
          log.warn('plugins', effect.message ?? '');
        case 'error':
          _notifyPluginError(contribution, effect.message);
        case 'set_setting':
          final key = effect.data['key'] as String?;
          if (key != null) {
            await PluginSettingsStore.instance.set(
              contribution.pluginId,
              key,
              effect.data['value'],
            );
          }
        case 'operation':
          await _runPluginOperation(effect);
        case 'custom_operation_start':
          _startPluginCustomOperation(contribution, effect);
        case 'custom_operation_update':
          _updatePluginCustomOperation(contribution, effect);
        case 'custom_operation_finish':
          _finishPluginCustomOperation(contribution, effect);
        case 'task':
          _runPluginTask(contribution, effect);
        case 'dialog':
          await _showPluginDialog(
            contribution,
            effect,
            background: background,
            depth: depth,
          );
      }
      if (!mounted) return;
    }
  }

  void _notifyFromPlugin(PluginContribution c, PluginEffect effect) {
    final level = (effect.data['level'] as String? ?? 'info').toLowerCase();
    final persistent = effect.data['persistent'] == true;
    Color? accent;
    switch (level) {
      case 'success':
        accent = AppColors.success;
      case 'warn':
      case 'warning':
        accent = AppColors.warning;
      case 'error':
        accent = AppColors.danger;
    }
    _notificationStore.add(
      AppNotification(
        title: effect.data['title'] as String? ?? c.manifest.name,
        message: effect.message ?? '',
        type: persistent
            ? NotificationType.persistent
            : NotificationType.autoDismiss,
        icon: WaydirIconsRegular.gearSix,
        accentColor: accent,
      ),
    );
  }

  Future<void> _runPluginOperation(PluginEffect effect) async {
    final op = effect.data['op'] as String?;
    final src = effect.data['src'] as String?;
    final dst = effect.data['dst'] as String?;
    if (src == null) return;
    switch (op) {
      case 'copy':
        if (dst != null) _operationStore.enqueueCopy([src], dst);
      case 'move':
        if (dst != null) _operationStore.enqueueMove([src], dst);
      case 'delete':
        if (await _confirmPluginDelete(src, permanent: true)) {
          _operationStore.enqueueDelete([src]);
        }
      case 'trash':
        if (await _confirmPluginDelete(src, permanent: false)) {
          _operationStore.enqueueTrash([src]);
        }
    }
  }

  String? _pluginCustomOperationKey(
    PluginContribution contribution,
    PluginEffect effect,
  ) {
    final id = effect.data['id'] as String?;
    if (id == null || id.trim().isEmpty) return null;
    return '${contribution.pluginId}:${id.trim()}';
  }

  void _startPluginCustomOperation(
    PluginContribution contribution,
    PluginEffect effect,
  ) {
    final key = _pluginCustomOperationKey(contribution, effect);
    if (key == null) return;

    final existing = _pluginCustomOperationIds.remove(key);
    if (existing != null) {
      _operationStore.finishPluginTask(
        existing,
        success: false,
        cancelled: true,
      );
    }

    final title = effect.data['title'] as String? ?? contribution.manifest.name;
    final task = _operationStore.beginPluginTask(
      title: title,
      totalBytes: (effect.data['total_bytes'] as num?)?.toInt(),
      totalFiles: (effect.data['total_files'] as num?)?.toInt() ?? 0,
    );
    _pluginCustomOperationIds[key] = task.id;
  }

  void _updatePluginCustomOperation(
    PluginContribution contribution,
    PluginEffect effect,
  ) {
    final key = _pluginCustomOperationKey(contribution, effect);
    if (key == null) return;
    final taskId = _pluginCustomOperationIds[key];
    if (taskId == null) return;

    final progress = (effect.data['progress'] as num?)?.toDouble();
    _operationStore.updatePluginTask(
      taskId,
      progress: progress,
      processedBytes: (effect.data['processed_bytes'] as num?)?.toInt(),
      totalBytes: (effect.data['total_bytes'] as num?)?.toInt(),
      bytesPerSecond: (effect.data['bytes_per_second'] as num?)?.toDouble(),
      processedFiles: (effect.data['processed_files'] as num?)?.toInt(),
      totalFiles: (effect.data['total_files'] as num?)?.toInt(),
      currentFile: effect.data['message'] as String?,
    );
  }

  void _finishPluginCustomOperation(
    PluginContribution contribution,
    PluginEffect effect,
  ) {
    final key = _pluginCustomOperationKey(contribution, effect);
    if (key == null) return;
    final taskId = _pluginCustomOperationIds.remove(key);
    if (taskId == null) return;

    _operationStore.finishPluginTask(
      taskId,
      success: effect.data['success'] != false,
      cancelled: effect.data['cancelled'] == true,
      error: effect.data['error'] as String? ?? '',
    );
  }

  /// Plugins can request destructive ops; gate them behind the same confirm
  /// the UI uses. Permanent deletes always confirm; trash respects the
  /// confirmDelete setting.
  Future<bool> _confirmPluginDelete(
    String path, {
    required bool permanent,
  }) async {
    if (!permanent && !SettingsStore.instance.confirmDelete.value) return true;
    final name = p.basename(path);
    final actionLabel = permanent ? t.dialog.delete : t.dialog.moveToTrash;
    final result = await showCustomDialog<String>(
      context: context,
      title: permanent
          ? t.dialog.confirmDeleteTitle
          : t.dialog.confirmTrashTitle,
      icon: permanent
          ? WaydirIconsRegular.trash
          : WaydirIconsRegular.trashSimple,
      iconColor: AppColors.danger,
      body: Text(
        permanent
            ? t.dialog.confirmDeleteSingle(name: name)
            : t.dialog.confirmTrashSingle(name: name),
        style: context.txt.body.copyWith(height: 1.4),
      ),
      actions: [
        DialogAction(label: t.dialog.cancel, color: AppColors.fgMuted),
        DialogAction(label: actionLabel, color: AppColors.danger),
      ],
    );
    return result == actionLabel;
  }

  Future<void> _runPluginTask(PluginContribution c, PluginEffect effect) async {
    if (!c.allowExec) return;
    final cmd = effect.data['cmd'] as String?;
    if (cmd == null) return;
    final title = effect.data['title'] as String? ?? c.manifest.name;
    final args = (effect.data['args'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final cwd = effect.data['cwd'] as String?;
    if (effect.data['operation'] == true) {
      await _runPluginOperationTask(effect, cmd, args, cwd, title);
      return;
    }
    final notifId =
        'plugin-task-${c.pluginId}-${DateTime.now().microsecondsSinceEpoch}';
    _notificationStore.add(
      AppNotification(
        id: notifId,
        title: title,
        message: t.preferences.plugins.taskRunning,
        type: NotificationType.persistent,
        icon: WaydirIconsRegular.gearSix,
      ),
    );
    try {
      final process = await Process.start(
        cmd,
        args,
        workingDirectory: cwd != null && cwd.isNotEmpty ? cwd : null,
      );
      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        _pluginTaskTimeoutFor(effect),
        onTimeout: () {
          timedOut = true;
          process.kill();
          return -1;
        },
      );
      if (!mounted) return;
      final ok = !timedOut && exitCode == 0;
      _notificationStore.add(
        AppNotification(
          id: notifId,
          title: title,
          message: timedOut
              ? t.preferences.plugins.taskTimeout
              : ok
              ? t.preferences.plugins.taskDone
              : t.preferences.plugins.taskFailed(code: exitCode),
          type: NotificationType.autoDismiss,
          icon: WaydirIconsRegular.gearSix,
          accentColor: ok ? AppColors.success : AppColors.danger,
        ),
      );
      if (ok) _active.refresh();
    } catch (e) {
      if (!mounted) return;
      _notificationStore.add(
        AppNotification(
          id: notifId,
          title: title,
          message: t.preferences.plugins.taskFailedError(error: '$e'),
          type: NotificationType.autoDismiss,
          icon: WaydirIconsRegular.gearSix,
          accentColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _runPluginOperationTask(
    PluginEffect effect,
    String cmd,
    List<String> args,
    String? cwd,
    String title,
  ) async {
    final progress = (effect.data['progress'] as Map?)?.cast<String, dynamic>();
    final usePty = effect.data['pty'] == true;

    Process? process;
    final task = _operationStore.beginPluginTask(
      title: title,
      totalBytes: (progress?['total_bytes'] as num?)?.toInt(),
      totalFiles: (progress?['total_files'] as num?)?.toInt() ?? 0,
      onCancel: () => process?.kill(),
    );

    final stderrTail = StringBuffer();
    void rememberError(String chunk) {
      if (chunk.trim().isEmpty) return;
      stderrTail.write(chunk);
      final text = stderrTail.toString();
      if (text.length > 4096) {
        stderrTail.clear();
        stderrTail.write(text.substring(text.length - 4096));
      }
    }

    void handleOutput(String chunk, {required bool stderr}) {
      if (stderr) rememberError(chunk);
      _updatePluginOperationProgress(task.id, chunk, progress);
    }

    try {
      var runCmd = cmd;
      var runArgs = args;
      if (usePty && PlatformPaths.isLinux) {
        runCmd = 'script';
        runArgs = [
          '-q',
          '-e',
          '-c',
          _pluginShellCommand([cmd, ...args]),
          '/dev/null',
        ];
      }

      try {
        process = await Process.start(
          runCmd,
          runArgs,
          workingDirectory: cwd != null && cwd.isNotEmpty ? cwd : null,
        );
      } on ProcessException catch (e) {
        if (!usePty || runCmd == cmd) rethrow;
        log.warn(
          'plugins',
          'pty wrapper unavailable, running plugin task without pty: $e',
        );
        process = await Process.start(
          cmd,
          args,
          workingDirectory: cwd != null && cwd.isNotEmpty ? cwd : null,
        );
      }
      final stdoutSub = process.stdout
          .transform(utf8.decoder)
          .listen((chunk) => handleOutput(chunk, stderr: false));
      final stderrSub = process.stderr
          .transform(utf8.decoder)
          .listen((chunk) => handleOutput(chunk, stderr: true));

      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        _pluginTaskTimeoutFor(effect),
        onTimeout: () {
          timedOut = true;
          process?.kill();
          return -1;
        },
      );
      await stdoutSub.cancel();
      await stderrSub.cancel();

      if (!mounted) return;
      final current = _pluginTaskById(task.id);
      final cancelled = timedOut || current?.status == TaskStatus.cancelling;
      final ok = !cancelled && exitCode == 0;
      _operationStore.finishPluginTask(
        task.id,
        success: ok,
        cancelled: cancelled,
        error: ok ? '' : _pluginTaskError(exitCode, timedOut, stderrTail),
      );
      if (ok) _active.refresh();
    } catch (e) {
      if (!mounted) return;
      _operationStore.finishPluginTask(
        task.id,
        success: false,
        cancelled: false,
        error: e.toString(),
      );
    }
  }

  FileTask? _pluginTaskById(String id) {
    for (final task in _operationStore.tasks.value) {
      if (task.id == id) return task;
    }
    return null;
  }

  String _pluginTaskError(
    int exitCode,
    bool timedOut,
    StringBuffer stderrTail,
  ) {
    if (timedOut) return t.preferences.plugins.taskTimeout;
    final detail = stderrTail.toString().trim();
    if (detail.isNotEmpty) return detail;
    return t.preferences.plugins.taskFailed(code: exitCode);
  }

  void _updatePluginOperationProgress(
    String taskId,
    String chunk,
    Map<String, dynamic>? progress,
  ) {
    if (progress == null) return;
    for (final raw in chunk.split(RegExp(r'[\r\n]+'))) {
      final line = raw
          .replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '')
          .trim();
      if (line.isEmpty) continue;

      final pct = _regexDouble(line, progress['percent_regex'] as String?);
      if (pct != null) {
        _operationStore.updatePluginTask(taskId, progress: pct / 100);
      }

      final message = _regexString(line, progress['message_regex'] as String?);
      final bytes = _regexByteAmount(line, progress['bytes_regex'] as String?);
      final speed = _regexByteAmount(line, progress['speed_regex'] as String?);
      if (message != null || bytes != null || speed != null) {
        _operationStore.updatePluginTask(
          taskId,
          processedBytes: bytes,
          bytesPerSecond: speed?.toDouble(),
          currentFile: message,
        );
      }
    }
  }

  String? _regexString(String line, String? pattern) {
    if (pattern == null || pattern.isEmpty) return null;
    final match = RegExp(pattern).firstMatch(line);
    if (match == null) return null;
    return (match.groupCount >= 1 ? match.group(1) : match.group(0))?.trim();
  }

  double? _regexDouble(String line, String? pattern) {
    final value = _regexString(line, pattern);
    if (value == null) return null;
    return double.tryParse(value);
  }

  int? _regexByteAmount(String line, String? pattern) {
    final value = _regexString(line, pattern);
    if (value == null) return null;
    return _parsePluginByteAmount(value);
  }

  int? _parsePluginByteAmount(String raw) {
    final match = RegExp(
      r'([0-9]+(?:\.[0-9]+)?)\s*([KMGTPE]?)(i?)B',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) return null;
    final value = double.tryParse(match.group(1) ?? '');
    if (value == null) return null;
    final prefix = (match.group(2) ?? '').toUpperCase();
    final binary = (match.group(3) ?? '').isNotEmpty;
    final base = binary ? 1024.0 : 1000.0;
    final power = switch (prefix) {
      'K' => 1,
      'M' => 2,
      'G' => 3,
      'T' => 4,
      'P' => 5,
      'E' => 6,
      _ => 0,
    };
    var multiplier = 1.0;
    for (var i = 0; i < power; i++) {
      multiplier *= base;
    }
    return (value * multiplier).round();
  }

  String _pluginShellCommand(List<String> argv) =>
      argv.map(_pluginShellQuote).join(' ');

  String _pluginShellQuote(String value) {
    if (value.isEmpty) return "''";
    if (RegExp(r'^[A-Za-z0-9_@%+=:,./-]+$').hasMatch(value)) return value;
    return "'${value.replaceAll("'", "'\"'\"'")}'";
  }

  /// Default time budget for a plugin `run_task`, used when the task does not
  /// declare its own `timeout` (seconds). Clamped to [_pluginTaskTimeoutMax].
  static const Duration _pluginTaskTimeout = Duration(minutes: 10);
  static const Duration _pluginTaskTimeoutMax = Duration(hours: 6);

  Duration _pluginTaskTimeoutFor(PluginEffect effect) {
    final secs = (effect.data['timeout'] as num?)?.toInt();
    if (secs == null || secs <= 0) return _pluginTaskTimeout;
    final requested = Duration(seconds: secs);
    return requested > _pluginTaskTimeoutMax
        ? _pluginTaskTimeoutMax
        : requested;
  }

  Future<void> _showPluginDialog(
    PluginContribution c,
    PluginEffect effect, {
    required bool background,
    required int depth,
  }) async {
    if (depth >= _maxPluginDialogDepth) {
      log.warn('plugins', 'dialog depth limit reached for ${c.fullActionId}');
      return;
    }
    final spec = (effect.data['dialog'] as Map?)?.cast<String, dynamic>();
    if (spec == null) return;
    final fields = PluginFormField.listFromJson(spec['fields']);
    final result = await showPluginFormDialog(
      context: context,
      title: spec['title'] as String? ?? c.title,
      fields: fields,
    );
    if (result == null || !mounted) return;
    await _runPluginAction(
      c.fullActionId,
      background: background,
      form: result,
      depth: depth + 1,
    );
  }

  ContextMenuItem get _openItem => ContextMenuItem(
    icon: WaydirIconsRegular.folderOpen,
    label: t.menu.open,
    action: 'open',
  );

  ContextMenuItem get _chooserItem => ContextMenuItem(
    icon: WaydirIconsRegular.dotsThreeOutline,
    label: t.menu.openWithChoose,
    action: 'open_with_choose',
  );

  /// Returns the "Open / Open with" items synchronously so the context menu
  /// can be shown immediately. On Linux the preferred-app lookup spawns
  /// `xdg-mime` subprocesses, so it is resolved off the menu path and cached
  /// per extension; the first menu for a given type shows the generic items,
  /// subsequent ones show the resolved default app.
  List<ContextMenuItem> _openWithItemsFor(FileEntry entry) {
    _openWithEntry = entry;

    if (PlatformPaths.isWindows) {
      return [
        _openItem,
        ContextMenuItem(
          icon: WaydirIconsRegular.dotsThreeOutline,
          label: t.menu.openWithChoose,
          action: 'open_with_system',
        ),
      ];
    }

    if (PlatformPaths.isMacOS) return [_openItem, _chooserItem];

    final key = entry.extension.toLowerCase();
    final cached = _openWithCache[key];
    if (cached != null) return cached;
    _warmOpenWith(entry.realPath, key);
    return [_openItem, _chooserItem];
  }

  Future<void> _warmOpenWith(String path, String key) async {
    if (!_openWithWarming.add(key)) return;
    try {
      final options = await OpenService.optionsFor(path);
      final preferred = options.defaultApp;
      _openWithCache[key] = preferred == null
          ? [_openItem, _chooserItem]
          : [
              ContextMenuItem(
                icon: WaydirIconsRegular.appWindow,
                label: t.menu.openWithApp(app: preferred.name),
                action: 'open',
                iconPath: preferred.iconPath,
              ),
              _chooserItem,
            ];
    } catch (_) {
      // Leave uncached so a later right-click can retry.
    } finally {
      _openWithWarming.remove(key);
    }
  }

  void _handleMenuAction(String action) {
    final store = _active;
    switch (action) {
      case 'open':
        store.openSelected();
      case 'open_with_choose':
        final entry = _openWithEntry;
        if (entry != null) {
          showOpenWithDialog(
            context: context,
            entry: entry,
          ).then((_) => _restoreFocus());
        }
      case 'open_with_system':
        final entry = _openWithEntry;
        if (entry != null) {
          OpenService.systemOpenWithDialog(entry.realPath);
        }
      case 'copy':
        store.copySelected();
        final count = store.selectedPaths.value.length;
        if (count > 0) {
          showToast(
            context: context,
            message: t.toast.copiedItems(count: count),
          );
        }
      case 'cut':
        store.cutSelected();
        final count = store.selectedPaths.value.length;
        if (count > 0) {
          showToast(
            context: context,
            message: t.toast.cutItems(count: count),
          );
        }
      case 'compress_zip':
        _quickCompress(ArchiveFormat.zip);
      case 'compress_targz':
        _quickCompress(ArchiveFormat.tarGz);
      case 'compress_options':
        _compressWithOptions();
      case 'extract_here':
        _extractSelected(toOwnFolder: false);
      case 'extract_to_folder':
        _extractSelected(toOwnFolder: true);
      case 'paste':
        store.paste();
      case 'copy_path':
        store.copySelectedPaths();
      case 'verify_checksum':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.file) {
          showChecksumDialog(
            context: context,
            entry: entries.first,
          ).then((_) => _restoreFocus());
        }
      case 'rename':
        store.startRename();
      case 'multi_rename':
        _multiRename(store);
      case 'trash':
        _confirmAndDelete();
      case 'delete_permanent':
        _confirmAndDelete(forcePermanent: true);
      case 'restore':
        store.restoreSelectedFromTrash();
      case 'delete_permanent_bin':
        store.deletePermanentlySelectedFromTrash();
      case 'open_in_terminal':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.folder) {
          _openInTerminal(entries.first.path);
        }
      case 'open_location':
        final entries = store.selectedEntries;
        if (entries.length == 1) {
          store.revealInFolder(entries.first.path);
        }
      case 'open_in_new_tab':
        final entries = store.selectedEntries;
        if (entries.length == 1 && entries.first.type == FileItemType.folder) {
          _shell.activePane.value!.tabs.addTab(entries.first.path);
        }
      case 'properties':
        _openPropertiesFromMenu(store);
      default:
        if (action.startsWith('plugin:')) _runPluginAction(action);
    }
  }

  Widget _buildViewMenu() {
    return SignalBuilder(
      builder: (_) {
        if (!_shell.ready.value) return const SizedBox.shrink();
        final store = _active;
        final selectedCount = store.selectedCount.value;
        final hasVisibleFiles = store.visibleFiles.value.isNotEmpty;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TitleMenuButton(
              label: t.menu.view,
              items: [
                ContextMenuItem(
                  icon: WaydirIconsRegular.columns,
                  label: t.menu.dualPaneMode,
                  action: 'toggle_dual',
                  isToggle: true,
                  toggleSignal: _shell.isDual,
                ),
                ContextMenuItem.divider,
                ContextMenuItem(
                  icon: WaydirIconsRegular.eye,
                  label: t.menu.showHidden,
                  action: 'toggle_hidden',
                  isToggle: true,
                  toggleSignal: SettingsStore.instance.showHiddenDefault,
                ),
              ],
              onSelect: (action) {
                switch (action) {
                  case 'toggle_dual':
                    _shell.toggleDual();
                  case 'toggle_hidden':
                    _toggleShowHiddenGlobal();
                }
              },
            ),
            TitleMenuButton(
              label: t.keybindings.categories.selection,
              items: [
                ContextMenuItem(
                  icon: WaydirIconsRegular.selectionAll,
                  label: t.menu.selectAll,
                  action: 'select_all',
                  shortcut: AppShortcuts.getById('select_all').displayKeys,
                  enabled: hasVisibleFiles,
                ),
                ContextMenuItem(
                  icon: WaydirIconsRegular.selectionAll,
                  label: t.menu.selectByPattern,
                  action: 'select_pattern',
                  shortcut: AppShortcuts.getById('select_pattern').displayKeys,
                  enabled: hasVisibleFiles,
                ),
                ContextMenuItem(
                  icon: WaydirIconsRegular.selectionAll,
                  label: t.menu.deselectAll,
                  action: 'deselect_all',
                  shortcut: AppShortcuts.getById('deselect_all').displayKeys,
                  enabled: selectedCount > 0,
                ),
                ContextMenuItem.divider,
                ContextMenuItem(
                  icon: WaydirIconsRegular.floppyDisk,
                  label: t.menu.saveSelection,
                  action: 'save_selection',
                  shortcut: AppShortcuts.getById('save_selection').displayKeys,
                  enabled: selectedCount > 0,
                ),
                ContextMenuItem(
                  icon: WaydirIconsRegular.fileTxt,
                  label: t.menu.loadSelection,
                  action: 'load_selection',
                  shortcut: AppShortcuts.getById('load_selection').displayKeys,
                  enabled: hasVisibleFiles,
                ),
              ],
              onSelect: _handleSelectionMenuAction,
            ),
            ?_buildPluginMenu(),
          ],
        );
      },
    );
  }

  Widget? _buildPluginMenu() {
    final contributions = PluginStore.instance.menubarContributions();
    if (contributions.isEmpty) return null;
    return TitleMenuButton(
      label: t.preferences.plugins.title,
      items: [
        for (final c in contributions)
          ContextMenuItem(
            icon: pluginGlyph(c.icon),
            label: c.title,
            action: c.fullActionId,
            iconPath: _pluginIconPath(c),
            shortcut: c.shortcut,
          ),
      ],
      onSelect: (action) {
        if (action.startsWith('plugin:')) _runPluginAction(action);
      },
    );
  }

  void _handleSelectionMenuAction(String action) {
    final store = _active;
    switch (action) {
      case 'select_all':
        store.selectAll();
      case 'select_pattern':
        _openSelectPattern();
      case 'deselect_all':
        store.deselectAll();
      case 'save_selection':
        _saveSelectionToFile();
      case 'load_selection':
        _loadSelectionFromFile();
    }
  }

  List<PlatformMenu> _platformViewMenus() {
    final store = _shell.ready.value ? _active : null;
    final selectedCount = store?.selectedCount.value ?? 0;
    final hasVisibleFiles = store?.visibleFiles.value.isNotEmpty ?? false;
    return [
      PlatformMenu(
        label: t.menu.view,
        menus: [
          PlatformMenuItem(
            label: t.menu.dualPaneMode,
            onSelected: () {
              if (_shell.ready.value) _shell.toggleDual();
            },
          ),
          PlatformMenuItem(
            label: t.menu.showHidden,
            onSelected: _toggleShowHiddenGlobal,
          ),
        ],
      ),
      PlatformMenu(
        label: t.keybindings.categories.selection,
        menus: [
          PlatformMenuItem(
            label: t.menu.selectAll,
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyA,
              meta: true,
            ),
            onSelected: hasVisibleFiles ? () => _active.selectAll() : null,
          ),
          PlatformMenuItem(
            label: t.menu.selectByPattern,
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyS,
              meta: true,
            ),
            onSelected: hasVisibleFiles ? _openSelectPattern : null,
          ),
          PlatformMenuItem(
            label: t.menu.deselectAll,
            shortcut: const SingleActivator(LogicalKeyboardKey.escape),
            onSelected: selectedCount > 0 ? () => _active.deselectAll() : null,
          ),
          PlatformMenuItemGroup(
            members: [
              PlatformMenuItem(
                label: t.menu.saveSelection,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyS,
                  meta: true,
                  shift: true,
                ),
                onSelected: selectedCount > 0 ? _saveSelectionToFile : null,
              ),
              PlatformMenuItem(
                label: t.menu.loadSelection,
                shortcut: const SingleActivator(
                  LogicalKeyboardKey.keyL,
                  meta: true,
                  shift: true,
                ),
                onSelected: hasVisibleFiles ? _loadSelectionFromFile : null,
              ),
            ],
          ),
        ],
      ),
      ?_platformPluginMenu(),
    ];
  }

  PlatformMenu? _platformPluginMenu() {
    final contributions = PluginStore.instance.menubarContributions();
    if (contributions.isEmpty) return null;
    return PlatformMenu(
      label: t.preferences.plugins.title,
      menus: [
        for (final c in contributions)
          PlatformMenuItem(
            label: c.title,
            onSelected: () => _runPluginAction(c.fullActionId),
          ),
      ],
    );
  }
}
