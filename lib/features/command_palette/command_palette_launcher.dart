import 'package:flutter/foundation.dart';

/// Lets decoupled UI (e.g. the title bar) open the command palette without a
/// reference to the shell state. The shell registers [open] while mounted.
class CommandPaletteLauncher {
  CommandPaletteLauncher._();
  static final instance = CommandPaletteLauncher._();

  VoidCallback? open;
}
