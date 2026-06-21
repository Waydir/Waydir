import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/settings/settings_store.dart';
import '../../i18n/strings.g.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../navigation/navigation_store.dart';
import '../panes/shell_store.dart';
import 'toolbar_button.dart';
import 'toolbar_item.dart';

class GlobalToolbar extends StatelessWidget {
  final ShellStore shell;
  final void Function(NavigationStore store) onMultiRename;
  final void Function(NavigationStore store) onCopyPath;
  final VoidCallback onSelectByPattern;
  final VoidCallback onToggleHidden;

  const GlobalToolbar({
    super.key,
    required this.shell,
    required this.onMultiRename,
    required this.onCopyPath,
    required this.onSelectByPattern,
    required this.onToggleHidden,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.bgToolbar,
        border: Border(bottom: BorderSide(color: AppColors.bgDivider)),
      ),
      child: SignalBuilder(
        builder: (context) {
          final active = shell.activeStore.value;
          final groups = _buildGroups(active);

          return Row(
            children: [
              const SizedBox(width: 4),
              for (var i = 0; i < groups.length; i++) ...[
                if (i > 0) const _ToolbarSeparator(),
                for (final item in groups[i])
                  ToolbarButton(
                    icon: item.icon,
                    tooltip: item.tooltip,
                    shortcutId: item.shortcutId,
                    enabled: item.isEnabled(),
                    active: item.isActive?.call() ?? false,
                    onTap: item.onTap,
                  ),
              ],
              const Spacer(),
            ],
          );
        },
      ),
    );
  }

  List<List<ToolbarItem>> _buildGroups(NavigationStore? active) {
    return [
      [
        ToolbarItem(
          id: 'multiRename',
          icon: WaydirIconsRegular.pencilSimple,
          tooltip: t.toolbar.multiRename,
          shortcutId: 'rename',
          isEnabled: () => (active?.selectedCount.value ?? 0) > 0,
          onTap: () {
            final store = active;
            if (store == null) return;
            onMultiRename(store);
          },
        ),
        ToolbarItem(
          id: 'copyPath',
          icon: WaydirIconsRegular.copy,
          tooltip: t.toolbar.copyPath,
          isEnabled: () => (active?.selectedCount.value ?? 0) > 0,
          onTap: () {
            final store = active;
            if (store == null) return;
            onCopyPath(store);
          },
        ),
        ToolbarItem(
          id: 'selectByPattern',
          icon: WaydirIconsRegular.selectionAll,
          tooltip: t.toolbar.selectByPattern,
          shortcutId: 'select_pattern',
          isEnabled: () => active != null,
          onTap: onSelectByPattern,
        ),
      ],
      [
        ToolbarItem(
          id: 'toggleHiddenFiles',
          icon: WaydirIconsRegular.eye,
          tooltip: t.toolbar.showHidden,
          shortcutId: 'toggle_hidden',
          isEnabled: () => active != null,
          isActive: () => SettingsStore.instance.showHiddenDefault.value,
          onTap: onToggleHidden,
        ),
      ],
    ];
  }
}

class _ToolbarSeparator extends StatelessWidget {
  const _ToolbarSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: AppColors.bgDivider,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
