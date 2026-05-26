import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/settings/settings_registry.dart';
import '../../../i18n/strings.g.dart';
import '../preferences_view.dart';

class GeneralPane extends StatelessWidget {
  const GeneralPane({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = SettingsRegistry.instance;
    final restoreSession = registry.byId('general.restoreSession');
    final defaultPath = registry.byId('general.defaultStartingPath');
    final confirmDelete = registry.byId('general.confirmDelete');
    final confirmCopy = registry.byId('general.confirmCopy');
    final confirmMove = registry.byId('general.confirmMove');
    final rememberFolderState = registry.byId('general.rememberFolderState');
    final rememberFolderSort = registry.byId('general.rememberFolderSort');
    final deleteKeyBehavior = registry.byId('general.deleteKeyBehavior');
    final terminal = registry.byId('general.terminal');
    final terminalCustom = registry.byId('general.terminalCustomCommand');

    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          title: t.preferences.general.startupSection,
          children: [
            RegistrySettingRow(setting: restoreSession),
            RegistrySettingRow(setting: defaultPath),
          ],
        ),
        SettingsSection(
          title: t.preferences.general.foldersSection,
          children: [
            RegistrySettingRow(setting: rememberFolderState),
            RegistrySettingRow(setting: rememberFolderSort),
          ],
        ),
        SettingsSection(
          title: t.preferences.general.fileOpsSection,
          children: [
            RegistrySettingRow(setting: deleteKeyBehavior),
            RegistrySettingRow(setting: confirmDelete),
            RegistrySettingRow(setting: confirmCopy),
            RegistrySettingRow(setting: confirmMove),
          ],
        ),
        SettingsSection(
          title: t.preferences.general.terminalSection,
          children: [
            RegistrySettingRow(setting: terminal),
            Watch((_) {
              if (terminal.value != 'custom') return const SizedBox.shrink();
              return RegistrySettingRow(setting: terminalCustom);
            }),
          ],
        ),
      ],
    );
  }
}
