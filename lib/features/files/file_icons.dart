import 'package:flutter/material.dart';
import 'package:waydir/ui/icons/waydir_icons.dart';
import '../../ui/theme/app_theme.dart';

Color fileIconColor(String ext) {
  return switch (ext) {
    'dart' => AppColors.fileCode,
    'py' => AppColors.fileCode,
    'js' || 'ts' => AppColors.fileJs,
    'html' => AppColors.fileHtml,
    'css' => AppColors.fileCss,
    'json' => AppColors.fgMuted,
    'md' => AppColors.accentHover,
    'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' || 'webp' => AppColors.fileImage,
    'zip' || 'tar' || 'gz' || 'rar' || '7z' => AppColors.fileArchive,
    'pdf' => AppColors.danger,
    'mp3' || 'wav' || 'flac' || 'ogg' => AppColors.fileAudio,
    'mp4' || 'avi' || 'mkv' || 'mov' => AppColors.fileVideo,
    'txt' || 'log' => AppColors.fgMuted,
    _ => AppColors.fileDefault,
  };
}

IconData fileIcon(String ext) {
  return switch (ext) {
    'dart' || 'py' => WaydirIconsRegular.fileCode,
    'js' => WaydirIconsRegular.fileJs,
    'ts' => WaydirIconsRegular.fileTs,
    'html' || 'htm' => WaydirIconsRegular.fileHtml,
    'css' => WaydirIconsRegular.fileCss,
    'json' => WaydirIconsRegular.fileCode,
    'md' => WaydirIconsRegular.fileMd,
    'png' ||
    'jpg' ||
    'jpeg' ||
    'gif' ||
    'svg' ||
    'webp' => WaydirIconsRegular.fileImage,
    'zip' || 'tar' || 'gz' || 'rar' || '7z' => WaydirIconsRegular.fileZip,
    'pdf' => WaydirIconsRegular.filePdf,
    'mp3' || 'wav' || 'flac' || 'ogg' => WaydirIconsRegular.fileAudio,
    'mp4' || 'avi' || 'mkv' || 'mov' => WaydirIconsRegular.fileVideo,
    'txt' || 'log' => WaydirIconsRegular.fileTxt,
    _ => WaydirIconsRegular.file,
  };
}
