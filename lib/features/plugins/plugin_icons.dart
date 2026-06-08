import 'package:flutter/widgets.dart';

import '../../ui/icons/waydir_icons.dart';

/// Glyph shown for a plugin entry that declares no icon, or an unknown name.
const IconData defaultPluginGlyph = WaydirIconsRegular.gearSix;

/// Named builtin icons a plugin may set via `icon = "<name>"` instead of
/// shipping an image file. Keep names stable - they are part of the plugin API.
const Map<String, IconData> _pluginGlyphs = {
  'archive': WaydirIconsRegular.archive,
  'bell': WaydirIconsRegular.bell,
  'bookmark': WaydirIconsRegular.bookmarkSimple,
  'bug': WaydirIconsRegular.bug,
  'calendar': WaydirIconsRegular.calendar,
  'check': WaydirIconsRegular.check,
  'clipboard': WaydirIconsRegular.clipboard,
  'clock': WaydirIconsRegular.clock,
  'code': WaydirIconsRegular.code,
  'copy': WaydirIconsRegular.copy,
  'desktop': WaydirIconsRegular.desktop,
  'download': WaydirIconsRegular.downloadSimple,
  'eye': WaydirIconsRegular.eye,
  'file': WaydirIconsRegular.file,
  'file-audio': WaydirIconsRegular.fileAudio,
  'file-code': WaydirIconsRegular.fileCode,
  'file-image': WaydirIconsRegular.fileImage,
  'file-pdf': WaydirIconsRegular.filePdf,
  'file-text': WaydirIconsRegular.fileTxt,
  'file-zip': WaydirIconsRegular.fileZip,
  'folder': WaydirIconsRegular.folder,
  'folder-open': WaydirIconsRegular.folderOpen,
  'folder-plus': WaydirIconsRegular.folderPlus,
  'gear': WaydirIconsRegular.gearSix,
  'git-branch': WaydirIconsRegular.gitBranch,
  'hard-drive': WaydirIconsRegular.hardDrive,
  'image': WaydirIconsRegular.image,
  'info': WaydirIconsRegular.info,
  'keyboard': WaydirIconsRegular.keyboard,
  'list': WaydirIconsRegular.list,
  'magic-wand': WaydirIconsRegular.magicWand,
  'music': WaydirIconsRegular.musicNote,
  'note': WaydirIconsRegular.notebook,
  'palette': WaydirIconsRegular.palette,
  'pencil': WaydirIconsRegular.pencilSimple,
  'plus': WaydirIconsRegular.plus,
  'ruler': WaydirIconsRegular.ruler,
  'scissors': WaydirIconsRegular.scissors,
  'search': WaydirIconsRegular.magnifyingGlass,
  'sliders': WaydirIconsRegular.slidersHorizontal,
  'terminal': WaydirIconsRegular.terminal,
  'trash': WaydirIconsRegular.trash,
  'tree': WaydirIconsRegular.treeStructure,
  'usb': WaydirIconsRegular.usb,
  'video': WaydirIconsRegular.videoCamera,
  'warning': WaydirIconsRegular.warning,
};

/// Resolves a plugin's `icon` name to a builtin glyph. Image paths (`.svg`/
/// `.png`) are handled separately via `PluginContribution.iconPath`; this
/// returns the fallback for those and for unknown names.
IconData pluginGlyph(String? name) {
  if (name == null) return defaultPluginGlyph;
  return _pluginGlyphs[name] ?? defaultPluginGlyph;
}
