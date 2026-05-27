import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_text_styles.dart';

class AppToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppToggleChip({
    super.key,
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
