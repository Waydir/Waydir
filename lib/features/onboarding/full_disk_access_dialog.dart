import 'package:flutter/material.dart';

import '../../core/platform/full_disk_access.dart';
import '../../i18n/strings.g.dart';
import '../../ui/dialogs/dialog.dart';
import '../../ui/icons/waydir_icons.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';

Future<void> showFullDiskAccessDialog(BuildContext context) {
  return showCustomDialog<String>(
    context: context,
    title: t.fullDiskAccess.title,
    icon: WaydirIconsRegular.hardDrive,
    width: 400,
    body: Text(
      t.fullDiskAccess.body,
      style: context.txt.body.copyWith(color: AppColors.fgMuted, height: 1.4),
    ),
    actions: [
      DialogAction(label: t.fullDiskAccess.later, color: AppColors.fgMuted),
      DialogAction(
        label: t.fullDiskAccess.openSettings,
        color: AppColors.accent,
      ),
    ],
  ).then((label) {
    if (label == t.fullDiskAccess.openSettings) {
      openFullDiskAccessSettings();
    }
  });
}
