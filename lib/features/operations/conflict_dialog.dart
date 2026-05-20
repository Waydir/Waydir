import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import 'package:path/path.dart' as p;
import '../../core/models/file_operation.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import '../../i18n/strings.g.dart';

void showErrorListDialog({
  required BuildContext context,
  required List<TaskError> errors,
}) {
  showCustomDialog<String>(
    context: context,
    title: t.operations.errors(count: errors.length),
    icon: WaydirIconsRegular.warningCircle,
    iconColor: AppColors.danger,
    body: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: errors.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, thickness: 1, color: AppColors.bgDivider),
        itemBuilder: (_, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.basename(errors[i].path),
                style: context.txt.rowEmphasis,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                errors[i].message,
                style: context.txt.captionSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [DialogAction(label: t.dialog.close, color: AppColors.fgMuted)],
  );
}
