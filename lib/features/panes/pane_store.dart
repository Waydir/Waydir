import 'package:flutter/widgets.dart';
import 'package:signals/signals.dart';

import '../../core/terminal/pty_session.dart';
import '../operations/operation_store.dart';
import '../tabs/tabs_store.dart';

class PaneStore {
  final TabsStore tabs;

  final terminalVisible = signal(false);
  final terminalHeight = signal(260.0);
  final terminalFocusNode = FocusNode(debugLabel: 'pane-terminal');

  PtySession? _terminal;

  PaneStore({required OperationStore operationStore, String? initialPath})
    : tabs = TabsStore(
        operationStore: operationStore,
        initialPath: initialPath,
      );

  PaneStore.fromPaths({
    required OperationStore operationStore,
    required List<String> paths,
    int activeTabIndex = 0,
  }) : tabs = TabsStore.fromPaths(
         operationStore: operationStore,
         paths: paths,
         activeTabIndex: activeTabIndex,
       );

  bool get hasTerminal => _terminal != null;

  PtySession? get activeTerminal => _terminal;

  PtySession? terminalSession(String cwd, {void Function()? onExit}) {
    final existing = _terminal;
    if (existing != null && !existing.hasExited) return existing;
    existing?.dispose();
    _terminal = null;
    final session = PtySession();
    final started = session.start(
      cwd: cwd,
      onExit: () {
        closeTerminal();
        onExit?.call();
      },
    );
    if (!started) {
      session.dispose();
      return null;
    }
    _terminal = session;
    return session;
  }

  void closeTerminal() {
    _terminal?.dispose();
    _terminal = null;
    terminalVisible.value = false;
  }

  void dispose() {
    _terminal?.dispose();
    _terminal = null;
    terminalFocusNode.dispose();
    tabs.dispose();
  }
}
