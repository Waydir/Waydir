import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import '../../ui/theme/app_theme.dart';
import 'material_icons_map.dart';

Widget buildFileIcon({
  required String name,
  required String ext,
  required bool isFolder,
  double size = 20,
}) {
  if (isFolder) {
    final folderName = materialFolderNames[name.toLowerCase()];
    if (folderName != null) {
      return SvgPicture.asset(
        'assets/icons/material/$folderName.svg',
        width: size,
        height: size,
      );
    }
    return Icon(
      WaydirIconsFill.folder,
      size: size,
      color: AppColors.folderColor,
    );
  }

  final lowerName = name.toLowerCase();
  var iconName = materialFileNames[lowerName];
  iconName ??= materialFileExtensions[ext.toLowerCase()];
  iconName ??= 'document';

  return SvgPicture.asset(
    'assets/icons/material/$iconName.svg',
    width: size,
    height: size,
  );
}
