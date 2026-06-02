import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/settings/settings_registry.dart';
import '../../../core/terminal/system_fonts.dart';
import '../../../i18n/strings.g.dart';
import '../preferences_view.dart';

class TerminalPane extends StatefulWidget {
  const TerminalPane({super.key});

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
  @override
  void initState() {
    super.initState();
    SettingsRegistry.instance.refreshShellChoices();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    final families = await SystemFonts.monospaceFamilies();
    if (!mounted) return;
    setState(
      () => SettingsRegistry.instance.refreshTerminalFontChoices(families),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registry = SettingsRegistry.instance;
    final useSystemFont = registry.byId('terminal.useSystemFont');
    final fontFamily = registry.byId('terminal.fontFamily');
    final fontSize = registry.byId('terminal.fontSize');
    final lineHeight = registry.byId('terminal.lineHeight');
    final shell = registry.byId('terminal.shell');
    final external = registry.byId('terminal.external');
    final externalCustom = registry.byId('terminal.externalCustomCommand');

    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          title: t.preferences.terminal.appearanceSection,
          children: [
            RegistrySettingRow(setting: useSystemFont),
            SignalBuilder(
              builder: (_) {
                if (useSystemFont.value == true) return const SizedBox.shrink();
                return RegistrySettingRow(setting: fontFamily);
              },
            ),
            RegistrySettingRow(setting: fontSize),
            RegistrySettingRow(setting: lineHeight),
          ],
        ),
        SettingsSection(
          title: t.preferences.terminal.shellSection,
          children: [RegistrySettingRow(setting: shell)],
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
