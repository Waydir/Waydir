import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/widgets/app_modal.dart';
import '../../ui/widgets/app_text_field.dart';
import 'tag_store.dart';

const _palette = <Color>[
  Color(0xFFE5484D),
  Color(0xFFF76B15),
  Color(0xFFE2A610),
  Color(0xFF46A758),
  Color(0xFF3E63DD),
  Color(0xFF8E4EC6),
  Color(0xFF8B8D98),
  Color(0xFFD6409F),
  Color(0xFF12A594),
  Color(0xFF978365),
];

Future<bool> showTagEditDialog(BuildContext context, {TagDef? existing}) async {
  final result = await showGeneralDialog<bool>(
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
          child: _TagEditDialog(existing: existing),
        ),
      );
    },
  );

  return result ?? false;
}

class _TagEditDialog extends StatefulWidget {
  final TagDef? existing;

  const _TagEditDialog({this.existing});

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  late final TextEditingController _controller;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.existing?.name ?? '');
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    _color = widget.existing?.color ?? _palette.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final existing = widget.existing;
    if (existing == null) {
      await TagStore.instance.createTag(name, _color);
    } else {
      await TagStore.instance.updateTag(existing.id, name: name, color: _color);
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  void _cancel() => Navigator.of(context).pop(false);

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
        icon: WaydirIconsRegular.bookmarkSimple,
        title: widget.existing == null ? t.tags.newTag : t.tags.editTag,
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
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final color in _palette)
                  _Swatch(
                    color: color,
                    selected: color.toARGB32() == _color.toARGB32(),
                    onTap: () => setState(() => _color = color),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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
                  label: t.tags.save,
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

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.fg : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
