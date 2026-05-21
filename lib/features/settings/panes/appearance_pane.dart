import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../../core/open/open_service.dart';
import '../../../core/platform/app_dirs.dart';
import '../../../core/settings/settings_registry.dart';
import '../../../i18n/strings.g.dart';
import '../../../ui/dialogs/dialog.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/app_theme_definition.dart';
import '../../../ui/theme/app_theme_registry.dart';
import '../preferences_view.dart';

class AppearancePane extends StatefulWidget {
  const AppearancePane({super.key});

  @override
  State<AppearancePane> createState() => _AppearancePaneState();
}

class _AppearancePaneState extends State<AppearancePane> {
  late Future<_ThemeFilesState> _themeFiles = _loadThemeFiles();
  int _themeVersion = 0;

  @override
  void initState() {
    super.initState();
    _reloadRegistry();
  }

  Future<_ThemeFilesState> _loadThemeFiles() async {
    final themesPath = await AppDirs.themes();
    final dir = Directory(themesPath);
    await dir.create(recursive: true);
    final files = <_CustomThemeFile>[];
    await for (final entity in dir.list()) {
      if (entity is! File ||
          p.extension(entity.path).toLowerCase() != '.json') {
        continue;
      }
      files.add(await _readThemeFile(entity));
    }
    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return _ThemeFilesState(themesPath: themesPath, files: files);
  }

  Future<_CustomThemeFile> _readThemeFile(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Theme file must contain a JSON object');
      }
      final theme = AppThemeDefinition.fromJson(decoded);
      return _CustomThemeFile(path: file.path, theme: theme);
    } catch (error) {
      return _CustomThemeFile(path: file.path, error: '$error');
    }
  }

  Future<void> _addTheme(String themesPath) async {
    final name = await _showNameDialog();
    if (name == null || name.trim().isEmpty) return;
    final trimmed = name.trim();
    final id = trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final fileName = '$id.json';
    final path = p.join(themesPath, fileName);
    if (File(path).existsSync()) {
      var index = 2;
      late String uniquePath;
      do {
        uniquePath = p.join(themesPath, '${id}_$index.json');
        index++;
      } while (File(uniquePath).existsSync());
      final json = darkTheme.toJson()
        ..['id'] = '${id}_${index - 1}'
        ..['name'] = trimmed;
      await File(
        uniquePath,
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    } else {
      final json = darkTheme.toJson()
        ..['id'] = id
        ..['name'] = trimmed;
      await File(
        path,
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    }
    await _reloadRegistry();
  }

  Future<void> _reloadRegistry() async {
    await AppThemeRegistry.instance.load();
    SettingsRegistry.instance.refreshThemeChoices();
    setState(() {
      _themeVersion++;
      _themeFiles = _loadThemeFiles();
    });
  }

  Future<String?> _showNameDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: _ThemeNameDialog(
              controller: controller,
              onCancel: () => Navigator.of(ctx).pop(),
              onSubmit: (value) => Navigator.of(ctx).pop(value),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editTheme(String path) {
    return OpenService.openDefault(path);
  }

  Future<void> _deleteTheme(String path, String name) async {
    final result = await showCustomDialog<String>(
      context: context,
      title: t.preferences.appearance.deleteThemeTitle,
      icon: WaydirIconsRegular.warning,
      iconColor: AppColors.danger,
      body: Text(
        t.preferences.appearance.deleteThemeMessage(name: name),
        style: context.txt.body,
      ),
      actions: [
        DialogAction(
          label: t.preferences.appearance.addThemeCancel,
          color: AppColors.fgMuted,
        ),
        DialogAction(
          label: t.preferences.appearance.deleteTheme,
          color: AppColors.danger,
        ),
      ],
    );
    if (result != t.preferences.appearance.deleteTheme) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    await _reloadRegistry();
  }

  @override
  Widget build(BuildContext context) {
    final registry = SettingsRegistry.instance;
    return SettingsPaneScaffold(
      children: [
        SettingsSection(
          title: t.preferences.appearance.themeSection,
          children: [
            RegistrySettingRow(
              key: ValueKey(_themeVersion),
              setting: registry.byId('appearance.theme'),
            ),
            FutureBuilder<_ThemeFilesState>(
              future: _themeFiles,
              builder: (context, snapshot) {
                final state = snapshot.data;
                return _CustomThemesRow(
                  state: state,
                  onAdd: state == null
                      ? null
                      : () => _addTheme(state.themesPath),
                  onEdit: _editTheme,
                  onDelete: _deleteTheme,
                );
              },
            ),
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

class _ThemeNameDialog extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmit;

  const _ThemeNameDialog({
    required this.controller,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<_ThemeNameDialog> createState() => _ThemeNameDialogState();
}

class _ThemeNameDialogState extends State<_ThemeNameDialog> {
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    final valid = widget.controller.text.trim().isNotEmpty;
    if (valid != _valid) setState(() => _valid = valid);
  }

  void _submit() {
    if (!_valid) return;
    widget.onSubmit(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                WaydirIconsRegular.palette,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text(
                t.preferences.appearance.addThemeTitle,
                style: context.txt.heading,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            autofocus: true,
            style: context.txt.body,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              hintText: t.preferences.appearance.addThemeNameHint,
              hintStyle: context.txt.body.copyWith(color: AppColors.fgMuted),
              filled: true,
              fillColor: AppColors.bgInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppColors.accent),
              ),
            ),
            cursorColor: AppColors.accent,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DialogButton(
                label: t.preferences.appearance.addThemeCancel,
                color: AppColors.fgMuted,
                onTap: widget.onCancel,
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: _valid ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !_valid,
                  child: DialogButton(
                    label: t.preferences.appearance.addThemeCreate,
                    color: AppColors.accent,
                    onTap: _submit,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomThemesRow extends StatelessWidget {
  final _ThemeFilesState? state;
  final VoidCallback? onAdd;
  final ValueChanged<String> onEdit;
  final void Function(String path, String name) onDelete;

  const _CustomThemesRow({
    required this.state,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final state = this.state;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.preferences.appearance.customThemes,
                  style: context.txt.body,
                ),
                const SizedBox(height: 2),
                Text(
                  t.preferences.appearance.customThemesHint,
                  style: context.txt.muted,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  state?.themesPath ?? '',
                  style: context.txt.code.copyWith(color: AppColors.fgMuted),
                ),
                const SizedBox(height: 8),
                if (state == null)
                  Text(
                    t.preferences.appearance.loadingThemes,
                    style: context.txt.muted,
                  )
                else if (state.files.isEmpty)
                  Text(
                    t.preferences.appearance.noCustomThemes,
                    style: context.txt.muted,
                  )
                else
                  Column(
                    children: [
                      for (final file in state.files)
                        _ThemeFileRow(
                          file: file,
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (onAdd != null)
            SettingsActionButton(
              icon: WaydirIconsRegular.plus,
              label: t.preferences.appearance.addTheme,
              onTap: onAdd!,
            ),
        ],
      ),
    );
  }
}

class _ThemeFileRow extends StatelessWidget {
  final _CustomThemeFile file;
  final ValueChanged<String> onEdit;
  final void Function(String path, String name) onDelete;

  const _ThemeFileRow({
    required this.file,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = file.theme;
    final title = theme == null ? p.basename(file.path) : theme.name;
    final subtitle = theme == null
        ? '${t.preferences.appearance.invalidTheme}: ${file.error}'
        : '${theme.id} - ${p.basename(file.path)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Icon(
            theme == null
                ? WaydirIconsRegular.warning
                : WaydirIconsRegular.palette,
            size: 14,
            color: theme == null ? AppColors.warning : AppColors.fgMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.txt.body,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: context.txt.captionSmall.copyWith(
                    color: AppColors.fgMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SettingsActionButton(
            icon: WaydirIconsRegular.pencilSimple,
            label: t.preferences.appearance.editTheme,
            onTap: () => onEdit(file.path),
          ),
          const SizedBox(width: 4),
          SettingsActionButton(
            icon: WaydirIconsRegular.trash,
            label: t.preferences.appearance.deleteTheme,
            onTap: () => onDelete(file.path, title),
          ),
        ],
      ),
    );
  }
}

class _ThemeFilesState {
  final String themesPath;
  final List<_CustomThemeFile> files;

  const _ThemeFilesState({required this.themesPath, required this.files});
}

class _CustomThemeFile {
  final String path;
  final AppThemeDefinition? theme;
  final String? error;

  const _CustomThemeFile({required this.path, this.theme, this.error});
}
