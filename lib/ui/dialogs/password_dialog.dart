import 'package:flutter/material.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';

Future<String?> showPasswordDialog(
  BuildContext context, {
  String title = 'Authentication Required',
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: _PasswordDialog(title: title),
        ),
      );
    },
  );
}

class _PasswordDialog extends StatefulWidget {
  final String title;

  const _PasswordDialog({required this.title});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.isNotEmpty) {
      Navigator.of(context).pop(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: context.txt.dialogTitle),
              const SizedBox(height: 8),
              Text(
                'Enter your password to mount this drive.',
                style: context.txt.body.copyWith(color: AppColors.fgMuted),
              ),
              const SizedBox(height: 16),
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.bgInput,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        obscureText: _obscure,
                        autofocus: true,
                        style: context.txt.body,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        size: 16,
                        color: AppColors.fgMuted,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.fgMuted,
                      textStyle: context.txt.body,
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.fgAccent,
                      textStyle: context.txt.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Unlock'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
