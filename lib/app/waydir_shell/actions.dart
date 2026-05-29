part of '../waydir_shell.dart';

mixin _WaydirActionsMixin on State<WaydirShell>, _WaydirStateBase {
  Future<bool> _confirmTransfer(TaskType type, List<String> sources) async {
    final isCopy = type == TaskType.copy;
    final enabled = isCopy
        ? SettingsStore.instance.confirmCopy.value
        : SettingsStore.instance.confirmMove.value;
    if (!enabled) return true;
    if (sources.isEmpty) return true;
    if (!mounted) return true;

    final count = sources.length;
    final single = count == 1;
    final name = PlatformPaths.fileName(sources.first);
    final String title;
    final String message;
    final String actionLabel;
    if (isCopy) {
      title = t.dialog.confirmCopyTitle;
      message = single
          ? t.dialog.confirmCopySingle(name: name)
          : t.dialog.confirmCopyMultiple(count: count);
      actionLabel = t.dialog.copy;
    } else {
      title = t.dialog.confirmMoveTitle;
      message = single
          ? t.dialog.confirmMoveSingle(name: name)
          : t.dialog.confirmMoveMultiple(count: count);
      actionLabel = t.dialog.move;
    }

    final result = await showCustomDialog<String>(
      context: context,
      title: title,
      icon: isCopy
          ? WaydirIconsRegular.copy
          : WaydirIconsRegular.arrowsLeftRight,
      iconColor: AppColors.accent,
      body: Text(message, style: context.txt.body.copyWith(height: 1.4)),
      actions: [
        DialogAction(label: t.dialog.cancel, color: AppColors.fgMuted),
        DialogAction(label: actionLabel, color: AppColors.accent),
      ],
    );
    return result == actionLabel;
  }

  Future<void> _confirmAndDelete({bool forcePermanent = false}) async {
    final entries = _active.selectedEntries;
    if (entries.isEmpty) return;
    if (_active.isTrashView) {
      _active.deletePermanentlySelectedFromTrash();
      return;
    }
    final useTrash =
        !forcePermanent &&
        SettingsStore.instance.deleteKeyBehavior.value == 'trash';
    if (!SettingsStore.instance.confirmDelete.value) {
      _active.deleteSelected(toTrash: useTrash);
      return;
    }
    final count = entries.length;
    final single = count == 1;
    final String message;
    if (useTrash) {
      message = single
          ? t.dialog.confirmTrashSingle(name: entries.first.name)
          : t.dialog.confirmTrashMultiple(count: count);
    } else {
      message = single
          ? t.dialog.confirmDeleteSingle(name: entries.first.name)
          : t.dialog.confirmDeleteMultiple(count: count);
    }
    final actionLabel = useTrash ? t.dialog.moveToTrash : t.dialog.delete;
    final result = await showCustomDialog<String>(
      context: context,
      title: useTrash
          ? t.dialog.confirmTrashTitle
          : t.dialog.confirmDeleteTitle,
      icon: useTrash
          ? WaydirIconsRegular.trashSimple
          : WaydirIconsRegular.trash,
      iconColor: AppColors.danger,
      body: Text(message, style: context.txt.body.copyWith(height: 1.4)),
      actions: [
        DialogAction(label: t.dialog.cancel, color: AppColors.fgMuted),
        DialogAction(label: actionLabel, color: AppColors.danger),
      ],
    );
    if (result == actionLabel) {
      _active.deleteSelected(toTrash: useTrash);
    }
  }

  void _openPropertiesFromMenu(NavigationStore store) {
    final entries = store.selectedEntries;
    if (entries.isEmpty) {
      _openFolderProperties(store.currentPath.value);
      return;
    }
    if (entries.length == 1) {
      showQuickLook(
        context: context,
        store: store,
        explicitEntry: entries.first,
      ).then((_) => _restoreFocus());
      return;
    }
    showQuickLook(context: context, store: store).then((_) => _restoreFocus());
  }

  void _openFolderProperties(String path) {
    if (path.isEmpty) return;
    final dir = Directory(path);
    if (!dir.existsSync()) return;
    final stat = dir.statSync();
    final entry = FileEntry(
      name: PlatformPaths.fileName(path).isEmpty
          ? path
          : PlatformPaths.fileName(path),
      path: path,
      type: FileItemType.folder,
      size: 0,
      modified: stat.modified,
    );
    showQuickLook(
      context: context,
      store: _active,
      explicitEntry: entry,
    ).then((_) => _restoreFocus());
  }

  List<String> _compressSources() {
    return _active.selectedEntries
        .where((e) => !FileSystemService.isInsideArchive(e.realPath))
        .map((e) => e.realPath)
        .toList();
  }

  String _compressBaseName() {
    final store = _active;
    final entries = store.selectedEntries;
    if (entries.length == 1) {
      final e = entries.first;
      return e.type == FileItemType.folder
          ? e.name
          : p.basenameWithoutExtension(e.name);
    }
    return _sanitizeArchiveBase(
      p.basename(store.currentPath.value),
      store.currentPath.value,
    );
  }

  String _sanitizeArchiveBase(String name, String fullPath) {
    final cleaned = name.replaceAll(RegExp(r'[\\/:]'), '').trim();
    if (cleaned.isNotEmpty) return cleaned;
    final drive = RegExp(r'^([A-Za-z]):').firstMatch(fullPath);
    if (drive != null) return drive.group(1)!;
    return 'archive';
  }

  void _quickCompress(ArchiveFormat format) async {
    final store = _active;
    final sources = _compressSources();
    if (sources.isEmpty) return;
    final dir = await store.resolveForOperation(store.currentPath.value);
    if (dir == null) return;
    final dest = FileSystemService.uniquePath(
      p.join(dir, '${_compressBaseName()}.${format.extension}'),
    );
    store.operationStore.enqueueCompress(
      sources,
      dest,
      format: format.name,
      level: CompressionLevel.normal.name,
    );
  }

  Future<void> _compressWithOptions() async {
    final store = _active;
    final sources = _compressSources();
    if (sources.isEmpty) return;
    final dir = store.currentPath.value;
    final req = await showCompressDialog(
      context: context,
      defaultBaseName: _compressBaseName(),
      destinationDir: dir,
    );
    if (req == null) return;
    final physicalDir = await store.resolveForOperation(dir);
    if (physicalDir == null) return;
    final dest = FileSystemService.uniquePath(
      p.join(physicalDir, req.fileName),
    );
    store.operationStore.enqueueCompress(
      sources,
      dest,
      format: req.format.name,
      level: req.level.name,
    );
  }

  void _multiRename(NavigationStore store) async {
    final entries = store.selectedEntries;
    if (entries.length < 2) return;
    if (store.isTrashView) {
      showToast(context: context, message: t.toast.multiRenameTrashBlocked);
      return;
    }
    final result = await showMultiRenameDialog(
      context: context,
      entries: entries,
    );
    if (result == null || result.renames.isEmpty) {
      _restoreFocus();
      return;
    }
    final outcome = await store.multiRename(
      result.renames.map((r) => (path: r.oldPath, newName: r.newName)).toList(),
    );
    if (mounted) _showMultiRenameToast(outcome);
    _restoreFocus();
  }

  void _showMultiRenameToast(MultiRenameOutcome outcome) {
    if (outcome.blocked) {
      showToast(context: context, message: t.toast.multiRenameTrashBlocked);
      return;
    }
    if (outcome.failed == 0) {
      showToast(
        context: context,
        message: t.toast.multiRenameSuccess(count: outcome.succeeded),
      );
      return;
    }
    final parts = <String>[];
    if (outcome.collision > 0) {
      parts.add(t.toast.multiRenameCollisions(count: outcome.collision));
    }
    if (outcome.invalid > 0) {
      parts.add(t.toast.multiRenameInvalid(count: outcome.invalid));
    }
    if (outcome.other > 0) {
      parts.add(t.toast.multiRenameOtherErrors(count: outcome.other));
    }
    showToast(
      context: context,
      message: t.toast.multiRenamePartial(
        succeeded: outcome.succeeded,
        total: outcome.total,
        details: parts.join(', '),
      ),
    );
  }

  void _extractSelected({required bool toOwnFolder}) async {
    final store = _active;
    final base = await store.resolveForOperation(store.currentPath.value);
    if (base == null) return;
    final archives = store.selectedEntries
        .where(
          (e) =>
              e.type == FileItemType.file &&
              ArchivePath.isArchiveName(e.name) &&
              !FileSystemService.isInsideArchive(e.realPath),
        )
        .toList();
    if (archives.isEmpty) return;

    if (toOwnFolder) {
      for (final entry in archives) {
        final dest = FileSystemService.uniquePath(
          p.join(base, FileSystemService.archiveBaseName(entry.name)),
        );
        store.operationStore.enqueueExtract([entry.realPath], dest);
      }
    } else {
      store.operationStore.enqueueExtract(
        archives.map((e) => e.realPath).toList(),
        base,
      );
    }
  }

  void _openPreferences() {
    showPreferencesDialog(context).then((_) {
      if (!mounted) return;
      _restoreFocus();
    });
  }

  void _openQuickLook() {
    if (_isModalRouteOnTop()) return;
    showQuickLook(
      context: context,
      store: _active,
    ).then((_) => _restoreFocus());
  }

  void _openSelectPattern() {
    if (_isModalRouteOnTop()) return;
    final store = _active;
    showSelectPatternDialog(context).then((pattern) {
      if (!mounted) return;
      _restoreFocus();
      if (pattern == null) return;
      store.selectByPattern(pattern);
    });
  }

  Future<void> _saveSelectionToFile() async {
    if (_isModalRouteOnTop()) return;
    final store = _active;
    final names = store.selectedNamesForFile();
    if (names.isEmpty) return;
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: t.selectionFile.saveTitle,
        fileName: 'selection.txt',
        initialDirectory: store.currentPath.value,
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        lockParentWindow: true,
      );
      if (!mounted) return;
      _restoreFocus();
      if (path == null) return;
      await File(path).writeAsString('${names.join('\n')}\n');
      if (!mounted) return;
      showToast(
        context: context,
        message: t.toast.selectionSaved(count: names.length, path: path),
      );
    } catch (e) {
      if (!mounted) return;
      showToast(
        context: context,
        message: t.toast.selectionFileError(message: e.toString()),
      );
    }
  }

  Future<void> _loadSelectionFromFile() async {
    if (_isModalRouteOnTop()) return;
    final store = _active;
    if (store.visibleFiles.value.isEmpty) return;
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: t.selectionFile.loadTitle,
        initialDirectory: store.currentPath.value,
        type: FileType.custom,
        allowedExtensions: const ['txt'],
        lockParentWindow: true,
      );
      if (!mounted) return;
      _restoreFocus();
      final path = result?.files.single.path;
      if (path == null) return;
      final lines = await File(path).readAsLines();
      final count = store.selectNamesFromFile(lines);
      if (!mounted) return;
      showToast(
        context: context,
        message: count == 0
            ? t.toast.selectionLoadEmpty
            : t.toast.selectionLoaded(count: count),
      );
    } catch (e) {
      if (!mounted) return;
      showToast(
        context: context,
        message: t.toast.selectionFileError(message: e.toString()),
      );
    }
  }

  Future<void> _dualPaneTransfer(
    NavigationStore store, {
    required bool move,
  }) async {
    final activeIdx = _shell.activePaneIndex.value;
    final otherStore =
        _shell.panes.value[1 - activeIdx].tabs.activeTab.value.store;
    final sources = _dualPaneSources(store);
    if (sources.isEmpty) return;
    final dest = await otherStore.resolveForOperation(
      otherStore.currentPath.value,
    );
    if (dest == null) return;
    if (move) {
      _operationStore.enqueueMove(sources, dest);
    } else {
      _operationStore.enqueueCopy(sources, dest);
    }
  }

  List<String> _dualPaneSources(NavigationStore store) {
    final entries = store.selectedEntries;
    if (entries.isNotEmpty) {
      return entries.map((e) => e.realPath).toList();
    }
    final idx = store.cursorIndex.value;
    final files = store.visibleFiles.value;
    if (idx >= 0 && idx < files.length) return [files[idx].realPath];
    return const [];
  }
}
