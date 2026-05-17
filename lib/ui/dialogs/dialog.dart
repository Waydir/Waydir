import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

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
      return Center(
        child: Material(
          type: MaterialType.transparency,
          child: _CustomDialogBody(
            title: title,
            icon: icon,
            iconColor: iconColor ?? AppColors.accent,
            width: width,
            body: body,
            actions: actions,
            onAction: (label) => Navigator.of(ctx).pop(label as T),
          ),
        ),
      );
    },
  );
}

class _CustomDialogBody extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final double width;
  final Widget body;
  final List<DialogAction> actions;
  final void Function(dynamic label) onAction;

  const _CustomDialogBody({
    required this.title,
    required this.icon,
    required this.iconColor,
    this.width = 360,
    required this.body,
    required this.actions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DialogTitle(title: title, icon: icon, iconColor: iconColor),
          const SizedBox(height: 12),
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
    );
  }
}

class _DialogTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;

  const _DialogTitle({
    required this.title,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PhosphorIcon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(title, style: context.txt.heading),
      ],
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
            borderRadius: BorderRadius.circular(4),
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
