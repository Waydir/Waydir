import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_theme.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_text_field.dart';
import 'dialog.dart';

Future<String?> showRenameDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  IconData icon = Icons.edit,
  String? confirmLabel,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: _RenameDialog(
            title: title,
            icon: icon,
            initialValue: initialValue,
            confirmLabel: confirmLabel ?? t.menu.rename,
          ),
        ),
      );
    },
  );
}

class _RenameDialog extends StatefulWidget {
  final String title;
  final IconData icon;
  final String initialValue;
  final String confirmLabel;

  const _RenameDialog({
    required this.title,
    required this.icon,
    required this.initialValue,
    required this.confirmLabel,
  });

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initialValue.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  void _cancel() => Navigator.of(context).pop();

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKey,
      child: AppModal(
        icon: widget.icon,
        title: widget.title,
        width: 360,
        padding: const EdgeInsets.all(16),
        onClose: _cancel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _controller,
              autofocus: true,
              height: 36,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DialogButton(
                  label: t.dialog.cancel,
                  color: AppColors.fgMuted,
                  onTap: _cancel,
                ),
                const SizedBox(width: 8),
                DialogButton(
                  label: widget.confirmLabel,
                  color: AppColors.accent,
                  onTap: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
