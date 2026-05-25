import 'package:flutter/material.dart';

import '../../features/locations/location_resolver.dart';
import '../../i18n/strings.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'dialog.dart';

Future<SftpCredentials?> showSftpCredentialsDialog(
  BuildContext context, {
  String? title,
  String? username,
}) {
  return showGeneralDialog<SftpCredentials>(
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
          child: _SftpCredentialsDialog(
            title: title ?? t.password.authenticationRequired,
            initialUsername: username,
          ),
        ),
      );
    },
  );
}

enum _Method { password, key }

class _SftpCredentialsDialog extends StatefulWidget {
  final String title;
  final String? initialUsername;

  const _SftpCredentialsDialog({required this.title, this.initialUsername});

  @override
  State<_SftpCredentialsDialog> createState() => _SftpCredentialsDialogState();
}

class _SftpCredentialsDialogState extends State<_SftpCredentialsDialog> {
  late final TextEditingController _username;
  final _password = TextEditingController();
  final _keyPath = TextEditingController();
  final _passphrase = TextEditingController();
  _Method _method = _Method.password;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _username = TextEditingController(text: widget.initialUsername ?? '');
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _keyPath.dispose();
    _passphrase.dispose();
    super.dispose();
  }

  void _submit() {
    final user = _username.text.trim();
    if (user.isEmpty) return;
    SftpCredentials creds;
    if (_method == _Method.password) {
      if (_password.text.isEmpty) return;
      creds = SftpCredentials.password(
        username: user,
        password: _password.text,
      );
    } else {
      final path = _keyPath.text.trim();
      if (path.isEmpty) return;
      creds = SftpCredentials.key(
        username: user,
        privateKeyPath: path,
        passphrase: _passphrase.text.isEmpty ? null : _passphrase.text,
      );
    }
    Navigator.of(context).pop(creds);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
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
                'SSH/SFTP authentication',
                style: context.txt.body.copyWith(color: AppColors.fgMuted),
              ),
              const SizedBox(height: 16),
              Text(t.password.username, style: context.txt.fieldLabel),
              const SizedBox(height: 6),
              _SmallInput(
                controller: _username,
                autofocus: _username.text.isEmpty,
                onSubmitted: _submit,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ToggleChip(
                      label: 'Password',
                      selected: _method == _Method.password,
                      onTap: () => setState(() => _method = _Method.password),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ToggleChip(
                      label: 'Private key',
                      selected: _method == _Method.key,
                      onTap: () => setState(() => _method = _Method.key),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_method == _Method.password) ...[
                Text(t.password.password, style: context.txt.fieldLabel),
                const SizedBox(height: 6),
                _SmallInput(
                  controller: _password,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: AppColors.fgMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    splashRadius: 16,
                  ),
                  onSubmitted: _submit,
                  autofocus: _username.text.isNotEmpty,
                ),
              ] else ...[
                Text('Private key path', style: context.txt.fieldLabel),
                const SizedBox(height: 6),
                _SmallInput(
                  controller: _keyPath,
                  hint: '~/.ssh/id_ed25519',
                  onSubmitted: _submit,
                ),
                const SizedBox(height: 10),
                Text('Passphrase (optional)', style: context.txt.fieldLabel),
                const SizedBox(height: 6),
                _SmallInput(
                  controller: _passphrase,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      size: 16,
                      color: AppColors.fgMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    splashRadius: 16,
                  ),
                  onSubmitted: _submit,
                ),
              ],
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

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.bgInput,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: context.txt.body.copyWith(
            color: selected ? AppColors.bg : AppColors.fg,
          ),
        ),
      ),
    );
  }
}

class _SmallInput extends StatelessWidget {
  final TextEditingController controller;
  final bool autofocus;
  final bool obscure;
  final String? hint;
  final Widget? suffix;
  final VoidCallback onSubmitted;

  const _SmallInput({
    required this.controller,
    this.autofocus = false,
    this.obscure = false,
    this.hint,
    this.suffix,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        obscureText: obscure,
        style: context.txt.body,
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.bgInput,
          hintText: hint,
          hintStyle: context.txt.body.copyWith(color: AppColors.fgMuted),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: AppColors.accent),
          ),
          suffixIcon: suffix,
        ),
        onSubmitted: (_) => onSubmitted(),
      ),
    );
  }
}
