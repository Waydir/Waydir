import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/settings/settings_registry.dart';
import '../../../core/terminal/system_fonts.dart';
import '../../../i18n/strings.g.dart';
import '../preferences_view.dart';

class QuickLookPane extends StatefulWidget {
  const QuickLookPane({super.key});

  @override
  State<QuickLookPane> createState() => _QuickLookPaneState();
}

class _QuickLookPaneState extends State<QuickLookPane> {
  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    final families = await SystemFonts.monospaceFamilies();
    if (!mounted) return;
    setState(
      () => SettingsRegistry.instance.refreshQuickLookFontChoices(families),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registry = SettingsRegistry.instance;
    final useSystemFont = registry.byId('quickLook.useSystemFont');
    final fontFamily = registry.byId('quickLook.fontFamily');
    final fontSize = registry.byId('quickLook.fontSize');
    final lineHeight = registry.byId('quickLook.lineHeight');
    final showLineNumbers = registry.byId('quickLook.showLineNumbers');
    final relativeLineNumbers = registry.byId('quickLook.relativeLineNumbers');
    final showStatistics = registry.byId('quickLook.showStatistics');
    final wrapLines = registry.byId('quickLook.wrapLines');
    final vimMode = registry.byId('quickLook.vimMode');

    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          title: t.preferences.quickLook.fontSection,
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
          title: t.preferences.quickLook.editorSection,
          children: [
            RegistrySettingRow(setting: showLineNumbers),
            SignalBuilder(
              builder: (_) {
                if (showLineNumbers.value != true) {
                  return const SizedBox.shrink();
                }

                return RegistrySettingRow(setting: relativeLineNumbers);
              },
            ),
            RegistrySettingRow(setting: wrapLines),
            RegistrySettingRow(setting: vimMode),
            RegistrySettingRow(setting: showStatistics),
          ],
        ),
      ],
    );
  }
}
