import 'package:flutter/material.dart';

class ToolbarItem {
  final String id;
  final IconData icon;
  final String tooltip;
  final String? shortcutId;
  final bool Function() isEnabled;
  final bool Function()? isActive;
  final VoidCallback onTap;

  const ToolbarItem({
    required this.id,
    required this.icon,
    required this.tooltip,
    this.shortcutId,
    required this.isEnabled,
    this.isActive,
    required this.onTap,
  });
}
