import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:signals/signals_flutter.dart';

import '../../../core/platform/app_dirs.dart';
import '../../../i18n/strings.g.dart';
import '../../../ui/overlays/toast.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../../panes/shell_store.dart';
import '../../plugins/plugin_form_dialog.dart';
import '../../plugins/plugin_models.dart';
import '../../plugins/plugin_settings_store.dart';
import '../../plugins/plugin_store.dart';
import '../preferences_view.dart';

class PluginsPane extends StatefulWidget {
  const PluginsPane({super.key});

  @override
  State<PluginsPane> createState() => _PluginsPaneState();
}

class _PluginsPaneState extends State<PluginsPane> {
  Future<void> _openFolder() async {
    final dir = await AppDirs.plugins();
    ShellStore.current?.openInNewTab(dir);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reload() async {
    await PluginStore.instance.loadAll();
    if (!mounted) return;
    showToast(
      context: context,
      message: t.preferences.plugins.reloaded(
        count: PluginStore.instance.plugins.value.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) {
        final plugins = PluginStore.instance.plugins.value;
        final disabled = PluginSettingsStore.instance.disabled.value;

        return SettingsPaneScaffold(
          children: [
            Text(t.preferences.plugins.title, style: context.txt.dialogTitle),
            const SizedBox(height: 4),
            Text(t.preferences.plugins.subtitle, style: context.txt.muted),
            const SizedBox(height: 16),
            Row(
              children: [
                _Btn(
                  icon: WaydirIconsRegular.folderOpen,
                  label: t.preferences.plugins.openFolder,
                  onTap: _openFolder,
                ),
                const SizedBox(width: 6),
                _Btn(
                  icon: WaydirIconsRegular.arrowClockwise,
                  label: t.preferences.plugins.reload,
                  onTap: _reload,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: AppColors.borderColor),
              ),
              child: plugins.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: 80,
                        child: Text(
                          t.preferences.plugins.empty,
                          style: context.txt.muted,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < plugins.length; i++) ...[
                          if (i > 0)
                            Container(height: 1, color: AppColors.bgDivider),
                          _PluginRow(
                            plugin: plugins[i],
                            userDisabled: disabled.contains(
                              plugins[i].manifest.id,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PluginRow extends StatelessWidget {
  final LoadedPlugin plugin;
  final bool userDisabled;

  const _PluginRow({required this.plugin, required this.userDisabled});

  Future<void> _configure(BuildContext context) async {
    final schema = plugin.settingsSchema;
    final current = PluginSettingsStore.instance.valuesFor(plugin.manifest.id);
    final result = await showPluginFormDialog(
      context: context,
      title: t.preferences.plugins.configureTitle(name: plugin.manifest.name),
      fields: schema,
      initialValues: current,
    );
    if (result != null) {
      await PluginSettingsStore.instance.setAll(plugin.manifest.id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = plugin.manifest;
    final hasError = plugin.error != null;
    final loadable = plugin.enabled && !hasError;
    final dim = hasError || !plugin.enabled || userDisabled;
    final canConfigure =
        loadable && !userDisabled && plugin.settingsSchema.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Opacity(
        opacity: dim ? 0.65 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.name,
                          style: context.txt.body.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('v${m.version}', style: context.txt.muted),
                      for (final perm in m.permissions) ...[
                        const SizedBox(width: 6),
                        _Pill(label: perm, color: AppColors.warning),
                      ],
                      if (hasError) ...[
                        const SizedBox(width: 6),
                        _Pill(label: 'error', color: AppColors.danger),
                      ] else if (!plugin.enabled || userDisabled) ...[
                        const SizedBox(width: 6),
                        _Pill(
                          label: t.preferences.plugins.disabled,
                          color: AppColors.fgMuted,
                        ),
                      ],
                    ],
                  ),
                  if (hasError || m.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      hasError
                          ? t.preferences.plugins.loadError(
                              message: plugin.error!,
                            )
                          : m.description,
                      style: context.txt.muted.copyWith(
                        color: hasError ? AppColors.danger : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    t.preferences.plugins.actionsCount(
                      count: plugin.contributions.length,
                    ),
                    style: context.txt.muted,
                  ),
                ],
              ),
            ),
            if (canConfigure) ...[
              const SizedBox(width: 8),
              _Btn(
                icon: WaydirIconsRegular.slidersHorizontal,
                label: t.preferences.plugins.configure,
                onTap: () => _configure(context),
              ),
            ],
            if (loadable) ...[
              const SizedBox(width: 8),
              _Btn(
                icon: userDisabled
                    ? WaydirIconsRegular.check
                    : WaydirIconsRegular.prohibit,
                label: userDisabled
                    ? t.preferences.plugins.enable
                    : t.preferences.plugins.disable,
                onTap: () async {
                  await PluginSettingsStore.instance.setDisabled(
                    m.id,
                    !userDisabled,
                  );
                  PluginStore.instance.applyEnablement();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: context.txt.muted.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Btn extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _Btn({required this.icon, required this.label, this.onTap});

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final fg = !enabled
        ? AppColors.fgMuted.withValues(alpha: 0.5)
        : (_hovered ? AppColors.fg : AppColors.fgMuted);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: enabled && _hovered ? AppColors.bgHover : AppColors.bgInput,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(widget.label, style: context.txt.body.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}
