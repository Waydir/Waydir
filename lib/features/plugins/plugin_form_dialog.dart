import 'package:flutter/material.dart';

import '../../ui/dialogs/dialog.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_dropdown.dart';
import '../../ui/widgets/app_modal.dart';
import '../../ui/widgets/app_text_field.dart';
import 'plugin_models.dart';

/// Renders a modal form from a plugin-declared field schema and returns the
/// collected values keyed by field id, or null if cancelled.
Future<Map<String, dynamic>?> showPluginFormDialog({
  required BuildContext context,
  required String title,
  required List<PluginFormField> fields,
  Map<String, dynamic> initialValues = const {},
  String submitLabel = 'OK',
  String cancelLabel = 'Cancel',
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => _PluginFormBody(
      title: title,
      fields: fields,
      initialValues: initialValues,
      submitLabel: submitLabel,
      cancelLabel: cancelLabel,
    ),
  );
}

class _PluginFormBody extends StatefulWidget {
  final String title;
  final List<PluginFormField> fields;
  final Map<String, dynamic> initialValues;
  final String submitLabel;
  final String cancelLabel;

  const _PluginFormBody({
    required this.title,
    required this.fields,
    required this.initialValues,
    required this.submitLabel,
    required this.cancelLabel,
  });

  @override
  State<_PluginFormBody> createState() => _PluginFormBodyState();
}

class _PluginFormBodyState extends State<_PluginFormBody> {
  final _values = <String, dynamic>{};
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      final initial = widget.initialValues.containsKey(f.id)
          ? widget.initialValues[f.id]
          : f.defaultValue;
      switch (f.type) {
        case 'checkbox':
        case 'toggle':
        case 'bool':
          _values[f.id] = initial == true;
        case 'select':
        case 'dropdown':
          _values[f.id] =
              (initial ?? (f.options.isNotEmpty ? f.options.first.value : ''))
                  .toString();
        case 'info':
        case 'label':
          break;
        default:
          final text = initial?.toString() ?? '';
          _controllers[f.id] = TextEditingController(text: text);
          _values[f.id] = text;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    for (final entry in _controllers.entries) {
      _values[entry.key] = entry.value.text;
    }
    Navigator.of(context).pop(Map<String, dynamic>.from(_values));
  }

  void _cancel() => Navigator.of(context).pop();

  Widget _fieldWidget(PluginFormField f) {
    switch (f.type) {
      case 'info':
      case 'label':
        return Text(f.label, style: context.txt.muted);
      case 'checkbox':
      case 'toggle':
      case 'bool':
        final value = _values[f.id] == true;

        return GestureDetector(
          onTap: () => setState(() => _values[f.id] = !value),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              value
                  ? Icon(
                      WaydirIconsRegular.checkSquare,
                      size: 16,
                      color: AppColors.accent,
                    )
                  : Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.fgMuted),
                      ),
                    ),
              const SizedBox(width: 8),
              Expanded(child: Text(f.label, style: context.txt.body)),
            ],
          ),
        );
      case 'select':
      case 'dropdown':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.label, style: context.txt.muted),
            const SizedBox(height: 4),
            AppDropdown<String>(
              value: _values[f.id] as String,
              items: [
                for (final o in f.options)
                  AppDropdownItem(value: o.value, label: o.label),
              ],
              onChanged: (v) => setState(() => _values[f.id] = v),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.label, style: context.txt.muted),
            const SizedBox(height: 4),
            AppTextField(
              controller: _controllers[f.id],
              hintText: f.hint,
              obscureText: f.type == 'password',
              onSubmitted: (_) => _submit(),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: WaydirIconsRegular.gearSix,
      title: widget.title,
      width: 380,
      padding: const EdgeInsets.all(16),
      onClose: _cancel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.fields.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _fieldWidget(widget.fields[i]),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DialogButton(
                label: widget.cancelLabel,
                color: AppColors.fgMuted,
                onTap: _cancel,
              ),
              const SizedBox(width: 8),
              DialogButton(
                label: widget.submitLabel,
                color: AppColors.accent,
                onTap: _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
