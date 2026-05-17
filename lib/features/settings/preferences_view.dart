import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:signals/signals_flutter.dart';

import '../../core/settings/settings_registry.dart';
import '../../i18n/strings.g.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_dropdown.dart';
import 'panes/about_pane.dart';
import 'panes/appearance_pane.dart';
import 'panes/general_pane.dart';

Future<void> showPreferencesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) => const _PreferencesDialog(),
  );
}

enum Category { general, appearance, about }

class CategoryMeta {
  final Category id;
  final IconData icon;
  final String Function() label;

  const CategoryMeta(this.id, this.icon, this.label);
}

final categories = <CategoryMeta>[
  CategoryMeta(
    Category.general,
    PhosphorIconsRegular.slidersHorizontal,
    () => t.preferences.categories.general,
  ),
  CategoryMeta(
    Category.appearance,
    PhosphorIconsRegular.palette,
    () => t.preferences.categories.appearance,
  ),
  CategoryMeta(
    Category.about,
    PhosphorIconsRegular.info,
    () => t.preferences.categories.about,
  ),
];

class _PreferencesDialog extends StatefulWidget {
  const _PreferencesDialog();

  @override
  State<_PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<_PreferencesDialog> {
  Category _selected = Category.general;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: const EdgeInsets.only(top: 24),
          width: size.width * 0.92,
          height: size.height - 48,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                _Header(onClose: () => Navigator.of(context).pop()),
                Container(height: 1, color: AppColors.bgDivider),
                Expanded(
                  child: Row(
                    children: [
                      _CategorySidebar(
                        selected: _selected,
                        onSelect: (c) => setState(() => _selected = c),
                      ),
                      Container(width: 1, color: AppColors.bgDivider),
                      Expanded(child: _ContentPane(category: _selected)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  const _Header({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.bgSidebar),
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.gearSix,
            size: 16,
            color: AppColors.fgAccent,
          ),
          const SizedBox(width: 8),
          Text(t.preferences.title, style: context.txt.dialogTitle),
          const Spacer(),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? AppColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: PhosphorIcon(
            PhosphorIconsRegular.x,
            size: 14,
            color: _hovered ? AppColors.fg : AppColors.fgMuted,
          ),
        ),
      ),
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  final Category selected;
  final ValueChanged<Category> onSelect;

  const _CategorySidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: AppColors.bgSidebar,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: ListView(
        children: [
          for (final cat in categories)
            _CategoryItem(
              meta: cat,
              selected: cat.id == selected,
              onTap: () => onSelect(cat.id),
            ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatefulWidget {
  final CategoryMeta meta;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.bgSelectedMuted
        : (_hovered ? AppColors.bgHover : Colors.transparent);
    final fg = widget.selected ? AppColors.fg : AppColors.fgMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: widget.selected
                ? Border(
                    left: BorderSide(color: AppColors.accent, width: 2),
                  )
                : null,
          ),
          child: Row(
            children: [
              PhosphorIcon(widget.meta.icon, size: 14, color: fg),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.meta.label(),
                  style: context.txt.body.copyWith(
                    color: fg,
                    fontWeight: widget.selected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentPane extends StatelessWidget {
  final Category category;
  const _ContentPane({required this.category});

  @override
  Widget build(BuildContext context) {
    return switch (category) {
      Category.general => const GeneralPane(),
      Category.appearance => const AppearancePane(),
      Category.about => const AboutPane(),
    };
  }
}

// ── Shared widgets used by individual panes ────────────────────────────────

class SettingsPaneScaffold extends StatelessWidget {
  final List<Widget> children;

  const SettingsPaneScaffold({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      children: children,
    );
  }
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: context.txt.fieldLabel.copyWith(color: AppColors.fg),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Container(height: 1, color: AppColors.bgDivider),
                children[i],
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class SettingsRow extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget control;

  const SettingsRow({
    super.key,
    required this.label,
    this.hint,
    required this.control,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: context.txt.body),
                if (hint != null) ...[
                  const SizedBox(height: 3),
                  Text(hint!, style: context.txt.muted),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }
}

class RegistrySettingRow extends StatelessWidget {
  final AppSetting<dynamic> setting;

  const RegistrySettingRow({super.key, required this.setting});

  @override
  Widget build(BuildContext context) {
    return Watch((_) {
      final control = switch (setting) {
        ToggleSetting toggle => SettingsToggle(
          value: toggle.value,
          onChanged: (value) => toggle.value = value,
        ),
        ChoiceSetting choice => SizedBox(
          width: 240,
          child: AppDropdown<dynamic>(
            value: choice.value,
            items: [
              for (final option in choice.choices)
                AppDropdownItem<dynamic>(
                  value: option.value,
                  label: option.label(),
                  icon: option.icon,
                ),
            ],
            onChanged: (value) => choice.value = value,
          ),
        ),
        TextSetting text => SizedBox(
          width: 280,
          child: SettingsTextField(setting: text),
        ),
        _ => const SizedBox.shrink(),
      };

      return SettingsRow(
        label: setting.label(),
        hint: setting.hint?.call(),
        control: control,
      );
    });
  }
}

class SettingsTextField extends StatefulWidget {
  final TextSetting setting;

  const SettingsTextField({super.key, required this.setting});

  @override
  State<SettingsTextField> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  late final TextEditingController _controller;
  late final void Function() _disposeEffect;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.setting.value);
    _controller.addListener(() {
      if (widget.setting.value != _controller.text) {
        widget.setting.value = _controller.text;
      }
    });
    _disposeEffect = effect(() {
      final value = widget.setting.value;
      if (_controller.text == value) return;
      _controller.value = _controller.value.copyWith(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
        composing: TextRange.empty,
      );
    });
  }

  @override
  void dispose() {
    _disposeEffect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: context.txt.body,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        hintText: widget.setting.hintText,
        hintStyle: context.txt.body.copyWith(color: AppColors.fgMuted),
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
      cursorColor: AppColors.accent,
    );
  }
}

class SettingsToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SettingsToggle> createState() => _SettingsToggleState();
}

class _SettingsToggleState extends State<SettingsToggle> {
  @override
  Widget build(BuildContext context) {
    final on = widget.value;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onChanged(!on),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          width: 36,
          height: 20,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: on ? AppColors.accent : AppColors.bgInput,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: on ? AppColors.accent : AppColors.borderColor,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
