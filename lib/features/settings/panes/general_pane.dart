import 'package:flutter/material.dart';

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
    final typeAheadBuffer = registry.byId('general.typeAheadBuffer');
    final deleteKeyBehavior = registry.byId('general.deleteKeyBehavior');
    final dragMovesByDefault = registry.byId('general.dragMovesByDefault');

    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          anchorId: 'general.startup',
          title: t.preferences.general.startupSection,
          children: [
            RegistrySettingRow(setting: restoreSession),
            RegistrySettingRow(setting: defaultPath),
          ],
        ),
        SettingsSection(
          anchorId: 'general.folders',
          title: t.preferences.general.foldersSection,
          children: [
            RegistrySettingRow(setting: rememberFolderState),
            RegistrySettingRow(setting: rememberFolderSort),
            RegistrySettingRow(setting: typeAheadBuffer),
          ],
        ),
        SettingsSection(
          anchorId: 'general.fileOps',
          title: t.preferences.general.fileOpsSection,
          children: [
            RegistrySettingRow(setting: deleteKeyBehavior),
            RegistrySettingRow(setting: confirmDelete),
            RegistrySettingRow(setting: confirmCopy),
            RegistrySettingRow(setting: confirmMove),
            RegistrySettingRow(setting: dragMovesByDefault),
          ],
        ),
      ],
    );
  }
}
