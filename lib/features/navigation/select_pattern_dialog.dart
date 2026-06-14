import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/widgets/app_modal.dart';
import '../../ui/widgets/app_text_field.dart';

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
    return AppModal(
      icon: WaydirIconsRegular.selectionAll,
      title: t.selectPattern.title,
      width: 360,
      padding: const EdgeInsets.all(16),
      onClose: widget.onCancel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: widget.controller,
            autofocus: true,
            hintText: t.selectPattern.hint,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          Text(t.selectPattern.help, style: context.txt.muted),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DialogButton(
                label: t.dialog.cancel,
                color: AppColors.fgMuted,
                onTap: widget.onCancel,
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: _valid ? 1.0 : 0.4,
                child: IgnorePointer(
                  ignoring: !_valid,
                  child: DialogButton(
                    label: t.selectPattern.select,
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
