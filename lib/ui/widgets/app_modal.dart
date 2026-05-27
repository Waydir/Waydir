import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';
import 'app_close_button.dart';

class AppModal extends StatelessWidget {
  final IconData? icon;
  final String title;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final VoidCallback onClose;
  final Widget child;

  const AppModal({
    super.key,
    this.icon,
    required this.title,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final fixedHeight = height != null;
    final body = fixedHeight
        ? Expanded(child: _paddedChild)
        : Flexible(child: _paddedChild);

    return Align(
      alignment: Alignment.center,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: width,
          height: height,
          constraints: fixedHeight
              ? null
              : const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Column(
              mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
              children: [
                _ModalTitleBar(icon: icon, title: title, onClose: onClose),
                Container(height: 1, color: AppColors.bgDivider),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget get _paddedChild {
    if (padding == EdgeInsets.zero) return child;
    return Padding(padding: padding, child: child);
  }
}

class _ModalTitleBar extends StatelessWidget {
  final IconData? icon;
  final String title;
  final VoidCallback onClose;

  const _ModalTitleBar({
    required this.icon,
    required this.title,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.bgSidebar),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.fgAccent),
            const SizedBox(width: 8),
          ],
          Text(title, style: context.txt.dialogTitle),
          const Spacer(),
          AppCloseButton(onTap: onClose),
        ],
      ),
    );
  }
}
