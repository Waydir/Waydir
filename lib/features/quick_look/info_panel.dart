import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/models/file_entry.dart';
import '../../core/platform/platform_paths.dart';
import '../../features/files/file_icons.dart';
import '../../i18n/strings.g.dart';
import '../../utils/format.dart';
import '../../ui/theme/app_theme.dart';
import '../../ui/theme/app_text_styles.dart';
import 'quick_look_common.dart';
import 'quick_look_io.dart';

class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text.toUpperCase(), style: context.txt.sectionLabel),
    );
  }
}

class PropRow extends StatelessWidget {
  final String label;
  final String value;

  const PropRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: context.txt.caption.copyWith(color: AppColors.fgMuted),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              value,
              style: context.txt.caption.copyWith(color: AppColors.fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _SizeRows extends StatelessWidget {
  final FileEntry entry;

  const _SizeRows({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.type != FileItemType.folder) {
      return PropRow(label: t.quickLook.size, value: formatBytes(entry.size));
    }
    return AsyncRetain<FolderStats?>(
      cacheKey: 'folder:${entry.realPath}',
      loader: () => folderStats(entry.realPath),
      builder: (stats) {
        final calc = t.quickLook.calculating;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropRow(
              label: t.quickLook.size,
              value: stats == null ? calc : formatBytes(stats.bytes),
            ),
            PropRow(
              label: t.quickLook.contains,
              value: stats == null
                  ? calc
                  : t.quickLook.items(count: stats.items),
            ),
          ],
        );
      },
    );
  }
}

class _StatRows extends StatelessWidget {
  final FileEntry entry;

  const _StatRows({required this.entry});

  @override
  Widget build(BuildContext context) {
    return AsyncRetain<FileStat?>(
      cacheKey: 'stat:${entry.realPath}|${entry.modifiedMs}',
      loader: () => FileStat.stat(entry.realPath),
      builder: (stat) {
        if (stat == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropRow(
              label: t.quickLook.accessed,
              value: formatTimeAgo(stat.accessed),
            ),
            PropRow(
              label: t.quickLook.changed,
              value: formatTimeAgo(stat.changed),
            ),
            PropRow(
              label: t.quickLook.permissions,
              value: stat.modeString(),
            ),
          ],
        );
      },
    );
  }
}

List<Widget> propertyRows(FileEntry e) {
  return [
    SectionLabel(t.quickLook.sectionGeneral),
    PropRow(
      label: t.quickLook.type,
      value: e.type == FileItemType.folder
          ? t.quickLook.typeFolder
          : e.extension.isEmpty
          ? t.quickLook.typeFile
          : e.extension.toUpperCase(),
    ),
    _SizeRows(entry: e),
    PropRow(label: t.quickLook.modified, value: formatTimeAgo(e.modified)),
    const SizedBox(height: 16),
    SectionLabel(t.quickLook.sectionDetails),
    PropRow(
      label: t.quickLook.location,
      value: PlatformPaths.parentOf(e.path),
    ),
    PropRow(label: t.quickLook.path, value: e.path),
    _StatRows(entry: e),
    AsyncRetain<QlSection?>(
      cacheKey: 'img:${e.realPath}|${e.modifiedMs}',
      loader: () => imageInfo(e),
      builder: (section) {
        if (section == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SectionLabel(section.title),
            for (final row in section.rows)
              PropRow(label: row.key, value: row.value),
          ],
        );
      },
    ),
  ];
}

class InfoPanel extends StatelessWidget {
  final FileEntry entry;

  const InfoPanel({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSidebar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        children: propertyRows(entry),
      ),
    );
  }
}

class PropertiesOnly extends StatelessWidget {
  final FileEntry? entry;
  final String? note;

  const PropertiesOnly({super.key, required this.entry, this.note});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    if (e == null) {
      return QlCentered(message: t.quickLook.noSelection);
    }
    final isFolder = e.type == FileItemType.folder;
    return Container(
      color: AppColors.bg,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: PhosphorIcon(
                  isFolder
                      ? PhosphorIconsRegular.folder
                      : fileIcon(e.extension),
                  size: 56,
                  color: isFolder
                      ? AppColors.accent
                      : fileIconColor(e.extension),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                e.name,
                textAlign: TextAlign.center,
                style: context.txt.heading,
              ),
              if (note != null) ...[
                const SizedBox(height: 6),
                Text(
                  note!,
                  textAlign: TextAlign.center,
                  style: context.txt.caption.copyWith(
                    color: AppColors.fgMuted,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSidebar,
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: propertyRows(e),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
