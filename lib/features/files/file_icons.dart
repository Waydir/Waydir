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
  bool isSymlink = false,
}) {
  final Widget icon;
  if (isFolder) {
    final folderName = materialFolderNames[name.toLowerCase()];
    icon = folderName != null
        ? SvgPicture.asset(
            'assets/icons/material/$folderName.svg',
            width: size,
            height: size,
          )
        : Icon(
            WaydirIconsFill.folder,
            size: size,
            color: AppColors.folderColor,
          );
  } else {
    final lowerName = name.toLowerCase();
    var iconName = materialFileNames[lowerName];
    iconName ??= materialFileExtensions[ext.toLowerCase()];
    iconName ??= 'document';
    icon = SvgPicture.asset(
      'assets/icons/material/$iconName.svg',
      width: size,
      height: size,
    );
  }

  if (!isSymlink) return icon;

  final badgeSize = size * 0.45;

  return SizedBox(
    width: size,
    height: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: Center(child: icon)),
        Positioned(
          right: -2,
          bottom: -2,
          child: Icon(
            WaydirIconsFill.link,
            size: badgeSize,
            color: AppColors.fgMuted,
          ),
        ),
      ],
    ),
  );
}
