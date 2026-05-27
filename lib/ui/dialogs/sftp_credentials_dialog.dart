import 'package:flutter/material.dart';

import '../../features/locations/location_resolver.dart';
import '../../i18n/strings.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_toggle_chip.dart';
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
    return AppModal(
      title: widget.title,
      width: 360,
      padding: const EdgeInsets.all(20),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.password.sftpPrompt,
            style: context.txt.body.copyWith(color: AppColors.fgMuted),
          ),
          const SizedBox(height: 16),
          Text(t.password.username, style: context.txt.fieldLabel),
          const SizedBox(height: 6),
          AppTextField(
            controller: _username,
            autofocus: _username.text.isEmpty,
            height: 34,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AppToggleChip(
                  label: t.password.password,
                  selected: _method == _Method.password,
                  onTap: () => setState(() => _method = _Method.password),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppToggleChip(
                  label: t.password.privateKey,
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
            AppTextField(
              controller: _password,
              obscureText: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                  color: AppColors.fgMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
                splashRadius: 16,
              ),
              onSubmitted: (_) => _submit(),
              autofocus: _username.text.isNotEmpty,
              height: 34,
            ),
          ] else ...[
            Text(t.password.privateKeyPath, style: context.txt.fieldLabel),
            const SizedBox(height: 6),
            AppTextField(
              controller: _keyPath,
              hintText: '~/.ssh/id_ed25519',
              onSubmitted: (_) => _submit(),
              height: 34,
            ),
            const SizedBox(height: 10),
            Text(t.password.passphraseOptional, style: context.txt.fieldLabel),
            const SizedBox(height: 6),
            AppTextField(
              controller: _passphrase,
              obscureText: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 16,
                  color: AppColors.fgMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
                splashRadius: 16,
              ),
              onSubmitted: (_) => _submit(),
              height: 34,
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
    );
  }
}
