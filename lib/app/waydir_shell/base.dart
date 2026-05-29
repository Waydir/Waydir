part of '../waydir_shell.dart';

const _cursorRepeatInterval = Duration(milliseconds: 70);
const _typeAheadResetAfter = Duration(milliseconds: 1500);

mixin _WaydirStateBase on State<WaydirShell> {
  final _notificationStore = NotificationStore();
  late final _operationStore = OperationStore(
    notificationStore: _notificationStore,
  );
  late final _shell = ShellStore(
    operationStore: _operationStore,
    notificationStore: _notificationStore,
  );
  final _focusNode = FocusNode();
  final _effectDisposers = <void Function()>[];

  /// The file the "Open With…" chooser was opened on.
  FileEntry? _openWithEntry;

  /// Resolved "Open with default app" menu items, keyed by lowercased file
  /// extension, plus the set of extensions currently being resolved.
  final Map<String, List<ContextMenuItem>> _openWithCache = {};
  final Set<String> _openWithWarming = {};
  final _renameErrorDisposers = <String, void Function()>{};
  DateTime? _lastCursorRepeatAt;
  DateTime? _terminalInteractionAt;

  String? _typeAheadLetter;
  int _typeAheadIndex = -1;
  DateTime? _typeAheadLastAt;

  NavigationStore get _active => _shell.activeStore.value!;

  String? _lastNotifiedUpdateVersion;
  void _installUpdateNotification() {
    _effectDisposers.add(
      effect(() {
        final available = UpdateStore.instance.updateAvailable.value;
        final release = UpdateStore.instance.latestRelease.value;
        if (!available || release == null) return;
        if (_lastNotifiedUpdateVersion == release.version) return;
        _lastNotifiedUpdateVersion = release.version;
        _notificationStore.add(
          AppNotification(
            id: 'update-${release.version}',
            title: t.update.available,
            message: t.update.versionLabel(version: release.version),
            type: NotificationType.persistent,
            icon: WaydirIconsRegular.arrowUp,
            accentColor: AppColors.warning,
            actions: [
              NotificationAction(
                label: t.update.btnUpdate,
                color: AppColors.warning,
                onTap: () {
                  if (mounted) showUpdateDialog(context);
                },
              ),
            ],
          ),
        );
      }),
    );
  }

  void _installRenameErrorEffects() {
    final currentIds = <String>{};
    for (final pane in _shell.panes.value) {
      for (final tab in pane.tabs.tabs.value) {
        currentIds.add(tab.id);
        if (!_renameErrorDisposers.containsKey(tab.id)) {
          final store = tab.store;
          _renameErrorDisposers[tab.id] = effect(() {
            final error = store.renameError.value;
            if (error != null) {
              store.renameError.value = null;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  showToast(
                    context: context,
                    message: error,
                    duration: const Duration(seconds: 3),
                  );
                }
              });
            }
          });
        }
      }
    }
    final existingIds = _renameErrorDisposers.keys.toSet();
    for (final id in existingIds.difference(currentIds)) {
      _renameErrorDisposers.remove(id)?.call();
    }
  }

  bool _isEditableFocused() {
    final primaryFocus = WidgetsBinding.instance.focusManager.primaryFocus;
    if (primaryFocus == null || primaryFocus == _focusNode) return false;
    final ctx = primaryFocus.context;
    if (ctx == null) return true;
    if (ctx.widget is EditableText) return true;
    bool found = false;
    ctx.visitAncestorElements((el) {
      if (el.widget is EditableText) {
        found = true;
        return false;
      }
      return true;
    });
    return found;
  }

  bool _isModalRouteOnTop() {
    final navigator = Navigator.maybeOf(context);
    return navigator != null && navigator.canPop();
  }

  bool _isTerminalFocused() {
    for (final tab in _shell.terminals.value) {
      if (tab.focusNode.hasFocus) return true;
    }
    return false;
  }

  void _restoreFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isEditableFocused()) return;
      final ti = _terminalInteractionAt;
      if (ti != null &&
          DateTime.now().difference(ti) < const Duration(milliseconds: 300)) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  void _focusFiles() {
    _focusNode.requestFocus();
  }

  VoidCallback _activatePane(int index) {
    return () {
      _shell.setActivePane(index);
      _restoreFocus();
    };
  }

  void _openInNewTab(String path) {
    _shell.activePane.value!.tabs.addTab(path);
  }

  void _setShowHiddenGlobal(bool value) {
    SettingsStore.instance.showHiddenDefault.value = value;
    if (!_shell.ready.value) return;
    for (final store in _shell.allStores) {
      store.showHidden.value = value;
    }
  }

  void _toggleShowHiddenGlobal() {
    if (!_shell.ready.value) return;
    _setShowHiddenGlobal(!SettingsStore.instance.showHiddenDefault.value);
  }
}
