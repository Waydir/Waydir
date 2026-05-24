import 'package:flutter/material.dart';
import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';

class CredentialsResult {
  final String username;
  final String password;

  const CredentialsResult({required this.username, required this.password});
}

Future<String?> showPasswordDialog(BuildContext context, {String? title}) {
  return showGeneralDialog<String>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    barrierLabel: t.password.dismiss,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: _PasswordDialog(
            title: title ?? t.password.authenticationRequired,
          ),
        ),
      );
    },
  );
}

Future<CredentialsResult?> showSmbCredentialsDialog(
  BuildContext context, {
  String? title,
  String? username,
}) {
  return showGeneralDialog<CredentialsResult>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: true,
    barrierLabel: t.password.dismiss,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: _SmbCredentialsDialog(
            title: title ?? t.password.authenticationRequired,
            username: username,
          ),
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
                t.password.mountPrompt,
                style: context.txt.body.copyWith(color: AppColors.fgMuted),
              ),
              const SizedBox(height: 16),
              _PasswordInput(
                controller: _controller,
                obscure: _obscure,
                autofocus: true,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onSubmitted: _submit,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DialogButton(
                    label: t.dialog.cancel,
                    color: AppColors.fgMuted,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  DialogButton(
                    label: t.password.unlock,
                    color: AppColors.accent,
                    onTap: _submit,
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

class _SmbCredentialsDialog extends StatefulWidget {
  final String title;
  final String? username;

  const _SmbCredentialsDialog({required this.title, this.username});

  @override
  State<_SmbCredentialsDialog> createState() => _SmbCredentialsDialogState();
}

class _SmbCredentialsDialogState extends State<_SmbCredentialsDialog> {
  late final TextEditingController _username;
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.username ?? '');
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) return;
    Navigator.of(
      context,
    ).pop(CredentialsResult(username: username, password: password));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
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
                t.password.smbPrompt,
                style: context.txt.body.copyWith(color: AppColors.fgMuted),
              ),
              const SizedBox(height: 16),
              Text(t.password.username, style: context.txt.fieldLabel),
              const SizedBox(height: 6),
              _TextInput(
                controller: _username,
                autofocus: _username.text.isEmpty,
                onSubmitted: _submit,
              ),
              const SizedBox(height: 12),
              Text(t.password.password, style: context.txt.fieldLabel),
              const SizedBox(height: 6),
              _PasswordInput(
                controller: _password,
                obscure: _obscure,
                autofocus: _username.text.isNotEmpty,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onSubmitted: _submit,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DialogButton(
                    label: t.dialog.cancel,
                    color: AppColors.fgMuted,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  DialogButton(
                    label: t.password.unlock,
                    color: AppColors.accent,
                    onTap: _submit,
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

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;
  final VoidCallback onSubmitted;

  const _TextInput({
    required this.controller,
    required this.autofocus,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        style: context.txt.body,
        cursorColor: AppColors.accent,
        decoration: _inputDecoration(context),
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final bool autofocus;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmitted;

  const _PasswordInput({
    required this.controller,
    required this.obscure,
    required this.autofocus,
    required this.onToggleObscure,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        autofocus: autofocus,
        style: context.txt.body,
        cursorColor: AppColors.accent,
        decoration: _inputDecoration(context).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              size: 16,
              color: AppColors.fgMuted,
            ),
            onPressed: onToggleObscure,
            splashRadius: 16,
          ),
        ),
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }
}

InputDecoration _inputDecoration(BuildContext context) {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.bgInput,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.accent),
    ),
  );
}
