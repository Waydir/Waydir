import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/settings/settings_registry.dart';
import '../../../core/terminal/system_fonts.dart';
import '../../../i18n/strings.g.dart';
import '../preferences_view.dart';

class TerminalPane extends StatefulWidget {
  final PreferenceAnchors anchors;

  const TerminalPane({super.key, required this.anchors});

  @override
  State<TerminalPane> createState() => _TerminalPaneState();
}

class _TerminalPaneState extends State<TerminalPane> {
  @override
  void initState() {
    super.initState();
    SettingsRegistry.instance.refreshShellChoices();
    _loadFonts();
    _loadTerminals();
  }

  Future<void> _loadFonts() async {
    final families = await SystemFonts.monospaceFamilies();
    if (!mounted) return;
    setState(
      () => SettingsRegistry.instance.refreshTerminalFontChoices(families),
    );
  }

  Future<void> _loadTerminals() async {
    await SettingsRegistry.instance.refreshExternalTerminalChoices();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final registry = SettingsRegistry.instance;
    final useSystemFont = registry.byId('terminal.useSystemFont');
    final fontFamily = registry.byId('terminal.fontFamily');
    final fontSize = registry.byId('terminal.fontSize');
    final lineHeight = registry.byId('terminal.lineHeight');
    final copyPasteMode = registry.byId('terminal.copyPasteMode');
    final shell = registry.byId('terminal.shell');
    final external = registry.byId('terminal.external');
    final externalCustom = registry.byId('terminal.externalCustomCommand');
    Widget row(AppSetting<dynamic> setting) {
      return RegistrySettingRow(setting: setting, anchors: widget.anchors);
    }

    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          anchorId: 'terminal.appearance',
          anchors: widget.anchors,
          title: t.preferences.terminal.appearanceSection,
          children: [
            row(useSystemFont),
            SignalBuilder(
              builder: (_) {
                if (useSystemFont.value == true) return const SizedBox.shrink();

                return row(fontFamily);
              },
            ),
            row(fontSize),
            row(lineHeight),
          ],
        ),
        SettingsSection(
          anchorId: 'terminal.behavior',
          anchors: widget.anchors,
          title: t.preferences.terminal.behaviorSection,
          children: [row(copyPasteMode)],
        ),
        SettingsSection(
          anchorId: 'terminal.shell',
          anchors: widget.anchors,
          title: t.preferences.terminal.shellSection,
          children: [row(shell)],
        ),
        SettingsSection(
          anchorId: 'terminal.external',
          anchors: widget.anchors,
          title: t.preferences.terminal.externalSection,
          children: [
            row(external),
            SignalBuilder(
              builder: (_) {
                if (external.value != 'custom') return const SizedBox.shrink();

                return row(externalCustom);
              },
            ),
          ],
        ),
      ],
    );
  }
}
