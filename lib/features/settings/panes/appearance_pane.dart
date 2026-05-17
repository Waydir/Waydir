import 'package:flutter/material.dart';

import '../../../core/settings/settings_registry.dart';
import '../../../i18n/strings.g.dart';
import '../preferences_view.dart';

class AppearancePane extends StatelessWidget {
  const AppearancePane({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = SettingsRegistry.instance;
    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          title: t.preferences.appearance.themeSection,
          children: [
            RegistrySettingRow(setting: registry.byId('appearance.themeMode')),
          ],
        ),
        SettingsSection(
          title: t.preferences.appearance.filesSection,
          children: [
            RegistrySettingRow(
              setting: registry.byId('appearance.showHiddenDefault'),
            ),
            RegistrySettingRow(setting: registry.byId('appearance.rowDensity')),
            RegistrySettingRow(setting: registry.byId('appearance.dateFormat')),
            RegistrySettingRow(
              setting: registry.byId('appearance.recentDatesRelative'),
            ),
          ],
        ),
      ],
    );
  }
}
