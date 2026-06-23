import 'package:flutter/widgets.dart';

/// A single entry in the command palette. Commands wrap the same handlers the
/// keyboard dispatch invokes, so the palette never duplicates action logic.
class AppCommand {
  /// Stable identifier, shared with [ShortcutDef] ids where one exists. Used to
  /// resolve the current key binding and to key usage history (frecency).
  final String id;
  final String label;

  /// Light secondary text shown under the label (usually the command's
  /// category) to give the entry context.
  final String? description;
  final IconData icon;

  /// Whether the command can run in the current context. Disabled commands are
  /// still shown (greyed out) for discoverability.
  final bool enabled;

  /// Optional reason shown when [enabled] is false.
  final String? disabledReason;

  /// When true the entry is only shown once the user types a query (e.g. files
  /// in the current directory), keeping the empty-query list focused.
  final bool queryOnly;

  /// Tiebreak for ranking matched results: higher sorts first, so lower-priority
  /// entries (e.g. files found in nested folders) fall below equally-matching
  /// entries from the current folder.
  final int sortPriority;

  final VoidCallback run;

  const AppCommand({
    required this.id,
    required this.label,
    required this.icon,
    required this.run,
    this.description,
    this.enabled = true,
    this.disabledReason,
    this.queryOnly = false,
    this.sortPriority = 0,
  });
}
