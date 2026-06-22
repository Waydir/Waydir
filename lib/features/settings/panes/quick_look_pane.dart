import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/settings/settings_registry.dart';
import '../../../core/terminal/system_fonts.dart';
import '../../../i18n/strings.g.dart';
import '../preferences_view.dart';

class QuickLookPane extends StatefulWidget {
  final PreferenceAnchors anchors;

  const QuickLookPane({super.key, required this.anchors});

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
    Widget row(AppSetting<dynamic> setting) {
      return RegistrySettingRow(setting: setting, anchors: widget.anchors);
    }

    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          anchorId: 'quickLook.font',
          anchors: widget.anchors,
          title: t.preferences.quickLook.fontSection,
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
          anchorId: 'quickLook.editor',
          anchors: widget.anchors,
          title: t.preferences.quickLook.editorSection,
          children: [
            row(showLineNumbers),
            SignalBuilder(
              builder: (_) {
                if (showLineNumbers.value != true) {
                  return const SizedBox.shrink();
                }

                return row(relativeLineNumbers);
              },
            ),
            row(wrapLines),
            row(vimMode),
            row(showStatistics),
          ],
        ),
      ],
    );
  }
}
