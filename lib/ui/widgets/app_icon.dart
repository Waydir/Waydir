import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';

import '../theme/app_theme.dart';

/// Renders an application icon from a freedesktop icon path (PNG/SVG), falling
/// back to a generic glyph when the path is missing or an unsupported format
/// (e.g. legacy XPM, which Flutter cannot decode).
class AppIcon extends StatelessWidget {
  final String? path;
  final double size;

  const AppIcon({super.key, required this.path, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      WaydirIconsRegular.appWindow,
      size: size * 0.9,
      color: AppColors.fgMuted,
    );
    final pth = path;
    if (pth == null || !File(pth).existsSync()) {
      return SizedBox(width: size, height: size, child: fallback);
    }
    final lower = pth.toLowerCase();
    Widget child;
    if (lower.endsWith('.svg')) {
      child = SvgPicture.file(
        File(pth),
        width: size,
        height: size,
        placeholderBuilder: (_) => fallback,
      );
    } else if (lower.endsWith('.png')) {
      child = Image.file(
        File(pth),
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      );
    } else {
      child = fallback;
    }
    return SizedBox(width: size, height: size, child: child);
  }
}
