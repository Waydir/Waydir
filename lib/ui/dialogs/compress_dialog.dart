import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../../core/archive/archive_writer.dart';
import '../../i18n/strings.g.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_dropdown.dart';
import 'dialog.dart';

class CompressRequest {
  final String baseName;
  final ArchiveFormat format;
  final CompressionLevel level;

  const CompressRequest({
    required this.baseName,
    required this.format,
    required this.level,
  });

  String get fileName => '$baseName.${format.extension}';
}

Future<CompressRequest?> showCompressDialog({
  required BuildContext context,
  required String defaultBaseName,
  required String destinationDir,
}) {
  return showDialog<CompressRequest>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _CompressBody(
          defaultBaseName: defaultBaseName,
          destinationDir: destinationDir,
        ),
      ),
    ),
  );
}

class _CompressBody extends StatefulWidget {
  final String defaultBaseName;
  final String destinationDir;

  const _CompressBody({
    required this.defaultBaseName,
    required this.destinationDir,
  });

  @override
  State<_CompressBody> createState() => _CompressBodyState();
}

class _CompressBodyState extends State<_CompressBody> {
  late final TextEditingController _name = TextEditingController(
    text: widget.defaultBaseName,
  )..addListener(_onNameChanged);
  ArchiveFormat _format = ArchiveFormat.zip;
  CompressionLevel _level = CompressionLevel.normal;

  String get _sanitized => _name.text.replaceAll(RegExp(r'[\\/:]'), '').trim();

  bool get _valid => _sanitized.isNotEmpty;

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _name.removeListener(_onNameChanged);
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final base = _sanitized;
    if (base.isEmpty) return;
    Navigator.of(
      context,
    ).pop(CompressRequest(baseName: base, format: _format, level: _level));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                WaydirIconsRegular.fileZip,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(t.compress.title, style: context.txt.heading),
            ],
          ),
          const SizedBox(height: 16),
          Text(t.compress.archiveName, style: context.txt.fieldLabel),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            autofocus: true,
            style: context.txt.body,
            cursorColor: AppColors.accent,
            decoration: _inputDecoration(suffix: '.${_format.extension}'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 14),
          Text(t.compress.format, style: context.txt.fieldLabel),
          const SizedBox(height: 6),
          AppDropdown<ArchiveFormat>(
            value: _format,
            items: [
              for (final f in ArchiveFormat.values)
                AppDropdownItem(value: f, label: f.label),
            ],
            onChanged: (v) => setState(() => _format = v),
          ),
          const SizedBox(height: 14),
          Text(t.compress.level, style: context.txt.fieldLabel),
          const SizedBox(height: 6),
          AppDropdown<CompressionLevel>(
            value: _level,
            items: [
              AppDropdownItem(
                value: CompressionLevel.store,
                label: t.compress.levelStore,
              ),
              AppDropdownItem(
                value: CompressionLevel.normal,
                label: t.compress.levelNormal,
              ),
              AppDropdownItem(
                value: CompressionLevel.maximum,
                label: t.compress.levelMaximum,
              ),
            ],
            onChanged: (v) => setState(() => _level = v),
          ),
          const SizedBox(height: 14),
          Text(t.compress.destination, style: context.txt.fieldLabel),
          const SizedBox(height: 6),
          Text(
            widget.destinationDir,
            style: context.txt.body.copyWith(color: AppColors.fgMuted),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DialogButton(
                label: t.compress.cancel,
                color: AppColors.fgMuted,
                onTap: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              DialogButton(
                label: t.compress.create,
                color: _valid ? AppColors.accent : AppColors.fgSubtle,
                onTap: _valid ? _submit : () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? suffix}) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.bgInput,
    suffixText: suffix,
    suffixStyle: context.txt.body.copyWith(color: AppColors.fgMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.accent),
    ),
  );
}
