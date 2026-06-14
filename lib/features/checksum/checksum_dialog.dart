import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/fs/checksum_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/models/file_entry.dart';
import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_modal.dart';
import '../../ui/widgets/app_text_field.dart';
import '../../ui/widgets/app_toggle_chip.dart';
import '../../utils/format.dart';

Future<void> showChecksumDialog({
  required BuildContext context,
  required FileEntry entry,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) => Center(
      child: Material(
        type: MaterialType.transparency,
        child: _ChecksumDialog(entry: entry),
      ),
    ),
  );
}

class _ChecksumDialog extends StatefulWidget {
  final FileEntry entry;

  const _ChecksumDialog({required this.entry});

  @override
  State<_ChecksumDialog> createState() => _ChecksumDialogState();
}

class _ChecksumDialogState extends State<_ChecksumDialog> {
  final _expectedCtrl = TextEditingController();
  ChecksumAlgorithm _algorithm = ChecksumAlgorithm.sha256;
  ChecksumResult? _result;
  String? _error;
  bool _running = false;
  bool _copied = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _expectedCtrl.addListener(_onExpectedChanged);
  }

  @override
  void dispose() {
    _expectedCtrl.removeListener(_onExpectedChanged);
    _expectedCtrl.dispose();
    _generation++;
    super.dispose();
  }

  void _onExpectedChanged() {
    if (_error != null || _copied || _result != null) {
      setState(() {
        _error = null;
        _copied = false;
      });
    }
  }

  void _setAlgorithm(ChecksumAlgorithm algorithm) {
    if (_algorithm == algorithm || _running) return;
    setState(() {
      _algorithm = algorithm;
      _result = null;
      _error = null;
      _copied = false;
    });
  }

  Future<void> _verify() async {
    if (_running) return;
    final expected = _expectedCtrl.text;
    if (!ChecksumService.isExpectedFormatValid(_algorithm, expected)) {
      setState(() {
        _error = t.checksum.invalidExpected(
          algorithm: _algorithm.label,
          length: _algorithm.hexLength,
        );
        _result = null;
        _copied = false;
      });

      return;
    }
    final generation = ++_generation;
    setState(() {
      _running = true;
      _error = null;
      _copied = false;
    });
    try {
      final result = await ChecksumService.calculate(
        widget.entry.realPath,
        _algorithm,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        _running = false;
      });
    } catch (e, st) {
      log.warn('checksum', 'checksum calculation failed', error: e, stack: st);
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = null;
        _running = false;
        _error = t.checksum.readError;
      });
    }
  }

  Future<void> _copyDigest() async {
    final digest = _result?.digest;
    if (digest == null) return;
    await Clipboard.setData(ClipboardData(text: digest));
    if (!mounted) return;
    setState(() => _copied = true);
  }

  bool get _matches {
    final result = _result;
    if (result == null) return false;

    return ChecksumService.matches(
      algorithm: _algorithm,
      expected: _expectedCtrl.text,
      actual: result.digest,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();

          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: AppModal(
        icon: WaydirIconsRegular.checkSquare,
        title: t.checksum.title,
        width: 520,
        padding: const EdgeInsets.all(20),
        onClose: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.entry.name, style: context.txt.bodyEmphasis),
            const SizedBox(height: 4),
            Text(
              formatBytes(widget.entry.size),
              style: context.txt.body.copyWith(color: AppColors.fgMuted),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppToggleChip(
                    label: t.checksum.md5,
                    selected: _algorithm == ChecksumAlgorithm.md5,
                    onTap: () => _setAlgorithm(ChecksumAlgorithm.md5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppToggleChip(
                    label: t.checksum.sha256,
                    selected: _algorithm == ChecksumAlgorithm.sha256,
                    onTap: () => _setAlgorithm(ChecksumAlgorithm.sha256),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(t.checksum.expected, style: context.txt.fieldLabel),
            const SizedBox(height: 6),
            AppTextField(
              controller: _expectedCtrl,
              autofocus: true,
              hintText: t.checksum.expectedHint(algorithm: _algorithm.label),
              onSubmitted: (_) => _verify(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: context.txt.captionSmall.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ],
            if (_running) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.fgMuted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(t.checksum.calculating, style: context.txt.muted),
                ],
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 18),
              _ResultPanel(
                label: _matches ? t.checksum.match : t.checksum.mismatch,
                digest: result.digest,
                color: _matches ? AppColors.accent : AppColors.danger,
                copied: _copied,
                onCopy: _copyDigest,
              ),
            ],
            const SizedBox(height: 18),
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
                  label: _running ? t.checksum.calculating : t.checksum.verify,
                  color: _running ? AppColors.fgSubtle : AppColors.accent,
                  onTap: _running ? () {} : _verify,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final String label;
  final String digest;
  final Color color;
  final bool copied;
  final VoidCallback onCopy;

  const _ResultPanel({
    required this.label,
    required this.digest,
    required this.color,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(WaydirIconsRegular.check, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.txt.bodyEmphasis.copyWith(color: color),
              ),
              const Spacer(),
              DialogButton(
                label: copied ? t.checksum.copied : t.checksum.copy,
                color: AppColors.fgMuted,
                onTap: onCopy,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            digest,
            style: context.txt.code.copyWith(color: AppColors.fg),
          ),
        ],
      ),
    );
  }
}
