import 'package:flutter/widgets.dart';

import '../../core/terminal/pty_session.dart';

class TerminalTab {
  final int id;
  int originPane;
  final PtySession session;
  final FocusNode focusNode;
  final String cwd;
  String label;

  TerminalTab({
    required this.id,
    required this.originPane,
    required this.session,
    required this.focusNode,
    required this.cwd,
    required this.label,
  });

  void dispose() {
    session.dispose();
    focusNode.dispose();
  }
}
