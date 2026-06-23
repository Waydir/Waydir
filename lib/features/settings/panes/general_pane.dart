import 'package:flutter/material.dart';

import '../../../core/settings/settings_registry.dart';
import '../../../i18n/strings.g.dart';
import '../preferences_view.dart';

class GeneralPane extends StatelessWidget {
  final PreferenceAnchors anchors;

  const GeneralPane({super.key, required this.anchors});

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
    Widget row(AppSetting<dynamic> setting) {
      return RegistrySettingRow(setting: setting, anchors: anchors);
    }

    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          anchorId: 'general.startup',
          anchors: anchors,
          title: t.preferences.general.startupSection,
          children: [row(restoreSession), row(defaultPath)],
        ),
        SettingsSection(
          anchorId: 'general.folders',
          anchors: anchors,
          title: t.preferences.general.foldersSection,
          children: [
            row(rememberFolderState),
            row(rememberFolderSort),
            row(typeAheadBuffer),
          ],
        ),
        SettingsSection(
          anchorId: 'general.fileOps',
          anchors: anchors,
          title: t.preferences.general.fileOpsSection,
          children: [
            row(deleteKeyBehavior),
            row(confirmDelete),
            row(confirmCopy),
            row(confirmMove),
            row(dragMovesByDefault),
          ],
        ),
      ],
    );
  }
}
