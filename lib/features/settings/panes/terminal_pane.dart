import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/settings/settings_registry.dart';
import '../../../i18n/strings.g.dart';
import '../preferences_view.dart';

class TerminalPane extends StatelessWidget {
  const TerminalPane({super.key});

  @override
  Widget build(BuildContext context) {
    final registry = SettingsRegistry.instance;
    final external = registry.byId('terminal.external');
    final externalCustom = registry.byId('terminal.externalCustomCommand');
    final fontFamily = registry.byId('terminal.fontFamily');
    final fontSize = registry.byId('terminal.fontSize');
    final lineHeight = registry.byId('terminal.lineHeight');

    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          title: t.preferences.terminal.appearanceSection,
          children: [
            RegistrySettingRow(setting: fontFamily),
            RegistrySettingRow(setting: fontSize),
            RegistrySettingRow(setting: lineHeight),
          ],
        ),
        SettingsSection(
          title: t.preferences.terminal.externalSection,
          children: [
            RegistrySettingRow(setting: external),
            SignalBuilder(
              builder: (_) {
                if (external.value != 'custom') return const SizedBox.shrink();
                return RegistrySettingRow(setting: externalCustom);
              },
            ),
          ],
        ),
      ],
    );
  }
}
