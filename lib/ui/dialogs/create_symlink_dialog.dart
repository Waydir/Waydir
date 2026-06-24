import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../i18n/strings.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_modal.dart';
import '../widgets/app_text_field.dart';
import 'dialog.dart';

class CreateSymlinkRequest {
  final String target;
  final String name;

  const CreateSymlinkRequest({required this.target, required this.name});
}

Future<CreateSymlinkRequest?> showCreateSymlinkDialog({
  required BuildContext context,
  String initialTarget = '',
  String initialName = '',
}) {
  return showDialog<CreateSymlinkRequest>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _CreateSymlinkBody(
          initialTarget: initialTarget,
          initialName: initialName,
        ),
      ),
    ),
  );
}

class _CreateSymlinkBody extends StatefulWidget {
  final String initialTarget;
  final String initialName;

  const _CreateSymlinkBody({
    required this.initialTarget,
    required this.initialName,
  });

  @override
  State<_CreateSymlinkBody> createState() => _CreateSymlinkBodyState();
}

class _CreateSymlinkBodyState extends State<_CreateSymlinkBody> {
  late final TextEditingController _target = TextEditingController(
    text: widget.initialTarget,
  )..addListener(_onChanged);
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  )..addListener(_onChanged);

  bool get _valid =>
      _target.text.trim().isNotEmpty && _name.text.trim().isNotEmpty;

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _target.removeListener(_onChanged);
    _target.dispose();
    _name.removeListener(_onChanged);
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_valid) return;
    Navigator.of(context).pop(
      CreateSymlinkRequest(
        target: _target.text.trim(),
        name: _name.text.trim(),
      ),
    );
  }

  Future<void> _pickFolder() async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: t.dialog.chooseFolder,
    );
    if (path != null) _target.text = path;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(dialogTitle: t.dialog.chooseFile);
    final path = result?.files.single.path;
    if (path != null) _target.text = path;
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: WaydirIconsRegular.link,
      title: t.dialog.createSymlinkTitle,
      width: 420,
      padding: const EdgeInsets.all(20),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.dialog.symlinkTargetHint, style: context.txt.fieldLabel),
          const SizedBox(height: 6),
          AppTextField(
            controller: _target,
            autofocus: true,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    WaydirIconsRegular.folder,
                    size: 16,
                    color: AppColors.fgMuted,
                  ),
                  tooltip: t.dialog.chooseFolder,
                  onPressed: _pickFolder,
                  splashRadius: 16,
                ),
                IconButton(
                  icon: Icon(
                    WaydirIconsRegular.file,
                    size: 16,
                    color: AppColors.fgMuted,
                  ),
                  tooltip: t.dialog.chooseFile,
                  onPressed: _pickFile,
                  splashRadius: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(t.dialog.symlinkNameHint, style: context.txt.fieldLabel),
          const SizedBox(height: 6),
          AppTextField(controller: _name, onSubmitted: (_) => _submit()),
          const SizedBox(height: 20),
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
                label: t.dialog.create,
                color: _valid ? AppColors.accent : AppColors.fgSubtle,
                onTap: _valid ? _submit : () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
