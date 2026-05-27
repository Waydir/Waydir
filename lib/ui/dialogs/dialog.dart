import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_modal.dart';

class DialogAction {
  final String label;
  final Color color;

  const DialogAction({required this.label, required this.color});
}

Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required String title,
  required IconData icon,
  Color? iconColor,
  double width = 360,
  required Widget body,
  required List<DialogAction> actions,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (ctx) {
      return _CustomDialogBody(
        title: title,
        icon: icon,
        width: width,
        body: body,
        actions: actions,
        onAction: (label) => Navigator.of(ctx).pop(label as T),
      );
    },
  );
}

class _CustomDialogBody extends StatelessWidget {
  final String title;
  final IconData icon;
  final double width;
  final Widget body;
  final List<DialogAction> actions;
  final void Function(dynamic label) onAction;

  const _CustomDialogBody({
    required this.title,
    required this.icon,
    this.width = 360,
    required this.body,
    required this.actions,
    required this.onAction,
  });

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || actions.isEmpty) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      onAction(actions.last.label);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      onAction(actions.first.label);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: AppModal(
        icon: icon,
        title: title,
        width: width,
        padding: const EdgeInsets.all(16),
        onClose: () =>
            onAction(actions.isNotEmpty ? actions.first.label : null),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            body,
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  DialogButton(
                    label: actions[i].label,
                    color: actions[i].color,
                    onTap: () => onAction(actions[i].label),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DialogButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const DialogButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<DialogButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: _hovered
                  ? widget.color
                  : widget.color.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            widget.label,
            style: context.txt.rowEmphasis.copyWith(color: widget.color),
          ),
        ),
      ),
    );
  }
}
