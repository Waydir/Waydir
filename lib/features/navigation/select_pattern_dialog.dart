import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../ui/dialogs/dialog.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';

/// Prompts for a shell-style glob (e.g. `*.jpg`) and returns it, or null if
/// cancelled / left empty.
Future<String?> showSelectPatternDialog(BuildContext context) {
  final controller = TextEditingController(text: '*');
  controller.selection = TextSelection(
    baseOffset: 0,
    extentOffset: controller.text.length,
  );
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) {
      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: _SelectPatternDialog(
            controller: controller,
            onCancel: () => Navigator.of(ctx).pop(),
            onSubmit: (value) => Navigator.of(ctx).pop(value),
          ),
        ),
      );
    },
  );
}

class _SelectPatternDialog extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final ValueChanged<String> onSubmit;

  const _SelectPatternDialog({
    required this.controller,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<_SelectPatternDialog> createState() => _SelectPatternDialogState();
}

class _SelectPatternDialogState extends State<_SelectPatternDialog> {
  bool _valid = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
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
              PhosphorIcon(
                PhosphorIconsRegular.selectionAll,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Text('Select by pattern', style: context.txt.heading),
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
              hintText: '*.jpg',
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
          ),
          const SizedBox(height: 8),
          Text(
            'Wildcards: * (any), ? (one char)',
            style: context.txt.muted,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DialogButton(
                label: 'Cancel',
                color: AppColors.fgMuted,
                onTap: widget.onCancel,
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: _valid ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !_valid,
                  child: DialogButton(
                    label: 'Select',
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
